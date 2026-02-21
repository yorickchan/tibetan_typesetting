# Tibetan Typesetting

[繁體中文](README.zh-TW.md) | English

A Flutter desktop application for creating and exporting Tibetan text documents with Chinese translations in a traditional layout format.

![Main Screen](screenshot/main%20screen.png)

## Features

### 📝 Rich Text Editing
- Create and manage multiple Tibetan text projects
- Organize content into blocks with:
  - Tibetan text (with heading support)
  - Chinese pronunciation (phonetic transcription)
  - Chinese translation
- Visual block navigation and management
- Auto-save functionality

### 🔤 Pronunciation Dictionary
- Local syllable-level Tibetan-to-Chinese pronunciation dictionary
- Auto-fills Chinese pronunciation as you type Tibetan text
- Unknown syllables are highlighted in yellow in the Tibetan field and shown as `X` in the pronunciation field
- Pronunciation entries are auto-saved to the dictionary when you type
- Dictionary management page with search, edit, and delete
- Export and import dictionary as JSON for sharing

![Edit Screen](screenshot/edit%20screen.png)

### 📄 Traditional Layout
- Traditional Tibetan book layout (landscape orientation)
- Configurable page dimensions and margins
- Multi-column layout support (1-8 columns)
- Page and column break controls
- Custom title page with Dharma Wheel symbol
- Flexible text sizing options

### 🖨️ PDF Export
- High-quality PDF generation with proper Tibetan script rendering
- Live preview before export
- Print directly from the app
- Share or save PDF files
- Proper handling of complex Tibetan OpenType features

![Export PDF](screenshot/export%20pdf.png)

## Technical Highlights

### Tibetan Script Rendering
The application uses a sophisticated approach to handle Tibetan script rendering in PDFs:
- Pre-renders Tibetan text using Flutter's native text engine
- Converts text to high-resolution PNG images (288 DPI)
- Embeds images in PDF to preserve complex OpenType shaping
- This workaround ensures perfect Tibetan script display, which standard PDF text rendering cannot achieve

### Data Persistence
- SQLite database for reliable local storage
- Projects stored as JSON with indexed metadata
- Support for project import/export
- Project duplication and tagging

## Getting Started

### Prerequisites
- Flutter SDK (^3.11.0)
- Desktop platform support (macOS, Windows, or Linux)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd tibetan_typesetting
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

### Font Requirements

The application uses system fonts:
- **Tibetan**: BabelStoneTibetan (or other Tibetan Unicode fonts)
- **Chinese**: STHeiti (typically pre-installed on macOS)

Make sure these fonts are installed on your system for proper text rendering.

## Usage

1. **Create a Project**: Start from the main screen by creating a new project
2. **Add Content**: Add text blocks with Tibetan text, pronunciation, and translation
3. **Pronunciation Auto-fill**: The editor auto-fills pronunciation from the dictionary as you type; unknown syllables are highlighted and shown as `X`
4. **Edit Layout**: Configure page setup, margins, and column count
5. **Preview**: View live preview of your document layout
6. **Export**: Generate PDF or print directly from the app
7. **Manage Dictionary**: Open the Pronunciation Dictionary page to view, search, edit, or delete saved syllable entries and export/import the dictionary as JSON

## Project Structure

```
lib/
├── main.dart                    # Application entry point
├── models/                      # Data models
│   ├── project.dart            # Project, TextBlock, PageSetup
│   ├── app_settings.dart       # Application settings
│   ├── font_config.dart        # Font configuration
│   └── pronunciation_entry.dart # Pronunciation dictionary entry
├── pages/                       # Main application pages
│   ├── projects_page.dart      # Project management
│   ├── editor_page.dart        # Text editor
│   ├── export_page.dart        # PDF export and preview
│   ├── settings_page.dart      # Application settings
│   └── dictionary_page.dart    # Pronunciation dictionary management
├── services/                    # Business logic
│   ├── database_service.dart   # SQLite persistence
│   ├── pdf_service.dart        # PDF generation
│   ├── font_service.dart       # Font management
│   ├── settings_service.dart   # Settings management
│   └── pronunciation_service.dart # Pronunciation dictionary CRUD
├── utils/                       # Utilities
│   ├── colors.dart             # Color palette
│   ├── sample_layout.dart      # Pagination logic
│   ├── text_renderer.dart      # Text to image rendering
│   ├── font_utils.dart         # Font utilities
│   └── tibetan_segmenter.dart  # Tsheg-based syllable extraction
└── widgets/                     # Reusable UI components
    ├── app_shell.dart          # Common scaffold
    ├── block_editor.dart       # Block editing panel
    ├── block_strip.dart        # Block navigation
    ├── font_picker.dart        # Font selection widget
    ├── sample_page.dart        # Page preview
    ├── sample_pages.dart       # Multi-page preview
    └── title_page_widget.dart  # Title page preview
```

## Development

### Code Analysis
```bash
flutter analyze
```

### Running Tests
```bash
flutter test
```

### Building for Release

**macOS:**
```bash
flutter build macos
```

**Windows:**
```bash
flutter build windows
```

**Linux:**
```bash
flutter build linux
```

## Architecture

### Key Components

- **DatabaseService**: Singleton managing SQLite operations for project persistence
- **PdfService**: Singleton handling PDF generation with Tibetan text pre-rendering
- **FontService**: System font discovery and management
- **SettingsService**: Application settings persistence
- **PronunciationService**: Singleton CRUD service for the local pronunciation dictionary
- **TibetanSegmenter**: Utility for splitting Tibetan text into syllables by tsheg (་)

### Page Layout Algorithm

The `sample_layout.dart` utility implements a two-pass pagination system:
1. Organizes blocks into rows based on column count
2. Distributes rows across pages respecting break flags
3. Handles page and column break controls

### Text Rendering Pipeline

1. Text input → `TextPainter` (Flutter's text engine)
2. Render to `Picture` at 4x scale for high DPI
3. Convert to PNG bytes
4. Embed in PDF as image

This approach ensures perfect Tibetan script rendering with proper OpenType feature support (GSUB/GPOS).

## License

This project is licensed under the GNU General Public License v2.0 - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Uses [BabelStoneTibetan](https://www.babelstone.co.uk/Fonts/Tibetan.html) font for Tibetan script
- PDF generation powered by the [pdf](https://pub.dev/packages/pdf) package
