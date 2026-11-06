import 'package:pdf/pdf.dart';
// The `pdf` package does not export form XObjects, which are the only public
// way to draw a reusable object. Sharing one per glyph keeps repeated text from
// re-emitting its outlines into every page's content stream.
// ignore: implementation_imports
import 'package:pdf/src/pdf/format/array.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/format/num.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/obj/formxobject.dart';
import 'package:pdf/widgets.dart' as pw;

import 'shaped_text_core.dart';

/// A font available both to HarfBuzz (shaping and outlines) and to the `pdf`
/// package (the invisible Unicode text layer that keeps the export
/// selectable and searchable).
class ShapedTextFont {
  final ShapedFontData data;

  /// Font used for the invisible text layer; null when this font cannot be
  /// embedded by the `pdf` package (CFF/OpenType outlines).
  final pw.Font? pdfFont;

  ShapedTextFont({required this.data, required this.pdfFont});

  String get name => data.name;

  void dispose() => data.dispose();
}

/// Resolves the colour of one character (UTF-16 index, rune), used for
/// red-highlighted syllables. Return null to use the default colour.
typedef ShapedTextColorizer = PdfColor? Function(int index, int rune);

/// Lays out and paints text whose script needs OpenType shaping (Tibetan).
///
/// The `pdf` package maps characters to glyphs one-to-one, so it cannot stack
/// Tibetan consonants or position vowel signs. This widget shapes the text
/// with HarfBuzz, draws the resulting glyph outlines as vectors, and emits an
/// invisible text layer so the result stays copyable and searchable.
///
/// Line metrics match Flutter's `TextPainter` with the same font size and
/// height multiplier, keeping the export aligned with the on-screen preview.
class ShapedText extends pw.Widget {
  ShapedText(
    this.text, {
    required this.fonts,
    required this.fontSize,
    required PdfColor color,
    required this.maxWidth,
    this.lineHeight,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.textAlign = pw.TextAlign.left,
    this.colorForRune,
  }) {
    _colors = colorForRune == null
        ? List<PdfColor>.filled(text.length, color)
        : List<PdfColor>.generate(
            text.length,
            (i) => colorForRune!(i, text.codeUnitAt(i)) ?? color,
            growable: false,
          );
  }

  /// Primary font first, then fallbacks (mirrors `fontFamilyFallback`).
  final List<ShapedTextFont> fonts;

  final String text;
  final double fontSize;
  final double maxWidth;

  /// Per-character colour override. Colours are resolved up front and shaping
  /// happens per font run, so a colour boundary never splits a Tibetan
  /// cluster.
  final ShapedTextColorizer? colorForRune;

  /// Multiplier applied to [fontSize] to get the distance between baselines.
  final double? lineHeight;

  final double topPadding;
  final double bottomPadding;
  final pw.TextAlign textAlign;

  late final List<PdfColor> _colors;
  _TextLayout? _layout;

  /// Reusable form XObjects, one per glyph, keyed by font instance and glyph id.
  /// Sharing them keeps repeated glyphs from re-emitting their outlines into
  /// every page's content stream, which otherwise dominates file size.
  static final Map<(ShapedFontData, int), _GlyphXObject> _glyphCache =
      <(ShapedFontData, int), _GlyphXObject>{};

  /// Releases the per-glyph XObject cache. XObjects belong to a single
  /// [PdfDocument], so the cache must not outlive an export.
  static void clearGlyphCache() => _glyphCache.clear();

  double get _lineHeight => fontSize * (lineHeight ?? 1.0);

  /// Width of each laid-out line, in PDF points.
  ///
  /// Exposed for layout diagnostics and tests; equal to the advance Flutter's
  /// `TextPainter` measures for the same text and font.
  List<double> get lineWidths {
    final lines = (_layout ??= _buildLayout()).lines;
    return [for (final line in lines) line.width];
  }

