# Repository Guidelines

## Project Overview

A Flutter desktop application (macOS primary; Linux, Windows) for composing Tibetan text documents with Chinese pronunciation and translation annotations, exported as PDF with traditional column layout. Version `1.1.13+16`, Dart SDK `^3.11.0`.

**Golden rule — Tibetan rendering:** the `pdf` package cannot shape Tibetan script (it needs OpenType GSUB/GPOS), so Tibetan text is shaped with HarfBuzz (`harfbuzz_ffi`, native asset) and embedded as **vector glyph outlines**, each glyph stored once as a reusable form XObject, with an invisible Unicode text layer so the PDF stays searchable/copyable. Chinese renders natively via `pw.Text`; SVG templates via `pw.SvgImage` with explicit mm dimensions. Do not change this pipeline without understanding it.

## Architecture & Data Flow

**State management:** no library. `StatefulWidget`s hold a `Project` in state and call service singletons directly via `setState`. Navigation is direct `Navigator.push(MaterialPageRoute(...))` — no named routes (a global `rootNavigatorKey` in `main.dart` serves menu-triggered dialogs).

**Startup sequence** (`lib/main.dart`, 476 L):
1. `main()` → `ScreenDpiService().init()` then assigns two mutable globals: `kMmToPx` (declared in `lib/widgets/sample_page.dart:15`, default `3.78`) and `font_utils.ptToPreviewPx` (`lib/utils/font_utils.dart:292`, default `1.333`). DPI comes from MethodChannel `getScreenDpi` with a 96.0 fallback.
2. `_DatabaseStartupGate` builds DI by closure injection — `DatabaseService()`, `createDatabaseLocationService()`, `DatabaseStartupController(resolveLocation:, configureDatabase:, openDatabase:)` — then validates and opens SQLite (schema v5). Failure → `DatabaseRecoveryPage`; success → loads `AppSettings` plus preview fonts for the tibetan/pronunciation/translation roles.
3. `TibetanTypesettingApp` calls `AppColors.setBrightness()` **before** constructing `ThemeData`, wraps a `PlatformMenuBar` around `MaterialApp`, wires en/zh/zh_TW l10n, home is `_HomeWrapper` (post-frame opens `SettingsPage(requireFonts: true)` when no font is configured; always renders `ProjectsPage`).

**Three data paths:**
- **Edit** — `EditorPage` mutation helpers each do `_undoService.pushState(_project!)` → `setState` with `copyWith` → `_bumpSave()` (800 ms debounced `Timer`) → `SaveStateMixin.performSave(() => _db.updateProject(_project!))`.
- **Preview** — `_pagesWithBlocks` maps `paginateBlocks(blocks, 0, 4, pageSetup.flowGap, contentWidthMm)` to `_PageWithBlocks`, rendered per page inside `ScaledPreview` → `SamplePageWidget` (mm-accurate via `kMmToPx`). See the caching caveat below.
- **Export** — `PdfService().generatePdfWithWarnings(project, appSettings:)` pre-renders non-Tibetan text to PNGs (`_render` → `renderTextToPng`) for side panels and free-text blocks, while Tibetan is handed to `ShapedText` (`lib/utils/shaped_text_pdf.dart`), which shapes with HarfBuzz and paints vector outlines plus an invisible text layer. Chinese uses `pw.Text(font:, fontFallback:)`; templates use `pw.SvgImage`. Non-fatal font problems surface as `PdfGenerationResult.warnings`. `HtmlExportService.generateHtml` is the static alternative path.

**Undo/redo:** snapshot-based `UndoService` — full `Project` copies, max 50, redo cleared on push.

**Known rough edges (verified, not yet fixed):**
- `lib/services/image_cache_service.dart` (55 L) has **no callers in `lib/`** — it is referenced only by docs. `contentTibetanRasterBleed` / `contentTibetanBottomBleed` in `sample_layout.dart` are likewise dead.

## Key Directories

