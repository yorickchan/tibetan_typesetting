import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/utils/title_page_layout.dart';

void main() {
  test('custom title page template bounds ignore regular page margins', () {
    final setup = PageSetup(
      pageWidthMm: 300,
      pageHeightMm: 120,
      marginMm: const MarginMm(top: 10, right: 10, bottom: 10, left: 10),
      templateInset: const TemplateInset(
        top: 24,
        right: 12,
        bottom: 24,
        left: 12,
      ),
      titleTextInset: const TemplateInset(
        top: 24,
        right: 55.2,
        bottom: 24,
        left: 55.2,
      ),
    );

    final bounds = titlePageTemplateBounds(setup);

    expect(bounds.leftMm, 12);
    expect(bounds.topMm, 24);
    expect(bounds.widthMm, 276);
    expect(bounds.heightMm, 72);
  });

  test('custom title page template text width uses PDF points', () {
    final setup = PageSetup(
      pageWidthMm: 300,
      pageHeightMm: 120,
      templateInset: const TemplateInset(
        top: 24,
        right: 12,
        bottom: 24,
        left: 12,
      ),
      titleTextInset: const TemplateInset(
        top: 24,
        right: 55.2,
        bottom: 24,
        left: 55.2,
      ),
    );

    final width = titlePageTemplateTextWidthPt(setup);

    expect(width, closeTo(189.6 * pdfPointsPerMm, 0.001));
  });

  test('custom title page text box stays in central template area', () {
    final setup = PageSetup(
      pageWidthMm: 300,
      pageHeightMm: 120,
      titleTextInset: const TemplateInset(
        top: 30,
        right: 50,
        bottom: 25,
        left: 60,
      ),
    );

    final bounds = titlePageTemplateTitleBoxBounds(setup);

    expect(bounds.leftMm, 60);
    expect(bounds.topMm, 30);
    expect(bounds.widthMm, 190);
    expect(bounds.heightMm, 65);
  });
}
