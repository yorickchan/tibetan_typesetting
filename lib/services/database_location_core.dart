import 'dart:convert';

import 'database_location_store_native.dart'
    if (dart.library.html) 'database_location_store_web.dart';

export 'database_location_store_native.dart'
    if (dart.library.html) 'database_location_store_web.dart';

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

