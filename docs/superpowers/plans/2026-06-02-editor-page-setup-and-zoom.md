# Editor Page Setup And Zoom Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move page geometry and frame settings into the editor, keep only vertical title and page number settings on PDF export, and add one shared zoom toolbar that scales editor page previews without scaling editing controls.

**Architecture:** Extract focused settings widgets so the editor and export screens expose different persisted `PageSetup` fields without duplicating form code. Extract a reusable zoom toolbar and a scaled-preview wrapper; export keeps its existing `InteractiveViewer`, while the editor wraps each independently rendered page preview in `ScaledPreview` so scaled layout space is reserved between normal-size editing controls.

**Tech Stack:** Flutter desktop, Dart, `flutter_test`, generated `AppLocalizations`

---

## File Structure

- Create `lib/widgets/editor_page_setup_panel.dart`: grouped editor form for width, height, margins, and frame visibility.
- Create `lib/widgets/export_pdf_settings_panel.dart`: export-only form for left vertical title and page number.
- Create `lib/widgets/preview_zoom_toolbar.dart`: shared zoom constants and minus/percentage/plus/reset toolbar.
- Create `lib/widgets/scaled_preview.dart`: scales one preview while reserving its scaled layout dimensions.
- Create `test/page_setup_widgets_test.dart`: focused widget tests for editor and export settings panels.
- Create `test/preview_zoom_widgets_test.dart`: focused widget tests for zoom toolbar and scaled-preview layout.
- Modify `lib/pages/editor_page.dart`: add grouped editor settings, one shared zoom state and toolbar, and scaled page previews.
- Modify `lib/pages/export_page.dart`: remove moved settings and sentence spacing, use the export-only panel and shared zoom toolbar.

### Task 1: Add The Editor Page Setup Panel

**Files:**
- Create: `lib/widgets/editor_page_setup_panel.dart`
- Create: `test/page_setup_widgets_test.dart`

- [ ] **Step 1: Write failing widget tests for editor geometry and frame updates**

Create `test/page_setup_widgets_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tibetan_typesetting/l10n/app_localizations_en.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/widgets/editor_page_setup_panel.dart';

void main() {
  final l10n = AppLocalizationsEn();

  Widget buildPanel({
    PageSetup? pageSetup,
    required void Function(PageSetup Function(PageSetup)) onUpdateSetup,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: EditorPageSetupPanel(
          pageSetup: pageSetup ?? PageSetup(),
          l10n: l10n,
          onUpdateSetup: onUpdateSetup,
        ),
      ),
    );
  }

  group('EditorPageSetupPanel', () {
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

      await tester.enterText(find.widgetWithText(TextFormField, 'Top (mm)'), '11');
      await tester.enterText(find.widgetWithText(TextFormField, 'Bottom (mm)'), '12');
      await tester.enterText(find.widgetWithText(TextFormField, 'Left (mm)'), '13');
      await tester.enterText(find.widgetWithText(TextFormField, 'Right (mm)'), '14');

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

      await tester.tap(find.byType(Checkbox));

      expect(updated.showFrame, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run the focused tests to verify RED**

Run:

```bash
flutter test test/page_setup_widgets_test.dart
```

Expected: FAIL because `editor_page_setup_panel.dart` and `EditorPageSetupPanel` do not exist.

- [ ] **Step 3: Implement the grouped editor panel**

Create `lib/widgets/editor_page_setup_panel.dart`. Use the existing `numberDecor()` helper and card styling from the export page. The widget interface is:

```dart
class EditorPageSetupPanel extends StatelessWidget {
  final PageSetup pageSetup;
  final AppLocalizations l10n;
  final void Function(PageSetup Function(PageSetup)) onUpdateSetup;