- `lib/models/` — 7 immutable data classes (~1041 L). `project.dart` (723 L) is the core: `PageSetup`, `TextBlock`, `Project`, `MarginMm`, `TemplateInset`, `ProjectListItem`, enums, `nowIso()`. Others: `app_settings`, `font_config`, `block_update`, `pronunciation_entry`, `title_page_template`, `chinese_script`.
- `lib/services/` — 22 files (~3284 L), of which **9 are true singletons** (`DatabaseService`, `FontService`, `PdfService`, `PronunciationService`, `ScreenDpiService`, `SettingsService`, `TitlePageTemplateService`, `ImageCacheService`, `ImageStorageService`). The rest are plain/const/static (`ChineseConversionService`, `UndoService`, `BatchImportService`, `HtmlExportService`, `DatabaseFileValidator`, `DatabaseStartupController`, `DatabaseLocationService`/`Store`, `MacOsDatabaseBookmarkService`). `*_core.dart` files are pure-helper splits for testability — note `font_service.dart` **re-exports** `font_service_core.dart` while `database_service_core.dart` is imported directly.
- `lib/pages/` — 6 full-screen pages (`DatabaseRecoveryPage` is stateless): editor (1073 L), settings (970 L), projects (644 L), dictionary (485 L), export (456 L), database_recovery (101 L).
- `lib/widgets/` — 18 reusable widgets (~5202 L): `sample_page` (993 L, owns `kMmToPx`), `block_editor`, `title_page_settings_panel`, `font_settings_panel`, `content_page_template_panel`, `block_strip`, `font_picker`, `title_page_widget`, `project_card`, `scaled_preview`, `app_shell`, etc.
- `lib/utils/` — 11 pure files (~1470 L): `sample_layout` (456 L, layout engine), `font_utils`, `tibetan_segmenter`, `text_renderer`, `colors`, `save_state_mixin`, `snackbar`, `decorations`, title/content-page layout math, `font_constants`.
- `lib/l10n/` — ARB sources (`app_en.arb` 264 L is the template; `app_zh.arb`, `app_zh_TW.arb` 198 L each) and **committed** generated `app_localizations*.dart` — regenerate with `flutter gen-l10n` after ARB edits.
- `test/` — 30 flat test files (~3435 L); see Testing & QA.
- `macos/`, `linux/`, `windows/` — platform runners; macOS is the real target.

## Development Commands

```bash
flutter pub get                # deps; regenerates macOS plugin SPM packages + registrant
flutter run -d macos           # primary dev target
flutter analyze                # flutter_lints v6 + 7 extra rules
flutter gen-l10n               # regenerate lib/l10n/*.dart after editing ARB files
flutter test                   # full suite (~31 files)
flutter test test/<file>.dart  # single file
flutter test --plain-name "<name>"  # single test/group by name substring
flutter build macos            # release build (also windows / linux)
```

## Code Conventions & Common Patterns

### Imports
Dart SDK → `package:flutter/*` → third-party (`pdf`, `sqflite`, `uuid`, `file_picker`, `flutter_svg`, `pinyin`, `crypto`, `path`, `path_provider`) → `../` parent-relative → same-dir relative — each group blank-line separated (alphabetical within group, not strictly enforced).

### Naming
PascalCase classes/enums, camelCase members/params, `_leadingUnderscore` private members, `snake_case.dart` filenames. Private widget sub-parts (`_Toolbar`, `_ContentGrid`, `_BlockTile`) and intent classes (`_AddBlockIntent`) live in the same file. Comments only where non-obvious (DPI rationale, Unicode codepoints, unit markers); there are no `TODO`/`FIXME`/`HACK` markers in `lib/`.

### Singleton + DI pattern (services)
```dart
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal(
    databaseFactory: databaseFactory,
    defaultDatabasesPath: getDatabasesPath,
  );
  factory DatabaseService() => _instance;
  DatabaseService._internal({ required DatabaseFactory databaseFactory, ... });
  DatabaseService.withDependencies({ required DatabaseFactory databaseFactory, ... }); // test injection
}
```
`DatabaseService` is the only service exposing `withDependencies` (used with `sqflite_common_ffi` in tests). Non-singleton services instead take closures in their constructors (`DatabaseStartupController`, `DatabaseLocationService`, `DatabaseLocationStore`).

### Immutable models
`final` fields, `copyWith()`, JSON round-trip. Nullable fields use parallel `clearXxx` boolean flags to distinguish "set to null" from "don't change":
```dart
columnSpan: clearColumnSpan ? null : (columnSpan ?? this.columnSpan),
imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
```
`PageSetup` has 9 clear flags, `TextBlock` 6, `AppSettings` 5. `TextBlock.fromJson` migrates the legacy `redHighlightStart`/`redHighlightCount` pair into the `"start-end"` range string.

