# Code Quality & Performance Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve code extensibility, fix performance bottlenecks, eliminate duplication, and add test coverage through focused, low-risk improvements.

**Architecture:** Conservative refactoring approach — make models immutable, extract shared utilities, add type safety to block updates, implement caching and memoization, and add comprehensive tests. All changes preserve existing behavior.

**Tech Stack:** Flutter/Dart, sqflite, pdf package

---

## File Structure

### New Files
- `lib/models/block_update.dart` — Typed block update class
- `lib/utils/decorations.dart` — Shared InputDecoration builders
- `lib/utils/snackbar.dart` — Shared SnackBar helper
- `lib/utils/save_state_mixin.dart` — Shared save-state logic
- `lib/widgets/project_card.dart` — Extracted ProjectCard widget
- `lib/widgets/flow_spacing_panel.dart` — Extracted FlowSpacingPanel widget
- `test/models_test.dart` — Model serialization tests
- `test/pagination_test.dart` — Pagination logic tests
- `test/pronunciation_service_test.dart` — PronunciationService tests

### Modified Files
- `lib/models/project.dart` — Make all fields final
- `lib/pages/editor_page.dart` — Use typed BlockUpdate, memoize pagination, lazy ListView, use shared utilities
- `lib/pages/export_page.dart` — Use shared utilities, use extracted FlowSpacingPanel
- `lib/pages/projects_page.dart` — Use shared utilities, use extracted ProjectCard
- `lib/widgets/block_editor.dart` — Use typed BlockUpdate, use shared decorations
- `lib/services/pdf_service.dart` — Add rendering cache
- `analysis_options.yaml` — Add stricter lint rules

---

## Task 1: Immutable Models

**Files:**
- Modify: `lib/models/project.dart`
- Test: `test/models_test.dart`

- [ ] **Step 1: Write test for model immutability**

```dart
// test/models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/project.dart';

void main() {
  group('MarginMm', () {
    test('copyWith preserves unchanged fields', () {
      final original = MarginMm(top: 10, right: 20, bottom: 30, left: 40);
      final copy = original.copyWith(top: 15);
      
      expect(copy.top, 15);
      expect(copy.right, 20);
      expect(copy.bottom, 30);
      expect(copy.left, 40);
    });

    test('serialization round-trip', () {
      final original = MarginMm(top: 10, right: 20, bottom: 30, left: 40);
      final json = original.toJson();
      final restored = MarginMm.fromJson(json);
      
      expect(restored.top, original.top);
      expect(restored.right, original.right);
      expect(restored.bottom, original.bottom);
      expect(restored.left, original.left);
    });
  });

  group('TextBlock', () {
    test('copyWith preserves unchanged fields', () {
      final original = TextBlock(
        id: 'test-id',
        tibetan: 'བོད་སྐད',
        chinesePronunciation: 'bod skad',
        chineseTranslation: '藏语',
        pageBreakBefore: true,
        columnBreakBefore: false,
        smallText: true,
        format: TextBlockFormat.normal,
        columnSpan: 2,
      );
      
      final copy = original.copyWith(tibetan: 'བོད་ཡིག');
      
      expect(copy.id, original.id);
      expect(copy.tibetan, 'བོད་ཡིག');
      expect(copy.chinesePronunciation, original.chinesePronunciation);
      expect(copy.chineseTranslation, original.chineseTranslation);
      expect(copy.pageBreakBefore, original.pageBreakBefore);
      expect(copy.columnBreakBefore, original.columnBreakBefore);
      expect(copy.smallText, original.smallText);
      expect(copy.format, original.format);
      expect(copy.columnSpan, original.columnSpan);
    });

    test('copyWith with clearColumnSpan', () {
      final original = TextBlock(id: 'test', columnSpan: 2);
      final copy = original.copyWith(clearColumnSpan: true);
      
      expect(copy.columnSpan, null);
    });

    test('serialization round-trip', () {
      final original = TextBlock(
        id: 'test-id',
        tibetan: 'བོད་སྐད',
        chinesePronunciation: 'bod skad',
        chineseTranslation: '藏语',
        pageBreakBefore: true,
        columnBreakBefore: false,
        smallText: true,
        format: TextBlockFormat.freeText,
        columnSpan: 2,
      );
      
      final json = original.toJson();
      final restored = TextBlock.fromJson(json);
      
      expect(restored.id, original.id);
      expect(restored.tibetan, original.tibetan);
      expect(restored.chinesePronunciation, original.chinesePronunciation);
      expect(restored.chineseTranslation, original.chineseTranslation);
      expect(restored.pageBreakBefore, original.pageBreakBefore);
      expect(restored.columnBreakBefore, original.columnBreakBefore);
      expect(restored.smallText, original.smallText);
      expect(restored.format, original.format);
      expect(restored.columnSpan, original.columnSpan);
    });
  });

  group('PageSetup', () {
    test('copyWith preserves unchanged fields', () {
      final original = PageSetup(
        pageWidthMm: 300,
        pageHeightMm: 120,
        columnCount: 5,
        showFrame: true,
      );
      
      final copy = original.copyWith(pageWidthMm: 350);
      
      expect(copy.pageWidthMm, 350);
      expect(copy.pageHeightMm, original.pageHeightMm);
      expect(copy.columnCount, original.columnCount);
      expect(copy.showFrame, original.showFrame);
    });

    test('serialization round-trip', () {
      final original = PageSetup(
        pageWidthMm: 300,
        pageHeightMm: 120,
        columnCount: 5,
        showFrame: true,
        leftVerticalTitle: 'Test',
        pageNumber: '1',
        flowGap: 0.02,
      );
      
      final json = original.toJson();
      final restored = PageSetup.fromJson(json);
      
      expect(restored.pageWidthMm, original.pageWidthMm);
      expect(restored.pageHeightMm, original.pageHeightMm);
      expect(restored.columnCount, original.columnCount);
      expect(restored.showFrame, original.showFrame);
      expect(restored.leftVerticalTitle, original.leftVerticalTitle);
      expect(restored.pageNumber, original.pageNumber);
      expect(restored.flowGap, original.flowGap);
    });
  });

  group('Project', () {
    test('copyWith preserves unchanged fields', () {
      final original = Project(
        id: 'test-id',
        name: 'Test Project',
        tags: ['tag1', 'tag2'],
        blocks: [TextBlock(id: 'block1')],
        updatedAt: '2026-01-01T00:00:00Z',
        createdAt: '2026-01-01T00:00:00Z',
      );
      
      final copy = original.copyWith(name: 'Updated Name');
      
      expect(copy.id, original.id);
      expect(copy.name, 'Updated Name');
      expect(copy.tags, original.tags);
      expect(copy.blocks.length, original.blocks.length);
      expect(copy.updatedAt, original.updatedAt);
      expect(copy.createdAt, original.createdAt);
    });

    test('serialization round-trip', () {
      final original = Project(
        id: 'test-id',
        name: 'Test Project',
        tags: ['tag1', 'tag2'],
        blocks: [
          TextBlock(id: 'block1', tibetan: 'བོད་སྐད'),
          TextBlock(id: 'block2', tibetan: 'བོད་ཡིག'),
        ],
        updatedAt: '2026-01-01T00:00:00Z',
        createdAt: '2026-01-01T00:00:00Z',
      );
      
      final jsonStr = original.toJsonString();
      final restored = Project.fromJsonString(jsonStr);
      
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.tags, original.tags);
      expect(restored.blocks.length, original.blocks.length);
      expect(restored.blocks[0].tibetan, original.blocks[0].tibetan);
      expect(restored.blocks[1].tibetan, original.blocks[1].tibetan);
      expect(restored.updatedAt, original.updatedAt);
      expect(restored.createdAt, original.createdAt);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `flutter test test/models_test.dart`
Expected: PASS (tests should pass with current mutable models)

- [ ] **Step 3: Make MarginMm fields final**

```dart
// lib/models/project.dart - MarginMm class
class MarginMm {
  final double top;
  final double right;
  final double bottom;
  final double left;

