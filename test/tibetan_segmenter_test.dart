import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/utils/tibetan_segmenter.dart';

void main() {
  group('extractSyllables', () {
    test('strips mark-only segments in U+0F04-U+0F1F range', () {
      // ༄ཾ (U+0F04 gter shad + U+0F07) in a mark-only segment between བོད and ལྷ
      final result = extractSyllables('བོད\u0F0B\u0F04\u0F07\u0F0Bལྷ');
      expect(result, ['བོད', 'ལྷ']);
    });

    test('strips bracket punctuation in U+0F3A-U+0F3F range', () {
      // ༺ ༻ (U+0F3C / U+0F3D) around a real syllable
      final result = extractSyllables('\u0F3Cབོད\u0F3D');
      expect(result, ['བོད']);
    });

    test('strips cantillation marks in U+0FBE-U+0FDA range', () {
      // ྾ ྿ (U+0FBE / U+0FBF) flanking a real syllable
      final result = extractSyllables('\u0FBEབོད\u0FBF');
      expect(result, ['བོད']);
    });

    test('mark-only segment produces no syllable', () {
      // A tsheg-separated run of only marks yields no syllables
      final result = extractSyllables('\u0F04\u0F07\u0F0B\u0F3C\u0F3D');
      expect(result, isEmpty);
    });

    test('keeps real letters when marks are mixed into a syllable', () {
      // བོད with a trailing ༔ (U+0F0D shad) — shad stripped, letters kept
      final result = extractSyllables('བོད\u0F0D');
      expect(result, ['བོད']);
    });

    test('multiple marks between words all skipped', () {
      // བོད ༄ ལྷ — the ༄ (U+0F04) segment is mark-only, skipped
      final result = extractSyllables('བོད\u0F0B\u0F04\u0F0Bལྷ');
      expect(result, ['བོད', 'ལྷ']);
    });

    test('keeps vowel signs inside real syllables', () {
      // བོད contains U+0F7C (vowel sign vocalic R) — must be preserved
      final result = extractSyllables('བོད');
      expect(result, ['བོད']);
    });

    test('vowel-sign-only segment produces no syllable', () {
      // A tsheg-separated run of only vowel signs yields no syllables
      final result = extractSyllables('\u0F7A\u0F7B\u0F0B\u0F7C\u0F7D');
      expect(result, isEmpty);
    });

    test('vowel-sign-only segment between words is skipped', () {
      // བོད ྺྀ ལྷ — the vowel-sign-only segment is skipped
      final result = extractSyllables('བོད\u0F0B\u0F7A\u0F7F\u0F0Bལྷ');
      expect(result, ['བོད', 'ལྷ']);
    });
  });
}
