import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/font_service_core.dart';

void main() {
  group('pickCjkFallbackFonts', () {
    test('returns fonts matching patterns in priority order', () {
      final fonts = [
        const SystemFontInfo(
            familyName: 'Arial Unicode MS',
            filePath: '/a.ttf',
            fileType: 'ttf'),
        const SystemFontInfo(
            familyName: 'Noto Sans CJK',
            filePath: '/b.ttf',
            fileType: 'ttf'),
        const SystemFontInfo(
            familyName: 'Helvetica',
            filePath: '/c.ttf',
            fileType: 'ttf'),
      ];
      final picked = pickCjkFallbackFonts(fonts, maxFonts: 2);
      expect(picked.map((f) => f.familyName),
          ['Arial Unicode MS', 'Noto Sans CJK']);
    });

    test('respects maxFonts limit', () {
      final fonts = [
        const SystemFontInfo(
            familyName: 'Arial Unicode MS',
            filePath: '/a.ttf',
            fileType: 'ttf'),
        const SystemFontInfo(
            familyName: 'Noto Sans CJK',
            filePath: '/b.ttf',
            fileType: 'ttf'),
      ];
      expect(pickCjkFallbackFonts(fonts, maxFonts: 1).length, 1);
    });

    test('deduplicates by filePath', () {
      final fonts = [
        const SystemFontInfo(
            familyName: 'Arial Unicode MS',
            filePath: '/a.ttf',
            fileType: 'ttf'),
        const SystemFontInfo(
            familyName: 'Noto Sans CJK',
            filePath: '/a.ttf',
            fileType: 'ttf'),
      ];
      expect(pickCjkFallbackFonts(fonts, maxFonts: 3).length, 1);
    });
  });

  group('resolveFontDirs', () {
    test('macOS includes user Library/Fonts when home given', () {
      final dirs = resolveFontDirs(home: '/Users/test', mac: true);
      expect(dirs, contains('/Users/test/Library/Fonts'));
      expect(dirs, contains('/System/Library/Fonts'));
    });

    test('linux includes .local/share/fonts and .fonts', () {
      final dirs = resolveFontDirs(home: '/home/test', linux: true);
      expect(dirs, contains('/home/test/.local/share/fonts'));
      expect(dirs, contains('/home/test/.fonts'));
    });

    test('windows uses WINDIR default', () {
      final dirs = resolveFontDirs(home: null, win: true);
      expect(dirs, contains(r'C:\Windows\Fonts'));
    });

    test('windows uses provided windir', () {
      final dirs = resolveFontDirs(home: null, windir: r'D:\Win', win: true);
      expect(dirs, contains(r'D:\Win\Fonts'));
    });
  });

  group('fontPriority', () {
    test('regular ranks highest (0)', () {
      expect(
        fontPriority(const SystemFontInfo(
            familyName: 'Regular',
            filePath: '/x-regular.ttf',
            fileType: 'ttf')),
        0,
      );
    });
    test('plain non-bold ranks 1', () {
      expect(
        fontPriority(const SystemFontInfo(
            familyName: 'Body', filePath: '/x.ttf', fileType: 'ttf')),
        1,
      );
    });
    test('bold/italic ranks 2', () {
      expect(
        fontPriority(const SystemFontInfo(
            familyName: 'Body Bold',
            filePath: '/x-bold.ttf',
            fileType: 'ttf')),
        2,
      );
    });
  });

  group('isTtc', () {
    test('identifies ttc magic bytes', () {
      expect(isTtc([0x74, 0x74, 0x63, 0x66, 0x00]), isTrue);
    });
    test('rejects non-ttc', () {
      expect(isTtc([0x00, 0x01, 0x00, 0x00]), isFalse);
    });
    test('rejects too-short input', () {
      expect(isTtc([0x74, 0x74]), isFalse);
    });
  });

  group('extensionLower', () {
    test('extracts lowercase extension', () {
      expect(extensionLower('/path/to/font.TTF'), '.ttf');
    });
    test('returns empty for no extension', () {
      expect(extensionLower('/path/to/font'), '');
    });
  });

  group('deduplicateFamilies', () {
    test('keeps highest-priority font per family, sorted', () {
      final fonts = [
        const SystemFontInfo(
            familyName: 'New York Large',
            filePath: '/System/Library/Fonts/NewYorkLarge-Bold.otf',
            fileType: 'otf'),
        const SystemFontInfo(
            familyName: 'New York Large',
            filePath: '/System/Library/Fonts/NewYorkLarge-Regular.otf',
            fileType: 'otf'),
        const SystemFontInfo(
            familyName: 'BabelStone Tibetan',
            filePath: '/Library/Fonts/BabelStoneTibetan.ttf',
            fileType: 'ttf'),
      ];
      final deduped = deduplicateFamilies(fonts);
      expect(deduped.map((f) => f.familyName),
          ['BabelStone Tibetan', 'New York Large']);
      expect(deduped.last.filePath, contains('Regular'));
    });

    test('skips empty family names', () {
      final fonts = [
        const SystemFontInfo(
            familyName: '  ',
            filePath: '/a.ttf',
            fileType: 'ttf'),
      ];
      expect(deduplicateFamilies(fonts), isEmpty);
    });
  });
}
