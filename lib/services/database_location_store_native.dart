import 'dart:convert';
import 'dart:io';

import 'database_location_core.dart';

typedef ApplicationSupportDirectoryProvider = Future<Directory> Function();

class DatabaseLocationStore {
  final ApplicationSupportDirectoryProvider applicationSupportDirectory;

  const DatabaseLocationStore({required this.applicationSupportDirectory});

  Future<File> get _file async {
    final directory = await applicationSupportDirectory();
    await directory.create(recursive: true);
    return File(
      '${directory.path}${Platform.pathSeparator}database_location.json',
    );
  }

  Future<DatabaseLocationPreference> read() async {
    try {
      final file = await _file;
      if (!await file.exists()) {
        return const DatabaseLocationPreference.defaultLocation();
      }
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) {
        return const DatabaseLocationPreference.defaultLocation();
      }
      return DatabaseLocationPreference.fromJson(json);
    } on Object catch (_) {
      return const DatabaseLocationPreference.defaultLocation();
    }
  }

  Future<void> write(DatabaseLocationPreference preference) async {
    final file = await _file;
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(preference.toJson()), flush: true);
    await temporary.rename(file.path);
  }
}
