import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/pronunciation_service.dart';

void main() {
  group('PronunciationService', () {
    test('isSavablePronunciation returns true for valid characters', () {
      expect(PronunciationService.isSavablePronunciation('bod'), true);
      expect(PronunciationService.isSavablePronunciation('藏'), true);
      expect(PronunciationService.isSavablePronunciation('123'), true);
    });

    test('isSavablePronunciation returns false for invalid characters', () {
      expect(PronunciationService.isSavablePronunciation(''), false);
      expect(PronunciationService.isSavablePronunciation('   '), false);
      expect(PronunciationService.isSavablePronunciation('!@#'), false);
    });

    test('savablePronunciationCharacters filters valid characters', () {
      final chars = PronunciationService.savablePronunciationCharacters('bod 123!');
      
      expect(chars, ['b', 'o', 'd', '1', '2', '3']);
    });

    test('savablePronunciationCharacters handles empty string', () {
      final chars = PronunciationService.savablePronunciationCharacters('');
      
      expect(chars, isEmpty);
    });

    test('savablePronunciationCharacters handles unicode', () {
      final chars = PronunciationService.savablePronunciationCharacters('藏语');
      
      expect(chars, ['藏', '语']);
    });
  });
}
