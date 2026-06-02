# Graph Report - .  (2026-06-03)

## Corpus Check
- 60 files · ~235,462 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1414 nodes · 1730 edges · 43 communities (41 shown, 2 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 20 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_English Localization|English Localization]]
- [[_COMMUNITY_English L10n Classes|English L10n Classes]]
- [[_COMMUNITY_Chinese Localization|Chinese Localization]]
- [[_COMMUNITY_Pagination Layout Engine|Pagination Layout Engine]]
- [[_COMMUNITY_Editor Page|Editor Page]]
- [[_COMMUNITY_Project Config & CI|Project Config & CI]]
- [[_COMMUNITY_Data Models|Data Models]]
- [[_COMMUNITY_Block Editor Widget|Block Editor Widget]]
- [[_COMMUNITY_App Settings|App Settings]]
- [[_COMMUNITY_Font Utilities|Font Utilities]]
- [[_COMMUNITY_Font Service|Font Service]]
- [[_COMMUNITY_Theme Colors|Theme Colors]]
- [[_COMMUNITY_Export Page|Export Page]]
- [[_COMMUNITY_Settings & Dictionary|Settings & Dictionary]]
- [[_COMMUNITY_PDF Service|PDF Service]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]

## God Nodes (most connected - your core abstractions)
1. `AppLocalizations` - 14 edges
2. `pubspec.yaml - Package Configuration` - 13 edges
3. `Tibetan Typesetting App` - 9 edges
4. `PdfService` - 7 edges
5. `FontConfig` - 6 edges
6. `DatabaseService` - 6 edges
7. `SaveStateMixin` - 5 edges
8. `TextBlock (data model)` - 5 edges
9. `Tibetan text pre-rendered to PNG workaround` - 5 edges
10. `Singleton service pattern` - 5 edges

## Surprising Connections (you probably didn't know these)
- `AGENTS.md - Agent Guidelines` --semantically_similar_to--> `CLAUDE.md - Claude Code Guidance`  [INFERRED] [semantically similar]
  AGENTS.md → CLAUDE.md
- `PUBLISH.md - GitHub Publishing Guide` --semantically_similar_to--> `RELEASE_GUIDE.md - Release Process Guide`  [INFERRED] [semantically similar]
  PUBLISH.md → RELEASE_GUIDE.md
- `README.md - English Documentation` --semantically_similar_to--> `README.zh-TW.md - Traditional Chinese Documentation`  [INFERRED] [semantically similar]
  README.md → README.zh-TW.md
- `Semantic color palette (15 properties)` --semantically_similar_to--> `AppColors (utility class)`  [INFERRED] [semantically similar]
  RELEASE_NOTES.md → README.md
- `AGENTS.md - Agent Guidelines` --references--> `Tibetan Typesetting App`  [EXTRACTED]
  AGENTS.md → README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Singleton services layer** — readme_databaseservice, readme_pdfservice, readme_fontservice, readme_settingsservice, readme_pronunciationservice [EXTRACTED 1.00]
- **Core data models** — readme_project, readme_textblock, readme_pagesetup [EXTRACTED 1.00]
- **Application pages (UI layer)** — readme_projectspage, readme_editorpage, readme_exportpage, readme_settingspage, readme_dictionarypage [EXTRACTED 1.00]
- **Tibetan text rendering pipeline** — readme_textpainter, readme_rendertexttopng, readme_tibetanpngworkaround, readme_pdfservice, pubspec_pdflib, readme_opentypefeatures, pubspec_textrenderingpipeline [EXTRACTED 1.00]
- **Release and publishing process** — publish_publishmd, releaseguide_release_guide, releasenotes_release_notes, publish_githubactions, publish_githubrepo, releaseguide_semanticversioning [EXTRACTED 1.00]
- **Pronunciation dictionary feature** — readme_pronunciationservice, readme_pronunciationdictionary, readme_dictionarypage, readme_tibetansegmenter [EXTRACTED 1.00]
- **Project documentation files** — agents_agentsmd, claude_claudemd, readme_readmemd, readme_readme_zh_tw, publish_publishmd, releaseguide_release_guide, releasenotes_release_notes [EXTRACTED 1.00]
- **Project configuration files** — pubspec_pubspecyaml, analysisoptions_analysisyaml, l10n_l10nyaml [EXTRACTED 1.00]
- **Page layout and pagination system** — readme_paginateblocks, readme_twopasspagination, readme_traditionallayout, readme_pagesetup [EXTRACTED 1.00]