### Async & error handling
- Check `if (!mounted) return;` after every `await` before `setState`; use `finally { if (mounted) setState(...) }` for busy flags.
- `try { ... } catch (e, s) { debugPrint(...); _showSnack(..., error: true); }` with `showAppSnackBar` or a local `_showSnack`.
- Font problems **warn, never crash**: `loadFontForPdf` throws `UnsupportedFontError`, caught into `PdfGenerationResult.warnings`; `loadFontForPreview` swallows with `debugPrint`; CFF fonts are silently skipped in `loadCjkFallbackFonts`.
- Debounced saves: `SaveStateMixin` (`idle→saving→saved→error`, 1 s idle reset) plus the editor's 800 ms `_bumpSave()` timer.

### DPI-aware conversions
Never hardcode 96 DPI. Use the global `kMmToPx` (mm→preview px) and `font_utils.ptToPreviewPx` / `previewFontSize`. Both are plain mutable globals set once in `main()`, not `BuildContext`-bound.

### Theming & l10n
- `AppColors.setBrightness(brightness)` MUST run before any widget reads the mutable statics (`textPrimary`, `surface`, `border`, ...). Dark theme default with full light support; Tailwind Slate palette, sky/rose/emerald/amber accents; radius 8/12, spacing multiples of 4/8.
- Every user-visible string via `AppLocalizations.of(context)!`; pages cache it as `AppLocalizations get _l10n => ...`, panel widgets receive `final AppLocalizations l10n` as a constructor param.

### Layout engine (`lib/utils/sample_layout.dart`)
- `paginateBlocks(blocks, colCount, [maxRows = 4, gapFraction = 0.01, contentWidthMm])` returns `List<PageLayout>`. All in-repo callers pass `colCount: 0`, which is coerced to **8** logical columns (`effectiveColCount`); the real `columnCount` only affects rendering.
- `_buildRows` is a fold state machine over `({current, cursor, pendingBreak, rows})` with a `flush` closure. **The cursor advances with the unclamped `width` (`s.cursor + width + gap`) while the stored cell keeps the clamped value (`width.clamp(0.08, (1.0 - cursor).clamp(0.08, 1.0))`)** — preserve both when refactoring. `gap = gapFraction.clamp(0.0, 0.08)`.
- `BlockWidthEstimate` is a sealed class with 4 variants (`ImageWidth`, `ManualWidth`, `OpeningMarkWidth`, `TextWidth`); `maxColumnSpan = 24`.
- `resolveContentRowHeights` gives compact rows their minimum height and redistributes the freed space evenly across normal rows.

### Rendering
- `renderTextToPng(...)` default `scale = 460/72 ≈ 6.389` → 460 DPI; it disposes image/picture/painter. Multi-colour Tibetan is no longer rasterised: `ShapedText` colours per glyph.
- Shaped-text internals: `shaped_text_core.dart` (FFI/HarfBuzz, outlines, break rules — pure and unit-tested) and `shaped_text_pdf.dart` (layout + painting via `pw.Widget`). It imports `package:pdf/src/pdf/obj/formxobject.dart` because form XObjects are not exported; `PdfXObject.name` lacks the leading `/`, so `_GlyphFormXObject` overrides it.
- **`fontFamilyFallback` is NOT part of `renderCacheKey`** (`lib/services/pdf_service_core.dart`) nor of the rich-text inline key — if you change CJK fallback handling, extend the cache key or you will serve stale rasters.
- `_renderCache` is cleared at the start of every `generatePdfWithWarnings`.

### Fonts
Three-tier resolution: `font_utils.effectiveFont(projectOverride, appDefault, fallback)` → project override → app default → hardcoded `font_constants` (BabelStoneTibetan / STHeiti). TTC files are auto-extracted to a standalone sfnt; CFF (`OTTO`) fonts are rejected for PDF. Small-block text sizing is a **multiplier, not a scalar default**: `smallBlockFontSize ?? fontSize * 0.75`, where `smallBlockFontSize` comes from `PageSetup` (project override) falling back to `AppSettings`, and is `null` unless explicitly set.

## Important Files

