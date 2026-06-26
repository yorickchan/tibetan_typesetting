import 'dart:ui' show Color, TextAlign;

import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/pdf_service_core.dart';

void main() {
  group('makeColorizedSpans', () {
    test('single color text returns one span', () {
      final spans = makeColorizedSpans(
        'abc',
        const Color(0xFF000000),
        const Color(0xFF000000),
      );
      expect(spans.length, 1);
      expect(spans.first.text, 'abc');
    });

    test('splits Tibetan letters from non-letters', () {
      const letter = Color(0xFF000000);
      const other = Color(0xFFFF0000);
      final spans = makeColorizedSpans('བོད།', letter, other);
      expect(spans.length, greaterThan(1));
      expect(spans.every((s) => s.color == letter || s.color == other), isTrue);
    });

    test('consecutive same-color chars merge into one span', () {
      final spans = makeColorizedSpans(
        'aaa',
        const Color(0xFF000000),
        const Color(0xFF000000),
      );
      expect(spans.length, 1);
    });

    test('empty text returns no spans', () {
      final spans = makeColorizedSpans(
        '',
        const Color(0xFF000000),
        const Color(0xFFFF0000),
      );
      expect(spans, isEmpty);
    });
  });

  group('renderCacheKey', () {
    test('produces stable key for same inputs', () {
      const args = (
        text: 'x',
        fontFamily: 'f',
        fontSize: 12.0,
        color: Color(0xFF000000),
        maxWidth: 100.0,
        lineHeight: null,
        topPadding: 0.0,
        bottomPadding: 0.0,
        textAlign: TextAlign.left,
      );
      final k1 = renderCacheKey(
        text: args.text,
        fontFamily: args.fontFamily,
        fontSize: args.fontSize,
        color: args.color,
        maxWidth: args.maxWidth,
        lineHeight: args.lineHeight,
        topPadding: args.topPadding,
        bottomPadding: args.bottomPadding,
        textAlign: args.textAlign,
      );
      final k2 = renderCacheKey(
        text: args.text,
        fontFamily: args.fontFamily,
        fontSize: args.fontSize,
        color: args.color,
        maxWidth: args.maxWidth,
        lineHeight: args.lineHeight,
        topPadding: args.topPadding,
        bottomPadding: args.bottomPadding,
        textAlign: args.textAlign,
      );
      expect(k1, k2);
    });

    test('different text produces different key', () {
      final k1 = renderCacheKey(
        text: 'x',
        fontFamily: 'f',
        fontSize: 12,
        color: const Color(0xFF000000),
        maxWidth: 100,
        lineHeight: null,
        topPadding: 0,
        bottomPadding: 0,
        textAlign: TextAlign.left,
      );
      final k2 = renderCacheKey(
        text: 'y',
        fontFamily: 'f',
        fontSize: 12,
        color: const Color(0xFF000000),
        maxWidth: 100,
        lineHeight: null,
        topPadding: 0,
        bottomPadding: 0,
        textAlign: TextAlign.left,
      );
      expect(k1, isNot(k2));
    });
  });
}
