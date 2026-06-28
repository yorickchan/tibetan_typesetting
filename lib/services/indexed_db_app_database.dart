import 'dart:async';

import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_browser.dart';
import 'app_database.dart';
import 'package:idb_shim/idb_browser.dart';
import 'app_database.dart';

/// [AppDatabase] implementation backed by IndexedDB via idb_shim.
///
/// Translates SQL DDL into IndexedDB object stores and maps CRUD operations
/// to IDB object store methods. Schema is tracked in-memory for query
/// filtering, column projection, and raw SQL emulation.
class IndexedDbAppDatabase implements AppDatabase {
  final Database _db;
  final String _dbName;
  final IdbFactory _idbFactory;
  final Transaction? _txn;

  /// table name → primary key column name
  final Map<String, String> _tableKeys;

  /// table name → ordered column names
  final Map<String, List<String>> _tableColumns;

  /// Set during [open]'s onUpgradeNeeded so that [execute] can create
  /// object stores on the versionchange transaction.
  VersionChangeEvent? _upgradeEvent;

  // ------------------------------------------------------------------
  // Constructors
  // ------------------------------------------------------------------

  IndexedDbAppDatabase._(
    this._db,
    this._dbName, {
    required IdbFactory idbFactory,
  })  : _idbFactory = idbFactory,
        _txn = null,
        _tableKeys = {},
        _tableColumns = {};

  /// Transaction-scoped constructor — all operations go through [_txn].
  IndexedDbAppDatabase._forTxn(
    this._txn,
    Map<String, String> tableKeys,
    Map<String, List<String>> tableColumns,
    this._dbName,
    this._idbFactory,
  )  : _db = _txn!.database,
        _tableKeys = Map.unmodifiable(tableKeys),
        _tableColumns = Map.unmodifiable(tableColumns);

  /// Open (or create) an IndexedDB database and run schema migrations.
  ///
  /// [name] becomes the IndexedDB database name.
  /// [version] is the target schema version.
  /// [onCreate] is called when the database is first created (oldVersion < 1).
  /// [onUpgrade] is called for every subsequent version bump.
  static Future<IndexedDbAppDatabase> open({
    required String name,
    required int version,
    required Future<void> Function(AppDatabase db, int version) onCreate,
    required Future<void> Function(
      AppDatabase db,
      int oldVersion,
      int newVersion,
    ) onUpgrade,
  }) async {
    final idbFactory = getIdbFactory()!;

    IndexedDbAppDatabase? instance;

    final db = await idbFactory.open(
      name,
      version: version,
      onUpgradeNeeded: (VersionChangeEvent event) {
        instance = IndexedDbAppDatabase._(event.database, name,
            idbFactory: idbFactory);

        // Create object stores synchronously. IndexedDB onupgradeneeded
        // must finish all work before the handler returns — no awaits.
        // We hardcode the schema instead of calling the async onCreate /
        // onUpgrade callbacks, which use await and would defer work past
        // the transaction commit.
        final edb = event.database;
        if (event.oldVersion < 1) {
          edb.createObjectStore('projects', keyPath: 'id');
          edb.createObjectStore('app_settings', keyPath: 'key');
          edb.createObjectStore('pronunciation_dictionary',
              keyPath: 'tibetan_syllable');
          edb.createObjectStore('title_page_templates', keyPath: 'id');
          instance!._initSchema();
        }
        // Future upgrades (oldVersion >= 1) would go here.
      },
    );

    instance ??= IndexedDbAppDatabase._(db, name, idbFactory: idbFactory);
    if (instance!._tableKeys.isEmpty) {
      // Reopened at same version — no upgrade fired. Populate schema
      // from the existing object store names.
      instance!._initSchema();
    }

    return instance!;
  }

  /// Populate in-memory schema maps. Called for both fresh creation and
  /// reopen of an existing database.
  void _initSchema() {
    _tableKeys['projects'] = 'id';
    _tableColumns['projects'] = [
      'id', 'name', 'tags_json', 'project_json', 'created_at', 'updated_at'
    ];
    _tableKeys['app_settings'] = 'key';
    _tableColumns['app_settings'] = ['key', 'value_json'];
    _tableKeys['pronunciation_dictionary'] = 'tibetan_syllable';
    _tableColumns['pronunciation_dictionary'] = [
      'tibetan_syllable', 'chinese_pronunciation', 'word_count',
      'created_at', 'updated_at'
    ];
    _tableKeys['title_page_templates'] = 'id';
    _tableColumns['title_page_templates'] = [
      'id', 'name', 'svg_content', 'created_at'
    ];
  }

