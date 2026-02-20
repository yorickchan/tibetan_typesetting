import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/font_config.dart';
import '../models/project.dart';
import '../services/database_service.dart';
import '../services/font_service.dart';
import '../services/settings_service.dart';
import '../utils/colors.dart';
import '../utils/font_utils.dart' as font_utils;
import '../utils/sample_layout.dart';
import '../widgets/app_shell.dart';
import '../widgets/block_editor.dart';
import '../widgets/block_strip.dart';
import '../widgets/font_picker.dart';
import '../widgets/sample_page.dart';
import '../widgets/title_page_widget.dart';
import 'export_page.dart';

const _uuid = Uuid();

String _resolvePageNumber(String base, int index) {
  final trimmed = base.trim();
  if (trimmed.isEmpty) return '${index + 1}';
  final num = int.tryParse(trimmed);
  if (num != null) return '${num + index}';
  return trimmed;
}

class EditorPage extends StatefulWidget {
  final String projectId;
  const EditorPage({super.key, required this.projectId});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _db = DatabaseService();
  final _settingsService = SettingsService();
  Project? _project;
  AppSettings _appSettings = AppSettings();
  bool _loading = true;
  String? _error;
  String? _selectedId;
  bool _titleOpen = false;
  bool _fontOpen = false;
  Timer? _saveTimer;
  String _saveState = 'idle'; // idle, saving, saved, error

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
        _error = project == null ? 'Project not found' : null;
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

  int _globalIndexOf(String id) {
    if (_project == null) return -1;
    return _project!.blocks.indexWhere((b) => b.id == id);
  }

