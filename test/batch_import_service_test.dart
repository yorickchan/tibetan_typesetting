import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/batch_import_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('batch_import_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> writeFile(String name, String contents) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsString(contents);
    return file;
  }

  test('parses CSV with header', () async {
    final file = await writeFile(
      'csv_header.csv',
      'tibetan,pronunciation,translation\n'
      'བཀྲ་ཤིས།,zha xi,good luck\n'
      'བདེ་ལེགས།,de le,blessings\n',
    );
    final result = BatchImportService.parseFile(file);
    expect(result.importedRows, 2);
    expect(result.skippedRows, 0);
    expect(result.blocks[0].tibetan, 'བཀྲ་ཤིས།');
    expect(result.blocks[0].chinesePronunciation, 'zha xi');
    expect(result.blocks[0].chineseTranslation, 'good luck');
  });

  test('parses CSV without header', () async {
    final file = await writeFile(
      'csv_noheader.csv',
      'བཀྲ་ཤིས།,zha xi,good luck\n'
      'བདེ་ལེགས།,de le,blessings\n',
    );
    final result = BatchImportService.parseFile(file);
    expect(result.importedRows, 2);
    expect(result.blocks[0].tibetan, 'བཀྲ་ཤིས།');
  });

  test('skips empty rows', () async {
    final file = await writeFile(
      'csv_empty.csv',
      'tibetan,pronunciation,translation\n'
      '\n'
      'བཀྲ་ཤིས།,zha xi,\n'
      '   ,,\n'
      'བདེ་ལེགས།,,blessings\n',
    );
    final result = BatchImportService.parseFile(file);
    expect(result.importedRows, 2);
    expect(result.skippedRows, 2);
  });

  test('parses TSV', () async {
    final file = await writeFile(
      'import.tsv',
      'tibetan\tpronunciation\ttranslation\n'
      'བཀྲ་ཤིས།\tzha xi\tgood luck\n',
    );
    final result = BatchImportService.parseFile(file);
    expect(result.importedRows, 1);
  });

  test('handles alternate header names', () async {
    final file = await writeFile(
      'alt_header.csv',
      'tib,pron,trans\n'
      'བཀྲ་ཤིས།,zha xi,good luck\n',
    );
    final result = BatchImportService.parseFile(file);
    expect(result.importedRows, 1);
  });
}
