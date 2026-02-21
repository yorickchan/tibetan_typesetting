# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tibetan Typesetting is a Flutter desktop application for creating and exporting Tibetan text documents with Chinese translations in a traditional layout format.

## Key Commands

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run

# Analyze code
flutter analyze

# Run tests
flutter test

# Build for release
flutter build macos    # macOS
flutter build windows  # Windows
flutter build linux    # Linux
```

## Architecture

### Directory Structure
```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── project.dart             # Project, TextBlock, PageSetup, MarginMm
│   ├── app_settings.dart        # Application settings
│   └── font_config.dart         # Font configuration
├── pages/
│   ├── projects_page.dart       # Project list/management
│   ├── editor_page.dart         # Main text editor
│   ├── export_page.dart         # PDF export with preview
│   └── settings_page.dart       # App settings
├── services/
│   ├── database_service.dart    # SQLite persistence (singleton)
│   ├── pdf_service.dart         # PDF generation (singleton)
│   ├── font_service.dart        # System font discovery (singleton)
│   └── settings_service.dart     # Settings persistence (singleton)
├── utils/
│   ├── colors.dart              # App color palette
│   ├── sample_layout.dart       # Pagination logic
│   ├── text_renderer.dart       # Rasterize text to PNG via Flutter
│   └── font_utils.dart          # Font utilities (TTC extraction)
└── widgets/
    ├── app_shell.dart           # Common scaffold
    ├── block_editor.dart        # TextBlock editor panel
    ├── block_strip.dart         # Block navigation strip
    ├── font_picker.dart         # Font selection widget
    ├── sample_page.dart         # Single page preview
    ├── sample_pages.dart        # Multi-page preview for export
    └── title_page_widget.dart   # Title page preview
```

### Data Model

- **Project**: Container for a document with name, tags, blocks, and page setup
- **TextBlock**: Unit of content with:
  - `tibetan`: Main Tibetan text (first line = heading, rest = body)
  - `chinesePronunciation`: Phonetic transcription
  - `chineseTranslation`: Translation
  - Flags: `pageBreakBefore`, `columnBreakBefore`, `smallText`
- **PageSetup**: Page dimensions, margins, columns, title page config
- **MarginMm**: Margins in millimeters

### Services

**DatabaseService** (`lib/services/database_service.dart`):
- Singleton SQLite database
- Stores full project as JSON blob + separate columns for indexing
- Methods: `listProjects`, `createProject`, `getProject`, `updateProject`, `deleteProject`, `duplicateProject`, `importProject`

**PdfService** (`lib/services/pdf_service.dart`):
- Singleton PDF generator using the `pdf` package
- Critical: Tibetan requires OpenType GSUB/GPOS features not supported by the pdf package
- **Workaround**: Pre-renders all Tibetan text to PNG using Flutter's text engine via `renderTextToPng()`
- Includes TTC (TrueType Collection) extractor to get TTF from STHeiti fonts
- Two-pass: first pre-render all text images, then build PDF pages

**FontService** (`lib/services/font_service.dart`):
- Singleton for system font discovery
- Methods: `listFonts`, `getFontFile`, `getTibetanFonts`, `getChineseFonts`

**SettingsService** (`lib/services/settings_service.dart`):
- Singleton for application settings persistence
- Stores font preferences, window size, recent projects

### Page Flow

1. **ProjectsPage** → Create/select project
2. **EditorPage** → Edit text blocks with live preview
3. **ExportPage** → Configure page setup, preview, export/print PDF
4. **SettingsPage** → Configure fonts and app preferences

### Key Utilities

**sample_layout.dart**:
- `paginateBlocks()`: Splits TextBlock list into pages with rows/columns
- `blocksToRows()`: Organizes blocks into rows for a given column count
- Handles `pageBreakBefore` and `columnBreakBefore` flags

**text_renderer.dart**:
- `renderTextToPng()`: Uses `TextPainter` + `PictureRecorder` to rasterize text at 4x scale (~288 DPI)
- Returns PNG bytes + dimensions

**font_utils.dart**:
- TTC (TrueType Collection) file extraction
- Methods to extract individual TTF fonts from .ttc files

### Styling

- Dark theme with slate/sky color scheme (see `lib/utils/colors.dart`)
- Tibetan font: BabelStoneTibetan (or other Tibetan Unicode fonts)
- Chinese font: STHeiti (from .ttc files, typically on macOS)

## Important Implementation Notes

### Tibetan Text Rendering

The pdf package cannot properly render Tibetan script (needs complex OpenType shaping). The solution:
1. All Tibetan text is pre-rendered to PNG images using Flutter's `TextPainter`
2. Images are embedded in the PDF
3. See `PdfService._render()` and `renderTextToPng()`

### Auto-Save

Editor uses debounced save (800ms delay after last edit) via `_bumpSave()` → `_saveCurrent()`

### Page Layout

- Default: 300mm × 120mm (landscape, traditional Tibetan text format)
- 4 rows per page, configurable columns (1-8)
- Content area with side panels for vertical text and page numbers

### Keyboard Shortcuts

- `Ctrl+N`: Add new block
- `Ctrl+S`: Save project
- `Delete`: Delete selected block
- `Alt+Up/Down`: Move block up/down

### Internationalization

- Supports English (en), Chinese Simplified (zh), and Chinese Traditional (zh_TW)
- Localization files in `lib/l10n/app_*.arb`
- Use `AppLocalizations.of(context)` to get translated strings
