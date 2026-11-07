import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/pdf_service_core.dart';

/// The exported page and the preview must reserve the same space for content.
///
/// The preview insets the page by its margins and then by one frame padding
/// above and below (`Padding(EdgeInsets.all(inset))`). The PDF used to subtract
/// that padding twice, so its content box was 4 mm shorter, every row was
/// squeezed, and the exported Tibetan looked smaller than on screen.
void main() {
  group('contentBoxHeightMm', () {
    test('subtracts one inset per side, matching the preview frame', () {
      // 80 mm page, 10 mm margins, 2 mm frame inset.
      // Preview: (80 - 20) - 2*2 = 56 mm.
      expect(
        contentBoxHeightMm(
          pageHeightMm: 80,
          marginTopMm: 10,
          marginBottomMm: 10,
          insetMm: 2,
        ),
        closeTo(56, 1e-9),
      );
    });

    test('is 4 mm larger than the previous double-inset behaviour', () {
      final correct = contentBoxHeightMm(
        pageHeightMm: 80,
        marginTopMm: 10,
        marginBottomMm: 10,
        insetMm: 2,
      );
      // The old formula subtracted 4*inset; keep this assertion so a
      // regression is reported in terms of the user-visible 4 mm squeeze.
      const double oldBehaviour = 80 - 20 - 4 * 2;
      expect(correct - oldBehaviour, closeTo(4, 1e-9));
    });

    test('handles asymmetric margins', () {
      expect(
        contentBoxHeightMm(
          pageHeightMm: 120,
          marginTopMm: 8,
          marginBottomMm: 12,
          insetMm: 2,
        ),
        closeTo(96, 1e-9),
      );
    });
  });

  group('contentBoxWidthMm', () {
    test('subtracts one inset and one side panel per side', () {
      // 232 mm page, 10 mm side margins, 2 mm inset, 14 mm side panels.
      expect(
        contentBoxWidthMm(
          pageWidthMm: 232,
          marginLeftMm: 10,
          marginRightMm: 10,
          insetMm: 2,
          sidePanelWidthMm: 14,
        ),
        closeTo(232 - 20 - 4 - 28, 1e-9),
      );
    });
  });
}
