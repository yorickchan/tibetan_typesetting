import 'package:flutter_test/flutter_test.dart';

import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/utils/sample_layout.dart';

void main() {
  test('compact rows use their content height and expand normal rows', () {
    final rows = [
      [
        LayoutCell(
          block: TextBlock(id: 'small', tibetan: 'བོད།', smallText: true),
          leftFraction: 0,
          widthFraction: 1,
        ),
      ],
      [
        LayoutCell(
          block: TextBlock(id: 'normal', tibetan: 'བོད།'),
          leftFraction: 0,
          widthFraction: 1,
        ),
      ],
    ];

    expect(
      resolveContentRowHeights(
        rows,
        contentHeight: 200,
        compactMinimumHeights: [30, 0],
      ),
      [30, 170],
    );
  });
}
