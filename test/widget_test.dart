import 'package:flutter_test/flutter_test.dart';

import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/models/font_config.dart';
import 'package:tibetan_typesetting/utils/sample_layout.dart';
import 'package:tibetan_typesetting/utils/font_constants.dart';

void main() {
  group('resolvePageNumber', () {
    test('returns index + 1 for empty string', () {
      expect(resolvePageNumber('', 0), '1');
      expect(resolvePageNumber('   ', 5), '6');
    });

    test('increments numeric base by index', () {
      expect(resolvePageNumber('1', 0), '1');
      expect(resolvePageNumber('1', 1), '2');
      expect(resolvePageNumber('10', 5), '15');
    });

    test('returns non-numeric base as-is', () {
      expect(resolvePageNumber('甲', 0), '甲');
      expect(resolvePageNumber('Page A', 3), 'Page A');
    });
  });

  group('splitLines', () {
    test('splits and trims', () {
      expect(splitLines('a\nb\n'), ['a', 'b']);
      expect(splitLines(''), []);
      expect(splitLines('  hello  '), ['hello']);
    });

    test('handles Windows line endings', () {
      expect(splitLines('a\r\nb\r\nc'), ['a', 'b', 'c']);
    });

    test('filters empty lines', () {
      expect(splitLines('a\n\nb\n  \nc'), ['a', 'b', 'c']);
    });
  });

  group('paginateBlocks', () {
    test('returns at least one page for empty blocks', () {
      final pages = paginateBlocks([], 5);
      expect(pages.length, 1);
      expect(pages[0].rows, isEmpty);
    });

    test('paginates correctly', () {
      final blocks = List.generate(
        12,
        (i) => TextBlock(id: 'b$i', tibetan: 'text $i'),
      );
      final pages = paginateBlocks(blocks, 3, 4);
      expect(pages.length, 1);
      expect(pages[0].rows.length, 4);
      expect(pages[0].colCount, 3);
    });

    test('splits into multiple pages when exceeding maxRows', () {
      final blocks = List.generate(
        20,
        (i) => TextBlock(id: 'b$i', tibetan: 'text $i'),
      );
      final pages = paginateBlocks(blocks, 3, 4);
      expect(pages.length, greaterThan(1));
    });

    test('respects pageBreakBefore', () {
      final blocks = [
        TextBlock(id: 'b1', tibetan: 'text 1'),
        TextBlock(id: 'b2', tibetan: 'text 2', pageBreakBefore: true),
        TextBlock(id: 'b3', tibetan: 'text 3'),
      ];
      final pages = paginateBlocks(blocks, 3, 4);
      expect(pages.length, 2);
    });
  });

  group('blocksToRows', () {
    test('pads rows to column count', () {
      final blocks = [
        TextBlock(id: 'b1', tibetan: 'text 1'),
        TextBlock(id: 'b2', tibetan: 'text 2'),
      ];
      final rows = blocksToRows(blocks, 5);
      expect(rows.length, 1);
      expect(rows[0].length, 5);
      expect(rows[0][0]?.id, 'b1');
      expect(rows[0][1]?.id, 'b2');
      expect(rows[0][2], isNull);
    });
  });

  group('TextBlock', () {
    test('serializes to and from JSON', () {
      final block = TextBlock(
        id: 'test-id',
        tibetan: 'བོད་སྐད',
        chinesePronunciation: 'bod skad',
        chineseTranslation: '藏语',
        pageBreakBefore: true,
        columnBreakBefore: false,
        smallText: true,
      );

      final json = block.toJson();
      final restored = TextBlock.fromJson(json);

      expect(restored.id, block.id);
      expect(restored.tibetan, block.tibetan);
      expect(restored.chinesePronunciation, block.chinesePronunciation);
      expect(restored.chineseTranslation, block.chineseTranslation);
      expect(restored.pageBreakBefore, block.pageBreakBefore);
      expect(restored.columnBreakBefore, block.columnBreakBefore);
      expect(restored.smallText, block.smallText);
    });

    test('copyWith creates modified copy', () {
      final block = TextBlock(id: 'test', tibetan: 'original');
      final modified = block.copyWith(tibetan: 'modified');

      expect(block.tibetan, 'original');
      expect(modified.tibetan, 'modified');
      expect(modified.id, 'test');
    });
  });

  group('PageSetup', () {
    test('serializes to and from JSON', () {
      final setup = PageSetup(
        pageWidthMm: 300,
        pageHeightMm: 120,
        columnCount: 5,
        showFrame: true,
        pageNumber: '1',
        showTitlePage: true,
        titleTibetan: 'མགོ་མ格外',
        titleChinese: '标题',
        tibetanFont: const FontConfig(
          fontFamily: 'TestFont',
          fontPath: '/path/to/font.ttf',
          fontSize: 12,
        ),
      );

      final json = setup.toJson();
      final restored = PageSetup.fromJson(json);

      expect(restored.pageWidthMm, setup.pageWidthMm);
      expect(restored.pageHeightMm, setup.pageHeightMm);
      expect(restored.columnCount, setup.columnCount);
      expect(restored.showFrame, setup.showFrame);
      expect(restored.pageNumber, setup.pageNumber);
      expect(restored.showTitlePage, setup.showTitlePage);
      expect(restored.titleTibetan, setup.titleTibetan);
      expect(restored.titleChinese, setup.titleChinese);
      expect(restored.tibetanFont?.fontFamily, 'TestFont');
    });

    test('copyWith clears font with clear flag', () {
      final setup = PageSetup(
        tibetanFont: const FontConfig(
          fontFamily: 'Test',
          fontPath: '',
          fontSize: 10,
        ),
      );

      final cleared = setup.copyWith(clearTibetanFont: true);
      expect(cleared.tibetanFont, isNull);
    });
  });

  group('Project', () {
    test('serializes to and from JSON', () {
      final project = Project(
        id: 'proj-1',
        name: 'Test Project',
        tags: ['tag1', 'tag2'],
        blocks: [TextBlock(id: 'b1', tibetan: 'text')],
        pageSetup: PageSetup(columnCount: 4),
        updatedAt: '2024-01-01T00:00:00Z',
        createdAt: '2024-01-01T00:00:00Z',
      );

      final json = project.toJson();
      final restored = Project.fromJson(json);

      expect(restored.id, project.id);
      expect(restored.name, project.name);
      expect(restored.tags, project.tags);
      expect(restored.blocks.length, 1);
      expect(restored.pageSetup.columnCount, 4);
    });

    test('fromJsonString parses JSON string', () {
      final jsonStr = '''
        {
          "id": "proj-1",
          "name": "Test",
          "tags": [],
          "blocks": [],
          "pageSetup": {"columnCount": 5},
          "updatedAt": "2024-01-01T00:00:00Z",
          "createdAt": "2024-01-01T00:00:00Z"
        }
      ''';

      final project = Project.fromJsonString(jsonStr);
      expect(project.id, 'proj-1');
      expect(project.name, 'Test');
    });

    test('copyWith creates deep copy', () {
      final project = Project(
        id: 'p1',
        name: 'Original',
        blocks: [TextBlock(id: 'b1', tibetan: 'text')],
        updatedAt: '2024-01-01T00:00:00Z',
        createdAt: '2024-01-01T00:00:00Z',
      );

      final copy = project.copyWith(name: 'Modified');
      expect(project.name, 'Original');
      expect(copy.name, 'Modified');
      expect(copy.blocks.first.id, 'b1');
    });
  });

  group('MarginMm', () {
    test('serializes to and from JSON', () {
      final margin = MarginMm(top: 15, right: 20, bottom: 15, left: 20);
      final json = margin.toJson();
      final restored = MarginMm.fromJson(json);

      expect(restored.top, 15);
      expect(restored.right, 20);
      expect(restored.bottom, 15);
      expect(restored.left, 20);
    });
  });

  group('FontConfig', () {
    test('serializes to and from JSON', () {
      const config = FontConfig(
        fontFamily: 'BabelStoneTibetan',
        fontPath: '/Library/Fonts/BabelStone.ttf',
        fontSize: 14.5,
      );

      final json = config.toJson();
      final restored = FontConfig.fromJson(json);

      expect(restored.fontFamily, 'BabelStoneTibetan');
      expect(restored.fontPath, '/Library/Fonts/BabelStone.ttf');
      expect(restored.fontSize, 14.5);
    });

    test('fallback constants are valid', () {
      expect(fallbackTibetanFont.fontFamily, 'BabelStoneTibetan');
      expect(fallbackChineseFont.fontFamily, 'STHeiti');
      expect(fallbackTibetanFont.fontSize, greaterThan(0));
      expect(fallbackChineseFont.fontSize, greaterThan(0));
    });
  });
}
