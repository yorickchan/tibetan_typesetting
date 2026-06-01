# Editor Page Setup And Zoom Design

## Goal

Move document geometry and frame controls from the PDF export screen into the
editor, keep sentence spacing in the editor only, and add shared zoom controls
for editor page previews.

## Editor Page Setup

Add a grouped `Page Setup` card to the editor near the existing title, font, and
sentence-spacing panels. The card contains:

- Page width in millimeters
- Page height in millimeters
- Top, bottom, left, and right margins in millimeters
- `Show frame`

These are persisted document settings. Each change updates `PageSetup` through
the editor's existing autosave path.

Sentence spacing remains in the existing editor `FlowSpacingPanel`. It is not
part of the new grouped card.

## Editor Preview Zoom

Add one shared zoom toolbar outside the grouped `Page Setup` card and above the
editor page-preview list. It contains:

- Zoom out
- Current percentage
- Zoom in
- Reset to 100%

Zoom scales page previews only. Title, font, page setup, sentence-spacing, block
strip, and block editor controls remain at their normal size. The same transient
zoom value applies to every editor page preview. Zoom is UI state and is not
saved into `PageSetup`.

The editor should use the same range and increments as the export preview:
20%-300% in 10% steps.

## PDF Export Page

Remove these controls from PDF export:

- Sentence spacing
- Page width
- Page height
- Top, bottom, left, and right margins
- `Show frame`

Keep these controls in PDF export:

- `Left vertical title`
- `Page number`

The export page continues to provide PDF preview zoom and the PDF export action.
Changes to its remaining settings continue to persist immediately through the
existing save path.

## Components

Create an editor-focused page-setup panel widget that receives `PageSetup`,
localized labels, and the editor's setup updater callback. Keep margin updates
inside that widget so `EditorPage` remains responsible for state ownership and
autosave while the panel owns form presentation.

Create a reusable preview zoom toolbar widget for the minus, percentage, plus,
and reset controls. Use it in the editor and export preview areas so both screens
present the same zoom controls without duplicating UI code. Each page retains
its own transient zoom state and callbacks.

## Validation

Widget tests should verify:

- The editor page-setup panel exposes geometry and frame controls and emits
  updated `PageSetup` values.
- The reusable zoom toolbar invokes zoom out, zoom in, and reset callbacks and
  displays the current percentage.
- The export page settings area no longer contains sentence spacing, geometry,
  margins, or frame controls and still contains vertical title and page number.

Run `flutter test` and `flutter analyze` after implementation.