  MarginMm({this.top = 10, this.right = 10, this.bottom = 10, this.left = 10});
  
  // ... rest of class unchanged
}
```

- [ ] **Step 4: Run test to verify it still passes**

Run: `flutter test test/models_test.dart`
Expected: PASS

- [ ] **Step 5: Make TextBlock fields final**

```dart
// lib/models/project.dart - TextBlock class
class TextBlock {
  final String id;
  final String tibetan;
  final String chinesePronunciation;
  final String chineseTranslation;
  final bool pageBreakBefore;
  final bool columnBreakBefore;
  final bool smallText;
  final TextBlockFormat format;
  final int? columnSpan;

  TextBlock({
    required this.id,
    this.tibetan = '',
    this.chinesePronunciation = '',
    this.chineseTranslation = '',
    this.pageBreakBefore = false,
    this.columnBreakBefore = false,
    this.smallText = false,
    this.format = TextBlockFormat.normal,
    this.columnSpan,
  });
  
  // ... rest of class unchanged
}
```

- [ ] **Step 6: Run test to verify it still passes**

Run: `flutter test test/models_test.dart`
Expected: PASS

- [ ] **Step 7: Make PageSetup fields final**

```dart
// lib/models/project.dart - PageSetup class
class PageSetup {
  final double pageWidthMm;
  final double pageHeightMm;
  final MarginMm marginMm;
  final int columnCount;
  final bool showFrame;
  final String leftVerticalTitle;
  final String pageNumber;
  final double flowGap;
  final bool showTitlePage;
  final String titleTibetan;
  final String titleChinese;
  final FontConfig? tibetanFont;
  final FontConfig? pronunciationFont;
  final FontConfig? translationFont;
  final FontConfig? titleTibetanFont;
  final FontConfig? titleChineseFont;

  PageSetup({
    this.pageWidthMm = 300,
    this.pageHeightMm = 120,
    MarginMm? marginMm,
    this.columnCount = 5,
    this.showFrame = true,
    this.leftVerticalTitle = '',
    this.pageNumber = '',
    this.flowGap = 0.01,
    this.showTitlePage = true,
    this.titleTibetan = '',
    this.titleChinese = '',
    this.tibetanFont,
    this.pronunciationFont,
    this.translationFont,
    this.titleTibetanFont,
    this.titleChineseFont,
  }) : marginMm = marginMm ?? MarginMm();
  
  // ... rest of class unchanged
}
```

- [ ] **Step 8: Run test to verify it still passes**

Run: `flutter test test/models_test.dart`
Expected: PASS

- [ ] **Step 9: Make Project fields final**

```dart
// lib/models/project.dart - Project class
class Project {
  final String id;
  final String name;
  final List<String> tags;
  final List<TextBlock> blocks;
  final PageSetup pageSetup;
  final String updatedAt;
  final String createdAt;

