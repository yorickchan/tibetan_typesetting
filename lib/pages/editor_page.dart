import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/project.dart';
import '../services/database_service.dart';
import '../utils/colors.dart';
import '../utils/sample_layout.dart';
import '../widgets/app_shell.dart';
import '../widgets/block_editor.dart';
import '../widgets/block_strip.dart';
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
  Project? _project;
  bool _loading = true;
  String? _error;
  String? _selectedId;
  bool _titleOpen = false;
  Timer? _saveTimer;
  String _saveState = 'idle'; // idle, saving, saved, error

  @override
  void initState() {
    super.initState();
    _loadProject();
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
    if (_project == null || _selectedIndex >= _project!.blocks.length - 1)
      return;
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
          isOpen: _titleOpen,
          onToggle: () => setState(() => _titleOpen = !_titleOpen),
          onUpdateSetup: _updateSetup,
        ),
        const SizedBox(height: 12),

        // Title page preview
        if (project.pageSetup.showTitlePage) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: TitlePageWidget(project: project, pageNumber: ''),
          ),
          const SizedBox(height: 12),
        ],

        // Per-page sections
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
                  globalIndexOf: _globalIndexOf,
                  selectedId: _selectedId,
                  onSelect: (id) => setState(() => _selectedId = id),
                  onAdd: _addBlock,
                  onAddPage: _addPage,
                  pageIndex: pageIdx,
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
                  ),
                ],
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SamplePageWidget(
                    project: project,
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
  final bool isOpen;
  final VoidCallback onToggle;
  final void Function(PageSetup Function(PageSetup)) onUpdateSetup;

  const _TitlePageSettings({
    required this.pageSetup,
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
                    fontFamily: 'BabelStoneTibetan',
                    onChanged: (v) =>
                        onUpdateSetup((s) => s.copyWith(titleTibetan: v)),
                  ),
                  const SizedBox(height: 8),
                  _settingsField(
                    label: 'Chinese',
                    value: pageSetup.titleChinese,
                    placeholder: 'Title (Chinese)',
                    fontFamily: 'STHeiti',
                    onChanged: (v) =>
                        onUpdateSetup((s) => s.copyWith(titleChinese: v)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
