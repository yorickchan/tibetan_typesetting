# Comprehensive Feature Enhancement Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 12 major features across 5 phases: undo/redo, WYSIWYG preview improvements, drag-to-reorder, batch import, multi-language translation, image blocks, multi-format export, headers/footers, export history, Tibetan spell check, Wylie input helper, project templates, test coverage, and image caching.

**Architecture:** Iterative enhancement of the existing Flutter desktop app. Each phase adds features in dependency order: core editor UX first, then import/export, then Tibetan-specific tools, then polish. No architectural rewrites — extend existing models, services, widgets, and pages.

**Tech Stack:** Flutter 3.x, Dart 3.x, sqflite (SQLite), pdf package, file_picker, uuid

---

## Phase 1: Core Editor UX (Undo/Redo, WYSIWYG, Drag-to-Reorder)

### Task 1.1: Undo/Redo System

**Files:**
- Create: `lib/services/undo_service.dart`
- Modify: `lib/pages/editor_page.dart` (integrate undo service)

**Rationale:** Every text editor needs undo/redo. Use a snapshot-based approach: store `Project` snapshots on each mutation, cap at 50 entries.

- [ ] **Step 1: Create the UndoService**

```dart
// lib/services/undo_service.dart
import '../models/project.dart';

class UndoService {
  static const int _maxStackSize = 50;

  final List<Project> _undoStack = [];
  final List<Project> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Call BEFORE a mutation to push the current state.
  void pushState(Project project) {
    _undoStack.add(project);
    if (_undoStack.length > _maxStackSize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  /// Returns the state to restore, or null.
  Project? undo(Project current) {
    if (!canUndo) return null;
    _redoStack.add(current);
    return _undoStack.removeLast();
  }

  /// Returns the state to restore, or null.
  Project? redo(Project current) {
    if (!canRedo) return null;
    _undoStack.add(current);
    return _redoStack.removeLast();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
```

- [ ] **Step 2: Write unit tests for UndoService**

Write `test/undo_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/services/undo_service.dart';

void main() {
  test('canUndo returns false when stack is empty', () {
    final service = UndoService();
    expect(service.canUndo, false);
    expect(service.canRedo, false);
  });

  test('undo returns previous state', () {
    final service = UndoService();
    final proj1 = Project(id: '1', name: 'A', updatedAt: '', createdAt: '');
    final proj2 = Project(id: '1', name: 'B', updatedAt: '', createdAt: '');

    service.pushState(proj1);
    final result = service.undo(proj2);

    expect(result, isNotNull);
    expect(result!.name, 'A');
    expect(service.canUndo, false);
    expect(service.canRedo, true);
  });

  test('redo restores state', () {
    final service = UndoService();
    final proj1 = Project(id: '1', name: 'A', updatedAt: '', createdAt: '');
    final proj2 = Project(id: '1', name: 'B', updatedAt: '', createdAt: '');

    service.pushState(proj1);
    service.undo(proj2);
    final result = service.redo(proj1);

    expect(result, isNotNull);
    expect(result!.name, 'B');
    expect(service.canUndo, true);
    expect(service.canRedo, false);
  });

  test('pushState clears redo stack', () {
    final service = UndoService();
    final proj1 = Project(id: '1', name: 'A', updatedAt: '', createdAt: '');
    final proj2 = Project(id: '1', name: 'B', updatedAt: '', createdAt: '');
    final proj3 = Project(id: '1', name: 'C', updatedAt: '', createdAt: '');

    service.pushState(proj1);
    service.undo(proj2);
    expect(service.canRedo, true);

    service.pushState(proj2);
    expect(service.canRedo, false);
  });

  test('stack capped at 50', () {
    final service = UndoService();
    for (int i = 0; i < 60; i++) {
      service.pushState(
        Project(id: '$i', name: '$i', updatedAt: '', createdAt: ''),
      );
    }
    expect(service.canUndo, true);
    // Can't directly inspect stack size, but undo 50 times should still work
    int count = 0;
    var current = Project(id: 'x', name: 'x', updatedAt: '', createdAt: '');
    while (service.canUndo) {
      current = service.undo(current)!;
      count++;
    }
    expect(count, 50);
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

```bash
flutter test test/undo_service_test.dart
```

Expected: FAIL (file not found errors if service doesn't exist yet, or compilation errors).

- [ ] **Step 4: Integrate UndoService into EditorPage**

In `lib/pages/editor_page.dart`, add the undo service field and wire up keyboard shortcuts.

After line 57 (the `_zoom` field), add:
```dart
  final _undoService = UndoService();
