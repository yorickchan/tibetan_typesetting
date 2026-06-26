# Functional Programming Refactor — Design Spec

**Date:** 2026-06-26
**Goal:** Improve maintainability of `lib/` by refactoring toward functional programming — immutability, pure functions, Dart 3 records/sealed classes/exhaustive pattern matching. No external FP libraries.
**Scope:** Whole `lib/` (utils, services, models, widgets, pages, l10n untouched).
**Migration:** File-by-file, worst offenders first, one commit per file, verify after each.

---

## 1. Guiding Principles

Apply to every file, regardless of layer:

1. **Immutability by default.** `final` on all locals; `const` constructors and `const` collections where possible. No `var` unless a genuine accumulator that `fold` cannot express cleanly. Mutable lists/maps only inside the imperative shell of a service, behind a pure-function boundary.

2. **Pure functions for all logic.** A function is pure if: same input → same output, no side effects, no I/O. Layout math, width estimation, range parsing, color-span splitting, SQL-where-clause building, font-priority ranking — all become top-level (or static) pure functions taking args → returning values. No singleton access, no `Platform.`, no `await` inside them.

3. **Dart 3 features, no external libs.**
   - **Records** for multi-value returns: `({List<LayoutCell> cells, bool pageBreakBefore})`, `({String prefix, String suffix})`, `({String where, List<Object> args})`.
   - **Switch expressions + exhaustive pattern matching** over `if/else` chains and type tags. Any place currently passing a `String` type-tag becomes a sealed class hierarchy.
   - **Sealed classes** for variant types — most notably `TextBlock` width-estimation, which currently branches on `isImageBlock`/`isOpeningMark`/`columnSpan != null`/else. Model as `sealed class BlockWidthEstimate` with `Image`, `Manual`, `OpeningMark`, `Text` subtypes.

4. **Higher-order over loops.** `fold`, `map`, `where`, `expand`, `fold`-based state machines replace `for` + `var cursor` + `.add`. The current `_buildRows` is a fold over blocks accumulating `({List<LayoutCell> current, double cursor, bool pendingBreak})`.

5. **No behavior change.** Same outputs for same inputs. This is a refactor, not a feature. Every transformed function must produce identical results — verified by the existing tests plus new unit tests on extracted pure functions.

---

## 2. `lib/utils/` — In-place transformation (Approach A)

Already nearly pure (only `text_renderer.dart` does I/O, as a leaf). Transform in place.

### `sample_layout.dart` (highest payoff)

- **`_buildRows`:** replace the `for` + `pushRow()` + `var current`/`var cursor`/`var pendingPageBreak` state machine with a `fold` over `blocks` accumulating a record `({List<LayoutCell> current, double cursor, bool pendingBreak, List<_Row> rows})`. The `pushRow` closure becomes a pure helper that flushes `current` into `rows` and resets the cursor. Floating-image blocks are filtered upstream with `where` so the fold never sees them.

- **`paginateBlocks` floating-image assignment (lines 152-175):** the nested-index loop becomes a functional pipeline. Compute `nonFloatingBlocks = blocks.where((b) => !b.floatingImage)`, build a cumulative-index map, then for each floating image, `fold` over pages accumulating `nonFloatingSeen` to find its target page. The per-page update becomes an immutable `map` producing a new `List<PageLayout>` rather than mutating `pages[clamped]`.

- **`_legacyRows`:** already a `map` — tighten to `List.generate` for the padding.

- **`estimateBlockWidthFraction`:** the `if/else` chain on `isImageBlock`/`columnSpan`/`isOpeningMark`/else → **sealed class**:
  ```dart
  sealed class BlockWidthEstimate {
    double fraction([double? contentWidthMm]);
    factory BlockWidthEstimate.from(TextBlock block) { ... }
  }
  class ImageWidth extends BlockWidthEstimate { final double? widthMm; ... }
  class ManualWidth extends BlockWidthEstimate { final int span; ... }
  class OpeningMarkWidth extends BlockWidthEstimate { ... }
  class TextWidth extends BlockWidthEstimate { final int tibetanLen, pronLen, transLen; ... }
  ```
  A factory `BlockWidthEstimate.from(TextBlock)` classifies; `double fraction([double? contentWidthMm])` on each subtype replaces the branch chain. Exhaustive `switch` guarantees a case was added when a new block kind appears.

- **`shouldUseShortRow`, `estimateCompactSmallRowHeight`:** `for`+`var maxHeight`/`var hasSmallBlock` → `fold` returning the running max. Early `return false` inside the loop → `row.every(...)` / `fold` with short-circuit via a `bool` accumulator.

