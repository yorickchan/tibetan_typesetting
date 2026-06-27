import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/database_file_validator.dart';
import 'package:tibetan_typesetting/services/database_location_core.dart';
import 'package:tibetan_typesetting/services/database_location_service.dart';

void main() {
  late Directory directory;
  late DatabaseLocationStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('location-service-');
    store = DatabaseLocationStore(
      applicationSupportDirectory: () async => directory,
    );
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('valid selection is persisted', () async {
    final service = DatabaseLocationService(
      store: store,
      validateFile: (_) async =>
          const DatabaseValidationResult.valid(currentDatabaseVersion),
      defaultDatabasePath: () async => '/local/default.db',
    );

    final result = await service.selectExisting('/cloud/library.db');

    expect(result.isValid, isTrue);
    expect(
      await store.read(),
      const DatabaseLocationPreference.custom(path: '/cloud/library.db'),
    );
  });

  test('invalid selection preserves the previous preference', () async {
    const previous = DatabaseLocationPreference.custom(path: '/old/data.db');
    await store.write(previous);
    final service = DatabaseLocationService(
      store: store,
      validateFile: (_) async => const DatabaseValidationResult.invalid(
        DatabaseValidationIssue.invalidSqlite,
      ),
      defaultDatabasePath: () async => '/local/default.db',
    );

    final result = await service.selectExisting('/cloud/not-database.db');

    expect(result.issue, DatabaseValidationIssue.invalidSqlite);
    expect(await store.read(), previous);
  });

  test('macOS selection persists a security-scoped bookmark', () async {
    final bookmarks = _FakeBookmarkService();
    final service = DatabaseLocationService(
      store: store,
      validateFile: (_) async =>
          const DatabaseValidationResult.valid(currentDatabaseVersion),
      defaultDatabasePath: () async => '/local/default.db',
      bookmarkService: bookmarks,
    );

    await service.selectExisting('/cloud/library.db');

    expect(
      await store.read(),
      const DatabaseLocationPreference.custom(
        path: '/cloud/library.db',
        macOsBookmark: 'bookmark:/cloud/library.db',
      ),
    );
  });

  test('startup resolution refreshes a moved bookmarked path', () async {
    await store.write(
      const DatabaseLocationPreference.custom(
        path: '/cloud/old.db',
        macOsBookmark: 'bookmark:/cloud/old.db',
      ),
    );
    final bookmarks = _FakeBookmarkService(resolvedPath: '/cloud/moved.db');
    final service = DatabaseLocationService(
      store: store,
      validateFile: (_) async =>
          const DatabaseValidationResult.valid(currentDatabaseVersion),
      defaultDatabasePath: () async => '/local/default.db',
      bookmarkService: bookmarks,
    );

    final result = await service.resolveForStartup();

    expect(result.path, '/cloud/moved.db');
    expect(result.issue, isNull);
    expect((await store.read()).path, '/cloud/moved.db');
    expect((await store.read()).macOsBookmark, 'refreshed-bookmark');
  });

  test('using default clears the custom location', () async {
    await store.write(
      const DatabaseLocationPreference.custom(path: '/cloud/library.db'),
    );
    final service = DatabaseLocationService(
      store: store,
      validateFile: (_) async =>
          const DatabaseValidationResult.valid(currentDatabaseVersion),
      defaultDatabasePath: () async => '/local/default.db',
    );

    await service.useDefault();
    final result = await service.resolveForStartup();

    expect(result.path, '/local/default.db');
    expect(result.usesDefault, isTrue);
  });
}

class _FakeBookmarkService implements DatabaseBookmarkService {
  final String? resolvedPath;

  _FakeBookmarkService({this.resolvedPath});

  @override
  Future<String> create(String path) async => 'bookmark:$path';

  @override
  Future<ResolvedDatabaseBookmark> resolveAndStartAccess(
    String bookmark,
  ) async => ResolvedDatabaseBookmark(
    path: resolvedPath ?? bookmark.substring('bookmark:'.length),
    bookmark: resolvedPath == null ? bookmark : 'refreshed-bookmark',
  );
}
