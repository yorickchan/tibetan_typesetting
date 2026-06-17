import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tibetan_typesetting/l10n/app_localizations_en.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/widgets/editor_page_setup_panel.dart';
import 'package:tibetan_typesetting/widgets/export_pdf_settings_panel.dart';

void main() {
  final l10n = AppLocalizationsEn();

  Widget buildPanel({
    PageSetup? pageSetup,
    bool isOpen = true,
    VoidCallback? onToggle,
    required void Function(PageSetup Function(PageSetup)) onUpdateSetup,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: EditorPageSetupPanel(
          pageSetup: pageSetup ?? PageSetup(),
          isOpen: isOpen,
          onToggle: onToggle ?? () {},
          l10n: l10n,
          onUpdateSetup: onUpdateSetup,
        ),
      ),
    );
  }

  group('EditorPageSetupPanel', () {
    testWidgets('hides details when collapsed and invokes toggle from header', (
      tester,
    ) async {
      var toggleCount = 0;
      await tester.pumpWidget(
        buildPanel(
          isOpen: false,
          onToggle: () => toggleCount++,
          onUpdateSetup: (_) {},
        ),
      );

      expect(find.text(l10n.pageSetup), findsOneWidget);
      expect(find.text(l10n.pageWidth), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      await tester.tap(find.text(l10n.pageSetup));

      expect(toggleCount, 1);
    });

    testWidgets('updates page width from the width field', (tester) async {
      PageSetup updated = PageSetup();
      await tester.pumpWidget(
        buildPanel(onUpdateSetup: (updater) => updated = updater(updated)),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.pageWidth),
        '232',
      );

      expect(updated.pageWidthMm, 232);
    });

    testWidgets('updates each margin from its field', (tester) async {
      PageSetup updated = PageSetup();
      await tester.pumpWidget(
        buildPanel(onUpdateSetup: (updater) => updated = updater(updated)),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Top (mm)'),
        '11',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bottom (mm)'),
        '12',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Left (mm)'),
        '13',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Right (mm)'),
        '14',
      );

      expect(updated.marginMm.top, 11);
      expect(updated.marginMm.bottom, 12);
      expect(updated.marginMm.left, 13);
      expect(updated.marginMm.right, 14);
    });

    testWidgets('updates show frame from the checkbox', (tester) async {
      PageSetup updated = PageSetup(showFrame: true);
      await tester.pumpWidget(
        buildPanel(
          pageSetup: updated,
          onUpdateSetup: (updater) => updated = updater(updated),
        ),
      );

      await tester.tap(find.byType(Checkbox).first);

      expect(updated.showFrame, isFalse);
    });
  });

  group('ExportPdfSettingsPanel', () {
    testWidgets('shows only vertical title and page number fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportPdfSettingsPanel(
              pageSetup: PageSetup(),
              l10n: l10n,
              onUpdateSetup: (_) {},
            ),
          ),
        ),
      );

      expect(find.text(l10n.leftVerticalTitle), findsOneWidget);
      expect(find.text(l10n.pageNumberLabel), findsOneWidget);
      expect(find.text(l10n.sentenceSpacing), findsNothing);
      expect(find.text(l10n.pageWidth), findsNothing);
      expect(find.text(l10n.pageHeight), findsNothing);
      expect(find.text(l10n.showFrame), findsNothing);
    });
  });
}
