# AGENTS.md

Guidelines for coding agents working on the Tibetan Typesetting Flutter project.

## Project Overview

A Flutter desktop application for creating and exporting Tibetan text documents with Chinese translations in a traditional layout format. Key feature: Tibetan text is pre-rendered to PNG images because the `pdf` package cannot render Tibetan script (requires OpenType GSUB/GPOS features).

## Build/Lint/Test Commands

```bash
flutter pub get              # Get dependencies
flutter run -d macos         # Run the app (or windows, linux)
flutter analyze              # Analyze code (lint)
flutter test                 # Run all tests
flutter test test/widget_test.dart                    # Run a single test file
flutter test test/widget_test.dart --name "testName"  # Run specific test by name
flutter build macos          # Build for release (or windows, linux)
```

## Architecture

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data classes (Project, TextBlock, PageSetup, etc.)
├── pages/                    # Screen widgets (ProjectsPage, EditorPage, ExportPage, SettingsPage)
├── services/                 # Singletons for persistence, PDF, fonts, settings
├── utils/                    # Helpers (colors, pagination, text rendering, font utils)
├── widgets/                  # Reusable UI components
└── l10n/                     # Localization (en, zh, zh_TW)
```

## Code Style Guidelines

### Imports

Order imports as follows, separated by blank lines:

1. Dart SDK imports (`dart:async`, `dart:convert`, etc.)
2. Flutter SDK imports (`package:flutter/...`)
3. Third-party package imports (`package:sqflite/...`)
4. Relative imports from parent directories (`../models/...`)
5. Relative imports from same directory (`./some_file.dart`)

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../models/project.dart';
import 'utils.dart';
```

### Naming Conventions

- **Classes**: PascalCase (`Project`, `TextBlock`, `PageSetup`)
- **Variables/Methods**: camelCase (`pageBreakBefore`, `copyWith`)
- **Private members**: Prefix with underscore (`_project`, `_loadProject`)
- **Constants**: camelCase for private (`_uuid`), PascalCase for public (`AppColors`)
- **File names**: snake_case (`editor_page.dart`, `database_service.dart`)

### Classes and Widgets

- Use `const` constructors where possible
- State classes: `_WidgetNameState` pattern
- Private helper classes: Prefix with underscore (`_Row`, `_PageWithBlocks`)
- Mark immutable parameters as `final`
- Use `super.key` for widget key parameters

### Models

- Provide `copyWith()` method for immutable updates
- Implement `toJson()` and `fromJson()` factories for serialization
- Use named constructor parameters with defaults
- Handle nullable fields with `clear*` flags in `copyWith` (e.g., `clearTibetanFont: true`)

### Services (Singleton Pattern)

```dart
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }
}
```

### Async Operations

- Always check `mounted` after `await` before calling `setState`
- Cancel timers/streams in `dispose()`
- Use `try/catch` for error handling with user-friendly messages

### Comments

- Do NOT add comments unless explicitly requested by the user
- Code should be self-documenting through clear naming

### Styling

- Use `AppColors` utility class for consistent theming (`lib/utils/colors.dart`)
- Dark theme with slate/sky color scheme
- Border radius: typically 8 or 12
- Spacing: multiples of 4 or 8

### Localization

- Use `AppLocalizations.of(context)!` to access translated strings
- All user-visible text should use localization

## Key Implementation Details

### Tibetan Text Rendering

The `pdf` package cannot render Tibetan script. The workaround:
1. Pre-render all Tibetan text to PNG using Flutter's `TextPainter`
2. Embed images in the PDF instead of text
3. See `renderTextToPng()` in `lib/utils/text_renderer.dart`

### Page Layout

- Default page: 300mm x 120mm (landscape)
- 4 rows per page, 1-8 columns
- See `paginateBlocks()` in `lib/utils/sample_layout.dart`
