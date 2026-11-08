import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../utils/colors.dart';
import '../utils/snackbar.dart';

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
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  path,
                  style: TextStyle(color: AppColors.textBody, fontSize: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                color: AppColors.textSecondary,
                tooltip: l10n.copyPath,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: path));
                  if (context.mounted) {
                    showAppSnackBar(context, l10n.copied);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.cloudDatabaseWarning,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
            FilledButton.icon(
              onPressed: busy ? null : onOpenExisting,
              icon: const Icon(Icons.folder_open, size: 16),
              label: Text(l10n.openExistingDatabase),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sky500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            OutlinedButton(
              onPressed: busy || usesDefault ? null : onUseDefault,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.useDefaultDatabase),
            ),
          ],
        ),
      ],
    );
  }
}
