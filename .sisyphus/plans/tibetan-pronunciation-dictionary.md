# Tibetan-Chinese Pronunciation Dictionary Feature

## TL;DR

> **Quick Summary**: Add a local SQLite-based pronunciation dictionary that auto-fills Chinese pronunciation for known Tibetan syllables and highlights unknown syllables, with a management UI for viewing/editing entries and export/import capability.
> 
> **Deliverables**:
> - `pronunciation_dictionary` SQLite table with migration
> - `PronunciationService` singleton for dictionary CRUD operations
> - `tibetan_segmenter.dart` utility for tsheg-based syllable splitting
> - Modified `BlockEditorWidget` with auto-fill, highlighting, and auto-save
> - New `DictionaryPage` for dictionary management (view, edit, delete)
> - Export/Import JSON functionality for dictionary sharing
> 
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 4 waves
> **Critical Path**: Database schema → Service → Widget integration → Management UI

---

## Context

### Original Request
Build a local Tibetan-to-Chinese pronunciation database that:
1. Auto-fills pronunciation when Tibetan syllable exists in database
2. Shows "X" indicator when Tibetan syllable is new (not in database)
3. Auto-saves user-input pronunciation to database
4. Provides dictionary management UI for viewing, editing, deleting entries
5. Supports export/import JSON for sharing dictionary data

### Interview Summary
**Key Discussions**:
- **Segmentation**: SYLLABLE-ONLY (Phase 1) - Split by tsheg (་, U+0F0B), each syllable stored separately. Word-level combination deferred to Phase 2.
- **Save Trigger**: Auto-save to dictionary whenever pronunciation field content changes
- **Visual Indicators**: Yellow highlight on unknown syllables in Tibetan field, 'X' placeholder in pronunciation field
- **Dictionary Management**: Full UI page for view/edit/delete, plus export/import JSON
- **Test Strategy**: No automated tests, rely on agent-executed QA scenarios

**Research Findings**:
- Tsheg (་, U+0F0B) separates syllables (tsheg-bar), NOT words
- Word boundaries in Tibetan are ambiguous and require dictionary/linguistic knowledge
- No Flutter/Dart Tibetan segmentation package exists
- Simple tsheg-split approach is recommended for Phase 1

### Technical Context
- **Database**: SQLite via `sqflite`, current version 2
- **Service Pattern**: Singletons with factory constructor (see `DatabaseService`, `SettingsService`)
- **TextBlock Model**: Already has `chinesePronunciation` field
- **Editor Flow**: `BlockEditorWidget.onUpdateBlock` → `EditorPage._updateBlock`

---

## Work Objectives

### Core Objective
Implement a syllable-level pronunciation dictionary that integrates into the existing block editor workflow, reducing repetitive manual entry of Chinese pronunciations for Tibetan text.

### Concrete Deliverables
- `lib/services/pronunciation_service.dart` - CRUD service for dictionary
- `lib/utils/tibetan_segmenter.dart` - Syllable extraction utility
- Modified `lib/widgets/block_editor.dart` - Auto-fill, highlighting, auto-save
- `lib/pages/dictionary_page.dart` - Dictionary management UI
- `lib/widgets/dictionary_entry_list.dart` - Reusable entry list widget
- Database migration: version 2 → 3

### Definition of Done
- [ ] Tibetan text typed in block editor shows yellow highlight on unknown syllables
- [ ] Pronunciation field shows 'X' placeholder for unknown syllables
- [ ] Pronunciation field auto-fills from dictionary when syllables match
- [ ] Pronunciation entries auto-save when user types in pronunciation field
- [ ] Dictionary page accessible from settings or navigation
- [ ] Dictionary page shows all entries with search/filter
- [ ] Dictionary entries can be edited and deleted
- [ ] Dictionary can be exported to JSON file
- [ ] Dictionary can be imported from JSON file
- [ ] `flutter analyze` passes with no errors