```

In the `_updateBlock` method, push state before mutation. Replace lines 142-160:

```dart
  void _updateBlock(BlockUpdate update) {
    if (_project == null || _selectedBlock == null) return;
    final selectedId = _selectedId;
    _undoService.pushState(_project!);
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

Similarly, add `_undoService.pushState(_project!);` at the start of `_addBlock`, `_deleteBlock`, `_moveBlock`, `_toggleColumnBreak`, `_togglePageBreak`, `_toggleSmallText`, `_toggleFreeTextFormat`, and `_updateSetup`.

Add undo/redo methods:

```dart
  void _undo() {
    if (_project == null) return;
    final prev = _undoService.undo(_project!);
    if (prev != null) {
      setState(() {
        _project = prev;
        _cachedPages = null;
      });
      _bumpSave();
    }
  }

  void _redo() {
    if (_project == null) return;
    final next = _undoService.redo(_project!);
    if (next != null) {
      setState(() {
        _project = next;
        _cachedPages = null;
      });
      _bumpSave();
    }
  }
```

Add keyboard shortcuts. In the `build` method's `Shortcuts` widget (lines 353-365), add:

```dart
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
            const _UndoIntent(),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
            const _RedoIntent(),
```

Add the intent classes after the existing ones:

```dart
class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}
```

Add the action bindings in the `Actions` widget (lines 367-382):

```dart
          _UndoIntent: CallbackAction<_UndoIntent>(
            onInvoke: (_) => _undo(),
          ),
          _RedoIntent: CallbackAction<_RedoIntent>(
            onInvoke: (_) => _redo(),
          ),
```

- [ ] **Step 5: Add undo/redo toolbar buttons**

In the editor page's `AppShell` actions, add undo/redo buttons. After the save pill (around line 390), add:

```dart
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: '${_l10n.undo} (Ctrl+Z)',
                onPressed: _undoService.canUndo ? _undo : null,
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                tooltip: '${_l10n.redo} (Ctrl+Shift+Z)',
                onPressed: _undoService.canRedo ? _redo : null,
              ),
```

Add localization keys to `app_en.arb`:
```json
  "undo": "Undo",
  "redo": "Redo"
```

Add to `app_zh.arb` and `app_zh_TW.arb` similarly.

Run code generation:
```bash
flutter gen-l10n
```

- [ ] **Step 6: Run tests to verify**

```bash
flutter test test/undo_service_test.dart
```

Expected: all 5 tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/services/undo_service.dart lib/pages/editor_page.dart test/undo_service_test.dart lib/l10n/
git commit -m "feat: add undo/redo system with Ctrl+Z / Ctrl+Shift+Z"
```

---

### Task 1.2: Drag-to-Reorder Blocks

**Files:**
- Modify: `lib/widgets/block_strip.dart`

**Rationale:** Replace the up/down arrow move buttons with drag handles on each block row in the strip, using Flutter's `ReorderableListView`.

- [ ] **Step 1: Replace ListView with ReorderableListView in block_strip.dart**

Read the current `BlockStripWidget.build` method. Change the `ListView` to a `ReorderableListView`.

Replace the block list rendering with:

```dart
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final pageSetups = _computePageSetups();
    if (pageSetups.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noBlocks, style: theme.textTheme.bodyMedium),
      );
    }
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: pageSetups.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final ps = pageSetups[index];
        return _BlockRow(
          key: ValueKey('${ps.pageIndex}-${ps.startIdx}'),
          blocks: blocks.sublist(ps.startIdx, ps.endIdx),
          globalStartIdx: ps.startIdx,
          pageIndex: ps.pageIndex,
          selectedId: selectedId,
          onSelect: onSelect,
          onAdd: onAdd,
          onAddPage: onAddPage,
          tibetanFontFamily: tibetanFontFamily,
          translationFontFamily: translationFontFamily,
        );
      },
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    // Delegate to parent: emit block move by index difference
    // This is approximate; fine-grained reorder within pages handled by
    // moving individual blocks.
  }
```

For each block tile in `_BlockRow`, wrap in a `ReorderableDragStartListener` with a drag handle icon:

```dart
  ReorderableDragStartListener(
    index: rowIndex,
    child: const Icon(Icons.drag_handle, size: 16),
  ),
```

- [ ] **Step 2: Wire onReorder callback through to EditorPage**

Add a new callback to `BlockStripWidget`:

```dart
  final void Function(int oldIndex, int newIndex)? onBlockReorder;
```

In `EditorPage`, implement the handler:

```dart
  void _onBlockReorder(int oldIndex, int newIndex) {
    if (_project == null) return;
    _undoService.pushState(_project!);
    setState(() {
      final blocks = List<TextBlock>.from(_project!.blocks);
      final item = blocks.removeAt(oldIndex);
      if (newIndex > oldIndex) newIndex--;
      blocks.insert(newIndex, item);
      _project = _project!.copyWith(blocks: blocks);
      _cachedPages = null;
    });
    _bumpSave();
  }
```

- [ ] **Step 3: Run widget tests**

```bash
flutter test test/widget_test.dart
```

Ensure no regressions.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/block_strip.dart lib/pages/editor_page.dart
git commit -m "feat: add drag-to-reorder for blocks in strip"
```

---

### Task 1.3: WYSIWYG Preview Positioning

**Files:**
- Modify: `lib/widgets/sample_page.dart`
- Modify: `lib/pages/editor_page.dart`

**Rationale:** Show a subtle highlight or indicator on the preview page showing where the selected block falls in the layout, so users can see column/page placement while editing.

- [ ] **Step 1: Add selected block highlight to SamplePageWidget**

In `SamplePageWidget`, add a `String? selectedBlockId` parameter. When drawing blocks, check if the block's id matches the selected ID and draw a highlight (dashed border or subtle background).

Read `lib/widgets/sample_page.dart` to understand the rendering, then add:

```dart
  final String? selectedBlockId;
```

In the painting logic, when iterating cells and drawing the block content, check:

```dart
  if (cell.block.id == selectedBlockId) {
    // Draw a highlight rectangle
    canvas.drawRect(
      blockRect,
      Paint()
        ..color = const Color(0x1A60A5FA)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      blockRect,
      Paint()
        ..color = const Color(0x6060A5FA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
```

