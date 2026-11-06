import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:harfbuzz_ffi/harfbuzz_ffi_bindings.dart' as hb;

/// A single positioned glyph produced by HarfBuzz.
///
/// All units are font units (`unitsPerEm` per em), scaled with
/// [ShapedFontData.scaleFor] when painting.
class ShapedGlyph {
  final int glyphId;
  final int cluster;
  final int xAdvance;
  final int yAdvance;
  final int xOffset;
  final int yOffset;

  const ShapedGlyph({
    required this.glyphId,
    required this.cluster,
    required this.xAdvance,
    required this.yAdvance,
    required this.xOffset,
    required this.yOffset,
  });
}

/// Result of shaping one run of text with a single font.
class ShapedRun {
  final List<ShapedGlyph> glyphs;

  /// Advance width in font units.
  final int advance;

  const ShapedRun({required this.glyphs, required this.advance});

  bool get isEmpty => glyphs.isEmpty;
}

/// Whether a line may break after [rune].
///
/// Breaks are allowed after whitespace, after Tibetan tsheg/shad and
/// punctuation, and between CJK characters. Everything else — notably the
/// letters and vowel signs of a Tibetan syllable — stays on one line, so a
/// syllable is never split across lines.
bool canBreakAfterRune(int rune) {
  if (rune == 0x20 || rune == 0x09 || rune == 0xA0) return true;
  // Tibetan tsheg, shad and punctuation.
  if (rune >= 0x0F0B && rune <= 0x0F14) return true;
  if (rune >= 0x0F3A && rune <= 0x0F3F) return true;
  // CJK: break between characters.
  if (rune >= 0x2E80 && rune <= 0x9FFF) return true;
  if (rune >= 0xF900 && rune <= 0xFAFF) return true;
  if (rune >= 0xFF00 && rune <= 0xFFEF) return true;
  return false;
}

/// Indices (exclusive ends) in [text] where a line may break, always including
/// the end of the text so the last line is reachable.
Set<int> lineBreakOpportunities(String text) {
  final breaks = <int>{text.length};
  for (var i = 0; i < text.length; i++) {
    if (canBreakAfterRune(text.codeUnitAt(i))) breaks.add(i + 1);
  }
  return breaks;
}

/// Path commands emitted while extracting a glyph outline.
sealed class GlyphPathCommand {
  const GlyphPathCommand();

  GlyphPathCommand scaled(double scale);
}

final class GlyphMoveTo extends GlyphPathCommand {
  final double x, y;
  const GlyphMoveTo(this.x, this.y);

  @override
  GlyphMoveTo scaled(double scale) => GlyphMoveTo(x * scale, y * scale);
}

final class GlyphLineTo extends GlyphPathCommand {
  final double x, y;
  const GlyphLineTo(this.x, this.y);

  @override
  GlyphLineTo scaled(double scale) => GlyphLineTo(x * scale, y * scale);
}

final class GlyphCubicTo extends GlyphPathCommand {
  final double x1, y1, x2, y2, x3, y3;
  const GlyphCubicTo(this.x1, this.y1, this.x2, this.y2, this.x3, this.y3);

  @override
  GlyphCubicTo scaled(double scale) => GlyphCubicTo(
        x1 * scale,
        y1 * scale,
        x2 * scale,
        y2 * scale,
        x3 * scale,
        y3 * scale,
      );
}

final class GlyphClosePath extends GlyphPathCommand {
  const GlyphClosePath();

  @override
  GlyphClosePath scaled(double scale) => const GlyphClosePath();
}

/// A glyph outline with its bounding box, all in font units.
///
/// Bounds are needed to place a reusable PDF form XObject for the glyph.
class GlyphOutline {
  final List<GlyphPathCommand> commands;
  final double xMin;
  final double yMin;
  final double xMax;
  final double yMax;

  const GlyphOutline({
    required this.commands,
    required this.xMin,
    required this.yMin,
    required this.xMax,
    required this.yMax,
  });

  bool get isEmpty => commands.isEmpty;

  double get width => xMax - xMin;
  double get height => yMax - yMin;
}

