# Release Notes

## [1.1.18] - 2026-11-11

### 🔐 macOS Distribution
- macOS releases are now signed with a Developer ID Application certificate and notarized by Apple. The DMG is stapled, so Gatekeeper accepts it without the unidentified-developer warning.
- CI imports the certificate into a temporary keychain, signs the app with hardened runtime and the release entitlements, signs the DMG, and submits it to `notarytool`.

### 📄 Included Fixes
- The v1.1.17 PDF fixes are included: the left vertical title uses the project Chinese title, and rotated side titles stay on one line.

### 🔧 Maintenance
- Release workflow upgraded to `softprops/action-gh-release@v2`; macOS signing secrets are documented in `RELEASE_GUIDE.md`.

---

## [1.1.17] - 2026-11-10

### 🐛 Fixes
- **Left vertical title uses the project Chinese title** — the Export PDF → Page Setup field now reads and writes `PageSetup.titleChinese` instead of a separate value, so the preview and PDF side panels show the project title. Existing `leftVerticalTitle` values are migrated into `titleChinese` when a project is loaded.
- **Side title stays on one line** — the PDF side panel now lays rotated text out unconstrained with an explicit page-height width. A 12-character Chinese title renders as a single vertical line instead of wrapping into two columns; the preview already behaved this way.

### 🔧 Maintenance
- Added model migration and export-panel binding tests (246 tests total).

---

## [1.1.16] - 2026-11-09

### ✨ New Features
- **Template previews** — the Templates page now shows a responsive card grid with live SVG previews, names, rename-on-tap, and delete actions
- **Row-line Y offset** — Page Setup exposes a signed offset field next to “Show row lines”; preview and PDF place the yellow line at the configured position and hide the field when row lines are off
- **Font preview** — the font picker previews the hovered/focused font with a Tibetan and CJK/Latin sample
- **Compact settings** — the settings form uses a 760 px column with a sticky save bar and status, compact font rows, inline page-size labels, and a two-column Language & theme section
- **Compact dictionary** — pronunciation entries appear in a responsive three-column, one-line grid
- **Title-page text first** — the Tibetan/Chinese title text and spacing fields now sit directly below the template picker
- **Side-by-side font rows** — the title font rows share a line above 1180 px; project font rows share a line above 1280 px, otherwise stack
- **Theme-aware window chrome** — the macOS title bar follows the app’s Light/Dark/System theme
- **Sky sidebar selection** — navigation uses Material icons and the sky accent

### 🐛 Fixes
- PDF red highlights now keep vowel signs, shad, and punctuation black while consonants and tshegs stay red, matching the preview
- Preview text falls back through system fonts for missing glyphs, and PDF export renders rare runes (e.g. U+27593) through HarfBuzz shaping when no embeddable font covers them
- The exported content pages match the preview’s content-box height

### 🔧 Maintenance
- Added widget tests for the row-line offset control and font-fallback chain
- `harfbuzz_ffi` 0.5.1

---

## [1.1.15] - 2026-11-08

### ✨ New Features
- **Red opening mark** — opening-mark blocks now have a **Red opening mark** checkbox that renders the whole mark (including shad punctuation) in red in both preview and PDF; the range-based highlight remains available for partial red

### 🐛 Fixes
- PDF red highlight now colors only the main syllable structure: base consonants and tshegs are red, while vowel signs, shad, and punctuation stay black, matching the preview

### 🔧 Maintenance
- Bumped `harfbuzz_ffi` to 0.5.1 (native HarfBuzz build)

---

## [1.1.14] - 2026-11-08

### ✨ New Features
- **Workspace sidebar** — Projects, Dictionary, Templates, and Settings destinations plus a recent-projects list, all in one workspace shell
- **Templates page** — title-page templates now have their own page instead of living inside Settings
- **Tibetan–Chinese spacing** — configurable gap for the title page and content text, in px; negative values overlap the lines

### 🖨️ PDF
- Tibetan is now embedded as **shaped vector glyph outlines** (HarfBuzz) with an invisible Unicode text layer, replacing the previous 460 DPI raster pipeline
- Glyph form XObjects use a `[0 0 width height]` BBox so outlines with negative coordinates (e.g. Kailasa combining marks) are not squeezed
- All text renders natively; invisible text state is isolated per run
- Exported content pages match the preview's content-box height
- Tibetan rasters keep bottom padding so descenders (e.g. the ུ in ཧཱུྃ) are not clipped

### 🎛️ UI
- Editor settings panels are denser: margins side-by-side, template thumbnails, single-line font rows, two-column content sections
- Font size fields now create an override from the effective default when edited
- `FontPicker` accepts a placeholder and skips the empty label line

### 🔧 Maintenance
- Migrated `file_picker` call sites to the v13 API
- Refreshed READMEs (English and Traditional Chinese) with new screenshots
- Added `.agents/` to `.gitignore`

---

## [1.1.3] - 2026-02-22

### 🎨 Assets
- Added application icon (`assets/images/icon.png`) for macOS and Windows builds
- Icon now displayed in README headers

---

## [1.1.2] - 2026-02-22

### 📖 Documentation
- Added version number to README headers
- Updated README (English & Traditional Chinese) with pronunciation dictionary screenshots and multi-character pronunciation feature

---

## [1.1.1] - 2026-02-22

### ✨ New Features

#### Pronunciation Dictionary
- **Local syllable-level pronunciation dictionary** — automatically maps Tibetan syllables to Chinese pronunciations using a local SQLite database
- **Auto-fill** — pronunciation field fills automatically as you type Tibetan text; unknown syllables appear as `X`
- **Auto-save** — typing a pronunciation in the editor saves it to the dictionary immediately
- **Multi-character pronunciation support** — special/abbreviated syllables (e.g. པདྨ) can be configured to span 2 or more Chinese characters via a stepper in the edit dialog; a `×N` badge appears on the entry card
- **Dictionary management page** — searchable list of all entries with inline edit and delete
- **Export / Import** — save and load the full dictionary as JSON for sharing between devices

---

## [1.0.1] - 2026-02-21

### 🎨 Improved

#### Light Theme Overhaul
- **Complete light theme redesign** with proper color contrast and readability
- Added semantic theme-aware color system that automatically adapts to light/dark modes
- All UI components now properly support both light and dark themes:
  - Project list and cards
  - Editor interface and text fields
  - Block strip and block editor
  - Font picker dialog
  - Settings dialog
  - Export/PDF preview page
  - All dialogs and modals

#### Technical Improvements
- Introduced 15 semantic color properties in `AppColors` class:
  - Text colors: `textPrimary`, `textSecondary`, `textBody`, `textCaption`, `textMuted`, `textFaint`
  - Surface colors: `surface`, `surfaceContainer`, `inputFill`
  - Border colors: `border`, `borderSubtle`, `divider`
  - Button colors: `buttonMutedBg`, `buttonMutedFg`
- Colors automatically switch based on theme brightness
- Eliminated hardcoded dark-only color values throughout the codebase
- Light theme now uses:
  - White/light gray backgrounds
  - Dark text for optimal readability
  - Subtle borders and dividers
  - Appropriate contrast ratios

### 🐛 Fixed
- Light theme no longer shows dark backgrounds with light text
- Input fields are now properly visible in light mode
- Dialogs and modals have correct backgrounds in light mode
- All text is now readable in light mode

---

## Previous Releases

See git history for earlier changes.
