import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/database_file_validator.dart';
import 'package:tibetan_typesetting/services/database_location_service.dart';
import 'package:tibetan_typesetting/services/database_startup_controller.dart';

void main() {
  test('configures and opens a resolved custom database', () async {
    String? configuredPath;
    bool? configuredAllowCreate;
    var opened = false;
    final controller = DatabaseStartupController(
      resolveLocation: () async => const DatabaseStartupResolution.success(
        path: '/cloud/library.db',
        usesDefault: false,
      ),
      configureDatabase: (path, {required allowCreate}) {
        configuredPath = path;
        configuredAllowCreate = allowCreate;
      },
      openDatabase: () async => opened = true,
    );

    final result = await controller.initialize();

    expect(result.isSuccess, isTrue);
    expect(configuredPath, '/cloud/library.db');
    expect(configuredAllowCreate, isFalse);
    expect(opened, isTrue);
  });

  test('returns the location failure without opening SQLite', () async {
    var opened = false;
    final controller = DatabaseStartupController(
      resolveLocation: () async => const DatabaseStartupResolution.failure(
        issue: DatabaseValidationIssue.notFound,
      ),
      configureDatabase: (_, {required allowCreate}) {},
      openDatabase: () async => opened = true,
    );

    final result = await controller.initialize();

    expect(result.issue, DatabaseValidationIssue.notFound);
    expect(opened, isFalse);
  });

  test('converts database open errors into an unreadable failure', () async {
    final controller = DatabaseStartupController(
      resolveLocation: () async => const DatabaseStartupResolution.success(
        path: '/cloud/library.db',
        usesDefault: false,
      ),
      configureDatabase: (_, {required allowCreate}) {},
      openDatabase: () async => throw Exception('cannot open'),
    );

    final result = await controller.initialize();

    expect(result.issue, DatabaseValidationIssue.unreadable);
  });
}
