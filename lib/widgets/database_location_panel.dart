import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/colors.dart';

class DatabaseLocationPanel extends StatelessWidget {
  final String path;
  final bool usesDefault;
  final bool restartRequired;
  final bool busy;
  final VoidCallback onOpenExisting;
  final VoidCallback onUseDefault;

  const DatabaseLocationPanel({
    super.key,
    required this.path,
    required this.usesDefault,
    required this.restartRequired,
    required this.busy,
    required this.onOpenExisting,
    required this.onUseDefault,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.currentDatabase,
          style: TextStyle(color: AppColors.textCaption, fontSize: 11),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: SelectableText(
            path,
            style: TextStyle(color: AppColors.textBody, fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.cloudDatabaseWarning,
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        if (restartRequired) ...[
          const SizedBox(height: 8),
          Text(
            l10n.databaseRestartRequired,
            style: const TextStyle(color: AppColors.sky500, fontSize: 11),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: busy ? null : onOpenExisting,
              icon: const Icon(Icons.folder_open, size: 16),
              label: Text(l10n.openExistingDatabase),
            ),
            OutlinedButton(
              onPressed: busy || usesDefault ? null : onUseDefault,
              child: Text(l10n.useDefaultDatabase),
            ),
          ],
        ),
      ],
    );
  }
}
