import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tibetan_typesetting/services/database_file_validator.dart';

void main() {
  sqfliteFfiInit();

  late Directory directory;
  late DatabaseFileValidator validator;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('database-validator-');
    validator = DatabaseFileValidator(databaseFactory: databaseFactoryFfi);
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('accepts a compatible application database', () async {
    final path = '${directory.path}/valid.db';
    final db = await databaseFactoryFfi.openDatabase(path);
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        tags_json TEXT NOT NULL,
        project_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.setVersion(5);
    await db.close();

    final result = await validator.validate(path);

    expect(result.isValid, isTrue);
    expect(result.issue, isNull);
    expect(result.version, 5);
  });

  test('rejects a missing file', () async {
    final result = await validator.validate('${directory.path}/missing.db');

    expect(result.issue, DatabaseValidationIssue.notFound);
  });

  test('rejects a non-SQLite file', () async {
    final path = '${directory.path}/invalid.db';
    await File(path).writeAsString('not a database');

    final result = await validator.validate(path);

    expect(result.issue, DatabaseValidationIssue.invalidSqlite);
  });

  test('rejects a database newer than the application', () async {
    final path = '${directory.path}/future.db';
    final db = await databaseFactoryFfi.openDatabase(path);
    await db.execute('CREATE TABLE projects (id TEXT PRIMARY KEY)');
    await db.setVersion(6);
    await db.close();

    final result = await validator.validate(path);

    expect(result.issue, DatabaseValidationIssue.newerVersion);
    expect(result.version, 6);
  });

  test('rejects a database without the complete projects schema', () async {
    final path = '${directory.path}/unrelated.db';
    final db = await databaseFactoryFfi.openDatabase(path);
    await db.execute('CREATE TABLE projects (id TEXT PRIMARY KEY)');
    await db.setVersion(5);
    await db.close();

    final result = await validator.validate(path);

    expect(result.issue, DatabaseValidationIssue.incompatibleSchema);
  });
}
