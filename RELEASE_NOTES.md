# Release Notes

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
