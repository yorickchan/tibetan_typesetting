import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/font_config.dart';
import '../models/title_page_template.dart';
import '../pages/dictionary_page.dart';
import '../services/database_file_validator.dart';
import '../services/database_location_provider.dart';
import '../services/font_service.dart';
import '../services/settings_service.dart';
import '../utils/snackbar.dart';
import '../services/title_page_template_service.dart';
import '../utils/colors.dart';
import '../widgets/font_picker.dart';
import '../widgets/database_location_panel.dart';

/// Application-level settings dialog for default fonts and page size.
class SettingsPage extends StatefulWidget {
  /// When true the dialog cannot be dismissed without configuring at least one
  /// font (used on first launch).
  final bool requireFonts;

  const SettingsPage({super.key, this.requireFonts = false});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsService = SettingsService();
  final _fontService = FontService();
  final _databaseLocationService = createDatabaseLocationService();
  AppSettings? _settings;
  List<TitlePageTemplate> _templates = [];
  bool _templatesLoading = true;
  void _showSnackMsg(String msg, {bool error = false}) {
    if (!mounted) return;
    showAppSnackBar(context, msg, error: error);
  }

  bool _loading = true;
  bool _saving = false;
  bool _databaseBusy = false;
  bool _databaseRestartRequired = false;
  bool _usesDefaultDatabase = true;
  String _databasePath = '';

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  late TextEditingController _widthCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _tibSizeCtrl;
  late TextEditingController _pronSizeCtrl;
  late TextEditingController _transSizeCtrl;
  late TextEditingController _smallBlockSizeCtrl;

