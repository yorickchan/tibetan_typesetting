import 'dart:ui' show Color, TextAlign;

import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/pdf_service_core.dart';

void main() {
  group('tibetanHighlightMask', () {
    test('empty range highlights nothing', () {
      final mask = tibetanHighlightMask('བོད།', '');
      expect(mask.every((v) => v == false), isTrue);
    });

    test('empty text yields empty mask', () {
      expect(tibetanHighlightMask('', '1-2'), isEmpty);
    });

    test('mask length matches text code units', () {
      const text = 'བོད་ཡིག';
      expect(tibetanHighlightMask(text, '1-1').length, text.length);
    });

    test('marks letters of the highlighted syllable only', () {
      // བོད་ཡིག = syllable 1 "བོད་", syllable 2 "ཡིག".
      const text = 'བོད་ཡིག';
      final mask = tibetanHighlightMask(text, '1-1');
      // བ (U+0F56) is a letter, ོ (U+0F7C) is a vowel sign, ད a letter,
      // ་ is tsheg (treated as a letter by the preview).
      expect(mask[0], isTrue, reason: 'first consonant');
      expect(mask[1], isFalse, reason: 'vowel sign is not a letter');
      expect(mask[2], isTrue, reason: 'second consonant');
      expect(mask[3], isTrue, reason: 'tsheg counts as a letter');
      expect(mask[4], isFalse, reason: 'second syllable is not highlighted');
    });

    test('highlight covers later syllables', () {
      const text = 'བོད་ཡིག';
      final mask = tibetanHighlightMask(text, '2-2');
      expect(mask[0], isFalse);
      expect(mask[4], isTrue, reason: 'first char of syllable 2');
    });

    test('multiple ranges are unioned', () {
      const text = 'ཀ་ཁ་ག་ང་';
      final mask = tibetanHighlightMask(text, '1-1,3-3');
      // positions of each letter: 0=ཀ 1=་ 2=ཁ 3=་ 4=ག 5=་ 6=ང 7=་
      expect(mask[0], isTrue);
      expect(mask[2], isFalse);
      expect(mask[4], isTrue);
      expect(mask[6], isFalse);
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

    test('different font family fallback produces different key', () {
      String keyWith(List<String>? fallback) => renderCacheKey(
        text: 'x',
        fontFamily: 'f',
        fontFamilyFallback: fallback,
        fontSize: 12,
        color: const Color(0xFF000000),
        maxWidth: 100,
        lineHeight: null,
        topPadding: 0,
        bottomPadding: 0,
        textAlign: TextAlign.left,
      );

      expect(keyWith(null), isNot(keyWith(['STHeiti'])));
      expect(keyWith(['STHeiti']), isNot(keyWith(['PingFang SC'])));
      expect(keyWith(['STHeiti']), keyWith(['STHeiti']));
    });
  });
}
