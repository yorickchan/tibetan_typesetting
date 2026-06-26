import 'package:flutter_test/flutter_test.dart';

import 'package:tibetan_typesetting/services/font_service.dart';

void main() {
  group('SystemFontInfo', () {
    test('creates info from native font map', () {
      final info = SystemFontInfo.fromNativeMap({
        'familyName': 'BabelStone Tibetan',
        'filePath': '/Users/test/Library/Fonts/BabelStoneTibetan.ttf',
        'fileType': 'ttf',
      });

      expect(info?.familyName, 'BabelStone Tibetan');
      expect(info?.filePath, '/Users/test/Library/Fonts/BabelStoneTibetan.ttf');
      expect(info?.fileType, 'ttf');
    });

    test('returns null for incomplete native font map', () {
      final info = SystemFontInfo.fromNativeMap({
        'familyName': 'Missing Path',
        'fileType': 'ttf',
      });

      expect(info, isNull);
    });

    test('deduplicates visible font families', () {
      final fonts = deduplicateFamilies([
        const SystemFontInfo(
          familyName: 'New York Large',
          filePath: '/System/Library/Fonts/NewYorkLarge-Regular.otf',
          fileType: 'otf',
        ),
        const SystemFontInfo(
          familyName: 'New York Large',
          filePath: '/System/Library/Fonts/NewYorkLarge-Bold.otf',
          fileType: 'otf',
        ),
        const SystemFontInfo(
          familyName: 'BabelStone Tibetan',
          filePath: '/Library/Fonts/BabelStoneTibetan.ttf',
          fileType: 'ttf',
        ),
      ]);

      expect(fonts.map((font) => font.familyName), [
        'BabelStone Tibetan',
        'New York Large',
      ]);
      expect(fonts.last.filePath, contains('Regular'));
    });
  });
}
