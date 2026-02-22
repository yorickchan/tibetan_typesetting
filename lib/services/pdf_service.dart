import 'dart:ui' show Color, TextAlign;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/app_settings.dart';
import '../models/project.dart';
import '../utils/font_constants.dart';
import '../utils/font_utils.dart' as font_utils;
import '../utils/sample_layout.dart';
import '../utils/text_renderer.dart';
import 'font_service.dart';
import 'settings_service.dart';

const _rose = PdfColor.fromInt(0xFFe11d48);

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
    TextAlign textAlign = TextAlign.left,
  }) async {
    if (text.trim().isEmpty) return null;
    final r = await renderTextToPng(
      text,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: fontSize,
      color: color,
      maxWidth: maxWidth,
      lineHeight: lineHeight,
      textAlign: textAlign,
    );
    if (r == null) return null;
    return _Img(pw.MemoryImage(r.pngBytes), r.width, r.height);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<Uint8List> generatePdf(
    Project project, {
    AppSettings? appSettings,
  }) async {
    await _loadSvg();

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

    // Load PDF fonts from file paths (for Chinese text drawn via pw.Text)
    pw.Font? pronPdfFont;
    pw.Font? transPdfFont;
    try {
      if (pronConfig.fontPath.isNotEmpty) {
        pronPdfFont = await _fontService.loadFontForPdf(pronConfig);
      }
    } catch (e, s) {
      debugPrint('Failed to load pronunciation font for PDF: $e\n$s');
    }
    try {
      if (transConfig.fontPath.isNotEmpty) {
        transPdfFont = await _fontService.loadFontForPdf(transConfig);
      }
    } catch (e, s) {
      debugPrint('Failed to load translation font for PDF: $e\n$s');
    }
    final chiFont = pronPdfFont ?? transPdfFont ?? pw.Font.helvetica();
    final tranFont = transPdfFont ?? pronPdfFont ?? pw.Font.helvetica();

    // Load broad-coverage CJK fallback fonts from system for characters
    // missing from the primary font (e.g. 瓔 U+74D4, 珞 U+73DE).
    final fontFallback = await _fontService.loadCjkFallbackFonts();

    // Title page fonts (fall back to body fonts)
    final titleTibConfig = ps.titleTibetanFont ?? tibConfig;
    final titleChiConfig = ps.titleChineseFont ?? transConfig;

    pw.Font? titleChiPdfFont;
    try {
      if (titleChiConfig.fontPath.isNotEmpty) {
        titleChiPdfFont = await _fontService.loadFontForPdf(titleChiConfig);
      }
    } catch (e, s) {
      debugPrint('Failed to load title Chinese font for PDF: $e\n$s');
    }
    final titleChiFont = titleChiPdfFont ?? tranFont;

    // Font families for pre-rendered text (Tibetan through HarfBuzz)
    final tibFamily = tibConfig.fontFamily;
    final transFamily = transConfig.fontFamily;
    final titleTibFamily = titleTibConfig.fontFamily;

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

    final colCount = (ps.columnCount > 0) ? ps.columnCount : 0;
    final pages = paginateBlocks(project.blocks, colCount, 4);

    // ---- dimensions needed for pre-render sizing ----

    // Content pages
    final sidePanelW = sideW - 2 * inset;
    final contentW = outerW - 2 * inset - 2 * sidePanelW;
    final contentH = outerH - 4 * inset;
    final padX = 3 * PdfPageFormat.mm;

    // Title page
    final framePad = 6 * PdfPageFormat.mm;
    final panelPadY = 2 * PdfPageFormat.mm;
    final innerH = outerH - 2 * inset - 2 * panelPadY;
    final panelWTitle = innerH * 0.6;
    final titleGap = 3 * PdfPageFormat.mm;
    final titleBoxW =
        outerW - 2 * (inset + framePad) - 2 * panelWTitle - 2 * titleGap;
    final titleTextW = titleBoxW - 2 * 4 - 2 * 12;

    // ---- pre-render all text as images ----

    final tibFontSize = tibConfig.fontSize;

    final imgs = <String, _Img>{};
    final tasks = <Future<void>>[];

    Future<void> put(String key, Future<_Img?> future) async {
      final img = await future;
      if (img != null) imgs[key] = img;
    }

    // Title page Tibetan
    if (ps.showTitlePage && ps.titleTibetan.trim().isNotEmpty) {
      tasks.add(
        put(
          'title_tib',
          _render(
            ps.titleTibetan,
            titleTibConfig.fontSize,
            _blackUi,
            titleTextW,
            fontFamily: titleTibFamily,
            lineHeight: 1.4,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Left side panel
    if (ps.leftVerticalTitle.trim().isNotEmpty) {
      tasks.add(
        put(
          'side_left',
          _render(
            ps.leftVerticalTitle,
            9,
            _roseUi,
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
      final pageCols = page.colCount < 1 ? 1 : page.colCount;
      final cellW = contentW / pageCols;

      final showMark = pi % 2 == 0;
      for (var ri = 0; ri < page.rows.length; ri++) {
        final row = page.rows[ri];
        for (var ci = 0; ci < pageCols; ci++) {
          if (ci >= row.length) continue;
          final block = row[ci];
          if (block == null) continue;

          final key = '${pi}_${ri}_$ci';
          final tibLines = splitLines(block.tibetan);
          var heading = tibLines.isNotEmpty ? tibLines[0] : '';
          final body = tibLines.length > 1
              ? tibLines.sublist(1).join('\n')
              : '';

          if (showMark && ri == 0 && ci == 0) {
            heading = '\u0F04\u0F05\u0F0D\u0F0D   $heading';
          }

          final small = block.smallText;
          final hSize = tibFontSize * 0.9 * (small ? 0.75 : 1.0);
          final bSize = tibFontSize * (small ? 0.75 : 1.0);

          // Small text extends from its column position to the right edge
          final textMaxW = small
              ? (contentW - ci * cellW - padX * 2)
              : (cellW - padX * 2);

          tasks.add(
            put(
              '${key}_h',
              _render(
                heading,
                hSize,
                _roseUi,
                textMaxW,
                fontFamily: tibFamily,
                lineHeight: 1.4,
              ),
            ),
          );
          tasks.add(
            put(
              '${key}_b',
              _render(
                body,
                bSize,
                _blackUi,
                textMaxW,
                fontFamily: tibFamily,
                lineHeight: 1.5,
              ),
            ),
          );
        }
      }
    }

    await Future.wait(tasks);

    // ---- build PDF ----

    final doc = pw.Document();

    if (ps.showTitlePage) {
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.only(
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
            outerW: outerW,
            outerH: outerH,
            sideW: sideW,
            inset: inset,
            imgs: imgs,
          ),
        ),
      );
    }

    for (var pageIdx = 0; pageIdx < pages.length; pageIdx++) {
      final page = pages[pageIdx];
      final pageNumber = resolvePageNumber(ps.pageNumber, pageIdx);

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.only(
            left: marginL,
            right: marginR,
            top: marginT,
            bottom: marginB,
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
            outerW: outerW,
            outerH: outerH,
            sideW: sideW,
            inset: inset,
            pageNumber: pageNumber,
            imgs: imgs,
          ),
        ),
      );
    }

    return doc.save();
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
  }) {
    final titleChinese =
        (ps.titleChinese.isNotEmpty ? ps.titleChinese : projectName).trim();

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
    required double outerW,
    required double outerH,
    required double sideW,
    required double inset,
    required String pageNumber,
    required Map<String, _Img> imgs,
  }) {
    final sideImg = imgs['side_left'];

    pw.Widget sidePanel(String? text, {_Img? image}) {
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
      final rows = page.rows;
      final pageCols = page.colCount;
      if (rows.isEmpty) return pw.SizedBox.expand();

      final rowCount = rows.length;
      final cellW = cW / (pageCols < 1 ? 1 : pageCols);
      final padX = 3 * PdfPageFormat.mm;
      final padY = 2 * PdfPageFormat.mm;
      final smallRowShrink = 6 * PdfPageFormat.mm;

      // Check which rows are "short" (smallText with empty translation)
      bool isShortRow(List<TextBlock?> row) {
        for (final b in row) {
          if (b != null && b.smallText) {
            final trans = splitLines(b.chineseTranslation).join('');
            if (trans.isEmpty) return true;
          }
        }
        return false;
      }

      final baseRowH = cH / rowCount;
      final shortRowH = baseRowH - smallRowShrink;
      final normalRowH = baseRowH;

      // Precompute row Y offsets
      final rowYs = <double>[];
      double yAccum = 0;
      for (var ri = 0; ri < rowCount; ri++) {
        rowYs.add(yAccum);
        yAccum += isShortRow(rows[ri]) ? shortRowH : normalRowH;
      }

      pw.Widget buildBlock(String key, TextBlock block, bool hasMark) {
        final small = block.smallText;
        final hSize = tibFontSize * 0.9 * (small ? 0.75 : 1.0);
        final pronSize = pronFontSize * (small ? 0.75 : 1.0);
        final transSize = transFontSize * (small ? 0.75 : 1.0);
        final markPad = hasMark ? hSize * 3.5 : 0.0;

        final pron = splitLines(block.chinesePronunciation).join('\n');
        final trans = small
            ? ''
            : splitLines(block.chineseTranslation).join('\n');

        final hImg = imgs['${key}_h'];
        final bImg = imgs['${key}_b'];

        return pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (hImg != null)
              pw.Image(hImg.provider, width: hImg.w, height: hImg.h),
            if (bImg != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 1),
                child: pw.Image(bImg.provider, width: bImg.w, height: bImg.h),
              ),
            if (pron.isNotEmpty)
              pw.Padding(
                padding: pw.EdgeInsets.only(top: 2, left: markPad),
                child: pw.Text(
                  pron,
                  style: pw.TextStyle(
                    font: pronFont,
                    fontFallback: fontFallback,
                    fontSize: pronSize,
                    color: PdfColors.black,
                    lineSpacing: pronSize * 0.4,
                  ),
                ),
              ),
            if (trans.isNotEmpty)
              pw.Padding(
                padding: pw.EdgeInsets.only(top: 1, left: markPad),
                child: pw.Text(
                  trans,
                  style: pw.TextStyle(
                    font: transFont,
                    fontFallback: fontFallback,
                    fontSize: transSize,
                    color: PdfColors.black,
                    lineSpacing: transSize * 0.4,
                  ),
                ),
              ),
          ],
        );
      }

      final positioned = <pw.Widget>[];
      final showMark = pageIdx % 2 == 0;
      for (var ri = 0; ri < rows.length; ri++) {
        final row = rows[ri];
        for (var ci = 0; ci < pageCols; ci++) {
          final block = (ci < row.length) ? row[ci] : null;
          if (block == null) continue;
          final key = '${pageIdx}_${ri}_$ci';
          final blockW = block.smallText
              ? (cW - ci * cellW - padX * 2)
              : (cellW - padX * 2);
          final hasMark = showMark && ri == 0 && ci == 0;
          positioned.add(
            pw.Positioned(
              left: ci * cellW + padX,
              top: rowYs[ri] + padY,
              child: pw.SizedBox(width: blockW, child: buildBlock(key, block, hasMark)),
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

    final sidePW = sideW - 2 * inset;
    final cW = outerW - 2 * inset - 2 * sidePW;
    final cH = outerH - 4 * inset;

    pw.Widget buildInner() {
      return pw.Row(
        children: [
          sidePanel(ps.leftVerticalTitle, image: sideImg),
          pw.Expanded(
            child: pw.Container(
              decoration: ps.showFrame
                  ? pw.BoxDecoration(
                      border: pw.Border.all(color: _rose, width: 0.5),
                    )
                  : null,
              child: contentArea(cW, cH),
            ),
          ),
          sidePanel(pageNumber),
        ],
      );
    }

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
          child: buildInner(),
        ),
      );
    }

    return pw.Padding(padding: pw.EdgeInsets.all(inset), child: buildInner());
  }
}