  Project({
    required this.id,
    required this.name,
    List<String>? tags,
    List<TextBlock>? blocks,
    PageSetup? pageSetup,
    required this.updatedAt,
    required this.createdAt,
  }) : tags = tags ?? [],
       blocks = blocks ?? [],
       pageSetup = pageSetup ?? PageSetup();
  
  // ... rest of class unchanged
}
```

- [ ] **Step 10: Run test to verify it still passes**

Run: `flutter test test/models_test.dart`
Expected: PASS

- [ ] **Step 11: Run full test suite**

Run: `flutter test`
Expected: PASS (all existing tests still pass)

- [ ] **Step 12: Run analyzer**

Run: `flutter analyze`
Expected: No errors (may have warnings about unused fields, which is fine)

- [ ] **Step 13: Commit**

```bash
git add lib/models/project.dart test/models_test.dart
git commit -m "refactor: make all model fields final for immutability"
```

---

## Task 2: Stricter Lint Rules

**Files:**
- Modify: `analysis_options.yaml`

- [ ] **Step 1: Add stricter lint rules**

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_final_fields: true
    prefer_const_constructors: true
    prefer_const_declarations: true
    avoid_catches_without_on_clauses: true
    unnecessary_lambdas: true
    prefer_final_locals: true
    prefer_final_in_for_each: true
```

- [ ] **Step 2: Run analyzer to see new warnings**

Run: `flutter analyze`
Expected: Multiple warnings about non-final fields, missing const, etc.

- [ ] **Step 3: Commit**

```bash
git add analysis_options.yaml
git commit -m "chore: add stricter lint rules for better code quality"
```

---

## Task 3: Shared Decorations Utility

**Files:**
- Create: `lib/utils/decorations.dart`
- Modify: `lib/widgets/block_editor.dart`
- Modify: `lib/pages/export_page.dart`
- Modify: `lib/pages/projects_page.dart`

- [ ] **Step 1: Create shared decorations utility**

```dart
// lib/utils/decorations.dart
import 'package:flutter/material.dart';

import 'colors.dart';

InputDecoration fieldDecoration({
  required String label,
  required String placeholder,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      color: AppColors.textMuted,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    ),
    hintText: placeholder,
    hintStyle: TextStyle(
      color: AppColors.textMuted.withValues(alpha: 0.5),
      fontSize: 13,
    ),
    filled: true,
    fillColor: AppColors.inputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.sky500),
    ),
  );
}

InputDecoration numberDecor(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    filled: true,
    fillColor: AppColors.inputFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.borderSubtle),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.borderSubtle),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.sky500),
    ),
  );
}
```

- [ ] **Step 2: Update block_editor.dart to use shared decorations**

```dart
// lib/widgets/block_editor.dart - _EditorFieldsState class
// Add import at top:
import '../utils/decorations.dart';

// Replace _fieldDecoration method calls with:
decoration: fieldDecoration(
  label: widget.l10n.tibetanLabelShort,
  placeholder: widget.l10n.tibetanText,
),

// Remove the _fieldDecoration method entirely
```

- [ ] **Step 3: Update export_page.dart to use shared decorations**

```dart
// lib/pages/export_page.dart - _ExportPageState class
// Add import at top:
import '../utils/decorations.dart';

// Replace _numberDecor method calls with:
decoration: numberDecor(_l10n.pageWidth),

// Remove the _numberDecor method entirely
```

- [ ] **Step 4: Update projects_page.dart to use shared decorations**

```dart
// lib/pages/projects_page.dart - _showNameTagsDialog method
// Add import at top:
import '../utils/decorations.dart';

// Replace inline InputDecoration with:
decoration: fieldDecoration(
  label: effectiveL10n.name,
  placeholder: effectiveL10n.projectName,
),
```

- [ ] **Step 5: Run analyzer**

Run: `flutter analyze`
Expected: No new errors

- [ ] **Step 6: Run tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/utils/decorations.dart lib/widgets/block_editor.dart lib/pages/export_page.dart lib/pages/projects_page.dart
git commit -m "refactor: extract shared InputDecoration utilities"
```

---

## Task 4: Shared SnackBar Utility

**Files:**
- Create: `lib/utils/snackbar.dart`
- Modify: `lib/pages/projects_page.dart`
- Modify: `lib/pages/export_page.dart`

- [ ] **Step 1: Create shared SnackBar utility**

```dart
// lib/utils/snackbar.dart
import 'package:flutter/material.dart';

import 'colors.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.rose600 : AppColors.sky500,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}
```

- [ ] **Step 2: Update projects_page.dart to use shared SnackBar**

```dart
// lib/pages/projects_page.dart - _ProjectsPageState class
// Add import at top:
import '../utils/snackbar.dart';

// Replace _showSnackMsg method with:
void _showSnackMsg(String msg, {bool error = false}) {
  if (!mounted) return;
  showAppSnackBar(context, msg, error: error);
}
```

- [ ] **Step 3: Update export_page.dart to use shared SnackBar**

```dart
// lib/pages/export_page.dart - _ExportPageState class
// Add import at top:
import '../utils/snackbar.dart';

// Replace _showSnack method with:
void _showSnack(String msg, {bool error = false}) {
  if (!mounted) return;
  showAppSnackBar(context, msg, error: error);
}
```

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze`
Expected: No new errors