- **`resolveContentRowHeights`:** the two-pass `for` with `List<double>.filled` mutation → build the compact-row index set with `where + toList`, then `List.generate` for final heights computing extra per normal row. Pure, no mutation.

### `tibetan_segmenter.dart` (light touch)

Already functional. `splitByTsek`/`splitByTsekRange`/`splitByRedHighlightRanges` already use records. Add `const` to regexes where not present; use `switch` expressions in `splitByRedHighlightRanges`'s segment-tagging where an `if/else` exists. Verify `parseRedHighlightRanges`'s `fold` is clean.

### `text_renderer.dart`

Rasterization leaf. Extract any pure layout-math (size computation, padding) into top-level functions; keep `renderTextToPng` itself as the imperative shell since it calls `TextPainter`/`instantiateImageCodec`.

### Remaining utils

`font_utils.dart`, `wylie_converter.dart`, `colors.dart`, `content_page_template_layout.dart`, `title_page_layout.dart`, `save_state_mixin.dart` — mostly already pure helpers. Convert any remaining `for`+`add` to `fold`/`map`; add `const`. Low risk.

---

## 3. `lib/services/` — Functional core / imperative shell (Approach B)

Each service splits into `<name>_core.dart` (pure logic: no I/O, no `await`, no singletons, no platform channels, no `dart:io`/`package:sqflite`/`MethodChannel`) + the original file as a thin shell owning I/O, caches, and singleton lifecycle. Value-type packages (`package:pdf`'s `pw.Font`/`PdfColor`) are permitted in the core since they carry no effects — only the *loading* of fonts (file reads) stays in the shell.

### `font_service.dart` → `font_service_core.dart`

- **Pure (core):** `deduplicateFamilies` (already static-pure), `_fontPriority`, `_extensionLower`, `_isTtc`, `_supportedExtensions`, CJK-fallback-pattern matching (`pickCjkFallbacks(List<SystemFontInfo> scanned, {int maxFonts}) → List<SystemFontInfo>`), and directory-list resolution (`resolveFontDirs({String? home, bool mac, bool win, bool linux}) → List<String>`). The `SystemFontInfo` and `UnsupportedFontError` data classes move from `font_service.dart` into `font_service_core.dart` so the core never imports the shell.
- **Shell:** `FontService` keeps `_cachedFonts`/`_loadedPreviewFamilies`/`_pdfFontCache` and the `MethodChannel`; `scanSystemFonts`/`loadCjkFallbackFonts`/`loadFontForPreview`/`loadFontForPdf` call the core functions and perform the actual file reads.

### `pdf_service.dart` → `pdf_service_core.dart` (largest payoff, largest file)

- **Pure (core):** `makeColorizedSpans` (extract from `_makeColorizedSpans`), all layout-measurement helpers that compute coordinates from `PageSetup`/`PageLayout` without rendering, the render-cache-key string builder (`renderCacheKey(...)` → `String`), and the `BlockWidthEstimate` pipeline from Section 2. The `tryLoadPdfFont` warning-accumulation logic becomes `({pw.Font? font, String? warning})` returned from a pure decision function, with the shell doing the actual `await`.
- **Shell:** `PdfService` keeps `_renderCache`/`_templateSvgCache`/`_dharmaWheelSvg`, all `await`s (`renderTextToPng`, `rootBundle`, `loadFontForPdf`), and the `pw.Document` assembly. The shell calls core for every decision; core never touches `pw.` or `await`.

### `database_service.dart` → `database_service_core.dart`

- **Pure (core):** `buildProjectQuery({String? query, String? tag}) → ({String where, List<Object> args})` (extracts lines 107-120), `projectToRow(Project p) → Map<String, Object>` (the insert-map builder), `normalizeImportedBlocks(List<TextBlock> blocks) → List<TextBlock>` (the id-filling `map` at lines 244-251), and `rowToProjectListItem(Map row) → ProjectListItem` (the map closure at 130-138).
- **Shell:** `DatabaseService` owns the `Database` handle and transactions, calling core for SQL construction and row decoding.

### Remaining services

`title_page_template_service.dart`, `html_export_service.dart`, `batch_import_service.dart`, `pronunciation_service.dart` — smaller; apply the same core/shell split where logic exists, leave pure-ish ones as-is.

---

## 4. `lib/models/` — Light touch

Models are already immutable with `copyWith`/`toJson`/`fromJson`. Changes:
- Add `const` to all constructors that can take it (many already do).
- `MarginMm`/`TemplateInset`/`PageSetup`/`TextBlock`/`Project`: ensure `==`/`hashCode` exist where value-equality matters (some do, e.g. `SystemFontInfo` — audit the rest). Makes `fold`/`map` pipelines testable on equality.
- `block_update.dart` — small; add `const`.
- No sealed-class modeling of `TextBlock` itself — it's a data model with many optional fields, persisted to JSON; the sealed-class treatment applies to *width-estimation variants* (Section 2), not the model.

---

## 5. `lib/widgets/` & `lib/pages/` — Extract pure build helpers

Flutter imposes `setState`/`TextEditingController`/lifecycle — we don't fight that. The FP win is **readability + golden-testability**: extract the gnarly conditional widget trees into top-level pure functions `Widget buildX(BuildContext, {required ...inputs})` that take explicit args (no `this._state` access) and return a `Widget`.

Targets (largest first):
- `sample_page.dart` (36KB), `block_editor.dart` (24KB), `content_page_template_panel.dart` (14KB), `title_page_settings_panel.dart` (26KB), `settings_page.dart` (25KB), `editor_page.dart` (33KB) — extract sub-builders; the `_State` keeps only lifecycle + event handlers + `setState` calls that delegate to pure helpers.
- `project_card.dart`, `block_strip.dart`, `scaled_preview.dart` — smaller; light touch.

The build helpers are pure in the sense of "same inputs → same widget tree," testable via golden tests, not unit tests.

---

## 6. Error handling & testing strategy

### Error handling (no `Either`/`Option` — no external libs)

- **Records for fallible-but-recoverable results:** `({pw.Font? font, String? warning})`, `({SystemFontInfo? info, String? error})`. Keeps the shell's `try/catch` at the I/O boundary; the core returns a record, the shell decides.
- **Sealed result types where the error path is structural** (e.g. font-load failure has distinct reasons): `sealed class FontLoadResult` with `Loaded(pw.Font)`, `Unsupported(reason)`, `MissingTables(List<String>)`, `NotFound`. The shell pattern-matches exhaustively.
- **Exceptions** stay for truly exceptional I/O failures (file missing, DB locked) — thrown at the shell, not the core.

### Testing

The whole point of core/shell is testability. New tests in `test/`:
- `sample_layout_test.dart` — `_buildRows` fold, `paginateBlocks` floating-image assignment, `estimateBlockWidthFraction` via `BlockWidthEstimate`, `resolveContentRowHeights` redistribution.
- `font_service_core_test.dart` — `deduplicateFamilies`, `pickCjkFallbacks`, `resolveFontDirs`, `_fontPriority`.
- `database_service_core_test.dart` — `buildProjectQuery`, `projectToRow`, `normalizeImportedBlocks`, `rowToProjectListItem`.
- `pdf_service_core_test.dart` — `makeColorizedSpans`, `renderCacheKey`, coordinate math.
- Existing `widget_test.dart` must still pass (behavior preservation).

Run `flutter analyze` + `flutter test` after each file — these are the gates, run once across the union of changed files.

---

## 7. Migration order (file-by-file, worst offenders first)

Each item = its own commit. Stop-and-verify (`flutter analyze` + `flutter test`) after each:

1. `sample_layout.dart` — `_buildRows` fold + floating-image pipeline + `BlockWidthEstimate` sealed class + `resolveContentRowHeights` rewrite. **Highest payoff.**
2. `font_service.dart` → `font_service_core.dart` split.
3. `database_service.dart` → `database_service_core.dart` split.
4. `pdf_service.dart` → `pdf_service_core.dart` split (largest; do last of the big three).
5. `tibetan_segmenter.dart` — light touch.
6. Remaining `utils/` — `font_utils`, `wylie_converter`, `colors`, layout helpers.
7. `models/` — `const`/equality audit.
8. `widgets/` + `pages/` — extract pure build helpers, largest files first.
9. Final pass: `flutter analyze` clean, `flutter test` green across all added + existing tests.

---

## Non-goals

- No new external dependencies (no `fpdart`, `dartz`, `built_value`, `freezed`).
- No change to the app's external behavior, PDF output, or persisted JSON format.
- No change to localization (`l10n/`).
- No sealed-class rewrite of the `TextBlock`/`Project` data models themselves.
- No rewrite of Flutter-imposed widget lifecycle (`setState`, controllers) — only extraction of pure build helpers.
