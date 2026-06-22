import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/widgets/sample_page.dart';

void main() {
  testWidgets('preview block top padding matches PDF text placement', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SamplePageWidget(
          project: Project(
            id: 'project',
            name: 'Project',
            blocks: [TextBlock(id: 'block', tibetan: 'བོད་ཡིག།')],
            updatedAt: '',
            createdAt: '',
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.padding ==
                const EdgeInsets.only(top: 5, left: 6, right: 6),
      ),
      findsOneWidget,
    );
  });

  testWidgets('preview Chinese text uses the PDF line height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SamplePageWidget(
          project: Project(
            id: 'project',
            name: 'Project',
            blocks: [
              TextBlock(
                id: 'block',
                tibetan: 'བོད་ཡིག།',
                chinesePronunciation: 'pinyin',
                chineseTranslation: 'translation',
              ),
            ],
            updatedAt: '',
            createdAt: '',
          ),
        ),
      ),
    );

    expect(tester.widget<Text>(find.text('pinyin')).style!.height, 1.4);
    expect(tester.widget<Text>(find.text('translation')).style!.height, 1.4);
  });
}
