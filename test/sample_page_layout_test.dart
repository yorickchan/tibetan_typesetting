import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/utils/colors.dart';
import 'package:tibetan_typesetting/widgets/sample_page.dart';

void main() {
  testWidgets('preview block top padding matches PDF text placement', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SamplePageWidget(
          project: Project(
            id: 'project',
            name: 'Project',
            blocks: [const TextBlock(id: 'block', tibetan: 'བོད་ཡིག།')],
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
            widget.padding == EdgeInsets.only(top: 5, left: 2 * kMmToPx, right: 2 * kMmToPx),
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
              const TextBlock(
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

  testWidgets('non-template preview uses the PDF inner frame inset', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SamplePageWidget(
          project: Project(
            id: 'project',
            name: 'Project',
            blocks: [const TextBlock(id: 'block', tibetan: 'བོད་ཡིག།')],
            updatedAt: '',
            createdAt: '',
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == EdgeInsets.all(2 * kMmToPx),
      ),
      findsOneWidget,
    );
  });

  testWidgets('preview text can paint beyond a row without flex overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SamplePageWidget(
          project: Project(
            id: 'project',
            name: 'Project',
            blocks: [const TextBlock(id: 'block', tibetan: 'བོད་ཡིག།')],
            updatedAt: '',
            createdAt: '',
          ),
        ),
      ),
    );

    expect(find.byType(OverflowBox), findsWidgets);
  });

  testWidgets('opening mark red renders the whole mark in rose', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SamplePageWidget(
          project: Project(
            id: 'project',
            name: 'Project',
            blocks: [
              const TextBlock(
                id: 'block',
                tibetan: '༄༅།།',
                format: TextBlockFormat.openingMark,
                openingMarkRed: true,
              ),
            ],
            updatedAt: '',
            createdAt: '',
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('༄༅།།'));
    expect(text.style!.color, AppColors.rose600);
  });

  testWidgets('tapping a preview text block reports its id', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: SamplePageWidget(
          project: Project(
            id: 'project',
            name: 'Project',
            blocks: [const TextBlock(id: 'block', tibetan: 'ཀ')],
            updatedAt: '',
            createdAt: '',
          ),
          onSelectBlock: (id) => selected = id,
        ),
      ),
    );

    final tapTarget = find.descendant(
      of: find.byType(SamplePageWidget),
      matching: find.byType(GestureDetector),
    );
    expect(tapTarget, findsOneWidget);

    await tester.tap(tapTarget);

    expect(selected, 'block');
  });
}
