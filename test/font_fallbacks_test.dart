import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tibetan_typesetting/utils/font_fallbacks.dart';

void main() {
  group('previewFontFallbacksFor', () {
    test('keeps the selected family first and appends fallbacks', () {
      final list = previewFontFallbacksFor('Kailasa');

      expect(list.first, 'Kailasa');
      expect(list, contains('STHeiti'));
      expect(list, contains('.LastResort'));
      expect(list.toSet().length, list.length);
    });

    test('does not duplicate a fallback that is already selected', () {
      final list = previewFontFallbacksFor('STHeiti');

      expect(list.where((f) => f == 'STHeiti').length, 1);
    });
  });

  group('ThemeData fallback', () {
    test('reaches text styles that set their own fontFamily', () {
      final theme = ThemeData(fontFamilyFallback: kPreviewFontFallbacks);
      final style = theme.textTheme.bodyMedium!.merge(
        const TextStyle(fontFamily: 'Kailasa'),
      );

      expect(style.fontFamily, 'Kailasa');
      expect(style.fontFamilyFallback, contains('.LastResort'));
    });
  });
}
