import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/font_config.dart';
import '../utils/font_utils.dart' as font_utils;
import 'font_service_core.dart';

export 'font_service_core.dart';

class FontService {
  FontService._();
  static final FontService _instance = FontService._();
  factory FontService() => _instance;

  List<SystemFontInfo>? _cachedFonts;
  final _loadedPreviewFamilies = <String>{};
  final _pdfFontCache = <String, pw.Font>{};

  static const _channel = MethodChannel('tibetan_typesetting/system_fonts');

  Future<List<SystemFontInfo>> scanSystemFonts() async {
    if (_cachedFonts != null) return _cachedFonts!;

    final fonts = <SystemFontInfo>[];
    final seen = <String>{};

    for (final font in await _scanNativeSystemFonts()) {
      if (seen.contains(font.filePath)) continue;
      seen.add(font.filePath);
      fonts.add(font);
    }

    final homeDir =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    final dirs = resolveFontDirs(
      home: homeDir.isEmpty ? null : homeDir,
      windir: Platform.environment['WINDIR'],
      mac: Platform.isMacOS,
      win: Platform.isWindows,
      linux: Platform.isLinux,
    );

    for (final dirPath in dirs) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;

      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        final path = entity.path;
        final ext = extensionLower(path);
        if (!supportedFontExtensions.contains(ext)) continue;
        if (seen.contains(path)) continue;
        seen.add(path);

        final familyName =
            await font_utils.readFontFamilyName(path) ??
            font_utils.fontNameFromPath(path);

        fonts.add(
          SystemFontInfo(
            familyName: familyName,
            filePath: path,
            fileType: ext.substring(1),
          ),
        );
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
        // Fallback scan: many system fonts are CFF / missing tables.
        // This is expected and not actionable, so don't log it.
      } catch (e) {
        debugPrint('Failed to load CJK fallback font ${info.filePath}: $e');
      }
    }
    return loaded;
  }

  Future<void> loadFontForPreview(FontConfig config) async {
    if (_loadedPreviewFamilies.contains(config.fontFamily)) return;

    try {
      final file = File(config.fontPath);
      if (!await file.exists()) return;

      final bytes = await file.readAsBytes();
      ByteData fontData = ByteData.sublistView(bytes);

      if (isTtc(bytes)) {
        final extracted = font_utils.extractTtfFromTtc(fontData, fontIndex: 0);
        if (extracted == null) return;
        fontData = extracted;
      }

      final loader = FontLoader(config.fontFamily);
      loader.addFont(Future.value(fontData));
      await loader.load();
      _loadedPreviewFamilies.add(config.fontFamily);
    } catch (e) {
      debugPrint('Failed to load font ${config.fontFamily} for preview: $e');
    }
  }

  Future<pw.Font> loadFontForPdf(FontConfig config) async {
    final cached = _pdfFontCache[config.fontPath];
    if (cached != null) return cached;

    final file = File(config.fontPath);
    final bytes = await file.readAsBytes();
    ByteData fontData = ByteData.sublistView(bytes);

    if (isTtc(bytes)) {
      final extracted = font_utils.extractFirstTrueTypeFromTtc(fontData);
      if (extracted == null) {
        throw UnsupportedFontError(
          'Font "${config.fontFamily}" (${config.fontPath}) cannot be embedded '
          'in PDFs (no TrueType-outline variant with the required tables). '
          'Please choose a different font.',
        );
      }
      fontData = extracted;
    } else {
      if (!font_utils.isTrueTypeOutlineFont(fontData)) {
        throw UnsupportedFontError(
          'Font "${config.fontFamily}" (${config.fontPath}) uses OpenType/CFF '
          'outlines which are not supported by the PDF engine for CJK text. '
          'Please choose a TrueType-flavored font (.ttf).',
        );
      }
      final missing = font_utils.missingPdfEmbeddingTables(fontData);
      if (missing.isNotEmpty) {
        throw UnsupportedFontError(
          'Font "${config.fontFamily}" (${config.fontPath}) is missing '
          'required font tables (${missing.join(', ')}) and cannot be '
          'embedded in PDFs. Please choose a different font.',
        );
      }
    }

    final font = pw.Font.ttf(fontData);
    _pdfFontCache[config.fontPath] = font;
    return font;
  }

  Future<List<SystemFontInfo>> _scanNativeSystemFonts() async {
    if (!Platform.isMacOS) return const [];

    try {
      final result = await _channel.invokeListMethod<Object?>('listFonts');
      if (result == null) return const [];

      return result
          .whereType<Map<Object?, Object?>>()
          .map(SystemFontInfo.fromNativeMap)
          .whereType<SystemFontInfo>()
          .where((font) => supportedFontExtensions.contains('.${font.fileType}'))
          .toList();
    } on MissingPluginException {
      return const [];
    } on PlatformException catch (e) {
      debugPrint('Failed to list native system fonts: ${e.message}');
      return const [];
    }
  }
}
