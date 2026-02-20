import 'package:flutter_test/flutter_test.dart';

import 'package:tibetan_typesetting/utils/sample_layout.dart';
import 'package:tibetan_typesetting/models/project.dart';

void main() {
  test('splitLines splits and trims', () {
    expect(splitLines('a\nb\n'), ['a', 'b']);
    expect(splitLines(''), []);
    expect(splitLines('  hello  '), ['hello']);
  });

  test('paginateBlocks returns at least one page for empty blocks', () {
    final pages = paginateBlocks([], 5);
    expect(pages.length, 1);
    expect(pages[0].rows, isEmpty);
  });

  test('paginateBlocks paginates correctly', () {
    final blocks = List.generate(
      12,
      (i) => TextBlock(id: 'b$i', tibetan: 'text $i'),
    );
    final pages = paginateBlocks(blocks, 3, 4);
    expect(pages.length, 1);
    expect(pages[0].rows.length, 4);
    expect(pages[0].colCount, 3);
  });
}