## Communities (43 total, 2 thin omitted)

### Community 0 - "English Localization"
Cohesion: 0.01
Nodes (152): app_localizations_en.dart, app_localizations_zh.dart, class, about, addBlock, applicationSettings, appTitle, areYouSureDelete (+144 more)

### Community 1 - "English L10n Classes"
Cohesion: 0.01
Nodes (139): app_localizations.dart, about, addBlock, applicationSettings, appTitle, areYouSureDelete, autoPerPage, block (+131 more)

### Community 2 - "Chinese Localization"
Cohesion: 0.01
Nodes (138): about, addBlock, applicationSettings, appTitle, areYouSureDelete, autoPerPage, block, blockNumber (+130 more)

### Community 3 - "Pagination Layout Engine"
Cohesion: 0.04
Nodes (56): RegExp, required double chineseFontSize,
  double, block, _buildRows, cells, chineseLineHeight, colCount, cols (+48 more)

### Community 4 - "Editor Page"
Cohesion: 0.04
Nodes (53): _addBlock, _addPage, _applyZoom, _appSettings, blocks, _buildEditor, _bumpSave, _cachedPages (+45 more)

### Community 5 - "Project Config & CI"
Cohesion: 0.06
Nodes (53): AGENTS.md - Agent Guidelines, analysis_options.yaml - Dart Analyzer Configuration, CLAUDE.md - Claude Code Guidance, l10n.yaml - Localization Configuration, GitHub Actions CI/CD, GitHub repository (yorickchan/tibetan_typesetting), PUBLISH.md - GitHub Publishing Guide, Application icon asset (+45 more)

### Community 6 - "Data Models"
Cohesion: 0.04
Nodes (47): blocks, bottom, chinesePronunciation, chineseTranslation, columnBreakBefore, columnCount, columnSpan, copyWith (+39 more)

### Community 7 - "Block Editor Widget"
Cohesion: 0.04
Nodes (44): ../models/block_update.dart, ../utils/tibetan_segmenter.dart, _autoFillPronunciation, block, build, createState, _debounce, didUpdateWidget (+36 more)

### Community 8 - "App Settings"
Cohesion: 0.05
Nodes (41): bool get, font_config.dart, int get, AppSettings, AppTheme, copyWith, defaultPageHeightMm, defaultPageWidthMm (+33 more)

### Community 9 - "Font Utilities"
Cohesion: 0.05
Nodes (43): checksums, count, dataOffset, difference, dotIdx, effectiveFont, extractFirstTrueTypeFromTtc, extractTtfFromTtc (+35 more)

### Community 10 - "Font Service"
Cohesion: 0.05
Nodes (37): Exception, ../models/font_config.dart, package:pdf/widgets.dart, _cachedFonts, _channel, _cjkFallbackPatterns, deduplicateFamilies, _extensionLower (+29 more)

### Community 11 - "Theme Colors"
Cohesion: 0.05
Nodes (38): static Color, amber400, AppColors, border, borderSubtle, buttonMutedBg, buttonMutedFg, cardBg (+30 more)

### Community 12 - "Export Page"
Cohesion: 0.06
Nodes (35): _applyZoom, _appSettings, build, _buildContent, createState, _db, dispose, _error (+27 more)

