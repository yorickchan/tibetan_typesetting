import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/block_update.dart';
import '../models/project.dart';
import '../services/database_service.dart';
import '../services/font_service.dart';
import '../services/settings_service.dart';
import '../utils/colors.dart';
import '../utils/font_constants.dart';
import '../utils/save_state_mixin.dart';
import '../utils/font_utils.dart' as font_utils;
import '../utils/sample_layout.dart';
import '../widgets/app_shell.dart';
import '../widgets/block_editor.dart';
import '../widgets/block_strip.dart';
import '../widgets/editor_page_setup_panel.dart';
import '../widgets/flow_spacing_panel.dart';
import '../widgets/font_settings_panel.dart';
import '../widgets/preview_zoom_toolbar.dart';
import '../widgets/sample_page.dart';
import '../widgets/scaled_preview.dart';
import '../widgets/title_page_settings_panel.dart';
import '../widgets/title_page_widget.dart';
import 'export_page.dart';

const _uuid = Uuid();

class EditorPage extends StatefulWidget {
  final String projectId;
  const EditorPage({super.key, required this.projectId});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage>
    with SaveStateMixin<EditorPage> {
  final _db = DatabaseService();
  final _settingsService = SettingsService();
  Project? _project;
  AppSettings _appSettings = AppSettings();
  bool _loading = true;
  String? _error;
  String? _selectedId;
  bool _titleOpen = false;
  bool _fontOpen = false;
  bool _pageSetupOpen = false;
  Timer? _saveTimer;
  List<_PageWithBlocks>? _cachedPages;
  List<TextBlock>? _lastBlocks;
  double _zoom = 1.0;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadProject();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _settingsService.getSettings();
    if (mounted) setState(() => _appSettings = s);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProject() async {
    setState(() => _loading = true);
    try {
      final project = await _db.getProject(widget.projectId);
      if (!mounted) return;

      if (project != null) {
        final ps = project.pageSetup;
        final fontService = FontService();
        for (final c in [
          ps.tibetanFont,
          ps.pronunciationFont,
          ps.translationFont,
          ps.titleTibetanFont,
          ps.titleChineseFont,
        ]) {
          if (c != null) await fontService.loadFontForPreview(c);
        }
      }

      if (!mounted) return;
      setState(() {
        _project = project;
        _loading = false;
        _error = project == null ? _l10n.projectNotFound : null;
        if (project != null &&
            _selectedId == null &&
            project.blocks.isNotEmpty) {
          _selectedId = project.blocks[0].id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  int get _selectedIndex {
    if (_project == null || _selectedId == null) return -1;
    return _project!.blocks.indexWhere((b) => b.id == _selectedId);
  }

  TextBlock? get _selectedBlock {
    final idx = _selectedIndex;
    if (idx < 0 || _project == null) return null;
    return _project!.blocks[idx];
  }

  void _bumpSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      _saveCurrent();
    });
  }

  Future<void> _saveCurrent() async {
    if (!mounted || _project == null) return;
    await performSave(() => _db.updateProject(_project!));
  }

  void _updateBlock(BlockUpdate update) {
    if (_project == null || _selectedBlock == null) return;
    final selectedId = _selectedId;
    setState(() {
      final blocks = _project!.blocks.map((b) {
        if (b.id != selectedId) return b;
        return b.copyWith(
          tibetan: update.tibetan,
          chinesePronunciation: update.chinesePronunciation,
          chineseTranslation: update.chineseTranslation,
          format: update.format,
          columnSpan: update.columnSpan,
          clearColumnSpan: update.clearColumnSpan,
        );
      }).toList();
      _project = _project!.copyWith(blocks: blocks);
    });
    _bumpSave();
  }

  void _updateSetup(PageSetup Function(PageSetup) updater) {
    if (_project == null) return;
    setState(() {
      _project = _project!.copyWith(pageSetup: updater(_project!.pageSetup));
    });
    _bumpSave();
  }

  void _applyZoom(double newZoom) {
    setState(() => _zoom = newZoom.clamp(kPreviewZoomMin, kPreviewZoomMax));
  }

  void _zoomIn() => _applyZoom(_zoom + kPreviewZoomStep);
  void _zoomOut() => _applyZoom(_zoom - kPreviewZoomStep);
  void _zoomReset() => _applyZoom(1.0);

  void _addBlock() {
    if (_project == null) return;
    final id = _uuid.v4().replaceAll('-', '');
    final block = TextBlock(id: id);
    final idx = _selectedIndex >= 0
        ? _selectedIndex + 1
        : _project!.blocks.length;
    setState(() {
      final blocks = List<TextBlock>.from(_project!.blocks);
      blocks.insert(idx, block);
      _project = _project!.copyWith(blocks: blocks);
      _selectedId = id;
    });
    _bumpSave();
  }

  void _addPage() {
    if (_project == null) return;
    final id = _uuid.v4().replaceAll('-', '');
    final block = TextBlock(id: id, pageBreakBefore: true);
    final idx = _selectedIndex >= 0
        ? _selectedIndex + 1
        : _project!.blocks.length;
    setState(() {
      final blocks = List<TextBlock>.from(_project!.blocks);
      blocks.insert(idx, block);
      _project = _project!.copyWith(blocks: blocks);
      _selectedId = id;
    });
    _bumpSave();
  }

  void _deleteBlock() {
    if (_project == null || _selectedId == null) return;
    final idx = _selectedIndex;
    setState(() {
      final blocks = _project!.blocks
          .where((b) => b.id != _selectedId)
          .toList();
      if (blocks.isEmpty) {
        final newId = _uuid.v4().replaceAll('-', '');
        _project = _project!.copyWith(blocks: [TextBlock(id: newId)]);
        _selectedId = newId;
      } else {
        final nextIdx = idx.clamp(0, blocks.length - 1);
        _project = _project!.copyWith(blocks: blocks);
        _selectedId = blocks[nextIdx].id;
      }
    });
    _bumpSave();
  }

  void _moveBlock(int dir) {
    if (_project == null || _selectedId == null) return;
    final idx = _selectedIndex;
    final nextIdx = idx + dir;
    if (idx < 0 || nextIdx < 0 || nextIdx >= _project!.blocks.length) return;
    setState(() {
      final blocks = List<TextBlock>.from(_project!.blocks);
      final item = blocks.removeAt(idx);
      blocks.insert(nextIdx, item);
      _project = _project!.copyWith(blocks: blocks);
    });
    _bumpSave();
  }

  void _toggleColumnBreak() {
    if (_project == null || _selectedBlock == null) return;
    final selectedId = _selectedId;
    setState(() {
      final blocks = _project!.blocks
          .map(
            (b) => b.id == selectedId
                ? b.copyWith(columnBreakBefore: !b.columnBreakBefore)
                : b,
          )
          .toList();
      _project = _project!.copyWith(blocks: blocks);
    });
    _bumpSave();
  }

  void _togglePageBreak() {
    if (_project == null || _selectedBlock == null) return;
    final selectedId = _selectedId;
    setState(() {
      final blocks = _project!.blocks
          .map(
            (b) => b.id == selectedId
                ? b.copyWith(pageBreakBefore: !b.pageBreakBefore)
                : b,
          )
          .toList();
      _project = _project!.copyWith(blocks: blocks);
    });
    _bumpSave();
  }

  void _toggleSmallText() {
    if (_project == null || _selectedBlock == null) return;
    final selectedId = _selectedId;
    setState(() {
      final blocks = _project!.blocks
          .map(
            (b) => b.id == selectedId ? b.copyWith(smallText: !b.smallText) : b,
          )
          .toList();
      _project = _project!.copyWith(blocks: blocks);
    });
    _bumpSave();
  }

  void _toggleFreeTextFormat() {
    if (_project == null || _selectedBlock == null) return;
    final nextFormat = _selectedBlock!.isFreeText
        ? TextBlockFormat.normal
        : TextBlockFormat.freeText;
    _updateBlock(BlockUpdate(format: nextFormat));
  }

  void _selectPrev() {
    if (_project == null || _selectedIndex <= 0) return;
    setState(() => _selectedId = _project!.blocks[_selectedIndex - 1].id);
  }

  void _selectNext() {
    if (_project == null || _selectedIndex >= _project!.blocks.length - 1) {
      return;
    }
    setState(() => _selectedId = _project!.blocks[_selectedIndex + 1].id);
  }

  List<_PageWithBlocks> get _pagesWithBlocks {
    if (_project == null) return [];

    // Return cached result if blocks haven't changed
    if (_cachedPages != null && identical(_project!.blocks, _lastBlocks)) {
      return _cachedPages!;
    }

    final pages = paginateBlocks(
      _project!.blocks,
      0,
      4,
      _project!.pageSetup.flowGap,
    );

    _cachedPages = pages.map((page) {
      final seen = <String>{};
      final blocks = <TextBlock>[];
      for (final row in page.flowRows) {
        for (final cell in row) {
          final block = cell.block;
          if (!seen.contains(block.id)) {
            seen.add(block.id);
            blocks.add(block);
          }
        }
      }
      return _PageWithBlocks(page: page, blocks: blocks);
    }).toList();

    _lastBlocks = _project!.blocks;
    return _cachedPages!;
  }

  @override
  Widget build(BuildContext context) {
    final savePill = switch (saveState) {
      SaveState.saving => _l10n.saving,
      SaveState.saved => _l10n.saved,
      SaveState.error => _l10n.saveError,
      _ => null,
    };

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            const _AddBlockIntent(),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            const _SaveIntent(),
        const SingleActivator(LogicalKeyboardKey.delete):
            const _DeleteBlockIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true):
            const _MoveBlockUpIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
            const _MoveBlockDownIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _AddBlockIntent: CallbackAction<_AddBlockIntent>(
            onInvoke: (_) => _addPage(),
          ),
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) => _saveCurrent(),
          ),
          _DeleteBlockIntent: CallbackAction<_DeleteBlockIntent>(
            onInvoke: (_) => _deleteBlock(),
          ),
          _MoveBlockUpIntent: CallbackAction<_MoveBlockUpIntent>(
            onInvoke: (_) => _moveBlock(-1),
          ),
          _MoveBlockDownIntent: CallbackAction<_MoveBlockDownIntent>(
            onInvoke: (_) => _moveBlock(1),
          ),
        },
        child: Focus(
          autofocus: true,
          child: AppShell(
            title: _project?.name ?? _l10n.editor,
            actions: [
              if (savePill != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: saveState == SaveState.error
                            ? AppColors.rose600.withValues(alpha: 0.5)
                            : AppColors.borderSubtle,
                      ),
                      color: saveState == SaveState.error
                          ? AppColors.rose600.withValues(alpha: 0.15)
                          : AppColors.cardBg,
                    ),
                    child: Text(
                      savePill,
                      style: TextStyle(
                        color: saveState == SaveState.error
                            ? AppColors.rose300
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.sky500,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _project == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExportPage(projectId: widget.projectId),
                            ),
                          );
                        },
                  child: Text(
                    _l10n.exportPdf,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.sky500),
                  )
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.rose300),
                    ),
                  )
                : _buildEditor(),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    final project = _project!;
    final pagesWithBlocks = _pagesWithBlocks;
    final previewWidth = project.pageSetup.pageWidthMm * kMmToPx;
    final previewHeight = project.pageSetup.pageHeightMm * kMmToPx;

    // Effective fonts are identical for every page; compute once.
    final tibFont = font_utils.effectiveFont(
      project.pageSetup.tibetanFont,
      _appSettings.tibetanFont,
      fallbackTibetanFont,
    );
    final pronFont = font_utils.effectiveFont(
      project.pageSetup.pronunciationFont,
      _appSettings.pronunciationFont,
      fallbackChineseFont,
    );
    final transFont = font_utils.effectiveFont(
      project.pageSetup.translationFont,
      _appSettings.translationFont,
      fallbackChineseFont,
    );

    // Precompute id -> global index map so per-block lookups are O(1).
    final blockIndexById = <String, int>{};
    for (var i = 0; i < project.blocks.length; i++) {
      blockIndexById[project.blocks[i].id] = i;
    }
    int globalIndexOf(String id) => blockIndexById[id] ?? -1;

    return ListView(
      children: [
        TitlePageSettingsPanel(
          pageSetup: project.pageSetup,
          appSettings: _appSettings,
          isOpen: _titleOpen,
          onToggle: () => setState(() => _titleOpen = !_titleOpen),
          onUpdateSetup: _updateSetup,
          l10n: _l10n,
        ),
        const SizedBox(height: 8),

        FontSettingsPanel(
          pageSetup: project.pageSetup,
          appSettings: _appSettings,
          isOpen: _fontOpen,
          onToggle: () => setState(() => _fontOpen = !_fontOpen),
          onUpdateSetup: _updateSetup,
          l10n: _l10n,
        ),
        const SizedBox(height: 8),

        EditorPageSetupPanel(
          pageSetup: project.pageSetup,
          isOpen: _pageSetupOpen,
          onToggle: () => setState(() => _pageSetupOpen = !_pageSetupOpen),
          l10n: _l10n,
          onUpdateSetup: _updateSetup,
        ),
        const SizedBox(height: 8),

        FlowSpacingPanel(
          pageSetup: project.pageSetup,
          l10n: _l10n,
          onUpdateSetup: _updateSetup,
        ),
        const SizedBox(height: 12),

        Align(
          alignment: Alignment.centerRight,
          child: PreviewZoomToolbar(
            zoom: _zoom,
            onZoomOut: _zoomOut,
            onZoomIn: _zoomIn,
            onReset: _zoomReset,
          ),
        ),
        const SizedBox(height: 12),

        if (project.pageSetup.showTitlePage) ...[
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ScaledPreview(
                zoom: _zoom,
                width: previewWidth,
                height: previewHeight,
                child: TitlePageWidget(
                  project: project,
                  appSettings: _appSettings,
                  pageNumber: '',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        ...List.generate(pagesWithBlocks.length, (pageIdx) {
          final pageData = pagesWithBlocks[pageIdx];
          final pageBlockIds = pageData.blocks.map((b) => b.id).toSet();
          final selectedOnThisPage =
              _selectedId != null && pageBlockIds.contains(_selectedId);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                BlockStripWidget(
                  blocks: pageData.blocks,
                  globalIndexOf: globalIndexOf,
                  selectedId: _selectedId,
                  onSelect: (id) => setState(() => _selectedId = id),
                  onAdd: _addBlock,
                  onAddPage: _addPage,
                  pageIndex: pageIdx,
                  tibetanFontFamily: tibFont.fontFamily,
                  translationFontFamily: transFont.fontFamily,
                ),
                if (selectedOnThisPage) ...[
                  const SizedBox(height: 8),
                  BlockEditorWidget(
                    selectedBlock: _selectedBlock,
                    selectedIndex: _selectedIndex,
                    totalBlocks: project.blocks.length,
                    onUpdateBlock: _updateBlock,
                    onMoveBlock: _moveBlock,
                    onDeleteBlock: _deleteBlock,
                    onToggleColumnBreak: _toggleColumnBreak,
                    onTogglePageBreak: _togglePageBreak,
                    onToggleSmallText: _toggleSmallText,
                    onToggleFreeTextFormat: _toggleFreeTextFormat,
                    onSelectPrev: _selectPrev,
                    onSelectNext: _selectNext,
                    tibetanFontFamily: tibFont.fontFamily,
                    pronunciationFontFamily: pronFont.fontFamily,
                    translationFontFamily: transFont.fontFamily,
                  ),
                ],
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ScaledPreview(
                    zoom: _zoom,
                    width: previewWidth,
                    height: previewHeight,
                    child: SamplePageWidget(
                      project: project,
                      appSettings: _appSettings,
                      rows: pageData.page.rows,
                      flowRows: pageData.page.flowRows,
                      colCount: pageData.page.colCount,
                      highlightBlockId: _selectedId,
                      showMark: pageIdx % 2 == 0,
                      pageNumber: resolvePageNumber(
                        project.pageSetup.pageNumber,
                        pageIdx,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _PageWithBlocks {
  final PageLayout page;
  final List<TextBlock> blocks;
  _PageWithBlocks({required this.page, required this.blocks});
}

// Keyboard shortcut intents
class _AddBlockIntent extends Intent {
  const _AddBlockIntent();
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _DeleteBlockIntent extends Intent {
  const _DeleteBlockIntent();
}

class _MoveBlockUpIntent extends Intent {
  const _MoveBlockUpIntent();
}

class _MoveBlockDownIntent extends Intent {
  const _MoveBlockDownIntent();
}
