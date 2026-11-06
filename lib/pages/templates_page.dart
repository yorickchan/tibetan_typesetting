import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/title_page_template.dart';
import '../services/title_page_template_service.dart';
import '../utils/colors.dart';
import '../utils/snackbar.dart';
import '../widgets/app_shell.dart';
import '../widgets/text_field_dialog.dart';

/// Manages the SVG title-page templates used when composing a document.
class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  final _service = TitlePageTemplateService();
  List<TitlePageTemplate> _templates = [];
  bool _loading = true;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await _service.listTemplates();
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _loading = false;
    });
  }

  Future<void> _addTemplate() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['svg'],
    );
    if (files.isEmpty) return;

    final file = files.first;
    final path = file.path;
    if (path == null) return;

    final content = await File(path).readAsString();
    if (!content.contains('<svg')) {
      if (mounted) {
        showAppSnackBar(context, _l10n.invalidSvgFile, error: true);
      }
      return;
    }

    if (!mounted) return;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => TextFieldDialog(
        title: _l10n.addTemplate,
        label: _l10n.templateName,
        confirmLabel: _l10n.create,
      ),
    );
    if (name == null || name.isEmpty) return;

    await _service.addTemplate(name, content);
    _loadTemplates();
  }

  Future<void> _renameTemplate(TitlePageTemplate template) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => TextFieldDialog(
        title: _l10n.templateName,
        label: _l10n.templateName,
        confirmLabel: _l10n.save,
        initialValue: template.name,
      ),
    );
    if (name == null || name.isEmpty) return;

    await _service.renameTemplate(template.id, name);
    _loadTemplates();
  }

  Future<void> _deleteTemplate(TitlePageTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          _l10n.deleteTemplate,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          _l10n.areYouSureDelete(template.name),
          style: TextStyle(color: AppColors.textBody, fontSize: 13),
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
              style: const TextStyle(
                color: AppColors.rose600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _service.deleteTemplate(template.id);
    _loadTemplates();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: _l10n.titlePageTemplates,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: Text(
              _l10n.addTemplate,
              style: const TextStyle(
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
            onPressed: _addTemplate,
          ),
        ),
      ],
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.sky500),
            )
          : _templates.isEmpty
          ? Center(
              child: Text(
                _l10n.noEntriesYet,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              itemCount: _templates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final template = _templates[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: AppColors.textCaption,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _renameTemplate(template),
                          child: Text(
                            template.name,
                            style: TextStyle(
                              color: AppColors.textBody,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: AppColors.rose600,
                        ),
                        onPressed: () => _deleteTemplate(template),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