### Community 13 - "Settings & Dictionary"
Cohesion: 0.06
Nodes (33): ../pages/dictionary_page.dart, build, _buildLanguageSelector, _buildThemeSelector, createState, dispose, _fontRow, _fontService (+25 more)

### Community 14 - "PDF Service"
Cohesion: 0.07
Nodes (28): double w,, font_service.dart, Map, MemoryImage, package:pdf/pdf.dart, _blackUi, _buildContentPage, _buildTitlePage (+20 more)

### Community 15 - "Community 15"
Cohesion: 0.07
Nodes (28): editor_page.dart, export_page.dart, build, _createProject, createState, _db, _deleteProject, dispose (+20 more)

### Community 16 - "Community 16"
Cohesion: 0.07
Nodes (27): AppLocalizations get, dart:io, package:file_picker/file_picker.dart, build, createState, _deleteEntry, DictionaryPage, _DictionaryPageState (+19 more)

### Community 17 - "Community 17"
Cohesion: 0.08
Nodes (26): AppSettings?, package:flutter_svg/flutter_svg.dart, Project, sample_page.dart, title_page_widget.dart, ../utils/font_utils.dart, ../utils/sample_layout.dart, appSettings (+18 more)

### Community 18 - "Community 18"
Cohesion: 0.09
Nodes (24): ../l10n/app_localizations.dart, ../models/project.dart, PageSetup, ../utils/decorations.dart, ValueChanged, build, EditorPageSetupPanel, initialValue (+16 more)

### Community 19 - "Community 19"
Cohesion: 0.08
Nodes (25): dart:typed_data, dart:ui, double? lineHeight,
  double, required double maxWidth,
  double, Uint8List, bottomPadding, canvas, h (+17 more)

### Community 20 - "Community 20"
Cohesion: 0.10
Nodes (19): TextBlock, package:flutter_test/flutter_test.dart, package:tibetan_typesetting/l10n/app_localizations_en.dart, package:tibetan_typesetting/models/font_config.dart, package:tibetan_typesetting/models/project.dart, package:tibetan_typesetting/services/font_service.dart, package:tibetan_typesetting/services/pronunciation_service.dart, package:tibetan_typesetting/utils/font_constants.dart (+11 more)

### Community 21 - "Community 21"
Cohesion: 0.09
Nodes (21): ../models/pronunciation_entry.dart, _db, deleteEntry, exportToJson, getAllEntries, getPronunciation, getWordCount, _ImportEntry (+13 more)

### Community 22 - "Community 22"
Cohesion: 0.10
Nodes (20): build, _buildTheme, createState, fontService, initialSettings, initState, main, needsSetup (+12 more)

### Community 23 - "Community 23"
Cohesion: 0.10
Nodes (19): dart:convert, Future, package:uuid/uuid.dart, _createAppSettingsTable, createProject, _createProjectsTable, _createPronunciationDictionaryTable, DatabaseService (+11 more)

### Community 24 - "Community 24"
Cohesion: 0.11
Nodes (19): ../services/font_service.dart, TextEditingController, _allFonts, build, createState, dispose, _filter, _filtered (+11 more)

### Community 25 - "Community 25"
Cohesion: 0.11
Nodes (18): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsEn, of, LocalizationsDelegate, ProjectListItem, VoidCallback, build (+10 more)

### Community 26 - "Community 26"
Cohesion: 0.11
Nodes (18): appSettings, build, colCount, flowRows, _flowRowsFromLegacyRows, fontFamily, highlightBlockId, kMmToPx (+10 more)

### Community 27 - "Community 27"
Cohesion: 0.11
Nodes (17): appSettings, build, current, defaultSize, fallback, fontFamily, isOpen, l10n (+9 more)

### Community 28 - "Community 28"
Cohesion: 0.12
Nodes (15): List, ../utils/colors.dart, Widget, actions, AppShell, build, child, leading (+7 more)

### Community 29 - "Community 29"
Cohesion: 0.12
Nodes (15): font_picker.dart, appDefault, appSettings, build, current, FontSettingsPanel, _hasOverrides, isOpen (+7 more)

