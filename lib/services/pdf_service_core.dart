
import '../utils/tibetan_segmenter.dart'
    show isTibetanNonLetter, parseRedHighlightRanges;

/// Extra line spacing for `package:pdf` text so its advance equals
/// `fontSize * lineHeight`.
///
/// Flutter's `TextStyle(height:)` (used by the preview) and the layout engine's
/// row-height estimates both treat `fontSize * lineHeight` as the distance
/// between baselines. `package:pdf` instead advances by the font's natural line
/// height — `(ascent - descent) * fontSize` — and adds `lineSpacing` on top.
/// Fonts whose ascent/descent ratio differs therefore need different values:
/// Kaiti already advances 1.4 em at the default settings, while MingLiU only
/// advances 1.0 em. A natural line taller than the target cannot be shrunk.
double pdfLineSpacing({
  required double ascent,
  required double descent,
  required double fontSize,
  required double lineHeight,
}) {
  final natural = (ascent - descent) * fontSize;
  final wanted = fontSize * lineHeight;
  return wanted > natural ? wanted - natural : 0;
}

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
