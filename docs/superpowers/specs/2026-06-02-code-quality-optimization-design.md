# Code Quality & Performance Optimization Design

**Date**: 2026-06-02  
**Approach**: A (Focused Cleanup)  
**Scope**: Conservative improvements without architectural changes

## Executive Summary

This design addresses extensibility pain points and performance issues in the Tibetan Typesetting Flutter application through focused, low-risk improvements. The goal is to make the codebase easier to extend while improving runtime performance, without disrupting the working application.

## Goals

1. **Improve extensibility** — Make the code easier to modify and extend
2. **Fix performance bottlenecks** — Reduce UI jank and speed up PDF export
3. **Eliminate duplication** — Extract shared patterns to reduce maintenance burden
4. **Strengthen type safety** — Catch errors at compile time instead of runtime
5. **Add test coverage** — Protect against regressions in critical paths

## Non-Goals

- Introduce new state management (Riverpod, Bloc, etc.)
- Restructure the application architecture
- Add dependency injection framework
- Rewrite existing features
- Change the public API or user-facing behavior

## Design Sections

### 1. Immutable Models

**Problem**: Models (`Project`, `TextBlock`, `PageSetup`, `MarginMm`) have mutable fields despite having `copyWith` methods. This allows silent mutation bugs where code modifies objects without going through the intended immutable update pattern.

**Solution**: Make all model fields `final`.

**Changes**:
- `lib/models/project.dart`:
  - `MarginMm`: All fields become `final`
  - `PageSetup`: All fields become `final`
  - `TextBlock`: All fields become `final`
  - `Project`: All fields become `final`

**Impact**: 
- Prevents an entire class of state mutation bugs
- Forces all updates through `copyWith`, making state changes explicit
- No API changes — `copyWith` already exists and works correctly
- Mechanical change with low risk

**Example**:
```dart
// Before
class TextBlock {
  String id;
  String tibetan;
  // ...
}

// After
class TextBlock {
  final String id;
  final String tibetan;
  // ...
}
```

### 2. Typed Block Updates

**Problem**: `_updateBlock` in `editor_page.dart` uses `Map<String, dynamic>` with string keys. Typos in keys cause silent failures. The API is not self-documenting.

**Solution**: Create a typed `BlockUpdate` class.

