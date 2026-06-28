import 'dart:typed_data';

import 'font_service_core.dart';

Future<List<SystemFontInfo>> scanNativeFonts(Set<String> seen) async => const [];

Future<List<SystemFontInfo>> scanMacOsNativeChannel() async => const [];

Future<Uint8List> readFontFileBytes(String path) async => Uint8List(0);