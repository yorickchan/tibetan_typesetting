import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/utils/sample_layout.dart';

void main() {
  group('BlockWidthEstimate', () {
    test('classifies image blocks', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 'img', imagePath: '/x.png', imageWidthMm: 50),
      );
      expect(estimate, isA<ImageWidth>());
      expect((estimate as ImageWidth).widthMm, 50);
    });

    test('classifies manual column span blocks', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 'm', columnSpan: 8),
      );
      expect(estimate, isA<ManualWidth>());
      expect((estimate as ManualWidth).span, 8);
    });

    test('classifies opening mark blocks', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 'om', format: TextBlockFormat.openingMark),
      );
      expect(estimate, isA<OpeningMarkWidth>());
    });

    test('classifies text blocks', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 't', tibetan: 'བོད།'),
      );
      expect(estimate, isA<TextWidth>());
    });

    test('image fraction uses widthMm when contentWidthMm given', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 'img', imagePath: '/x.png', imageWidthMm: 50),
      );
      expect(estimate.fraction(100), closeTo(0.5, 0.0001));
    });

    test('image fraction falls back to 0.45 without contentWidthMm', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 'img', imagePath: '/x.png'),
      );
      expect(estimate.fraction(null), 0.45);
    });

    test('manual span clamps to maxColumnSpan', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 'm', columnSpan: 25),
      );
      expect(estimate.fraction(), closeTo(1.0, 0.0001));
    });

    test('opening mark is 2/maxColumnSpan', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 'om', format: TextBlockFormat.openingMark),
      );
      expect(estimate.fraction(), 2.0 / maxColumnSpan);
    });
  });

  group('_buildRows via paginateBlocks', () {
    test('packs blocks into rows respecting 1.0 width limit', () {
      final blocks = List.generate(
        10,
        (i) => TextBlock(id: 'b$i', tibetan: 'text $i', columnSpan: 8),
      );
      final pages = paginateBlocks(blocks, 4, 4);
      final rows = pages[0].flowRows;
      expect(rows.length, greaterThan(1));
      for (final row in rows) {
        final totalWidth = row.fold<double>(
          0,
          (sum, cell) => sum + cell.widthFraction,
        );
        expect(totalWidth, lessThanOrEqualTo(1.0 + 0.0001));
      }
    });

    test('pageBreakBefore on empty start sets pending break', () {
      final blocks = [
        TextBlock(id: 'b1', tibetan: 'a', pageBreakBefore: true),
      ];
      final pages = paginateBlocks(blocks, 4, 4);
      expect(pages.length, 1);
      expect(pages[0].flowRows[0].single.block.id, 'b1');
    });

    test('floating images are excluded from rows', () {
      final blocks = [
        TextBlock(id: 'b1', tibetan: 'a'),
        TextBlock(id: 'float', tibetan: '', floatingImage: true),
        TextBlock(id: 'b2', tibetan: 'b'),
      ];
      final pages = paginateBlocks(blocks, 4, 4);
      final allBlockIds = pages
          .expand((p) => p.flowRows)
          .expand((r) => r)
          .map((c) => c.block.id)
          .toList();
      expect(allBlockIds, isNot(contains('float')));
    });
  });
}
