# Functional Programming Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor `lib/` toward functional programming — immutability, pure functions, Dart 3 records/sealed classes/exhaustive pattern matching — to improve maintainability, with zero behavior change.

**Architecture:** Two strategies by layer. `lib/utils/` transforms in place (already nearly pure). `lib/services/` splits each into a `*_core.dart` (pure logic, no I/O/singletons/platform channels) plus a thin imperative shell. `lib/models/` gets a `const`/equality audit. `lib/widgets/`+`pages/` extract pure build helpers from large State classes. No external FP libraries.

**Tech Stack:** Dart 3 (records, sealed classes, switch expressions), Flutter, `pdf` package, `sqflite`. No new dependencies.

## Global Constraints

- **No behavior change.** Same outputs for same inputs. Verified by existing 121 tests staying green plus new unit tests on extracted pure functions.
- **No external FP libraries** (`fpdart`, `dartz`, `built_value`, `freezed`). Dart 3 features only.
- **Pure core constraint:** `*_core.dart` files have no I/O, no `await`, no singletons, no platform channels, no `dart:io`/`package:sqflite`/`MethodChannel`. Value-type packages (`package:pdf`'s `pw.Font`/`PdfColor`) are permitted since they carry no effects.
- **Verify after each task:** `flutter analyze` must be clean and `flutter test` must pass before committing.
- **Import order** (from AGENTS.md): Dart SDK → Flutter SDK → third-party → parent-relative → same-dir relative, separated by blank lines.
- **No comments** unless explicitly requested. Code is self-documenting.
- **`const` constructors** where possible. `final` on all locals.
- Baseline: 121 tests pass across 16 test files (verified pre-plan).

---

### Task 1: Sealed `BlockWidthEstimate` in `sample_layout.dart`

Extract the `if/else` branch chain in `estimateBlockWidthFraction` into a sealed class hierarchy with exhaustive `switch`. This is the foundation for Task 2's `fold` rewrite and is independently testable.

**Files:**
- Modify: `lib/utils/sample_layout.dart:183-216` (`estimateBlockWidthFraction`)
- Test: `test/sample_layout_test.dart` (new file)

**Interfaces:**
- Consumes: `TextBlock` from `lib/models/project.dart` (fields: `isImageBlock` getter, `imageWidthMm: double?`, `columnSpan: int?`, `isOpeningMark` getter, `isFreeText` getter, `tibetan: String`, `chinesePronunciation: String`, `chineseTranslation: String`). `splitLines` from same file (line 15). `maxColumnSpan` const (line 3).
- Produces: `sealed class BlockWidthEstimate` with `factory BlockWidthEstimate.from(TextBlock block)` and `double fraction([double? contentWidthMm])` method; subtypes `ImageWidth`, `ManualWidth`, `OpeningMarkWidth`, `TextWidth`. Public function `estimateBlockWidthFraction(TextBlock block, [double? contentWidthMm]) → double` (kept for all callers, now delegates to the sealed class).

- [ ] **Step 1: Write the failing test**

Create `test/sample_layout_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/utils/sample_layout.dart';

void main() {
  group('BlockWidthEstimate', () {
    test('classifies image blocks', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 'img', imagePath: '/x.png', imageWidthMm: 50),
      );
      expect(estimate, isA<ImageWidth>());
      expect((estimate as ImageWidth).widthMm, 50);
    });

    test('classifies manual column span blocks', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 'm', columnSpan: 8),
      );
      expect(estimate, isA<ManualWidth>());
      expect((estimate as ManualWidth).span, 8);
    });

    test('classifies opening mark blocks', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 'om', format: TextBlockFormat.openingMark),
      );
      expect(estimate, isA<OpeningMarkWidth>());
    });

    test('classifies text blocks', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 't', tibetan: 'བོད།'),
      );
      expect(estimate, isA<TextWidth>());
    });

    test('image fraction uses widthMm when contentWidthMm given', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 'img', imagePath: '/x.png', imageWidthMm: 50),
      );
      expect(estimate.fraction(100), closeTo(0.5, 0.0001));
    });

    test('image fraction falls back to 0.45 without contentWidthMm', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 'img', imagePath: '/x.png'),
      );
      expect(estimate.fraction(null), 0.45);
    });

    test('manual span clamps to maxColumnSpan', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 'm', columnSpan: 25),
      );
      expect(estimate.fraction(), closeTo(1.0, 0.0001));
    });

    test('opening mark is 2/maxColumnSpan', () {
      final estimate = BlockWidthEstimate.from(
        TextBlock(id: 'om', format: TextBlockFormat.openingMark),
      );
      expect(estimate.fraction(), 2.0 / maxColumnSpan);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/sample_layout_test.dart`
Expected: FAIL — `BlockWidthEstimate` / `ImageWidth` / `ManualWidth` / `OpeningMarkWidth` / `TextWidth` are undefined.

- [ ] **Step 3: Write minimal implementation**

In `lib/utils/sample_layout.dart`, replace the `estimateBlockWidthFraction` function (lines 183-216) with the sealed class hierarchy plus a delegating function. Insert before the old function location (after `paginateBlocks`, before `contentTibetanLineHeight`):

```dart
sealed class BlockWidthEstimate {
  const BlockWidthEstimate();
  factory BlockWidthEstimate.from(TextBlock block) {
    if (block.isImageBlock) return ImageWidth(block.imageWidthMm);
    final manual = block.columnSpan;
    if (manual != null) return ManualWidth(manual);
    if (block.isOpeningMark) return const OpeningMarkWidth();
    return TextWidth(
      tibetanLen: splitLines(block.tibetan).join('').runes.length,
      pronLen: block.isFreeText
          ? 0
          : splitLines(block.chinesePronunciation).join('').runes.length,
      transLen: block.isFreeText
          ? 0
          : splitLines(block.chineseTranslation).join('').runes.length,
    );
  }
  double fraction([double? contentWidthMm]);
}

final class ImageWidth extends BlockWidthEstimate {
  final double? widthMm;
  const ImageWidth(this.widthMm);
  @override
  double fraction([double? contentWidthMm]) {
    if (widthMm != null && contentWidthMm != null && contentWidthMm > 0) {
      return (widthMm! / contentWidthMm).clamp(0.05, 1.0);
    }
    return 0.45;
  }
}

final class ManualWidth extends BlockWidthEstimate {
  final int span;
  const ManualWidth(this.span);
  @override
  double fraction([double? contentWidthMm]) =>
      span.clamp(1, maxColumnSpan) / maxColumnSpan;
}

final class OpeningMarkWidth extends BlockWidthEstimate {
  const OpeningMarkWidth();
  @override
  double fraction([double? contentWidthMm]) => 2.0 / maxColumnSpan;
}

final class TextWidth extends BlockWidthEstimate {
  final int tibetanLen;
  final int pronLen;
  final int transLen;
  const TextWidth({
    required this.tibetanLen,
    required this.pronLen,
    required this.transLen,
  });
  @override
  double fraction([double? contentWidthMm]) {
    final score = [
      tibetanLen * 1.15,
      pronLen * 0.62,
      transLen * 0.62,
    ].reduce((a, b) => a > b ? a : b);
    return (0.07 + score / 260).clamp(0.09, 0.52);
  }
}

double estimateBlockWidthFraction(TextBlock block, [double? contentWidthMm]) =>
    BlockWidthEstimate.from(block).fraction(contentWidthMm);
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/sample_layout_test.dart test/pagination_test.dart test/widget_test.dart`
Expected: PASS — new `BlockWidthEstimate` tests pass, existing `estimateBlockWidthFraction` tests still pass (behavior preserved).

- [ ] **Step 5: Commit**

```bash
git add lib/utils/sample_layout.dart test/sample_layout_test.dart
git commit -m "refactor: extract BlockWidthEstimate sealed class from estimateBlockWidthFraction"
```

---

### Task 2: `_buildRows` fold rewrite in `sample_layout.dart`

Replace the `for` + `pushRow()` + mutable-accumulator state machine with a `fold` over blocks accumulating a record. Pure, no mutation visible.

**Files:**
- Modify: `lib/utils/sample_layout.dart:60-108` (`_buildRows`)
- Test: `test/sample_layout_test.dart` (extend)

**Interfaces:**
- Consumes: `TextBlock`, `LayoutCell` (lines 25-38: `block`, `leftFraction`, `widthFraction`), `_Row` (lines 40-45: `cells`, `pageBreakBefore`), `estimateBlockWidthFraction` (Task 1), `splitLines` (line 15).
- Produces: `List<_Row> _buildRows(List<TextBlock> blocks, double gapFraction, [double? contentWidthMm])` — unchanged signature.

- [ ] **Step 1: Write the failing test**

Append to `test/sample_layout_test.dart` (after the `BlockWidthEstimate` group):

```dart
  group('_buildRows via paginateBlocks', () {
    test('packs blocks into rows respecting 1.0 width limit', () {
      final blocks = List.generate(
        10,
        (i) => TextBlock(id: 'b$i', tibetan: 'text $i', columnSpan: 8),
      );
      final pages = paginateBlocks(blocks, 4, 4);
      final rows = pages[0].flowRows;
      expect(rows.length, greaterThan(1));
      for (final row in rows) {
        final totalWidth = row.fold<double>(
          0,
          (sum, cell) => sum + cell.widthFraction,
        );
        expect(totalWidth, lessThanOrEqualTo(1.0 + 0.0001));
      }
    });

    test('pageBreakBefore on empty start sets pending break', () {
      final blocks = [
        TextBlock(id: 'b1', tibetan: 'a', pageBreakBefore: true),
      ];
      final pages = paginateBlocks(blocks, 4, 4);
      expect(pages.length, 1);
      expect(pages[0].flowRows[0].single.block.id, 'b1');
    });

    test('floating images are excluded from rows', () {
      final blocks = [
        TextBlock(id: 'b1', tibetan: 'a'),
        TextBlock(id: 'float', tibetan: '', floatingImage: true),
        TextBlock(id: 'b2', tibetan: 'b'),
      ];
      final pages = paginateBlocks(blocks, 4, 4);
      final allBlockIds = pages
          .expand((p) => p.flowRows)
          .expand((r) => r)
          .map((c) => c.block.id)
          .toList();
      expect(allBlockIds, isNot(contains('float')));
    });
  });
```

- [ ] **Step 2: Run test to verify it fails (or passes against old impl)**

Run: `flutter test test/sample_layout_test.dart`
Expected: These tests may pass against the old implementation (they're behavior tests). They serve as the safety net proving the fold rewrite preserves behavior.

- [ ] **Step 3: Rewrite `_buildRows` as a fold**

Replace lines 60-108 (the entire `_buildRows` function) with:

```dart
List<_Row> _buildRows(
  List<TextBlock> blocks,
  double gapFraction, [
  double? contentWidthMm,
]) {
  final gap = gapFraction.clamp(0.0, 0.08);

  ({List<LayoutCell> current, double cursor, bool pendingBreak, List<_Row> rows})
  flush({
    required List<LayoutCell> current,
    required double cursor,
    required bool pendingBreak,
    required List<_Row> rows,
  }) {
    if (current.isEmpty) {
      return (current: current, cursor: cursor, pendingBreak: pendingBreak, rows: rows);
    }
    return (
      current: const [],
      cursor: 0.0,
      pendingBreak: false,
      rows: [...rows, _Row(cells: current, pageBreakBefore: pendingBreak)],
    );
  }

  final flowBlocks = blocks.where((b) => !b.floatingImage);

  final result = flowBlocks.fold<
    ({List<LayoutCell> current, double cursor, bool pendingBreak, List<_Row> rows})
  >(
    (current: const [], cursor: 0.0, pendingBreak: false, rows: const []),
    (acc, block) {
      var current = acc.current;
      var cursor = acc.cursor;
      var pendingBreak = acc.pendingBreak;

      if (block.pageBreakBefore && current.isNotEmpty) {
        final flushed = flush(
          current: current,
          cursor: cursor,
          pendingBreak: pendingBreak,
          rows: acc.rows,
        );
        current = flushed.current;
        cursor = flushed.cursor;
        pendingBreak = flushed.pendingBreak;
      }
      if (block.pageBreakBefore && current.isEmpty) {
        pendingBreak = true;
      }
      if (block.columnBreakBefore && current.isNotEmpty) {
        final flushed = flush(
          current: current,
          cursor: cursor,
          pendingBreak: pendingBreak,
          rows: acc.rows,
        );
        current = flushed.current;
        cursor = flushed.cursor;
        pendingBreak = flushed.pendingBreak;
      }

      final width = estimateBlockWidthFraction(block, contentWidthMm);
      if (current.isNotEmpty && cursor + width > 1.0) {
        final flushed = flush(
          current: current,
          cursor: cursor,
          pendingBreak: pendingBreak,
          rows: acc.rows,
        );
        current = flushed.current;
        cursor = flushed.cursor;
        pendingBreak = flushed.pendingBreak;
      }

      final clampedWidth = width.clamp(0.08, (1.0 - cursor).clamp(0.08, 1.0));
      final newCurrent = [
        ...current,
        LayoutCell(
          block: block,
          leftFraction: cursor,
          widthFraction: clampedWidth,
        ),
      ];
      return (
        current: newCurrent,
        cursor: cursor + clampedWidth + gap,
        pendingBreak: pendingBreak,
        rows: acc.rows,
      );
    },
  );

  final finalFlushed = flush(
    current: result.current,
    cursor: result.cursor,
    pendingBreak: result.pendingBreak,
    rows: result.rows,
  );
  return finalFlushed.rows;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/sample_layout_test.dart test/pagination_test.dart test/widget_test.dart test/row_height_layout_test.dart`
Expected: PASS — all behavior tests preserved.

- [ ] **Step 5: Commit**

```bash
git add lib/utils/sample_layout.dart test/sample_layout_test.dart
git commit -m "refactor: rewrite _buildRows as fold with immutable record accumulator"
```

---

### Task 3: `paginateBlocks` floating-image pipeline rewrite

Replace the nested-index `for` loop (lines 152-175) that mutates `pages[clamped]` with an immutable functional pipeline.

**Files:**
- Modify: `lib/utils/sample_layout.dart:110-181` (`paginateBlocks`)
- Test: `test/pagination_test.dart` (extend — already has floating-image tests)

**Interfaces:**
- Consumes: `_buildRows` (Task 2), `PageLayout` (lines 47-58), `_Row`.
- Produces: `List<PageLayout> paginateBlocks(...)` — unchanged signature.

- [ ] **Step 1: Write the failing test**

Append to `test/pagination_test.dart` (inside the `floating image blocks` group):

```dart
    test('multiple floating images assign to correct pages', () {
      final blocks = [
        TextBlock(id: 'b1', tibetan: 'a', columnSpan: 24),
        TextBlock(id: 'b2', tibetan: 'b', columnSpan: 24),
        TextBlock(id: 'b3', tibetan: 'c', columnSpan: 24),
        TextBlock(id: 'b4', tibetan: 'd', columnSpan: 24),
        TextBlock(id: 'f1', tibetan: '', floatingImage: true),
        TextBlock(id: 'f2', tibetan: '', floatingImage: true),
      ];
      final pages = paginateBlocks(blocks, 4, 1);
      final allFloating = pages.expand((p) => p.floatingImages).map((b) => b.id);
      expect(allFloating, containsAll(['f1', 'f2']));
    });

    test('floating image before all content assigns to first page', () {
      final blocks = [
        TextBlock(id: 'f', tibetan: '', floatingImage: true),
        TextBlock(id: 'b1', tibetan: 'a', columnSpan: 24),
        TextBlock(id: 'b2', tibetan: 'b', columnSpan: 24),
      ];
      final pages = paginateBlocks(blocks, 4, 1);
      expect(pages.first.floatingImages.any((b) => b.id == 'f'), isTrue);
    });
```

- [ ] **Step 2: Run test to verify it fails (or passes against old impl)**

Run: `flutter test test/pagination_test.dart`
Expected: Likely passes against old impl — safety net.

- [ ] **Step 3: Rewrite floating-image assignment as immutable pipeline**

Replace lines 151-175 (the `// Assign floating images to pages` block through the closing of the `if (floatImages.isNotEmpty ...)`) with:

```dart
  final floatImages = blocks.where((b) => b.floatingImage).toList();
  final pagesWithFloats = floatImages.isEmpty || pages.isEmpty
      ? pages
      : floatImages.fold<List<PageLayout>>(
          pages,
          (currentPages, fi) {
            final fiIdx = blocks.indexOf(fi);
            final assignment = _assignFloatingImagePage(
              fiIdx,
              currentPages,
            );
            return [
              for (var pi = 0; pi < currentPages.length; pi++)
                if (pi == assignment.pageIndex)
                  PageLayout(
                    colCount: currentPages[pi].colCount,
                    flowRows: currentPages[pi].flowRows,
                    floatingImages: [
                      ...currentPages[pi].floatingImages,
                      fi,
                    ],
                  )
                else
                  currentPages[pi],
            ];
          },
        );
  return pagesWithFloats.isEmpty
      ? [PageLayout(colCount: effectiveColCount, flowRows: const [])]
      : pagesWithFloats;
}

({int pageIndex, int nonFloatingSeen}) _assignFloatingImagePage(
  int fiIdx,
  List<PageLayout> pages,
) {
  var nonFloatingSeen = 0;
  for (var pi = 0; pi < pages.length; pi++) {
    final pageBlockCount = pages[pi].flowRows.expand((r) => r).length;
    if (fiIdx <= nonFloatingSeen + pageBlockCount) {
      return (pageIndex: pi, nonFloatingSeen: nonFloatingSeen);
    }
    nonFloatingSeen += pageBlockCount;
  }
  return (pageIndex: pages.length - 1, nonFloatingSeen: nonFloatingSeen);
}
```

Note: This replaces the `return pages;` at the end of the original function too — the new `pagesWithFloats` return is the function's final return. Ensure the trailing `if (pages.isEmpty)` guard (lines 177-179) is subsumed by the `pagesWithFloats.isEmpty ? ... : ...` check.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test`
Expected: ALL 121+ tests pass. This is the critical behavior-preservation gate.

- [ ] **Step 5: Commit**

```bash
git add lib/utils/sample_layout.dart test/pagination_test.dart
git commit -m "refactor: rewrite paginateBlocks floating-image assignment as immutable fold"
```

---

### Task 4: `resolveContentRowHeights` + `shouldUseShortRow` + `estimateCompactSmallRowHeight` rewrite

Replace the remaining `for`+mutation loops in `sample_layout.dart` with `fold`/`where`/`List.generate`.

**Files:**
- Modify: `lib/utils/sample_layout.dart:242-349` (`shouldUseShortRow`, `estimateCompactSmallRowHeight`, `resolveContentRowHeights`)
- Test: `test/row_height_layout_test.dart` (extend), `test/sample_layout_test.dart` (extend)

**Interfaces:**
- Consumes: `LayoutCell`, `TextBlock`, `splitLines`, `contentChineseLineHeight` const (line 240).
- Produces: unchanged signatures for all three functions.

- [ ] **Step 1: Write the failing test**

Append to `test/sample_layout_test.dart`:

```dart
  group('resolveContentRowHeights', () {
    test('all-compact rows return minimums unchanged', () {
      final rows = [
        [LayoutCell(block: TextBlock(id: 's1', tibetan: 'x', smallText: true), leftFraction: 0, widthFraction: 1)],
        [LayoutCell(block: TextBlock(id: 's2', tibetan: 'x', smallText: true), leftFraction: 0, widthFraction: 1)],
      ];
      expect(
        resolveContentRowHeights(rows, contentHeight: 100, compactMinimumHeights: [20, 30]),
        [20, 30],
      );
    });

    test('all-normal rows split content height equally', () {
      final rows = [
        [LayoutCell(block: TextBlock(id: 'n1', tibetan: 'x'), leftFraction: 0, widthFraction: 1)],
        [LayoutCell(block: TextBlock(id: 'n2', tibetan: 'x'), leftFraction: 0, widthFraction: 1)],
      ];
      expect(
        resolveContentRowHeights(rows, contentHeight: 100, compactMinimumHeights: [0, 0]),
        [50, 50],
      );
    });

    test('empty rows returns empty', () {
      expect(
        resolveContentRowHeights(const [], contentHeight: 100, compactMinimumHeights: const []),
        isEmpty,
      );
    });
  });
```

- [ ] **Step 2: Run test to verify it fails (or passes against old impl)**

Run: `flutter test test/sample_layout_test.dart`
Expected: Likely passes — safety net.

- [ ] **Step 3: Rewrite the three functions**

Replace `shouldUseShortRow` (lines 242-271) with:

```dart
bool shouldUseShortRow(
  List<LayoutCell> row, {
  double? availableHeight,
  double? minimumHeight,
}) {
  if (row.isEmpty) return false;
  if (availableHeight != null &&
      minimumHeight != null &&
      availableHeight < minimumHeight) {
    return false;
  }
  final hasSmall = row.fold<bool>(
    false,
    (acc, cell) {
      if (!acc) return false;
      final block = cell.block;
      if (!block.smallText && !block.isFreeText) return false;
      if (block.isFreeText) {
        return splitLines(block.tibetan).length <= 1;
      }
      return splitLines(block.tibetan).length <= 1 &&
          splitLines(block.chinesePronunciation).length <= 1;
    },
    initial: true,
  );
  return hasSmall;
}
```

Wait — `fold<bool>` with short-circuit doesn't truly short-circuit (it visits all elements). The original early-returns. To preserve the early-exit semantics (and avoid calling `splitLines` on later cells once a `false` is determined), use `every`-style logic instead:

Replace `shouldUseShortRow` (lines 242-271) with:

```dart
bool shouldUseShortRow(
  List<LayoutCell> row, {
  double? availableHeight,
  double? minimumHeight,
}) {
  if (row.isEmpty) return false;
  if (availableHeight != null &&
      minimumHeight != null &&
      availableHeight < minimumHeight) {
    return false;
  }
  final allCompact = row.every((cell) {
    final block = cell.block;
    if (!block.smallText && !block.isFreeText) return false;
    if (block.isFreeText) {
      return splitLines(block.tibetan).length <= 1;
    }
    return splitLines(block.tibetan).length <= 1 &&
        splitLines(block.chinesePronunciation).length <= 1;
  });
  return allCompact;
}
```

Replace `estimateCompactSmallRowHeight` (lines 273-306) with:

```dart
double estimateCompactSmallRowHeight(
  List<LayoutCell> row, {
  required double tibetanFontSize,
  required double chineseFontSize,
  double topPadding = 0,
  double tibetanLineHeight = 1.2,
  double chineseLineHeight = contentChineseLineHeight,
}) {
  return row.fold<double>(
    0,
    (maxHeight, cell) {
      final block = cell.block;
      var height = topPadding;
      if (block.isFreeText) {
        if (splitLines(block.tibetan).isNotEmpty) {
          height += chineseFontSize * chineseLineHeight;
        }
        return height > maxHeight ? height : maxHeight;
      }
      if (splitLines(block.tibetan).isNotEmpty) {
        height += tibetanFontSize * tibetanLineHeight;
      }
      if (splitLines(block.chinesePronunciation).isNotEmpty) {
        height += 2 + chineseFontSize * chineseLineHeight;
      }
      return height > maxHeight ? height : maxHeight;
    },
  );
}
```

Replace `resolveContentRowHeights` (lines 308-349) with:

```dart
List<double> resolveContentRowHeights(
  List<List<LayoutCell>> rows, {
  required double contentHeight,
  required List<double> compactMinimumHeights,
}) {
  if (rows.isEmpty) return const [];

  final baseHeight = contentHeight / rows.length;
  final compactIndices = [
    for (var i = 0; i < rows.length; i++)
      if (shouldUseShortRow(
        rows[i],
        availableHeight: baseHeight,
        minimumHeight: compactMinimumHeights[i],
      ))
        i,
  ];

  if (compactIndices.isEmpty || compactIndices.length == rows.length) {
    return [for (final i in compactIndices) compactMinimumHeights[i].toDouble(), for (var i = 0; i < rows.length; i++) if (!compactIndices.contains(i)) baseHeight];
  }
```

Hmm — the original returns `List<double>.filled(rows.length, baseHeight)` with compact rows overridden, then redistributes. The all-compact early-return returns `rowHeights` (which has minimums set). The all-normal path returns `rowHeights` (all baseHeight). Let me match exactly. Replace `resolveContentRowHeights` (lines 308-349) with:

```dart
List<double> resolveContentRowHeights(
  List<List<LayoutCell>> rows, {
  required double contentHeight,
  required List<double> compactMinimumHeights,
}) {
  if (rows.isEmpty) return const [];

  final baseHeight = contentHeight / rows.length;
  final compactIndices = <int>[
    for (var i = 0; i < rows.length; i++)
      if (shouldUseShortRow(
        rows[i],
        availableHeight: baseHeight,
        minimumHeight: compactMinimumHeights[i],
      ))
        i,
  ];

  final isCompact = {for (final i in compactIndices) i};

  if (compactIndices.isEmpty || compactIndices.length == rows.length) {
    return [
      for (var i = 0; i < rows.length; i++)
        isCompact.contains(i) ? compactMinimumHeights[i] : baseHeight,
    ];
  }

  final releasedHeight = compactIndices.fold<double>(
    0,
    (sum, i) => sum + baseHeight - compactMinimumHeights[i],
  );
  final normalRowCount = rows.length - compactIndices.length;
  final normalRowExtraHeight = releasedHeight / normalRowCount;

  return [
    for (var i = 0; i < rows.length; i++)
      isCompact.contains(i)
          ? compactMinimumHeights[i]
          : baseHeight + normalRowExtraHeight,
  ];
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/sample_layout_test.dart test/row_height_layout_test.dart test/widget_test.dart`
Expected: PASS — the `row_height_layout_test.dart` case (`[30, 170]`) is the critical redistribution assertion.

- [ ] **Step 5: Commit**

```bash
git add lib/utils/sample_layout.dart test/sample_layout_test.dart
git commit -m "refactor: rewrite resolveContentRowHeights and shouldUseShortRow with fold/every"
```

---

### Task 5: `font_service` core/shell split

Extract pure logic from `FontService` into `font_service_core.dart`. `SystemFontInfo` and `UnsupportedFontError` move to core so the core never imports the shell.

**Files:**
- Create: `lib/services/font_service_core.dart`
- Modify: `lib/services/font_service.dart` (remove extracted code, re-export for compatibility)
- Test: `test/font_service_core_test.dart` (new), `test/font_service_test.dart` (existing — must still pass)

**Interfaces:**
- Consumes: `FontConfig` from `lib/models/font_config.dart`.
- Produces: `SystemFontInfo`, `UnsupportedFontError`, `deduplicateFamilies`, `fontPriority`, `extensionLower`, `isTtc`, `supportedFontExtensions`, `pickCjkFallbackFonts`, `resolveFontDirs` — all in `font_service_core.dart`, exported via `font_service.dart` for existing callers.

- [ ] **Step 1: Write the failing test**

Create `test/font_service_core_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/font_service_core.dart';

void main() {
  group('pickCjkFallbackFonts', () {
    test('returns fonts matching patterns in priority order', () {
      final fonts = [
        const SystemFontInfo(
            familyName: 'Arial Unicode MS', filePath: '/a.ttf', fileType: 'ttf'),
        const SystemFontInfo(
            familyName: 'Noto Sans CJK', filePath: '/b.ttf', fileType: 'ttf'),
        const SystemFontInfo(
            familyName: 'Helvetica', filePath: '/c.ttf', fileType: 'ttf'),
      ];
      final picked = pickCjkFallbackFonts(fonts, maxFonts: 2);
      expect(picked.map((f) => f.familyName), ['Arial Unicode MS', 'Noto Sans CJK']);
    });

    test('respects maxFonts limit', () {
      final fonts = [
        const SystemFontInfo(
            familyName: 'Arial Unicode MS', filePath: '/a.ttf', fileType: 'ttf'),
        const SystemFontInfo(
            familyName: 'Noto Sans CJK', filePath: '/b.ttf', fileType: 'ttf'),
      ];
      expect(pickCjkFallbackFonts(fonts, maxFonts: 1).length, 1);
    });

    test('deduplicates by filePath', () {
      final fonts = [
        const SystemFontInfo(
            familyName: 'Arial Unicode MS', filePath: '/a.ttf', fileType: 'ttf'),
        const SystemFontInfo(
            familyName: 'Noto Sans CJK', filePath: '/a.ttf', fileType: 'ttf'),
      ];
      expect(pickCjkFallbackFonts(fonts, maxFonts: 3).length, 1);
    });
  });

  group('resolveFontDirs', () {
    test('macOS includes user Library/Fonts when home given', () {
      final dirs = resolveFontDirs(home: '/Users/test', mac: true);
      expect(dirs, contains('/Users/test/Library/Fonts'));
      expect(dirs, contains('/System/Library/Fonts'));
    });

    test('linux includes .local/share/fonts and .fonts', () {
      final dirs = resolveFontDirs(home: '/home/test', linux: true);
      expect(dirs, contains('/home/test/.local/share/fonts'));
      expect(dirs, contains('/home/test/.fonts'));
    });

    test('windows uses WINDIR default', () {
      final dirs = resolveFontDirs(home: null, win: true);
      expect(dirs, contains(r'C:\Windows\Fonts'));
    });
  });

  group('fontPriority', () {
    test('regular ranks highest (0)', () {
      expect(
        fontPriority(const SystemFontInfo(
            familyName: 'Regular', filePath: '/x-regular.ttf', fileType: 'ttf')),
        0,
      );
    });
    test('plain non-bold ranks 1', () {
      expect(
        fontPriority(const SystemFontInfo(
            familyName: 'Body', filePath: '/x.ttf', fileType: 'ttf')),
        1,
      );
    });
    test('bold/italic ranks 2', () {
      expect(
        fontPriority(const SystemFontInfo(
            familyName: 'Body Bold', filePath: '/x-bold.ttf', fileType: 'ttf')),
        2,
      );
    });
  });

  group('isTtc', () {
    test('identifies ttc magic bytes', () {
      expect(isTtc([0x74, 0x74, 0x63, 0x66, 0x00]), isTrue);
    });
    test('rejects non-ttc', () {
      expect(isTtc([0x00, 0x01, 0x00, 0x00]), isFalse);
    });
    test('rejects too-short input', () {
      expect(isTtc([0x74, 0x74]), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/font_service_core_test.dart`
Expected: FAIL — `font_service_core.dart` / `pickCjkFallbackFonts` / `resolveFontDirs` / `fontPriority` / `isTtc` (public) undefined.

- [ ] **Step 3: Create `font_service_core.dart`**

Create `lib/services/font_service_core.dart`:

```dart
const Set<String> supportedFontExtensions = {'.ttf', '.otf', '.ttc'};

class UnsupportedFontError implements Exception {
  final String message;
  const UnsupportedFontError(this.message);
  @override
  String toString() => 'UnsupportedFontError: $message';
}

class SystemFontInfo {
  final String familyName;
  final String filePath;
  final String fileType;

  const SystemFontInfo({
    required this.familyName,
    required this.filePath,
    required this.fileType,
  });

  static SystemFontInfo? fromNativeMap(Map<Object?, Object?> map) {
    final familyName = map['familyName'];
    final filePath = map['filePath'];
    final fileType = map['fileType'];
    if (familyName is! String ||
        familyName.trim().isEmpty ||
        filePath is! String ||
        filePath.trim().isEmpty ||
        fileType is! String ||
        fileType.trim().isEmpty) {
      return null;
    }
    return SystemFontInfo(
      familyName: familyName,
      filePath: filePath,
      fileType: fileType.toLowerCase(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemFontInfo && filePath == other.filePath;

  @override
  int get hashCode => filePath.hashCode;
}

const _cjkFallbackPatterns = [
  'arial unicode',
  'noto sans cjk',
  'noto serif cjk',
  'droid sans fallback',
  'wenquanyi',
  'microsoft yahei',
  'simsun',
  'nsimsun',
  'simhei',
  'kaiti',
  'songti',
  'stheiti',
  'stsong',
  'pingfang',
  'hiragino sans gb',
  'hiragino sans',
];

List<SystemFontInfo> pickCjkFallbackFonts(
  List<SystemFontInfo> scanned, {
  int maxFonts = 3,
}) {
  final usedPaths = <String>{};
  final loaded = <SystemFontInfo>[];
  for (final pattern in _cjkFallbackPatterns) {
    if (loaded.length >= maxFonts) break;
    for (final info in scanned) {
      if (loaded.length >= maxFonts) break;
      if (usedPaths.contains(info.filePath)) continue;
      if (info.familyName.toLowerCase().contains(pattern)) {
        loaded.add(info);
        usedPaths.add(info.filePath);
      }
    }
  }
  return loaded;
}

List<String> resolveFontDirs({
  String? home,
  bool mac = false,
  bool win = false,
  bool linux = false,
}) {
  final base = <String>[
    if (mac) ...const [
      '/System/Library/Fonts',
      '/Library/Fonts',
      '/Network/Library/Fonts',
    ],
    if (win) ...[
      '${Platform.environment['WINDIR'] ?? r'C:\Windows'}\\Fonts',
    ],
    if (linux) ...const ['/usr/share/fonts', '/usr/local/share/fonts'],
  ];
  final userDirs = <String>[
    if (home != null && home.isNotEmpty) ...[
      if (mac) '$home/Library/Fonts',
      if (linux) '$home/.local/share/fonts',
      if (linux) '$home/.fonts',
    ],
  ];
  return [...base, ...userDirs];
}
```

Note: `resolveFontDirs` references `Platform.environment['WINDIR']` — that's `dart:io`. Since the core must not depend on `dart:io`, pass `windir` as a parameter instead. Revise the signature:

```dart
List<String> resolveFontDirs({
  String? home,
  String? windir,
  bool mac = false,
  bool win = false,
  bool linux = false,
}) {
  final winDir = windir ?? r'C:\Windows';
  return [
    if (mac) ...const ['/System/Library/Fonts', '/Library/Fonts', '/Network/Library/Fonts'],
    if (win) '$winDir\\Fonts',
    if (linux) ...const ['/usr/share/fonts', '/usr/local/share/fonts'],
    if (home != null && home.isNotEmpty) ...[
      if (mac) '$home/Library/Fonts',
      if (linux) '$home/.local/share/fonts',
      if (linux) '$home/.fonts',
    ],
  ];
}
```

Update the test in Step 1 to pass `windir: null` (the default `C:\Windows` applies). The test `'windows uses WINDIR default'` stays as-is.

Also add to core:

```dart
int fontPriority(SystemFontInfo font) {
  final path = font.filePath.toLowerCase();
  final name = font.familyName.toLowerCase();
  if (path.contains('regular') || name.contains('regular')) return 0;
  if (!path.contains('bold') &&
      !path.contains('italic') &&
      !path.contains('oblique') &&
      !path.contains('black') &&
      !path.contains('heavy')) {
    return 1;
  }
  return 2;
}

List<SystemFontInfo> deduplicateFamilies(List<SystemFontInfo> fonts) {
  final byFamily = <String, SystemFontInfo>{};
  for (final font in fonts) {
    final key = font.familyName.trim().toLowerCase();
    if (key.isEmpty) continue;
    final existing = byFamily[key];
    if (existing == null || fontPriority(font) < fontPriority(existing)) {
      byFamily[key] = font;
    }
  }
  final deduplicated = byFamily.values.toList();
  deduplicated.sort(
    (a, b) =>
        a.familyName.toLowerCase().compareTo(b.familyName.toLowerCase()),
  );
  return deduplicated;
}

String extensionLower(String path) {
  final dot = path.lastIndexOf('.');
  return dot >= 0 ? path.substring(dot).toLowerCase() : '';
}

bool isTtc(List<int> bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x74 &&
    bytes[1] == 0x74 &&
    bytes[2] == 0x63 &&
    bytes[3] == 0x66;
```

- [ ] **Step 4: Rewrite `font_service.dart` as the shell**

In `lib/services/font_service.dart`:
- Remove `SystemFontInfo`, `UnsupportedFontError`, `deduplicateFamilies`, `_cjkFallbackPatterns`, `_fontPriority`, `_extensionLower`, `_supportedExtensions`, `_isTtc` (all moved to core).
- Add `export 'font_service_core.dart';` at the top (after imports) so existing callers like `test/font_service_test.dart` and `pdf_service.dart` keep importing `font_service.dart` and still see `SystemFontInfo`/`UnsupportedFontError`/`deduplicateFamilies`.
- Rewrite `scanSystemFonts` to call `resolveFontDirs(home: homeDir, mac: Platform.isMacOS, win: Platform.isWindows, linux: Platform.isLinux)` and `deduplicateFamilies`.
- Rewrite `loadCjkFallbackFonts` to call `pickCjkFallbackFonts(await scanSystemFonts(), maxFonts: maxFonts)` then load each via `loadFontForPdf`.
- Keep `loadFontForPreview`, `loadFontForPdf`, `_scanNativeSystemFonts` as shell methods (they do I/O).

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/font_service_core_test.dart test/font_service_test.dart`
Expected: PASS — new core tests pass, existing `font_service_test.dart` (uses `SystemFontInfo.fromNativeMap`, `FontService.deduplicateFamilies`) still passes via the re-export.

Then run full suite: `flutter test`
Expected: ALL pass.

- [ ] **Step 6: Commit**

```bash
git add lib/services/font_service_core.dart lib/services/font_service.dart test/font_service_core_test.dart
git commit -m "refactor: split font_service into pure core and imperative shell"
```

---

### Task 6: `database_service` core/shell split

Extract pure SQL-construction and row-decoding logic from `DatabaseService`.

**Files:**
- Create: `lib/services/database_service_core.dart`
- Modify: `lib/services/database_service.dart`
- Test: `test/database_service_core_test.dart` (new)

**Interfaces:**
- Consumes: `Project`, `ProjectListItem`, `TextBlock` from `lib/models/project.dart`, `uuid` package (via the `_uuid` const in shell — core takes generated ids as args).
- Produces: `buildProjectQuery`, `projectToRow`, `normalizeImportedBlocks`, `rowToProjectListItem`.

- [ ] **Step 1: Write the failing test**

Create `test/database_service_core_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/models/project.dart';
import 'package:tibetan_typesetting/services/database_service_core.dart';

void main() {
  group('buildProjectQuery', () {
    test('empty query and tag returns null where', () {
      final result = buildProjectQuery(query: null, tag: null);
      expect(result.where, isNull);
      expect(result.args, isEmpty);
    });

    test('query adds name and tags LIKE clauses', () {
      final result = buildProjectQuery(query: 'dharma', tag: null);
      expect(result.where, contains('name'));
      expect(result.args, hasLength(2));
      expect(result.args.every((a) => (a as String).contains('dharma')), isTrue);
    });

    test('tag adds tags_json LIKE clause', () {
      final result = buildProjectQuery(query: null, tag: 'sutra');
      expect(result.where, contains('tags_json'));
      expect(result.args, hasLength(1));
    });

    test('both query and tag join with AND', () {
      final result = buildProjectQuery(query: 'dharma', tag: 'sutra');
      expect(result.where, contains('AND'));
      expect(result.args, hasLength(3));
    });
  });

  group('normalizeImportedBlocks', () {
    test('fills empty ids with generated ids', () {
      final blocks = [
        TextBlock(id: '', tibetan: 'a'),
        TextBlock(id: 'existing', tibetan: 'b'),
      ];
      final result = normalizeImportedBlocks(blocks, () => 'generated-id');
      expect(result[0].id, 'generated-id');
      expect(result[1].id, 'existing');
    });

    test('empty list returns single block with generated id', () {
      final result = normalizeImportedBlocks(const [], () => 'gen');
      expect(result.length, 1);
      expect(result[0].id, 'gen');
    });
  });

  group('projectToRow', () {
    test('builds insert map with json fields', () {
      final project = Project(
        id: 'p1',
        name: 'Test',
        tags: const ['a', 'b'],
        createdAt: '2024-01-01',
        updatedAt: '2024-01-02',
        blocks: const [],
      );
      final row = projectToRow(project);
      expect(row['id'], 'p1');
      expect(row['name'], 'Test');
      expect(row['tags_json'], contains('a'));
      expect(row['created_at'], '2024-01-01');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/database_service_core_test.dart`
Expected: FAIL — `database_service_core.dart` / functions undefined.

- [ ] **Step 3: Create `database_service_core.dart`**

Create `lib/services/database_service_core.dart`:

```dart
import 'dart:convert';

import '../models/project.dart';

({String? where, List<Object> args}) buildProjectQuery({
  String? query,
  String? tag,
}) {
  final q = (query ?? '').trim().toLowerCase();
  final t = (tag ?? '').trim().toLowerCase();
  final whereClauses = <String>[];
  final whereArgs = <Object>[];

  if (q.isNotEmpty) {
    whereClauses.add('(LOWER(name) LIKE ? OR LOWER(tags_json) LIKE ?)');
    whereArgs.add('%$q%');
    whereArgs.add('%$q%');
  }
  if (t.isNotEmpty) {
    whereClauses.add('LOWER(tags_json) LIKE ?');
    whereArgs.add('%"$t"%');
  }

  return (
    where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
    args: whereArgs,
  );
}

List<TextBlock> normalizeImportedBlocks(
  List<TextBlock> blocks,
  String Function() generateId,
) {
  final filled = blocks
      .map((b) => b.id.isEmpty ? b.copyWith(id: generateId()) : b)
      .toList();
  return filled.isEmpty ? [TextBlock(id: generateId())] : filled;
}

Map<String, Object> projectToRow(Project project) => {
      'id': project.id,
      'name': project.name,
      'tags_json': jsonEncode(project.tags),
      'project_json': project.toJsonString(),
      'created_at': project.createdAt,
      'updated_at': project.updatedAt,
    };

ProjectListItem rowToProjectListItem(Map<String, Object?> row) {
  final tags =
      (jsonDecode(row['tags_json'] as String) as List<dynamic>).cast<String>();
  return ProjectListItem(
    id: row['id'] as String,
    name: row['name'] as String,
    tags: tags,
    updatedAt: row['updated_at'] as String,
  );
}
```

- [ ] **Step 4: Rewrite `database_service.dart` to use core**

In `lib/services/database_service.dart`:
- Import `database_service_core.dart`.
- In `listProjects` (lines 100-139): replace lines 103-128 with `final query = buildProjectQuery(query: query, tag: tag);` then `db.query(..., where: query.where, whereArgs: query.args.isNotEmpty ? query.args : null, ...)`, and the `.map` closure becomes `.map(rowToProjectListItem)`.
- In `importProject` (lines 242-272): replace the `blocks`/`finalBlocks` computation (lines 244-251) with `final finalBlocks = normalizeImportedBlocks(project.blocks, () => _uuid.v4().replaceAll('-', ''));` and the insert map (lines 261-268) with `projectToRow(finalImported)`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/database_service_core_test.dart`
Then full suite: `flutter test`
Expected: ALL pass.

- [ ] **Step 6: Commit**

```bash
git add lib/services/database_service_core.dart lib/services/database_service.dart test/database_service_core_test.dart
git commit -m "refactor: split database_service into pure core and imperative shell"
```

---

### Task 7: `pdf_service` core extraction — `makeColorizedSpans` + `renderCacheKey`

Start the largest-file refactor with the two most self-contained pure functions.

**Files:**
- Create: `lib/services/pdf_service_core.dart`
- Modify: `lib/services/pdf_service.dart:161-184` (`_makeColorizedSpans`), `lib/services/pdf_service.dart:95-96` (cache key)
- Test: `test/pdf_service_core_test.dart` (new)

**Interfaces:**
- Consumes: `TextSpanDef` (defined where? — check `pdf_service.dart` or models), `isTibetanNonLetter` from `lib/utils/tibetan_segmenter.dart`.
- Produces: `makeColorizedSpans(String text, Color letterColor, Color otherColor) → List<TextSpanDef>`, `renderCacheKey(...)` → `String`.

- [ ] **Step 1: Locate `TextSpanDef`**

Run a search (the implementing agent should do this) to find where `TextSpanDef` is defined. It's referenced in `pdf_service.dart:161` and likely in `text_renderer.dart`. If it's in `lib/utils/text_renderer.dart`, the core imports it.

- [ ] **Step 2: Write the failing test**

Create `test/pdf_service_core_test.dart`:

```dart
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibetan_typesetting/services/pdf_service_core.dart';

void main() {
  group('makeColorizedSpans', () {
    test('single color text returns one span', () {
      final spans = makeColorizedSpans('abc', const Color(0xFF000000), const Color(0xFF000000));
      expect(spans.length, 1);
      expect(spans.first.text, 'abc');
    });

    test('splits Tibetan letters from non-letters', () {
      final letter = const Color(0xFF000000);
      final other = const Color(0xFFFF0000);
      final spans = makeColorizedSpans('བོད།', letter, other);
      expect(spans.length, greaterThan(1));
      expect(spans.every((s) => s.color == letter || s.color == other), isTrue);
    });

    test('consecutive same-color chars merge into one span', () {
      final spans = makeColorizedSpans('aaa', const Color(0xFF000000), const Color(0xFF000000));
      expect(spans.length, 1);
    });
  });

  group('renderCacheKey', () {
    test('produces stable key for same inputs', () {
      final k1 = renderCacheKey(
        text: 'x', fontFamily: 'f', fontSize: 12, color: const Color(0xFF000000),
        maxWidth: 100, lineHeight: null, topPadding: 0, bottomPadding: 0, textAlign: TextAlign.left,
      );
      final k2 = renderCacheKey(
        text: 'x', fontFamily: 'f', fontSize: 12, color: const Color(0xFF000000),
        maxWidth: 100, lineHeight: null, topPadding: 0, bottomPadding: 0, textAlign: TextAlign.left,
      );
      expect(k1, k2);
    });

    test('different text produces different key', () {
      final k1 = renderCacheKey(text: 'x', fontFamily: 'f', fontSize: 12, color: const Color(0xFF000000), maxWidth: 100, lineHeight: null, topPadding: 0, bottomPadding: 0, textAlign: TextAlign.left);
      final k2 = renderCacheKey(text: 'y', fontFamily: 'f', fontSize: 12, color: const Color(0xFF000000), maxWidth: 100, lineHeight: null, topPadding: 0, bottomPadding: 0, textAlign: TextAlign.left);
      expect(k1, isNot(k2));
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/pdf_service_core_test.dart`
Expected: FAIL — `pdf_service_core.dart` undefined.

- [ ] **Step 4: Create `pdf_service_core.dart`**

Create `lib/services/pdf_service_core.dart`:

```dart
import 'dart:ui' show Color, TextAlign;

import '../utils/text_renderer.dart' show TextSpanDef;
import '../utils/tibetan_segmenter.dart' show isTibetanNonLetter;

List<TextSpanDef> makeColorizedSpans(
  String text,
  Color letterColor,
  Color otherColor,
) {
  if (text.isEmpty) return const [];
  final chars = text.split('');
  final spans = chars.fold<List<TextSpanDef>>(
    const [],
    (acc, c) {
      final color = isTibetanNonLetter(c.codeUnitAt(0)) ? otherColor : letterColor;
      if (acc.isNotEmpty && acc.last.color == color) {
        return [...acc.sublist(0, acc.length - 1), TextSpanDef(acc.last.text + c, color)];
      }
      return [...acc, TextSpanDef(c, color)];
    },
  );
  return spans;
}

String renderCacheKey({
  required String text,
  required String fontFamily,
  required double fontSize,
  required Color color,
  required double maxWidth,
  double? lineHeight,
  required double topPadding,
  required double bottomPadding,
  required TextAlign textAlign,
}) =>
    '${text}_|_${fontFamily}_|_${fontSize}_|_${color.toARGB32()}_|_${maxWidth}_|_${lineHeight}_|_${topPadding}_|_${bottomPadding}_|_${textAlign}';
```

Note: The implementing agent must verify `TextSpanDef`'s constructor signature and location (search for `class TextSpanDef`). If `TextSpanDef` is defined in `pdf_service.dart` itself, move it to `text_renderer.dart` or `pdf_service_core.dart` first.

- [ ] **Step 5: Rewrite `pdf_service.dart` to use core**

In `lib/services/pdf_service.dart`:
- Import `pdf_service_core.dart`.
- Replace `_makeColorizedSpans` (lines 161-184) body with `return makeColorizedSpans(text, letterColor, otherColor);` (or remove the method and have callers use `makeColorizedSpans` directly — but keep the private wrapper if other private methods call it, to minimize diff).
- Replace the cache-key string literal in `_render` (line 95-96) with `renderCacheKey(...)`.

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/pdf_service_core_test.dart`
Then: `flutter test`
Expected: ALL pass.

- [ ] **Step 7: Commit**

```bash
git add lib/services/pdf_service_core.dart lib/services/pdf_service.dart test/pdf_service_core_test.dart
git commit -m "refactor: extract makeColorizedSpans and renderCacheKey into pdf_service_core"
```

---

### Task 8: `tibetan_segmenter.dart` light touch

Apply `const` to regexes, `switch` expressions where `if/else` exists in segment tagging.

**Files:**
- Modify: `lib/utils/tibetan_segmenter.dart`
- Test: existing `test/wylie_converter_test.dart` must stay green (if it covers segmenter); add no new tests unless behavior is unclear.

**Interfaces:**
- Consumes: existing functions.
- Produces: same signatures, internal style improvements only.

- [ ] **Step 1: Read current file fully**

Run: read `lib/utils/tibetan_segmenter.dart` (all 196 lines). Identify: regex declarations missing `const`, any `if/else` in `splitByRedHighlightRanges` segment tagging.

- [ ] **Step 2: Apply `const` to regexes**

Lines 3 and 7: `_splitPattern` and `_stripPattern` are already `final`. Change to `const` since `RegExp` literals are compile-time constants:

```dart
const _splitPattern = RegExp('[\u0F0B\u0F0C]');
const _stripPattern = RegExp('[\u0F0D-\u0F14\\s]');
```

- [ ] **Step 3: Convert segment-tagging if/else to switch expression**

In `splitByRedHighlightRanges` (lines 146-184), if there's an `if/else` deciding the `highlight` bool per segment, convert to a `switch` expression or keep as a `map` returning `({String text, bool highlight})`. Read the full function first to see the exact shape, then convert conditionals to switch expressions where a tag or enum is being tested. If the logic is a simple bool computation (not a type/tag test), leave it — YAGNI.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test`
Expected: ALL pass. No behavior change.

- [ ] **Step 5: Commit**

```bash
git add lib/utils/tibetan_segmenter.dart
git commit -m "refactor: const regexes and switch expressions in tibetan_segmenter"
```

---

### Task 9: Remaining utils — `const`/`fold` pass

Sweep `font_utils.dart`, `wylie_converter.dart`, `colors.dart`, `content_page_template_layout.dart`, `title_page_layout.dart`, `save_state_mixin.dart`.

**Files:**
- Modify: the six files above.
- Test: existing tests must stay green.

**Interfaces:** None new.

- [ ] **Step 1: Identify mutable loops**

For each file, search for `for (` and `var ` and `.add(`. Convert to `fold`/`map`/`where` where the pattern is accumulator+add. Add `const` to constructors and collections.

- [ ] **Step 2: Apply conversions file by file**

Work through each file. No code shown here because the conversions depend on what each file contains — the implementing agent reads each file, identifies the imperative patterns, and applies the fold/map/where equivalents following the principles in Section 1.

- [ ] **Step 3: Run tests after each file**

Run: `flutter test`
Expected: ALL pass after each file.

- [ ] **Step 4: Commit (one per file, or batched)**

```bash
git add lib/utils/font_utils.dart lib/utils/wylie_converter.dart lib/utils/colors.dart lib/utils/content_page_template_layout.dart lib/utils/title_page_layout.dart lib/utils/save_state_mixin.dart
git commit -m "refactor: fold/map/const pass over remaining utils"
```

---

### Task 10: Models — `const`/equality audit

Audit `MarginMm`, `TemplateInset`, `PageSetup`, `TextBlock`, `Project`, `block_update.dart` for `const` constructors and value equality.

**Files:**
- Modify: `lib/models/project.dart`, `lib/models/app_settings.dart`, `lib/models/block_update.dart`
- Test: `test/models_test.dart` (existing — extend if equality added)

**Interfaces:** None new.

- [ ] **Step 1: Audit const constructors**

`MarginMm` and `TemplateInset` already have `const` constructors. Verify `PageSetup`'s constructor can be `const` (it can't currently — it has `??` default initializers in the initializer list). Leave non-const where `??` defaults prevent it; don't restructure the constructor. `TextBlock` constructor — check if `const` is possible (it has no `??` in initializer list, so add `const`).

- [ ] **Step 2: Add value equality where missing**

`SystemFontInfo` has `==`/`hashCode`. Check `MarginMm`, `TemplateInset` — if they lack `==` and equality would aid testing, add it. But YAGNI: only add `==`/`hashCode` if a test or `fold` pipeline actually needs equality. Skip unless a concrete need exists.

- [ ] **Step 3: Run tests**

Run: `flutter test test/models_test.dart`
Then: `flutter test`
Expected: ALL pass.

- [ ] **Step 4: Commit**

```bash
git add lib/models/project.dart lib/models/block_update.dart
git commit -m "refactor: const/equality audit on models"
```

---

### Task 11: Widgets/pages — extract pure build helpers (largest files first)

Extract conditional widget trees from `sample_page.dart`, `block_editor.dart`, `editor_page.dart`, `title_page_settings_panel.dart`, `settings_page.dart` into top-level pure functions.

**Files:**
- Modify: the widget/page files above.
- Test: existing widget tests (`page_setup_widgets_test.dart`, `preview_zoom_widgets_test.dart`, `zoom_overflow_test.dart`) must stay green.

**Interfaces:** None new — extracted helpers are file-private (`_buildX`).

- [ ] **Step 1: For each large State class, identify the gnarliest `build` sub-method**

Read `sample_page.dart`, find the `build` method's conditional branches. Extract each branch into a top-level function `Widget _buildX(BuildContext context, {required Type input, ...})`.

- [ ] **Step 2: Extract helpers one file at a time**

Per file: identify 2-3 sub-builders worth extracting (the longest/most-branched). Move them to top-level functions taking explicit args (no `this._state`). The `_State.build` calls them.

- [ ] **Step 3: Run widget tests after each file**

Run: `flutter test`
Expected: ALL pass. Widget trees unchanged.

- [ ] **Step 4: Commit (one per file)**

```bash
git add lib/widgets/sample_page.dart
git commit -m "refactor: extract pure build helpers from sample_page"
```
Repeat per file.

---

### Task 12: Final verification pass

Confirm the whole refactor is clean and green.

- [ ] **Step 1: Run flutter analyze**

Run: `flutter analyze`
Expected: No issues.

- [ ] **Step 2: Run full test suite**

Run: `flutter test`
Expected: ALL tests pass (121 baseline + all new tests).

- [ ] **Step 3: Build the app**

Run: `flutter build macos`
Expected: Successful build. Confirms no runtime breakage from the refactor.

- [ ] **Step 4: Final commit if any cleanup**

```bash
git add -A
git commit -m "refactor: final cleanup after functional programming pass"
```

---

## Self-Review Notes

**Spec coverage check:**
- Section 1 (Principles): Tasks 1-4 (fold/const/sealed/switch), Task 5-7 (pure core), Task 8-9 (const/fold), Task 10 (const/equality). ✓
- Section 2 (`utils/` in-place): Tasks 1-4 (`sample_layout`), Task 8 (`tibetan_segmenter`), Task 9 (remaining utils). `text_renderer.dart` extraction is folded into Task 7's note. ✓
- Section 3 (`services/` core/shell): Task 5 (`font_service`), Task 6 (`database_service`), Task 7 (`pdf_service` core start). Remaining services (`title_page_template_service`, `html_export_service`, `batch_import_service`, `pronunciation_service`) are not given dedicated tasks — they're smaller and the spec says "leave pure-ish ones as-is." The implementing agent should assess these during Task 12 and add tasks if they have clear core/shell splits. Flagged.
- Section 4 (Models light touch): Task 10. ✓
- Section 5 (Widgets/pages): Task 11. ✓
- Section 6 (Error handling): records (`buildProjectQuery` returns `({String? where, List<Object> args})`) and sealed `FontLoadResult` — the sealed result type is described in the spec but not given a dedicated task. The `tryLoadPdfFont` pattern in Task 7's note covers the record form `({pw.Font? font, String? warning})`. Sealed `FontLoadResult` is a possible extension; the spec marks it as "where the error path is structural" — current code uses `UnsupportedFontError` exception which is adequate. Flagged as optional — not blocking.
- Section 6 (Testing): Each task has its `*_test.dart`. ✓
- Section 7 (Migration order): Tasks 1-12 follow the spec's order (sample_layout first, then font/database/pdf services, then segmenter, remaining utils, models, widgets, final pass). ✓

**Placeholder scan:** Task 9 (remaining utils) and Task 11 (widgets) are deliberately less detailed because they depend on per-file reading. This is acceptable for a sweep task but the implementing agent must read each file before editing. Task 7 has a genuine dependency (locate `TextSpanDef`) that's flagged as a step.

**Type consistency:** `BlockWidthEstimate` subtypes (`ImageWidth`/`ManualWidth`/`OpeningMarkWidth`/`TextWidth`) match between Task 1's test and implementation. `pickCjkFallbackFonts`/`resolveFontDirs`/`fontPriority`/`isTtc` match between Task 5's test and core. `buildProjectQuery`/`normalizeImportedBlocks`/`projectToRow`/`rowToProjectListItem` match between Task 6's test and core. `makeColorizedSpans`/`renderCacheKey` match between Task 7's test and core. ✓
