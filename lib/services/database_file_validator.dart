import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

const currentDatabaseVersion = 5;

enum DatabaseValidationIssue {
  notFound,
  notAFile,
  invalidSqlite,
  newerVersion,
  incompatibleSchema,
  directoryAccessRequired,
  unreadable,
}

class DatabaseValidationResult {
  final DatabaseValidationIssue? issue;
  final int? version;

  const DatabaseValidationResult.valid(this.version) : issue = null;

  const DatabaseValidationResult.invalid(this.issue, {this.version});

  bool get isValid => issue == null;
}

class DatabaseFileValidator {
  static const _sqliteHeader = 'SQLite format 3\u0000';
  static const _projectColumns = {
    'id',
    'name',
    'tags_json',
    'project_json',
    'created_at',
    'updated_at',
  };

  final DatabaseFactory databaseFactory;
  final int supportedVersion;

  DatabaseFileValidator({
    required this.databaseFactory,
    this.supportedVersion = currentDatabaseVersion,
  });

  Future<DatabaseValidationResult> validate(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return const DatabaseValidationResult.invalid(
        DatabaseValidationIssue.notFound,
      );
    }
    if (await FileSystemEntity.type(path) != FileSystemEntityType.file) {
      return const DatabaseValidationResult.invalid(
        DatabaseValidationIssue.notAFile,
      );
    }

    try {
      final handle = await file.open();
      final headerBytes = await handle.read(16);
      await handle.close();
      if (headerBytes.length != 16 ||
          latin1.decode(headerBytes) != _sqliteHeader) {
        return const DatabaseValidationResult.invalid(
          DatabaseValidationIssue.invalidSqlite,
        );
      }

      final db = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );
      try {
        final version = await db.getVersion();
        if (version > supportedVersion) {
          return DatabaseValidationResult.invalid(
            DatabaseValidationIssue.newerVersion,
            version: version,
          );
        }
        if (version < 1) {
          return DatabaseValidationResult.invalid(
            DatabaseValidationIssue.incompatibleSchema,
            version: version,
          );
        }
        final rows = await db.rawQuery('PRAGMA table_info(projects)');
        final columns = rows
            .map((row) => row['name'])
            .whereType<String>()
            .toSet();
        if (!columns.containsAll(_projectColumns)) {
          return DatabaseValidationResult.invalid(
            DatabaseValidationIssue.incompatibleSchema,
            version: version,
          );
        }
        return DatabaseValidationResult.valid(version);
      } finally {
        await db.close();
      }
    } on DatabaseException {
      return const DatabaseValidationResult.invalid(
        DatabaseValidationIssue.invalidSqlite,
      );
    } on Object catch (_) {
      return const DatabaseValidationResult.invalid(
        DatabaseValidationIssue.unreadable,
      );
    }
  }
}
