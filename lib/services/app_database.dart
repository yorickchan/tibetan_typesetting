enum DbConflictAlgorithm { replace, ignore, rollback, abort, fail }

class DbBatch {
  final List<_BatchOp> _ops = [];

  void insert(
    String table,
    Map<String, Object?> values, {
    DbConflictAlgorithm? conflictAlgorithm,
  }) {
    _ops.add(_BatchOp.insert(table, values, conflictAlgorithm: conflictAlgorithm));
  }
  Iterable<_BatchOp> get ops => _ops;
}

class _BatchOp {
  final _BatchOpType type;
  final String table;
  final Map<String, Object?> values;
  final DbConflictAlgorithm? conflictAlgorithm;

  _BatchOp.insert(this.table, this.values, {this.conflictAlgorithm})
    : type = _BatchOpType.insert;
}

enum _BatchOpType { insert }

abstract class AppDatabase {
  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  });

  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    DbConflictAlgorithm? conflictAlgorithm,
  });

  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  });

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  });

  Future<void> execute(String sql);

  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]);

  Future<void> transaction(Future<void> Function(AppDatabase txn) action);

  DbBatch batch();
  Future<void> commitBatch(DbBatch batch, {bool noResult = false});

  Future<int> getVersion();
  Future<void> setVersion(int version);
  Future<void> close();
}
