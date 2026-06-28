import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;

import 'app_database.dart';
import 'indexed_db_app_database.dart';
import 'sqlite_app_database.dart';

Future<AppDatabase> createAppDatabase({
  required String name,
  required int version,
  String? path,
  required Future<void> Function(AppDatabase db, int version) onCreate,
  required Future<void> Function(AppDatabase db, int oldVersion, int newVersion)
      onUpgrade,
}) async {
  if (kIsWeb) {
    return IndexedDbAppDatabase.open(
      name: name,
      version: version,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
  } else {
    final dbPath = path ?? p.join(await getDatabasesPath(), '$name.db');
    return SqliteAppDatabase.open(
      path: dbPath,
      version: version,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
  }
}
