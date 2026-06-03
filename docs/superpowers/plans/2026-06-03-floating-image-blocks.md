# Floating Image Blocks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make image blocks free-floating — resizable, freely positionable anywhere on the page, rendered as an overlay layer on top of text content, with identical appearance in editor preview and exported PDF.

**Architecture:** Add position/size fields to `TextBlock`. Split rendering into two layers: a bottom layer for text flow (existing), and a top layer for floating images (new). Images excluded from flow pagination; each page tracks its own floating images via a new `PageLayout.floatImages` field. Preview (`sample_page.dart`) and PDF (`pdf_service.dart`) both render the stack. Editor gets drag-to-move and corner-resize handles on the preview.

**Tech Stack:** Flutter 3.x, Dart 3.x, sqflite, pdf package, uuid

---

## Architecture Decisions

1. **Floating flag**: `TextBlock.floatingImage` (default `false`). When `true`, the block is excluded from flow pagination. `imageXMm`/`imageYMm`/`imageWidthMm`/`imageHeightMm` control position and size in mm relative to page top-left.
2. **Page tracking**: `PageLayout` gains `List<TextBlock> floatingImages` — image blocks assigned to that page.
3. **Two-layer rendering**: Every page renders as a `Stack` — text content at bottom, floating images on top.
4. **DPI independence**: Positions stored in mm, converted to px at render time using `kMmToPx` (`3.78`).

---

## File Map

| File | Role |
|------|------|
| `lib/models/project.dart` | Add `floatingImage`, `imageWidthMm`, `imageHeightMm`, `imageXMm`, `imageYMm` to `TextBlock` |
| `lib/utils/sample_layout.dart` | Add `PageLayout.floatingImages`; modify `paginateBlocks` to collect float images per page and exclude them from flow rows |
| `lib/widgets/sample_page.dart` | Replace `Stack` in `_ContentGrid` with a two-layer stack — text below, float images above. Render each float image at its mm-based position. Add drag + resize handles when `selectedBlockId` matches. |
| `lib/widgets/sample_pages.dart` | No changes — delegates to `SamplePageWidget`. |
| `lib/services/pdf_service.dart` | Match the two-layer Stack in PDF output. Render float images using `pw.Positioned` at mm-based coordinates. |
| `lib/pages/editor_page.dart` | Add "Make Floating" toggle to block editor; forward mouse events for drag/resize on preview to update position/size fields. |
| `lib/widgets/block_editor.dart` | Add floating toggle + position/size fields. |

---

## Task 1: Model — Add floating image fields to TextBlock

**Files:**
- Modify: `lib/models/project.dart` (TextBlock section)

Add `floatingImage`, `imageWidthMm`, `imageHeightMm`, `imageXMm`, `imageYMm` fields. The existing `imagePath` field is kept — `imagePath` controls *what* to show, the new fields control *where* and *how big*.

- [ ] **Step 1: Add fields to TextBlock**

After `imagePath`:
```dart
  final bool floatingImage;
  final double? imageWidthMm;
  final double? imageHeightMm;
  final double? imageXMm;
  final double? imageYMm;
```

Add to constructor (defaults: `floatingImage = false`, others `null`).

- [ ] **Step 2: Add to copyWith**

```dart
  bool? floatingImage,
  double? imageWidthMm,
  double? imageHeightMm,
  double? imageXMm,
  double? imageYMm,
  bool clearImageWidthMm = false,
  bool clearImageHeightMm = false,
  bool clearImageXMm = false,
  bool clearImageYMm = false,
```

In the return:
```dart
  floatingImage: floatingImage ?? this.floatingImage,
  imageWidthMm: clearImageWidthMm ? null : (imageWidthMm ?? this.imageWidthMm),
  imageHeightMm: clearImageHeightMm ? null : (imageHeightMm ?? this.imageHeightMm),
  imageXMm: clearImageXMm ? null : (imageXMm ?? this.imageXMm),
  imageYMm: clearImageYMm ? null : (imageYMm ?? this.imageYMm),
```

- [ ] **Step 3: Add to toJson / fromJson**

