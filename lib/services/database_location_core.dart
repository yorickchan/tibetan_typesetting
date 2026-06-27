import 'dart:convert';
import 'dart:io';

typedef ApplicationSupportDirectoryProvider = Future<Directory> Function();

class DatabaseLocationPreference {
  final String? path;
  final String? macOsBookmark;

  const DatabaseLocationPreference.defaultLocation()
    : path = null,
      macOsBookmark = null;

  const DatabaseLocationPreference.custom({
    required String this.path,
    this.macOsBookmark,
  });

  bool get usesDefault => path == null;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'kind': usesDefault ? 'default' : 'custom',
    if (path != null) 'path': path,
    if (macOsBookmark != null) 'macOsBookmark': macOsBookmark,
  };

  factory DatabaseLocationPreference.fromJson(Map<String, dynamic> json) {
    if (json['kind'] != 'custom') {
      return const DatabaseLocationPreference.defaultLocation();
    }
    final path = json['path'];
    if (path is! String || path.trim().isEmpty) {
      return const DatabaseLocationPreference.defaultLocation();
    }
    final bookmark = json['macOsBookmark'];
    return DatabaseLocationPreference.custom(
      path: path,
      macOsBookmark: bookmark is String && bookmark.isNotEmpty
          ? bookmark
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatabaseLocationPreference &&
          path == other.path &&
          macOsBookmark == other.macOsBookmark;

  @override
  int get hashCode => Object.hash(path, macOsBookmark);
}

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
