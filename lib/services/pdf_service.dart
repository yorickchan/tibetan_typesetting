import 'dart:io';
import 'dart:ui' show Color, TextAlign, instantiateImageCodec;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/app_settings.dart';
import '../models/font_config.dart';
import '../models/project.dart';
import '../services/title_page_template_service.dart';
import '../utils/content_page_template_layout.dart';
import '../utils/font_constants.dart';
import '../utils/font_utils.dart' as font_utils;
import '../utils/sample_layout.dart';
import '../utils/tibetan_segmenter.dart';
import '../utils/text_renderer.dart';
import '../utils/title_page_layout.dart';
import 'font_service.dart';
import 'settings_service.dart';

/// Result of a PDF generation: the produced bytes together with any
/// non-fatal warnings (e.g. fonts that fell back to a default because the
/// original was not supported by the PDF engine).
class PdfGenerationResult {
  final Uint8List bytes;
  final List<String> warnings;
  const PdfGenerationResult({required this.bytes, required this.warnings});
}

const _rose = PdfColor.fromInt(0xFFe11d48);
const _rowLine = PdfColor.fromInt(0xFFFFD700);

const _roseUi = Color(0xFFe11d48);
const _blackUi = Color(0xFF000000);

/// Pre-rendered text image stored for synchronous PDF page construction.
class _Img {
  final pw.MemoryImage provider;
  final double w, h;
  _Img(this.provider, this.w, this.h);
}

class PdfService {
  PdfService._();
  static final PdfService _instance = PdfService._();
  factory PdfService() => _instance;

  final _fontService = FontService();
  String? _dharmaWheelSvg;
  final Map<String, String?> _templateSvgCache = {};
  final Map<String, _Img> _renderCache = {};

  Future<void> _loadSvg() async {
    if (_dharmaWheelSvg != null) return;
    try {
      _dharmaWheelSvg = await rootBundle.loadString(
        'assets/images/dharma_wheel.svg',
      );
    } catch (e) {
      debugPrint('Failed to load dharma wheel SVG: $e');
    }
  }

  Future<String?> _loadTemplateSvg(String templateId) async {
    if (_templateSvgCache.containsKey(templateId)) {
      return _templateSvgCache[templateId];
    }
    final t = await TitlePageTemplateService().getTemplate(templateId);
    _templateSvgCache[templateId] = t?.svgContent;
    return t?.svgContent;
  }

  // ---------------------------------------------------------------------------
  // Pre-render a piece of text through Flutter's HarfBuzz engine and store
  // the resulting image. Tibetan script requires OpenType GSUB/GPOS features
  // (abvs, blws, ccmp, etc.) that the pdf package does not implement, so we
  // rasterise through Flutter's Skia/Impeller pipeline instead.
  // ---------------------------------------------------------------------------
  Future<_Img?> _render(
    String text,
    double fontSize,
    Color color,
    double maxWidth, {
    required String fontFamily,
    List<String>? fontFamilyFallback,
    double? lineHeight,
    double topPadding = 0,
    double bottomPadding = 0,
    TextAlign textAlign = TextAlign.left,
  }) async {
    if (text.trim().isEmpty) return null;

    final key =
        '${text}_|_${fontFamily}_|_${fontSize}_|_${color.toARGB32()}_|_${maxWidth}_|_${lineHeight}_|_${topPadding}_|_${bottomPadding}_|_${textAlign}';
    if (_renderCache.containsKey(key)) {
      return _renderCache[key];
    }

    final r = await renderTextToPng(
      text,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: fontSize,
      color: color,
      maxWidth: maxWidth,
      lineHeight: lineHeight,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
      textAlign: textAlign,
    );
    if (r == null) return null;

    final img = _Img(pw.MemoryImage(r.pngBytes), r.width, r.height);
    _renderCache[key] = img;
    return img;
  }

  // ---------------------------------------------------------------------------

