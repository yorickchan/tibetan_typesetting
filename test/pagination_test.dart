import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/utils/sample_layout.dart';

void main() {
  group('paginateBlocks', () {
    test('empty blocks returns single empty page', () {
      final pages = paginateBlocks([], 5);
      
      expect(pages.length, 1);
      expect(pages[0].flowRows, isEmpty);
    });

    test('single block returns single page with one row', () {
      final blocks = [TextBlock(id: 'block1', tibetan: 'བོད་སྐད')];
      final pages = paginateBlocks(blocks, 5);
      
      expect(pages.length, 1);
      expect(pages[0].flowRows.length, 1);
      expect(pages[0].flowRows[0].length, 1);
      expect(pages[0].flowRows[0][0].block.id, 'block1');
    });

    test('page break creates new page', () {
      final blocks = [
        TextBlock(id: 'block1', tibetan: 'བོད་སྐད'),
        TextBlock(id: 'block2', tibetan: 'བོད་ཡིག', pageBreakBefore: true),
      ];
      final pages = paginateBlocks(blocks, 5);
      
      expect(pages.length, 2);
      expect(pages[0].flowRows.length, 1);
      expect(pages[1].flowRows.length, 1);
    });

    test('column break creates new row', () {
      final blocks = [
        TextBlock(id: 'block1', tibetan: 'བོད་སྐད'),
        TextBlock(id: 'block2', tibetan: 'བོད་ཡིག', columnBreakBefore: true),
      ];
      final pages = paginateBlocks(blocks, 5);
      
      expect(pages.length, 1);
      expect(pages[0].flowRows.length, 2);
    });

    test('respects maxRows per page', () {
      // Create blocks with column breaks to force multiple rows
      final blocks = <TextBlock>[];
      for (var i = 0; i < 10; i++) {
        blocks.add(TextBlock(
          id: 'block$i',
          tibetan: 'བོད་སྐད',
          columnBreakBefore: i > 0 && i % 2 == 0,
        ));
      }
      final pages = paginateBlocks(blocks, 5, 4);
      
      // Should create multiple pages with max 4 rows each
      expect(pages.length, greaterThan(1));
      for (final page in pages) {
        expect(page.flowRows.length, lessThanOrEqualTo(4));
      }
    });
  });

  group('estimateBlockWidthFraction', () {
    test('block with columnSpan uses manual span', () {
      final block = TextBlock(id: 'test', columnSpan: 3);
      final fraction = estimateBlockWidthFraction(block);
      
      expect(fraction, closeTo(3 / 24, 0.01));
    });

    test('empty block returns minimum fraction', () {
      final block = TextBlock(id: 'test');
      final fraction = estimateBlockWidthFraction(block);
      
      expect(fraction, greaterThanOrEqualTo(0.09));
    });

    test('long text returns larger fraction', () {
      final shortBlock = TextBlock(id: 'short', tibetan: 'བོད');
      final longBlock = TextBlock(id: 'long', tibetan: 'བོད་སྐད་ཆེན་པོ་ཞིག');
      
      final shortFraction = estimateBlockWidthFraction(shortBlock);
      final longFraction = estimateBlockWidthFraction(longBlock);
      
      expect(longFraction, greaterThan(shortFraction));
    });

  test('image blocks are included in pagination', () {
    final blocks = [
      TextBlock(id: 'img', imagePath: '/tmp/test.png'),
      TextBlock(id: 'text', tibetan: 'བཀྲ་ཤིས།'),
    ];
    final pages = paginateBlocks(blocks, 0, 4, 0.01);
    expect(pages.isNotEmpty, true);
    // Image block should appear somewhere
    var foundImage = false;
    for (final page in pages) {
      for (final row in page.flowRows) {
        for (final cell in row) {
          if (cell.block.isImageBlock) foundImage = true;
        }
      }
    }
    expect(foundImage, true);
  });

  test('image blocks get minimum width fraction', () {
    final block = TextBlock(id: 'img', imagePath: '/tmp/test.png');
    final fraction = estimateBlockWidthFraction(block);
    expect(fraction, greaterThanOrEqualTo(0.09));
    expect(fraction, lessThanOrEqualTo(0.15));
  });

  });

  group('splitLines', () {
    test('splits by newline', () {
      final lines = splitLines('line1\nline2\nline3');
      
      expect(lines.length, 3);
      expect(lines[0], 'line1');
      expect(lines[1], 'line2');
      expect(lines[2], 'line3');
    });

    test('trims whitespace', () {
      final lines = splitLines('  line1  \n  line2  ');
      
      expect(lines[0], 'line1');
      expect(lines[1], 'line2');
    });

    test('filters empty lines', () {
      final lines = splitLines('line1\n\n\nline2');
      
      expect(lines.length, 2);
    });
  });
}
