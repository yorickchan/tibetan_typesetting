import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/font_config.dart';
import '../utils/font_utils.dart' as font_utils;

/// Raised when a font file is recognised but its format cannot be used for
/// CJK / non-Latin text in PDFs (e.g. OpenType with CFF outlines).
class UnsupportedFontError implements Exception {
  final String message;
  const UnsupportedFontError(this.message);

  @override
  String toString() => 'UnsupportedFontError: $message';
}

/// Information about a font file discovered on the system.
class SystemFontInfo {
  final String familyName;
  final String filePath;

  /// 'ttf', 'otf', or 'ttc'
  final String fileType;

  const SystemFontInfo({
    required this.familyName,
    required this.filePath,
    required this.fileType,
  });

  static SystemFontInfo? fromNativeMap(Map<Object?, Object?> map) {
    final familyName = map['familyName'];
    final filePath = map['filePath'];
    final fileType = map['fileType'];
    if (familyName is! String ||
        familyName.trim().isEmpty ||
        filePath is! String ||
        filePath.trim().isEmpty ||
        fileType is! String ||
        fileType.trim().isEmpty) {
      return null;
    }
    return SystemFontInfo(
      familyName: familyName,
      filePath: filePath,
      fileType: fileType.toLowerCase(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemFontInfo && filePath == other.filePath;

  @override
  int get hashCode => filePath.hashCode;
}

class FontService {
  FontService._();
  static final FontService _instance = FontService._();
  factory FontService() => _instance;

  List<SystemFontInfo>? _cachedFonts;
  final _loadedPreviewFamilies = <String>{};
  final _pdfFontCache = <String, pw.Font>{};

  static const _channel = MethodChannel('tibetan_typesetting/system_fonts');

  static List<String> get _fontDirs {
    if (Platform.isMacOS) {
      return const [
        '/System/Library/Fonts',
        '/Library/Fonts',
        '/Network/Library/Fonts',
      ];
    } else if (Platform.isWindows) {
      final winDir = Platform.environment['WINDIR'] ?? r'C:\Windows';
      return ['$winDir\\Fonts'];
    } else if (Platform.isLinux) {
      return const ['/usr/share/fonts', '/usr/local/share/fonts'];
    }
    return const [];
  }

  static const _supportedExtensions = {'.ttf', '.otf', '.ttc'};

  // ---------------------------------------------------------------------------
  // System font scanning
  // ---------------------------------------------------------------------------

  /// Scan macOS system font directories and return a sorted list of discovered
  /// fonts. Results are cached after the first scan.
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
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    final dirs = [
      ..._fontDirs,
      if (homeDir.isNotEmpty && Platform.isMacOS) '$homeDir/Library/Fonts',
      if (homeDir.isNotEmpty && Platform.isLinux) '$homeDir/.local/share/fonts',
      if (homeDir.isNotEmpty && Platform.isLinux) '$homeDir/.fonts',
    ];

    for (final dirPath in dirs) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;

      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        final path = entity.path;
        final ext = _extensionLower(path);
        if (!_supportedExtensions.contains(ext)) continue;
        if (seen.contains(path)) continue;
        seen.add(path);

        final familyName =
            await font_utils.readFontFamilyName(path) ??
            font_utils.fontNameFromPath(path);

        fonts.add(
          SystemFontInfo(
            familyName: familyName,
            filePath: path,
            fileType: ext.substring(1), // remove leading dot
          ),
        );
      }
    }

    // deduplicateFamilies will sort the result, so no need to sort here
    _cachedFonts = deduplicateFamilies(fonts);
    return _cachedFonts!;
  }

  /// Force a re-scan next time [scanSystemFonts] is called.
  void invalidateCache() => _cachedFonts = null;

  static List<SystemFontInfo> deduplicateFamilies(List<SystemFontInfo> fonts) {
    final byFamily = <String, SystemFontInfo>{};
    for (final font in fonts) {
      final key = font.familyName.trim().toLowerCase();
      if (key.isEmpty) continue;
      final existing = byFamily[key];
      if (existing == null || _fontPriority(font) < _fontPriority(existing)) {
        byFamily[key] = font;
      }
    }

    final deduplicated = byFamily.values.toList();
    deduplicated.sort(
      (a, b) =>
          a.familyName.toLowerCase().compareTo(b.familyName.toLowerCase()),
    );
    return deduplicated;
  }

