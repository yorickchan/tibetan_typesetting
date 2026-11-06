import '../models/project.dart';

const double pdfPointsPerMm = 72 / 25.4;

/// Flutter logical pixels assume 96 DPI; PDF points are 72 per inch.
const double pxToPdfPoints = 72 / 96;

/// Vertical gap between the Tibetan and Chinese title lines, in PDF points.
double titleTextGapPoints(PageSetup setup) =>
    setup.titleTextGapPx * pxToPdfPoints;

class TitlePageTemplateBounds {
  final double leftMm;
  final double topMm;
  final double widthMm;
  final double heightMm;

  const TitlePageTemplateBounds({
    required this.leftMm,
    required this.topMm,
    required this.widthMm,
    required this.heightMm,
  });
}

double titlePageTemplateTextWidthPt(PageSetup setup) {
  return titlePageTemplateTitleBoxBounds(setup).widthMm * pdfPointsPerMm;
}

TitlePageTemplateBounds titlePageTemplateBounds(PageSetup setup) {
  final inset = setup.templateInset;
  return TitlePageTemplateBounds(
    leftMm: inset.left,
    topMm: inset.top,
    widthMm: setup.pageWidthMm - inset.left - inset.right,
    heightMm: setup.pageHeightMm - inset.top - inset.bottom,
  );
}

TitlePageTemplateBounds titlePageTemplateTitleBoxBounds(PageSetup setup) {
  final inset = setup.titleTextInset;
  final width = setup.pageWidthMm - inset.left - inset.right;
  final height = setup.pageHeightMm - inset.top - inset.bottom;
  return TitlePageTemplateBounds(
    leftMm: inset.left,
    topMm: inset.top,
    widthMm: width > 0 ? width : 0,
    heightMm: height > 0 ? height : 0,
  );
}