**Changes**:
- Create `lib/models/block_update.dart`:
```dart
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

- Update `editor_page.dart`:
  - Change `_updateBlock(Map<String, dynamic> patch)` to `_updateBlock(BlockUpdate update)`
  - Update implementation to use typed fields instead of map lookups

- Update `block_editor.dart`:
  - Change `onUpdateBlock` callback signature from `ValueChanged<Map<String, dynamic>>` to `ValueChanged<BlockUpdate>`
  - Update all call sites to construct `BlockUpdate` objects

**Impact**:
- Compile-time type checking prevents typos
- Self-documenting API — IDE autocomplete shows available fields
- Easier to extend with new block properties
- Slight API change but contained to editor widgets

### 3. Shared Utilities

**Problem**: Duplicated patterns across multiple files:
- InputDecoration builders (`_fieldDecoration`, `_numberDecor`, inline decorations)
- SnackBar helpers (`_showSnackMsg`, `_showSnack`)
- Save-state logic (idle/saving/saved/error pattern)

**Solution**: Extract shared utilities.

**Changes**:

#### 3a. Shared Decorations
Create `lib/utils/decorations.dart`:
```dart
InputDecoration fieldDecoration({
  required String label,
  required String placeholder,
  AppLocalizations? l10n,
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

Update `block_editor.dart`, `export_page.dart`, `projects_page.dart` to use these.

#### 3b. Shared SnackBar
Create `lib/utils/snackbar.dart`:
```dart
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

Update `projects_page.dart`, `export_page.dart` to use this.

#### 3c. Shared Save State
Create `lib/utils/save_state_mixin.dart`:
```dart
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveState = 'error');
    }
  }
}
```

Update `editor_page.dart`, `export_page.dart` to use this mixin.

**Impact**:
- Reduces code duplication by ~150 lines
- Single source of truth for common patterns
- Easier to maintain and update styling consistently

### 4. PDF Rendering Cache

**Problem**: `renderTextToPng()` is called for every text block on every PDF generation, even when the text hasn't changed. This is expensive (text layout + rasterization).

**Solution**: Add a simple in-memory cache in `PdfService` keyed by text content and rendering parameters.

**Changes**:
- `lib/services/pdf_service.dart`:
  - Add cache: `final Map<String, _Img> _renderCache = {};`
  - Generate cache key: `String _cacheKey(String text, String font, double size, Color color, double maxWidth)`
  - Check cache before rendering: `if (_renderCache.containsKey(key)) return _renderCache[key];`
  - Store result after rendering: `_renderCache[key] = img;`
  - Clear cache at start of each `generatePdfWithWarnings` call (not persistent across exports)

**Impact**:
- Significant speedup for PDF export when blocks have identical or similar text
- Cache is per-export, so no memory leak or stale data issues
- Simple implementation with low risk

**Example**:
```dart
Future<_Img?> _render(
  String text,
  double fontSize,
  Color color,
  double maxWidth, {
  required String fontFamily,
  // ...
}) async {
  if (text.trim().isEmpty) return null;
  
  final key = '${text.hashCode}_$fontFamily_$fontSize_${color.value}_$maxWidth';
  if (_renderCache.containsKey(key)) {
    return _renderCache[key];
  }
  
  final r = await renderTextToPng(/* ... */);
  if (r == null) return null;
  
  final img = _Img(pw.MemoryImage(r.pngBytes), r.width, r.height);
  _renderCache[key] = img;
  return img;
}
```

### 5. Editor Performance

**Problem**: 
- `_pagesWithBlocks` getter recomputes pagination on every rebuild
- `ListView` in editor builds all children eagerly, causing jank with many pages

**Solution**:
- Memoize pagination result
- Switch to lazy `ListView.builder`

**Changes**:

#### 5a. Memoize Pagination
- `lib/pages/editor_page.dart`:
  - Add field: `List<_PageWithBlocks>? _cachedPages;`
  - Add field: `List<TextBlock>? _lastBlocks;`
  - Update `_pagesWithBlocks` getter:
```dart
List<_PageWithBlocks> get _pagesWithBlocks {
  if (_project == null) return [];
  
  // Return cached result if blocks haven't changed
  if (_cachedPages != null && 
      identical(_project!.blocks, _lastBlocks)) {
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

#### 5b. Lazy ListView
- `lib/pages/editor_page.dart`:
  - Change `ListView(children: [...])` to `ListView.builder`
  - Compute total item count (title panel + font panel + spacing panel + pages)
  - Build items on demand in `itemBuilder`

**Impact**:
- Eliminates redundant pagination computation
- Reduces initial build time for projects with many pages
- Smoother scrolling in editor

### 6. Extract Large Widgets

**Problem**: 
- `_ProjectCard` (197 lines) lives inside `projects_page.dart`, making the file harder to navigate
- `_FlowSpacingPanel` is duplicated in editor and export pages

**Solution**: Extract to separate files.

**Changes**:

#### 6a. Extract ProjectCard
- Create `lib/widgets/project_card.dart`:
  - Move `_ProjectCard` class from `projects_page.dart`
  - Make it public: `class ProjectCard extends StatelessWidget`
  - Update `projects_page.dart` to import and use `ProjectCard`

#### 6b. Extract FlowSpacingPanel
- Create `lib/widgets/flow_spacing_panel.dart`:
  - Move `_FlowSpacingPanel` from `editor_page.dart`
  - Make it public: `class FlowSpacingPanel extends StatelessWidget`
  - Update `editor_page.dart` and `export_page.dart` to import and use it

**Impact**:
- Smaller, more focused files
- Easier to find and modify specific widgets
- Reusable components

### 7. Stricter Lint Rules

**Problem**: Default `flutter_lints` doesn't catch some common issues like mutable fields, missing const constructors, and empty catch blocks.

**Solution**: Enable additional lint rules.

**Changes**:
- `analysis_options.yaml`:
```yaml
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

**Impact**:
- Catches more issues at compile time
- Encourages better coding practices
- May surface existing issues that need fixing
- Low risk — lints are warnings, not errors

### 8. Basic Tests

**Problem**: Only 2 test files for ~11,842 lines of code. Critical paths have no test coverage.

**Solution**: Add tests for core functionality.

**Changes**:

#### 8a. Model Tests
Create `test/models_test.dart`:
- Test `Project` serialization round-trip (toJson → fromJson)
- Test `TextBlock` serialization round-trip
- Test `PageSetup` serialization round-trip
- Test `MarginMm` serialization round-trip
- Test `copyWith` methods preserve unchanged fields
- Test `copyWith` with clear flags (e.g., `clearColumnSpan`)

#### 8b. Pagination Tests
Create `test/pagination_test.dart`:
- Test `paginateBlocks` with empty blocks
- Test `paginateBlocks` with single block
- Test `paginateBlocks` with page breaks
- Test `paginateBlocks` with column breaks
- Test `paginateBlocks` with column spans
- Test `estimateBlockWidthFraction` scoring

#### 8c. Pronunciation Service Tests
Create `test/pronunciation_service_test.dart`:
- Test `savePronunciation` and `getPronunciation`
- Test `updatePronunciation`
- Test `deleteEntry`
- Test `getAllEntries`
- Test `exportToJson` and `importFromJson`
- Test `isSavablePronunciation` validation

**Impact**:
- Protects against regressions
- Documents expected behavior
- Makes refactoring safer
- Moderate effort but high long-term value

## Implementation Order

1. **Immutable models** — Mechanical change, no dependencies
2. **Stricter lint rules** — Quick win, surfaces issues early
3. **Shared utilities** — Reduces duplication before other changes
4. **Typed block updates** — Improves type safety
5. **Extract large widgets** — Improves code organization
6. **PDF rendering cache** — Performance improvement
7. **Editor performance** — Performance improvement
8. **Basic tests** — Protects all changes above

## Risk Assessment

| Change | Risk | Mitigation |
|--------|------|------------|
| Immutable models | Low | Mechanical change, existing copyWith works |
| Typed block updates | Low | Contained to editor widgets |
| Shared utilities | Low | Pure extraction, no behavior change |
| PDF cache | Low | Per-export cache, no persistence |
| Editor memoization | Low | Simple reference check |
| Lazy ListView | Low | Standard Flutter pattern |
| Extract widgets | Low | Pure refactoring |
| Lint rules | Low | Warnings only, not errors |
| Tests | None | Additive only |

**Overall Risk**: Low. All changes are conservative, well-scoped, and don't alter the application's behavior or architecture.

## Success Criteria

1. ✅ All model fields are `final`
2. ✅ No `Map<String, dynamic>` in block update API
3. ✅ Duplicated patterns extracted to shared utilities
4. ✅ PDF export faster for projects with repeated text
5. ✅ Editor smoother with many blocks
6. ✅ Lint rules catch common issues
7. ✅ Core functionality has test coverage
8. ✅ `flutter analyze` passes with new rules
9. ✅ `flutter test` passes
10. ✅ Application behavior unchanged

## Conclusion

This focused optimization addresses the most impactful extensibility and performance issues without introducing architectural complexity or risk. Each change is independently valuable and can be implemented incrementally. The result is a codebase that's easier to extend, faster to use, and safer to modify.
