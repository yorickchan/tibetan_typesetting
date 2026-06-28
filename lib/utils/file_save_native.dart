import 'dart:io';

Future<void> saveTextFile(String path, String content) async {
  await File(path).writeAsString(content);
}

Future<void> saveBytesFile(String path, List<int> bytes) async {
  await File(path).writeAsBytes(bytes);
}
