import '../models/project.dart';

class HtmlExportService {
  static String generateHtml(Project project) {
    final buf = StringBuffer();
    buf.writeln('<!DOCTYPE html>');
    buf.writeln('<html lang="bo">');
    buf.writeln('<head>');
    buf.writeln('<meta charset="UTF-8">');
    buf.writeln(
        '<meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buf.writeln('<title>${_escapeHtml(project.name)}</title>');
    buf.writeln('<style>');
    buf.writeln('''
      body {
        font-family: "Microsoft Himalaya", "Noto Sans Tibetan", sans-serif;
        max-width: 800px;
        margin: 0 auto;
        padding: 20px;
        color: #1a1a2e;
        line-height: 1.6;
      }
      .title-page { text-align: center; margin: 40px 0 30px; }
      .title-tibetan { font-size: 28px; }
      .title-chinese { font-size: 18px; color: #555; margin-top: 8px; }
      .block {
        margin-bottom: 14px;
        padding: 8px 0;
        border-bottom: 1px solid #eee;
      }
      .tibetan { font-size: 18px; }
      .pronunciation { font-size: 13px; color: #555; margin-top: 2px; }
      .translation { font-size: 14px; color: #444; margin-top: 4px; }
      .page-break { page-break-before: always; }
      .column-break { display: inline-block; width: 100%; }
      .small-text { font-size: 14px; }
      hr { border: none; border-top: 2px solid #ccc; margin: 20px 0; }
    ''');

    buf.writeln('</style>');
    buf.writeln('</head>');
    buf.writeln('<body>');

    if (project.pageSetup.showTitlePage) {
      buf.writeln('<div class="title-page">');
      if (project.pageSetup.titleTibetan.isNotEmpty) {
        buf.writeln(
            '<h1 class="title-tibetan">${_escapeHtml(project.pageSetup.titleTibetan)}</h1>');
      }
      if (project.pageSetup.titleChinese.isNotEmpty) {
        buf.writeln(
            '<h2 class="title-chinese">${_escapeHtml(project.pageSetup.titleChinese)}</h2>');
      }
      buf.writeln('<hr>');
      buf.writeln('</div>');
    }

    for (final block in project.blocks) {
      if (block.pageBreakBefore) {
        buf.writeln('<div class="page-break"></div>');
      }
      if (block.columnBreakBefore) {
        buf.writeln('<div class="column-break"></div>');
      }

      buf.writeln('<div class="block">');

      if (block.isFreeText) {
        buf.writeln(
            '<p class="translation">${_escapeHtml(block.tibetan)}</p>');
      } else {
        final smallClass = block.smallText ? ' small-text' : '';
        if (block.tibetan.isNotEmpty) {
          buf.writeln(
              '<p class="tibetan$smallClass">${_escapeHtml(block.tibetan)}</p>');
        }
        if (block.chinesePronunciation.isNotEmpty) {
          buf.writeln(
              '<p class="pronunciation$smallClass">${_escapeHtml(block.chinesePronunciation)}</p>');
        }
        if (block.chineseTranslation.isNotEmpty) {
          buf.writeln(
              '<p class="translation$smallClass">${_escapeHtml(block.chineseTranslation)}</p>');
        }
      }

      buf.writeln('</div>');
    }

    buf.writeln('</body></html>');
    return buf.toString();
  }

  static String _escapeHtml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
