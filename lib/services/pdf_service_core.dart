import 'dart:ui' show Color, TextAlign;

import '../utils/text_renderer.dart' show TextSpanDef;
import '../utils/tibetan_segmenter.dart' show isTibetanNonLetter;

List<TextSpanDef> makeColorizedSpans(
  String text,
  Color letterColor,
  Color otherColor,
) {
  if (text.isEmpty) return const [];
  return text.split('').fold<List<TextSpanDef>>(
    const [],
    (acc, c) {
      final color =
          isTibetanNonLetter(c.codeUnitAt(0)) ? otherColor : letterColor;
      if (acc.isNotEmpty && acc.last.color == color) {
        return [
          ...acc.sublist(0, acc.length - 1),
          TextSpanDef(acc.last.text + c, color),
        ];
      }
      return [...acc, TextSpanDef(c, color)];
    },
  );
}

String renderCacheKey({
  required String text,
  required String fontFamily,
  required double fontSize,
  required Color color,
  required double maxWidth,
  double? lineHeight,
  required double topPadding,
  required double bottomPadding,
  required TextAlign textAlign,
}) =>
    '${text}_|_${fontFamily}_|_${fontSize}_|_${color.toARGB32()}_|_${maxWidth}_|_${lineHeight}_|_${topPadding}_|_${bottomPadding}_|_${textAlign}';
