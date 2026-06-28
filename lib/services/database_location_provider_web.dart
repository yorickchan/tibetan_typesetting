// ignore_for_file: argument_type_not_assignable

import 'database_file_validator.dart';
import 'database_location_core.dart';
import 'database_location_service.dart';

DatabaseLocationService createDatabaseLocationService() {
  return DatabaseLocationService(
    store: DatabaseLocationStore(
      applicationSupportDirectory: _webNoop,
    ),
    validateFile: (_) async => const DatabaseValidationResult.valid(null),
    defaultDatabasePath: () async => 'tibetan_typesetting',
    bookmarkService: null,
  );
}

Future<dynamic> _webNoop() async {}