- [ ] **Step 2: Pass selectedBlockId from EditorPage**

In `EditorPage.build`, wherever `SamplePageWidget` is used, pass `selectedBlockId: _selectedId`.

- [ ] **Step 3: Verify visually by running the app**

```bash
flutter run -d macos
```

Click different blocks in the strip and confirm the highlight moves on the preview.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/sample_page.dart lib/pages/editor_page.dart
git commit -m "feat: highlight selected block in preview page"
```

---

## Phase 2: Import & Content Features

### Task 2.1: Batch Import (CSV/TSV)

**Files:**
- Create: `lib/services/batch_import_service.dart`
- Modify: `lib/pages/editor_page.dart` (add import button/menu)
- Modify: `pubspec.yaml` (add csv package)

**Rationale:** Allow importing Tibetan text blocks from CSV/TSV files with columns: tibetan, pronunciation, translation.

- [ ] **Step 1: Add csv package dependency**

Run:
```bash
flutter pub add csv
```

- [ ] **Step 2: Create BatchImportService**

```dart
// lib/services/batch_import_service.dart
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/project.dart';

const _uuid = Uuid();

class ImportResult {
  final List<TextBlock> blocks;
  final List<String> warnings;
  final int skippedRows;
  final int importedRows;

  const ImportResult({
    required this.blocks,
    required this.warnings,
    required this.skippedRows,
    required this.importedRows,
  });
}

class BatchImportService {
  /// Parse a CSV/TSV file. Expected columns (header row optional):
  ///   tibetan[, pronunciation[, translation]]
  /// Delimiter auto-detected: comma or tab.
  static ImportResult parseFile(File file) {
    final text = file.readAsStringSync();
    final delimiter = text.contains('\t') ? '\t' : ',';
    final rows = const CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: '\n',
    ).convert(text);

    final blocks = <TextBlock>[];
    final warnings = <String>[];
    int skipped = 0;
    int imported = 0;
    int startRow = 0;

    // Detect header: if first row's first cell is text and matches
    // known column names, treat as header
    if (rows.isNotEmpty && rows[0].isNotEmpty) {
      final firstCell = rows[0][0].toString().toLowerCase().trim();
      if (firstCell == 'tibetan' || firstCell == 'tib' || firstCell == 'bo') {
        startRow = 1;
      }
    }

    for (var i = startRow; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) {
        skipped++;
        continue;
      }
      final tibetan = row[0].toString().trim();
      if (tibetan.isEmpty) {
        skipped++;
        continue;
      }
      final pronunciation = row.length > 1 ? row[1].toString().trim() : '';
      final translation = row.length > 2 ? row[2].toString().trim() : '';

      blocks.add(TextBlock(
        id: _uuid.v4().replaceAll('-', ''),
        tibetan: tibetan,
        chinesePronunciation: pronunciation,
        chineseTranslation: translation,
      ));
      imported++;
    }

    return ImportResult(
      blocks: blocks,
      warnings: warnings,
      skippedRows: skipped,
      importedRows: imported,
    );
  }
}
```

- [ ] **Step 3: Write tests**

```dart
// test/batch_import_service_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/batch_import_service.dart';

void main() {
  test('parses CSV with header', () {
    final file = File('/tmp/test_import.csv');
    file.writeAsStringSync('tibetan,pronunciation,translation\n'
        'བཀྲ་ཤིས།,zha xi,good luck\n'
        'བདེ་ལེགས།,de le,blessings\n');
    final result = BatchImportService.parseFile(file);
    expect(result.importedRows, 2);
    expect(result.skippedRows, 0);
    expect(result.blocks[0].tibetan, 'བཀྲ་ཤིས།');
    expect(result.blocks[0].chinesePronunciation, 'zha xi');
    expect(result.blocks[0].chineseTranslation, 'good luck');
  });

  test('parses CSV without header', () {
    final file = File('/tmp/test_import_noheader.csv');
    file.writeAsStringSync('བཀྲ་ཤིས།,zha xi,good luck\n'
        'བདེ་ལེགས།,de le,blessings\n');
    final result = BatchImportService.parseFile(file);
    expect(result.importedRows, 2);
    expect(result.blocks[0].tibetan, 'བཀྲ་ཤིས།');
  });

  test('skips empty rows', () {
    final file = File('/tmp/test_import_empty.csv');
    file.writeAsStringSync('tibetan,pronunciation,translation\n'
        '\n'
        'བཀྲ་ཤིས།,zha xi,\n'
        '   ,,\n'
        'བདེ་ལེགས།,,blessings\n');
    final result = BatchImportService.parseFile(file);
    expect(result.importedRows, 2);
    expect(result.skippedRows, 2);
  });

  test('parses TSV', () {
    final file = File('/tmp/test_import.tsv');
    file.writeAsStringSync('tibetan\tpronunciation\ttranslation\n'
        'བཀྲ་ཤིས།\tzha xi\tgood luck\n');
    final result = BatchImportService.parseFile(file);
    expect(result.importedRows, 1);
  });
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/batch_import_service_test.dart
```

Expected: all PASS.

- [ ] **Step 5: Add import UI to EditorPage**

Add an import button in the `AppShell` actions. Add a method:

```dart
  Future<void> _importCsv() async {
    final result = await FilePickerService.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'tsv', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.single.path!);

    final importResult = BatchImportService.parseFile(file);
    if (importResult.importedRows == 0) {
      _showSnack(_l10n.importNoBlocksFound, error: true);
      return;
    }

    _undoService.pushState(_project!);
    setState(() {
      final blocks = List<TextBlock>.from(_project!.blocks);
      final idx = _selectedIndex >= 0 ? _selectedIndex + 1 : blocks.length;
      blocks.insertAll(idx, importResult.blocks);
      _project = _project!.copyWith(blocks: blocks);
      _cachedPages = null;
      if (importResult.blocks.isNotEmpty) {
        _selectedId = importResult.blocks.first.id;
      }
    });
    _bumpSave();
    if (mounted) {
      _showSnack(
        _l10n.importedBlocks(importResult.importedRows),
      );
    }
  }