- [ ] **Step 5: Run tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/utils/snackbar.dart lib/pages/projects_page.dart lib/pages/export_page.dart
git commit -m "refactor: extract shared SnackBar utility"
```

---

## Task 5: Shared Save State Mixin

**Files:**
- Create: `lib/utils/save_state_mixin.dart`
- Modify: `lib/pages/editor_page.dart`
- Modify: `lib/pages/export_page.dart`

- [ ] **Step 1: Create shared save state mixin**

```dart
// lib/utils/save_state_mixin.dart
import 'package:flutter/material.dart';

mixin SaveStateMixin<T extends StatefulWidget> on State<T> {
  String _saveState = 'idle';
  String get saveState => _saveState;

  Future<void> performSave(Future<void> Function() saveAction) async {
    if (!mounted) return;
    setState(() => _saveState = 'saving');
    try {
      await saveAction();
      if (!mounted) return;
      setState(() => _saveState = 'saved');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _saveState == 'saved') {
          setState(() => _saveState = 'idle');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveState = 'error');
    }
  }
}
```

- [ ] **Step 2: Update editor_page.dart to use SaveStateMixin**

```dart
// lib/pages/editor_page.dart - _EditorPageState class
// Add import at top:
import '../utils/save_state_mixin.dart';

// Add mixin to class declaration:
class _EditorPageState extends State<EditorPage> with SaveStateMixin<EditorPage> {
  // ... existing code

// Replace _saveCurrent method with:
Future<void> _saveCurrent() async {
  if (_project == null) return;
  await performSave(() => _db.updateProject(_project!));
}

// Remove _saveState field (now provided by mixin)
// Update build method to use saveState getter instead of _saveState
```

- [ ] **Step 3: Update export_page.dart to use SaveStateMixin**

```dart
// lib/pages/export_page.dart - _ExportPageState class
// Add import at top:
import '../utils/save_state_mixin.dart';

// Add mixin to class declaration:
class _ExportPageState extends State<ExportPage> with SaveStateMixin<ExportPage> {
  // ... existing code

// Replace _saveProject method with:
Future<void> _saveProject() async {
  if (_project == null) return;
  await performSave(() => _db.updateProject(_project!));
}

// Remove _saveState field (now provided by mixin)
// Update build method to use saveState getter instead of _saveState
```

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze`
Expected: No new errors

- [ ] **Step 5: Run tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/utils/save_state_mixin.dart lib/pages/editor_page.dart lib/pages/export_page.dart
git commit -m "refactor: extract shared SaveStateMixin for save-state logic"
```

---

## Task 6: Typed Block Updates

**Files:**
- Create: `lib/models/block_update.dart`
- Modify: `lib/pages/editor_page.dart`
- Modify: `lib/widgets/block_editor.dart`

- [ ] **Step 1: Create BlockUpdate class**

```dart
// lib/models/block_update.dart
import 'project.dart';

class BlockUpdate {
  final String? tibetan;
  final String? chinesePronunciation;
  final String? chineseTranslation;
  final TextBlockFormat? format;
  final int? columnSpan;
  final bool clearColumnSpan;

  const BlockUpdate({
    this.tibetan,
    this.chinesePronunciation,
    this.chineseTranslation,
    this.format,
    this.columnSpan,
    this.clearColumnSpan = false,
  });
}
```

- [ ] **Step 2: Update editor_page.dart to use BlockUpdate**

```dart
// lib/pages/editor_page.dart - _EditorPageState class
// Add import at top:
import '../models/block_update.dart';

// Replace _updateBlock method signature and implementation:
void _updateBlock(BlockUpdate update) {
  if (_project == null || _selectedBlock == null) return;
  final selectedId = _selectedId;
  setState(() {
    final blocks = _project!.blocks.map((b) {
      if (b.id != selectedId) return b;
      return b.copyWith(
        tibetan: update.tibetan,
        chinesePronunciation: update.chinesePronunciation,
        chineseTranslation: update.chineseTranslation,
        format: update.format,
        columnSpan: update.columnSpan,
        clearColumnSpan: update.clearColumnSpan,
      );
    }).toList();
    _project = _project!.copyWith(blocks: blocks);
  });
  _bumpSave();
}
```

- [ ] **Step 3: Update block_editor.dart to use BlockUpdate**

```dart
// lib/widgets/block_editor.dart
// Add import at top:
import '../models/block_update.dart';

// Update BlockEditorWidget callback signature:
final ValueChanged<BlockUpdate> onUpdateBlock;

// Update _Toolbar callback signature:
final ValueChanged<int?> onSetColumnSpan;

// Update _Toolbar onSetColumnSpan handler:
onSetColumnSpan: (span) => onUpdateBlock(
  BlockUpdate(columnSpan: span, clearColumnSpan: span == null),
),

// Update _EditorFields to use BlockUpdate:
widget.onUpdateBlock(const BlockUpdate(tibetan: v));
widget.onUpdateBlock(const BlockUpdate(chinesePronunciation: newPron));
widget.onUpdateBlock(const BlockUpdate(chinesePronunciation: v));
widget.onUpdateBlock(const BlockUpdate(chineseTranslation: v));
```

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze`
Expected: No new errors

- [ ] **Step 5: Run tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/models/block_update.dart lib/pages/editor_page.dart lib/widgets/block_editor.dart
git commit -m "refactor: replace Map<String, dynamic> with typed BlockUpdate class"
```

---

## Task 7: PDF Rendering Cache

**Files:**
- Modify: `lib/services/pdf_service.dart`

- [ ] **Step 1: Add render cache to PdfService**

```dart
// lib/services/pdf_service.dart - PdfService class
class PdfService {
  PdfService._();
  static final PdfService _instance = PdfService._();
  factory PdfService() => _instance;

