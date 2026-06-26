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
}
