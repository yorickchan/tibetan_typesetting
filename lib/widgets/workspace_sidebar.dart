import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../utils/colors.dart';

/// Top-level destinations reachable from the workspace sidebar.
enum WorkspaceSection { projects, dictionary, templates, settings }

/// Fixed-width navigation rail for the workspace root.
///
/// Mirrors the reference layout: product title, a WORKSPACE group with four
/// destinations, then a RECENT PROJECTS list that opens the editor directly.
class WorkspaceSidebar extends StatelessWidget {
  final WorkspaceSection selected;
  final ValueChanged<WorkspaceSection> onSelected;
  final List<ProjectListItem> recentProjects;
  final ValueChanged<ProjectListItem> onOpenProject;

  const WorkspaceSidebar({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.recentProjects,
    required this.onOpenProject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 204,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        right: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.workspaceTitle.toUpperCase(),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _sectionLabel(l10n.workspaceSection),
              const SizedBox(height: 8),
              _NavItem(
                glyph: 'P',
                label: l10n.projects,
                selected: selected == WorkspaceSection.projects,
                onTap: () => onSelected(WorkspaceSection.projects),
              ),
              _NavItem(
                glyph: '文',
                label: l10n.dictionary,
                selected: selected == WorkspaceSection.dictionary,
                onTap: () => onSelected(WorkspaceSection.dictionary),
              ),
              _NavItem(
                glyph: 'T',
                label: l10n.templates,
                selected: selected == WorkspaceSection.templates,
                onTap: () => onSelected(WorkspaceSection.templates),
              ),
              _NavItem(
                glyph: 'S',
                label: l10n.settings,
                selected: selected == WorkspaceSection.settings,
                onTap: () => onSelected(WorkspaceSection.settings),
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 20),
              _sectionLabel(l10n.recentProjects),
              const SizedBox(height: 6),
              ...recentProjects.map(
                (project) => InkWell(
                  onTap: () => onOpenProject(project),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 7,
                    ),
                    child: Text(
                      project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.navText,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String glyph;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.glyph,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.navSelectedText : AppColors.navText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppColors.navSelectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? AppColors.navSelectedBorder
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: Text(
                    glyph,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