  Future<_Img?> _renderRich(
    List<TextSpanDef> spans,
    double fontSize,
    double maxWidth, {
    required String fontFamily,
    List<String>? fontFamilyFallback,
    double? lineHeight,
    double topPadding = 0,
    double bottomPadding = 0,
    TextAlign textAlign = TextAlign.left,
  }) async {
    if (spans.isEmpty) return null;

    final key =
        'rich_${spans.map((s) => '${s.text}_${s.color.toARGB32()}').join('|')}_|_${fontFamily}_|_${fontSize}_|_${maxWidth}_|_${lineHeight}_|_${topPadding}_|_${bottomPadding}_|_${textAlign}';
    if (_renderCache.containsKey(key)) {
      return _renderCache[key];
    }

    final r = await renderRichTextToPng(
      spans,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: fontSize,
      maxWidth: maxWidth,
      lineHeight: lineHeight,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
      textAlign: textAlign,
    );
    if (r == null) return null;

    final img = _Img(pw.MemoryImage(r.pngBytes), r.width, r.height);
    _renderCache[key] = img;
    return img;
  }

  /// Break [text] into spans where Tibetan non-letters (vowels, tsheg, shad)
  /// use [otherColor] and everything else uses [letterColor].
  List<TextSpanDef> _makeColorizedSpans(
    String text,
    Color letterColor,
    Color otherColor,
  ) {
    final spans = <TextSpanDef>[];
    String? buf;
    Color? bufColor;
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      final color =
          isTibetanNonLetter(c.codeUnitAt(0)) ? otherColor : letterColor;
      if (bufColor == color) {
        buf = buf! + c;
      } else {
        if (buf != null) spans.add(TextSpanDef(buf, bufColor!));
        buf = c;
        bufColor = color;
      }
    }
    if (buf != null) spans.add(TextSpanDef(buf, bufColor!));
    return spans;
  }
  // Public API
  // ---------------------------------------------------------------------------

  Future<Uint8List> generatePdf(
    Project project, {
    AppSettings? appSettings,
  }) async {
    final result = await generatePdfWithWarnings(
      project,
      appSettings: appSettings,
    );
    return result.bytes;
  }

  Future<PdfGenerationResult> generatePdfWithWarnings(
    Project project, {
    AppSettings? appSettings,
  }) async {
    _renderCache.clear();
    await _loadSvg();

    final warnings = <String>[];

    // Resolve effective fonts
    final settings = appSettings ?? await SettingsService().getSettings();
    final ps = project.pageSetup;

    final tibConfig = font_utils.effectiveFont(
      ps.tibetanFont,
      settings.tibetanFont,
      fallbackTibetanFont,
    );
    final pronConfig = font_utils.effectiveFont(
      ps.pronunciationFont,
      settings.pronunciationFont,
      fallbackChineseFont,
    );
    final transConfig = font_utils.effectiveFont(
      ps.translationFont,
      settings.translationFont,
      fallbackChineseFont,
    );

    Future<pw.Font?> tryLoadPdfFont(FontConfig config, String role) async {
      if (config.fontPath.isEmpty) return null;
      try {
        return await _fontService.loadFontForPdf(config);
      } on UnsupportedFontError catch (e) {
        warnings.add('$role: ${e.message}');
        debugPrint('Failed to load $role font for PDF: $e');
        return null;
      } catch (e, s) {
        debugPrint('Failed to load $role font for PDF: $e\n$s');
        return null;
      }
    }

    // Load PDF fonts from file paths (for Chinese text drawn via pw.Text)
    final pronPdfFont = await tryLoadPdfFont(pronConfig, 'pronunciation');
    final transPdfFont = await tryLoadPdfFont(transConfig, 'translation');
    final chiFont = pronPdfFont ?? transPdfFont ?? pw.Font.helvetica();
    final tranFont = transPdfFont ?? pronPdfFont ?? pw.Font.helvetica();

    // Load broad-coverage CJK fallback fonts from system for characters
    // missing from the primary font (e.g. 瓔 U+74D4, 珞 U+73DE).
    final fontFallback = await _fontService.loadCjkFallbackFonts();

    // Title page fonts (fall back to body fonts)
    final titleTibConfig = ps.titleTibetanFont ?? tibConfig;
    final titleChiConfig = ps.titleChineseFont ?? transConfig;

    final titleChiPdfFont = await tryLoadPdfFont(
      titleChiConfig,
      'title Chinese',
    );
    final titleChiFont = titleChiPdfFont ?? tranFont;

    // Font families for pre-rendered text (Tibetan through HarfBuzz)
    final tibFamily = tibConfig.fontFamily;
    final transFamily = transConfig.fontFamily;

    final pageW = ps.pageWidthMm * PdfPageFormat.mm;
    final pageH = ps.pageHeightMm * PdfPageFormat.mm;
    final pageFormat = PdfPageFormat(pageW, pageH);

    final marginL = ps.marginMm.left * PdfPageFormat.mm;
    final marginR = ps.marginMm.right * PdfPageFormat.mm;
    final marginT = ps.marginMm.top * PdfPageFormat.mm;
    final marginB = ps.marginMm.bottom * PdfPageFormat.mm;

    final outerW = pageW - marginL - marginR;
    final outerH = pageH - marginT - marginB;
    final sideW = 18 * PdfPageFormat.mm;
    final inset = 2 * PdfPageFormat.mm;

    final contentWidthMm =
        ps.pageWidthMm - ps.marginMm.left - ps.marginMm.right;
    final pages = paginateBlocks(
      project.blocks,
      0,
      4,
      ps.flowGap,
      contentWidthMm,
    );

    final contentH = outerH - 4 * inset;

    // Title page template SVG (load before pre-rendering so we can rasterize)
    String? titlePageSvg;
    if (ps.titlePageTemplateId != null) {
      titlePageSvg = await _loadTemplateSvg(ps.titlePageTemplateId!);
    }
    final hasTemplate = titlePageSvg != null && titlePageSvg.isNotEmpty;

    // Content page template SVGs
    String? contentFirstPageSvg;
    String? contentSubsequentPageSvg;
    if (ps.contentFirstPageTemplateId != null) {
      contentFirstPageSvg =
          await _loadTemplateSvg(ps.contentFirstPageTemplateId!);
    }
    if (ps.contentSubsequentPageTemplateId != null) {
      contentSubsequentPageSvg =
          await _loadTemplateSvg(ps.contentSubsequentPageTemplateId!);
    }


    // ---- pre-render all text as images (side panels, images) and shape
    // ---- Tibetan text through HarfBuzz for vector rendering.

    final tibFontSize = tibConfig.fontSize;

    final smallBlockFontSize = ps.smallBlockFontSize ?? settings.smallBlockFontSize;

    final imgs = <String, _Img>{};
    final tasks = <Future<void>>[];

    Future<void> put(String key, Future<_Img?> future) async {
      final img = await future;
      if (img != null) imgs[key] = img;
    }

    // Title page Tibetan (PNG rasterization)
    if (ps.showTitlePage && ps.titleTibetan.trim().isNotEmpty) {
      tasks.add(put('title_tib',
          _render(ps.titleTibetan, titleTibConfig.fontSize, _blackUi, outerW,
              fontFamily: titleTibConfig.fontFamily,
              lineHeight: 1.4, topPadding: 5, textAlign: TextAlign.center)));
    }


    // Left side panel
    if (ps.leftVerticalTitle.trim().isNotEmpty) {
      tasks.add(
        put(
          'side_left',
          _render(
            ps.leftVerticalTitle,
            9,
            _blackUi,
            contentH,
            fontFamily: transFamily,
            fontFamilyFallback: [tibFamily],
          ),
        ),
      );
    }

    // Content blocks
    for (var pi = 0; pi < pages.length; pi++) {
      final page = pages[pi];
      for (var ri = 0; ri < page.flowRows.length; ri++) {
        final row = page.flowRows[ri];
        for (var cellIndex = 0; cellIndex < row.length; cellIndex++) {
          final cell = row[cellIndex];
          final block = cell.block;
          if (block.isImageBlock) {
            final key = '${pi}_${ri}_$cellIndex';
            final file = File(block.imagePath!);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              double w = 120, h = 120;
              try {
                final codec = await instantiateImageCodec(bytes);
                final frame = await codec.getNextFrame();
                w = frame.image.width.toDouble();
                h = frame.image.height.toDouble();
                frame.image.dispose();
              } catch (_) {}
              imgs['${key}_h'] = _Img(pw.MemoryImage(bytes), w, h);
            }
            continue;
          }

          final key = '${pi}_${ri}_$cellIndex';
          final tibLines = splitLines(block.tibetan);
          final heading = tibLines.isNotEmpty ? tibLines[0] : '';
          final body =
              tibLines.length > 1 ? tibLines.sublist(1).join('\n') : '';

          final small = block.smallText;
          final tibContentSize = contentTibetanFontSize(
            tibFontSize,
            smallText: small,
            smallBlockFontSize: small ? smallBlockFontSize : null,
          );
          if (heading.isNotEmpty) {
            final segs = splitByRedHighlightRanges(heading, block.redHighlightRange);
            if (segs.isEmpty) {
              tasks.add(put('${key}_h',
                  _render(heading, tibContentSize, _blackUi, outerW,
                      fontFamily: tibConfig.fontFamily,
                      lineHeight: contentTibetanLineHeight(smallText: small),
                      topPadding: contentTibetanPngTopPadding)));
            } else {
              final spans = <TextSpanDef>[];
              for (final s in segs) {
                if (s.highlight) {
                  spans.addAll(_makeColorizedSpans(s.text, _roseUi, _blackUi));
                } else {
                  spans.add(TextSpanDef(s.text, _blackUi));
                }
              }
              if (spans.isNotEmpty) {
                tasks.add(put('${key}_h',
                    _renderRich(spans, tibContentSize, outerW,
                        fontFamily: tibConfig.fontFamily,
                        lineHeight: contentTibetanLineHeight(smallText: small),
                        topPadding: contentTibetanPngTopPadding)));
              }
            }
          }
          // Tibetan body (PNG rasterization)
          if (body.isNotEmpty) {
            tasks.add(put('${key}_b',
                _render(body, tibContentSize, _blackUi, outerW,
                    fontFamily: tibConfig.fontFamily,
                    lineHeight: contentTibetanLineHeight(smallText: small),
                    topPadding: contentTibetanPngTopPadding)));
          }
        }
      }
    }

    // Wait for any remaining async tasks (side panel pre-render)
    await Future.wait(tasks);
    final doc = pw.Document();

    if (ps.showTitlePage) {
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: hasTemplate
              ? pw.EdgeInsets.zero
              : pw.EdgeInsets.only(
                  left: marginL,
                  right: marginR,
                  top: marginT,
                  bottom: marginB,
                ),
          build: (_) => _buildTitlePage(
            ps: ps,
            projectName: project.name,
            chiFont: titleChiFont,
            chiFontSize: titleChiConfig.fontSize,
            fontFallback: fontFallback,
            outerW: hasTemplate ? pageW : outerW,
            outerH: hasTemplate ? pageH : outerH,
            sideW: sideW,
            inset: inset,
            imgs: imgs,
            titlePageSvg: titlePageSvg,
          ),
        ),
      );
    }

    for (var pageIdx = 0; pageIdx < pages.length; pageIdx++) {
      final page = pages[pageIdx];
      final pageNumber = resolvePageNumber(ps.pageNumber, pageIdx);
      final isFirstPage = pageIdx == 0;

      final pageMargin = isFirstPage
          ? ps.contentFirstPageMargin
          : ps.contentSubsequentPageMargin;
      final pageMarginL = pageMargin.left * PdfPageFormat.mm;
      final pageMarginR = pageMargin.right * PdfPageFormat.mm;
      final pageMarginT = pageMargin.top * PdfPageFormat.mm;
      final pageMarginB = pageMargin.bottom * PdfPageFormat.mm;
      final pageOuterW = pageW - pageMarginL - pageMarginR;
      final pageOuterH = pageH - pageMarginT - pageMarginB;

      final pageTemplateSvg = isFirstPage
          ? contentFirstPageSvg
          : contentSubsequentPageSvg;
      final pageTemplateInset = isFirstPage
          ? ps.contentFirstPageTemplateInset
          : ps.contentSubsequentPageTemplateInset;
      final hasPageTemplate =
          pageTemplateSvg != null && pageTemplateSvg.isNotEmpty;
      final templateLayout = hasPageTemplate
          ? contentPageTemplateLayout(
              pageWidthMm: ps.pageWidthMm,
              pageHeightMm: ps.pageHeightMm,
              contentMargin: pageMargin,
              templateInset: pageTemplateInset,
            )
          : null;

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: hasPageTemplate
              ? pw.EdgeInsets.zero
              : pw.EdgeInsets.only(
                  left: pageMarginL,
                  right: pageMarginR,
                  top: pageMarginT,
                  bottom: pageMarginB,
                ),
          build: (_) => _buildContentPage(
            ps: ps,
            page: page,
            pageIdx: pageIdx,
            pronFont: chiFont,
            transFont: tranFont,
            fontFallback: fontFallback,
            pronFontSize: pronConfig.fontSize,
            transFontSize: transConfig.fontSize,
            tibFontSize: tibFontSize,
            smallBlockFontSize: smallBlockFontSize,
            outerW: hasPageTemplate ? pageW : pageOuterW,
            outerH: hasPageTemplate ? pageH : pageOuterH,
            sideW: sideW,
            inset: inset,
            pageNumber: pageNumber,
            imgs: imgs,
            templateSvg: pageTemplateSvg,
            templateLayout: templateLayout,
          ),
        ),
      );
    }

    final bytes = await doc.save();
    return PdfGenerationResult(bytes: bytes, warnings: warnings);
  }

  // ---------------------------------------------------------------------------
  // Title page
  // ---------------------------------------------------------------------------

  pw.Widget _buildTitlePage({
    required PageSetup ps,
    required String projectName,
    required pw.Font chiFont,
    required double chiFontSize,
    required List<pw.Font> fontFallback,
    required double outerW,
    required double outerH,
    required double sideW,
    required double inset,
    required Map<String, _Img> imgs,
    String? titlePageSvg,
  }) {
    final titleChinese =
        (ps.titleChinese.isNotEmpty ? ps.titleChinese : projectName).trim();

    if (titlePageSvg != null && titlePageSvg.isNotEmpty) {
      final templateBounds = titlePageTemplateBounds(ps);
      final titleBoxBounds = titlePageTemplateTitleBoxBounds(ps);
      final il = templateBounds.leftMm * PdfPageFormat.mm;
      final it = templateBounds.topMm * PdfPageFormat.mm;
      final titleLeft = titleBoxBounds.leftMm * PdfPageFormat.mm;
      final titleTop = titleBoxBounds.topMm * PdfPageFormat.mm;
      final titleW = titleBoxBounds.widthMm * PdfPageFormat.mm;
      final titleH = titleBoxBounds.heightMm * PdfPageFormat.mm;
      final tibImg = imgs['title_tib'];
      return pw.Stack(
        children: [
          pw.Positioned(
            left: il,
            top: it,
            child: pw.SvgImage(
              svg: titlePageSvg,
              width: templateBounds.widthMm * PdfPageFormat.mm,
              height: templateBounds.heightMm * PdfPageFormat.mm,
              fit: pw.BoxFit.fill,
            ),
          ),
          pw.Positioned(
            left: titleLeft,
            top: titleTop,
            child: pw.SizedBox(
              width: titleW,
              height: titleH,
              child: pw.Center(
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (tibImg != null)
                      pw.Image(
                        tibImg.provider,
                        width: tibImg.w,
                        height: tibImg.h,
                      ),
                    pw.SizedBox(height: tibImg != null ? 6 : 0),
                    pw.Text(
                      titleChinese.isEmpty ? ' ' : titleChinese,
                      style: pw.TextStyle(
                        font: chiFont,
                        fontFallback: fontFallback,
                        fontSize: chiFontSize,
                        color: PdfColors.black,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final framePad = 6 * PdfPageFormat.mm;
    final panelPadY = 2 * PdfPageFormat.mm;
    final panelInnerPadX = 6 * PdfPageFormat.mm;
    final innerH = outerH - 2 * inset - 2 * panelPadY;
    final panelW = innerH * 0.6;
    final titleGap = 3 * PdfPageFormat.mm;

    pw.Widget crestPanel() {
      return pw.Container(
        width: panelW,
        height: innerH,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: _rose, width: 0.75),
            right: pw.BorderSide(color: _rose, width: 0.75),
          ),
        ),
        child: _dharmaWheelSvg != null
            ? pw.Center(
                child: pw.Padding(
                  padding: pw.EdgeInsets.all(panelInnerPadX),
                  child: pw.SvgImage(svg: _dharmaWheelSvg!),
                ),
              )
            : pw.SizedBox(),
      );
    }

    final tibImg = imgs['title_tib'];


    pw.Widget titleBox() {
      final titleBoxW =
          outerW - 2 * (inset + framePad) - 2 * panelW - 2 * titleGap;

      return pw.Container(
        width: titleBoxW,
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _rose, width: 3),
        ),
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _rose, width: 1.5),
          ),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (tibImg != null)
                pw.Image(tibImg.provider, width: tibImg.w, height: tibImg.h),
              if (tibImg == null)
                pw.Text(
                  ' ',
                  style: pw.TextStyle(
                    font: chiFont,
                    fontFallback: fontFallback,
                    fontSize: chiFontSize,
                  ),
                ),
              pw.SizedBox(height: 6),
              pw.Text(
                titleChinese.isEmpty ? ' ' : titleChinese,
                style: pw.TextStyle(
                  font: chiFont,
                  fontFallback: fontFallback,
                  fontSize: chiFontSize,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
          ),
        );
    }

    final content = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(width: framePad - inset),
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(vertical: panelPadY),
          child: crestPanel(),
        ),
        pw.SizedBox(width: titleGap),
        pw.Expanded(child: pw.Center(child: titleBox())),
        pw.SizedBox(width: titleGap),
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(vertical: panelPadY),
          child: crestPanel(),
        ),
        pw.SizedBox(width: framePad - inset),
      ],
    );

    if (ps.showFrame) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _rose, width: 1.5),
        ),
        child: pw.Container(
          margin: pw.EdgeInsets.all(inset),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _rose, width: 0.5),
          ),
          child: content,
        ),
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _rose, width: 0.5),
      ),
      child: content,
    );
  }

  // ---------------------------------------------------------------------------
  // Content page
  // ---------------------------------------------------------------------------

  pw.Widget _buildContentPage({
    required PageSetup ps,
    required PageLayout page,
    required int pageIdx,
    required pw.Font pronFont,
    required pw.Font transFont,
    required List<pw.Font> fontFallback,
    required double pronFontSize,
    required double transFontSize,
    required double tibFontSize,
    required double? smallBlockFontSize,
    required double outerW,
    required double outerH,
    required double sideW,
    required double inset,
    required String pageNumber,
    required Map<String, _Img> imgs,
    String? templateSvg,
    ContentPageTemplateLayout? templateLayout,
  }) {
    final hasPageTemplate =
        templateSvg != null && templateSvg.isNotEmpty;
    final sideImg = imgs['side_left'];
    pw.Widget sidePanel(String? text, {_Img? image}) {
      if (hasPageTemplate) return pw.SizedBox();
      pw.Widget? inner;
      if (image != null) {
        inner = pw.Transform.rotateBox(
          angle: 1.5708,
          child: pw.Image(image.provider, width: image.w, height: image.h),
        );
      } else if (text != null && text.isNotEmpty) {
        inner = pw.Transform.rotateBox(
          angle: 1.5708,
          child: pw.Text(
            text,
            style: pw.TextStyle(
              font: transFont,
              fontFallback: fontFallback,
              fontSize: 9,
              color: _rose,
            ),
            textAlign: pw.TextAlign.center,
          ),
        );
      }
      return pw.Container(
        width: sideW - 2 * inset,
        decoration: ps.showFrame
            ? pw.BoxDecoration(border: pw.Border.all(color: _rose, width: 0.5))
            : null,
        child: inner != null ? pw.Center(child: inner) : pw.SizedBox(),
      );
    }

    pw.Widget contentArea(double cW, double cH) {
      final rows = page.flowRows;
      if (rows.isEmpty) return pw.SizedBox.expand();

      final rowCount = rows.length;
      final padX = 2 * PdfPageFormat.mm;
      // Precompute row Y offsets
      final rowYs = <double>[];
      final smallTibetanSize = contentTibetanFontSize(
        tibFontSize,
        smallText: true,
        smallBlockFontSize: smallBlockFontSize,
      );
      final smallScale = smallBlockFontSize != null
          ? smallBlockFontSize! / tibFontSize
          : 0.75;
      final smallChineseSize = pronFontSize * smallScale;
      final compactMinimumHeights = <double>[];
      for (var ri = 0; ri < rowCount; ri++) {
        compactMinimumHeights.add(estimateCompactSmallRowHeight(
          rows[ri],
          tibetanFontSize: smallTibetanSize,
          chineseFontSize: smallChineseSize,
          topPadding: contentTibetanPngTopPadding,
          tibetanLineHeight: contentTibetanLineHeight(smallText: true),
          chineseLineHeight: 1.4,
        ));
      }
      final rowHeights = resolveContentRowHeights(
        rows,
        contentHeight: cH,
        compactMinimumHeights: compactMinimumHeights,
      );
      double yAccum = 0;
      for (final rowHeight in rowHeights) {
        rowYs.add(yAccum);
        yAccum += rowHeight;
      }

      pw.Widget buildBlock(String key, TextBlock block, double maxW) {
        final small = block.smallText;
        final freeText = block.isFreeText;
        final pronSize = pronFontSize * (small ? smallScale : 1.0);
        final transSize = transFontSize * (small || freeText ? smallScale : 1.0);

        final pron = splitLines(block.chinesePronunciation).join('\n');
        final trans = small || freeText
            ? ''
            : splitLines(block.chineseTranslation).join('\n');
        final freeTextContent = splitLines(block.tibetan).join('\n');

        final hImg = imgs['${key}_h'];
        final bImg = imgs['${key}_b'];

        if (block.isOpeningMark) {
          return hImg != null
              ? pw.Image(hImg.provider, width: hImg.w, height: hImg.h)
              : pw.SizedBox();
        }

        return pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (freeText && freeTextContent.isNotEmpty)
              pw.Text(
                freeTextContent,
                style: pw.TextStyle(
                  font: transFont,
                  fontFallback: fontFallback,
                  fontSize: transSize,
                  color: PdfColors.black,
                  lineSpacing: transSize * 0.4,
                ),
              ),
            if (!freeText) ...[
              if (hImg != null && block.isImageBlock) ...[
                pw.Image(
                  hImg.provider,
                  width: block.imageWidthMm != null
                      ? (block.imageWidthMm! * PdfPageFormat.mm).clamp(
                          10.0, maxW)
                      : hImg.w * (maxW / hImg.w).clamp(0.1, 1.0),
                  height: block.imageWidthMm != null
                      ? (hImg.h *
                            ((block.imageWidthMm! * PdfPageFormat.mm)
                                    .clamp(10.0, maxW) /
                                hImg.w))
                      : hImg.h * (maxW / hImg.w).clamp(0.1, 1.0),
                ),
              ] else if (hImg != null)
                pw.Image(hImg.provider, width: hImg.w, height: hImg.h),
              if (bImg != null)
                pw.Image(bImg.provider, width: bImg.w, height: bImg.h),
            ],
            if (pron.isNotEmpty)
              pw.Text(pron,
                  style: pw.TextStyle(
                      font: pronFont,
                      fontFallback: fontFallback,
                      fontSize: pronSize,
                      color: PdfColors.black,
                      lineSpacing: pronSize * 0.4)),
            if (trans.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 1),
                child: pw.Text(trans,
                    style: pw.TextStyle(
                        font: transFont,
                        fontFallback: fontFallback,
                        fontSize: transSize,
                        color: PdfColors.black,
                        lineSpacing: transSize * 0.4)),
              ),
          ],
        );
      }

      final positioned = <pw.Widget>[];
      final rowLineYOffset = 7 * PdfPageFormat.mm / 3.78;
      if (ps.showRowLines) {
        const rowLineH = 0.6;
        for (var ri = 0; ri < rows.length; ri++) {
          final hasNormalBlock = rows[ri].any(
            (cell) =>
                !cell.block.smallText &&
                !cell.block.isFreeText &&
                !cell.block.isImageBlock,
          );
          if (!hasNormalBlock) continue;
          positioned.add(
            pw.Positioned(
              left: 0,
              top: rowYs[ri] + rowLineYOffset,
              child: pw.Container(width: cW, height: rowLineH, color: _rowLine),
            ),
          );
        }
      }
      for (var ri = 0; ri < rows.length; ri++) {
        final row = rows[ri];
        for (var cellIndex = 0; cellIndex < row.length; cellIndex++) {
          final cell = row[cellIndex];
          final block = cell.block;
          final key = '${pageIdx}_${ri}_$cellIndex';
          final left = cell.leftFraction * cW;
          final spannedW = cell.widthFraction * cW;
          final blockW =
              (block.smallText || block.isFreeText) && block.columnSpan == null
              ? (cW - left - padX * 2)
              : (spannedW - padX * 2);
          positioned.add(
            pw.Positioned(
              left: left + padX,
              top: rowYs[ri],
              child: pw.SizedBox(
                width: blockW,
                child: buildBlock(key, block, blockW),
              ),
            ),
          );
        }
      }

      // ---- Floating image overlay ----
      for (final fi in page.floatingImages) {
        final imgX = (fi.imageXMm ?? 10) * PdfPageFormat.mm;
        final imgY = (fi.imageYMm ?? 10) * PdfPageFormat.mm;
        final imgW = (fi.imageWidthMm ?? 30) * PdfPageFormat.mm;
        final imgH = (fi.imageHeightMm ?? 30) * PdfPageFormat.mm;
        if (fi.imagePath != null) {
          positioned.add(
            pw.Positioned(
              left: imgX,
              top: imgY,
              child: pw.SizedBox(
                width: imgW,
                height: imgH,
                child: pw.ClipRRect(
                  horizontalRadius: 2,
                  verticalRadius: 2,
                  child: pw.Image(
                    pw.MemoryImage(File(fi.imagePath!).readAsBytesSync()),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            ),
          );
        }
      }

      return pw.SizedBox(
        width: cW,
        height: cH,
        child: pw.Stack(overflow: pw.Overflow.visible, children: positioned),
      );
    }

    final templateContent = templateLayout?.content;
    final contentPadL = hasPageTemplate
        ? templateContent!.leftMm * PdfPageFormat.mm
        : inset;
    final contentPadT = hasPageTemplate
        ? templateContent!.topMm * PdfPageFormat.mm
        : inset;
    final contentPadR = hasPageTemplate
        ? (outerW - templateContent!.leftMm * PdfPageFormat.mm -
              templateContent.widthMm * PdfPageFormat.mm)
        : inset;
    final contentPadB = hasPageTemplate
        ? (outerH - templateContent!.topMm * PdfPageFormat.mm -
              templateContent.heightMm * PdfPageFormat.mm)
        : inset;
    final sidePW = hasPageTemplate ? 0.0 : sideW - 2 * inset;
    final cW = hasPageTemplate
        ? templateContent!.widthMm * PdfPageFormat.mm
        : outerW - 2 * inset - 2 * sidePW;
    final cH = hasPageTemplate
        ? templateContent!.heightMm * PdfPageFormat.mm
        : outerH - 4 * inset;
    pw.Widget buildInner() {
      return pw.Row(
        children: [
          sidePanel(ps.leftVerticalTitle, image: sideImg),
          pw.Expanded(child: pw.Container(child: contentArea(cW, cH))),
          sidePanel(pageNumber),
        ],
      );
    }

    pw.Widget contentPage;
    if (ps.showFrame && !hasPageTemplate) {
      contentPage = pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _rose, width: 1.5),
        ),
        child: pw.Container(
          margin: pw.EdgeInsets.all(inset),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _rose, width: 0.5),
          ),
          child: buildInner(),
        ),
      );
    } else {
      contentPage = pw.Padding(
          padding: pw.EdgeInsets.only(
            left: contentPadL,
            top: contentPadT,
            right: contentPadR,
            bottom: contentPadB,
          ),
          child: buildInner());
    }

    if (!hasPageTemplate) return contentPage;

    final templateBounds = templateLayout!.template;
    final il = templateBounds.leftMm * PdfPageFormat.mm;
    final it = templateBounds.topMm * PdfPageFormat.mm;
    final svgW = templateBounds.widthMm * PdfPageFormat.mm;
    final svgH = templateBounds.heightMm * PdfPageFormat.mm;

    return pw.Stack(
      children: [
        pw.Positioned(
          left: il,
          top: it,
          child: pw.SvgImage(
            svg: templateSvg,
            width: svgW,
            height: svgH,
            fit: pw.BoxFit.fill,
          ),
        ),
        contentPage,
        if (ps.leftVerticalTitle.trim().isNotEmpty)
          pw.Positioned(
            left: 0,
            top: 0,
            child: pw.SizedBox(
              width: 10 * PdfPageFormat.mm,
              height: outerH,
              child: pw.Center(
                child: pw.Transform.rotateBox(
                  angle: 1.5708,
                  child: pw.Text(
                    ps.leftVerticalTitle,
                    style: pw.TextStyle(
                      font: transFont,
                      fontFallback: fontFallback,
                      fontSize: 9,
                      color: _rose,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        if (pageNumber.trim().isNotEmpty)
          pw.Positioned(
            left: outerW - 10 * PdfPageFormat.mm,
            top: 0,
            child: pw.SizedBox(
              width: 10 * PdfPageFormat.mm,
              height: outerH,
              child: pw.Center(
                child: pw.Transform.rotateBox(
                  angle: 1.5708,
                  child: pw.Text(
                    pageNumber,
                    style: pw.TextStyle(
                      font: transFont,
                      fontFallback: fontFallback,
                      fontSize: 9,
                      color: _rose,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
