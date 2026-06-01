import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tibetan_typesetting/widgets/preview_zoom_toolbar.dart';
import 'package:tibetan_typesetting/widgets/scaled_preview.dart';

void main() {
  testWidgets('PreviewZoomToolbar displays zoom and invokes callbacks', (
    tester,
  ) async {
    var zoomOutCount = 0;
    var zoomInCount = 0;
    var resetCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PreviewZoomToolbar(
            zoom: 1.2,
            onZoomOut: () => zoomOutCount++,
            onZoomIn: () => zoomInCount++,
            onReset: () => resetCount++,
          ),
        ),
      ),
    );

    expect(find.text('120%'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.refresh));

    expect(zoomOutCount, 1);
    expect(zoomInCount, 1);
    expect(resetCount, 1);
  });

  testWidgets('ScaledPreview reserves scaled dimensions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScaledPreview(
            zoom: 1.5,
            width: 200,
            height: 100,
            child: SizedBox(width: 200, height: 100),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(ScaledPreview)), const Size(300, 150));
  });
}
