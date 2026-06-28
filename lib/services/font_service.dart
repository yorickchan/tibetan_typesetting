import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'dart:ui' show ByteData, FontLoader;
import '../utils/font_utils.dart';
import '../models/font_config.dart';
import 'font_service_core.dart';
import 'font_service_native_helpers.dart'
  if (dart.library.html) 'font_service_web_helpers.dart';

export 'font_service_core.dart';

class FontService {
  FontService._();
  static final FontService _instance = FontService._();
  factory FontService() => _instance;

  static const _bundledFonts = <SystemFontInfo>[
    SystemFontInfo(
      familyName: 'Jomolhari',
      filePath: 'Jomolhari',
      fileType: 'ttf',
    ),
  ];
  List<SystemFontInfo>? _cachedFonts;
  final _loadedPreviewFamilies = <String>{};
  final _pdfFontCache = <String, pw.Font>{};

  Future<List<SystemFontInfo>> scanSystemFonts() async {
    if (_cachedFonts != null) return _cachedFonts!;

    final fonts = <SystemFontInfo>[];
    final seen = <String>{};

    if (kIsWeb) {
      fonts.addAll(_bundledFonts.where((b) => !seen.contains(b.filePath)));
      for (final b in _bundledFonts) {
        seen.add(b.filePath);
      }
    } else {
      for (final font in await scanMacOsNativeChannel()) {
        if (seen.contains(font.filePath)) continue;
        seen.add(font.filePath);
        fonts.add(font);
      }

      for (final font in await scanNativeFonts(seen)) {
        if (seen.contains(font.filePath)) continue;
        seen.add(font.filePath);
        fonts.add(font);
      }
    }

    _cachedFonts = deduplicateFamilies(fonts);
    return _cachedFonts!;
  }

  void invalidateCache() => _cachedFonts = null;

  Future<List<pw.Font>> loadCjkFallbackFonts({int maxFonts = 3}) async {
    final systemFonts = await scanSystemFonts();
    final candidates = pickCjkFallbackFonts(systemFonts, maxFonts: maxFonts);
    final loaded = <pw.Font>[];
    for (final info in candidates) {
      try {
        final font = await loadFontForPdf(
          FontConfig(
            fontFamily: info.familyName,
            fontPath: info.filePath,
            fontSize: 10,
          ),
        );
        loaded.add(font);
      } on UnsupportedFontError {
      } catch (e) {
        debugPrint('Failed to load CJK fallback font ${info.filePath}: $e');
      }
    }
    return loaded;
  }

  Future<void> loadFontForPreview(FontConfig config) async {
    if (_loadedPreviewFamilies.contains(config.fontFamily)) return;
    final loader = FontLoader(config.fontFamily);
    try {
      loader.addFont(_loadFontBytes(config));
      await loader.load();
      _loadedPreviewFamilies.add(config.fontFamily);
    } on UnsupportedFontError {
    } catch (e) {
      debugPrint('Failed to load preview font ${config.fontFamily}: $e');
    }
  }

  Future<pw.Font> loadFontForPdf(FontConfig config) async {
    final cacheKey = config.fontPath ?? config.fontFamily;
    if (_pdfFontCache.containsKey(cacheKey)) return _pdfFontCache[cacheKey]!;

    final fontData = await _loadFontBytes(config);
    final font = pw.Font.ttf(fontData);
    _pdfFontCache[cacheKey] = font;
    return font;
  }

  Future<ByteData> _loadFontBytes(FontConfig config) async {
    final path = config.fontPath;
    if (path != null && path.isNotEmpty) {
      final bytes = await _readFontFile(path);
      if (bytes.isNotEmpty) {
        final data = ByteData.sublistView(bytes);
        if (!isTrueTypeOutlineFont(data)) {
          throw UnsupportedFontError(
            '${config.fontFamily}: not a TrueType outline font (CFF/OTTO).',
          );
        }
        return await _ensureTtf(data);
      }
      // Fall through to asset loading on web (bytes empty from stub)
    }

    final assetKey = 'assets/fonts/${config.fontFamily}.ttf';
    final byteData = await rootBundle.load(assetKey);
    if (!isTrueTypeOutlineFont(byteData)) {
      throw UnsupportedFontError(
        '${config.fontFamily}: not a TrueType outline font (CFF/OTTO).',
      );
    }
    return await _ensureTtf(byteData);
  }

  Future<Uint8List> _readFontFile(String path) async {
    return readFontFileBytes(path);
  }

  Future<ByteData> _ensureTtf(ByteData data) async {
    if (isTtc(data.buffer.asUint8List())) {
      final ttf = extractTtfFromTtc(data, fontIndex: 0);
      if (ttf == null) throw UnsupportedFontError('Failed to extract TTF from TTC.');
      return ttf;
    }
    return data;
  }
}