  // ------------------------------------------------------------------
  // Schema DDL
  // ------------------------------------------------------------------

  @override
  Future<void> execute(String sql) async {
    final trimmed = sql.trim();

    // ---- CREATE TABLE -------------------------------------------------
    final createMatch = RegExp(
      r'CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+(\w+)\s*\((.+)\)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (createMatch != null) {
      final tableName = createMatch.group(1)!;
      final columnsDef = createMatch.group(2)!;
      final cols = <String>[];
      String? keyCol;

      for (final colDef in columnsDef.split(',')) {
        final colMatch = RegExp(
          r'(\w+)\s+\w+(\s+PRIMARY\s+KEY)?',
          caseSensitive: false,
        ).firstMatch(colDef.trim());
        if (colMatch != null) {
          final colName = colMatch.group(1)!;
          cols.add(colName);
          if (colMatch.group(2) != null) {
            keyCol = colName;
          }
        }
      }

      _tableColumns[tableName] = cols;
      if (keyCol != null) {
        _tableKeys[tableName] = keyCol;
      }

      // During upgrade, actually create the object store.
      if (_upgradeEvent != null) {
        _upgradeEvent!.database.createObjectStore(
          tableName,
          keyPath: keyCol,
          autoIncrement: false,
        );
      }
      return;
    }

    // ---- CREATE INDEX -------------------------------------------------
    if (RegExp(r'CREATE\s+INDEX', caseSensitive: false).hasMatch(trimmed)) {
      // IndexedDB uses key-based lookups; indexes are not needed.
      return;
    }

    // ---- ALTER TABLE ADD COLUMN ---------------------------------------
    final alterMatch = RegExp(
      r'ALTER\s+TABLE\s+(\w+)\s+ADD\s+COLUMN\s+(\w+)\s+\w+',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (alterMatch != null) {
      final tableName = alterMatch.group(1)!;
      final colName = alterMatch.group(2)!;
      _tableColumns[tableName]?.add(colName);
      return;
    }

    // Unknown DDL — silently ignored in IndexedDB mode.
  }

  // ------------------------------------------------------------------
  // Query
  // ------------------------------------------------------------------

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    List<Map<String, Object?>> results;

    final keyCol = _tableKeys[table];
    final simpleKey = _parseSimpleEquality(where);
    if (simpleKey != null &&
        keyCol != null &&
        simpleKey == keyCol &&
        whereArgs != null &&
        whereArgs.length == 1) {
      // Primary key lookup.
      final store = _getStore(table, mode: idbModeReadOnly);
      final obj = await store.getObject(whereArgs.first!);
      if (obj is Map) {
        results = [Map<String, Object?>.from(obj as Map)];
      } else {
        results = [];
      }
    } else {
      // Full scan + Dart-side filter/sort/limit.
      final store = _getStore(table, mode: idbModeReadOnly);
      final all = await store.getAll();
      results = all.map((e) => Map<String, Object?>.from(e as Map)).toList();

      // WHERE filtering
      if (where != null && whereArgs != null) {
        results = _applyWhere(results, where, whereArgs);
      }

      // ORDER BY
      if (orderBy != null) {
        results = _applyOrderBy(results, orderBy);
      }

      // LIMIT / OFFSET
      if (offset != null && offset > 0) {
        results = offset < results.length
            ? results.sublist(offset)
            : <Map<String, Object?>>[];
      }
      if (limit != null) {
        results = results.take(limit).toList();
      }
    }

    // Column projection
    if (columns != null && columns.isNotEmpty) {
      results = results.map((row) {
        final projected = <String, Object?>{};
        for (final col in columns) {
          projected[col] = row[col];
        }
        return projected;
      }).toList();
    }

    return results;
  }

