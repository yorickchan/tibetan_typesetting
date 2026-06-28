import 'dart:io';

import 'package:flutter/foundation.dart';

import 'font_utils.dart' show parseFontFamilyName, extractTtfFromTtc;

Future<String?> readFontFamilyName(String filePath) async {
  try {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final data = ByteData.sublistView(bytes);

    if (bytes.length >= 4 &&
        bytes[0] == 0x74 &&
        bytes[1] == 0x74 &&
        bytes[2] == 0x63 &&
        bytes[3] == 0x66) {
      final ttf = extractTtfFromTtc(data, fontIndex: 0);
      if (ttf == null) return null;
      return parseFontFamilyName(ttf);
    }

    return parseFontFamilyName(data);
  } catch (e) {
    debugPrint('Failed to read font family name: $e');
    return null;
  }
}