```dart
// toJson
'floatingImage': floatingImage,
if (imageWidthMm != null) 'imageWidthMm': imageWidthMm,
if (imageHeightMm != null) 'imageHeightMm': imageHeightMm,
if (imageXMm != null) 'imageXMm': imageXMm,
if (imageYMm != null) 'imageYMm': imageYMm,

// fromJson
floatingImage: json['floatingImage'] as bool? ?? false,
imageWidthMm: (json['imageWidthMm'] as num?)?.toDouble(),
imageHeightMm: (json['imageHeightMm'] as num?)?.toDouble(),
imageXMm: (json['imageXMm'] as num?)?.toDouble(),
imageYMm: (json['imageYMm'] as num?)?.toDouble(),
```

- [ ] **Step 4: Write model serialization test**

Add to `test/models_test.dart`:
```dart
test('TextBlock floating image fields serialize round-trip', () {
  final block = TextBlock(
    id: 'img1',
    imagePath: '/tmp/foo.png',
    floatingImage: true,
    imageWidthMm: 50,
    imageHeightMm: 40,
    imageXMm: 10,
    imageYMm: 20,
  );
  final json = block.toJson();
  final restored = TextBlock.fromJson(json);
  expect(restored.imagePath, '/tmp/foo.png');
  expect(restored.floatingImage, true);
  expect(restored.imageWidthMm, 50);
  expect(restored.imageHeightMm, 40);
  expect(restored.imageXMm, 10);
  expect(restored.imageYMm, 20);
});
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/models_test.dart
```

Expected: all pass including new test.

- [ ] **Step 6: Commit**

```bash
git add lib/models/project.dart test/models_test.dart
git commit -m "feat: add floating image position/size fields to TextBlock"
```

---

## Task 2: Pagination — Exclude floating images from flow, track per page

**Files:**
- Modify: `lib/utils/sample_layout.dart` (paginateBlocks, PageLayout)

Floating images must NOT appear in flow rows. Instead, each `PageLayout` gets a `List<TextBlock> floatingImages` field. `paginateBlocks` assigns float images to the page they would have appeared on based on their index.

- [ ] **Step 1: Add floatingImages to PageLayout**

```dart
class PageLayout {
  final List<_Row> rows;
  final List<List<LayoutCell>> flowRows;
  final int colCount;
  final List<TextBlock> floatingImages;

  PageLayout({
    required this.rows,
    required this.flowRows,
    required this.colCount,
    this.floatingImages = const [],
  });
}
```

- [ ] **Step 2: Modify _buildRows to skip floating images**

In `_buildRows`, before the main for-loop:
```dart
  for (final block in blocks) {
    if (block.floatingImage) continue;  // skip float images in flow
    // ... rest unchanged
  }
```

- [ ] **Step 3: Modify paginateBlocks to assign float images to pages**

After building `pages` from rows, iterate through all blocks, collect float images, and assign them by index proportion:

```dart
  // Collect floating images
  final floatImages = blocks.where((b) => b.floatingImage).toList();
  if (floatImages.isNotEmpty && pages.isNotEmpty) {
    // Assign each float image to the page it's nearest to (by original index proportion)
    for (final fi in floatImages) {
      final fiIdx = blocks.indexOf(fi);
      // Map block index to page index
      final int pageCount = pages.length;
      // Count non-floating blocks per page
      var acc = 0;
      var assignedPage = 0;
      for (var pi = 0; pi < pageCount; pi++) {
        final pageBlockCount = pages[pi].flowRows
            .expand((r) => r)
            .length;
        if (fiIdx < acc + pageBlockCount + pi) { // +pi for the float blocks skipped
          assignedPage = pi;
          break;
        }
        acc += pageBlockCount;
        assignedPage = pi;
      }
      final clamped = assignedPage.clamp(0, pages.length - 1);
      pages[clamped] = PageLayout(
        rows: pages[clamped].rows,
        flowRows: pages[clamped].flowRows,
        colCount: pages[clamped].colCount,
        floatingImages: [...pages[clamped].floatingImages, fi],
      );
    }
  }
```

- [ ] **Step 4: Write test for float image exclusion**

