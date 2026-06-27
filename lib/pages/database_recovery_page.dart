import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/database_file_validator.dart';
import '../utils/colors.dart';

class DatabaseRecoveryPage extends StatelessWidget {
  final DatabaseValidationIssue? issue;
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onChooseAnother;
  final VoidCallback onUseDefault;

  const DatabaseRecoveryPage({
    super.key,
    required this.issue,
    required this.busy,
    required this.onRetry,
    required this.onChooseAnother,
    required this.onUseDefault,
  });

  String _message(AppLocalizations l10n) {
    return switch (issue) {
      DatabaseValidationIssue.notFound => l10n.databaseNotFound,
      DatabaseValidationIssue.newerVersion => l10n.databaseNewerVersion,
      DatabaseValidationIssue.invalidSqlite ||
      DatabaseValidationIssue.incompatibleSchema ||
      DatabaseValidationIssue.notAFile => l10n.databaseInvalid,
      _ => l10n.databaseUnreadable,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        width: 460,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.storage_outlined,
              color: AppColors.rose600,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.databaseRecoveryTitle,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _message(l10n),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textBody, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: busy ? null : onRetry,
                  child: Text(l10n.retry),
                ),
                OutlinedButton(
                  onPressed: busy ? null : onChooseAnother,
                  child: Text(l10n.chooseAnotherDatabase),
                ),
                FilledButton(
                  onPressed: busy ? null : onUseDefault,
                  child: Text(l10n.useDefaultDatabase),
                ),
              ],
            ),
            if (busy) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: AppColors.sky500),
            ],
          ],
        ),
      ),
    );
  }
}
