import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/l10n/app_localizations.dart';
import 'package:tibetan_typesetting/pages/database_recovery_page.dart';
import 'package:tibetan_typesetting/services/database_file_validator.dart';
import 'package:tibetan_typesetting/widgets/database_location_panel.dart';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('database panel shows path and invokes location actions', (
    tester,
  ) async {
    var opened = false;
    var reset = false;
    await tester.pumpWidget(
      _app(
        DatabaseLocationPanel(
          path: '/cloud/library.db',
          usesDefault: false,
          restartRequired: false,
          busy: false,
          onOpenExisting: () => opened = true,
          onUseDefault: () => reset = true,
        ),
      ),
    );

    expect(find.text('/cloud/library.db'), findsOneWidget);
    expect(find.text('Open Existing Database…'), findsOneWidget);
    expect(find.text('Use Default Database'), findsOneWidget);

    await tester.tap(find.text('Open Existing Database…'));
    await tester.tap(find.text('Use Default Database'));

    expect(opened, isTrue);
    expect(reset, isTrue);
  });

  testWidgets('database panel shows restart requirement', (tester) async {
    await tester.pumpWidget(
      _app(
        DatabaseLocationPanel(
          path: '/cloud/library.db',
          usesDefault: false,
          restartRequired: true,
          busy: false,
          onOpenExisting: () {},
          onUseDefault: () {},
        ),
      ),
    );

    expect(
      find.text('Restart the application to use this database.'),
      findsOneWidget,
    );
  });

  testWidgets('recovery page exposes all recovery actions', (tester) async {
    var retried = false;
    var chose = false;
    var reset = false;
    await tester.pumpWidget(
      _app(
        DatabaseRecoveryPage(
          issue: DatabaseValidationIssue.notFound,
          busy: false,
          onRetry: () => retried = true,
          onChooseAnother: () => chose = true,
          onUseDefault: () => reset = true,
        ),
      ),
    );

    expect(
      find.text('The selected database could not be found.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.tap(find.text('Choose Another Database…'));
    await tester.tap(find.text('Use Default Database'));

    expect(retried, isTrue);
    expect(chose, isTrue);
    expect(reset, isTrue);
  });

  testWidgets('recovery explains that containing-folder access is required', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        DatabaseRecoveryPage(
          issue: DatabaseValidationIssue.directoryAccessRequired,
          busy: false,
          onRetry: () {},
          onChooseAnother: () {},
          onUseDefault: () {},
        ),
      ),
    );

    expect(
      find.text(
        'Select the database again and grant access to its containing folder.',
      ),
      findsOneWidget,
    );
  });
}