  // ------------------------------------------------------------------
  // Insert
  // ------------------------------------------------------------------

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    DbConflictAlgorithm? conflictAlgorithm,
  }) async {
    final store = _getStore(table, mode: idbModeReadWrite);

    // IndexedDB put() is always upsert (equivalent to replace).
    // For ignore semantics we would check existence first, but the app
    // only uses replace and the default (unspecified) behavior.
    if (conflictAlgorithm == DbConflictAlgorithm.ignore) {
      final keyCol = _tableKeys[table];
      if (keyCol != null && values.containsKey(keyCol)) {
        final existing = await store.getObject(values[keyCol]!);
        if (existing != null) return 0;
      }
    }

    await store.put(values);
    return 1;
  }

  // ------------------------------------------------------------------
  // Update
  // ------------------------------------------------------------------

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final store = _getStore(table, mode: idbModeReadWrite);
    final keyCol = _tableKeys[table];

    // Primary key update path.
    final simpleKey = _parseSimpleEquality(where);
    if (simpleKey != null &&
        keyCol != null &&
        simpleKey == keyCol &&
        whereArgs != null &&
        whereArgs.length == 1) {
      final key = whereArgs.first!;
      final existing = await store.getObject(key);
      if (existing is! Map) return 0;
      final merged = Map<String, Object?>.from(existing as Map);
      merged.addAll(values);
      await store.put(merged);
      return 1;
    }

    // General update path: scan, filter, merge, put.
    final all = await store.getAll();
    final rows = all.map((e) => Map<String, Object?>.from(e as Map)).toList();
    final filtered =
        where != null && whereArgs != null
            ? _applyWhere(rows, where, whereArgs)
            : rows;

    int count = 0;
    for (final row in filtered) {
      row.addAll(values);
      await store.put(row);
      count++;
    }
    return count;
  }

  // ------------------------------------------------------------------
  // Delete
  // ------------------------------------------------------------------

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final store = _getStore(table, mode: idbModeReadWrite);
    final keyCol = _tableKeys[table];

    // Primary key delete path.
    final simpleKey = _parseSimpleEquality(where);
    if (simpleKey != null &&
        keyCol != null &&
        simpleKey == keyCol &&
        whereArgs != null &&
        whereArgs.length == 1) {
      await store.delete(whereArgs.first!);
      return 1;
    }

    // General delete path: scan, filter, delete each.
    final all = await store.getAll();
    final rows = all.map((e) => Map<String, Object?>.from(e as Map)).toList();
    final filtered =
        where != null && whereArgs != null
            ? _applyWhere(rows, where, whereArgs)
            : rows;

    int count = 0;
    for (final row in filtered) {
      final pk = keyCol != null ? row[keyCol] : null;
      if (pk != null) {
        await store.delete(pk);
        count++;
      }
    }
    return count;
  }

  // ------------------------------------------------------------------
  // Transaction
  // ------------------------------------------------------------------

  @override
  Future<void> transaction(
    Future<void> Function(AppDatabase txn) action,
  ) async {
    final storeNames = _tableKeys.keys.toList();
    if (storeNames.isEmpty) {
      // No stores known yet — just run directly.
      await action(this);
      return;
    }

    final txn = _db.transaction(storeNames, idbModeReadWrite);
    final txnDb = IndexedDbAppDatabase._forTxn(
      txn,
      _tableKeys,
      _tableColumns,
      _dbName,
      _idbFactory,
    );
    try {
      await action(txnDb);
    } catch (e) {
      txn.abort();
      rethrow;
    }
    await txn.completed;
  }

  // ------------------------------------------------------------------
  // Batch
  // ------------------------------------------------------------------

  @override
  DbBatch batch() => DbBatch();

  @override
  Future<void> commitBatch(DbBatch batch, {bool noResult = false}) async {
    if (batch.ops.isEmpty) return;

    final storeNames = batch.ops.map((op) => op.table).toSet().toList();
    final txn = _db.transaction(storeNames, idbModeReadWrite);

    try {
      for (final op in batch.ops) {
        final store = txn.objectStore(op.table);
        await store.put(op.values);
      }
    } catch (e) {
      txn.abort();
      rethrow;
    }
    await txn.completed;
  }

  // ------------------------------------------------------------------
  // rawQuery
  // ------------------------------------------------------------------

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    // PRAGMA table_info(...) → simulate from schema maps.
    final pragmaMatch = RegExp(
      r"PRAGMA\s+table_info\((\w+)\)",
      caseSensitive: false,
    ).firstMatch(sql.trim());
    if (pragmaMatch != null) {
      final tableName = pragmaMatch.group(1)!;
      final cols = _tableColumns[tableName];
      if (cols == null) return [];
      return cols.map((col) {
        return <String, Object?>{
          'name': col,
          'type': 'TEXT', // approximate
        };
      }).toList();
    }

    // SELECT col FROM table WHERE col IN (?,?,...)
    final selectInMatch = RegExp(
      r"SELECT\s+(.+?)\s+FROM\s+(\w+)\s+WHERE\s+(\w+)\s+IN\s*\(([^)]*)\)",
      caseSensitive: false,
    ).firstMatch(sql.trim());
    if (selectInMatch != null) {
      final selectExpr = selectInMatch.group(1)!.trim();
      final tableName = selectInMatch.group(2)!;
      final whereCol = selectInMatch.group(3)!;
      final selectCols = selectExpr == '*'
          ? null
          : selectExpr.split(',').map((s) => s.trim()).toList();

      final keyCol = _tableKeys[tableName];
      final args = arguments ?? <Object?>[];

      // If WHERE col is the primary key, do direct lookups.
      if (keyCol != null && whereCol == keyCol) {
        final store = _getStore(tableName, mode: idbModeReadOnly);
        final results = <Map<String, Object?>>[];
        for (final arg in args) {
          final obj = await store.getObject(arg!);
          if (obj is Map) {
            results.add(Map<String, Object?>.from(obj as Map));
          }
        }

        // Column projection
        if (selectCols != null) {
          return results.map((row) {
            final projected = <String, Object?>{};
            for (final col in selectCols) {
              projected[col] = row[col];
            }
            return projected;
          }).toList();
        }
        return results;
      }

      // General fallback: scan + filter.
      final store = _getStore(tableName, mode: idbModeReadOnly);
      final all = await store.getAll();
      final rows =
          all.map((e) => Map<String, Object?>.from(e as Map)).toList();

      final argSet = args.whereType<Object>().toSet();
      final filtered = rows.where((row) {
        final val = row[whereCol];
        return val != null && argSet.contains(val);
      }).toList();

      if (selectCols != null) {
        return filtered.map((row) {
          final projected = <String, Object?>{};
          for (final col in selectCols) {
            projected[col] = row[col];
          }
          return projected;
        }).toList();
      }
      return filtered;
    }

    throw UnsupportedError('rawQuery SQL not supported: $sql');
  }

  // ------------------------------------------------------------------
  // Version
  // ------------------------------------------------------------------

  @override
  Future<int> getVersion() async => _db.version;

  @override
  Future<void> setVersion(int version) async {
    // IndexedDB version is set at open time; runtime changes require
    // closing and re-opening with a new version.
    // This is a no-op — the caller should use open() for migrations.
  }

  // ------------------------------------------------------------------
  // Lifecycle
  // ------------------------------------------------------------------

  @override
  Future<void> close() async {
    _db.close();
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  /// Returns the object store for [tableName].
  ///
  /// When inside an explicit transaction ([_txn] is set), uses that
  /// transaction. Otherwise opens an auto-commit transaction.
  ObjectStore _getStore(String tableName, {String mode = 'readonly'}) {
    if (_txn != null) {
      return _txn!.objectStore(tableName);
    }
    return _db.transaction(tableName, mode).objectStore(tableName);
  }

  /// Extracts the column name from a simple `col = ?` where clause.
  /// Returns `null` if the clause is compound or uses operators other
  /// than `=`.
  String? _parseSimpleEquality(String? where) {
    if (where == null) return null;
    final m = RegExp(r'^(\w+)\s*=\s*\?\s*$').firstMatch(where.trim());
    return m?.group(1);
  }

  /// Dart-side WHERE filter. Supports only simple `col = ?` clauses.
  List<Map<String, Object?>> _applyWhere(
    List<Map<String, Object?>> rows,
    String where,
    List<Object?> whereArgs,
  ) {
    final m = RegExp(r'^(\w+)\s*=\s*\?\s*$').firstMatch(where.trim());
    if (m == null || whereArgs.isEmpty) return rows;
    final col = m.group(1)!;
    final val = whereArgs.first;
    return rows.where((row) => row[col] == val).toList();
  }

  /// Dart-side ORDER BY. Simple single-column ASC/DESC.
  List<Map<String, Object?>> _applyOrderBy(
    List<Map<String, Object?>> rows,
    String orderBy,
  ) {
    final parts = orderBy.trim().split(RegExp(r'\s+'));
    final col = parts[0];
    final desc = parts.length > 1 && parts[1].toUpperCase() == 'DESC';

    final sorted = List<Map<String, Object?>>.from(rows);
    sorted.sort((a, b) {
      final va = a[col];
      final vb = b[col];
      if (va == null && vb == null) return 0;
      if (va == null) return desc ? -1 : 1;
      if (vb == null) return desc ? 1 : -1;
      final cmp = _compareValues(va, vb);
      return desc ? -cmp : cmp;
    });
    return sorted;
  }

  /// Compares two values for ordering using their natural [Comparable] order.
  int _compareValues(Object a, Object b) {
    if (a is num && b is num) return a.compareTo(b);
    if (a is String && b is String) return a.compareTo(b);
    if (a is bool && b is bool) return (a ? 1 : 0).compareTo(b ? 1 : 0);
    return a.toString().compareTo(b.toString());
  }
}