### Must Have
- SQLite table `pronunciation_dictionary` with Tibetan syllable as primary key
- Tsheg-based syllable extraction function
- Real-time auto-fill when Tibetan text changes
- Auto-save to dictionary on pronunciation change
- Dictionary management page with CRUD operations

### Must NOT Have (Guardrails)
- NO cloud sync - this is a local-only feature
- NO word-level segmentation in Phase 1
- NO multi-syllable word combination UI (Phase 2)
- NO external Tibetan NLP library dependencies
- Do NOT modify existing PDF export logic
- Do NOT touch `TextBlock` model structure

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: YES (flutter_test)
- **Automated tests**: NO (per user decision)
- **Framework**: N/A
- **QA Method**: Agent-executed scenarios via Playwright for Flutter desktop

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Desktop App QA**: Use Playwright with Flutter --device-id for automation
- **SQLite QA**: Direct queries via `flutter run` with debug output
- **UI QA**: Screenshot capture, DOM assertions for Flutter widgets

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — database + core utilities):
├── Task 1: Database schema migration (v2→v3) [quick]
├── Task 2: PronunciationService CRUD methods [quick]
├── Task 3: Tibetan segmenter utility function [quick]
└── Task 4: Model for dictionary entry [quick]

Wave 2 (After Wave 1 — widget integration):
├── Task 5: Syllable highlight decorator widget [visual-engineering]
├── Task 6: Auto-fill logic in BlockEditorWidget [quick]
├── Task 7: Auto-save to dictionary on pronunciation change [quick]
└── Task 8: 'X' placeholder logic in pronunciation field [quick]

Wave 3 (After Wave 2 — management UI):
├── Task 9: Dictionary page scaffold and layout [visual-engineering]
├── Task 10: Dictionary entry list with search [visual-engineering]
├── Task 11: Edit/delete entry functionality [quick]
├── Task 12: Dictionary entry edit dialog [visual-engineering]
└── Task 13: Navigation route to dictionary page [quick]

Wave 4 (After Wave 3 — export/import):
├── Task 14: Export dictionary to JSON file [quick]
├── Task 15: Import dictionary from JSON file [quick]
└── Task 16: Localization strings for new UI [writing]

Wave FINAL (After ALL tasks — independent review):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
└── Task F4: Scope fidelity check (deep)

