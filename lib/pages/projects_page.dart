import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/project.dart';
import '../services/database_service.dart';
import '../utils/colors.dart';
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

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.rose600 : AppColors.sky500,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
    final result = await _showNameTagsDialog(
      title: 'New Project',
      initialName: 'Untitled',
    );
    if (result == null) return;
    try {
      final project = await _db.createProject(
        name: result['name'] as String,
        tags: result['tags'] as List<String>,
      );
      _showSnack('Project created');
      if (mounted) _openProject(project.id);
    } catch (e) {
      _showSnack('Failed to create project', error: true);
    }
  }

  Future<void> _renameProject(ProjectListItem item) async {
    final result = await _showNameTagsDialog(
      title: 'Rename Project',
      initialName: item.name,
      initialTags: item.tags.join(', '),
    );
    if (result == null) return;
    try {
      final project = await _db.getProject(item.id);
      if (project == null) return;
      project.name = result['name'] as String;
      project.tags = result['tags'] as List<String>;
      await _db.updateProject(project);
      _showSnack('Project updated');
      _loadProjects();
    } catch (e) {
      _showSnack('Failed to update project', error: true);
    }
  }

  Future<void> _deleteProject(ProjectListItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate900,
        title: const Text(
          'Delete Project',
          style: TextStyle(color: AppColors.slate100),
        ),
        content: Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Are you sure you want to delete ',
                style: TextStyle(color: AppColors.slate300),
              ),
              TextSpan(
                text: item.name,
                style: const TextStyle(
                  color: AppColors.slate100,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(
                text: '? This cannot be undone.',
                style: TextStyle(color: AppColors.slate300),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.slate400),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.rose400),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _db.deleteProject(item.id);
      _showSnack('Project deleted');
      _loadProjects();
    } catch (e) {
      _showSnack('Failed to delete project', error: true);
    }
  }

  Future<void> _duplicateProject(String projectId) async {
    try {
      final copy = await _db.duplicateProject(projectId);
      _showSnack('Project duplicated');
      if (mounted) _openProject(copy.id);
    } catch (e) {
      _showSnack('Failed to duplicate project', error: true);
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
      _showSnack('Project exported');
    } catch (e) {
      _showSnack('Failed to export project', error: true);
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
      _showSnack('Project imported');
      if (mounted) _openProject(imported.id);
    } catch (e) {
      _showSnack('Failed to import project', error: true);
    }
  }

  Future<Map<String, dynamic>?> _showNameTagsDialog({
    required String title,
    String initialName = '',
    String initialTags = '',
  }) async {
    final nameCtrl = TextEditingController(text: initialName);
    final tagsCtrl = TextEditingController(text: initialTags);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate900,
        title: Text(title, style: const TextStyle(color: AppColors.slate100)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.slate100, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: const TextStyle(color: AppColors.slate400),
                hintText: 'Project name',
                hintStyle: TextStyle(
                  color: AppColors.slate500.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: AppColors.slate800,
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
            const SizedBox(height: 12),
            TextField(
              controller: tagsCtrl,
              style: const TextStyle(color: AppColors.slate100, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Tags',
                labelStyle: const TextStyle(color: AppColors.slate400),
                hintText: 'Comma-separated tags',
                hintStyle: TextStyle(
                  color: AppColors.slate500.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: AppColors.slate800,
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.slate400),
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
              title.contains('New') ? 'Create' : 'Save',
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
      title: 'Projects',
      leading: const SizedBox(width: 0),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text(
              'New Project',
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
                  style: const TextStyle(
                    color: AppColors.slate100,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.slate500,
                      size: 18,
                    ),
                    hintText: 'Search projects',
                    hintStyle: const TextStyle(
                      color: AppColors.slate500,
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
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(
                  Icons.upload_file,
                  size: 16,
                  color: AppColors.slate100,
                ),
                label: const Text(
                  'Import JSON',
                  style: TextStyle(color: AppColors.slate100, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.cardBg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.slate800),
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
            const Text(
              'No projects yet. Create one to start.',
              style: TextStyle(color: AppColors.slate400, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text(
                'New Project',
                style: TextStyle(
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

  const _ProjectCard({
    required this.item,
    required this.onOpen,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
    required this.onExportJson,
    required this.onExportPrint,
    required this.formatDate,
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
                      style: const TextStyle(
                        color: AppColors.slate100,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Updated ${formatDate(item.updatedAt)}',
                      style: const TextStyle(
                        color: AppColors.slate500,
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
                        border: Border.all(color: AppColors.slate800),
                        color: AppColors.slate900.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          color: AppColors.slate300,
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
                icon: const Icon(
                  Icons.folder_open,
                  size: 16,
                  color: AppColors.slate900,
                ),
                label: const Text(
                  'Open',
                  style: TextStyle(
                    color: AppColors.slate900,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.slate100,
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
                    child: const Text(
                      'Export PDF',
                      style: TextStyle(color: AppColors.sky400, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onExportJson,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.download,
                          size: 14,
                          color: AppColors.slate300,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'JSON',
                          style: TextStyle(
                            color: AppColors.slate300,
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
    Color color = AppColors.slate200,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.slate800),
          color: AppColors.slate900.withValues(alpha: 0.2),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
