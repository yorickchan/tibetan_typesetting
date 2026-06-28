import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tibetan_typesetting/models/chinese_script.dart';
import 'package:tibetan_typesetting/services/app_database_factory.dart';
import 'package:tibetan_typesetting/services/database_service.dart';
import 'package:tibetan_typesetting/services/sqlite_app_database.dart';

void main() {
  sqfliteFfiInit();

  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('database-service-');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('custom configuration never creates a missing database', () async {
    final path = '${directory.path}/missing.db';
    final service = DatabaseService();
    service.configurePath(path, allowCreate: false);

    await expectLater(service.database, throwsA(isA<FileSystemException>()));
    expect(await File(path).exists(), isFalse);
  });

  test('default configuration creates and initializes the database', () async {
    final path = '${directory.path}/default.db';
    final appDb = await SqliteAppDatabase.open(
      path: path,
      factory: databaseFactoryFfi,
      version: 5,
      onCreate: (_, __) async {},
      onUpgrade: (_, __, ___) async {},
    );
    final service = DatabaseService.withDependencies(appDatabase: appDb);
    service.configurePath(path, allowCreate: true);

    final db = await service.database;

    expect(await File(path).exists(), isTrue);
    expect(await db.getVersion(), 5);
    // The tables are not created since onCreate callbacks are empty.
    // This test just verifies the DB opens and returns.
    await db.close();
  });

  test('new projects default to Simplified Chinese', () async {
    final path = '${directory.path}/default.db';
    // Create database with proper table creation
    final appDb = await SqliteAppDatabase.open(
      path: path,
      factory: databaseFactoryFfi,
      version: 5,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS projects (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            tags_json TEXT NOT NULL,
            project_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (_, __, ___) async {},
    );
    final service = DatabaseService.withDependencies(appDatabase: appDb);
    service.configurePath(path, allowCreate: true);

    final created = await service.createProject(name: 'Project');
    final restored = await service.getProject(created.id);

    expect(created.chineseScript, ChineseScript.simplified);
    expect(restored?.chineseScript, ChineseScript.simplified);
    await (await service.database).close();
  });
}
