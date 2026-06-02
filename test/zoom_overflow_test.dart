import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/app_settings.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/widgets/scaled_preview.dart';
import 'package:tibetan_typesetting/widgets/title_page_widget.dart';

void main() {
  testWidgets('ScaledPreview does not overflow editor title page at zoom 0.5', (
    tester,
  ) async {
    final overflowErrors = <FlutterErrorDetails>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = overflowErrors.add;

    const previewWidth = 300 * 3.78;
    const previewHeight = 120 * 3.78;
    final project = Project(
      id: 'test',
      name: 'Test',
      blocks: [],
      pageSetup: PageSetup(
        titleTibetan: '༄༅། །བླ་མ་རིན་པོ་ཆེ་ལ་ཕྱག་འཚལ་ལོ། །',
        titleChinese: '諸加持和念珠加持',
      ),
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              if (project.pageSetup.showTitlePage) ...[
                Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ScaledPreview(
                      zoom: 0.5,
                      width: previewWidth,
                      height: previewHeight,
                      child: TitlePageWidget(
                        project: project,
                        appSettings: const AppSettings(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    FlutterError.onError = originalOnError;

    expect(
      overflowErrors,
      isEmpty,
      reason:
          'Editor title page must not overflow when zoomed out. '
          'The ScaledPreview must keep the child at its full un-scaled size '
          'so internal layout (text wrapping, Row/Column) is computed at '
          'the natural page dimensions, not the scaled-down ones.',
    );
  });

  testWidgets('ScaledPreview at zoom 0.5 keeps child at full un-scaled size', (
    tester,
  ) async {
    const childKey = Key('preview-child');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScaledPreview(
            zoom: 0.5,
            width: 200,
            height: 100,
            child: SizedBox(key: childKey, width: 200, height: 100),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(ScaledPreview)), const Size(100, 50));
    expect(tester.getSize(find.byKey(childKey)), const Size(200, 100));
  });
}
