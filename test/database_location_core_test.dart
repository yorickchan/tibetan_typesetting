import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/database_location_core.dart';

void main() {
  group('DatabaseLocationPreference', () {
    test('default location round-trips through JSON', () {
      const preference = DatabaseLocationPreference.defaultLocation();

      final restored = DatabaseLocationPreference.fromJson(preference.toJson());

      expect(restored, preference);
      expect(restored.usesDefault, isTrue);
    });

    test('custom location round-trips path and bookmark', () {
      const preference = DatabaseLocationPreference.custom(
        path: '/cloud/library.db',
        macOsBookmark: 'bookmark-data',
      );

      final restored = DatabaseLocationPreference.fromJson(preference.toJson());

      expect(restored, preference);
      expect(restored.usesDefault, isFalse);
    });

    test('invalid JSON falls back to the default location', () {
      final restored = DatabaseLocationPreference.fromJson({
        'kind': 'custom',
        'path': '',
      });

      expect(restored, const DatabaseLocationPreference.defaultLocation());
    });
  });

  group('DatabaseLocationStore', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('database-location-');
    });

    tearDown(() async {
      await directory.delete(recursive: true);
    });

    test('returns the default when no bootstrap file exists', () async {
      final store = DatabaseLocationStore(
        applicationSupportDirectory: () async => directory,
      );

      expect(
        await store.read(),
        const DatabaseLocationPreference.defaultLocation(),
      );
    });

    test('persists and reloads a custom location', () async {
      final store = DatabaseLocationStore(
        applicationSupportDirectory: () async => directory,
      );
      const preference = DatabaseLocationPreference.custom(
        path: '/cloud/library.db',
        macOsBookmark: 'bookmark-data',
      );

      await store.write(preference);

      expect(await store.read(), preference);
    });

    test('corrupt bootstrap content falls back to default', () async {
      final store = DatabaseLocationStore(
        applicationSupportDirectory: () async => directory,
      );
      await File(
        '${directory.path}/database_location.json',
      ).writeAsString('not-json');

      expect(
        await store.read(),
        const DatabaseLocationPreference.defaultLocation(),
      );
    });
  });
}