  /// Baseline distance from the top of a line box.
  ///
  /// Flutter first computes the font's natural line box, then scales that box
  /// to `fontSize * lineHeight`; the ascent is scaled by the same ratio:
  /// `ascender * fontSize * multiplier / (ascender - descender + lineGap)`.
  double _baselineFor(ShapedFontData font) {
    final raw = font.ascender - font.descender + font.lineGap;
    if (raw <= 0) return _lineHeight * 0.8;
    return font.ascender * _lineHeight / raw;
  }

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    final layout = _layout ??= _buildLayout();
    final width = maxWidth.isFinite
        ? maxWidth
        : (constraints.hasBoundedWidth
              ? constraints.maxWidth
              : layout.naturalWidth);
    final height =
        topPadding + layout.lines.length * _lineHeight + bottomPadding;
    box = PdfRect(0, 0, width, height);
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    final layout = _layout;
    final bounds = box;
    if (layout == null || bounds == null || layout.lines.isEmpty) return;

    final canvas = context.canvas;
    final originX = bounds.left;
    final originY = bounds.top;
    final baseline = _baselineFor(fonts.first.data);

    for (var i = 0; i < layout.lines.length; i++) {
      final line = layout.lines[i];
      final lineX = originX + _alignedOffset(bounds.width, line.width);
      final baselineY = originY - topPadding - baseline - i * _lineHeight;

      var runX = 0.0;
      for (final run in line.runs) {
        final scale = fontSize / run.font.data.unitsPerEm;
        final pdfFont = run.font.pdfFont;
        if (pdfFont != null && run.text.isNotEmpty) {
          canvas.drawString(
            pdfFont.getFont(context),
            fontSize,
            run.text,
            lineX + runX,
            baselineY,
            mode: PdfTextRenderingMode.invisible,
          );
        }
        _paintRun(
          canvas,
          context.document,
          run,
          lineX + runX,
          baselineY,
          scale,
        );
        runX += run.advance * scale;
      }
    }
  }

  void _paintRun(
    PdfGraphics canvas,
    PdfDocument document,
    _LineRun run,
    double originX,
    double originY,
    double scale,
  ) {
    PdfColor? fill;
    var cursor = 0.0;
    for (final glyph in run.glyphs) {
      final outline = run.font.data.outline(glyph.glyphId);
      if (outline.isEmpty) {
        cursor += glyph.xAdvance;
        continue;
      }
      final color = run.colors[glyph];
      if (color != fill) {
        canvas.setFillColor(color);
        fill = color;
      }
      final xobj =
          _glyphXObject(canvas, document, run.font.data, glyph.glyphId, outline);
      final gx = originX + (cursor + glyph.xOffset) * scale;
      final gy = originY + glyph.yOffset * scale;
      canvas.drawXObject(
        xobj.form,
        gx + outline.xMin * scale,
        gy + outline.yMin * scale,
        w: outline.width * scale,
        h: outline.height * scale,
      );
      cursor += glyph.xAdvance;
    }
  }

  /// Builds (once per glyph) a form XObject painting the outline in font units.
  _GlyphXObject _glyphXObject(
    PdfGraphics canvas,
    PdfDocument document,
    ShapedFontData font,
    int glyphId,
    GlyphOutline outline,
  ) {
    final key = (font, glyphId);
    final cached = _glyphCache[key];
    if (cached != null && cached.document == document) return cached;

    // The form's content stream is written directly: constructing a PdfPage to
    // get a PdfGraphics would register that throwaway page in the page tree.
    final form = _GlyphFormXObject(document);
    form.params['/BBox'] = PdfArray.fromNum(<double>[
      outline.xMin,
      outline.yMin,
      outline.xMax,
      outline.yMax,
    ]);

    final buf = form.buf;
    void num(double v) => PdfNum(v).output(form, buf);
    for (final command in outline.commands) {
      switch (command) {
        case GlyphMoveTo(:final x, :final y):
          num(x);
          buf.putByte(0x20);
          num(y);
          buf.putString(' m ');
        case GlyphLineTo(:final x, :final y):
          num(x);
          buf.putByte(0x20);
          num(y);
          buf.putString(' l ');
        case GlyphCubicTo(
          :final x1,
          :final y1,
          :final x2,
          :final y2,
          :final x3,
          :final y3,
        ):
          for (final v in [x1, y1, x2, y2, x3, y3]) {
            num(v);
            buf.putByte(0x20);
          }
          buf.putString('c ');
        case GlyphClosePath():
          buf.putString('h ');
      }
    }
    buf.putString('f ');

    final created = _GlyphXObject(document: document, form: form);
    _glyphCache[key] = created;
    return created;
  }

  double _alignedOffset(double available, double lineWidth) {
    switch (textAlign) {
      case pw.TextAlign.center:
        return (available - lineWidth) / 2;
      case pw.TextAlign.right:
      case pw.TextAlign.end:
        return available - lineWidth;
      case pw.TextAlign.left:
      case pw.TextAlign.start:
      case pw.TextAlign.justify:
        return 0;
    }
  }

  _TextLayout _buildLayout() {
    final paragraphs = <List<_Piece>>[];
    var current = <_Piece>[];

    var start = 0;
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) != _newline) continue;
      final head = text.substring(start, i);
      if (head.isNotEmpty) current.addAll(_shapePieces(head, start));
      paragraphs.add(current);
      current = <_Piece>[];
      start = i + 1;
    }
    final tail = text.substring(start);
    if (tail.isNotEmpty) current.addAll(_shapePieces(tail, start));
    paragraphs.add(current);

    final lines = <_LineLayout>[];
    var naturalWidth = 0.0;
    for (final paragraph in paragraphs) {
      if (paragraph.isEmpty) {
        lines.add(const _LineLayout(runs: [], width: 0));
        continue;
      }
      for (final line in _wrap(paragraph)) {
        if (line.width > naturalWidth) naturalWidth = line.width;
        lines.add(line);
      }
    }
    return _TextLayout(lines: lines, naturalWidth: naturalWidth);
  }

  /// Splits [text] into font-coverage runs and shapes each run.
  List<_Piece> _shapePieces(String piece, int baseOffset) {
    final pieces = <_Piece>[];
    var runStart = 0;
    var runFont = _fontForRune(piece.runes.first, null);

    void flush(int end) {
      if (end <= runStart) return;
      final runText = piece.substring(runStart, end);
      final shaped = runFont.data.shape(runText);
      pieces.add(
        _Piece(
          text: runText,
          font: runFont,
          glyphs: shaped.glyphs,
          advance: shaped.advance,
          baseOffset: baseOffset + runStart,
          colors: _colors,
        ),
      );
    }

    var offset = 0;
    for (final rune in piece.runes) {
      final length = rune > 0xFFFF ? 2 : 1;
      final font = _isWhitespace(rune) ? runFont : _fontForRune(rune, runFont);
      if (font != runFont && offset > runStart) {
        flush(offset);
        runStart = offset;
      }
      runFont = font;
      offset += length;
    }
    flush(piece.length);
    return pieces;
  }

  ShapedTextFont _fontForRune(int rune, ShapedTextFont? current) {
    if (current != null && current.data.supportsRune(rune)) return current;
    for (final font in fonts) {
      if (font.data.supportsRune(rune)) return font;
    }
    return current ?? fonts.first;
  }

  /// Greedy line filling; breaks are allowed after whitespace, after Tibetan
  /// tsheg/shad, and between CJK characters.
  List<_LineLayout> _wrap(List<_Piece> paragraph) {
    final charOffsets = <int>[];
    var total = 0;
    for (final piece in paragraph) {
      charOffsets.add(total);
      total += piece.text.length;
    }

    final breaks = <int>{total};
    for (var p = 0; p < paragraph.length; p++) {
      final piece = paragraph[p];
      for (final offset in lineBreakOpportunities(piece.text)) {
        breaks.add(charOffsets[p] + offset);
      }
    }
    final sortedBreaks = breaks.toList()..sort();

    final limit = maxWidth.isFinite ? maxWidth : double.infinity;
    final lines = <_LineLayout>[];
    var lineStart = 0;

    while (lineStart < total) {
      var lineEnd = lineStart + 1;
      for (final candidate in sortedBreaks) {
        if (candidate <= lineStart) continue;
        final line = _sliceLine(paragraph, charOffsets, lineStart, candidate);
        if (line.width <= limit) {
          lineEnd = candidate;
          continue;
        }
        break;
      }
      if (lineEnd <= lineStart) lineEnd = lineStart + 1;

      final line = _sliceLine(paragraph, charOffsets, lineStart, lineEnd);
      if (line.runs.isNotEmpty) lines.add(line);
      lineStart = lineEnd;
    }

    if (lines.isEmpty) lines.add(const _LineLayout(runs: [], width: 0));
    return lines;
  }

  _LineLayout _sliceLine(
    List<_Piece> paragraph,
    List<int> charOffsets,
    int from,
    int to,
  ) {
    final runs = <_LineRun>[];
    var width = 0.0;
    for (var p = 0; p < paragraph.length; p++) {
      final piece = paragraph[p];
      final start = charOffsets[p];
      final end = start + piece.text.length;
      final a = from > start ? from : start;
      final b = to < end ? to : end;
      if (b <= a) continue;
      final run = piece.slice(a - start, b - start);
      if (run.isEmpty) continue;
      runs.add(run);
      width += run.advance * (fontSize / piece.font.data.unitsPerEm);
    }
    return _LineLayout(runs: runs, width: width);
  }

  static const int _newline = 0x0A;

  static bool _isWhitespace(int rune) =>
      rune == 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D ||
      rune == 0xA0;

}

