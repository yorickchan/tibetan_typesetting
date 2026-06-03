import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/pronunciation_entry.dart';
import '../services/pronunciation_service.dart';
import '../utils/colors.dart';
import '../widgets/app_shell.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final _pronunciationService = PronunciationService();
  final _searchCtrl = TextEditingController();
  List<PronunciationEntry> _entries = [];
  List<PronunciationEntry> _filtered = [];
  bool _loading = true;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    try {
      final entries = await _pronunciationService.getAllEntries();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _filtered = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack('Failed to load dictionary: $e', error: true);
    }
  }

  void _filterEntries(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _entries
          : _entries
                .where(
                  (e) =>
                      e.tibetanSyllable.toLowerCase().contains(q) ||
                      e.chinesePronunciation.toLowerCase().contains(q),
                )
                .toList();
    });
  }

  Future<void> _deleteEntry(PronunciationEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          _l10n.delete,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          _l10n.deleteEntry(entry.tibetanSyllable),
          style: TextStyle(color: AppColors.textBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _l10n.cancel,
              style: TextStyle(color: AppColors.textCaption),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _l10n.delete,
              style: TextStyle(color: AppColors.rose400),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _pronunciationService.deleteEntry(entry.tibetanSyllable);
    _showSnack(_l10n.projectDeleted);
    _loadEntries();
  }

  Future<void> _editEntry(PronunciationEntry entry) async {
    final ctrl = TextEditingController(text: entry.chinesePronunciation);
    try {
    int wordCount = entry.wordCount;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            entry.tibetanSyllable,
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: _l10n.chinesePronunciation,
                  labelStyle: TextStyle(color: AppColors.textCaption),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    _l10n.charactersInPronunciation,
                    style: TextStyle(
                      color: AppColors.textCaption,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      icon: Icon(
                        Icons.remove,
                        color: wordCount > 1
                            ? AppColors.textCaption
                            : AppColors.textFaint,
                      ),
                      onPressed: wordCount > 1
                          ? () => setDialogState(() => wordCount--)
                          : null,
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$wordCount',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      icon: Icon(
                        Icons.add,
                        color: wordCount < 10
                            ? AppColors.textCaption
                            : AppColors.textFaint,
                      ),
                      onPressed: wordCount < 10
                          ? () => setDialogState(() => wordCount++)
                          : null,
                    ),
                  ),
                ],
              ),
              if (wordCount > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _l10n.syllableMapsToChars(wordCount),
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                _l10n.cancel,
                style: TextStyle(color: AppColors.textCaption),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                _l10n.save,
                style: const TextStyle(
                  color: AppColors.sky500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != true) return;
    await _pronunciationService.updatePronunciation(
      entry.tibetanSyllable,
      ctrl.text,
      wordCount: wordCount,
    );
    _showSnack(_l10n.saved);
    _loadEntries();
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _exportJson() async {
    try {
      final json = await _pronunciationService.exportToJson();
      final path = await FilePicker.saveFile(
        dialogTitle: _l10n.exportDictionary,
        fileName: 'pronunciation_dictionary.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (path == null) return;
      await File(path).writeAsString(json);
      _showSnack(_l10n.projectExported);
    } catch (e) {
      _showSnack(_l10n.failedToExportProject, error: true);
    }
  }

  Future<void> _importJson() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = File(result.files.single.path!);
      final json = await file.readAsString();
      final count = await _pronunciationService.importFromJson(json);
      _showSnack(_l10n.importedCount(count));
      _loadEntries();
    } catch (e) {
      _showSnack(_l10n.failedToImportProject, error: true);
    }
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

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: _l10n.pronunciationDictionary,
      actions: [
        TextButton.icon(
          icon: Icon(Icons.upload_file, size: 16, color: AppColors.textCaption),
          label: Text(
            _l10n.import,
            style: TextStyle(color: AppColors.textCaption, fontSize: 12),
          ),
          onPressed: _importJson,
        ),
        TextButton.icon(
          icon: Icon(Icons.download, size: 16, color: AppColors.textCaption),
          label: Text(
            _l10n.export,
            style: TextStyle(color: AppColors.textCaption, fontSize: 12),
          ),
          onPressed: _exportJson,
        ),
        const SizedBox(width: 8),
      ],
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: _filterEntries,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.textMuted,
                size: 18,
              ),
              hintText: _l10n.searchEntries,
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
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
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.sky500),
                  )
                : _filtered.isEmpty
                ? Center(
                    child: Text(
                      _entries.isEmpty
                          ? _l10n.noEntriesYet
                          : _l10n.noMatchingEntries,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) => _EntryCard(
                      entry: _filtered[index],
                      onEdit: () => _editEntry(_filtered[index]),
                      onDelete: () => _deleteEntry(_filtered[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final PronunciationEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.tibetanSyllable,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (entry.wordCount > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sky500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.sky500.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '×${entry.wordCount}',
                          style: const TextStyle(
                            color: AppColors.sky500,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.chinesePronunciation,
                  style: TextStyle(color: AppColors.textBody, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.textCaption,
            ),
            onPressed: onEdit,
            tooltip: l10n.edit,
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: AppColors.rose400,
            ),
            onPressed: onDelete,
            tooltip: l10n.delete,
          ),
        ],
      ),
    );
  }
}
