import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:tibetan_typesetting/l10n/app_localizations.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/widgets/block_editor.dart';

void main() {
  setUp(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('BlockEditorWidget', () {
    testWidgets('uses the supplied focus node for the Tibetan field', (
      tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BlockEditorWidget(
              selectedBlock: const TextBlock(id: '1', tibetan: 'ཀ'),
              selectedIndex: 0,
              totalBlocks: 1,
              onUpdateBlock: (_) {},
              onMoveBlock: (_) {},
              onDeleteBlock: () {},
              onToggleColumnBreak: () {},
              onTogglePageBreak: () {},
              onToggleSmallText: () {},
              onToggleFreeTextFormat: () {},
              onToggleOpeningMarkFormat: () {},
              onSelectPrev: () {},
              onSelectNext: () {},
              textFocusNode: focusNode,
            ),
          ),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.focusNode, same(focusNode));

      focusNode.requestFocus();
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });
  });
}
