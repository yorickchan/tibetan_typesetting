import 'dart:io';
import 'dart:ui' show instantiateImageCodec;

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
import '../utils/shaped_text_pdf.dart';
import '../utils/title_page_layout.dart';
import 'font_service.dart';
import 'settings_service.dart';
import 'pdf_service_core.dart';

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
  List<ShapedTextFont> _chineseShapingFonts = const [];
  ShapedTextFont? _rareGlyphShapingFont;
  String? _dharmaWheelSvg;
  final Map<String, String?> _templateSvgCache = {};

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
    clearShapedGlyphCache();
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

    // Shaping equivalents for the Chinese text paths, plus the macOS
    // .LastResort font. The pdf package cannot embed .LastResort (CFF), but
    // HarfBuzz can shape its outlines for rare glyphs that no native font
    // covers (e.g. U+27593).
    final chineseShaping = <ShapedTextFont>[];
    for (final config in [pronConfig, transConfig, titleChiConfig]) {
      final shaped = await _fontService.shapingFont(config);
      if (shaped != null && !chineseShaping.any((f) => identical(f, shaped))) {
        chineseShaping.add(shaped);
      }
    }
    _chineseShapingFonts = chineseShaping;
    _rareGlyphShapingFont = Platform.isMacOS
        ? await _fontService.shapingFont(
            const FontConfig(
              fontFamily: '.LastResort',
              fontPath: '/System/Library/Fonts/LastResort.otf',
              fontSize: 10,
            ),
          )
        : null;

    // Tibetan is drawn as shaped vector outlines through HarfBuzz; the same
    // bytes also feed the invisible Unicode text layer.
    //
    // Tibetan-only fonts often lack Latin/punctuation glyphs (Kailasa has no
    // U+002D), so the Chinese fonts are appended as shaping fallbacks. Flutter
    // does the same on screen, which is why the preview never shows the gap.
    final tibShaping = await _fontService.shapingFont(tibConfig);
    if (tibShaping == null) {
      warnings.add(
        'tibetan: no usable font file is configured, Tibetan text is omitted '
        'from the PDF.',
      );
    }
    final tibFallbacks = <ShapedTextFont>[];
    for (final config in [pronConfig, transConfig, titleChiConfig]) {
      final font = await _fontService.shapingFont(config);
      if (font == null || font == tibShaping) continue;
      if (tibFallbacks.contains(font)) continue;
      tibFallbacks.add(font);
    }
    final tibFonts = <ShapedTextFont>[
      if (tibShaping != null) tibShaping,
      ...tibFallbacks,
    ];

    List<ShapedTextFont> titleTibFonts;
    if (titleTibConfig.fontPath == tibConfig.fontPath) {
      titleTibFonts = tibFonts;
    } else {
      final titleFont = await _fontService.shapingFont(titleTibConfig);
      titleTibFonts = <ShapedTextFont>[
        if (titleFont != null) titleFont,
        ...tibFallbacks,
      ];
    }
    final titleChiFont = titleChiPdfFont ?? tranFont;

    final pageW = ps.pageWidthMm * PdfPageFormat.mm;
    final pageH = ps.pageHeightMm * PdfPageFormat.mm;
    final pageFormat = PdfPageFormat(pageW, pageH);

    final marginL = ps.marginMm.left * PdfPageFormat.mm;
    final marginR = ps.marginMm.right * PdfPageFormat.mm;
    final marginT = ps.marginMm.top * PdfPageFormat.mm;
    final marginB = ps.marginMm.bottom * PdfPageFormat.mm;

    final outerW = pageW - marginL - marginR;
    final outerH = pageH - marginT - marginB;
    const sideW = 18 * PdfPageFormat.mm;
    const inset = 2 * PdfPageFormat.mm;

    final contentWidthMm =
        ps.pageWidthMm - ps.marginMm.left - ps.marginMm.right;
    final pages = paginateBlocks(
      project.blocks,
      0,
      4,
      ps.flowGap,
      contentWidthMm,
    );

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
      contentFirstPageSvg = await _loadTemplateSvg(
        ps.contentFirstPageTemplateId!,
      );
    }
    if (ps.contentSubsequentPageTemplateId != null) {
      contentSubsequentPageSvg = await _loadTemplateSvg(
        ps.contentSubsequentPageTemplateId!,
      );
    }

    // Inline images are loaded up front; all text is drawn natively.

    final tibFontSize = tibConfig.fontSize;

    final smallBlockFontSize =
        ps.smallBlockFontSize ?? settings.smallBlockFontSize;

    final imgs = <String, _Img>{};

    // Inline images only; all text is drawn as real PDF text later.
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

          // Chinese, free text and side-panel labels are drawn as real PDF
          // text in _buildContentPage, so only images need pre-loading here.
        }
      }
    }

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
          build: (context) => _buildTitlePage(
            context: context,
            ps: ps,
            projectName: project.name,
            chiFont: titleChiFont,
            chiFontSize: titleChiConfig.fontSize,
            fontFallback: fontFallback,
            outerW: hasTemplate ? pageW : outerW,
            outerH: hasTemplate ? pageH : outerH,
            sideW: sideW,
            inset: inset,
            titleTibFonts: titleTibFonts,
            titleTibFontSize: titleTibConfig.fontSize,
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
          build: (context) => _buildContentPage(
            context: context,
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
            pageMargin: pageMargin,
            tibFonts: tibFonts,
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
  // Tibetan text (shaped vector outlines + invisible Unicode text layer)
  // ---------------------------------------------------------------------------

  /// Native PDF text whose line advance equals `fontSize * lineHeight`.
  ///
  /// That is Flutter's `TextStyle(height:)` semantics, which the preview and
  /// the layout engine's row-height estimates both assume. `package:pdf`
  /// instead advances by the font's natural line height and adds `lineSpacing`
  /// on top, so the extra spacing is derived per font: Kaiti advances 1.4 em
  /// naturally (needs none), MingLiU only 1.0 em (needs 0.4 em extra).
  pw.Widget _chineseText(
    String text,
    pw.Context context, {
    required pw.Font font,
    required List<pw.Font> fontFallback,
    required double fontSize,
    required double lineHeight,
    required double maxWidth,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    final built = font.getFont(context);
    if (_rareGlyphShapingFont != null &&
        _chineseShapingFonts.isNotEmpty &&
        _needsShapedFallback(text, context, font, fontFallback)) {
      final primary = _chineseShapingFonts.firstWhere(
        (f) => identical(f.pdfFont, font),
        orElse: () => _chineseShapingFonts.first,
      );
      return ShapedText(
        text,
        fonts: <ShapedTextFont>[
          primary,
          ..._chineseShapingFonts.where((f) => !identical(f, primary)),
          _rareGlyphShapingFont!,
        ],
        fontSize: fontSize,
        color: PdfColors.black,
        maxWidth: maxWidth,
        lineHeight: lineHeight,
        textAlign: textAlign,
      );
    }
    // The rotated side panels lay this text out with the panel width as the
    // available width, not the panel height, so an explicit width is needed
    // for the title to stay on one line (the preview's RotatedBox swaps the
    // constraints for us).
    return pw.SizedBox(
      width: maxWidth,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontFallback: fontFallback,
          fontSize: fontSize,
          color: PdfColors.black,
          // `pdf` defaults wordSpacing to 1 em and adds it after every word,
          // which pushed CJK lines past the column width and wrapped them early.
          wordSpacing: 0,
          lineSpacing: pdfLineSpacing(
            ascent: built.ascent,
            descent: built.descent,
            fontSize: fontSize,
            lineHeight: lineHeight,
          ),
        ),
        textAlign: textAlign,
        // CJK has no spaces, so the default whitespace splitter can never wrap
        // it; splitting per character allows wrapping anywhere.
        lineSplitter: (line) => line.split(''),
      ),
    );
  }

  /// Whether [text] contains a rune that the native PDF fonts cannot draw but
  /// a shaping font can. Those runs are rendered as HarfBuzz outlines.
  bool _needsShapedFallback(
    String text,
    pw.Context context,
    pw.Font font,
    List<pw.Font> fontFallback,
  ) {
    final primary = font.getFont(context);
    final fallbacks = [for (final f in fontFallback) f.getFont(context)];
    final shaping = <ShapedTextFont>[
      ..._chineseShapingFonts,
      if (_rareGlyphShapingFont != null) _rareGlyphShapingFont!,
    ];
    for (final rune in text.runes) {
      final native = primary.isRuneSupported(rune) ||
          fallbacks.any((f) => f.isRuneSupported(rune));
      if (native) continue;
      if (shaping.any((f) => f.data.supportsRune(rune))) return true;
    }
    return false;
  }

  /// Title-page Tibetan, or null when no shapable Tibetan font is configured.
  pw.Widget? _titleTibetan(
    PageSetup ps, {
    required List<ShapedTextFont> fonts,
    required double fontSize,
    required double maxWidth,
  }) {
    final text = ps.titleTibetan;
    if (fonts.isEmpty || text.trim().isEmpty) return null;
    return ShapedText(
      text,
      fonts: fonts,
      fontSize: fontSize,
      color: PdfColors.black,
      maxWidth: maxWidth,
      lineHeight: 1.4,
      topPadding: 5,
      textAlign: pw.TextAlign.center,

    );
  }

  /// Content Tibetan for [block]: the first line is the heading, the rest is
  /// the body. Red highlighting applies to heading syllables only, matching
  /// the editor preview.
  pw.Widget? _contentTibetan(
    TextBlock block, {
    required List<ShapedTextFont> fonts,
    required double maxW,
    required double fontSize,
    bool forceRed = false,
  }) {
    final lines = splitLines(block.tibetan);
    if (fonts.isEmpty || lines.isEmpty) return null;

    final heading = lines.first;
    final body = lines.length > 1 ? lines.sublist(1).join('\n') : '';
    final small = block.smallText;
    final lineHeight = contentTibetanLineHeight(smallText: small);

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        ShapedText(
          heading,
          fonts: fonts,
          fontSize: fontSize,
          color: forceRed ? _rose : PdfColors.black,
          maxWidth: maxW,
          lineHeight: lineHeight,
          topPadding: contentTibetanPngTopPadding,
          bottomPadding: contentTibetanPngBottomPadding,
          colorForRune: forceRed
              ? null
              : _tibetanColorFor(heading, block.redHighlightRange),
        ),
        if (body.isNotEmpty)
          ShapedText(
            body,
            fonts: fonts,
            fontSize: fontSize,
            color: forceRed ? _rose : PdfColors.black,
            maxWidth: maxW,
            lineHeight: lineHeight,
            topPadding: contentTibetanPngTopPadding,
            bottomPadding: contentTibetanPngBottomPadding,
          ),
      ],
    );
  }

  /// Colours syllables covered by [highlightRange] rose, matching the preview
  /// (highlighted letters rose, their vowel signs and punctuation black).
  ShapedTextColorizer? _tibetanColorFor(String text, String highlightRange) {
    final mask = tibetanHighlightMask(text, highlightRange);
    if (!mask.contains(true)) return null;
    return (index, rune) =>
        index < mask.length && mask[index] ? _rose : PdfColors.black;
  }

  pw.Widget _buildTitlePage({
    required pw.Context context,
    required PageSetup ps,
    required String projectName,
    required pw.Font chiFont,
    required double chiFontSize,
    required List<pw.Font> fontFallback,
    required double outerW,
    required double outerH,
    required double sideW,
    required double inset,
    required List<ShapedTextFont> titleTibFonts,
    required double titleTibFontSize,
    String? titlePageSvg,
  }) {
    final titleChinese =
        (ps.titleChinese.isNotEmpty ? ps.titleChinese : projectName).trim();
    final titleGapPt = titleTextGapPoints(ps);

    if (titlePageSvg != null && titlePageSvg.isNotEmpty) {
      final templateBounds = titlePageTemplateBounds(ps);
      final titleBoxBounds = titlePageTemplateTitleBoxBounds(ps);
      final il = templateBounds.leftMm * PdfPageFormat.mm;
      final it = templateBounds.topMm * PdfPageFormat.mm;
      final titleLeft = titleBoxBounds.leftMm * PdfPageFormat.mm;
      final titleTop = titleBoxBounds.topMm * PdfPageFormat.mm;
      final titleW = titleBoxBounds.widthMm * PdfPageFormat.mm;
      final titleH = titleBoxBounds.heightMm * PdfPageFormat.mm;
      final title = _titleTibetan(
        ps,
        fonts: titleTibFonts,
        fontSize: titleTibFontSize,
        maxWidth: titleW,
      );
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
                    if (title != null) ...[
                      title,
                      pw.SizedBox(height: titleGapPt > 0 ? titleGapPt : 0),
                    ],
                    pw.Transform.translate(
                      offset: PdfPoint(
                        0,
                        title != null && titleGapPt < 0 ? -titleGapPt : 0,
                      ),
                      child: _chineseText(
                        titleChinese.isEmpty ? ' ' : titleChinese,
                        context,
                        font: chiFont,
                        fontFallback: fontFallback,
                        fontSize: chiFontSize,
                        lineHeight: 1.2,
                        maxWidth: titleW,
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    const framePad = 6 * PdfPageFormat.mm;
    const panelPadY = 2 * PdfPageFormat.mm;
    const panelInnerPadX = 6 * PdfPageFormat.mm;
    final innerH = outerH - 2 * inset - 2 * panelPadY;
    final panelW = innerH * 0.6;
    const titleGap = 3 * PdfPageFormat.mm;

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
                  padding: const pw.EdgeInsets.all(panelInnerPadX),
                  child: pw.SvgImage(svg: _dharmaWheelSvg!),
                ),
              )
            : pw.SizedBox(),
      );
    }

    pw.Widget titleBox() {
      final titleBoxW =
          outerW - 2 * (inset + framePad) - 2 * panelW - 2 * titleGap;
      final title = _titleTibetan(
        ps,
        fonts: titleTibFonts,
        fontSize: titleTibFontSize,
        maxWidth: titleBoxW - 24,
      );

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
              ?title,
              if (title == null)
                pw.Text(
                  ' ',
                  style: pw.TextStyle(
                    font: chiFont,
                    fontFallback: fontFallback,
                    fontSize: chiFontSize,
                  ),
                ),
              pw.SizedBox(height: titleGapPt > 0 ? titleGapPt : 0),
              pw.Transform.translate(
                offset: PdfPoint(0, titleGapPt < 0 ? -titleGapPt : 0),
                child: _chineseText(
                  titleChinese.isEmpty ? ' ' : titleChinese,
                  context,
                  font: chiFont,
                  fontFallback: fontFallback,
                  fontSize: chiFontSize,
                  lineHeight: 1.2,
                  maxWidth: titleBoxW - 24,
                  textAlign: pw.TextAlign.center,
                ),
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
          padding: const pw.EdgeInsets.symmetric(vertical: panelPadY),
          child: crestPanel(),
        ),
        pw.SizedBox(width: titleGap),
        pw.Expanded(child: pw.Center(child: titleBox())),
        pw.SizedBox(width: titleGap),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: panelPadY),
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
    required pw.Context context,
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
    required MarginMm pageMargin,
    required double outerW,
    required double outerH,
    required double sideW,
    required double inset,
    required String pageNumber,
    required List<ShapedTextFont> tibFonts,
    required Map<String, _Img> imgs,
    String? templateSvg,
    ContentPageTemplateLayout? templateLayout,
  }) {
    final hasPageTemplate = templateSvg != null && templateSvg.isNotEmpty;
    const sideFontSize = 9.0;
    pw.Widget sidePanel(String? text) {
      if (hasPageTemplate) return pw.SizedBox();
      pw.Widget? inner;
      if (text != null && text.isNotEmpty) {
        final isTibetan = text.runes.any((r) => r >= 0x0F00 && r <= 0x0FFF);
        inner = pw.Transform.rotateBox(
          angle: 1.5708,
          // The panel's width would otherwise clamp the text to the narrow
          // side column; lay it out unconstrained so the explicit width below
          // can span the page height and keep the title on one line.
          unconstrained: true,
          child: isTibetan
              // Mixed Tibetan: needs HarfBuzz shaping, not raw codepoint mapping.
              ? ShapedText(
                  text,
                  fonts: tibFonts,
                  fontSize: sideFontSize,
                  color: PdfColors.black,
                  maxWidth: outerH,
                  textAlign: pw.TextAlign.center,
                )
              : _chineseText(
                  text,
                  context,
                  font: transFont,
                  fontFallback: fontFallback,
                  fontSize: sideFontSize,
                  lineHeight: 1.2,
                  maxWidth: outerH,
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
      const padX = 2 * PdfPageFormat.mm;
      // Precompute row Y offsets
      final rowYs = <double>[];
      final smallTibetanSize = contentTibetanFontSize(
        tibFontSize,
        smallText: true,
        smallBlockFontSize: smallBlockFontSize,
      );
      final smallScale = smallBlockFontSize != null
          ? smallBlockFontSize / tibFontSize
          : 0.75;
      final smallChineseSize = pronFontSize * smallScale;
      final contentGapPt = ps.contentTextGapPx * pxToPdfPoints;
      final compactMinimumHeights = <double>[];
      for (var ri = 0; ri < rowCount; ri++) {
        compactMinimumHeights.add(
          estimateCompactSmallRowHeight(
            rows[ri],
            tibetanFontSize: smallTibetanSize,
            chineseFontSize: smallChineseSize,
            topPadding: contentTibetanPngTopPadding,
            tibetanLineHeight: contentTibetanLineHeight(smallText: true),
            chineseLineHeight: 1.4,
            chineseTopGap: contentGapPt,
          ),
        );
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
        final transSize =
            transFontSize * (small || freeText ? smallScale : 1.0);

        final pron = splitLines(block.chinesePronunciation).join('\n');
        final trans = small || freeText
            ? ''
            : splitLines(block.chineseTranslation).join('\n');
        final freeTextContent = splitLines(block.tibetan).join('\n');

        // Free-text blocks hold Chinese/English content, not Tibetan, so they
        // keep the raster path below.
        final tibText = freeText
            ? null
            : _contentTibetan(
                block,
                fonts: tibFonts,
                maxW: maxW,
                fontSize: contentTibetanFontSize(
                  tibFontSize,
                  smallText: small,
                  smallBlockFontSize: small ? smallBlockFontSize : null,
                ),
                forceRed: block.isOpeningMark && block.openingMarkRed,
              );
        // The Tibetan widget reserves the same transparent bottom padding the
        // raster used for descenders, so subtract it to keep the visible gap
        // equal to the configured setting.
        final effectiveGapPt =
            contentGapPt - (tibText != null ? contentTibetanPngBottomPadding : 0);

        if (block.isOpeningMark) return tibText ?? pw.SizedBox();

        return pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (freeText && freeTextContent.isNotEmpty)
              _chineseText(
                freeTextContent,
                context,
                font: transFont,
                fontFallback: fontFallback,
                fontSize: transSize,
                lineHeight: 1.2,
                maxWidth: maxW,
              ),
            if (!freeText && tibText != null) tibText,
            if (pron.isNotEmpty || trans.isNotEmpty)
              pw.Transform.translate(
                offset: PdfPoint(
                  0,
                  effectiveGapPt < 0 ? -effectiveGapPt : 0,
                ),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (pron.isNotEmpty) ...[
                      pw.SizedBox(
                        height: effectiveGapPt > 0 ? effectiveGapPt : 0,
                      ),
                      _chineseText(
                        pron,
                        context,
                        font: pronFont,
                        fontFallback: fontFallback,
                        fontSize: pronSize,
                        lineHeight: contentChineseLineHeight,
                        maxWidth: maxW,
                      ),
                    ],
                    if (trans.isNotEmpty) ...[
                      if (pron.isEmpty)
                        pw.SizedBox(
                          height: effectiveGapPt > 0 ? effectiveGapPt : 0,
                        ),
                      pw.SizedBox(height: 1),
                      _chineseText(
                        trans,
                        context,
                        font: transFont,
                        fontFallback: fontFallback,
                        fontSize: transSize,
                        lineHeight: contentChineseLineHeight,
                        maxWidth: maxW,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      }

      final positioned = <pw.Widget>[];
      final rowLineYOffset =
          ps.rowLineYOffset * PdfPageFormat.mm / 3.78;
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
        ? (outerW -
              templateContent!.leftMm * PdfPageFormat.mm -
              templateContent.widthMm * PdfPageFormat.mm)
        : inset;
    final contentPadB = hasPageTemplate
        ? (outerH -
              templateContent!.topMm * PdfPageFormat.mm -
              templateContent.heightMm * PdfPageFormat.mm)
        : inset;
    final sidePW = hasPageTemplate ? 0.0 : sideW - 2 * inset;
    final cW = hasPageTemplate
        ? templateContent!.widthMm * PdfPageFormat.mm
        : contentBoxWidthMm(
            pageWidthMm: ps.pageWidthMm,
            marginLeftMm: pageMargin.left,
            marginRightMm: pageMargin.right,
            insetMm: inset / PdfPageFormat.mm,
            sidePanelWidthMm: sidePW / PdfPageFormat.mm,
          ) *
          PdfPageFormat.mm;
    final cH = hasPageTemplate
        ? templateContent!.heightMm * PdfPageFormat.mm
        : contentBoxHeightMm(
            pageHeightMm: ps.pageHeightMm,
            marginTopMm: pageMargin.top,
            marginBottomMm: pageMargin.bottom,
            insetMm: inset / PdfPageFormat.mm,
          ) *
          PdfPageFormat.mm;
    pw.Widget buildInner() {
      return pw.Row(
        children: [
          sidePanel(ps.titleChinese),
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
        child: buildInner(),
      );
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
                      color: PdfColors.black,
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
