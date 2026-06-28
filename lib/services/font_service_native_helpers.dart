import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException, PlatformException;

import 'font_service_core.dart';
import '../utils/font_utils.dart' show fontNameFromPath;
import '../utils/font_utils_native.dart'
  if (dart.library.html) '../utils/font_utils_web.dart';

Future<List<SystemFontInfo>> scanNativeFonts(Set<String> seen) async {
  final fonts = <SystemFontInfo>[];

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

      final familyName = await readFontFamilyName(path);

      fonts.add(
        SystemFontInfo(
          familyName: familyName ?? fontNameFromPath(path),
          filePath: path,
          fileType: ext.substring(1),
        ),
      );
    }
  }

  return fonts;
}

Future<List<SystemFontInfo>> scanMacOsNativeChannel() async {
  if (!Platform.isMacOS) return const [];

  try {
    const channel = MethodChannel('tibetan_typesetting/system_fonts');
    final result = await channel.invokeListMethod<Object?>('listFonts');
    if (result == null) return const [];

    return result
        .whereType<Map<Object?, Object?>>()
        .map(SystemFontInfo.fromNativeMap)
        .whereType<SystemFontInfo>()
        .where((font) => supportedFontExtensions.contains('.${font.fileType}'))
        .toList();
  } on MissingPluginException {
    return const [];
  } on PlatformException {
    return const [];
  }
}

Future<Uint8List> readFontFileBytes(String path) async {
  final file = File(path);
  return await file.readAsBytes();
}