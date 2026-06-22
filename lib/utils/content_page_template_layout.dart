import '../models/project.dart';

class ContentPageTemplateBounds {
  final double leftMm;
  final double topMm;
  final double widthMm;
  final double heightMm;

  const ContentPageTemplateBounds({
    required this.leftMm,
    required this.topMm,
    required this.widthMm,
    required this.heightMm,
  });
}

class ContentPageTemplateLayout {
  final ContentPageTemplateBounds content;
  final ContentPageTemplateBounds template;

  const ContentPageTemplateLayout({
    required this.content,
    required this.template,
  });
}

ContentPageTemplateLayout contentPageTemplateLayout({
  required double pageWidthMm,
  required double pageHeightMm,
  required MarginMm contentMargin,
  required TemplateInset templateInset,
}) {
  return ContentPageTemplateLayout(
    content: ContentPageTemplateBounds(
      leftMm: contentMargin.left,
      topMm: contentMargin.top,
      widthMm: pageWidthMm - contentMargin.left - contentMargin.right,
      heightMm: pageHeightMm - contentMargin.top - contentMargin.bottom,
    ),
    template: ContentPageTemplateBounds(
      leftMm: templateInset.left,
      topMm: templateInset.top,
      widthMm: pageWidthMm - templateInset.left - templateInset.right,
      heightMm: pageHeightMm - templateInset.top - templateInset.bottom,
    ),
  );
}
