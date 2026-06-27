import 'database_file_validator.dart';
import 'database_location_service.dart';

typedef DatabaseLocationResolver = Future<DatabaseStartupResolution> Function();
typedef DatabasePathConfigurator =
    void Function(String path, {required bool allowCreate});
typedef DatabaseOpener = Future<void> Function();

class DatabaseStartupResult {
  final DatabaseValidationIssue? issue;
  final int? version;

  const DatabaseStartupResult.success() : issue = null, version = null;

  const DatabaseStartupResult.failure(this.issue, {this.version});

  bool get isSuccess => issue == null;
}

class DatabaseStartupController {
  final DatabaseLocationResolver resolveLocation;
  final DatabasePathConfigurator configureDatabase;
  final DatabaseOpener openDatabase;

  const DatabaseStartupController({
    required this.resolveLocation,
    required this.configureDatabase,
    required this.openDatabase,
  });

  Future<DatabaseStartupResult> initialize() async {
    final resolution = await resolveLocation();
    if (!resolution.isSuccess) {
      return DatabaseStartupResult.failure(
        resolution.issue,
        version: resolution.version,
      );
    }
    configureDatabase(resolution.path!, allowCreate: resolution.usesDefault);
    try {
      await openDatabase();
      return const DatabaseStartupResult.success();
    } on Object catch (_) {
      return const DatabaseStartupResult.failure(
        DatabaseValidationIssue.unreadable,
      );
    }
  }
}