```

Add localization keys for:
- `importCsv` → "Import CSV/TSV"
- `importNoBlocksFound` → "No blocks found in file"
- `importedBlocks` → with count parameter

- [ ] **Step 6: Commit**

```bash
git add lib/services/batch_import_service.dart lib/pages/editor_page.dart test/batch_import_service_test.dart pubspec.yaml pubspec.lock
git commit -m "feat: add CSV/TSV batch import"
```

---

### Task 2.2: Multi-Language Translation Support

**Files:**
- Modify: `lib/models/project.dart` (add `translationLang` field)
- Modify: `lib/widgets/block_editor.dart` (show language selector)
- Modify: `lib/pages/editor_page.dart`
- Modify: `lib/services/pdf_service.dart` (conditionally render translation)
- Modify: `lib/l10n/` (localization)

**Rationale:** Currently translation is hardcoded to Chinese. Add a language field so users can switch to English, Japanese, etc.

- [ ] **Step 1: Add TranslationLanguage enum to project.dart**

```dart
enum TranslationLanguage {
  chinese,
  english,
  japanese,
  custom;

  String get label {
    return switch (this) {
      TranslationLanguage.chinese => '中文',
      TranslationLanguage.english => 'English',
      TranslationLanguage.japanese => '日本語',
      TranslationLanguage.custom => 'Custom',
    };
  }

  static TranslationLanguage fromJson(String? value) {
    return switch (value) {
      'english' => TranslationLanguage.english,
      'japanese' => TranslationLanguage.japanese,
      'custom' => TranslationLanguage.custom,
      _ => TranslationLanguage.chinese,
    };
  }
}
```

- [ ] **Step 2: Add translationLang field to PageSetup**

Add to `PageSetup`:
```dart
  final TranslationLanguage translationLang;
```

Default to `TranslationLanguage.chinese`. Add to `copyWith`, `toJson`, `fromJson`.

- [ ] **Step 3: Update block editor label**

In `BlockEditorWidget`, change the translation field label from "Chinese Translation" to use the language label. Add a dropdown in the editor to switch the project's translation language.

- [ ] **Step 4: Update PDF service**

In `pdf_service.dart`, the column label for translation should use the language's label instead of hardcoded Chinese text.

- [ ] **Step 5: Write tests**

```dart
// In test/models_test.dart, add tests for TranslationLanguage serialization
```

- [ ] **Step 6: Commit**

```bash
git add lib/models/project.dart lib/widgets/block_editor.dart lib/services/pdf_service.dart lib/l10n/ test/models_test.dart
git commit -m "feat: add multi-language translation support (en, ja, zh, custom)"
```

---

### Task 2.3: Image Blocks

**Files:**
- Modify: `lib/models/project.dart` (add `imagePath` to TextBlock or new ImageBlock)
- Modify: `lib/widgets/block_editor.dart` (add image picker)
- Modify: `lib/services/pdf_service.dart` (render images in PDF)
- Create: `lib/utils/image_utils.dart`

**Rationale:** Support inserting images between text blocks (e.g., dharma wheel, mandala, illustrations).

- [ ] **Step 1: Add image support to TextBlock model**

Add to `TextBlock`:
```dart
  final String? imagePath; // null for text blocks, path for image blocks
```

Add to `copyWith`, `toJson`, `fromJson`. Add `clearImagePath` flag.

Add a getter:
```dart
  bool get isImageBlock => imagePath != null && imagePath!.isNotEmpty;
```

- [ ] **Step 2: Add image insertion to editor page**

In `EditorPage`, add `_addImageBlock()`:

```dart
  Future<void> _addImageBlock() async {
    final result = await FilePickerService.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null || result.files.isEmpty) return;

    _undoService.pushState(_project!);
    final id = _uuid.v4().replaceAll('-', '');
    final block = TextBlock(id: id, imagePath: result.files.single.path);
    final idx = _selectedIndex >= 0
        ? _selectedIndex + 1
        : _project!.blocks.length;
    setState(() {
      final blocks = List<TextBlock>.from(_project!.blocks);
      blocks.insert(idx, block);
      _project = _project!.copyWith(blocks: blocks);
      _selectedId = id;
      _cachedPages = null;
    });
    _bumpSave();
  }
