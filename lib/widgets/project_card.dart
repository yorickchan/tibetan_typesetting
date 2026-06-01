import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../utils/colors.dart';

class ProjectCard extends StatelessWidget {
  final ProjectListItem item;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onExportJson;
  final VoidCallback onExportPrint;
  final String Function(String) formatDate;
  final AppLocalizations l10n;

  const ProjectCard({
    super.key,
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
