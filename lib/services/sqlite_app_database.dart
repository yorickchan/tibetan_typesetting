import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

ConflictAlgorithm? _mapConflict(DbConflictAlgorithm? ca) {
  return switch (ca) {
    DbConflictAlgorithm.replace => ConflictAlgorithm.replace,
    DbConflictAlgorithm.ignore => ConflictAlgorithm.ignore,
    DbConflictAlgorithm.rollback => ConflictAlgorithm.rollback,
    DbConflictAlgorithm.abort => ConflictAlgorithm.abort,
    DbConflictAlgorithm.fail => ConflictAlgorithm.fail,
    null => null,
  };
}

class SqliteAppDatabase implements AppDatabase {
  final DatabaseExecutor _db;

  SqliteAppDatabase._(this._db);

  static Future<SqliteAppDatabase> open({
    required String path,
    DatabaseFactory? factory,
    required int version,
    required Future<void> Function(AppDatabase db, int version) onCreate,
    required Future<void> Function(
      AppDatabase db,
      int oldVersion,
      int newVersion,
    ) onUpgrade,
  }) async {
    final db = await (factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (d, v) async => onCreate(SqliteAppDatabase._(d), v),
        onUpgrade: (d, o, n) async =>
            onUpgrade(SqliteAppDatabase._(d), o, n),
      ),
    );
    return SqliteAppDatabase._(db);
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) => _db.query(
    table,
    columns: columns,
    where: where,
    whereArgs: whereArgs,
    orderBy: orderBy,
    limit: limit,
    offset: offset,
  );

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    DbConflictAlgorithm? conflictAlgorithm,
  }) => _db.insert(table, values, conflictAlgorithm: _mapConflict(conflictAlgorithm));

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) => _db.update(table, values, where: where, whereArgs: whereArgs);

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) => _db.delete(table, where: where, whereArgs: whereArgs);

  @override
  Future<void> execute(String sql) => _db.execute(sql);

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) => _db.rawQuery(sql, arguments);

  @override
  Future<void> transaction(Future<void> Function(AppDatabase txn) action) async {
    final db = _db as Database;
    await db.transaction((txn) async => action(SqliteAppDatabase._(txn)));
  }

  @override
  DbBatch batch() => DbBatch();

  @override
  Future<void> commitBatch(DbBatch dbBatch, {bool noResult = false}) async {
    final db = _db as Database;
    final batch = db.batch();
    for (final op in dbBatch.ops) {
      batch.insert(op.table, op.values,
          conflictAlgorithm: _mapConflict(op.conflictAlgorithm));
    }
    await batch.commit(noResult: noResult);
  }

  @override
  Future<int> getVersion() => (_db as Database).getVersion();

  @override
  Future<void> setVersion(int version) =>
      (_db as Database).setVersion(version);

  @override
  Future<void> close() => (_db as Database).close();
}
