import 'package:flutter_test/flutter_test.dart';

import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/utils/content_page_template_layout.dart';

void main() {
  test('content bounds use page margins while template bounds use its inset', () {
    final layout = contentPageTemplateLayout(
      pageWidthMm: 300,
      pageHeightMm: 120,
      contentMargin: const MarginMm(top: 9, right: 25, bottom: 13, left: 21),
      templateInset: const TemplateInset(top: 3, right: 7, bottom: 5, left: 11),
    );

    expect(layout.content.leftMm, 21);
    expect(layout.content.topMm, 9);
    expect(layout.content.widthMm, 254);
    expect(layout.content.heightMm, 98);
    expect(layout.template.leftMm, 11);
    expect(layout.template.topMm, 3);
    expect(layout.template.widthMm, 282);
    expect(layout.template.heightMm, 112);
  });
}