| File | Role |
|---|---|
| `lib/main.dart` | Entry: DPI init + globals, `_DatabaseStartupGate`, app shell, `PlatformMenuBar`, theming |
| `lib/services/pdf_service.dart` | PDF generation: shaped Tibetan vectors, raster Chinese/side panels, native SVG, warnings |
| `lib/pages/editor_page.dart` | Main editor: block strip/editor, setup panels, undo/redo shortcuts, pagination, debounced save |
| `lib/widgets/sample_page.dart` | mm-accurate page preview; owns global `kMmToPx` |
| `lib/models/project.dart` | Core domain: `PageSetup`/`TextBlock`/`Project` + enums + copyWith/clearXxx |
| `lib/utils/sample_layout.dart` | Layout engine: `paginateBlocks`/`_buildRows`/`BlockWidthEstimate` |
| `lib/utils/text_renderer.dart` | `TextPainter` → high-res PNG (460 DPI) for non-Tibetan text |
| `lib/utils/shaped_text_core.dart` | HarfBuzz shaping, glyph outlines, line-break rules (pure, unit-tested) |
| `lib/utils/shaped_text_pdf.dart` | `ShapedText` widget: layout mirroring `TextPainter`, vector painting, invisible text layer |
| `lib/services/database_service.dart` | SQLite facade + `withDependencies` DI (schema v5) |
| `lib/services/font_service.dart` | System font scan, preview/PDF loading, TTC/CFF handling, CJK fallback |
| `lib/services/database_location_service.dart` | Custom DB path + macOS security-scoped bookmarks |
| `lib/services/pronunciation_service.dart` | Pronunciation dictionary CRUD, spelling check, JSON import/export |
| `pubspec.yaml` | Deps + assets; `generate: true` drives l10n codegen |
| `.github/workflows/release.yml` | Only CI: `v*` tag → macOS DMG, Windows ZIP, Linux tar.gz → GitHub Release |

## Runtime/Tooling Preferences