  const EditorPageSetupPanel({
    super.key,
    required this.pageSetup,
    required this.l10n,
    required this.onUpdateSetup,
  });
}
```

Inside `build()`:

1. Render a card with `l10n.pageSetup`.
2. Render width and height `TextFormField`s initialized from `pageWidthMm` and `pageHeightMm`.
3. Accept width and height only when `double.tryParse(value)` succeeds and the value is at least `50`.
4. Render top, bottom, left, and right margin fields with labels `${label} (mm)`.
5. For margin changes, call:

```dart
void updateMargin(String key, double value) {
  onUpdateSetup((setup) {
    final margin = setup.marginMm;
    final updated = switch (key) {
      'top' => margin.copyWith(top: value),
      'bottom' => margin.copyWith(bottom: value),
      'left' => margin.copyWith(left: value),
      'right' => margin.copyWith(right: value),
      _ => margin,
    };
    return setup.copyWith(marginMm: updated);
  });
}
```

6. Render the existing checkbox style and call:

```dart
onChanged: (value) => onUpdateSetup((setup) => setup.copyWith(showFrame: value)),
```

- [ ] **Step 4: Run the focused tests to verify GREEN**

Run:

```bash
flutter test test/page_setup_widgets_test.dart
```

Expected: PASS for the three `EditorPageSetupPanel` tests.

- [ ] **Step 5: Commit the editor panel**

```bash
git add lib/widgets/editor_page_setup_panel.dart test/page_setup_widgets_test.dart
git commit -m "feat: add editor page setup panel"
```

### Task 2: Add Reusable Preview Zoom Widgets

**Files:**
- Create: `lib/widgets/preview_zoom_toolbar.dart`
- Create: `lib/widgets/scaled_preview.dart`
- Create: `test/preview_zoom_widgets_test.dart`

- [ ] **Step 1: Write failing tests for toolbar callbacks and scaled layout**

Create `test/preview_zoom_widgets_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tibetan_typesetting/widgets/preview_zoom_toolbar.dart';
import 'package:tibetan_typesetting/widgets/scaled_preview.dart';

