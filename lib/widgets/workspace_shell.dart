import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/project.dart';
import '../pages/dictionary_page.dart';
import '../pages/editor_page.dart';
import '../pages/projects_page.dart';
import '../pages/settings_page.dart';
import '../pages/templates_page.dart';
import '../services/database_service.dart';
import 'workspace_sidebar.dart';

/// Root workspace: fixed left sidebar plus the selected destination.
class WorkspaceShell extends StatefulWidget {
  final ValueChanged<AppSettings> onSettingsChanged;

  const WorkspaceShell({super.key, required this.onSettingsChanged});

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  final _db = DatabaseService();
  WorkspaceSection _section = WorkspaceSection.projects;
  List<ProjectListItem> _recentProjects = [];

  @override
  void initState() {
    super.initState();
    _loadRecentProjects();
  }

  Future<void> _loadRecentProjects() async {
    try {
      final projects = await _db.listProjects();
      if (!mounted) return;
      setState(() => _recentProjects = projects.take(8).toList());
    } on Exception catch (e) {
      debugPrint('Failed to load recent projects: $e');
    }
  }

  Future<void> _openProject(ProjectListItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditorPage(projectId: item.id)),
    );
    _loadRecentProjects();
  }

  void _selectSection(WorkspaceSection section) {
    if (_section == section) return;
    setState(() => _section = section);
  }

  Widget _buildContent() {
    switch (_section) {
      case WorkspaceSection.projects:
        return ProjectsPage(onProjectsChanged: _loadRecentProjects);
      case WorkspaceSection.dictionary:
        return const DictionaryPage();
      case WorkspaceSection.templates:
        return const TemplatesPage();
      case WorkspaceSection.settings:
        return SettingsPage(asPage: true, onSaved: widget.onSettingsChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorkspaceSidebar(
            selected: _section,
            onSelected: _selectSection,
            recentProjects: _recentProjects,
            onOpenProject: _openProject,
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}
