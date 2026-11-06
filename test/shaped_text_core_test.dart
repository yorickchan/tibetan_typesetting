import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/utils/shaped_text_core.dart';

void main() {
  group('canBreakAfterRune', () {
    test('allows a break after space and tab', () {
      expect(canBreakAfterRune(0x20), isTrue);
      expect(canBreakAfterRune(0x09), isTrue);
    });

    test('allows a break after tsheg', () {
      expect(canBreakAfterRune(0x0F0B), isTrue);
      expect(canBreakAfterRune(0x0F0C), isTrue);
    });

    test('allows a break after shad', () {
      expect(canBreakAfterRune(0x0F0D), isTrue);
      expect(canBreakAfterRune(0x0F0E), isTrue);
    });

    test('does not break inside a Tibetan syllable', () {
      // བ (letter), ོ (vowel sign), ད (letter), ུ (vowel sign).
      expect(canBreakAfterRune(0x0F56), isFalse);
      expect(canBreakAfterRune(0x0F7C), isFalse);
      expect(canBreakAfterRune(0x0F51), isFalse);
      expect(canBreakAfterRune(0x0F74), isFalse);
    });

    test('allows breaks between CJK characters', () {
      expect(canBreakAfterRune(0x4E2D), isTrue);
      expect(canBreakAfterRune(0xFF0C), isTrue);
    });

    test('does not break after Latin letters', () {
      expect(canBreakAfterRune(0x61), isFalse);
    });
  });

  group('lineBreakOpportunities', () {
    test('empty text has only the end break', () {
      expect(lineBreakOpportunities(''), {0});
    });

    test('always includes the end of the text', () {
      const text = 'བོད';
      expect(lineBreakOpportunities(text), contains(text.length));
    });

    test('breaks only between syllables', () {
      // ཀ་ཁ = ཀ ་ ཁ ; the only break is after the tsheg.
      const text = 'ཀ་ཁ';
      expect(lineBreakOpportunities(text), {2, 3});
    });

    test('excludes positions inside a stacked syllable', () {
      // ཧཱུྃ = ཧ + ཱ + ུ + ྃ, one indivisible cluster.
      const text = 'ཧཱུྃ';
      expect(lineBreakOpportunities(text), {text.length});
    });
  });
}
