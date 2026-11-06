
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/pdf_service_core.dart';

void main() {
  group('pdfLineSpacing', () {
    test('adds nothing when the font already advances the wanted distance', () {
      // Kaiti: ascent 1.06, descent -0.34 => natural 1.4 em.
      expect(
        pdfLineSpacing(
          ascent: 1.06,
          descent: -0.34,
          fontSize: 8,
          lineHeight: 1.4,
        ),
        closeTo(0, 1e-9),
      );
    });

    test('adds the shortfall for fonts with a tighter natural line', () {
      // MingLiU: ascent 0.80078, descent -0.19922 => natural 1.0 em,
      // wanted 1.4 em, so 0.4 em of extra spacing.
      expect(
        pdfLineSpacing(
          ascent: 0.80078125,
          descent: -0.19921875,
          fontSize: 8,
          lineHeight: 1.4,
        ),
        closeTo(3.2, 1e-9),
      );
    });

    test('never returns a negative spacing', () {
      expect(
        pdfLineSpacing(
          ascent: 2,
          descent: 0,
          fontSize: 10,
          lineHeight: 1.0,
        ),
        0,
      );
    });

    test('scales with font size', () {
      final small = pdfLineSpacing(
        ascent: 0.8,
        descent: -0.2,
        fontSize: 8,
        lineHeight: 1.4,
      );
      final large = pdfLineSpacing(
        ascent: 0.8,
        descent: -0.2,
        fontSize: 16,
        lineHeight: 1.4,
      );
      expect(large, closeTo(small * 2, 1e-9));
    });
  });

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
}