### Community 30 - "Community 30"
Cohesion: 0.12
Nodes (15): ../utils/font_constants.dart, _AddButton, blocks, BlockStripWidget, build, label, onAdd, onAddPage (+7 more)

### Community 31 - "Community 31"
Cohesion: 0.14
Nodes (13): database_service.dart, ../models/app_settings.dart, package:flutter/foundation.dart, package:sqflite/sqflite.dart, _cached, _db, getSettings, _instance (+5 more)

### Community 32 - "Community 32"
Cohesion: 0.14
Nodes (13): IconData, build, icon, kPreviewZoomMax, kPreviewZoomMin, kPreviewZoomStep, onPressed, onReset (+5 more)

### Community 33 - "Community 33"
Cohesion: 0.21
Nodes (14): _HomeWrapper, _HomeWrapperState, EditorPage, _EditorPageState, ExportPage, _ExportPageState, State, StatefulWidget (+6 more)

### Community 34 - "Community 34"
Cohesion: 0.18
Nodes (9): colors.dart, package:flutter/material.dart, package:tibetan_typesetting/widgets/preview_zoom_toolbar.dart, package:tibetan_typesetting/widgets/scaled_preview.dart, main, fieldDecoration, numberDecor, error (+1 more)

### Community 35 - "Community 35"
Cohesion: 0.17
Nodes (11): int?, BlockUpdate, chinesePronunciation, chineseTranslation, clearColumnSpan, columnSpan, format, tibetan (+3 more)

### Community 36 - "Community 36"
Cohesion: 0.18
Nodes (10): dart:async, Object?, Object? get, SaveState get, Timer?, disposeSaveStateTimer, _idleTimer, performSave (+2 more)

### Community 37 - "Community 37"
Cohesion: 0.18
Nodes (11): _EntryCard, StatelessWidget, BlockEditorWidget, _Toolbar, _FontOverrideRow, _ContentGrid, SamplePageWidget, _SidePanel (+3 more)

### Community 38 - "Community 38"
Cohesion: 0.33
Nodes (6): Intent, _AddBlockIntent, _DeleteBlockIntent, _MoveBlockDownIntent, _MoveBlockUpIntent, _SaveIntent

### Community 39 - "Community 39"
Cohesion: 0.33
Nodes (5): return, extractSyllables, _splitPattern, _stripPattern, tibetanText

### Community 40 - "Community 40"
Cohesion: 0.40
Nodes (5): MaterialPageRoute, build, _openExport, _openProject, _buildContent

## Knowledge Gaps
- **1120 isolated node(s):** `localeName`, `delegate`, `localizationsDelegates`, `supportedLocales`, `appTitle` (+1115 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppLocalizations` connect `Community 25` to `English Localization`, `Block Editor Widget`, `Community 41`, `Community 18`, `Community 27`, `Community 29`?**
  _High betweenness centrality (0.289) - this node is a cross-community bridge._
- **Why does `AppLocalizationsZh` connect `Community 41` to `Community 25`, `Chinese Localization`?**
  _High betweenness centrality (0.107) - this node is a cross-community bridge._
- **Why does `AppLocalizationsEn` connect `Community 25` to `English L10n Classes`?**
  _High betweenness centrality (0.107) - this node is a cross-community bridge._
- **What connects `localeName`, `delegate`, `localizationsDelegates` to the rest of the system?**
  _1122 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `English Localization` be split into smaller, more focused modules?**
  _Cohesion score 0.013071895424836602 - nodes in this community are weakly interconnected._
- **Should `English L10n Classes` be split into smaller, more focused modules?**
  _Cohesion score 0.014285714285714285 - nodes in this community are weakly interconnected._
- **Should `Chinese Localization` be split into smaller, more focused modules?**
  _Cohesion score 0.014388489208633094 - nodes in this community are weakly interconnected._