  @override
  void initState() {
    super.initState();
    _widthCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    _tibSizeCtrl = TextEditingController();
    _pronSizeCtrl = TextEditingController();
    _smallBlockSizeCtrl = TextEditingController();
    _transSizeCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _tibSizeCtrl.dispose();
    _pronSizeCtrl.dispose();
    _smallBlockSizeCtrl.dispose();
    _transSizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await _settingsService.getSettings();
    final databasePreference = await _databaseLocationService.getPreference();
    final databasePath = await _databaseLocationService.getDisplayPath();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _usesDefaultDatabase = databasePreference.usesDefault;
      _databasePath = databasePath;
      _loadTemplates();
      _loading = false;
      _widthCtrl.text = settings.defaultPageWidthMm.toStringAsFixed(0);
      _heightCtrl.text = settings.defaultPageHeightMm.toStringAsFixed(0);
      _tibSizeCtrl.text = (settings.tibetanFont?.fontSize ?? 10)
          .toStringAsFixed(1);
      _pronSizeCtrl.text = (settings.pronunciationFont?.fontSize ?? 8)
          .toStringAsFixed(1);
      _transSizeCtrl.text = (settings.translationFont?.fontSize ?? 8)
          .toStringAsFixed(1);
      _smallBlockSizeCtrl.text =
          settings.smallBlockFontSize?.toStringAsFixed(1) ?? '';
    });
  }

  String _databaseError(DatabaseValidationIssue? issue) {
    return switch (issue) {
      DatabaseValidationIssue.notFound => _l10n.databaseNotFound,
      DatabaseValidationIssue.newerVersion => _l10n.databaseNewerVersion,
      DatabaseValidationIssue.directoryAccessRequired =>
        _l10n.databaseFolderAccessRequired,
      DatabaseValidationIssue.invalidSqlite ||
      DatabaseValidationIssue.incompatibleSchema ||
      DatabaseValidationIssue.notAFile => _l10n.databaseInvalid,
      _ => _l10n.databaseUnreadable,
    };
  }

  Future<void> _openExistingDatabase() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['db'],
      dialogTitle: _l10n.openExistingDatabase,
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(_l10n.cloudDatabaseConfirmationTitle),
        content: Text(_l10n.cloudDatabaseConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_l10n.continueLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    String? bookmarkRootPath;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      bookmarkRootPath = await FilePicker.getDirectoryPath(
        dialogTitle: _l10n.authorizeDatabaseFolder,
        initialDirectory: p.dirname(path),
      );
      if (bookmarkRootPath == null || !mounted) return;
    }

    setState(() => _databaseBusy = true);
    final selection = await _databaseLocationService.selectExisting(
      path,
      bookmarkRootPath: bookmarkRootPath,
    );
    if (!mounted) return;
    setState(() => _databaseBusy = false);
    if (!selection.isValid) {
      _showSnackMsg(_databaseError(selection.issue), error: true);
      return;
    }
    setState(() {
      _databasePath = path;
      _usesDefaultDatabase = false;
      _databaseRestartRequired = true;
    });
  }

  Future<void> _useDefaultDatabase() async {
    setState(() => _databaseBusy = true);
    await _databaseLocationService.useDefault();
    final path = await _databaseLocationService.getDisplayPath();
    if (!mounted) return;
    setState(() {
      _databaseBusy = false;
      _databasePath = path;
      _usesDefaultDatabase = true;
      _databaseRestartRequired = true;
    });
  }

  Future<void> _loadTemplates() async {
    final templates = await TitlePageTemplateService().listTemplates();
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _templatesLoading = false;
    });
  }

  Future<void> _addTemplate() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['svg'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final content = !kIsWeb && file.path != null
        ? await File(file.path!).readAsString()
        : utf8.decode(file.bytes!);
    if (!content.contains('<svg')) {
      if (mounted) {
        _showSnackMsg(_l10n.invalidSvgFile, error: true);
      }
      return;
    }

    if (!mounted) return;
    final name = await _templateNameDialog();
    if (name == null || name.isEmpty) return;

    await TitlePageTemplateService().addTemplate(name, content);
    _loadTemplates();
  }

  Future<String?> _templateNameDialog() {
    return showDialog<String>(
      context: context,
      builder: (ctx) => _TextFieldDialog(
        title: _l10n.addTemplate,
        label: _l10n.templateName,
        confirmLabel: _l10n.create,
        initialValue: '',
      ),
    );
  }

  Future<void> _deleteTemplateDialog(TitlePageTemplate t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          _l10n.deleteTemplate,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          _l10n.areYouSureDelete(t.name),
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
    if (ok == true) {
      await TitlePageTemplateService().deleteTemplate(t.id);
      _loadTemplates();
    }
  }

  Future<void> _renameTemplateDialog(TitlePageTemplate t) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _TextFieldDialog(
        title: _l10n.templateName,
        label: _l10n.templateName,
        confirmLabel: _l10n.save,
        initialValue: t.name,
      ),
    );
    if (name != null && name.isNotEmpty) {
      await TitlePageTemplateService().renameTemplate(t.id, name);
      _loadTemplates();
    }
  }

  Future<void> _save() async {
    if (_settings == null) return;
    setState(() => _saving = true);
    await _settingsService.updateSettings(_settings!);

    final configs = [
      _settings!.tibetanFont,
      _settings!.pronunciationFont,
      _settings!.translationFont,
    ];
    for (final c in configs) {
      if (c != null) await _fontService.loadFontForPreview(c);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(_settings);
  }

  void _updateTibetanFont(SystemFontInfo info) {
    setState(() {
      _settings = _settings!.copyWith(
        tibetanFont: FontConfig(
          fontFamily: info.familyName,
          fontPath: info.filePath,
          fontSize: _settings!.tibetanFont?.fontSize ?? 10,
        ),
      );
    });
  }

  void _updatePronunciationFont(SystemFontInfo info) {
    setState(() {
      _settings = _settings!.copyWith(
        pronunciationFont: FontConfig(
          fontFamily: info.familyName,
          fontPath: info.filePath,
          fontSize: _settings!.pronunciationFont?.fontSize ?? 8,
        ),
      );
    });
  }

  void _updateTranslationFont(SystemFontInfo info) {
    setState(() {
      _settings = _settings!.copyWith(
        translationFont: FontConfig(
          fontFamily: info.familyName,
          fontPath: info.filePath,
          fontSize: _settings!.translationFont?.fontSize ?? 8,
        ),
      );
    });
  }

  void _updateTibetanSize(String v) {
    final n = double.tryParse(v);
    if (n == null || n <= 0 || _settings!.tibetanFont == null) return;
    setState(() {
      _settings = _settings!.copyWith(
        tibetanFont: _settings!.tibetanFont!.copyWith(fontSize: n),
      );
    });
  }

  void _updatePronunciationSize(String v) {
    final n = double.tryParse(v);
    if (n == null || n <= 0 || _settings!.pronunciationFont == null) return;
    setState(() {
      _settings = _settings!.copyWith(
        pronunciationFont: _settings!.pronunciationFont!.copyWith(fontSize: n),
      );
    });
  }

  void _updateTranslationSize(String v) {
    final n = double.tryParse(v);
    if (n == null || n <= 0 || _settings!.translationFont == null) return;
    setState(() {
      _settings = _settings!.copyWith(
        translationFont: _settings!.translationFont!.copyWith(fontSize: n),
      );
    });
  }

  bool get _canSave {
    if (widget.requireFonts) {
      return _settings?.hasAnyFontConfigured ?? false;
    }
    return true;
  }

  void _updateSmallBlockSize(String v) {
    if (v.isEmpty) {
      setState(() {
        _settings = _settings!.copyWith(clearSmallBlockFontSize: true);
      });
      return;
    }
    final n = double.tryParse(v);
    if (n == null || n <= 0) return;
    setState(() {
      _settings = _settings!.copyWith(smallBlockFontSize: n);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 520,
        child: _loading
            ? const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.sky500),
                ),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _l10n.applicationSettings,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!widget.requireFonts)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textCaption,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
          ),
          if (widget.requireFonts) ...[
            const SizedBox(height: 4),
            Text(
              _l10n.configureFonts,
              style: TextStyle(color: AppColors.textCaption, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),

          _sectionLabel(_l10n.defaultFonts),
          const SizedBox(height: 12),

          _fontRow(
            label: _l10n.tibetan.toUpperCase(),
            selectedPath: _settings!.tibetanFont?.fontPath,
            onSelected: _updateTibetanFont,
            sizeCtrl: _tibSizeCtrl,
            onSizeChanged: _updateTibetanSize,
          ),
          const SizedBox(height: 12),
          _fontRow(
            label: _l10n.pronunciation.toUpperCase(),
            selectedPath: _settings!.pronunciationFont?.fontPath,
            onSelected: _updatePronunciationFont,
            sizeCtrl: _pronSizeCtrl,
            onSizeChanged: _updatePronunciationSize,
          ),
          const SizedBox(height: 12),
          _fontRow(
            label: _l10n.translation.toUpperCase(),
            selectedPath: _settings!.translationFont?.fontPath,
            onSelected: _updateTranslationFont,
            sizeCtrl: _transSizeCtrl,
            onSizeChanged: _updateTranslationSize,
          ),

          if (_settings!.tibetanFont != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _numberField(
                    controller: _smallBlockSizeCtrl,
                    label: _l10n.smallBlockFontSizeLabel,
                    onChanged: _updateSmallBlockSize,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          _sectionLabel(_l10n.defaultPageSize),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _widthCtrl,
                  label: '${_l10n.width} (mm)',
                  onChanged: (v) {
                    final n = double.tryParse(v);
                    if (n != null && n >= 50) {
                      setState(
                        () => _settings = _settings!.copyWith(
                          defaultPageWidthMm: n,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                  controller: _heightCtrl,
                  label: '${_l10n.height} (mm)',
                  onChanged: (v) {
                    final n = double.tryParse(v);
                    if (n != null && n >= 50) {
                      setState(
                        () => _settings = _settings!.copyWith(
                          defaultPageHeightMm: n,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _sectionLabel(_l10n.titlePageTemplates.toUpperCase()),
          const SizedBox(height: 12),
          ..._templates.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _renameTemplateDialog(t),
                        child: Text(
                          t.name,
                          style: TextStyle(
                            color: AppColors.textBody,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: AppColors.rose600,
                      ),
                      onPressed: () => _deleteTemplateDialog(t),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_templates.isEmpty && !_templatesLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _l10n.noEntriesYet,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addTemplate,
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                _l10n.addTemplate,
                style: const TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.sky500),
            ),
          ),
          const SizedBox(height: 24),

          _sectionLabel('DICTIONARY'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const DictionaryPage()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.book, size: 16, color: AppColors.textCaption),
                  const SizedBox(width: 8),
                  Text(
                    'Pronunciation Dictionary',
                    style: TextStyle(color: AppColors.textBody, fontSize: 13),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (!kIsWeb) ...[
            const SizedBox(height: 24),
            _sectionLabel(_l10n.database.toUpperCase()),
            const SizedBox(height: 12),
            DatabaseLocationPanel(
              path: _databasePath,
              usesDefault: _usesDefaultDatabase,
              restartRequired: _databaseRestartRequired,
              busy: _databaseBusy,
              onOpenExisting: _openExistingDatabase,
              onUseDefault: _useDefaultDatabase,
            ),
            const SizedBox(height: 24),
          ],

          _sectionLabel(_l10n.language.toUpperCase()),
          const SizedBox(height: 12),
          _buildLanguageSelector(),

          const SizedBox(height: 24),

          _sectionLabel(_l10n.theme.toUpperCase()),
          const SizedBox(height: 12),
          _buildThemeSelector(),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!widget.requireFonts)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    _l10n.cancel,
                    style: TextStyle(color: AppColors.textCaption),
                  ),
                ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _canSave && !_saving ? _save : null,
                style: TextButton.styleFrom(
                  backgroundColor: _canSave
                      ? AppColors.sky500
                      : AppColors.border,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _saving ? _l10n.saving : _l10n.save,
                  style: TextStyle(
                    color: _canSave ? Colors.white : AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _fontRow({
    required String label,
    required String? selectedPath,
    required ValueChanged<SystemFontInfo> onSelected,
    required TextEditingController sizeCtrl,
    required ValueChanged<String> onSizeChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 3,
          child: FontPicker(
            label: label,
            selectedPath: selectedPath,
            onSelected: onSelected,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: _numberField(
            controller: sizeCtrl,
            label: '${_l10n.size} (pt)',
            onChanged: onSizeChanged,
          ),
        ),
      ],
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textCaption,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            filled: true,
            fillColor: AppColors.inputFill,
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
    );
  }

  Widget _buildLanguageSelector() {
    final languages = [
      (null, _l10n.systemDefault),
      ('en', 'English'),
      ('zh', '简体中文'),
      ('zh_TW', '繁體中文'),
    ];

    return DropdownButtonFormField<String>(
      initialValue: _settings?.locale,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
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
      dropdownColor: AppColors.surfaceContainer,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
      items: languages.map((lang) {
        return DropdownMenuItem<String>(value: lang.$1, child: Text(lang.$2));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _settings = _settings!.copyWith(
            locale: value,
            clearLocale: value == null,
          );
        });
      },
    );
  }

  Widget _buildThemeSelector() {
    final themes = [
      (AppTheme.system, _l10n.themeSystem),
      (AppTheme.light, _l10n.themeLight),
      (AppTheme.dark, _l10n.themeDark),
    ];

    return DropdownButtonFormField<AppTheme>(
      initialValue: _settings?.theme ?? AppTheme.dark,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
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
      dropdownColor: AppColors.surfaceContainer,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
      items: themes.map((t) {
        return DropdownMenuItem<AppTheme>(value: t.$1, child: Text(t.$2));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _settings = _settings!.copyWith(theme: value);
          });
        }
      },
    );
  }
}

class _TextFieldDialog extends StatefulWidget {
  final String title;
  final String label;
  final String confirmLabel;
  final String initialValue;

  const _TextFieldDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.initialValue,
  });

  @override
  State<_TextFieldDialog> createState() => _TextFieldDialogState();
}

class _TextFieldDialogState extends State<_TextFieldDialog> {
  late final _ctrl = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.title, style: TextStyle(color: AppColors.textPrimary)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(color: AppColors.textCaption),
          filled: true,
          fillColor: AppColors.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.cancel,
            style: TextStyle(color: AppColors.textCaption),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: Text(
            widget.confirmLabel,
            style: const TextStyle(
              color: AppColors.sky500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