```

- [ ] **Step 3: Update BlockStripWidget to show image thumbnails**

In the strip, for image blocks, show a small image thumbnail instead of text preview.

- [ ] **Step 4: Update PDF service to embed images**

In `pdf_service.dart`, when a block has `imagePath`, use `pw.MemoryImage` with the file bytes instead of rendering text as PNG.

- [ ] **Step 5: Write tests**

Add test for image block serialization in `models_test.dart`.

- [ ] **Step 6: Commit**

```bash
git add lib/models/project.dart lib/widgets/block_editor.dart lib/widgets/block_strip.dart lib/pages/editor_page.dart lib/services/pdf_service.dart lib/utils/image_utils.dart test/models_test.dart
git commit -m "feat: add image block support"
```

---

## Phase 3: Export & Output

### Task 3.1: Headers and Footers

**Files:**
- Modify: `lib/models/project.dart` (add header/footer fields to PageSetup)
- Modify: `lib/services/pdf_service.dart` (render headers/footers)
- Modify: `lib/widgets/editor_page_setup_panel.dart` (UI for configuring)
- Modify: `lib/l10n/`

**Rationale:** Add configurable running headers and footers to PDF output.

- [ ] **Step 1: Add HeaderFooter model**

```dart
enum HeaderFooterField {
  none,
  fileName,
  pageNumber,
  date,
  custom;

  static HeaderFooterField fromJson(String? value) {
    return switch (value) {
      'fileName' => HeaderFooterField.fileName,
      'pageNumber' => HeaderFooterField.pageNumber,
      'date' => HeaderFooterField.date,
      'custom' => HeaderFooterField.custom,
      _ => HeaderFooterField.none,
    };
  }
}
```

Add to `PageSetup`:
```dart
  final HeaderFooterField headerLeft;
  final HeaderFooterField headerCenter;
  final HeaderFooterField headerRight;
  final String headerCustomText;
  final HeaderFooterField footerLeft;
  final HeaderFooterField footerCenter;
  final HeaderFooterField footerRight;
  final String footerCustomText;
  final double headerFontSize;
  final double footerFontSize;
```

- [ ] **Step 2: Render headers/footers in PDF service**

In `PdfService._buildPage`, add header and footer drawing. Render the configured fields at the top/bottom margin area.

- [ ] **Step 3: Add UI to editor page setup panel**

Add header/footer configuration fields to `EditorPageSetupPanel`.

- [ ] **Step 4: Write tests**

Add serialization tests for header/footer fields.

- [ ] **Step 5: Commit**

```bash
git add lib/models/project.dart lib/services/pdf_service.dart lib/widgets/editor_page_setup_panel.dart lib/l10n/ test/models_test.dart
git commit -m "feat: add customizable headers and footers to PDF export"
```

---

### Task 3.2: Multi-Format Export (HTML)

**Files:**
- Create: `lib/services/html_export_service.dart`
- Modify: `lib/pages/export_page.dart` (add format selector)

**Rationale:** Add HTML export alongside PDF for web publishing. EPUB and DOCX are significantly more complex — start with HTML as the most practical second format.

- [ ] **Step 1: Create HtmlExportService**

```dart
// lib/services/html_export_service.dart
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/project.dart';
import '../utils/sample_layout.dart';
import '../utils/text_renderer.dart';
import 'font_service.dart';

