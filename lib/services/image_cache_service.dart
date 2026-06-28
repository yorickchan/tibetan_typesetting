import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  Directory? _cacheDir;
  final Map<String, Uint8List> _webCache = {};

  Future<Directory> get cacheDir async {
    if (_cacheDir != null) return _cacheDir!;
    final dir = await getTemporaryDirectory();
    _cacheDir = Directory('${dir.path}/tibetan_text_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  String _cacheKey(
      String text, String fontFamily, double fontSize, double maxWidth) {
    final input = '$text|$fontFamily|$fontSize|$maxWidth';
    return sha256.convert(utf8.encode(input)).toString();
  }

  Future<Uint8List?> get(
      String text, String fontFamily, double fontSize, double maxWidth) async {
    final key = _cacheKey(text, fontFamily, fontSize, maxWidth);
    if (kIsWeb) {
      return _webCache[key];
    }
    final file = File('${(await cacheDir).path}/$key.png');
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  Future<void> put(String text, String fontFamily, double fontSize,
      double maxWidth, Uint8List png) async {
    final key = _cacheKey(text, fontFamily, fontSize, maxWidth);
    if (kIsWeb) {
      _webCache[key] = png;
      return;
    }
    final file = File('${(await cacheDir).path}/$key.png');
    await file.writeAsBytes(png);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      _webCache.clear();
      return;
    }
    final dir = await cacheDir;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      _cacheDir = null;
    }
  }
}