  final _fontService = FontService();
  String? _dharmaWheelSvg;
  final Map<String, _Img> _renderCache = {};

  // ... rest of class
}
```

- [ ] **Step 2: Update _render method to use cache**

```dart
// lib/services/pdf_service.dart - _render method
Future<_Img?> _render(
  String text,
  double fontSize,
  Color color,
  double maxWidth, {
  required String fontFamily,
  List<String>? fontFamilyFallback,
  double? lineHeight,
  double topPadding = 0,
  double bottomPadding = 0,
  TextAlign textAlign = TextAlign.left,
}) async {
  if (text.trim().isEmpty) return null;
  
  final key = '${text.hashCode}_$fontFamily_$fontSize_${color.value}_${maxWidth}_${lineHeight}_${topPadding}_${bottomPadding}_${textAlign}';
  if (_renderCache.containsKey(key)) {
    return _renderCache[key];
  }
  
  final r = await renderTextToPng(
    text,
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: fontSize,
    color: color,
    maxWidth: maxWidth,
    lineHeight: lineHeight,
    topPadding: topPadding,
    bottomPadding: bottomPadding,
    textAlign: textAlign,
  );
  if (r == null) return null;
  
  final img = _Img(pw.MemoryImage(r.pngBytes), r.width, r.height);
  _renderCache[key] = img;
  return img;
}
```

- [ ] **Step 3: Clear cache at start of generatePdfWithWarnings**

```dart
// lib/services/pdf_service.dart - generatePdfWithWarnings method
Future<PdfGenerationResult> generatePdfWithWarnings(
  Project project, {
  AppSettings? appSettings,
}) async {
  _renderCache.clear();
  await _loadSvg();
  
  // ... rest of method
}
```

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze`
Expected: No new errors

- [ ] **Step 5: Run tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/services/pdf_service.dart
git commit -m "perf: add rendering cache to PdfService for faster PDF export"
```

---

## Task 8: Editor Performance - Memoize Pagination

**Files:**
- Modify: `lib/pages/editor_page.dart`

- [ ] **Step 1: Add cache fields to _EditorPageState**

```dart
// lib/pages/editor_page.dart - _EditorPageState class
class _EditorPageState extends State<EditorPage> with SaveStateMixin<EditorPage> {
  final _db = DatabaseService();
  final _settingsService = SettingsService();
  Project? _project;
  AppSettings _appSettings = AppSettings();
  bool _loading = true;
  String? _error;
  String? _selectedId;
  bool _titleOpen = false;
  bool _fontOpen = false;
  Timer? _saveTimer;
  
  // Add cache fields:
  List<_PageWithBlocks>? _cachedPages;
  List<TextBlock>? _lastBlocks;
  
  // ... rest of class
}
```

- [ ] **Step 2: Update _pagesWithBlocks getter to use cache**

```dart
// lib/pages/editor_page.dart - _pagesWithBlocks getter
List<_PageWithBlocks> get _pagesWithBlocks {
  if (_project == null) return [];
  
  // Return cached result if blocks haven't changed
  if (_cachedPages != null && identical(_project!.blocks, _lastBlocks)) {
    return _cachedPages!;
  }
  
  final pages = paginateBlocks(
    _project!.blocks,
    0,
    4,
    _project!.pageSetup.flowGap,
  );
  
  _cachedPages = pages.map((page) {
    final seen = <String>{};
    final blocks = <TextBlock>[];
    for (final row in page.flowRows) {
      for (final cell in row) {
        final block = cell.block;
        if (!seen.contains(block.id)) {
          seen.add(block.id);
          blocks.add(block);
        }
      }
    }
    return _PageWithBlocks(page: page, blocks: blocks);
  }).toList();
  
  _lastBlocks = _project!.blocks;
  return _cachedPages!;
}
```

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze`
Expected: No new errors

- [ ] **Step 4: Run tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/pages/editor_page.dart
git commit -m "perf: memoize pagination computation in editor"
```

---

## Task 9: Editor Performance - Lazy ListView

**Files:**
- Modify: `lib/pages/editor_page.dart`

- [ ] **Step 1: Convert ListView to ListView.builder**

```dart
// lib/pages/editor_page.dart - _buildEditor method
Widget _buildEditor() {
  final project = _project!;
  final pagesWithBlocks = _pagesWithBlocks;

  final tibFont = font_utils.effectiveFont(
    project.pageSetup.tibetanFont,
    _appSettings.tibetanFont,
    fallbackTibetanFont,
  );
  final pronFont = font_utils.effectiveFont(
    project.pageSetup.pronunciationFont,
    _appSettings.pronunciationFont,
    fallbackChineseFont,
  );
  final transFont = font_utils.effectiveFont(
    project.pageSetup.translationFont,
    _appSettings.translationFont,
    fallbackChineseFont,
  );

  final blockIndexById = <String, int>{};
  for (var i = 0; i < project.blocks.length; i++) {
    blockIndexById[project.blocks[i].id] = i;
  }
  int globalIndexOf(String id) => blockIndexById[id] ?? -1;

  // Calculate total item count
  final itemCount = 3 + (project.pageSetup.showTitlePage ? 1 : 0) + pagesWithBlocks.length;
  
  return ListView.builder(
    itemCount: itemCount,
    itemBuilder: (context, index) {
      // Title panel
      if (index == 0) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TitlePageSettingsPanel(
            pageSetup: project.pageSetup,
            appSettings: _appSettings,
            isOpen: _titleOpen,
            onToggle: () => setState(() => _titleOpen = !_titleOpen),
            onUpdateSetup: _updateSetup,
            l10n: _l10n,
          ),
        );
      }
      
      // Font panel
      if (index == 1) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FontSettingsPanel(
            pageSetup: project.pageSetup,
            appSettings: _appSettings,
            isOpen: _fontOpen,
            onToggle: () => setState(() => _fontOpen = !_fontOpen),
            onUpdateSetup: _updateSetup,
            l10n: _l10n,
          ),
        );
      }
      