Add to `test/pagination_test.dart`:
```dart
test('floating image blocks are excluded from flow rows', () {
  final blocks = [
    TextBlock(id: 'txt', tibetan: 'text'),
    TextBlock(id: 'img', imagePath: '/tmp/x.png', floatingImage: true),
    TextBlock(id: 'txt2', tibetan: 'more text'),
  ];
  final pages = paginateBlocks(blocks, 0, 4, 0.01);
  // Only 2 text blocks in flow
  var totalText = 0;
  for (final page in pages) {
    for (final row in page.flowRows) {
      totalText += row.length;
    }
  }
  expect(totalText, 2);
  // Floating image should be in floatingImages
  expect(pages[0].floatingImages.length, 1);
});
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/pagination_test.dart
```

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add lib/utils/sample_layout.dart test/pagination_test.dart
git commit -m "feat: exclude floating images from flow pagination, track per page"
```

---

## Task 3: Preview — Two-layer Stack rendering

**Files:**
- Modify: `lib/widgets/sample_page.dart` (_ContentGrid.build)

The `_ContentGrid.build` method currently returns a `Stack` with text-only children. Replace with a two-layer approach: draw text blocks in the existing loop, then add floating images as additional `Positioned` children on top.

- [ ] **Step 1: After the text block loop, add float image children**

After `children.add(...)` for all flow blocks, iterate `page.floatingImages`:

```dart
    // ---- Floating image overlay ----
    for (final fi in page.floatingImages) {
      final imgX = (fi.imageXMm ?? 10) * kMmToPx;
      final imgY = (fi.imageYMm ?? 10) * kMmToPx;
      final imgW = (fi.imageWidthMm ?? 30) * kMmToPx;
      final imgH = (fi.imageHeightMm ?? 30) * kMmToPx;
      final isSelected = fi.id == selectedBlockId;

      children.add(
        Positioned(
          left: imgX,
          top: imgY,
          width: imgW,
          height: imgH,
          child: GestureDetector(
            onTap: () => onSelect?.call(fi.id), // need to add onSelect to _ContentGrid
            child: Container(
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(color: AppColors.sky500, width: 2),
                      borderRadius: BorderRadius.circular(2),
                    )
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: fi.imagePath != null && File(fi.imagePath!).existsSync()
                    ? Image.file(
                        File(fi.imagePath!),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.broken_image, size: 16, color: AppColors.textFaint),
                      )
                    : Icon(Icons.image, size: 16, color: AppColors.textFaint),
              ),
            ),
          ),
        ),
      );
    }
```

- [ ] **Step 2: Pass floatingImages through SamplePageWidget**

`SamplePageWidget` already receives `rows` and `flowRows`. Add `floatingImages`:

```dart
class SamplePageWidget extends StatelessWidget {
  // ... existing fields ...
  final List<TextBlock> floatingImages;

