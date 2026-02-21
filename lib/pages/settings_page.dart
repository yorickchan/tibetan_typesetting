import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/font_config.dart';
import '../services/font_service.dart';
import '../services/settings_service.dart';
import '../utils/colors.dart';
import '../widgets/font_picker.dart';

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
  AppSettings? _settings;
  bool _loading = true;
  bool _saving = false;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  late TextEditingController _widthCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _tibSizeCtrl;
  late TextEditingController _pronSizeCtrl;
  late TextEditingController _transSizeCtrl;

  @override
  void initState() {
    super.initState();
    _widthCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    _tibSizeCtrl = TextEditingController();
    _pronSizeCtrl = TextEditingController();
    _transSizeCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _tibSizeCtrl.dispose();
    _pronSizeCtrl.dispose();
    _transSizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await _settingsService.getSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
      _widthCtrl.text = settings.defaultPageWidthMm.toStringAsFixed(0);
      _heightCtrl.text = settings.defaultPageHeightMm.toStringAsFixed(0);
      _tibSizeCtrl.text =
          (settings.tibetanFont?.fontSize ?? 10).toStringAsFixed(1);
      _pronSizeCtrl.text =
          (settings.pronunciationFont?.fontSize ?? 8).toStringAsFixed(1);
      _transSizeCtrl.text =
          (settings.translationFont?.fontSize ?? 8).toStringAsFixed(1);
    });
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
        pronunciationFont:
            _settings!.pronunciationFont!.copyWith(fontSize: n),
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
      return _settings?.hasFontsConfigured ?? false;
    }
    return true;
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
                  icon: Icon(Icons.close,
                      size: 18, color: AppColors.textCaption),
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
                      setState(() => _settings = _settings!
                          .copyWith(defaultPageWidthMm: n));
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
                      setState(() => _settings = _settings!
                          .copyWith(defaultPageHeightMm: n));
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

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
                  child: Text(_l10n.cancel,
                      style: TextStyle(color: AppColors.textCaption)),
                ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _canSave && !_saving ? _save : null,
                style: TextButton.styleFrom(
                  backgroundColor: _canSave
                      ? AppColors.sky500
                      : AppColors.border,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
    final l10n = AppLocalizations.of(context)!;
    final languages = [
      (null, l10n.systemDefault),
      ('en', 'English'),
      ('zh', '简体中文'),
      ('zh_TW', '繁體中文'),
    ];

    return DropdownButtonFormField<String>(
      initialValue: _settings?.locale,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        return DropdownMenuItem<String>(
          value: lang.$1,
          child: Text(lang.$2),
        );
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        return DropdownMenuItem<AppTheme>(
          value: t.$1,
          child: Text(t.$2),
        );
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
