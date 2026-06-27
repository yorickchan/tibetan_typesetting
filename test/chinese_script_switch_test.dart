import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/l10n/app_localizations.dart';
import 'package:tibetan_typesetting/models/chinese_script.dart';
import 'package:tibetan_typesetting/widgets/chinese_script_switch.dart';

void main() {
  Widget app(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('shows both scripts and allows reselecting the active script', (
    tester,
  ) async {
    final selections = <ChineseScript>[];

    await tester.pumpWidget(
      app(
        ChineseScriptSwitch(
          selectedScript: ChineseScript.simplified,
          onSelected: selections.add,
        ),
      ),
    );

    expect(find.text('Simplified Chinese'), findsOneWidget);
    expect(find.text('Traditional Chinese'), findsOneWidget);
    await tester.tap(find.text('Simplified Chinese'));
    await tester.tap(find.text('Traditional Chinese'));

    expect(selections, [ChineseScript.simplified, ChineseScript.traditional]);
  });

  testWidgets('disables both scripts and shows progress while busy', (
    tester,
  ) async {
    final selections = <ChineseScript>[];

    await tester.pumpWidget(
      app(
        ChineseScriptSwitch(
          selectedScript: ChineseScript.traditional,
          busy: true,
          onSelected: selections.add,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Simplified Chinese'));
    await tester.tap(find.text('Traditional Chinese'));

    expect(selections, isEmpty);
  });

  testWidgets('conversion dialog warns and confirms the target script', (
    tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showChineseScriptConversionDialog(
                context,
                ChineseScript.traditional,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Convert to Traditional Chinese?'), findsOneWidget);
    expect(find.textContaining('may not convert back exactly'), findsOneWidget);
    await tester.tap(find.text('Convert'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