      // Spacing panel
      if (index == 2) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _FlowSpacingPanel(
            pageSetup: project.pageSetup,
            l10n: _l10n,
            onUpdateSetup: _updateSetup,
          ),
        );
      }
      
      // Title page preview (if enabled)
      int adjustedIndex = index - 3;
      if (project.pageSetup.showTitlePage) {
        if (adjustedIndex == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: TitlePageWidget(
                  project: project,
                  appSettings: _appSettings,
                  pageNumber: '',
                ),
              ),
            ),
          );
        }
        adjustedIndex--;
      }
      
      // Content pages
      final pageIdx = adjustedIndex;
      if (pageIdx < pagesWithBlocks.length) {
        final pageData = pagesWithBlocks[pageIdx];
        final pageBlockIds = pageData.blocks.map((b) => b.id).toSet();
        final selectedOnThisPage =
            _selectedId != null && pageBlockIds.contains(_selectedId);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              BlockStripWidget(
                blocks: pageData.blocks,
                globalIndexOf: globalIndexOf,
                selectedId: _selectedId,
                onSelect: (id) => setState(() => _selectedId = id),
                onAdd: _addBlock,
                onAddPage: _addPage,
                pageIndex: pageIdx,
                tibetanFontFamily: tibFont.fontFamily,
                translationFontFamily: transFont.fontFamily,
              ),
              if (selectedOnThisPage) ...[
                const SizedBox(height: 8),
                BlockEditorWidget(
                  selectedBlock: _selectedBlock,
                  selectedIndex: _selectedIndex,
                  totalBlocks: project.blocks.length,
                  onUpdateBlock: _updateBlock,
                  onMoveBlock: _moveBlock,
                  onDeleteBlock: _deleteBlock,
                  onToggleColumnBreak: _toggleColumnBreak,
                  onTogglePageBreak: _togglePageBreak,
                  onToggleSmallText: _toggleSmallText,
                  onToggleFreeTextFormat: _toggleFreeTextFormat,
                  onSelectPrev: _selectPrev,
                  onSelectNext: _selectNext,
                  tibetanFontFamily: tibFont.fontFamily,
                  pronunciationFontFamily: pronFont.fontFamily,
                  translationFontFamily: transFont.fontFamily,
                ),
              ],
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
            ],
          ),
        );
      }
      
      return const SizedBox.shrink();
    },
  );
}
```

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No new errors

- [ ] **Step 3: Run tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/pages/editor_page.dart
git commit -m "perf: convert editor ListView to lazy ListView.builder"
```

---

## Task 10: Extract ProjectCard Widget

**Files:**
- Create: `lib/widgets/project_card.dart`
- Modify: `lib/pages/projects_page.dart`

- [ ] **Step 1: Create project_card.dart**

```dart
// lib/widgets/project_card.dart
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../utils/colors.dart';

class ProjectCard extends StatelessWidget {
  final ProjectListItem item;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onExportJson;
  final VoidCallback onExportPrint;
  final String Function(String) formatDate;
  final AppLocalizations l10n;

  const ProjectCard({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
    required this.onExportJson,
    required this.onExportPrint,
    required this.formatDate,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.updated(formatDate(item.updatedAt)),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _cardIconBtn(Icons.edit_outlined, onRename),
                  _cardIconBtn(Icons.copy, onDuplicate),
                  _cardIconBtn(
                    Icons.delete_outline,
                    onDelete,
                    color: AppColors.rose300,
                  ),
                ],
              ),
            ],
          ),
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: item.tags
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                        color: AppColors.surface.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          color: AppColors.textBody,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: Icon(
                  Icons.folder_open,
                  size: 16,
                  color: AppColors.buttonMutedFg,
                ),
                label: Text(
                  l10n.open,
                  style: TextStyle(
                    color: AppColors.buttonMutedFg,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.buttonMutedBg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onOpen,
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onExportPrint,
                    child: Text(
                      l10n.exportPdf,
                      style: TextStyle(color: AppColors.sky400, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onExportJson,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download,
                          size: 14,
                          color: AppColors.textBody,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          l10n.exportJson,
                          style: TextStyle(
                            color: AppColors.textBody,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardIconBtn(
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    final c = color ?? AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle),
          color: AppColors.surface.withValues(alpha: 0.2),
        ),
        child: Icon(icon, size: 14, color: c),
      ),
    );
  }
}
```

- [ ] **Step 2: Update projects_page.dart to use extracted ProjectCard**