Critical Path: T1 → T2 → T6,T7 → T9 → T14,T15 → F1-F4
Parallel Speedup: ~60% faster than sequential
Max Concurrent: 4 (Wave 1)
```

### Dependency Matrix

- **1-4**: — — 5-8
- **5**: 3 — 6, 7
- **6**: 2, 3 — 7, 8
- **7**: 2, 6 — —
- **8**: 6 — —
- **9**: 2 — 10, 11, 12
- **10**: 2, 9 — —
- **11**: 2, 9 — —
- **12**: 9 — 11
- **13**: 9 — —
- **14**: 2 — 15
- **15**: 2, 14 — —
- **16**: 9, 13 — —
- **F1-F4**: 1-16 — —

### Agent Dispatch Summary

- **Wave 1**: 4 tasks → all `quick`
- **Wave 2**: 4 tasks → 1 `visual-engineering`, 3 `quick`
- **Wave 3**: 5 tasks → 3 `visual-engineering`, 2 `quick`
- **Wave 4**: 3 tasks → 2 `quick`, 1 `writing`
- **FINAL**: 4 tasks → 1 `oracle`, 2 `unspecified-high`, 1 `deep`

---

## TODOs

- [ ] 1. Database schema migration (v2→v3)

  **What to do**:
  - Add `pronunciation_dictionary` table to SQLite schema in `DatabaseService`
  - Increment database version from 2 to 3
  - Add `onCreate` handler for new table in `_initDb`
  - Add `onUpgrade` migration for existing databases (oldVersion < 3)
  - Table schema: `tibetan_syllable TEXT PRIMARY KEY, chinese_pronunciation TEXT NOT NULL, created_at TEXT, updated_at TEXT`

  **Must NOT do**:
  - Do NOT modify existing `projects` or `app_settings` tables
  - Do NOT change database path or name

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3, 4)
  - **Blocks**: Task 2
  - **Blocked By**: None

  **References**:
  - `lib/services/database_service.dart:28-38` - Database version and migration pattern
  - `lib/services/database_service.dart:41-55` - Table creation pattern

  **Acceptance Criteria**:
  - [ ] Database version incremented to 3
  - [ ] `pronunciation_dictionary` table created with correct schema

  **QA Scenarios**:
  ```
  Scenario: New install creates pronunciation_dictionary table
    Tool: Bash (flutter run)
    Steps:
      1. Delete existing database
      2. Run `flutter run -d macos`
      3. App launches successfully
    Expected Result: Database created with pronunciation_dictionary table
    Evidence: .sisyphus/evidence/task-01-db-migration.png
  ```

  **Commit**: YES (groups with 2, 3, 4)

- [ ] 2. PronunciationService CRUD methods

  **What to do**:
  - Create `lib/services/pronunciation_service.dart`
  - Implement singleton pattern (factory constructor, _internal)
  - Methods: `getPronunciation(String)`, `savePronunciation(String, String)`, `getAllEntries()`, `deleteEntry(String)`, `updateEntry(String, String)`, `exportToJson()`, `importFromJson(String)`
  - Add timestamps on save

  **Must NOT do**:
  - Do NOT modify DatabaseService directly
  - Do NOT add business logic beyond CRUD

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3, 4)
  - **Blocks**: Tasks 6, 7, 9-15
  - **Blocked By**: Task 1

  **References**:
  - `lib/services/settings_service.dart:8-35` - Singleton service pattern

  **Acceptance Criteria**:
  - [ ] `PronunciationService` singleton created
  - [ ] All CRUD methods work correctly

  **QA Scenarios**:
  ```
  Scenario: CRUD operations work
    Tool: Bash (flutter run debug)
    Steps:
      1. Save pronunciation: `PronunciationService().savePronunciation('བསྟན', 'bstan')`
      2. Retrieve: `PronunciationService().getPronunciation('བསྟན')`
    Expected Result: Returns 'bstan'
    Evidence: .sisyphus/evidence/task-02-crud.log
  ```

  **Commit**: YES (groups with 1, 3, 4)

- [ ] 3. Tibetan segmenter utility function

  **What to do**:
  - Create `lib/utils/tibetan_segmenter.dart`
  - Implement `List<String> extractSyllables(String tibetanText)`
  - Split by tsheg (་, U+0F0B)
  - Filter empty strings
  - Add `String joinSyllables(List<String> syllables)`

  **Must NOT do**:
  - Do NOT implement word-level segmentation
  - Do NOT add external dependencies

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 4)
  - **Blocks**: Tasks 5, 6
  - **Blocked By**: None

  **References**:
  - `lib/utils/sample_layout.dart:11-14` - Utility function pattern

  **Acceptance Criteria**:
  - [ ] `extractSyllables('བསྟན་པ་སྲིད')` returns `['བསྟན', 'པ', 'སྲིད']`
  - [ ] Handles empty input
  - [ ] `joinSyllables` reconstructs text

  **QA Scenarios**:
  ```
  Scenario: Syllable extraction works
    Tool: Bash (dart test)
    Steps:
      1. Call extractSyllables with test input
    Expected Result: Correct syllable list
    Evidence: .sisyphus/evidence/task-03-segmenter.log
  ```

  **Commit**: YES (groups with 1, 2, 4)

- [ ] 4. Model for dictionary entry

  **What to do**:
  - Create `lib/models/pronunciation_entry.dart`
  - Define `PronunciationEntry` class with `tibetanSyllable`, `chinesePronunciation`, `createdAt`, `updatedAt`
  - Implement `fromJson`, `toJson`, `copyWith`

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3)
  - **Blocked By**: None

  **References**:
  - `lib/models/project.dart:184-242` - Model pattern

  **Commit**: YES (groups with 1, 2, 3)

- [ ] 5. Syllable highlight decorator widget

  **What to do**:
  - Create `lib/widgets/syllable_highlight_text.dart`
  - Implement a `TextSpan`-based widget that can highlight specific text ranges
  - Accept `text` and `List<String> unknownSyllables` parameters
  - Use `TextSpan` with `BackgroundColorSpan` or custom painter for yellow highlight
  - Match syllables in text and apply highlight

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 6, 7, 8)
  - **Blocks**: Tasks 6, 7
  - **Blocked By**: Task 3 (segmenter function)

  **References**:
  - `lib/widgets/block_editor.dart:436-448` - Tibetan field implementation

  **QA Scenarios**:
  ```
  Scenario: Unknown syllables highlighted in yellow
    Tool: Playwright (Flutter desktop)
    Steps:
      1. Launch app
      2. Type Tibetan text with unknown syllables
    Expected Result: Unknown syllables show yellow background
    Evidence: .sisyphus/evidence/task-05-highlight.png
  ```

  **Commit**: YES (groups with 6, 7, 8)

- [ ] 6. Auto-fill logic in BlockEditorWidget

  **What to do**:
  - Modify `lib/widgets/block_editor.dart`
  - Add logic to call `PronunciationService().getPronunciation()` on Tibetan text change
  - Use `extractSyllables` to get each syllable
  - Look up each syllable in dictionary, concatenate results
  - Update pronunciation TextEditingController with auto-filled values
  - Leave unknown syllables as 'X' in the concatenated result

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 7, 8)
  - **Blocks**: Tasks 7, 8
  - **Blocked By**: Tasks 2, 3

  **References**:
  - `lib/widgets/block_editor.dart:436-464` - Text fields and controllers
  - `lib/pages/editor_page.dart:150-169` - Block update flow

  **QA Scenarios**:
  ```
  Scenario: Auto-fill pronunciation from dictionary
    Tool: Playwright (Flutter desktop)
    Steps:
      1. Add dictionary entry via DictionaryPage
      2. Type matching Tibetan syllable in editor
    Expected Result: Pronunciation auto-fills with correct value
    Evidence: .sisyphus/evidence/task-06-autofill.png
  ```

  **Commit**: YES (groups with 5, 7, 8)

- [ ] 7. Auto-save to dictionary on pronunciation change

  **What to do**:
  - Modify `_EditorFieldsState` in `block_editor.dart`
  - Add logic in pronunciation `onChanged` callback
  - Extract syllables from Tibetan field, match with pronunciation field
  - Save each syllable-pronunciation pair to database via PronunciationService
  - Add debounce to avoid excessive saves

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 6, 8)
  - **Blocked By**: Tasks 2, 6

  **References**:
  - `lib/widgets/block_editor.dart:451-463` - Pronunciation field
  - `lib/pages/editor_page.dart:125-130` - Debounce pattern

  **QA Scenarios**:
  ```
  Scenario: Pronunciation auto-saves to dictionary
    Tool: Playwright (Flutter desktop)
    Steps:
      1. Type new Tibetan syllable
      2. Type pronunciation
      3. Navigate away and back
    Expected Result: Pronunciation is saved and auto-fills
    Evidence: .sisyphus/evidence/task-07-autosave.png
  ```

  **Commit**: YES (groups with 5, 6, 8)

- [ ] 8. 'X' placeholder logic in pronunciation field

  **What to do**:
  - Modify pronunciation field in `block_editor.dart`
  - When auto-filling, replace unknown syllables with 'X'
  - Show placeholder/hint text when field contains only 'X' entries
  - Handle case where all syllables are unknown (show single 'X')

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 6, 7)
  - **Blocked By**: Task 6

  **QA Scenarios**:
  ```
  Scenario: Unknown syllables show X placeholder
    Tool: Playwright (Flutter desktop)
    Steps:
      1. Type Tibetan syllable not in dictionary
    Expected Result: Pronunciation field shows 'X'
    Evidence: .sisyphus/evidence/task-08-x-placeholder.png
  ```

  **Commit**: YES (groups with 5, 6, 7)

- [ ] 9. Dictionary page scaffold and layout

  **What to do**:
  - Create `lib/pages/dictionary_page.dart`
  - Use `AppShell` wrapper for consistent UI
  - Add title 'Pronunciation Dictionary'
  - Add FAB or button for adding new entries
  - Reserve space for entry list, search bar, export/import buttons

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 10, 11, 12, 13)
  - **Blocks**: Tasks 10, 11, 12, 13
  - **Blocked By**: Task 2

  **References**:
  - `lib/pages/settings_page.dart` - Page layout pattern
  - `lib/widgets/app_shell.dart` - App shell wrapper

  **QA Scenarios**:
  ```
  Scenario: Dictionary page opens and displays
    Tool: Playwright (Flutter desktop)
    Steps:
      1. Navigate to Dictionary page
    Expected Result: Page shows title and basic layout
    Evidence: .sisyphus/evidence/task-09-page-scaffold.png
  ```

  **Commit**: YES (groups with 10, 11, 12, 13)

- [ ] 10. Dictionary entry list with search

  **What to do**:
  - Create `lib/widgets/dictionary_entry_list.dart`
  - Display entries in `ListView` with `ListTile` widgets
  - Show Tibetan syllable and Chinese pronunciation
  - Add search bar that filters entries
  - Use `PronunciationService().getAllEntries()` to load data

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 9, 11, 12, 13)
  - **Blocked By**: Tasks 2, 9

  **References**:
  - `lib/pages/projects_page.dart:66-100` - List with search pattern

  **QA Scenarios**:
  ```
  Scenario: Dictionary entries display in list
    Tool: Playwright (Flutter desktop)
    Steps:
      1. Open Dictionary page
      2. Verify entries from database appear
      3. Type in search box
    Expected Result: Entries filter correctly
    Evidence: .sisyphus/evidence/task-10-entry-list.png
  ```

  **Commit**: YES (groups with 9, 11, 12, 13)

- [ ] 11. Edit/delete entry functionality

  **What to do**:
  - Add edit and delete buttons to each entry in the list
  - Delete: Show confirmation dialog, call `PronunciationService().deleteEntry()`
  - Edit: Open dialog, save changes via `PronunciationService().updateEntry()`
  - Refresh list after changes

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 9, 10, 12, 13)
  - **Blocked By**: Tasks 2, 9

  **QA Scenarios**:
  ```
  Scenario: Delete dictionary entry
    Tool: Playwright (Flutter desktop)
    Steps:
      1. Click delete button on entry
      2. Confirm deletion
    Expected Result: Entry removed from list
    Evidence: .sisyphus/evidence/task-11-delete.png
  ```

  **Commit**: YES (groups with 9, 10, 12, 13)

- [ ] 12. Dictionary entry edit dialog

  **What to do**:
  - Create reusable edit dialog widget
  - Show text fields for Tibetan syllable (read-only) and Chinese pronunciation
  - Add save/cancel buttons
  - Validate input before saving

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 9, 10, 11, 13)
  - **Blocked By**: Task 9

  **QA Scenarios**:
  ```
  Scenario: Edit entry via dialog
    Tool: Playwright (Flutter desktop)
    Steps:
      1. Click edit button
      2. Modify pronunciation
      3. Click save
    Expected Result: Entry updated in list
    Evidence: .sisyphus/evidence/task-12-edit-dialog.png
  ```

  **Commit**: YES (groups with 9, 10, 11, 13)

- [ ] 13. Navigation route to dictionary page

  **What to do**:
  - Add route to DictionaryPage in navigation
  - Add entry in Settings page or EditorPage toolbar
  - Use `Navigator.push()` to navigate

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 9, 10, 11, 12)
  - **Blocked By**: Task 9

  **References**:
  - `lib/pages/settings_page.dart` - Settings page for navigation entry

  **QA Scenarios**:
  ```
  Scenario: Navigate to Dictionary page
    Tool: Playwright (Flutter desktop)
    Steps:
      1. Click Dictionary link/button
    Expected Result: Dictionary page opens
    Evidence: .sisyphus/evidence/task-13-navigation.png
  ```

  **Commit**: YES (groups with 9, 10, 11, 12)

- [ ] 14. Export dictionary to JSON file

  **What to do**:
  - Add export button to DictionaryPage
  - Use `file_picker` package (already in dependencies) to select save location
  - Call `PronunciationService().exportToJson()`
  - Write JSON to selected file path
  - Show success/error message

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 15, 16)
  - **Blocks**: Task 15
  - **Blocked By**: Task 2

  **References**:
  - `lib/pages/editor_page.dart` - File picker usage

  **QA Scenarios**:
  ```
  Scenario: Export dictionary to JSON
    Tool: Playwright (Flutter desktop)
    Steps:
      1. Click export button
      2. Select save location
      3. Verify file created
    Expected Result: JSON file with all entries
    Evidence: .sisyphus/evidence/task-14-export.png
  ```

  **Commit**: YES (groups with 15, 16)

- [ ] 15. Import dictionary from JSON file

  **What to do**:
  - Add import button to DictionaryPage
  - Use `file_picker` to select JSON file
  - Parse JSON, call `PronunciationService().importFromJson()`
  - Handle merge strategy (skip existing / overwrite)
  - Show summary of imported entries

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 14, 16)
  - **Blocked By**: Tasks 2, 14

  **QA Scenarios**:
  ```
  Scenario: Import dictionary from JSON
    Tool: Playwright (Flutter desktop)
    Steps:
      1. Click import button
      2. Select JSON file
      3. Verify entries added
    Expected Result: Dictionary entries imported
    Evidence: .sisyphus/evidence/task-15-import.png
  ```

  **Commit**: YES (groups with 14, 16)

- [ ] 16. Localization strings for new UI

  **What to do**:
  - Add localization strings to `lib/l10n/app_en.arb` and `app_zh.arb`
  - Strings: 'Pronunciation Dictionary', 'Export', 'Import', 'Search entries', 'Edit', 'Delete', 'Save', 'Cancel', 'Tibetan', 'Pronunciation', etc.
  - Run `flutter gen-l10n` to generate localization classes

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 14, 15)
  - **Blocked By**: Tasks 9, 13

  **References**:
  - `lib/l10n/app_localizations.dart` - Localization pattern

  **QA Scenarios**:
  ```
  Scenario: UI shows localized strings
    Tool: Playwright (Flutter desktop)
    Steps:
      1. Change app language
      2. Verify UI strings update
    Expected Result: All strings localized
    Evidence: .sisyphus/evidence/task-16-localization.png
  ```

  **Commit**: YES (groups with 14, 15)


---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. Verify all "Must Have" features exist. Check evidence files. Compare deliverables against plan.

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `flutter analyze` + `flutter test`. Review for AI slop patterns, unused imports, proper null safety.

- [ ] F3. **Real Manual QA** — `unspecified-high` (+ `playwright` skill)
  Execute EVERY QA scenario from EVERY task. Test cross-task integration. Test edge cases.

- [ ] F4. **Scope Fidelity Check** — `deep`
  Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT Have" compliance.

---

## Commit Strategy

- **Wave 1 Complete**: `feat(pronunciation): add database schema and service`
- **Wave 2 Complete**: `feat(pronunciation): integrate auto-fill in block editor`
- **Wave 3 Complete**: `feat(pronunciation): add dictionary management UI`
- **Wave 4 Complete**: `feat(pronunciation): add export/import functionality`

---

## Success Criteria

### Verification Commands
```bash
flutter analyze              # Expected: No issues found
flutter run -d macos         # Expected: App launches
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] App builds and runs on macOS
- [ ] Dictionary persists between app restarts
