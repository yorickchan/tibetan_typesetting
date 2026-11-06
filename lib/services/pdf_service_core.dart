import 'dart:ui' show Color, TextAlign;

import '../utils/tibetan_segmenter.dart'
    show isTibetanNonLetter, parseRedHighlightRanges;

/// Per-code-unit flag: true where the red highlight applies (Tibetan letters,
/// including tsheg), false elsewhere (vowel signs, shad, punctuation and any
/// syllable outside the highlight range).
///
/// Syllables are counted the same way [parseRedHighlightRanges] expects: a new
/// word starts after each tsheg, and the tsheg itself belongs to the word it
/// terminates. This mirrors the preview, which colours highlighted syllables
/// with rose letters and black marks.
List<bool> tibetanHighlightMask(String text, String ranges) {
  final mask = List<bool>.filled(text.length, false);
  final parsed = parseRedHighlightRanges(ranges);
  if (parsed.isEmpty || text.isEmpty) return mask;

  var word = 1;
  for (var i = 0; i < text.length; i++) {
    final codeUnit = text.codeUnitAt(i);
    final highlighted = parsed.any((r) => word >= r.start && word <= r.end);
    mask[i] = highlighted && !isTibetanNonLetter(codeUnit);
    if (codeUnit == 0x0F0B || codeUnit == 0x0F0C) word++;
  }
  return mask;
}

String renderCacheKey({
  required String text,
  required String fontFamily,
  List<String>? fontFamilyFallback,
  required double fontSize,
  required Color color,
  required double maxWidth,
  double? lineHeight,
  required double topPadding,
  required double bottomPadding,
  required TextAlign textAlign,
}) =>
    '${text}_|_${fontFamily}_|_${fontFamilyFallback?.join(',') ?? ''}_|_${fontSize}_|_${color.toARGB32()}_|_${maxWidth}_|_${lineHeight}_|_${topPadding}_|_${bottomPadding}_|_$textAlign';