/// A form XObject for one glyph outline.
///
/// [PdfXObject.name] omits the required leading `/` (the package's own
/// subclasses override it), so without this the resource dictionary key is
/// invalid and readers reject the file.
class _GlyphFormXObject extends PdfFormXObject {
  _GlyphFormXObject(super.document);

  @override
  String get name => '/X$objser';
}

/// A glyph outline stored as a reusable form XObject.
class _GlyphXObject {
  final PdfDocument document;
  final PdfFormXObject form;

  const _GlyphXObject({required this.document, required this.form});
}

/// Drops cached glyph XObjects. Call when the PDF document they belong to is
/// finished, so their objects are not retained across exports.
void clearShapedGlyphCache() => ShapedText.clearGlyphCache();

class _TextLayout {
  final List<_LineLayout> lines;
  final double naturalWidth;

  const _TextLayout({required this.lines, required this.naturalWidth});
}

class _LineLayout {
  final List<_LineRun> runs;
  final double width;

  const _LineLayout({required this.runs, required this.width});
}

class _LineRun {
  final String text;
  final ShapedTextFont font;
  final List<ShapedGlyph> glyphs;

  /// Colour per glyph, resolved from the source character of its cluster.
  final Map<ShapedGlyph, PdfColor> colors;

  /// Advance of the kept glyphs, in font units.
  final int advance;

