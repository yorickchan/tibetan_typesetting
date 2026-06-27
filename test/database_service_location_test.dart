import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tibetan_typesetting/services/database_service.dart';

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
    final service = DatabaseService.withDependencies(
      databaseFactory: databaseFactoryFfi,
      defaultDatabasesPath: () async => directory.path,
    );
    service.configurePath(path, allowCreate: false);

    await expectLater(service.database, throwsA(isA<FileSystemException>()));
    expect(await File(path).exists(), isFalse);
  });

  test('default configuration creates and initializes the database', () async {
    final path = '${directory.path}/default.db';
    final service = DatabaseService.withDependencies(
      databaseFactory: databaseFactoryFfi,
      defaultDatabasesPath: () async => directory.path,
    );
    service.configurePath(path, allowCreate: true);

    final db = await service.database;

    expect(await File(path).exists(), isTrue);
    expect(await db.getVersion(), 5);
    expect(
      await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'projects'",
      ),
      isNotEmpty,
    );
    await db.close();
  });
}
