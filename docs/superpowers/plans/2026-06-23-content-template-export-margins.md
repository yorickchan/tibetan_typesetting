# Content Template Export Margins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make content-template PDF exports use the configured content-page margins while independently placing the SVG using its template inset.

**Architecture:** Add a pure geometry utility that produces distinct content and template rectangles in millimetres. The PDF service will consume these rectangles only on templated content pages; normal framed and unframed layouts remain unchanged. Unit tests will lock the separation between page margins and template insets.

**Tech Stack:** Flutter/Dart, `flutter_test`, `pdf` package.

---

## File Structure

- Create: `lib/utils/content_page_template_layout.dart` — pure content and SVG rectangle calculations.
- Create: `test/content_page_template_layout_test.dart` — regression tests for independent content-margin and template-inset geometry.
- Modify: `lib/services/pdf_service.dart:1-16, 462-515, 727-1056` — pass the separate rectangles to templated PDF content-page construction.

### Task 1: Specify the independent template geometry

**Files:**

- Create: `lib/utils/content_page_template_layout.dart`
- Test: `test/content_page_template_layout_test.dart`

- [ ] **Step 1: Write the failing regression test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/utils/content_page_template_layout.dart';

void main() {
  test('content bounds use page margins while template bounds use its inset', () {
    final layout = contentPageTemplateLayout(
      pageWidthMm: 300,
      pageHeightMm: 120,
      contentMargin: const MarginMm(top: 9, right: 25, bottom: 13, left: 21),
      templateInset: const TemplateInset(top: 3, right: 7, bottom: 5, left: 11),
    );

    expect(layout.content.leftMm, 21);
    expect(layout.content.topMm, 9);
    expect(layout.content.widthMm, 254);
    expect(layout.content.heightMm, 98);
    expect(layout.template.leftMm, 11);
    expect(layout.template.topMm, 3);
    expect(layout.template.widthMm, 282);
    expect(layout.template.heightMm, 112);
  });
}
```

- [ ] **Step 2: Run the test and verify it fails because the utility does not exist**

Run: `rtk flutter test test/content_page_template_layout_test.dart`

Expected: FAIL with an import or undefined `contentPageTemplateLayout` error.

- [ ] **Step 3: Add the minimal geometry utility**

```dart
import '../models/project.dart';

class ContentPageTemplateBounds {
  final double leftMm;
  final double topMm;
  final double widthMm;
  final double heightMm;

  const ContentPageTemplateBounds({
    required this.leftMm,
    required this.topMm,
    required this.widthMm,
    required this.heightMm,
  });
}

class ContentPageTemplateLayout {
  final ContentPageTemplateBounds content;
  final ContentPageTemplateBounds template;

  const ContentPageTemplateLayout({
    required this.content,
    required this.template,
  });
}

ContentPageTemplateLayout contentPageTemplateLayout({
  required double pageWidthMm,
  required double pageHeightMm,
  required MarginMm contentMargin,
  required TemplateInset templateInset,
}) {
  return ContentPageTemplateLayout(
    content: ContentPageTemplateBounds(
      leftMm: contentMargin.left,
      topMm: contentMargin.top,
      widthMm: pageWidthMm - contentMargin.left - contentMargin.right,
      heightMm: pageHeightMm - contentMargin.top - contentMargin.bottom,
    ),
    template: ContentPageTemplateBounds(
      leftMm: templateInset.left,
      topMm: templateInset.top,
      widthMm: pageWidthMm - templateInset.left - templateInset.right,
      heightMm: pageHeightMm - templateInset.top - templateInset.bottom,
    ),
  );
}
```

- [ ] **Step 4: Run the focused test and verify it passes**

Run: `rtk flutter test test/content_page_template_layout_test.dart`

Expected: PASS with 1 test passing.

- [ ] **Step 5: Commit the test and utility**

```bash
git add lib/utils/content_page_template_layout.dart test/content_page_template_layout_test.dart
git commit -m "test: cover content template geometry"
```

### Task 2: Use independent rectangles in templated PDF export

**Files:**

- Modify: `lib/services/pdf_service.dart:12, 462-515, 727-1056`
- Test: `test/content_page_template_layout_test.dart`

- [ ] **Step 1: Extend the regression test with a subsequent-page configuration**

Add a second test using the same helper with a different content margin and
template inset. Assert that the subsequent page's content left edge and width
follow its own margin and that its template left edge and width follow its own
inset:

```dart
expect(subsequent.content.leftMm, 35);
expect(subsequent.content.widthMm, 250);
expect(subsequent.template.leftMm, 9);
expect(subsequent.template.widthMm, 288);
```

- [ ] **Step 2: Run the focused regression test and verify it passes**

Run: `rtk flutter test test/content_page_template_layout_test.dart`

Expected: PASS with 2 tests passing. This locks the shared geometry used by
both first and subsequent export pages before it is wired into the PDF service.

- [ ] **Step 3: Pass the rectangles through `PdfService` and use them only for templated pages**

```dart
final templateLayout = hasPageTemplate
    ? contentPageTemplateLayout(
        pageWidthMm: ps.pageWidthMm,
        pageHeightMm: ps.pageHeightMm,
        contentMargin: pageMargin,
        templateInset: pageTemplateInset,
      )
    : null;

// _buildContentPage receives templateLayout. For a templated page, convert
// templateLayout.content to PDF points for Padding and cW/cH, and convert
// templateLayout.template to PDF points only for Positioned/SvgImage.
// In particular, cH is content.heightMm * PdfPageFormat.mm, with no extra
// fixed inset subtracted.
```

Also add `import '../utils/content_page_template_layout.dart';` with the existing relative-import grouping. Keep the existing `inset`, side-panel, and frame calculations untouched when `templateLayout == null`.

- [ ] **Step 4: Run the focused regression test after export integration**

Run: `rtk flutter test test/content_page_template_layout_test.dart`

Expected: PASS with 2 tests passing.

- [ ] **Step 5: Run static analysis for the modified files**

Run: `rtk flutter analyze lib/services/pdf_service.dart lib/utils/content_page_template_layout.dart test/content_page_template_layout_test.dart`

Expected: exit code 0 with no diagnostics.

- [ ] **Step 6: Commit the export integration**

```bash
git add lib/services/pdf_service.dart lib/utils/content_page_template_layout.dart test/content_page_template_layout_test.dart
git commit -m "fix: align content template export margins"
```

### Task 3: Verify the repository state

**Files:**

- Modify: none
- Test: `test/content_page_template_layout_test.dart`

- [ ] **Step 1: Run the full test suite**

Run: `rtk flutter test`

Expected: exit code 0 with all tests passing.

- [ ] **Step 2: Run full static analysis**

Run: `rtk flutter analyze`

Expected: exit code 0 with no diagnostics.

- [ ] **Step 3: Inspect the final diff for unintended changes**

Run: `rtk git diff --check HEAD^ HEAD && rtk git status --short`

Expected: no whitespace errors; only intentional working-tree changes, if any, remain.
