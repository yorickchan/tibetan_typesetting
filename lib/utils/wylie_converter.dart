class WylieConverter {
  static const Map<String, int> _consonantCodes = {
    'k': 0x0F40, 'kh': 0x0F41, 'g': 0x0F42, 'ng': 0x0F44,
    'c': 0x0F45, 'ch': 0x0F46, 'j': 0x0F47, 'ny': 0x0F49,
    't': 0x0F4F, 'th': 0x0F50, 'd': 0x0F51, 'n': 0x0F53,
    'p': 0x0F54, 'ph': 0x0F55, 'b': 0x0F56, 'm': 0x0F58,
    'ts': 0x0F59, 'tsh': 0x0F5A, 'dz': 0x0F5B, 'w': 0x0F5D,
    'zh': 0x0F5E, 'z': 0x0F5F, 'y': 0x0F61,
    'r': 0x0F62, 'l': 0x0F63, 'sh': 0x0F64, 's': 0x0F66, 'h': 0x0F67,
    'a': 0x0F68,
  };

  static const _subjoinable = {'w', 'y', 'r', 'l'};

  static const Map<String, int> _vowelCodes = {
    'i': 0x0F72, 'u': 0x0F74, 'e': 0x0F7A, 'o': 0x0F7C,
  };

  static List<String> _tokenize(String wylie) {
    final parts = <String>[];
    var i = 0;
    while (i < wylie.length) {
      String? found;
      if (i + 2 < wylie.length) {
        final three = wylie.substring(i, i + 3);
        if (_consonantCodes.containsKey(three)) {
          found = three;
        }
      }
      if (found == null && i + 1 < wylie.length) {
        final two = wylie.substring(i, i + 2);
        if (_consonantCodes.containsKey(two) || _vowelCodes.containsKey(two)) {
          found = two;
        }
      }
      if (found == null) {
        found = wylie[i];
      }
      parts.add(found);
      i += found.length;
    }
    return parts;
  }

  static String convertSyllable(String wylie) {
    if (wylie.isEmpty) return wylie;

    final parts = _tokenize(wylie);
    if (parts.isEmpty) return '';

    final result = StringBuffer();

    // Find the vowel position (including inherent 'a')
    var vowelIdx = -1;
    for (var i = 0; i < parts.length; i++) {
      if (_vowelCodes.containsKey(parts[i])) {
        vowelIdx = i;
        break;
      }
      if (parts[i] == 'a') {
        vowelIdx = i;
        break;
      }
    }

    // Determine root position: consonant immediately before vowel.
    // If the pre-vowel consonant is subjoinable and has a consonant before it,
    // that preceding consonant is the root and this one is subjoined.
    final preVowelIdx = vowelIdx >= 0 ? vowelIdx - 1 : parts.length - 1;
    final preVowel = preVowelIdx >= 0 ? parts[preVowelIdx] : null;
    final isVowelA = vowelIdx >= 0 && parts[vowelIdx] == 'a';

    var rootIdx = preVowelIdx;
    var subjoinedIdx = -1;

    if (preVowel != null &&
        _subjoinable.contains(preVowel) &&
        preVowelIdx > 0 &&
        _consonantCodes.containsKey(parts[preVowelIdx - 1])) {
      rootIdx = preVowelIdx - 1;
      subjoinedIdx = preVowelIdx;
    }

    // Write prefix consonants (before root, full height)
    for (var i = 0; i < rootIdx; i++) {
      final code = _consonantCodes[parts[i]];
      if (code != null) {
        result.writeCharCode(code);
      }
    }

    // Write root (full height)
    final rootCode = _consonantCodes[parts[rootIdx]];
    if (rootCode != null) {
      result.writeCharCode(rootCode);
    }

    // Write subjoined
    if (subjoinedIdx >= 0) {
      final code = _consonantCodes[parts[subjoinedIdx]];
      if (code != null) {
        result.writeCharCode(code + 0x50);
      }
    }

    // Write vowel (skip inherent 'a')
    if (vowelIdx >= 0 && !isVowelA) {
      final vCode = _vowelCodes[parts[vowelIdx]];
      if (vCode != null) {
        result.writeCharCode(vCode);
      }
    }

    // Write suffix consonants (after vowel, full height)
    if (vowelIdx >= 0) {
      for (var i = vowelIdx + 1; i < parts.length; i++) {
        final code = _consonantCodes[parts[i]];
        if (code != null) {
          result.writeCharCode(code);
        }
      }
    }

    // Add tsheg
    final s = result.toString();
    if (s.isNotEmpty && !RegExp(r'[\u0F0B\u0F0D]$').hasMatch(s)) {
      result.write('\u0F0B');
    }

    return result.toString();
  }

  static String convert(String wylieText) {
    return wylieText
        .split(RegExp(r'\s+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => convertSyllable(s.trim()))
        .join('');
  }
}