```dart
// lib/pages/projects_page.dart
// Add import at top:
import '../widgets/project_card.dart';

// In _projectGrid method, replace _ProjectCard with ProjectCard:
itemBuilder: (context, index) => ProjectCard(
  item: items[index],
  onOpen: () => _openProject(items[index].id),
  onRename: () => _renameProject(items[index]),
  onDuplicate: () => _duplicateProject(items[index].id),
  onDelete: () => _deleteProject(items[index]),
  onExportJson: () => _exportJson(items[index]),
  onExportPrint: () => _openExport(items[index].id),
  formatDate: _formatDate,
  l10n: _l10n,
),

// Remove the _ProjectCard class entirely from projects_page.dart
```

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze`
Expected: No new errors

- [ ] **Step 4: Run tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/project_card.dart lib/pages/projects_page.dart
git commit -m "refactor: extract ProjectCard widget to separate file"
```

---

## Task 11: Extract FlowSpacingPanel Widget

**Files:**
- Create: `lib/widgets/flow_spacing_panel.dart`
- Modify: `lib/pages/editor_page.dart`
- Modify: `lib/pages/export_page.dart`

- [ ] **Step 1: Create flow_spacing_panel.dart**

```dart
// lib/widgets/flow_spacing_panel.dart
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../utils/colors.dart';

class FlowSpacingPanel extends StatelessWidget {
  final PageSetup pageSetup;
  final AppLocalizations l10n;
  final void Function(PageSetup Function(PageSetup)) onUpdateSetup;

  const FlowSpacingPanel({
    super.key,
    required this.pageSetup,
    required this.l10n,
    required this.onUpdateSetup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.format_line_spacing, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            l10n.sentenceSpacing,
            style: TextStyle(
              color: AppColors.textBody,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Slider(
              value: pageSetup.flowGap.clamp(0.0, 0.08),
              min: 0,
              max: 0.08,
              divisions: 8,
              activeColor: AppColors.sky500,
              inactiveColor: AppColors.border,
              onChanged: (v) => onUpdateSetup((s) => s.copyWith(flowGap: v)),
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              '${(pageSetup.flowGap * 100).round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textCaption, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Update editor_page.dart to use extracted FlowSpacingPanel**

```dart
// lib/pages/editor_page.dart
// Add import at top:
import '../widgets/flow_spacing_panel.dart';

// In _buildEditor method, replace _FlowSpacingPanel with FlowSpacingPanel:
FlowSpacingPanel(
  pageSetup: project.pageSetup,
  l10n: _l10n,
  onUpdateSetup: _updateSetup,
),

// Remove the _FlowSpacingPanel class entirely from editor_page.dart
```

- [ ] **Step 3: Update export_page.dart to use extracted FlowSpacingPanel**

```dart
// lib/pages/export_page.dart
// Add import at top:
import '../widgets/flow_spacing_panel.dart';

// In _buildContent method, replace inline flow gap slider with:
FlowSpacingPanel(
  pageSetup: ps,
  l10n: _l10n,
  onUpdateSetup: _updateSetup,
),
```

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze`
Expected: No new errors

- [ ] **Step 5: Run tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/flow_spacing_panel.dart lib/pages/editor_page.dart lib/pages/export_page.dart
git commit -m "refactor: extract FlowSpacingPanel widget to separate file"
```

---

## Task 12: Pagination Tests

**Files:**
- Create: `test/pagination_test.dart`

- [ ] **Step 1: Write pagination tests**

```dart
// test/pagination_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/utils/sample_layout.dart';

