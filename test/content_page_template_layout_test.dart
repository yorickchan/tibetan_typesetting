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

  test('each page configuration retains its own content margin', () {
    final first = contentPageTemplateLayout(
      pageWidthMm: 300,
      pageHeightMm: 120,
      contentMargin: const MarginMm(left: 20, right: 20),
      templateInset: const TemplateInset(left: 5, right: 5),
    );
    final subsequent = contentPageTemplateLayout(
      pageWidthMm: 300,
      pageHeightMm: 120,
      contentMargin: const MarginMm(left: 35, right: 15),
      templateInset: const TemplateInset(left: 9, right: 3),
    );

    expect(first.content.widthMm, 260);
    expect(subsequent.content.leftMm, 35);
    expect(subsequent.content.widthMm, 250);
    expect(subsequent.template.leftMm, 9);
    expect(subsequent.template.widthMm, 288);
  });
}
