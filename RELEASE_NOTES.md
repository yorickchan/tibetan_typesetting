# Release Notes

## [Unreleased]

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
