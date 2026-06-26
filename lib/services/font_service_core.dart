const Set<String> supportedFontExtensions = {'.ttf', '.otf', '.ttc'};

class UnsupportedFontError implements Exception {
  final String message;
  const UnsupportedFontError(this.message);
  @override
  String toString() => 'UnsupportedFontError: $message';
}

class SystemFontInfo {
  final String familyName;
  final String filePath;
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

const _cjkFallbackPatterns = [
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

List<SystemFontInfo> pickCjkFallbackFonts(
  List<SystemFontInfo> scanned, {
  int maxFonts = 3,
}) {
  final usedPaths = <String>{};
  final loaded = <SystemFontInfo>[];
  for (final pattern in _cjkFallbackPatterns) {
    if (loaded.length >= maxFonts) break;
    for (final info in scanned) {
      if (loaded.length >= maxFonts) break;
      if (usedPaths.contains(info.filePath)) continue;
      if (info.familyName.toLowerCase().contains(pattern)) {
        loaded.add(info);
        usedPaths.add(info.filePath);
      }
    }
  }
  return loaded;
}

List<String> resolveFontDirs({
  String? home,
  String? windir,
  bool mac = false,
  bool win = false,
  bool linux = false,
}) {
  final winDir = windir ?? r'C:\Windows';
  return [
    if (mac)
      ...const [
        '/System/Library/Fonts',
        '/Library/Fonts',
        '/Network/Library/Fonts',
      ],
    if (win) '$winDir\\Fonts',
    if (linux) ...const ['/usr/share/fonts', '/usr/local/share/fonts'],
    if (home != null && home.isNotEmpty) ...[
      if (mac) '$home/Library/Fonts',
      if (linux) '$home/.local/share/fonts',
      if (linux) '$home/.fonts',
    ],
  ];
}

int fontPriority(SystemFontInfo font) {
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

List<SystemFontInfo> deduplicateFamilies(List<SystemFontInfo> fonts) {
  final byFamily = <String, SystemFontInfo>{};
  for (final font in fonts) {
    final key = font.familyName.trim().toLowerCase();
    if (key.isEmpty) continue;
    final existing = byFamily[key];
    if (existing == null || fontPriority(font) < fontPriority(existing)) {
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

String extensionLower(String path) {
  final dot = path.lastIndexOf('.');
  return dot >= 0 ? path.substring(dot).toLowerCase() : '';
}

bool isTtc(List<int> bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x74 &&
    bytes[1] == 0x74 &&
    bytes[2] == 0x63 &&
    bytes[3] == 0x66;
