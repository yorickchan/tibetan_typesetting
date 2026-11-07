import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tibetan_typesetting/models/font_config.dart';
import 'package:tibetan_typesetting/services/font_service.dart';
import 'package:tibetan_typesetting/utils/shaped_text_pdf.dart';

/// Fonts whose glyphs extend left of the origin exercise the form XObject
/// scaling path: `PdfGraphics.drawXObject` derives its scale from `BBox[2]`
/// alone, so a bounding box that does not start at 0 silently squeezes glyphs.
const _fonts = <String>[
  // xMin is about -1348 for combining marks while xMax is only ~307.
  '/System/Library/Fonts/Supplemental/Kailasa.ttc',
];

void main() {
  for (final path in _fonts) {
    final file = File(path);
    final name = path.split('/').last;

    testWidgets('$name renders glyphs without horizontal squeezing', (
      tester,
    ) async {
      if (!file.existsSync()) {
        markTestSkipped('$name is not installed');
        return;
      }

      await tester.runAsync(() async {
        final shaping = await FontService().shapingFont(
          FontConfig(fontFamily: name, fontPath: path, fontSize: 12),
        );
        expect(shaping, isNotNull, reason: 'font should open for shaping');

        final doc = pw.Document();
        // A single line keeps the comparison free of wrapping decisions.
        const text = 'དཀོན་མཆོག';
        doc.addPage(
          pw.Page(
            pageFormat: const PdfPageFormat(300, 80, marginAll: 8),
            build: (_) => ShapedText(
              text,
              fonts: [shaping!],
              fontSize: 12,
              color: PdfColors.black,
              maxWidth: 280,
            ),
          ),
        );
        final bytes = await doc.save();

        // Every glyph form must declare a bounding box that starts at the origin
        // and has positive extent; that is what makes drawXObject's scale exact.
        final raw = String.fromCharCodes(bytes);
        final boxes = RegExp(
          r'/BBox\s*\[\s*([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s*\]',
        ).allMatches(raw).toList();
        expect(boxes, isNotEmpty, reason: 'expected glyph form XObjects');

        for (final match in boxes) {
          final values = [
            for (var i = 1; i <= 4; i++) double.parse(match.group(i)!),
          ];
          expect(values[0], 0, reason: 'BBox xMin must be 0');
          expect(values[1], 0, reason: 'BBox yMin must be 0');
          expect(values[2], greaterThan(0), reason: 'BBox width must be > 0');
          expect(values[3], greaterThan(0), reason: 'BBox height must be > 0');
        }

        // Sanity check the underlying outline really does start left of zero,
        // otherwise this test would pass trivially.
        final run = shaping!.data.shape(text);
        final anyNegative = run.glyphs.any(
          (glyph) => shaping.data.outline(glyph.glyphId).xMin < 0,
        );
        expect(
          anyNegative,
          isTrue,
          reason: 'this font is expected to have glyphs left of the origin',
        );
      });
    }, timeout: const Timeout(Duration(minutes: 5)));

    testWidgets('$name keeps vowel signs black in red-highlighted text', (
      tester,
    ) async {
      if (!file.existsSync()) {
        markTestSkipped('$name is not installed');
        return;
      }

      await tester.runAsync(() async {
        final shaping = await FontService().shapingFont(
          FontConfig(fontFamily: name, fontPath: path, fontSize: 12),
        );
        expect(shaping, isNotNull, reason: 'font should open for shaping');

        const text = 'དཀོན';
        const rose = PdfColor.fromInt(0xFFe11d48);
        final widget = ShapedText(
          text,
          fonts: [shaping!],
          fontSize: 12,
          color: PdfColors.black,
          maxWidth: 280,
          colorForRune: (i, _) =>
              text.codeUnitAt(i) == 0x0F7C ? PdfColors.black : rose,
        );

        final run = shaping.data.shape(text);
        final clusterStart = run.glyphs.indexWhere((g) => g.cluster == 1);
        expect(clusterStart, isNot(-1), reason: 'expected the ཀོ cluster');
        expect(
          run.glyphs[clusterStart + 1].cluster,
          1,
          reason: 'expected the vowel sign in the same cluster',
        );

        final colors = widget.glyphColors;
        expect(colors[clusterStart], rose);
        expect(colors[clusterStart + 1], PdfColors.black);
      });
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