class HtmlExportService {
  static String generateHtml(Project project) {
    final buf = StringBuffer();
    buf.writeln('<!DOCTYPE html>');
    buf.writeln('<html lang="bo">');
    buf.writeln('<head>');
    buf.writeln('<meta charset="UTF-8">');
    buf.writeln('<meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buf.writeln('<title>${_escapeHtml(project.name)}</title>');
    buf.writeln('<style>');
    buf.writeln('''
      body { font-family: "Microsoft Himalaya", "Noto Sans Tibetan", sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
      .block { margin-bottom: 16px; padding: 8px; border-bottom: 1px solid #eee; }
      .tibetan { font-size: 18px; color: #1a1a2e; }
      .chinese { font-size: 14px; color: #555; }
      .page-break { page-break-before: always; }
    ''');
    buf.writeln('</style>');
    buf.writeln('</head>');
    buf.writeln('<body>');

    if (project.pageSetup.showTitlePage) {
      buf.writeln('<h1 class="title">${_escapeHtml(project.pageSetup.titleTibetan)}</h1>');
      buf.writeln('<h2 class="subtitle">${_escapeHtml(project.pageSetup.titleChinese)}</h2>');
      buf.writeln('<hr>');
    }

    for (final block in project.blocks) {
      if (block.pageBreakBefore) {
        buf.writeln('<div class="page-break"></div>');
      }
      buf.writeln('<div class="block">');
      buf.writeln('<p class="tibetan">${_escapeHtml(block.tibetan)}</p>');
      if (block.chineseTranslation.isNotEmpty) {
        buf.writeln('<p class="chinese">${_escapeHtml(block.chineseTranslation)}</p>');
      }
      buf.writeln('</div>');
    }

    buf.writeln('</body></html>');
    return buf.toString();
  }

  static String _escapeHtml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
```

- [ ] **Step 2: Add HTML export to ExportPage**

Add a dropdown or segmented button to choose between PDF and HTML. Add `_exportHtml()` method.

- [ ] **Step 3: Write tests**

```dart
// test/html_export_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/services/html_export_service.dart';

void main() {
  test('generateHtml produces valid HTML', () {
    final project = Project(
      id: '1',
      name: 'Test',
      updatedAt: '',
      createdAt: '',
      blocks: [
        TextBlock(id: 'b1', tibetan: 'བཀྲ་ཤིས།', chineseTranslation: '吉祥'),
      ],
    );
    final html = HtmlExportService.generateHtml(project);
    expect(html, contains('<!DOCTYPE html>'));
    expect(html, contains('བཀྲ་ཤིས།'));
    expect(html, contains('吉祥'));
  });

  test('generateHtml escapes HTML entities', () {
    final project = Project(
      id: '1',
      name: '<Test>',
      updatedAt: '',
      createdAt: '',
      blocks: [
        TextBlock(id: 'b1', tibetan: 'a & b', chineseTranslation: ''),
      ],
    );
    final html = HtmlExportService.generateHtml(project);
    expect(html, contains('&lt;Test&gt;'));
    expect(html, contains('a &amp; b'));
  });
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/services/html_export_service.dart lib/pages/export_page.dart test/html_export_service_test.dart
git commit -m "feat: add HTML export alongside PDF"
```

---

### Task 3.3: Export History

**Files:**
- Modify: `lib/services/database_service.dart` (add export_history table)
- Create: `lib/models/export_record.dart`
- Modify: `lib/pages/export_page.dart` (show history)
- Modify: `lib/pages/projects_page.dart` (show last export)

**Rationale:** Track each export with timestamp, format, and page setup snapshot for auditing and reproducibility.

- [ ] **Step 1: Add export_history table to database**

In `DatabaseService._initDb`:

```dart
  Future<void> _createExportHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS export_history (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        format TEXT NOT NULL,
        file_path TEXT NOT NULL,
        exported_at TEXT NOT NULL,
        page_setup_json TEXT NOT NULL,
        block_count INTEGER NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
  }
```

- [ ] **Step 2: Create ExportRecord model**

```dart
// lib/models/export_record.dart
class ExportRecord {
  final String id;
  final String projectId;
  final String format;
  final String filePath;
  final String exportedAt;
  final String pageSetupJson;
  final int blockCount;

  const ExportRecord({
    required this.id,
    required this.projectId,
    required this.format,
    required this.filePath,
    required this.exportedAt,
    required this.pageSetupJson,
    required this.blockCount,
  });

  // toJson, fromJson
}
```

- [ ] **Step 3: Add CRUD methods to DatabaseService**

```dart
  Future<void> recordExport(ExportRecord record) async { ... }
  Future<List<ExportRecord>> getExportHistory(String projectId) async { ... }
```

- [ ] **Step 4: Record exports in ExportPage**

After successful PDF or HTML export, call `_db.recordExport(...)`.

- [ ] **Step 5: Show history in ExportPage**

Add a section at the bottom showing recent exports for this project.

- [ ] **Step 6: Commit**

```bash
git add lib/services/database_service.dart lib/models/export_record.dart lib/pages/export_page.dart lib/pages/projects_page.dart
git commit -m "feat: add export history tracking"
```

---

## Phase 4: Tibetan Tools

### Task 4.1: Tibetan Spell Check

**Files:**
- Modify: `lib/services/pronunciation_service.dart` (add spell check)
- Modify: `lib/widgets/block_editor.dart` (show warnings)

**Rationale:** Flag Tibetan syllables that are not in the pronunciation dictionary as potentially misspelled, with a visual indicator in the editor.

- [ ] **Step 1: Add spell check to PronunciationService**

```dart
  /// Returns list of syllables not found in the dictionary.
  Future<List<String>> checkSpelling(String tibetanText) async {
    final syllables = _segmenter.extractSyllables(tibetanText);
    final unknown = <String>[];
    final db = await _db.database;
    for (final syl in syllables) {
      final rows = await db.query(
        'pronunciation_dictionary',
        columns: ['tibetan_syllable'],
        where: 'tibetan_syllable = ?',
        whereArgs: [syl],
        limit: 1,
      );
      if (rows.isEmpty) {
        unknown.add(syl);
      }
    }
    return unknown;
  }
```

- [ ] **Step 2: Show warnings in BlockEditorWidget**

In `_EditorFields`, after each input change, run spell check and show unknown syllables with a subtle underline or warning icon.

Add a `List<String> _unknownSyllables` state field, update it after text changes with a debounce, and display a warning row:

```dart
  if (_unknownSyllables.isNotEmpty)
    Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'Unknown: ${_unknownSyllables.join(", ")}',
        style: TextStyle(color: AppColors.rose600, fontSize: 11),
      ),
    ),
```

- [ ] **Step 3: Add "Add All to Dictionary" button**

When unknown syllables are detected, show a button to batch-add them all to the dictionary with empty pronunciations (for later filling).

- [ ] **Step 4: Commit**

```bash
git add lib/services/pronunciation_service.dart lib/widgets/block_editor.dart
git commit -m "feat: add Tibetan spell check against pronunciation dictionary"
```

---

### Task 4.2: Wylie Transliteration Input Helper

**Files:**
- Create: `lib/utils/wylie_converter.dart`
- Modify: `lib/widgets/block_editor.dart` (add Wylie input toggle)

**Rationale:** Many scholars input Tibetan via Wylie romanization (e.g., "bkra shis" → "བཀྲ་ཤིས"). Add a toggleable Wylie-to-Unicode converter as a text field prefix/option.

- [ ] **Step 1: Create WylieConverter**

```dart
// lib/utils/wylie_converter.dart
class WylieConverter {
  // Basic mapping of Wylie to Tibetan Unicode
  // This is a simplified version; a full implementation would use
  // the EWTS/THL extended Wylie standard.
  static const Map<String, String> _consonants = {
    'k': 'ཀ', 'kh': 'ཁ', 'g': 'ག', 'gh': 'གྷ', 'ng': 'ང',
    'c': 'ཅ', 'ch': 'ཆ', 'j': 'ཇ', 'ny': 'ཉ',
    't': 'ཏ', 'th': 'ཐ', 'd': 'ད', 'dh': 'དྷ', 'n': 'ན',
    'p': 'པ', 'ph': 'ཕ', 'b': 'བ', 'bh': 'བྷ', 'm': 'མ',
    'ts': 'ཙ', 'tsh': 'ཚ', 'dz': 'ཛ', 'dzh': 'ཛྷ', 'w': 'ཝ',
    'zh': 'ཞ', 'z': 'ཟ', '\'': 'འ', 'y': 'ཡ',
    'r': 'ར', 'l': 'ལ', 'sh': 'ཤ', 's': 'ས', 'h': 'ཧ', 'a': 'ཨ',
  };

