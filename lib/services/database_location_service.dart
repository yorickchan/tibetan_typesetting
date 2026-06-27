import 'database_file_validator.dart';
import 'database_location_core.dart';

typedef DatabaseFileValidationProvider =
    Future<DatabaseValidationResult> Function(String path);
typedef DefaultDatabasePathProvider = Future<String> Function();

abstract interface class DatabaseBookmarkService {
  Future<String> create(String path);
  Future<ResolvedDatabaseBookmark> resolveAndStartAccess(String bookmark);
}

class ResolvedDatabaseBookmark {
  final String path;
  final String bookmark;

  const ResolvedDatabaseBookmark({required this.path, required this.bookmark});
}

class DatabaseStartupResolution {
  final String? path;
  final bool usesDefault;
  final DatabaseValidationIssue? issue;
  final int? version;

  const DatabaseStartupResolution.success({
    required String this.path,
    required this.usesDefault,
    this.version,
  }) : issue = null;

  const DatabaseStartupResolution.failure({required this.issue, this.version})
    : path = null,
      usesDefault = false;

  bool get isSuccess => issue == null;
}

class DatabaseLocationService {
  final DatabaseLocationStore store;
  final DatabaseFileValidationProvider validateFile;
  final DefaultDatabasePathProvider defaultDatabasePath;
  final DatabaseBookmarkService? bookmarkService;

  const DatabaseLocationService({
    required this.store,
    required this.validateFile,
    required this.defaultDatabasePath,
    this.bookmarkService,
  });

  Future<DatabaseLocationPreference> getPreference() => store.read();

  Future<String> getDisplayPath() async {
    final preference = await store.read();
    return preference.path ?? await defaultDatabasePath();
  }

  Future<DatabaseValidationResult> selectExisting(String path) async {
    final validation = await validateFile(path);
    if (!validation.isValid) return validation;

    String? bookmark;
    try {
      bookmark = await bookmarkService?.create(path);
    } on Object catch (_) {
      return const DatabaseValidationResult.invalid(
        DatabaseValidationIssue.unreadable,
      );
    }
    await store.write(
      DatabaseLocationPreference.custom(path: path, macOsBookmark: bookmark),
    );
    return validation;
  }

  Future<void> useDefault() async {
    await store.write(const DatabaseLocationPreference.defaultLocation());
  }

  Future<DatabaseStartupResolution> resolveForStartup() async {
    final preference = await store.read();
    if (preference.usesDefault) {
      return DatabaseStartupResolution.success(
        path: await defaultDatabasePath(),
        usesDefault: true,
      );
    }

    var path = preference.path!;
    var bookmark = preference.macOsBookmark;
    if (bookmarkService != null && preference.macOsBookmark != null) {
      try {
        final resolved = await bookmarkService!.resolveAndStartAccess(
          preference.macOsBookmark!,
        );
        path = resolved.path;
        bookmark = resolved.bookmark;
      } on Object catch (_) {
        return const DatabaseStartupResolution.failure(
          issue: DatabaseValidationIssue.unreadable,
        );
      }
    }

    final validation = await validateFile(path);
    if (!validation.isValid) {
      return DatabaseStartupResolution.failure(
        issue: validation.issue,
        version: validation.version,
      );
    }
    if (path != preference.path || bookmark != preference.macOsBookmark) {
      await store.write(
        DatabaseLocationPreference.custom(path: path, macOsBookmark: bookmark),
      );
    }
    return DatabaseStartupResolution.success(
      path: path,
      usesDefault: false,
      version: validation.version,
    );
  }
}