/// A font face opened through HarfBuzz, with its metrics and an outline
/// extractor.
///
/// Native memory is owned by this object; call [dispose] when done. Fonts are
/// cached by [PdfService] for the duration of a PDF generation.
class ShapedFontData {
  ShapedFontData._({
    required this.name,
    required this.unitsPerEm,
    required this.ascender,
    required this.descender,
    required this.lineGap,
    required Pointer<hb.hb_blob_t> blob,
    required Pointer<hb.hb_face_t> face,
    required Pointer<hb.hb_font_t> font,
  })  : _blob = blob,
        _face = face,
        _font = font {
    _drawFuncs = hb.hb_draw_funcs_create();
    final noDestroy =
        nullptr.cast<NativeFunction<hb.hb_destroy_func_tFunction>>();
    hb.hb_draw_funcs_set_move_to_func(_drawFuncs, _moveToPointer, nullptr,
        noDestroy);
    hb.hb_draw_funcs_set_line_to_func(_drawFuncs, _lineToPointer, nullptr,
        noDestroy);
    hb.hb_draw_funcs_set_quadratic_to_func(
        _drawFuncs, _quadraticToPointer, nullptr, noDestroy);
    hb.hb_draw_funcs_set_cubic_to_func(
        _drawFuncs, _cubicToPointer, nullptr, noDestroy);
    hb.hb_draw_funcs_set_close_path_func(
        _drawFuncs, _closePathPointer, nullptr, noDestroy);
  }

