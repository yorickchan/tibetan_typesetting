import 'package:uuid/uuid.dart';

import '../models/project.dart';

const _uuid = Uuid();

class ImportResult {
  final List<TextBlock> blocks;
  final List<String> warnings;
  final int skippedRows;
  final int importedRows;

  const ImportResult({
    required this.blocks,
    required this.warnings,
    required this.skippedRows,
    required this.importedRows,
  });
}

class BatchImportService {
  static ImportResult parseContent(String text) {
    final delimiter = text.contains('\t') ? '\t' : ',';
    var lines = text.split(RegExp(r'\r?\n'));
    if (lines.isNotEmpty && lines.last.isEmpty) {
      lines = lines.sublist(0, lines.length - 1);
    }
    final blocks = <TextBlock>[];
    final warnings = <String>[];
    int skipped = 0;
    int imported = 0;
    int startRow = 0;

    if (lines.isNotEmpty && lines[0].isNotEmpty) {
      final firstParts = _splitLine(lines[0], delimiter);
      if (firstParts.isNotEmpty) {
        final firstCell = firstParts[0].toLowerCase().trim();
        if (firstCell == 'tibetan' || firstCell == 'tib' || firstCell == 'bo') {
          startRow = 1;
        }
      }
    }

    for (var i = startRow; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        skipped++;
        continue;
      }
      final parts = _splitLine(line, delimiter);
      if (parts.isEmpty || parts[0].trim().isEmpty) {
        skipped++;
        continue;
      }
      final tibetan = parts[0].trim();
      final pronunciation = parts.length > 1 ? parts[1].trim() : '';
      final translation = parts.length > 2 ? parts[2].trim() : '';

      blocks.add(TextBlock(
        id: _uuid.v4().replaceAll('-', ''),
        tibetan: tibetan,
        chinesePronunciation: pronunciation,
        chineseTranslation: translation,
      ));
      imported++;
    }

    return ImportResult(
      blocks: blocks,
      warnings: warnings,
      skippedRows: skipped,
      importedRows: imported,
    );
  }

  static List<String> _splitLine(String line, String delimiter) {
    final result = <String>[];
    var inQuotes = false;
    final buf = StringBuffer();
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (c == delimiter && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    result.add(buf.toString());
    return result;
  }
}