  const SamplePageWidget({
    // ... existing params ...
    this.floatingImages = const [],
  });
```

Pass to `_ContentGrid`:
```dart
  floatingImages: floatingImages,
```

- [ ] **Step 3: Update SamplePagesWidget to pass floatingImages**

In `sample_pages.dart:42-55`, pass `pages[index].floatingImages`:
```dart
  SamplePageWidget(
    // ... existing params ...
    floatingImages: pages[index].floatingImages,
  ),
```

- [ ] **Step 4: Update EditorPage to pass floatingImages**

In `editor_page.dart` where `SamplePageWidget` is constructed (~line 807), pass:
```dart
  floatingImages: pageData.page.floatingImages,
```

Also update `_PageWithBlocks` to carry `floatingImages`:
```dart
class _PageWithBlocks {
  final PageLayout page;
  final List<TextBlock> blocks;
  const _PageWithBlocks({required this.page, required this.blocks});
}
```

In `_pagesWithBlocks` getter, the `PageLayout` already carries `floatingImages` (from Task 2 changes), so no extra mapping needed — just read `pageData.page.floatingImages`.

- [ ] **Step 5: Write widget test for float image in preview**

Add to `test/widget_test.dart`:
```dart
testWidgets('floating image renders in preview', (tester) async {
  final project = Project(
    id: 'test',
    name: 'Test',
    updatedAt: '',
    createdAt: '',
    blocks: [
      TextBlock(id: 'txt', tibetan: 'text'),
      TextBlock(
        id: 'img',
        imagePath: '/nonexistent.png',
        floatingImage: true,
        imageXMm: 10,
        imageYMm: 10,
        imageWidthMm: 30,
        imageHeightMm: 30,
      ),
    ],
  );
  // Build SamplePageWidget and verify floating image is rendered
  // (limited test since Image.file needs real filesystem)
  final pages = paginateBlocks(project.blocks, 0, 4, project.pageSetup.flowGap);
  expect(pages[0].floatingImages.length, 1);
});
```

- [ ] **Step 6: Run tests**

```bash
flutter test test/widget_test.dart test/pagination_test.dart
```

Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/sample_page.dart lib/widgets/sample_pages.dart lib/pages/editor_page.dart test/widget_test.dart
git commit -m "feat: render floating images as overlay layer in preview"
```

---

## Task 4: PDF — Two-layer Stack rendering

**Files:**
- Modify: `lib/services/pdf_service.dart` (_buildContentPage)

Match the two-layer approach from the preview. In the PDF content page builder, after rendering all flow blocks, add floating images as `pw.Positioned` widgets.

- [ ] **Step 1: Add float image rendering after flow block loop**

After the positioned flow block loop (after `positioned.add(...)` for text blocks), add:

```dart
    // ---- Floating image overlay ----
    for (final fi in page.floatingImages) {
      final imgX = (fi.imageXMm ?? 10) * mmToPt;
      final imgY = (fi.imageYMm ?? 10) * mmToPt;
      final imgW = (fi.imageWidthMm ?? 30) * mmToPt;
      final imgH = (fi.imageHeightMm ?? 30) * mmToPt;

      if (fi.imagePath != null) {
        final file = File(fi.imagePath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          positioned.add(
            pw.Positioned(
              left: imgX,
              top: imgY,
              child: pw.SizedBox(
                width: imgW,
                height: imgH,
                child: pw.ClipRRect(
                  horizontalRadius: 2,
                  verticalRadius: 2,
                  child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
                ),
              ),
            ),
          );
        }
      }
    }
```

Note: `mmToPt` is ~`2.8346` (72/25.4). The existing code uses `_mmToPt` or similar. Use the same constant already in the file.

- [ ] **Step 2: Filter float images from text rendering**

In the text block rendering loop that calls `_render` (Task 2 already excluded float images from `paginateBlocks` return, but verify that the `_render` loop at ~line 269 skips them via the `if (block.isImageBlock && !block.floatingImage)` check — or just rely on `paginateBlocks` already excluding them). No changes needed here if Task 2 is correct.

- [ ] **Step 3: Run analyze**

```bash
flutter analyze lib/services/pdf_service.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/services/pdf_service.dart
git commit -m "feat: render floating images as overlay in PDF export"
```

---

## Task 5: Editor — Drag and resize floating images

**Files:**
- Modify: `lib/pages/editor_page.dart`
- Modify: `lib/widgets/block_editor.dart`

Add a "Floating" toggle to the block editor. When enabled, show position (X, Y mm) and size (W, H mm) fields. On the preview, floating images can be dragged to reposition (updating `imageXMm`/`imageYMm`) and have a corner handle for resize (updating `imageWidthMm`/`imageHeightMm`).

- [ ] **Step 1: Add floating toggle and fields to BlockEditorWidget**

In `block_editor.dart`, after the existing block format controls, add:

```dart
  if (selectedBlock.isImageBlock) ...[
    const SizedBox(height: 12),
    Row(
      children: [
        const Text('Floating'),
        const SizedBox(width: 8),
        Switch(
          value: selectedBlock.floatingImage,
          onChanged: (v) => onUpdate(BlockUpdate(floatingImage: v)),
        ),
      ],
    ),
    if (selectedBlock.floatingImage) ...[
      const SizedBox(height: 8),
      Row(
        children: [
          _MmField(label: 'X', value: selectedBlock.imageXMm, onChanged: (v) => onUpdate(BlockUpdate(imageXMm: v))),
          const SizedBox(width: 8),
          _MmField(label: 'Y', value: selectedBlock.imageYMm, onChanged: (v) => onUpdate(BlockUpdate(imageYMm: v))),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          _MmField(label: 'W', value: selectedBlock.imageWidthMm, onChanged: (v) => onUpdate(BlockUpdate(imageWidthMm: v))),
          const SizedBox(width: 8),
          _MmField(label: 'H', value: selectedBlock.imageHeightMm, onChanged: (v) => onUpdate(BlockUpdate(imageHeightMm: v))),
        ],
      ),
    ],
  ],
```

Add `floatingImage`, `imageXMm`, `imageYMm`, `imageWidthMm`, `imageHeightMm` to `BlockUpdate` model.

- [ ] **Step 2: Add drag handling on preview for floating images**

In `sample_page.dart`, wrap the float image `Positioned` child with a `GestureDetector` that handles `onPanUpdate`:

```dart
  GestureDetector(
    onPanUpdate: (details) {
      if (onFloatImageMove != null) {
        onFloatImageMove!(fi.id, details.delta.dx / kMmToPx, details.delta.dy / kMmToPx);
      }
    },
    child: // ... existing image widget ...
  ),
```

Add `onFloatImageMove` callback to `_ContentGrid` and `SamplePageWidget`. Wire it in `EditorPage` to call a method that updates `imageXMm`/`imageYMm` via `_updateBlock`.

- [ ] **Step 3: Add resize handle**

Add a small draggable corner handle on the bottom-right of selected floating images:

```dart
  if (isSelected)
    Positioned(
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onPanUpdate: (details) {
          if (onFloatImageResize != null) {
            onFloatImageResize!(fi.id, details.delta.dx / kMmToPx, details.delta.dy / kMmToPx);
          }
        },
        child: Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: AppColors.sky500,
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Icon(Icons.drag_handle, size: 8, color: Colors.white),
        ),
      ),
    ),
```

Wire `onFloatImageResize` in editor page similarly.

- [ ] **Step 4: Add _onFloatImageMove and _onFloatImageResize to EditorPage**

```dart
  void _onFloatImageMove(String blockId, double dxMm, double dyMm) {
    final block = _project?.blocks.firstWhere((b) => b.id == blockId);
    if (block == null) return;
    final newX = (block.imageXMm ?? 0) + dxMm;
    final newY = (block.imageYMm ?? 0) + dyMm;
    _undoService.pushState(_project!);
    _updateBlock(BlockUpdate(imageXMm: newX, imageYMm: newY));
  }

  void _onFloatImageResize(String blockId, double dwMm, double dhMm) {
    final block = _project?.blocks.firstWhere((b) => b.id == blockId);
    if (block == null) return;
    final newW = ((block.imageWidthMm ?? 30) + dwMm).clamp(10, 300);
    final newH = ((block.imageHeightMm ?? 30) + dhMm).clamp(10, 300);
    _undoService.pushState(_project!);
    _updateBlock(BlockUpdate(imageWidthMm: newW, imageHeightMm: newH));
  }
```

- [ ] **Step 5: Wire callbacks through SamplePageWidget**

Add to `SamplePageWidget`:
```dart
  final void Function(String id, double dxMm, double dyMm)? onFloatImageMove;
  final void Function(String id, double dwMm, double dhMm)? onFloatImageResize;
```

Pass from `EditorPage` -> `SamplePageWidget` -> `_ContentGrid`.

- [ ] **Step 6: Run analyze and tests**

```bash
flutter analyze
flutter test
```

- [ ] **Step 7: Commit**

```bash
git add lib/pages/editor_page.dart lib/widgets/block_editor.dart lib/widgets/sample_page.dart lib/models/block_update.dart
git commit -m "feat: add drag-move and resize for floating images in editor"
```

---

## Task 6: Integration — Ensure consistent mm-to-px conversion

**Files:**
- Modify: `lib/widgets/sample_page.dart` (ensure kMmToPx used consistently)
- Modify: `lib/services/pdf_service.dart` (ensure mmToPt used consistently)

- [ ] **Step 1: Verify kMmToPx is used for all mm→px in preview**

`lib/widgets/sample_page.dart` already has `const double kMmToPx = 3.78;`. Ensure float image positions use it.

- [ ] **Step 2: Verify mm→Pt conversion in PDF**

The PDF service uses `_mmToPt` function or similar. Find the correct conversion constant and use it for float image positions. Typically: `mm * 72 / 25.4` ≈ `mm * 2.8346`.

- [ ] **Step 3: Verify existing page dimension usage**

The existing code already uses mm→pt for page margins. Float image positions should use the same coordinate system.

- [ ] **Step 4: Commit**

```bash
git commit -m "fix: ensure consistent mm-to-px conversion for float images"
```

---

## Verification

After completing all tasks:

- [ ] `flutter analyze` — no errors
- [ ] `flutter test` — all tests pass
- [ ] Manual smoke test:
  - Add a floating image block
  - Verify it renders in preview at the specified mm position
  - Drag image in preview — verify position updates in block editor fields
  - Resize image via corner handle — verify size updates
  - Export PDF — verify image appears at same position/size as preview
  - Verify text flow is NOT disrupted by floating images
