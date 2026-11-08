import 'font_constants.dart';

/// Font families tried when the selected font lacks a glyph.
///
/// The selected family always comes first; these are appended as the
/// `ThemeData.fontFamilyFallback` so any preview text can fall back to a
/// system font that covers the codepoint. `.LastResort` is intentionally
/// last: it covers rare Unicode ranges that the script fonts miss.
const List<String> kPreviewFontFallbacks = <String>[
  fallbackTibetanFontFamily,
  fallbackChineseFontFamily,
  'Kailasa',
  'STKaiti',
  'Songti SC',
  'PingFang SC',
  'Hiragino Sans GB',
  'Arial Unicode MS',
  '.LastResort',
];

/// Adds the resolved [family] first, followed by the shared fallback list.
List<String> previewFontFallbacksFor(String family) => <String>[
      family,
      ...kPreviewFontFallbacks.where((f) => f != family),
    ];
