import 'package:flutter/services.dart';

import 'database_location_service.dart';

class MacOsDatabaseBookmarkService implements DatabaseBookmarkService {
  static const _channel = MethodChannel(
    'tibetan_typesetting/database_bookmarks',
  );

  @override
  Future<String> create(String path) async {
    final bookmark = await _channel.invokeMethod<String>('create', {
      'path': path,
    });
    if (bookmark == null || bookmark.isEmpty) {
      throw PlatformException(code: 'bookmark_creation_failed');
    }
    return bookmark;
  }

  @override
  Future<ResolvedDatabaseBookmark> resolveAndStartAccess(
    String bookmark,
  ) async {
    final resolved = await _channel.invokeMethod<Map<Object?, Object?>>(
      'resolveAndStartAccess',
      {'bookmark': bookmark},
    );
    final path = resolved?['path'] as String?;
    final refreshedBookmark = resolved?['bookmark'] as String?;
    final isDirectory = resolved?['isDirectory'] as bool?;
    if (path == null ||
        path.isEmpty ||
        refreshedBookmark == null ||
        refreshedBookmark.isEmpty ||
        isDirectory == null) {
      throw PlatformException(code: 'bookmark_resolution_failed');
    }
    return ResolvedDatabaseBookmark(
      path: path,
      bookmark: refreshedBookmark,
      isDirectory: isDirectory,
    );
  }
}
