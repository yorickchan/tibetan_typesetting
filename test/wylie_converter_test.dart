import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/utils/wylie_converter.dart';

void main() {
  test('converts basic syllables', () {
    final result = WylieConverter.convert('bkra shis');
    expect(result, contains('བཀྲ'));
    expect(result, contains('ཤིས'));
  });

  test('converts common Tibetan phrases', () {
    final result = WylieConverter.convert('bde legs');
    expect(result, contains('བདེ'));
    expect(result, contains('ལེགས'));
  });

  test('handles empty input', () {
    expect(WylieConverter.convert(''), '');
  });

  test('handles whitespace-only input', () {
    expect(WylieConverter.convert('   '), '');
  });

  test('converts single syllable', () {
    final result = WylieConverter.convertSyllable('bkra');
    expect(result, contains('བཀྲ'));
    expect(result, endsWith('་'));
  });

  test('adds tsheg when not present', () {
    final result = WylieConverter.convertSyllable('ka');
    expect(result, endsWith('་'));
    expect(result, contains('ཀ'));
  });
}