void main() {
  group('paginateBlocks', () {
    test('empty blocks returns single empty page', () {
      final pages = paginateBlocks([], 5);
      
      expect(pages.length, 1);
      expect(pages[0].flowRows, isEmpty);
    });

    test('single block returns single page with one row', () {
      final blocks = [TextBlock(id: 'block1', tibetan: 'བོད་སྐད')];
      final pages = paginateBlocks(blocks, 5);
      
      expect(pages.length, 1);
      expect(pages[0].flowRows.length, 1);
      expect(pages[0].flowRows[0].length, 1);
      expect(pages[0].flowRows[0][0].block.id, 'block1');
    });

    test('page break creates new page', () {
      final blocks = [
        TextBlock(id: 'block1', tibetan: 'བོད་སྐད'),
        TextBlock(id: 'block2', tibetan: 'བོད་ཡིག', pageBreakBefore: true),
      ];
      final pages = paginateBlocks(blocks, 5);
      
      expect(pages.length, 2);
      expect(pages[0].flowRows.length, 1);
      expect(pages[1].flowRows.length, 1);
    });

    test('column break creates new row', () {
      final blocks = [
        TextBlock(id: 'block1', tibetan: 'བོད་སྐད'),
        TextBlock(id: 'block2', tibetan: 'བོད་ཡིག', columnBreakBefore: true),
      ];
      final pages = paginateBlocks(blocks, 5);
      
      expect(pages.length, 1);
      expect(pages[0].flowRows.length, 2);
    });

    test('respects maxRows per page', () {
      final blocks = List.generate(
        10,
        (i) => TextBlock(id: 'block$i', tibetan: 'བོད་སྐད'),
      );
      final pages = paginateBlocks(blocks, 5, 4);
      
      // Should create multiple pages with max 4 rows each
      expect(pages.length, greaterThan(1));
      for (final page in pages) {
        expect(page.flowRows.length, lessThanOrEqualTo(4));
      }
    });
  });

  group('estimateBlockWidthFraction', () {
    test('block with columnSpan uses manual span', () {
      final block = TextBlock(id: 'test', columnSpan: 3);
      final fraction = estimateBlockWidthFraction(block);
      
      expect(fraction, closeTo(3 / 24, 0.01));
    });

    test('empty block returns minimum fraction', () {
      final block = TextBlock(id: 'test');
      final fraction = estimateBlockWidthFraction(block);
      
      expect(fraction, greaterThanOrEqualTo(0.09));
    });

    test('long text returns larger fraction', () {
      final shortBlock = TextBlock(id: 'short', tibetan: 'བོད');
      final longBlock = TextBlock(id: 'long', tibetan: 'བོད་སྐད་ཆེན་པོ་ཞིག');
      
      final shortFraction = estimateBlockWidthFraction(shortBlock);
      final longFraction = estimateBlockWidthFraction(longBlock);
      
      expect(longFraction, greaterThan(shortFraction));
    });
  });

  group('splitLines', () {
    test('splits by newline', () {
      final lines = splitLines('line1\nline2\nline3');
      
      expect(lines.length, 3);
      expect(lines[0], 'line1');
      expect(lines[1], 'line2');
      expect(lines[2], 'line3');
    });

    test('trims whitespace', () {
      final lines = splitLines('  line1  \n  line2  ');
      
      expect(lines[0], 'line1');
      expect(lines[1], 'line2');
    });

    test('filters empty lines', () {
      final lines = splitLines('line1\n\n\nline2');
      
      expect(lines.length, 2);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `flutter test test/pagination_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add test/pagination_test.dart
git commit -m "test: add pagination logic tests"
```

---

## Task 13: PronunciationService Tests

**Files:**
- Create: `test/pronunciation_service_test.dart`

- [ ] **Step 1: Write PronunciationService tests**

```dart
// test/pronunciation_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/pronunciation_service.dart';

void main() {
  group('PronunciationService', () {
    test('isSavablePronunciation returns true for valid characters', () {
      expect(PronunciationService.isSavablePronunciation('bod'), true);
      expect(PronunciationService.isSavablePronunciation('藏'), true);
      expect(PronunciationService.isSavablePronunciation('123'), true);
    });

    test('isSavablePronunciation returns false for invalid characters', () {
      expect(PronunciationService.isSavablePronunciation(''), false);
      expect(PronunciationService.isSavablePronunciation('   '), false);
      expect(PronunciationService.isSavablePronunciation('!@#'), false);
    });

    test('savablePronunciationCharacters filters valid characters', () {
      final chars = PronunciationService.savablePronunciationCharacters('bod 123!');
      
      expect(chars, ['b', 'o', 'd', '1', '2', '3']);
    });

    test('savablePronunciationCharacters handles empty string', () {
      final chars = PronunciationService.savablePronunciationCharacters('');
      
      expect(chars, isEmpty);
    });

    test('savablePronunciationCharacters handles unicode', () {
      final chars = PronunciationService.savablePronunciationCharacters('藏语');
      
      expect(chars, ['藏', '语']);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `flutter test test/pronunciation_service_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add test/pronunciation_service_test.dart
git commit -m "test: add PronunciationService validation tests"
```

---

## Task 14: Final Verification

**Files:**
- All modified files

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No errors (warnings are acceptable)

- [ ] **Step 3: Run the application**

Run: `flutter run -d macos`
Expected: Application launches and functions normally

- [ ] **Step 4: Test PDF export**

Manually test:
1. Create a new project
2. Add several text blocks with Tibetan text
3. Navigate to Export page
4. Generate PDF
5. Verify PDF is created successfully

Expected: PDF export works and is noticeably faster for projects with repeated text

- [ ] **Step 5: Test editor performance**

Manually test:
1. Open a project with many blocks (10+)
2. Scroll through the editor
3. Edit blocks
4. Verify smooth scrolling and responsive UI

Expected: Editor is smooth and responsive

- [ ] **Step 6: Final commit**

```bash
git add .
git commit -m "chore: complete code quality optimization

- Made all model fields final for immutability
- Added typed BlockUpdate class for type safety
- Extracted shared utilities (decorations, snackbar, save state)
- Added PDF rendering cache for faster export
- Memoized pagination and converted to lazy ListView
- Extracted large widgets to separate files
- Added stricter lint rules
- Added comprehensive test coverage

All changes preserve existing behavior while improving
extensibility, performance, and maintainability."
```

---

## Summary

This implementation plan consists of 14 tasks covering:

1. **Immutable models** — Make all fields final
2. **Stricter lint rules** — Enable additional lints
3. **Shared decorations** — Extract InputDecoration builders
4. **Shared SnackBar** — Extract SnackBar helper
5. **Shared save state** — Extract SaveStateMixin
6. **Typed block updates** — Replace Map with BlockUpdate class
7. **PDF rendering cache** — Add per-export cache
8. **Editor memoization** — Cache pagination results
9. **Lazy ListView** — Convert to ListView.builder
10. **Extract ProjectCard** — Move to separate file
11. **Extract FlowSpacingPanel** — Move to separate file
12. **Pagination tests** — Add comprehensive tests
13. **PronunciationService tests** — Add validation tests
14. **Final verification** — Test everything works

Each task is independent and can be implemented in order. The plan follows TDD principles where appropriate and includes frequent commits for easy rollback if needed.
