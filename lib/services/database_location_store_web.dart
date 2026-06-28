import 'dart:convert';
import 'dart:html' as html;

import 'database_location_core.dart';

typedef ApplicationSupportDirectoryProvider = Future<dynamic> Function();

class DatabaseLocationStore {
  final ApplicationSupportDirectoryProvider applicationSupportDirectory;

  const DatabaseLocationStore({required this.applicationSupportDirectory});

  Future<DatabaseLocationPreference> read() async {
    try {
      final stored = html.window.localStorage['database_location'];
      if (stored == null) {
        return const DatabaseLocationPreference.defaultLocation();
      }
      final json = jsonDecode(stored);
      if (json is! Map<String, dynamic>) {
        return const DatabaseLocationPreference.defaultLocation();
      }
      return DatabaseLocationPreference.fromJson(json);
    } on Object catch (_) {
      return const DatabaseLocationPreference.defaultLocation();
    }
  }

  Future<void> write(DatabaseLocationPreference preference) async {
    html.window.localStorage['database_location'] =
        jsonEncode(preference.toJson());
  }
}