  void _bumpSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      _saveCurrent();
    });
  }

  Future<void> _saveCurrent() async {
    if (_project == null) return;
    setState(() => _saveState = 'saving');
    try {
      await _db.updateProject(_project!);
      if (!mounted) return;
      setState(() => _saveState = 'saved');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _saveState == 'saved') {
          setState(() => _saveState = 'idle');
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveState = 'error');
    }
  }

  void _updateBlock(Map<String, dynamic> patch) {
    if (_project == null || _selectedBlock == null) return;
    setState(() {
      final blocks = _project!.blocks.map((b) {
        if (b.id != _selectedBlock!.id) return b;
        return b.copyWith(
          tibetan: patch.containsKey('tibetan')
              ? patch['tibetan'] as String
              : null,
          chinesePronunciation: patch.containsKey('chinesePronunciation')
              ? patch['chinesePronunciation'] as String
              : null,
          chineseTranslation: patch.containsKey('chineseTranslation')
              ? patch['chineseTranslation'] as String
              : null,
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
    setState(() {
      final blocks = _project!.blocks
          .map(
            (b) => b.id == _selectedBlock!.id
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
    setState(() {
      final blocks = _project!.blocks
          .map(
            (b) => b.id == _selectedBlock!.id
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
    setState(() {
      final blocks = _project!.blocks
          .map(
            (b) => b.id == _selectedBlock!.id
                ? b.copyWith(smallText: !b.smallText)
                : b,
          )
          .toList();
      _project = _project!.copyWith(blocks: blocks);
    });
    _bumpSave();
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
    final setup = _project!.pageSetup;
    final colCount = (setup.columnCount > 0)
        ? setup.columnCount.clamp(1, 8)
        : 0;
    final pages = paginateBlocks(_project!.blocks, colCount, 4);
    return pages.map((page) {
      final seen = <String>{};
      final blocks = <TextBlock>[];
      for (final row in page.rows) {
        for (final cell in row) {
          if (cell != null && !seen.contains(cell.id)) {
            seen.add(cell.id);
            blocks.add(cell);
          }
        }
      }
      return _PageWithBlocks(page: page, blocks: blocks);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final savePill = switch (_saveState) {
      'saving' => 'Saving...',
      'saved' => 'Saved',
      'error' => 'Save failed',
      _ => null,
    };

    return AppShell(
      title: _project?.name ?? 'Editor',
      actions: [
        if (savePill != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _saveState == 'error'
                      ? AppColors.rose600.withValues(alpha: 0.5)
                      : AppColors.slate800,
                ),
                color: _saveState == 'error'
                    ? AppColors.rose600.withValues(alpha: 0.15)
                    : AppColors.cardBg,
              ),
              child: Text(
                savePill,
                style: TextStyle(
                  color: _saveState == 'error'
                      ? AppColors.rose300
                      : AppColors.slate200,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        builder: (_) => ExportPage(projectId: widget.projectId),
                      ),
                    );
                  },
            child: const Text(
              'Export PDF',
              style: TextStyle(
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
    );
  }

  Widget _buildEditor() {
    final project = _project!;
    final pagesWithBlocks = _pagesWithBlocks;

    return ListView(
      children: [
        // Title page settings
        _TitlePageSettings(
          pageSetup: project.pageSetup,
          appSettings: _appSettings,
          isOpen: _titleOpen,
          onToggle: () => setState(() => _titleOpen = !_titleOpen),
          onUpdateSetup: _updateSetup,
        ),
        const SizedBox(height: 8),

        // Font settings
        _FontSettingsPanel(
          pageSetup: project.pageSetup,
          appSettings: _appSettings,
          isOpen: _fontOpen,
          onToggle: () => setState(() => _fontOpen = !_fontOpen),
          onUpdateSetup: _updateSetup,
        ),
        const SizedBox(height: 12),

        // Title page preview
        if (project.pageSetup.showTitlePage) ...[
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: TitlePageWidget(
                project: project,
                appSettings: _appSettings,
                pageNumber: '',
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Per-page sections
        ...List.generate(pagesWithBlocks.length, (pageIdx) {
          final pageData = pagesWithBlocks[pageIdx];
          final pageBlockIds = pageData.blocks.map((b) => b.id).toSet();
          final selectedOnThisPage =
              _selectedId != null && pageBlockIds.contains(_selectedId);

          final tibFont = font_utils.effectiveFont(
            project.pageSetup.tibetanFont,
            _appSettings.tibetanFont,
            const FontConfig(fontFamily: 'BabelStoneTibetan', fontPath: '', fontSize: 10),
          );
          final pronFont = font_utils.effectiveFont(
            project.pageSetup.pronunciationFont,
            _appSettings.pronunciationFont,
            const FontConfig(fontFamily: 'STHeiti', fontPath: '', fontSize: 8),
          );
          final transFont = font_utils.effectiveFont(
            project.pageSetup.translationFont,
            _appSettings.translationFont,
            const FontConfig(fontFamily: 'STHeiti', fontPath: '', fontSize: 8),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                BlockStripWidget(
                  blocks: pageData.blocks,
                  globalIndexOf: _globalIndexOf,
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
                  child: SamplePageWidget(
                    project: project,
                    appSettings: _appSettings,
                    rows: pageData.page.rows,
                    colCount: pageData.page.colCount,
                    highlightBlockId: _selectedId,
                    showMark: pageIdx % 2 == 0,
                    pageNumber: _resolvePageNumber(
                      project.pageSetup.pageNumber,
                      pageIdx,
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

class _TitlePageSettings extends StatelessWidget {
  final PageSetup pageSetup;
  final AppSettings appSettings;
  final bool isOpen;
  final VoidCallback onToggle;
  final void Function(PageSetup Function(PageSetup)) onUpdateSetup;

  const _TitlePageSettings({
    required this.pageSetup,
    required this.appSettings,
    required this.isOpen,
    required this.onToggle,
    required this.onUpdateSetup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 14,
                    color: AppColors.slate400,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Title page',
                    style: TextStyle(
                      color: AppColors.slate300,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: pageSetup.showTitlePage
                          ? AppColors.emerald400.withValues(alpha: 0.15)
                          : AppColors.slate700.withValues(alpha: 0.4),
                    ),
                    child: Text(
                      pageSetup.showTitlePage ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: pageSetup.showTitlePage
                            ? AppColors.emerald400
                            : AppColors.slate500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isOpen ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: AppColors.slate500,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) ...[
            Container(height: 1, color: AppColors.slate800),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: pageSetup.showTitlePage,
                          onChanged: (v) => onUpdateSetup(
                            (s) => s.copyWith(showTitlePage: v),
                          ),
                          activeColor: AppColors.sky500,
                          side: const BorderSide(color: AppColors.slate500),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Show title page',
                        style: TextStyle(
                          color: AppColors.slate200,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _settingsField(
                    label: 'Tibetan',
                    value: pageSetup.titleTibetan,
                    placeholder: 'Title (Tibetan)',
                    fontFamily: (pageSetup.titleTibetanFont ?? font_utils.effectiveFont(
                      pageSetup.tibetanFont,
                      appSettings.tibetanFont,
                      const FontConfig(fontFamily: 'BabelStoneTibetan', fontPath: '', fontSize: 10),
                    )).fontFamily,
                    onChanged: (v) =>
                        onUpdateSetup((s) => s.copyWith(titleTibetan: v)),
                  ),
                  const SizedBox(height: 8),
                  _settingsField(
                    label: 'Chinese',
                    value: pageSetup.titleChinese,
                    placeholder: 'Title (Chinese)',
                    fontFamily: (pageSetup.titleChineseFont ?? font_utils.effectiveFont(
                      pageSetup.translationFont,
                      appSettings.translationFont,
                      const FontConfig(fontFamily: 'STHeiti', fontPath: '', fontSize: 8),
                    )).fontFamily,
                    onChanged: (v) =>
                        onUpdateSetup((s) => s.copyWith(titleChinese: v)),
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: AppColors.slate800),
                  const SizedBox(height: 12),
                  _titleFontRow(
                    label: 'TITLE TIBETAN FONT',
                    current: pageSetup.titleTibetanFont,
                    fallback: font_utils.effectiveFont(
                      pageSetup.tibetanFont,
                      appSettings.tibetanFont,
                      const FontConfig(fontFamily: 'BabelStoneTibetan', fontPath: '', fontSize: 10),
                    ),
                    defaultSize: 10,
                    onSelected: (info) {
                      FontService().loadFontForPreview(FontConfig(
                        fontFamily: info.familyName,
                        fontPath: info.filePath,
                        fontSize: 10,
                      ));
                      onUpdateSetup((s) => s.copyWith(
                        titleTibetanFont: FontConfig(
                          fontFamily: info.familyName,
                          fontPath: info.filePath,
                          fontSize: pageSetup.titleTibetanFont?.fontSize ?? 10,
                        ),
                      ));
                    },
                    onSizeChanged: (v) {
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return;
                      final cur = pageSetup.titleTibetanFont;
                      if (cur == null) return;
                      onUpdateSetup(
                        (s) => s.copyWith(titleTibetanFont: cur.copyWith(fontSize: n)),
                      );
                    },
                    onReset: () => onUpdateSetup(
                      (s) => s.copyWith(clearTitleTibetanFont: true),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _titleFontRow(
                    label: 'TITLE CHINESE FONT',
                    current: pageSetup.titleChineseFont,
                    fallback: font_utils.effectiveFont(
                      pageSetup.translationFont,
                      appSettings.translationFont,
                      const FontConfig(fontFamily: 'STHeiti', fontPath: '', fontSize: 8),
                    ),
                    defaultSize: 8,
                    onSelected: (info) {
                      FontService().loadFontForPreview(FontConfig(
                        fontFamily: info.familyName,
                        fontPath: info.filePath,
                        fontSize: 8,
                      ));
                      onUpdateSetup((s) => s.copyWith(
                        titleChineseFont: FontConfig(
                          fontFamily: info.familyName,
                          fontPath: info.filePath,
                          fontSize: pageSetup.titleChineseFont?.fontSize ?? 8,
                        ),
                      ));
                    },
                    onSizeChanged: (v) {
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return;
                      final cur = pageSetup.titleChineseFont;
                      if (cur == null) return;
                      onUpdateSetup(
                        (s) => s.copyWith(titleChineseFont: cur.copyWith(fontSize: n)),
                      );
                    },
                    onReset: () => onUpdateSetup(
                      (s) => s.copyWith(clearTitleChineseFont: true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _titleFontRow({
    required String label,
    required FontConfig? current,
    required FontConfig fallback,
    required double defaultSize,
    required ValueChanged<SystemFontInfo> onSelected,
    required ValueChanged<String> onSizeChanged,
    required VoidCallback onReset,
  }) {
    final hasOverride = current != null;
    final effectiveName = current?.fontFamily ?? fallback.fontFamily;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.slate500,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            if (!hasOverride)
              Text(
                'Default: $effectiveName',
                style: const TextStyle(
                  color: AppColors.slate600,
                  fontSize: 10,
                ),
              ),
            if (hasOverride)
              GestureDetector(
                onTap: onReset,
                child: const Text(
                  'Reset to default',
                  style: TextStyle(
                    color: AppColors.sky500,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: FontPicker(
                label: '',
                selectedPath: current?.fontPath,
                onSelected: onSelected,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: (current?.fontSize ?? defaultSize)
                    .toStringAsFixed(1),
                keyboardType: TextInputType.number,
                onChanged: onSizeChanged,
                style: const TextStyle(
                  color: AppColors.slate100,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  labelText: 'Size',
                  labelStyle: const TextStyle(
                    color: AppColors.slate500,
                    fontSize: 10,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: AppColors.slate950.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.slate700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.slate700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.sky500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _settingsField({
    required String label,
    required String value,
    required String placeholder,
    String? fontFamily,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.slate400, fontSize: 10),
          ),
        ),
        Expanded(
          child: TextFormField(
            initialValue: value,
            onChanged: onChanged,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 13,
              color: AppColors.slate100,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: AppColors.slate500.withValues(alpha: 0.5),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              filled: true,
              fillColor: AppColors.slate950.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.slate800),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.slate800),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.sky500),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Project-level font overrides panel
// ---------------------------------------------------------------------------

class _FontSettingsPanel extends StatelessWidget {
  final PageSetup pageSetup;
  final AppSettings appSettings;
  final bool isOpen;
  final VoidCallback onToggle;
  final void Function(PageSetup Function(PageSetup)) onUpdateSetup;

  const _FontSettingsPanel({
    required this.pageSetup,
    required this.appSettings,
    required this.isOpen,
    required this.onToggle,
    required this.onUpdateSetup,
  });

  bool get _hasOverrides =>
      pageSetup.tibetanFont != null ||
      pageSetup.pronunciationFont != null ||
      pageSetup.translationFont != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.font_download_outlined,
                      size: 14, color: AppColors.slate400),
                  const SizedBox(width: 6),
                  const Text(
                    'Project fonts',
                    style: TextStyle(
                      color: AppColors.slate300,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (_hasOverrides)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: AppColors.sky500.withValues(alpha: 0.15),
                      ),
                      child: const Text(
                        'CUSTOM',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: AppColors.sky400,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    isOpen ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: AppColors.slate500,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) ...[
            Container(height: 1, color: AppColors.slate800),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _fontOverrideRow(
                    label: 'TIBETAN',
                    current: pageSetup.tibetanFont,
                    appDefault: appSettings.tibetanFont,
                    onSelected: (info) {
                      final existing = pageSetup.tibetanFont;
                      onUpdateSetup((s) => s.copyWith(
                            tibetanFont: FontConfig(
                              fontFamily: info.familyName,
                              fontPath: info.filePath,
                              fontSize: existing?.fontSize ??
                                  appSettings.tibetanFont?.fontSize ??
                                  10,
                            ),
                          ));
                      FontService().loadFontForPreview(FontConfig(
                        fontFamily: info.familyName,
                        fontPath: info.filePath,
                        fontSize: 10,
                      ));
                    },
                    onSizeChanged: (v) {
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return;
                      final cur = pageSetup.tibetanFont;
                      if (cur == null) return;
                      onUpdateSetup(
                          (s) => s.copyWith(tibetanFont: cur.copyWith(fontSize: n)));
                    },
                    onReset: () =>
                        onUpdateSetup((s) => s.copyWith(clearTibetanFont: true)),
                  ),
                  const SizedBox(height: 10),
                  _fontOverrideRow(
                    label: 'PRONUNCIATION',
                    current: pageSetup.pronunciationFont,
                    appDefault: appSettings.pronunciationFont,
                    onSelected: (info) {
                      final existing = pageSetup.pronunciationFont;
                      onUpdateSetup((s) => s.copyWith(
                            pronunciationFont: FontConfig(
                              fontFamily: info.familyName,
                              fontPath: info.filePath,
                              fontSize: existing?.fontSize ??
                                  appSettings.pronunciationFont?.fontSize ??
                                  8,
                            ),
                          ));
                      FontService().loadFontForPreview(FontConfig(
                        fontFamily: info.familyName,
                        fontPath: info.filePath,
                        fontSize: 8,
                      ));
                    },
                    onSizeChanged: (v) {
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return;
                      final cur = pageSetup.pronunciationFont;
                      if (cur == null) return;
                      onUpdateSetup((s) =>
                          s.copyWith(pronunciationFont: cur.copyWith(fontSize: n)));
                    },
                    onReset: () => onUpdateSetup(
                        (s) => s.copyWith(clearPronunciationFont: true)),
                  ),
                  const SizedBox(height: 10),
                  _fontOverrideRow(
                    label: 'TRANSLATION',
                    current: pageSetup.translationFont,
                    appDefault: appSettings.translationFont,
                    onSelected: (info) {
                      final existing = pageSetup.translationFont;
                      onUpdateSetup((s) => s.copyWith(
                            translationFont: FontConfig(
                              fontFamily: info.familyName,
                              fontPath: info.filePath,
                              fontSize: existing?.fontSize ??
                                  appSettings.translationFont?.fontSize ??
                                  8,
                            ),
                          ));
                      FontService().loadFontForPreview(FontConfig(
                        fontFamily: info.familyName,
                        fontPath: info.filePath,
                        fontSize: 8,
                      ));
                    },
                    onSizeChanged: (v) {
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return;
                      final cur = pageSetup.translationFont;
                      if (cur == null) return;
                      onUpdateSetup((s) =>
                          s.copyWith(translationFont: cur.copyWith(fontSize: n)));
                    },
                    onReset: () => onUpdateSetup(
                        (s) => s.copyWith(clearTranslationFont: true)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fontOverrideRow({
    required String label,
    required FontConfig? current,
    required FontConfig? appDefault,
    required ValueChanged<SystemFontInfo> onSelected,
    required ValueChanged<String> onSizeChanged,
    required VoidCallback onReset,
  }) {
    final hasOverride = current != null;
    final effectiveName = current?.fontFamily ??
        appDefault?.fontFamily ??
        '(not set)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.slate500,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            if (!hasOverride)
              Text(
                'Default: $effectiveName',
                style: const TextStyle(
                    color: AppColors.slate600, fontSize: 10),
              ),
            if (hasOverride)
              GestureDetector(
                onTap: onReset,
                child: const Text(
                  'Reset to default',
                  style: TextStyle(
                    color: AppColors.sky500,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: FontPicker(
                label: '',
                selectedPath: current?.fontPath,
                onSelected: onSelected,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: (current?.fontSize ??
                        appDefault?.fontSize ??
                        10)
                    .toStringAsFixed(1),
                keyboardType: TextInputType.number,
                onChanged: onSizeChanged,
                style: const TextStyle(
                    color: AppColors.slate100, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Size',
                  labelStyle: const TextStyle(
                      color: AppColors.slate500, fontSize: 10),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  filled: true,
                  fillColor: AppColors.slate950.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.slate700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.slate700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.sky500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