  /// Well-known font families with broad CJK coverage, checked in priority order.
  static const _cjkFallbackPatterns = [
    'arial unicode',
    'noto sans cjk',
    'noto serif cjk',
    'droid sans fallback',
    'wenquanyi',
    'microsoft yahei',
    'simsun',
    'nsimsun',
    'simhei',
    'kaiti',
    'songti',
    'stheiti',
    'stsong',
    'pingfang',
    'hiragino sans gb',
    'hiragino sans',
  ];

  /// Search scanned system fonts for CJK-capable fallback fonts and load them
  /// for PDF use. Returns up to [maxFonts] fonts.
  Future<List<pw.Font>> loadCjkFallbackFonts({int maxFonts = 3}) async {
    final systemFonts = await scanSystemFonts();
    final loaded = <pw.Font>[];
    final usedPaths = <String>{};

    for (final pattern in _cjkFallbackPatterns) {
      if (loaded.length >= maxFonts) break;
      for (final info in systemFonts) {
        if (loaded.length >= maxFonts) break;
        if (usedPaths.contains(info.filePath)) continue;
        if (info.familyName.toLowerCase().contains(pattern)) {
          try {
            final font = await loadFontForPdf(
              FontConfig(
                fontFamily: info.familyName,
                fontPath: info.filePath,
                fontSize: 10,
              ),
            );
            loaded.add(font);
            usedPaths.add(info.filePath);
          } on UnsupportedFontError {
            // Fallback scan: many system fonts are CFF / missing tables.
            // This is expected and not actionable, so don't log it.
          } catch (e) {
            debugPrint('Failed to load CJK fallback font ${info.filePath}: $e');
          }
        }
      }
    }
    return loaded;
  }

  // ---------------------------------------------------------------------------
  // Dynamic font loading for Flutter preview
  // ---------------------------------------------------------------------------

  /// Register a font with Flutter's engine so it can be used in [TextStyle].
  ///
  /// If the font has already been loaded (by family name), this is a no-op.
  Future<void> loadFontForPreview(FontConfig config) async {
    if (_loadedPreviewFamilies.contains(config.fontFamily)) return;

    try {
      final file = File(config.fontPath);
      if (!await file.exists()) return;

      final bytes = await file.readAsBytes();
      ByteData fontData = ByteData.sublistView(bytes);

      // For TTC files, extract the first TTF
      if (_isTtc(bytes)) {
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

  // ---------------------------------------------------------------------------
  // Font loading for PDF generation
  // ---------------------------------------------------------------------------

  /// Load a font suitable for the `pdf` package. Returns a cached instance
  /// if the same font path was loaded before.
  ///
  /// Throws [UnsupportedFontError] if the font uses CFF (OpenType PostScript)
  /// outlines, which the `pdf` package cannot embed for CJK / non-Latin text.
  Future<pw.Font> loadFontForPdf(FontConfig config) async {
    final cached = _pdfFontCache[config.fontPath];
    if (cached != null) return cached;

    final file = File(config.fontPath);
    final bytes = await file.readAsBytes();
    ByteData fontData = ByteData.sublistView(bytes);

    if (_isTtc(bytes)) {
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _extensionLower(String path) {
    final dot = path.lastIndexOf('.');
    return dot >= 0 ? path.substring(dot).toLowerCase() : '';
  }

  static int _fontPriority(SystemFontInfo font) {
    final path = font.filePath.toLowerCase();
    final name = font.familyName.toLowerCase();
    if (path.contains('regular') || name.contains('regular')) return 0;
    if (!path.contains('bold') &&
        !path.contains('italic') &&
        !path.contains('oblique') &&
        !path.contains('black') &&
        !path.contains('heavy')) {
      return 1;
    }
    return 2;
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
          .where((font) => _supportedExtensions.contains('.${font.fileType}'))
          .toList();
    } on MissingPluginException {
      return const [];
    } on PlatformException catch (e) {
      debugPrint('Failed to list native system fonts: ${e.message}');
      return const [];
    }
  }

  static bool _isTtc(Uint8List bytes) =>
      bytes.length >= 4 &&
      bytes[0] == 0x74 &&
      bytes[1] == 0x74 &&
      bytes[2] == 0x63 &&
      bytes[3] == 0x66;
}
