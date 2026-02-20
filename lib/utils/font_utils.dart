import 'dart:io';
import 'dart:typed_data';

import '../models/font_config.dart';

/// Extract a single TTF font from a TrueType Collection (.ttc) file.
///
/// Returns null if the data is not a valid TTC or the [fontIndex] is out of
/// range.
ByteData? extractTtfFromTtc(ByteData ttc, {int fontIndex = 0}) {
  if (ttc.lengthInBytes < 12) return null;
  final tag = String.fromCharCodes([
    ttc.getUint8(0),
    ttc.getUint8(1),
    ttc.getUint8(2),
    ttc.getUint8(3),
  ]);
  if (tag != 'ttcf') return null;

  final numFonts = ttc.getUint32(8);
  if (fontIndex >= numFonts) return null;

  final fontOffset = ttc.getUint32(12 + fontIndex * 4);
  if (fontOffset + 12 > ttc.lengthInBytes) return null;

  final numTables = ttc.getUint16(fontOffset + 4);
  final tags = <int>[];
  final checksums = <int>[];
  final offsets = <int>[];
  final lengths = <int>[];
  for (var i = 0; i < numTables; i++) {
    final e = fontOffset + 12 + i * 16;
    if (e + 16 > ttc.lengthInBytes) return null;
    tags.add(ttc.getUint32(e));
    checksums.add(ttc.getUint32(e + 4));
    offsets.add(ttc.getUint32(e + 8));
    lengths.add(ttc.getUint32(e + 12));
  }

  final headerSize = 12 + numTables * 16;
  var totalSize = headerSize;
  for (final len in lengths) {
    totalSize += (len + 3) & ~3;
  }

  final out = ByteData(totalSize);
  for (var i = 0; i < 12; i++) {
    out.setUint8(i, ttc.getUint8(fontOffset + i));
  }

  var dataOffset = headerSize;
  for (var i = 0; i < numTables; i++) {
    final dirOff = 12 + i * 16;
    out.setUint32(dirOff, tags[i]);
    out.setUint32(dirOff + 4, checksums[i]);
    out.setUint32(dirOff + 8, dataOffset);
    out.setUint32(dirOff + 12, lengths[i]);
    for (var j = 0; j < lengths[i]; j++) {
      out.setUint8(dataOffset + j, ttc.getUint8(offsets[i] + j));
    }
    dataOffset += (lengths[i] + 3) & ~3;
  }
  return out;
}

/// Parse the font family name from a TTF/OTF file's `name` table.
///
/// Returns the family name (nameID 1) using platformID 3 (Windows) with
/// UTF-16BE encoding first, falling back to platformID 1 (Mac) with
/// Latin/ASCII encoding. Returns null if the name cannot be parsed.
String? parseFontFamilyName(ByteData data) {
  if (data.lengthInBytes < 12) return null;

  final numTables = data.getUint16(4);
  int? nameTableOffset;
  int? nameTableLength;

  for (var i = 0; i < numTables; i++) {
    final entry = 12 + i * 16;
    if (entry + 16 > data.lengthInBytes) break;
    final tag = String.fromCharCodes([
      data.getUint8(entry),
      data.getUint8(entry + 1),
      data.getUint8(entry + 2),
      data.getUint8(entry + 3),
    ]);
    if (tag == 'name') {
      nameTableOffset = data.getUint32(entry + 8);
      nameTableLength = data.getUint32(entry + 12);
      break;
    }
  }

  if (nameTableOffset == null ||
      nameTableLength == null ||
      nameTableOffset + 6 > data.lengthInBytes) {
    return null;
  }

  final nameCount = data.getUint16(nameTableOffset + 2);
  final stringOffset = data.getUint16(nameTableOffset + 4);
  final stringsBase = nameTableOffset + stringOffset;

  String? windowsName;
  String? macName;

  for (var i = 0; i < nameCount; i++) {
    final rec = nameTableOffset + 6 + i * 12;
    if (rec + 12 > data.lengthInBytes) break;

    final platformID = data.getUint16(rec);
    final nameID = data.getUint16(rec + 6);
    final strLength = data.getUint16(rec + 8);
    final strOffset = data.getUint16(rec + 10);

    if (nameID != 1) continue; // only font family name

    final start = stringsBase + strOffset;
    if (start + strLength > data.lengthInBytes) continue;

    if (platformID == 3 && windowsName == null) {
      // Windows platform: UTF-16BE
      final chars = <int>[];
      for (var j = 0; j + 1 < strLength; j += 2) {
        chars.add(data.getUint16(start + j));
      }
      windowsName = String.fromCharCodes(chars).trim();
    } else if (platformID == 1 && macName == null) {
      // Macintosh platform: single-byte encoding (roughly Latin)
      final chars = <int>[];
      for (var j = 0; j < strLength; j++) {
        chars.add(data.getUint8(start + j));
      }
      macName = String.fromCharCodes(chars).trim();
    }

    if (windowsName != null) break;
  }

  final name = windowsName ?? macName;
  return (name != null && name.isNotEmpty) ? name : null;
}

/// Try to read the font family name from a file on disk.
///
/// Handles both plain TTF/OTF and TTC files (reads the first font in the
/// collection).
Future<String?> readFontFamilyName(String filePath) async {
  try {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final data = ByteData.sublistView(bytes);

    // Check if TTC
    if (bytes.length >= 4 &&
        bytes[0] == 0x74 && // 't'
        bytes[1] == 0x74 && // 't'
        bytes[2] == 0x63 && // 'c'
        bytes[3] == 0x66) {
      // 'f'
      final ttf = extractTtfFromTtc(data, fontIndex: 0);
      if (ttf == null) return null;
      return parseFontFamilyName(ttf);
    }

    return parseFontFamilyName(data);
  } catch (_) {
    return null;
  }
}

/// Derive a human-readable name from a font file path, used as fallback when
/// the name table cannot be parsed.
String fontNameFromPath(String path) {
  final fileName = path.split('/').last;
  final dotIdx = fileName.lastIndexOf('.');
  return dotIdx > 0 ? fileName.substring(0, dotIdx) : fileName;
}

/// Resolve the effective [FontConfig] by checking project override first, then
/// app default, then a hardcoded fallback.
FontConfig effectiveFont(
  FontConfig? projectOverride,
  FontConfig? appDefault,
  FontConfig fallback,
) {
  return projectOverride ?? appDefault ?? fallback;
}

/// Convert a font size in points to preview pixels.
///
/// Based on the 3.78 px/mm conversion factor used in preview widgets
/// and the 72 DPI PDF coordinate system: pt / 72 * 25.4 * 3.78 ≈ pt * 1.333
const double ptToPreviewPx = 1.333;

double previewFontSize(double fontSizePt) => fontSizePt * ptToPreviewPx;