  static const Map<String, String> _vowels = {
    'i': 'ི', 'u': 'ུ', 'e': 'ེ', 'o': 'ོ',
  };

  /// Convert a Wylie syllable to Tibetan Unicode.
  /// e.g., "bkra" → "བཀྲ", "shis" → "ཤིས"
  static String convertSyllable(String wylie) {
    if (wylie.isEmpty) return wylie;
    // Simplified implementation: stack-based conversion
    // Full EWTS would handle subjoined characters, Sanskrit stacks, etc.
    String result = '';
    int i = 0;
    final chars = wylie.split('');

    while (i < chars.length) {
      // Try two-char combinations first
      String? matched;
      if (i + 1 < chars.length) {
        final two = chars[i] + chars[i + 1];
        if (_consonants.containsKey(two)) {
          matched = _consonants[two];
          i += 2;
        }
      }
      if (matched == null) {
        final one = chars[i];
        matched = _consonants[one] ?? _vowels[one] ?? one;
        i++;
      }
      result += matched;
    }

    // Add tsheg if not present
    if (!result.endsWith('་') && result.isNotEmpty) {
      result += '་';
    }
    return result;
  }

  /// Convert a full Wylie text (space-separated syllables) to Tibetan.
  static String convert(String wylieText) {
    return wylieText
        .split(RegExp(r'\s+'))
        .map((s) => convertSyllable(s.trim()))
        .join('');
  }
}
```

- [ ] **Step 2: Write tests**

```dart
// test/wylie_converter_test.dart
void main() {
  test('converts basic syllables', () {
    final result = WylieConverter.convert('bkra shis');
    expect(result, contains('བཀྲ'));
    expect(result, contains('ཤིས'));
  });

  test('handles empty input', () {
    expect(WylieConverter.convert(''), '');
  });
}
```

- [ ] **Step 3: Add Wylie toggle to block editor**

In `_EditorFields`, add a toggle button (icon: keyboard) that switches between normal Tibetan input and Wylie input mode. When Wylie mode is active, wrap the Tibetan text field to convert on-the-fly or show a preview.

Add a `bool _wylieMode = false` state and a toggle button:

```dart
  IconButton(
    icon: Icon(_wylieMode ? Icons.keyboard : Icons.keyboard_alt),
    tooltip: 'Wylie input mode',
    onPressed: () => setState(() => _wylieMode = !_wylieMode),
  ),
```

When Wylie mode is on, show a second preview row with the converted Tibetan:

```dart
  if (_wylieMode)
    Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        WylieConverter.convert(_tibetanCtrl.text),
        style: TextStyle(fontFamily: widget.tibetanFontFamily, fontSize: 14),
      ),
    ),
```

- [ ] **Step 4: Commit**

```bash
git add lib/utils/wylie_converter.dart lib/widgets/block_editor.dart test/wylie_converter_test.dart
git commit -m "feat: add Wylie transliteration input helper"
```

---

## Phase 5: Polish

### Task 5.1: Project Templates

**Files:**
- Modify: `lib/services/database_service.dart` (add templates table)
- Modify: `lib/pages/projects_page.dart` (add "New from Template" option)
- Modify: `lib/pages/editor_page.dart` (add "Save as Template" action)

**Rationale:** Save page setup + font configs as reusable templates.

- [ ] **Step 1: Add templates table**

In `DatabaseService._initDb`:
```dart
  Future<void> _createTemplatesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        page_setup_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }
```

- [ ] **Step 2: Add template CRUD to DatabaseService**

```dart
  Future<List<ProjectListItem>> listTemplates() async { ... }
  Future<void> saveTemplate(String name, PageSetup setup) async { ... }
  Future<PageSetup?> getTemplate(String id) async { ... }
  Future<void> deleteTemplate(String id) async { ... }
