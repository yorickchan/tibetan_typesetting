import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../utils/colors.dart';
import '../utils/decorations.dart';
import '../utils/snackbar.dart';
import '../widgets/app_shell.dart';
import 'editor_page.dart';
import 'export_page.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final _db = DatabaseService();
  final _searchCtrl = TextEditingController();
  List<ProjectListItem> _projects = [];
  bool _loading = true;
  String? _error;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    try {
      final projects = await _db.listProjects();
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<ProjectListItem> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _projects;
    return _projects
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.tags.any((t) => t.toLowerCase().contains(q)),
        )
        .toList();
  }

  void _showSnackMsg(String msg, {bool error = false}) {
    if (!mounted) return;
    showAppSnackBar(context, msg, error: error);
  }

  Future<void> _openProject(String projectId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditorPage(projectId: projectId)),
    );
    _loadProjects();
  }

  Future<void> _openExport(String projectId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExportPage(projectId: projectId)),
    );
    _loadProjects();
  }

  Future<void> _createProject() async {
    final l10n = _l10n;
    final result = await _showNameTagsDialog(
      title: l10n.newProject,
      initialName: l10n.untitled,
      l10n: l10n,
    );
    if (result == null) return;
    try {
      final settings = await SettingsService().getSettings();
      final project = await _db.createProject(
        name: result['name'] as String,
        tags: result['tags'] as List<String>,
        pageSetup: PageSetup(
          pageWidthMm: settings.defaultPageWidthMm,
          pageHeightMm: settings.defaultPageHeightMm,
        ),
      );
      _showSnackMsg(_l10n.projectCreated);
      if (mounted) _openProject(project.id);
    } catch (e) {
      _showSnackMsg(_l10n.failedToCreateProject, error: true);
    }
  }

  Future<void> _renameProject(ProjectListItem item) async {
    final l10n = _l10n;
    final result = await _showNameTagsDialog(
      title: l10n.renameProject,
      initialName: item.name,
      initialTags: item.tags.join(', '),
      l10n: l10n,
    );
    if (result == null) return;
    try {
      final project = await _db.getProject(item.id);
      if (project == null) return;
      final updated = project.copyWith(
        name: result['name'] as String,
        tags: result['tags'] as List<String>,
      );
      await _db.updateProject(updated);
      _showSnackMsg(_l10n.projectUpdated);
      _loadProjects();
    } catch (e) {
      _showSnackMsg(_l10n.failedToUpdateProject, error: true);
    }
  }

  Future<void> _deleteProject(ProjectListItem item) async {
    final l10n = _l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.deleteProject,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: l10n.areYouSureDelete(item.name),
                style: TextStyle(color: AppColors.textBody),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: AppColors.textCaption),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: TextStyle(color: AppColors.rose400),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _db.deleteProject(item.id);
      _showSnackMsg(_l10n.projectDeleted);
      _loadProjects();
    } catch (e) {
      _showSnackMsg(_l10n.failedToDeleteProject, error: true);
    }
  }

  Future<void> _duplicateProject(String projectId) async {
    try {
      final copy = await _db.duplicateProject(projectId);
      _showSnackMsg(_l10n.projectDuplicated);
      if (mounted) _openProject(copy.id);
    } catch (e) {
      _showSnackMsg(_l10n.failedToDuplicateProject, error: true);
    }
  }

  Future<void> _exportJson(ProjectListItem item) async {
    try {
      final project = await _db.getProject(item.id);
      if (project == null) return;
      final jsonStr = const JsonEncoder.withIndent(
        '  ',
      ).convert(project.toJson());

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Project JSON',
        fileName: '${project.name}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (path == null) return;
      await File(path).writeAsString(jsonStr);
      _showSnackMsg(_l10n.projectExported);
    } catch (e) {
      _showSnackMsg(_l10n.failedToExportProject, error: true);
    }
  }

  Future<void> _importJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = File(result.files.single.path!);
      final text = await file.readAsString();
      final parsed = jsonDecode(text) as Map<String, dynamic>;
      final project = Project.fromJson(parsed);
      final imported = await _db.importProject(project);
      _showSnackMsg(_l10n.projectImported);
      if (mounted) _openProject(imported.id);
    } catch (e) {
      _showSnackMsg(_l10n.failedToImportProject, error: true);
    }
  }

  Future<Map<String, dynamic>?> _showNameTagsDialog({
    required String title,
    String initialName = '',
    String initialTags = '',
    AppLocalizations? l10n,
  }) async {
    final nameCtrl = TextEditingController(text: initialName);
    final tagsCtrl = TextEditingController(text: initialTags);
    final effectiveL10n = l10n ?? _l10n;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: effectiveL10n.name,
                labelStyle: TextStyle(color: AppColors.textCaption),
                hintText: effectiveL10n.projectName,
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: AppColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.sky500),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tagsCtrl,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: effectiveL10n.tags,
                labelStyle: TextStyle(color: AppColors.textCaption),
                hintText: effectiveL10n.tagsHint,
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: AppColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.sky500),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              effectiveL10n.cancel,
              style: TextStyle(color: AppColors.textCaption),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final tags = tagsCtrl.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              Navigator.pop(ctx, {'name': name, 'tags': tags});
            },
            child: Text(
              title.contains('New') ? effectiveL10n.create : effectiveL10n.save,
              style: const TextStyle(
                color: AppColors.sky500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return result;
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return AppShell(
      title: _l10n.projects,
      leading: const SizedBox(width: 0),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: Text(
              _l10n.newProject,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.sky500,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _createProject,
          ),
        ),
      ],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    hintText: _l10n.searchProjects,
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppColors.cardBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.sky500),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: Icon(
                  Icons.upload_file,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
                label: Text(
                  _l10n.importJson,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.cardBg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                onPressed: _importJson,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.rose600.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.rose600.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.rose300, fontSize: 13),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.sky500),
                  )
                : filtered.isEmpty
                ? _emptyState()
                : _projectGrid(filtered),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _l10n.noProjectsYet,
              style: TextStyle(color: AppColors.textCaption, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: Text(
                _l10n.newProject,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.sky500,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _createProject,
            ),
          ],
        ),
      ),
    );
  }

  Widget _projectGrid(List<ProjectListItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
            ? 2
            : 1;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _ProjectCard(
            item: items[index],
            onOpen: () => _openProject(items[index].id),
            onRename: () => _renameProject(items[index]),
            onDuplicate: () => _duplicateProject(items[index].id),
            onDelete: () => _deleteProject(items[index]),
            onExportJson: () => _exportJson(items[index]),
            onExportPrint: () => _openExport(items[index].id),
            formatDate: _formatDate,
            l10n: _l10n,
          ),
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectListItem item;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onExportJson;
  final VoidCallback onExportPrint;
  final String Function(String) formatDate;
  final AppLocalizations l10n;

  const _ProjectCard({
    required this.item,
    required this.onOpen,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
    required this.onExportJson,
    required this.onExportPrint,
    required this.formatDate,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.updated(formatDate(item.updatedAt)),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _cardIconBtn(Icons.edit_outlined, onRename),
                  _cardIconBtn(Icons.copy, onDuplicate),
                  _cardIconBtn(
                    Icons.delete_outline,
                    onDelete,
                    color: AppColors.rose300,
                  ),
                ],
              ),
            ],
          ),
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: item.tags
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                        color: AppColors.surface.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          color: AppColors.textBody,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: Icon(
                  Icons.folder_open,
                  size: 16,
                  color: AppColors.buttonMutedFg,
                ),
                label: Text(
                  l10n.open,
                  style: TextStyle(
                    color: AppColors.buttonMutedFg,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.buttonMutedBg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onOpen,
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onExportPrint,
                    child: Text(
                      l10n.exportPdf,
                      style: TextStyle(color: AppColors.sky400, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onExportJson,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download,
                          size: 14,
                          color: AppColors.textBody,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          l10n.exportJson,
                          style: TextStyle(
                            color: AppColors.textBody,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardIconBtn(
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    final c = color ?? AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle),
          color: AppColors.surface.withValues(alpha: 0.2),
        ),
        child: Icon(icon, size: 14, color: c),
      ),
    );
  }
}
