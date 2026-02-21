const int _tshegCodeUnit = 0x0F0B;

// U+0F0B ་ TIBETAN MARK INTERSYLLABIC TSHEG
// U+0F0C ་ TIBETAN MARK DELIMITER TSHEG BSTAR (variant tsheg)
final _splitPattern = RegExp('[\u0F0B\u0F0C]');

// U+0F0D–U+0F14: shad variants and other Tibetan punctuation marks that
// are not part of a syllable and must be stripped after splitting.
final _stripPattern = RegExp('[\u0F0D-\u0F14\\s]');

List<String> extractSyllables(String tibetanText) {
  if (tibetanText.isEmpty) return [];

  return tibetanText
      .split(_splitPattern)
      .map((s) => s.replaceAll(_stripPattern, ''))
      .where((s) => s.isNotEmpty)
      .toList();
}

String joinSyllables(List<String> syllables) {
  if (syllables.isEmpty) return '';
  return syllables.join(String.fromCharCode(_tshegCodeUnit));
}