- **Runtime**: Flutter/Dart only. SDK `^3.11.0` (lockfloor: Dart ≥3.12.0, Flutter ≥3.44.0). Package manager is `flutter pub`. **No Node/Bun/npm, no Makefile/Taskfile/justfile, and no project scripts at all** — the Flutter toolchain plus one CI workflow is the entire build surface.
- **Primary target**: macOS desktop. macOS uses **Swift Package Manager only — no CocoaPods** (no Podfile/Pods, no Pods references in `project.pbxproj`; `.flutter-plugins-dependencies` sets `swift_package_manager_enabled.macos = true`). New plugins register via `flutter pub get` → `macos/Flutter/GeneratedPluginRegistrant.swift` (currently only `FilePickerPlugin`, `SqflitePlugin`); don't reintroduce a Podfile.
- **macOS native** (`macos/Runner/MainFlutterWindow.swift`, 160 L — not AppDelegate): two MethodChannels — `tibetan_typesetting/system_fonts` (`listFonts` via CTFontManager, `getScreenDpi` via NSScreen/CGDisplayScreenSize) and `tibetan_typesetting/database_bookmarks` (`create`, `resolveAndStartAccess`). App is sandboxed; `Release.entitlements` has app-sandbox + network.client + user-selected read-write + bookmarks.app-scope + print, while `DebugProfile.entitlements` adds `cs.allow-jit` and `network.server`. Runner deployment target is 11.0 (project-level configs stay 10.15); `CODE_SIGN_STYLE = Automatic` with ad-hoc `CODE_SIGN_IDENTITY = "-"` and `DEVELOPMENT_TEAM = 9ELBDQ2BWM`. Two `alwaysOutOfDate = 1` shell phases (`33CC111E2044C6BF0003C045`, `3399D490228B24CF009A79C7`) are deliberate — do not add them to `outputPaths`.
- **Linux/Windows**: stock `flutter create` runners (no hand-written native logic, no MethodChannels). Both nevertheless carry the transitive `jni` FFI plugin in `generated_plugins.cmake`; registrants are no-ops.
- **Lints**: `flutter_lints` v6 + `prefer_final_fields`, `prefer_const_constructors`, `prefer_const_declarations`, `avoid_catches_without_on_clauses`, `unnecessary_lambdas`, `prefer_final_locals`, `prefer_final_in_for_each`. `analysis_options.yaml` excludes `build/**`, `macos/**`, `linux/**`, `windows/**` (native edits are not analyzed).
- **VCS**: colocated Jujutsu (`jj`) + git; GitHub remote `yorickchan/tibetan_typesetting`, branch `master` (plus remote `origin/web-support`). Git tags run `v1.0.0`–`v1.1.13`. `rtk` is **not installed** — run `git`/`flutter` directly (some plans under `docs/superpowers/plans/` still spell commands with `rtk`; they are stale).
- **Release/CI**: tag pushes (`v*`) and `workflow_dispatch` build all 3 platforms and create a GitHub Release (DMG with `if: failure()` ZIP fallback / ZIP / tar.gz); no caching, and **no test or analyze step**.
- **Docs drift** (don't trust blindly): `RELEASE_NOTES.md` stops at 1.1.3 (ten releases behind pubspec); `PUBLISH.md` and `RELEASE_GUIDE.md` are pinned to `v1.0.0` and instruct `git push origin main` though the branch is `master`; `README.zh-TW.md` says the render scale is 4× (English README and the code say ~6.4×/460 DPI); `.metadata` and `graphify-out/` still list removed `android`/`ios`/`web` platforms. **Do not re-add android/ios/web.**
- **Planning artifacts**: `docs/superpowers/plans` (7 dated plans) + `docs/superpowers/specs` (5 design specs — the two `2026-06-03-*` plans have no spec) and `.sisyphus/plans/` (one plan; `drafts/` empty, referenced `evidence/` absent). There is no `gsd-core/`, `.planning/`, `agents/`, `tool/`, `scripts/` or `bin/`.

## Testing & QA

- **Framework**: `package:flutter_test` exclusively — no mockito/mocktail. Dev deps: `flutter_test`, `sqflite_common_ffi`, `flutter_launcher_icons`, `flutter_lints`.
- **Layout**: 30 flat files in `test/` (~3435 L), largest `widget_test.dart` (616 L), `models_test.dart` (273 L). 24 files use pure `test()` inside `group()`; 6 use `testWidgets()` (`chinese_script_switch`, `database_location_widgets`, `page_setup_widgets`, `preview_zoom_widgets`, `sample_page_layout`, `zoom_overflow`). Naming maps to source only loosely — `pagination_test`, `sample_layout_test` and `row_height_layout_test` all target `utils/sample_layout.dart`, and three files target `models/project.dart`.
- **Naming**: `test('<behavior>')` — lowercase, no "should" (e.g. `'parses CSV with header'`, `'stack capped at 50'`). Group names are bare symbol names. `setUp()`/`tearDown()` only (never `setUpAll`/`tearDownAll`); temp dirs via `Directory.systemTemp.createTemp(...)` + recursive delete.
- **Widget wrapping**: two idioms, not one. Either full delegates — `MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: ..., home: Scaffold(body: child))` via a file-local `_app(...)`/`app(...)` helper — or a bare `MaterialApp` with `AppLocalizationsEn()` injected directly into the widget's `l10n` param. `sample_page_layout_test.dart` uses no `Scaffold`; `zoom_overflow_test.dart` nests the widget inside a `ListView`.
- **Mocking without mockito**: (1) closure injection into constructors — `DatabaseStartupController(resolveLocation:, configureDatabase:, openDatabase:)`, `DatabaseService.withDependencies(...)`, `DatabaseLocationStore(applicationSupportDirectory:)`; (2) private fake classes — `_FakeBookmarkService implements DatabaseBookmarkService` (`database_location_service_test.dart`); (3) exactly one MethodChannel mock via `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(...)` (`database_bookmark_service_test.dart`); (4) real SQLite via `sqfliteFfiInit()` + `databaseFactoryFfi` (`database_file_validator_test.dart`, `database_service_location_test.dart`).
- **Coverage**: none configured — no `coverage/` dir, no lcov, no codecov/coveralls config, and CI never runs tests. `.gitignore` already excludes `/coverage/`, so `flutter test --coverage` produces artifacts cleanly if you add it.
- **Caveats**: `test/widget_test.dart` contains NO `testWidgets()` despite its name (it is a unit-test grab-bag). `test/batch_import_service_test.dart` writes hardcoded `/tmp/test_import_*.csv|tsv` files with no `tearDown` cleanup — the one test with unsandboxed IO.