  /// Opens [bytes] as a font face.
  ///
  /// [name] is only used for error messages. Throws [StateError] if HarfBuzz
  /// rejects the data.
  factory ShapedFontData.fromBytes(Uint8List bytes, {String name = 'font'}) {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'Font bytes cannot be empty.');
    }

    final nativeBytes = calloc<Uint8>(bytes.length);
    nativeBytes.asTypedList(bytes.length).setAll(0, bytes);
    final blob = hb.hb_blob_create(
      nativeBytes.cast<Char>(),
      bytes.length,
      hb.hb_memory_mode_t.HB_MEMORY_MODE_DUPLICATE,
      nullptr,
      nullptr.cast<NativeFunction<hb.hb_destroy_func_tFunction>>(),
    );
    calloc.free(nativeBytes);
    if (blob == nullptr) {
      throw StateError('HarfBuzz could not create a blob for "$name".');
    }

    final face = hb.hb_face_create(blob, 0);
    if (face == nullptr) {
      hb.hb_blob_destroy(blob);
      throw StateError('HarfBuzz could not create a face for "$name".');
    }

    final font = hb.hb_font_create(face);
    if (font == nullptr) {
      hb.hb_face_destroy(face);
      hb.hb_blob_destroy(blob);
      throw StateError('HarfBuzz could not create a font for "$name".');
    }
    hb.hb_ot_font_set_funcs(font);

    final unitsPerEm = hb.hb_face_get_upem(face);
    if (unitsPerEm <= 0) {
      hb.hb_font_destroy(font);
      hb.hb_face_destroy(face);
      hb.hb_blob_destroy(blob);
      throw StateError('Font "$name" reports an invalid units-per-em.');
    }
    hb.hb_font_set_scale(font, unitsPerEm, unitsPerEm);

    final extents = calloc<hb.hb_font_extents_t>();
    final hasExtents = hb.hb_font_get_h_extents(font, extents) != 0;
    final ascender = hasExtents ? extents.ref.ascender : unitsPerEm;
    final descender = hasExtents ? extents.ref.descender : -(unitsPerEm ~/ 4);
    final lineGap = hasExtents ? extents.ref.line_gap : 0;
    calloc.free(extents);

    return ShapedFontData._(
      name: name,
      unitsPerEm: unitsPerEm,
      ascender: ascender,
      descender: descender,
      lineGap: lineGap,
      blob: blob,
      face: face,
      font: font,
    );
  }

  final String name;
  final int unitsPerEm;

  /// Distance from the baseline to the top of the line, in font units
  /// (positive).
  final int ascender;

  /// Distance from the baseline to the bottom of the line, in font units
  /// (negative for fonts that descend below the baseline).
  final int descender;

  final int lineGap;

  final Pointer<hb.hb_blob_t> _blob;
  final Pointer<hb.hb_face_t> _face;
  final Pointer<hb.hb_font_t> _font;
  late final Pointer<hb.hb_draw_funcs_t> _drawFuncs;

  final Map<int, bool> _coverage = {};
  final Map<int, GlyphOutline> _outlines = {};
  bool _disposed = false;

  double scaleFor(double fontSize) => fontSize / unitsPerEm;

  /// Natural line height at [fontSize] (ascender - descender + line gap).
  double lineHeightFor(double fontSize) {
    final raw = (ascender - descender + lineGap) * scaleFor(fontSize);
    return raw > 0 ? raw : fontSize * 1.2;
  }

  /// Whether [rune] has a glyph in this font.
  bool supportsRune(int rune) {
    _ensureAlive();
    return _coverage.putIfAbsent(rune, () {
      final glyph = calloc<hb.hb_glyph_info_t>();
      try {
        return hb.hb_font_get_nominal_glyph(_font, rune, glyph.cast()) != 0;
      } finally {
        calloc.free(glyph);
      }
    });
  }

  /// Whether every non-whitespace rune of [text] has a glyph in this font.
  bool supportsText(String text) {
    for (final rune in text.runes) {
      if (_isWhitespace(rune)) continue;
      if (!supportsRune(rune)) return false;
    }
    return true;
  }

  /// Shapes [text] (UTF-16 code units as used by Dart) into glyphs.
  ///
  /// HarfBuzz applies the font's GSUB/GPOS tables, which is what Tibetan
  /// needs for stacking consonants and positioning vowel signs.
  ShapedRun shape(String text) {
    _ensureAlive();
    if (text.isEmpty) return const ShapedRun(glyphs: [], advance: 0);

    final units = text.codeUnits;
    final buffer = calloc<Uint16>(units.length);
    final hbBuffer = hb.hb_buffer_create();
    try {
      buffer.asTypedList(units.length).setAll(0, units);
      hb.hb_buffer_add_utf16(hbBuffer, buffer, units.length, 0, units.length);
      hb.hb_buffer_guess_segment_properties(hbBuffer);
      hb.hb_shape(_font, hbBuffer, nullptr.cast<hb.hb_feature_t>(), 0);

      final length = hb.hb_buffer_get_length(hbBuffer);
      if (length == 0) return const ShapedRun(glyphs: [], advance: 0);

      final infos = hb.hb_buffer_get_glyph_infos(hbBuffer, nullptr);
      final positions = hb.hb_buffer_get_glyph_positions(hbBuffer, nullptr);

      final glyphs = List<ShapedGlyph>.generate(
        length,
        (i) => ShapedGlyph(
          glyphId: infos[i].codepoint,
          cluster: infos[i].cluster,
          xAdvance: positions[i].x_advance,
          yAdvance: positions[i].y_advance,
          xOffset: positions[i].x_offset,
          yOffset: positions[i].y_offset,
        ),
        growable: false,
      );
      final advance =
          glyphs.fold<int>(0, (sum, g) => sum + g.xAdvance).abs();
      return ShapedRun(glyphs: glyphs, advance: advance);
    } finally {
      hb.hb_buffer_destroy(hbBuffer);
      calloc.free(buffer);
    }
  }

  /// Returns the outline of [glyphId] in font units, cached per glyph.
  GlyphOutline outline(int glyphId) {
    _ensureAlive();
    final cached = _outlines[glyphId];
    if (cached != null) return cached;

    _activeSession = <GlyphPathCommand>[];
    _resetBounds();
    try {
      hb.hb_font_draw_glyph(_font, glyphId, _drawFuncs, nullptr);
      final commands = _activeSession!;
      final outline = GlyphOutline(
        commands: List<GlyphPathCommand>.unmodifiable(commands),
        xMin: _xMin,
        yMin: _yMin,
        xMax: _xMax,
        yMax: _yMax,
      );
      _outlines[glyphId] = outline;
      return outline;
    } finally {
      _activeSession = null;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _outlines.clear();
    _coverage.clear();
    hb.hb_draw_funcs_destroy(_drawFuncs);
    hb.hb_font_destroy(_font);
    hb.hb_face_destroy(_face);
    hb.hb_blob_destroy(_blob);
  }

  void _ensureAlive() {
    if (_disposed) {
      throw StateError('ShapedFontData "$name" has already been disposed.');
    }
  }

  static bool _isWhitespace(int rune) =>
      rune == 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D ||
      rune == 0xA0;

  // HarfBuzz draw callbacks. The active command list and its running bounds are
  // held in statics so the top-level FFI callbacks can reach them; outlines are
  // extracted one at a time and never re-entrantly.
  static List<GlyphPathCommand>? _activeSession;
  static double _xMin = 0;
  static double _yMin = 0;
  static double _xMax = 0;
  static double _yMax = 0;

  static void _resetBounds() {
    _xMin = double.infinity;
    _yMin = double.infinity;
    _xMax = double.negativeInfinity;
    _yMax = double.negativeInfinity;
  }

  static void _extendBounds(double x, double y) {
    if (x < _xMin) _xMin = x;
    if (x > _xMax) _xMax = x;
    if (y < _yMin) _yMin = y;
    if (y > _yMax) _yMax = y;
  }

  static void _moveTo(
    Pointer<hb.hb_draw_funcs_t> funcs,
    Pointer<Void> drawData,
    Pointer<hb.hb_draw_state_t> state,
    double toX,
    double toY,
    Pointer<Void> userData,
  ) {
    _activeSession?.add(GlyphMoveTo(toX, toY));
    _extendBounds(toX, toY);
  }

  static void _lineTo(
    Pointer<hb.hb_draw_funcs_t> funcs,
    Pointer<Void> drawData,
    Pointer<hb.hb_draw_state_t> state,
    double toX,
    double toY,
    Pointer<Void> userData,
  ) {
    _activeSession?.add(GlyphLineTo(toX, toY));
    _extendBounds(toX, toY);
  }

  static void _quadraticTo(
    Pointer<hb.hb_draw_funcs_t> funcs,
    Pointer<Void> drawData,
    Pointer<hb.hb_draw_state_t> state,
    double controlX,
    double controlY,
    double toX,
    double toY,
    Pointer<Void> userData,
  ) {
    final commands = _activeSession;
    if (commands == null) return;

    // TrueType quadratics have no direct equivalent in PDF paths; convert to
    // a cubic using the standard 2/3 control-point rule.
    final fromX = state.ref.current_x;
    final fromY = state.ref.current_y;
    commands.add(GlyphCubicTo(
      fromX + 2 / 3 * (controlX - fromX),
      fromY + 2 / 3 * (controlY - fromY),
      toX + 2 / 3 * (controlX - toX),
      toY + 2 / 3 * (controlY - toY),
      toX,
      toY,
    ));
    _extendBounds(toX, toY);
  }

  static void _cubicTo(
    Pointer<hb.hb_draw_funcs_t> funcs,
    Pointer<Void> drawData,
    Pointer<hb.hb_draw_state_t> state,
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
    Pointer<Void> userData,
  ) {
    _activeSession?.add(GlyphCubicTo(x1, y1, x2, y2, x3, y3));
    _extendBounds(x1, y1);
    _extendBounds(x2, y2);
    _extendBounds(x3, y3);
  }

  static void _closePath(
    Pointer<hb.hb_draw_funcs_t> funcs,
    Pointer<Void> drawData,
    Pointer<hb.hb_draw_state_t> state,
    Pointer<Void> userData,
  ) {
    _activeSession?.add(const GlyphClosePath());
  }

  static final hb.hb_draw_move_to_func_t _moveToPointer =
      Pointer.fromFunction<hb.hb_draw_move_to_func_tFunction>(_moveTo);
  static final hb.hb_draw_line_to_func_t _lineToPointer =
      Pointer.fromFunction<hb.hb_draw_line_to_func_tFunction>(_lineTo);
  static final hb.hb_draw_quadratic_to_func_t _quadraticToPointer =
      Pointer.fromFunction<hb.hb_draw_quadratic_to_func_tFunction>(
          _quadraticTo);
  static final hb.hb_draw_cubic_to_func_t _cubicToPointer =
      Pointer.fromFunction<hb.hb_draw_cubic_to_func_tFunction>(_cubicTo);
  static final hb.hb_draw_close_path_func_t _closePathPointer =
      Pointer.fromFunction<hb.hb_draw_close_path_func_tFunction>(_closePath);
}
