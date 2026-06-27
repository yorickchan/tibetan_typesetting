import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'database_bookmark_service.dart';
import 'database_file_validator.dart';
import 'database_location_core.dart';
import 'database_location_service.dart';

DatabaseLocationService createDatabaseLocationService() {
  final validator = DatabaseFileValidator(databaseFactory: databaseFactory);
  return DatabaseLocationService(
    store: const DatabaseLocationStore(
      applicationSupportDirectory: getApplicationSupportDirectory,
    ),
    validateFile: validator.validate,
    defaultDatabasePath: () async =>
        '${await getDatabasesPath()}/tibetan_typesetting.db',
    bookmarkService: Platform.isMacOS ? MacOsDatabaseBookmarkService() : null,
  );
}
