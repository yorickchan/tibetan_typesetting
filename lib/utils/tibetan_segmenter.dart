// U+0F0B ་ TIBETAN MARK INTERSYLLABIC TSHEG
// U+0F0C ་ TIBETAN MARK DELIMITER TSHEG BSTAR (variant tsheg)
final _splitPattern = RegExp('[\u0F0B\u0F0C]');

// U+0F04–U+0F1F: Tibetan marks and punctuation (gter shad, nyis shad,
// shad variants, etc.). U+0F3A–U+0F3F: brackets and punctuation.
// U+0FBE–U+0FDA: cantillation marks and signs.
// These are not part of a syllable and must be stripped after splitting,
// so that mark-only segments are skipped during pronunciation auto-fill.
final _stripPattern = RegExp('[\u0F04-\u0F1F\u0F3A-\u0F3F\u0FBE-\u0FDA\\s]');

// U+0F7A–U+0F7F: vowel signs (II, UU, vocalic R/RR/L/LL). These are
// combining marks that are part of real syllables (e.g. བོད contains
// U+0F7C). They must NOT be stripped from syllables. Instead, syllables
// that consist entirely of these vowel signs (no consonant base) are
// filtered out separately.
final _vowelSignOnly = RegExp(r'^[\u0F7A-\u0F7F]+$');

List<String> extractSyllables(String tibetanText) {
  if (tibetanText.isEmpty) return [];

  return tibetanText
      .split(_splitPattern)
      .map((s) => s.replaceAll(_stripPattern, ''))
      .where((s) => s.isNotEmpty && !_vowelSignOnly.hasMatch(s))
      .toList();
}


/// Split [text] by Tibetan tsheg (U+0F0B ་ or U+0F0C ༌).
/// Returns a record with [prefix] (first [n] words, including the nth
/// trailing tsheg) and [suffix] (the remainder). When [text] has fewer
/// than [n] words the entire string becomes the prefix.
({String prefix, String suffix}) splitByTsek(String text, int n) {
  if (n <= 0 || text.isEmpty) return (prefix: '', suffix: text);

  int count = 0;
  for (int i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == '\u0F0B' || c == '\u0F0C') {
      count++;
      if (count == n) {
        return (prefix: text.substring(0, i + 1), suffix: text.substring(i + 1));
      }
    }
  }

  // Fewer than n tshegs — highlight everything.
  return (prefix: text, suffix: '');
}

/// Split [text] by tsheg into three segments:
/// [before] — words 1..(start-1), [highlight] — words start..(start+count-1),
/// [after] — the rest.  [start] is 1-indexed.
({String before, String highlight, String after}) splitByTsekRange(
  String text,
  int start,
  int count,
) {
  if (count <= 0 || start < 1 || text.isEmpty) {
    return (before: text, highlight: '', after: '');
  }

  // Find position of the (start-1)th tsheg (end of "before" segment).
  int beforeEnd = 0;
  if (start > 1) {
    int seen = 0;
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '\u0F0B' || c == '\u0F0C') {
        seen++;
        if (seen == start - 1) {
          beforeEnd = i + 1;
          break;
        }
      }
    }
    // If we didn't find enough tshegs, everything is "before".
    if (beforeEnd == 0) return (before: text, highlight: '', after: '');
  }

  // From beforeEnd, find the (start+count-1)th tsheg overall.
  // We need to find `count` tshegs starting from position beforeEnd.
  int highlightEnd = -1;
  int seen = start - 1; // already passed (start-1) tshegs
  for (int i = beforeEnd; i < text.length; i++) {
    final c = text[i];
    if (c == '\u0F0B' || c == '\u0F0C') {
      seen++;
      if (seen == start - 1 + count) {
        highlightEnd = i + 1;
        break;
      }
    }
  }

  if (highlightEnd == -1) {
    // Not enough words — highlight goes to end.
    return (
      before: text.substring(0, beforeEnd),
      highlight: text.substring(beforeEnd),
      after: '',
    );
  }

  return (
    before: text.substring(0, beforeEnd),
    highlight: text.substring(beforeEnd, highlightEnd),
    after: text.substring(highlightEnd),
  );
}


/// Parse a red-highlight range string like "1-4,6-8" into sorted,
/// non-overlapping (start,end) pairs.  Invalid input → empty list.
List<({int start, int end})> parseRedHighlightRanges(String input) {
  final out = <({int start, int end})>[];
  if (input.trim().isEmpty) return out;

  for (final part in input.split(',')) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) continue;
    final dash = trimmed.indexOf('-');
    if (dash == -1) {
      final v = int.tryParse(trimmed);
      if (v != null && v > 0) out.add((start: v, end: v));
    } else {
      final a = int.tryParse(trimmed.substring(0, dash).trim());
      final b = int.tryParse(trimmed.substring(dash + 1).trim());
      if (a != null && b != null && a > 0 && b >= a) {
        out.add((start: a, end: b));
      }
    }
  }

  // Sort by start, merge overlapping/adjacent.
  out.sort((x, y) => x.start.compareTo(y.start));
  final merged = <({int start, int end})>[];
  for (final r in out) {
    if (merged.isEmpty) {
      merged.add(r);
    } else {
      final prev = merged.last;
      if (r.start <= prev.end + 1) {
        merged.last = (start: prev.start, end: r.end > prev.end ? r.end : prev.end);
      } else {
        merged.add(r);
      }
    }
  }
  return merged;
}

/// Split [text] into alternating segments by tsheg boundaries, tagging
/// each segment as highlighted (true) or not.
List<({String text, bool highlight})> splitByRedHighlightRanges(
  String text,
  String ranges,
) {
  final segs = <({String text, bool highlight})>[];
  if (text.isEmpty) return segs;

  final parsed = parseRedHighlightRanges(ranges);

  bool isHighlighted(int wi) {
    for (final r in parsed) {
      if (wi >= r.start && wi <= r.end) return true;
      if (wi < r.start) return false;
    }
    return false;
  }

  String buf = '';
  bool? bufHighlight;
  int wi = 1; // 1-indexed word counter

  for (int i = 0; i < text.length; i++) {
    final c = text[i];
    final isTsek = c == '\u0F0B' || c == '\u0F0C';
    final hl = parsed.isNotEmpty && isHighlighted(wi);

    if (buf.isNotEmpty && hl != bufHighlight) {
      segs.add((text: buf, highlight: bufHighlight!));
      buf = '';
    }
    buf += c;
    bufHighlight = hl;

    if (isTsek) wi++;
  }

  if (buf.isNotEmpty) segs.add((text: buf, highlight: bufHighlight!));
  return segs;
}

/// Characters that should not receive the red highlight:
/// tsheg (U+0F0B–U+0F0C) is treated as a letter for highlighting.
/// shad/punctuation (U+0F0D–U+0F14) and vowel/marks (U+0F71–U+0F80,
/// U+0F82–U+0F84) are excluded.
bool isTibetanNonLetter(int codeUnit) {
  if (codeUnit >= 0x0F0D && codeUnit <= 0x0F14) return true;
  if (codeUnit >= 0x0F71 && codeUnit <= 0x0F7F) return true;
  if (codeUnit == 0x0F80) return true;
  if (codeUnit >= 0x0F82 && codeUnit <= 0x0F84) return true;
  return false;
}