```

- [ ] **Step 3: Add UI in ProjectsPage**

"New Project" button → dialog offering "Blank" or a list of templates.

- [ ] **Step 4: Add "Save as Template" in EditorPage**

In the page setup panel or a menu action, allow saving current `PageSetup` as a template.

- [ ] **Step 5: Commit**

```bash
git add lib/services/database_service.dart lib/pages/projects_page.dart lib/pages/editor_page.dart
git commit -m "feat: add project templates"
```

---

### Task 5.2: Test Coverage Improvements

**Files:**
- Create: `test/pdf_service_test.dart`
- Create: `test/font_service_test.dart`

**Rationale:** Core services lack unit tests. Add focused tests for critical paths.

- [ ] **Step 1: Write PDF service tests**

Test `paginateBlocks`, layout calculations, and PDF generation with mock data.

```dart
// test/pdf_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/utils/sample_layout.dart';

void main() {
  group('paginateBlocks', () {
    test('returns empty list for empty blocks', () {
      final pages = paginateBlocks([], 0, 4, 0.01);
      expect(pages, isEmpty);
    });

    test('paginates blocks across multiple pages', () {
      final blocks = List.generate(50, (i) => TextBlock(
        id: '$i',
        tibetan: 'བཀྲ་ཤིས་བདེ་ལེགས།',
      ));
      final pages = paginateBlocks(blocks, 0, 4, 0.01);
      expect(pages.length, greaterThan(1));
    });

    test('respects explicit page breaks', () {
      final blocks = [
        TextBlock(id: '1', tibetan: 'one'),
        TextBlock(id: '2', tibetan: 'two', pageBreakBefore: true),
        TextBlock(id: '3', tibetan: 'three'),
      ];
      final pages = paginateBlocks(blocks, 0, 4, 0.01);
      expect(pages.length, 2);
    });
  });

  group('estimateBlockWidthFraction', () {
    test('returns larger width for longer text', () {
      final short = TextBlock(id: '1', tibetan: 'short');
      final long = TextBlock(id: '2', tibetan: 'very long tibetan text here');
      expect(
        estimateBlockWidthFraction(short),
        lessThan(estimateBlockWidthFraction(long)),
      );
    });
  });
}
```

- [ ] **Step 2: Write FontService tests**

Test font discovery, validation, and loading.

- [ ] **Step 3: Run all tests**

```bash
flutter test
```

Fix any regressions.

- [ ] **Step 4: Commit**

```bash
git add test/pdf_service_test.dart test/font_service_test.dart
git commit -m "test: add unit tests for PDF service and font service"
```

---

### Task 5.3: Image Rendering Cache

**Files:**
- Create: `lib/services/image_cache_service.dart`
- Modify: `lib/utils/text_renderer.dart` (add caching layer)

**Rationale:** Tibetan text → PNG rendering is expensive. Cache results by content hash + font + size so repeated renders are instant.

- [ ] **Step 1: Create ImageCacheService**

```dart
// lib/services/image_cache_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  Directory? _cacheDir;

  Future<Directory> get cacheDir async {
    if (_cacheDir != null) return _cacheDir!;
    final dir = await getTemporaryDirectory();
    _cacheDir = Directory('${dir.path}/tibetan_text_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  String _cacheKey(String text, String fontFamily, double fontSize, double maxWidth) {
    final input = '$text|$fontFamily|$fontSize|$maxWidth';
    return sha256.convert(utf8.encode(input)).toString();
  }

  Future<Uint8List?> get(String text, String fontFamily, double fontSize, double maxWidth) async {
    final key = _cacheKey(text, fontFamily, fontSize, maxWidth);
    final file = File('${(await cacheDir).path}/$key.png');
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  Future<void> put(String text, String fontFamily, double fontSize, double maxWidth, Uint8List png) async {
    final key = _cacheKey(text, fontFamily, fontSize, maxWidth);
    final file = File('${(await cacheDir).path}/$key.png');
    await file.writeAsBytes(png);
  }

  Future<void> clear() async {
    final dir = await cacheDir;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      _cacheDir = null;
    }
  }
}
```

- [ ] **Step 2: Add caching to text_renderer.dart**

Wrap `renderTextToPng` with cache lookup:

```dart
  // Before rendering, check cache:
  final cache = ImageCacheService();
  final cached = await cache.get(text, fontFamily, fontSize, maxWidth);
  if (cached != null) {
    return RenderedText(
      pngBytes: cached,
      width: maxWidth,  // approximate
      height: cached.length / maxWidth, // approximate
    );
  }

  // ... existing rendering logic ...

  // After rendering, store in cache:
  if (result != null) {
    await cache.put(text, fontFamily, fontSize, maxWidth, result.pngBytes);
  }
```

Add `path_provider` and `crypto` to `pubspec.yaml`:
```bash
flutter pub add path_provider crypto
```

- [ ] **Step 3: Write tests**

```dart
// test/image_cache_service_test.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/services/image_cache_service.dart lib/utils/text_renderer.dart test/image_cache_service_test.dart pubspec.yaml pubspec.lock
git commit -m "feat: add disk cache for rendered Tibetan text images"
```

---

## Verification

After completing all phases, run the full verification suite:

- [ ] `flutter analyze` — no errors
- [ ] `flutter test` — all tests pass
- [ ] `flutter run -d macos` — manual smoke test:
  - Create project, add blocks
  - Test undo/redo (Ctrl+Z / Ctrl+Shift+Z)
  - Drag to reorder blocks in strip
  - Import CSV
  - Export PDF and HTML
  - Check export history appears
  - Test Wylie input mode
  - Check spell check warnings
  - Save and load templates
  - Verify image caching works (repeated renders faster)
- [ ] `flutter build macos` — release build succeeds