  const _LineRun({
    required this.text,
    required this.font,
    required this.glyphs,
    required this.colors,
    required this.advance,
  });

  bool get isEmpty => text.isEmpty;
}

class _Piece {
  final String text;
  final ShapedTextFont font;

  /// Shaped glyphs for [text]; `cluster` values are UTF-16 offsets into [text].
  final List<ShapedGlyph> glyphs;

  /// Advance of the whole piece, in font units.
  final int advance;

  /// UTF-16 offset of this piece within the widget's text.
  final int baseOffset;

  /// Per-character colours for the widget's whole text.
  final List<PdfColor> colors;

  const _Piece({
    required this.text,
    required this.font,
    required this.glyphs,
    required this.advance,
    required this.baseOffset,
    required this.colors,
  });

  _LineRun slice(int from, int to) {
    final kept = <ShapedGlyph>[];
    final colors = <ShapedGlyph, PdfColor>{};
    var advance = 0;
    // A glyph belongs to the line when its source cluster overlaps the range.
    // Clusters are never split: a Tibetan syllable that straddles the range
    // edge is kept whole with the glyphs of its cluster.
    var i = 0;
    while (i < glyphs.length) {
      final cluster = glyphs[i].cluster;
      var end = i + 1;
      while (end < glyphs.length && glyphs[end].cluster == cluster) {
        end++;
      }
      final clusterEnd = end < glyphs.length ? glyphs[end].cluster : text.length;
      if (clusterEnd > from && cluster < to) {
        for (var k = i; k < end; k++) {
          kept.add(glyphs[k]);
          colors[glyphs[k]] = this.colors[baseOffset + cluster];
          advance += glyphs[k].xAdvance;
        }
      }
      i = end;
    }
    return _LineRun(
      text: text.substring(from, to),
      font: font,
      glyphs: kept,
      colors: colors,
      advance: advance.abs(),
    );
  }
}