void main() {
  testWidgets('PreviewZoomToolbar displays zoom and invokes callbacks', (tester) async {
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
```

- [ ] **Step 2: Run the focused tests to verify RED**

Run:

```bash
flutter test test/preview_zoom_widgets_test.dart
```

Expected: FAIL because `PreviewZoomToolbar` and `ScaledPreview` do not exist.

- [ ] **Step 3: Implement the shared toolbar**

Create `lib/widgets/preview_zoom_toolbar.dart`:

```dart
import 'package:flutter/material.dart';

import '../utils/colors.dart';

const double kPreviewZoomMin = 0.2;
const double kPreviewZoomMax = 3.0;
const double kPreviewZoomStep = 0.1;

class PreviewZoomToolbar extends StatelessWidget {
  final double zoom;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onReset;

  const PreviewZoomToolbar({
    super.key,
    required this.zoom,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ZoomButton(icon: Icons.remove, onPressed: onZoomOut),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '${(zoom * 100).round()}%',
            style: TextStyle(
              color: AppColors.textBody,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ),
        _ZoomButton(icon: Icons.add, onPressed: onZoomIn),
        const SizedBox(width: 4),
        _ZoomButton(icon: Icons.refresh, onPressed: onReset),
      ],
    );
  }
}
```

Add a private `_ZoomButton` matching the existing export page button styling: a `28x28` `SizedBox`, zero-padding `IconButton`, icon size `16`, `AppColors.surfaceContainer`, and radius `6`.

- [ ] **Step 4: Implement scaled-preview layout reservation**

Create `lib/widgets/scaled_preview.dart`:

```dart
import 'package:flutter/material.dart';

class ScaledPreview extends StatelessWidget {
  final double zoom;
  final double width;
  final double height;
  final Widget child;

  const ScaledPreview({
    super.key,
    required this.zoom,
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width * zoom,
      height: height * zoom,
      child: Transform.scale(
        alignment: Alignment.topLeft,
        scale: zoom,
        child: child,
      ),
    );
  }
}
```

- [ ] **Step 5: Run the focused tests to verify GREEN**

Run:

```bash
flutter test test/preview_zoom_widgets_test.dart
```

Expected: PASS for both preview zoom widget tests.

- [ ] **Step 6: Commit the reusable preview widgets**

```bash
git add lib/widgets/preview_zoom_toolbar.dart lib/widgets/scaled_preview.dart test/preview_zoom_widgets_test.dart
git commit -m "feat: add reusable preview zoom widgets"
```

### Task 3: Trim PDF Export Settings

**Files:**
- Create: `lib/widgets/export_pdf_settings_panel.dart`
- Modify: `lib/pages/export_page.dart:1-567`
- Modify: `test/page_setup_widgets_test.dart`

- [ ] **Step 1: Write a failing test for the export-only settings panel**

Add this import at the top of `test/page_setup_widgets_test.dart`:

```dart
import 'package:tibetan_typesetting/widgets/export_pdf_settings_panel.dart';
```

Append this group inside `main()`:

```dart
group('ExportPdfSettingsPanel', () {
  testWidgets('shows only vertical title and page number fields', (tester) async {
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
```

- [ ] **Step 2: Run the focused test to verify RED**

Run:

```bash
flutter test test/page_setup_widgets_test.dart
```

Expected: FAIL because `export_pdf_settings_panel.dart` and `ExportPdfSettingsPanel` do not exist.

- [ ] **Step 3: Implement the export-only panel**

Create `lib/widgets/export_pdf_settings_panel.dart` with the same card styling as the current export settings container. Its constructor matches:

```dart
class ExportPdfSettingsPanel extends StatelessWidget {
  final PageSetup pageSetup;
  final AppLocalizations l10n;
  final void Function(PageSetup Function(PageSetup)) onUpdateSetup;
}
```

Render `l10n.pageSetup`, then only these two fields:

```dart
TextFormField(
  initialValue: pageSetup.leftVerticalTitle,
  decoration: numberDecor(l10n.leftVerticalTitle),
  onChanged: (value) => onUpdateSetup(
    (setup) => setup.copyWith(leftVerticalTitle: value),
  ),
),
TextFormField(
  initialValue: pageSetup.pageNumber,
  decoration: numberDecor(l10n.pageNumberLabel),
  onChanged: (value) => onUpdateSetup(
    (setup) => setup.copyWith(pageNumber: value),
  ),
),
```

- [ ] **Step 4: Replace inline export settings and zoom buttons**

In `lib/pages/export_page.dart`:

1. Import `export_pdf_settings_panel.dart` and `preview_zoom_toolbar.dart`.
2. Remove the `decorations.dart` import.
3. Replace local zoom constants with `kPreviewZoomMin`, `kPreviewZoomMax`, and `kPreviewZoomStep`.
4. Remove `_updateMargin()`, `_getMargin()`, and `_zoomBtn()`.
5. Replace the first settings `Container` in `_buildContent()` with:

```dart
ExportPdfSettingsPanel(
  pageSetup: ps,
  l10n: _l10n,
  onUpdateSetup: _updateSetup,
),
```

6. Replace the inline preview zoom `Row` with:

```dart
PreviewZoomToolbar(
  zoom: _zoom,
  onZoomOut: _zoomOut,
  onZoomIn: _zoomIn,
  onReset: _zoomReset,
),
```

Keep the existing export `InteractiveViewer`, keyboard shortcuts, preview hint, save path, and PDF export action unchanged.

- [ ] **Step 5: Run focused tests and analysis**

Run:

```bash
flutter test test/page_setup_widgets_test.dart test/preview_zoom_widgets_test.dart
flutter analyze
```

Expected: all focused tests PASS and analysis reports no issues.

- [ ] **Step 6: Commit the trimmed export page**

```bash
git add lib/widgets/export_pdf_settings_panel.dart lib/pages/export_page.dart test/page_setup_widgets_test.dart
git commit -m "refactor: keep export-only PDF settings"
```

### Task 4: Integrate Grouped Setup And Shared Zoom Into The Editor

**Files:**
- Modify: `lib/pages/editor_page.dart:1-595`

- [ ] **Step 1: Add editor zoom state and helper methods**

In `lib/pages/editor_page.dart`, import:

```dart
import '../widgets/editor_page_setup_panel.dart';
import '../widgets/preview_zoom_toolbar.dart';
import '../widgets/scaled_preview.dart';
```

Add transient state:

```dart
double _zoom = 1.0;
```

Add zoom handlers:

```dart
void _applyZoom(double newZoom) {
  setState(() => _zoom = newZoom.clamp(kPreviewZoomMin, kPreviewZoomMax));
}

void _zoomIn() => _applyZoom(_zoom + kPreviewZoomStep);
void _zoomOut() => _applyZoom(_zoom - kPreviewZoomStep);
void _zoomReset() => _applyZoom(1.0);
```

- [ ] **Step 2: Add grouped editor setup and one shared toolbar**

In `_buildEditor()`, insert the editor setup panel immediately before `FlowSpacingPanel`:

```dart
EditorPageSetupPanel(
  pageSetup: project.pageSetup,
  l10n: _l10n,
  onUpdateSetup: _updateSetup,
),
const SizedBox(height: 8),
```

Insert one toolbar after `FlowSpacingPanel` and before title/content previews:

```dart
Align(
  alignment: Alignment.centerRight,
  child: PreviewZoomToolbar(
    zoom: _zoom,
    onZoomOut: _zoomOut,
    onZoomIn: _zoomIn,
    onReset: _zoomReset,
  ),
),
const SizedBox(height: 12),
```

Do not put the toolbar inside `EditorPageSetupPanel` and do not generate one toolbar per page.

- [ ] **Step 3: Scale title and content previews only**

Near the top of `_buildEditor()`, derive fixed preview dimensions:

```dart
final previewWidth = project.pageSetup.pageWidthMm * kMmToPx;
final previewHeight = project.pageSetup.pageHeightMm * kMmToPx;
```

Wrap only `TitlePageWidget` and `SamplePageWidget` instances:

```dart
ScaledPreview(
  zoom: _zoom,
  width: previewWidth,
  height: previewHeight,
  child: TitlePageWidget(
    project: project,
    appSettings: _appSettings,
    pageNumber: '',
  ),
),
```

```dart
ScaledPreview(
  zoom: _zoom,
  width: previewWidth,
  height: previewHeight,
  child: SamplePageWidget(
    project: project,
    appSettings: _appSettings,
    rows: pageData.page.rows,
    flowRows: pageData.page.flowRows,
    colCount: pageData.page.colCount,
    highlightBlockId: _selectedId,
    showMark: pageIdx % 2 == 0,
    pageNumber: resolvePageNumber(
      project.pageSetup.pageNumber,
      pageIdx,
    ),
  ),
),
```

Leave `TitlePageSettingsPanel`, `FontSettingsPanel`, `EditorPageSetupPanel`, `FlowSpacingPanel`, `BlockStripWidget`, and `BlockEditorWidget` outside `ScaledPreview`.

- [ ] **Step 4: Format and verify editor integration**

Run:

```bash
dart format lib/pages/editor_page.dart
flutter test test/page_setup_widgets_test.dart test/preview_zoom_widgets_test.dart
flutter analyze
```

Expected: formatting succeeds, all focused widget tests PASS, and analysis reports no issues.

- [ ] **Step 5: Manually verify desktop editor behavior**

Run:

```bash
flutter run -d macos
```

Verify:

1. Editor shows the grouped `Page Setup` card with geometry, margins, and frame visibility.
2. Sentence spacing remains visible in the editor.
3. One zoom toolbar appears outside the grouped card.
4. Zoom changes every title/content page preview together.
5. Zoom does not resize settings, block strips, or block editors.
6. Export settings show only left vertical title and page number.
7. Export preview zoom and PDF export action remain available.

- [ ] **Step 6: Commit editor integration**

```bash
git add lib/pages/editor_page.dart
git commit -m "feat: add shared editor preview zoom"
```

### Task 5: Run Full Verification

**Files:**
- No code changes expected

- [ ] **Step 1: Run formatting check**

Run:

```bash
dart format --output=none --set-exit-if-changed lib test
```

Expected: exit code `0`.

- [ ] **Step 2: Run the complete test suite**

Run:

```bash
flutter test
```

Expected: all tests PASS.

- [ ] **Step 3: Run static analysis**

Run:

```bash
flutter analyze
```

Expected: analysis reports no issues.

- [ ] **Step 4: Inspect the final diff**

Run:

```bash
git status --short
git diff --stat HEAD~4..HEAD
```

Expected: only the planned source and test files are committed. Existing unrelated untracked artifacts remain untouched.
