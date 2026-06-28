import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/batch_import_service.dart';

void main() {
  test('parses CSV with header', () {
    final result = BatchImportService.parseContent(
      'tibetan,pronunciation,translation\n'
      'བཀྲ་ཤིས།,zha xi,good luck\n'
      'བདེ་ལེགས།,de le,blessings\n',
    );
    expect(result.importedRows, 2);
    expect(result.skippedRows, 0);
    expect(result.blocks[0].tibetan, 'བཀྲ་ཤིས།');
    expect(result.blocks[0].chinesePronunciation, 'zha xi');
    expect(result.blocks[0].chineseTranslation, 'good luck');
  });

  test('parses CSV without header', () {
    final result = BatchImportService.parseContent(
      'བཀྲ་ཤིས།,zha xi,good luck\n'
      'བདེ་ལེགས།,de le,blessings\n',
    );
    expect(result.importedRows, 2);
    expect(result.blocks[0].tibetan, 'བཀྲ་ཤིས།');
  });

  test('skips empty rows', () {
    final result = BatchImportService.parseContent(
      'tibetan,pronunciation,translation\n'
      '\n'
      'བཀྲ་ཤིས།,zha xi,\n'
      '   ,,\n'
      'བདེ་ལེགས།,,blessings\n',
    );
    expect(result.importedRows, 2);
    expect(result.skippedRows, 2);
  });

  test('parses TSV', () {
    final result = BatchImportService.parseContent(
      'tibetan\tpronunciation\ttranslation\n'
      'བཀྲ་ཤིས།\tzha xi\tgood luck\n',
    );
    expect(result.importedRows, 1);
  });

  test('handles alternate header names', () {
    final result = BatchImportService.parseContent(
      'tib,pron,trans\n'
      'བཀྲ་ཤིས།,zha xi,good luck\n',
    );
    expect(result.importedRows, 1);
  });
}
