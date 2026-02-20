# Release Notes

## Version 1.0.0

### Features

- **Multi-Project Management**: Create, organize, and manage multiple Tibetan text projects with tagging system
- **Traditional Layout**: 300mm × 120mm landscape format with configurable columns (1-8) and rows
- **Trilingual Support**: 
  - Main Tibetan text with heading support
  - Chinese pronunciation (phonetic transcription)
  - Chinese translation
- **Advanced Text Editing**:
  - Rich text editor with live preview
  - Block-based content organization
  - Page break and column break controls
  - Small text formatting option
- **Title Page Creation**: Customizable title page with Dharma Wheel image and optional subtitles
- **PDF Export & Print**: High-quality PDF generation with proper Tibetan text rendering
- **Font System**: Dynamic font loading for Tibetan (BabelStoneTibetan) and Chinese (STHeiti) fonts
- **Dark Theme**: Modern slate/sky color scheme optimized for long editing sessions
- **Auto-Save**: Automatic saving with 800ms debounce
- **Data Persistence**: SQLite database for reliable project storage
- **Project Operations**: Duplicate, import, export, and delete projects

### Technical Highlights

- Pre-renders Tibetan text to PNG for proper OpenType shaping in PDFs
- Handles TrueType Collection (.ttc) font extraction
- 4x scale rendering (~288 DPI) for high-quality output
- Efficient pagination algorithm with block splitting

### Platform Support

- macOS (10.14 or later recommended)
- Windows (10 or later)
- Linux (Ubuntu 20.04 or later)

### Installation

#### macOS
1. Download `tibetan-typesetting-macos.zip` or `tibetan-typesetting-macos.dmg`
2. Extract/mount and drag to Applications folder
3. Right-click and select "Open" on first launch (may require allowing in System Settings > Privacy & Security)

#### Windows
1. Download `tibetan-typesetting-windows.zip`
2. Extract to desired location
3. Run `tibetan_typesetting.exe`

#### Linux
1. Download `tibetan-typesetting-linux.tar.gz`
2. Extract: `tar -xzf tibetan-typesetting-linux.tar.gz`
3. Run: `./tibetan_typesetting`

### Requirements

- **Fonts**: Application loads fonts from system. For best results, install:
  - BabelStoneTibetan (for Tibetan script)
  - STHeiti or similar Chinese font

### Known Limitations

- First launch may take a moment to initialize database
- PDF export of large projects (100+ blocks) may take several seconds due to text pre-rendering

### License

Mozilla Public License Version 2.0

---

For questions, issues, or contributions, please visit the GitHub repository.
