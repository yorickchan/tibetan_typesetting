// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

Future<void> saveTextFile(String path, String content) async {
  final blob = html.Blob([content.codeUnits], 'text/plain');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', path.split('/').last)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> saveBytesFile(String path, List<int> bytes) async {
  final blob = html.Blob([bytes], 'application/octet-stream');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', path.split('/').last)
    ..click();
  html.Url.revokeObjectUrl(url);
}
