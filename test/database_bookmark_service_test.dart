import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/database_bookmark_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('tibetan_typesetting/database_bookmarks');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'create' => 'stored-bookmark',
            'resolveAndStartAccess' => {
              'path': '/cloud',
              'bookmark': 'refreshed-bookmark',
              'isDirectory': true,
            },
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('creates a bookmark for a selected path', () async {
    final service = MacOsDatabaseBookmarkService();

    final bookmark = await service.create('/cloud');

    expect(bookmark, 'stored-bookmark');
    expect(calls.single.method, 'create');
    expect(calls.single.arguments, {'path': '/cloud'});
  });

  test('resolves a bookmark and starts persistent access', () async {
    final service = MacOsDatabaseBookmarkService();

    final resolved = await service.resolveAndStartAccess('stored-bookmark');

    expect(resolved.path, '/cloud');
    expect(resolved.bookmark, 'refreshed-bookmark');
    expect(resolved.isDirectory, isTrue);
    expect(calls.single.method, 'resolveAndStartAccess');
    expect(calls.single.arguments, {'bookmark': 'stored-bookmark'});
  });
}
