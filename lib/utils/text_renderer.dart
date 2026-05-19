import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class RenderedText {
  final Uint8List pngBytes;
  final double width;
  final double height;
  RenderedText({
    required this.pngBytes,
    required this.width,
    required this.height,
  });
}

/// Render text using Flutter's HarfBuzz-powered text engine (which fully
/// supports OpenType GSUB/GPOS for complex scripts like Tibetan) and return
/// a high-resolution PNG suitable for embedding in a PDF.
///
/// [scale] controls pixel density. 460/72 ≈ 6.389× gives exactly 460 DPI
/// in a 72-DPI PDF coordinate space.
Future<RenderedText?> renderTextToPng(
  String text, {
  required String fontFamily,
  List<String>? fontFamilyFallback,
  required double fontSize,
  required Color color,
  required double maxWidth,
  double scale = 460 / 72,
  double? lineHeight,
  TextAlign textAlign = TextAlign.left,
}) async {
  if (text.trim().isEmpty) return null;

  final style = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: fontSize * scale,
    color: color,
    height: lineHeight,
  );

  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: textAlign,
  );

  // For centered/right alignment, force the painter's layout width to the
  // full available width so that TextAlign positions each line within the
  // full canvas (otherwise lines are centered inside their own intrinsic
  // bounding box, which produces left-aligned-looking output).
  final useFullWidth =
      textAlign != TextAlign.left && textAlign != TextAlign.start;
  final layoutMax = maxWidth * scale;
  painter.layout(
    minWidth: useFullWidth ? layoutMax : 0,
    maxWidth: layoutMax,
  );

  final w = useFullWidth
      ? layoutMax.ceilToDouble()
      : painter.width.ceilToDouble();
  final h = painter.height.ceilToDouble();
  if (w <= 0 || h <= 0) return null;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
  painter.paint(canvas, Offset.zero);
  final picture = recorder.endRecording();

  final image = await picture.toImage(w.toInt(), h.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  painter.dispose();

  if (byteData == null) return null;

  return RenderedText(
    pngBytes: byteData.buffer.asUint8List(),
    width: useFullWidth ? maxWidth : w / scale,
    height: h / scale,
  );
}
