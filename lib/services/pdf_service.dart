import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/project.dart';
import '../utils/sample_layout.dart';
import '../utils/text_renderer.dart';

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

  pw.Font? _tibetanFont;
  pw.Font? _chineseFont;
  String? _dharmaWheelSvg;
  bool _loaded = false;

  static ByteData? _extractTtfFromTtc(ByteData ttc, {int fontIndex = 0}) {
    if (ttc.lengthInBytes < 12) return null;
    final tag = String.fromCharCodes([
      ttc.getUint8(0),
      ttc.getUint8(1),
      ttc.getUint8(2),
      ttc.getUint8(3),
    ]);
    if (tag != 'ttcf') return null;

    final numFonts = ttc.getUint32(8);
    if (fontIndex >= numFonts) return null;

    final fontOffset = ttc.getUint32(12 + fontIndex * 4);
    if (fontOffset + 12 > ttc.lengthInBytes) return null;

    final numTables = ttc.getUint16(fontOffset + 4);
    final tags = <int>[];
    final checksums = <int>[];
    final offsets = <int>[];
    final lengths = <int>[];
    for (var i = 0; i < numTables; i++) {
      final e = fontOffset + 12 + i * 16;
      if (e + 16 > ttc.lengthInBytes) return null;
      tags.add(ttc.getUint32(e));
      checksums.add(ttc.getUint32(e + 4));
      offsets.add(ttc.getUint32(e + 8));
      lengths.add(ttc.getUint32(e + 12));
    }

    final headerSize = 12 + numTables * 16;
    var totalSize = headerSize;
    for (final len in lengths) {
      totalSize += (len + 3) & ~3;
    }

    final out = ByteData(totalSize);
    for (var i = 0; i < 12; i++) {
      out.setUint8(i, ttc.getUint8(fontOffset + i));
    }

    var dataOffset = headerSize;
    for (var i = 0; i < numTables; i++) {
      final dirOff = 12 + i * 16;
      out.setUint32(dirOff, tags[i]);
      out.setUint32(dirOff + 4, checksums[i]);
      out.setUint32(dirOff + 8, dataOffset);
      out.setUint32(dirOff + 12, lengths[i]);
      for (var j = 0; j < lengths[i]; j++) {
        out.setUint8(dataOffset + j, ttc.getUint8(offsets[i] + j));
      }
      dataOffset += (lengths[i] + 3) & ~3;
    }
    return out;
  }

  Future<void> _loadAssets() async {
    if (_loaded) return;
    _loaded = true;

    try {
      final data =
          await rootBundle.load('assets/fonts/BabelStoneTibetan.ttf');
      _tibetanFont = pw.Font.ttf(data);
    } catch (_) {
      _tibetanFont = pw.Font.helvetica();
    }

    for (final path in [
      'assets/fonts/STHeitiLight.ttc',
      'assets/fonts/STHeitiMedium.ttc',
    ]) {
      if (_chineseFont != null) break;
      try {
        final ttcData = await rootBundle.load(path);
        final ttfData = _extractTtfFromTtc(ttcData);
        if (ttfData != null) {
          _chineseFont = pw.Font.ttf(ttfData);
        }
      } catch (_) {}
    }
    _chineseFont ??= _tibetanFont;

    try {
      _dharmaWheelSvg =
          await rootBundle.loadString('assets/images/dharma_wheel.svg');
    } catch (_) {}
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
    String fontFamily = 'BabelStoneTibetan',
    List<String> fontFamilyFallback = const ['STHeiti'],
    double? lineHeight,
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
    );
    if (r == null) return null;
    return _Img(pw.MemoryImage(r.pngBytes), r.width, r.height);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<Uint8List> generatePdf(Project project) async {
    await _loadAssets();

    final chiFont = _chineseFont ?? pw.Font.helvetica();

    final ps = project.pageSetup;
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
    // Approximate the usable text width inside the double-bordered title box.
    final titleTextW = titleBoxW - 2 * 4 - 2 * 12;

    // ---- pre-render all Tibetan text as images ----

    final imgs = <String, _Img>{};

    final tasks = <Future<void>>[];

    Future<void> put(String key, Future<_Img?> future) async {
      final img = await future;
      if (img != null) imgs[key] = img;
    }

    // Title page Tibetan
    if (ps.showTitlePage && ps.titleTibetan.trim().isNotEmpty) {
      tasks.add(put('title_tib', _render(
        ps.titleTibetan, 16, _blackUi, titleTextW,
        lineHeight: 1.4,
      )));
    }

    // Left side panel — typically Chinese text, fall back to Tibetan
    if (ps.leftVerticalTitle.trim().isNotEmpty) {
      tasks.add(put('side_left', _render(
        ps.leftVerticalTitle, 9, _roseUi, contentH,
        fontFamily: 'STHeiti',
        fontFamilyFallback: const ['BabelStoneTibetan'],
      )));
    }

    // Content blocks — compute textMaxW per-page using page.colCount
    for (var pi = 0; pi < pages.length; pi++) {
      final page = pages[pi];
      final pageCols = page.colCount < 1 ? 1 : page.colCount;
      final cellW = contentW / pageCols;
      final textMaxW = cellW - padX * 2;

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
          final hSize = small ? 7.0 : 9.0;
          final bSize = small ? 7.5 : 10.0;

          tasks.add(put('${key}_h', _render(
            heading, hSize, _roseUi, textMaxW,
            lineHeight: 1.4,
          )));
          tasks.add(put('${key}_b', _render(
            body, bSize, _blackUi, textMaxW,
            lineHeight: 1.5,
          )));
        }
      }
    }

    await Future.wait(tasks);

    // ---- build PDF ----

    final doc = pw.Document();

    if (ps.showTitlePage) {
      doc.addPage(pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.only(
          left: marginL, right: marginR, top: marginT, bottom: marginB,
        ),
        build: (_) => _buildTitlePage(
          ps: ps,
          projectName: project.name,
          chiFont: chiFont,
          outerW: outerW,
          outerH: outerH,
          sideW: sideW,
          inset: inset,
          imgs: imgs,
        ),
      ));
    }

    for (var pageIdx = 0; pageIdx < pages.length; pageIdx++) {
      final page = pages[pageIdx];
      final pageNumber = _resolvePageNumber(ps.pageNumber, pageIdx);

      doc.addPage(pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.only(
          left: marginL, right: marginR, top: marginT, bottom: marginB,
        ),
        build: (_) => _buildContentPage(
          ps: ps,
          page: page,
          pageIdx: pageIdx,
          chiFont: chiFont,
          outerW: outerW,
          outerH: outerH,
          sideW: sideW,
          inset: inset,
          pageNumber: pageNumber,
          imgs: imgs,
        ),
      ));
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

    // Tibetan title: use pre-rendered image for correct shaping
    final tibImg = imgs['title_tib'];

    pw.Widget titleBox() {
      final titleBoxW = outerW -
          2 * (inset + framePad) -
          2 * panelW -
          2 * titleGap;

      return pw.Container(
        width: titleBoxW,
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _rose, width: 3),
        ),
        child: pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _rose, width: 1.5),
          ),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              if (tibImg != null)
                pw.Image(tibImg.provider,
                    width: tibImg.w, height: tibImg.h),
              if (tibImg == null)
                pw.Text(' ',
                    style: pw.TextStyle(
                        font: chiFont, fontSize: 16)),
              pw.SizedBox(height: 6),
              pw.Text(
                titleChinese.isEmpty ? ' ' : titleChinese,
                style: pw.TextStyle(
                    font: chiFont, fontSize: 12, color: PdfColors.black),
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
    required pw.Font chiFont,
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
          child:
              pw.Image(image.provider, width: image.w, height: image.h),
        );
      } else if (text != null && text.isNotEmpty) {
        inner = pw.Transform.rotateBox(
          angle: 1.5708,
          child: pw.Text(
            text,
            style: pw.TextStyle(
                font: chiFont, fontSize: 9, color: _rose),
            textAlign: pw.TextAlign.center,
          ),
        );
      }
      return pw.Container(
        width: sideW - 2 * inset,
        decoration: ps.showFrame
            ? pw.BoxDecoration(
                border: pw.Border.all(color: _rose, width: 0.5))
            : null,
        child: inner != null ? pw.Center(child: inner) : pw.SizedBox(),
      );
    }

    pw.Widget contentArea(double cW, double cH) {
      final rows = page.rows;
      final pageCols = page.colCount;
      if (rows.isEmpty) return pw.SizedBox.expand();

      final rowCount = rows.length;
      final rowH = cH / rowCount;
      final cellW = cW / (pageCols < 1 ? 1 : pageCols);
      final padX = 3 * PdfPageFormat.mm;
      final padY = 2 * PdfPageFormat.mm;

      pw.Widget buildBlock(String key, TextBlock block) {
        final small = block.smallText;
        final chiSize = small ? 6.0 : 8.0;

        final pron = splitLines(block.chinesePronunciation).join('\n');
        final trans = splitLines(block.chineseTranslation).join('\n');

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
                child: pw.Image(bImg.provider,
                    width: bImg.w, height: bImg.h),
              ),
            if (pron.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  pron,
                  style: pw.TextStyle(
                      font: chiFont,
                      fontSize: chiSize,
                      color: PdfColors.black,
                      lineSpacing: chiSize * 0.4),
                ),
              ),
            if (trans.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 1),
                child: pw.Text(
                  trans,
                  style: pw.TextStyle(
                      font: chiFont,
                      fontSize: chiSize,
                      color: PdfColors.black,
                      lineSpacing: chiSize * 0.4),
                ),
              ),
          ],
        );
      }

      final positioned = <pw.Widget>[];
      for (var ri = 0; ri < rows.length; ri++) {
        final row = rows[ri];
        for (var ci = 0; ci < pageCols; ci++) {
          final block = (ci < row.length) ? row[ci] : null;
          if (block == null) continue;
          final key = '${pageIdx}_${ri}_$ci';
          positioned.add(
            pw.Positioned(
              left: ci * cellW + padX,
              top: ri * rowH + padY,
              child: pw.SizedBox(
                width: cellW - padX * 2,
                child: buildBlock(key, block),
              ),
            ),
          );
        }
      }

      return pw.SizedBox(
        width: cW,
        height: cH,
        child: pw.Stack(
          overflow: pw.Overflow.visible,
          children: positioned,
        ),
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
                      border: pw.Border.all(color: _rose, width: 0.5))
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

    return pw.Padding(
      padding: pw.EdgeInsets.all(inset),
      child: buildInner(),
    );
  }

  String _resolvePageNumber(String base, int index) {
    final trimmed = base.trim();
    if (trimmed.isEmpty) return '${index + 1}';
    final num = int.tryParse(trimmed);
    if (num != null) return '${num + index}';
    return trimmed;
  }
}
