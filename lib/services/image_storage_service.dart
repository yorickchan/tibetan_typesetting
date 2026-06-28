import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageStorageService {
  static final ImageStorageService _instance = ImageStorageService._internal();
  factory ImageStorageService() => _instance;
  ImageStorageService._internal();

  Directory? _imagesDir;
  final Map<String, Uint8List> _webStorage = {};

  Future<Directory> _ensureDir() async {
    if (_imagesDir != null) return _imagesDir!;
    final appDir = await getApplicationSupportDirectory();
    _imagesDir = Directory('${appDir.path}/images');
    if (!await _imagesDir!.exists()) {
      await _imagesDir!.create(recursive: true);
    }
    return _imagesDir!;
  }

  Future<String> copyImageToAppSupport(String sourcePath) async {
    if (kIsWeb) {
      // On web, image data is stored as bytes in the block model, not filesystem paths.
      // Return the source path as-is — it should be a data URL or blob URL.
      return sourcePath;
    }
    final dir = await _ensureDir();
    final ext = sourcePath.split('.').last.toLowerCase();
    final fileName = '${const Uuid().v4().replaceAll('-', '')}.$ext';
    final destFile = File('${dir.path}/$fileName');
    await File(sourcePath).copy(destFile.path);
    return destFile.path;
  }

  Future<void> deleteImage(String path) async {
    if (kIsWeb) {
      _webStorage.remove(path);
      return;
    }
    final dir = await _ensureDir();
    if (path.startsWith(dir.path)) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }
}
