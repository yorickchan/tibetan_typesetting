import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/project.dart';
import '../services/database_service.dart';
import '../services/font_service.dart';
import '../services/pdf_service.dart';
import '../services/settings_service.dart';
import '../utils/colors.dart';
import '../utils/decorations.dart';
import '../utils/snackbar.dart';
import '../widgets/app_shell.dart';
import '../widgets/sample_pages.dart';

class ExportPage extends StatefulWidget {
  final String projectId;
  const ExportPage({super.key, required this.projectId});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final _db = DatabaseService();
  final _pdfService = PdfService();
  final _settingsService = SettingsService();
  final _fontService = FontService();
  final _focusNode = FocusNode();
  final _txController = TransformationController();
  Project? _project;
  AppSettings _appSettings = AppSettings();
  bool _loading = true;
  String? _error;
  bool _pdfBusy = false;
  String _saveState = 'idle';
  double _zoom = 1.0;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  static const _zoomMin = 0.2;
  static const _zoomMax = 3.0;
  static const _zoomStep = 0.1;

  @override
  void initState() {
    super.initState();
    _loadProject();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _settingsService.getSettings();
    if (mounted) setState(() => _appSettings = s);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _txController.dispose();
    super.dispose();
  }

  void _applyZoom(double newZoom) {
    setState(() {
      _zoom = newZoom.clamp(_zoomMin, _zoomMax);
      _txController.value = Matrix4.diagonal3Values(_zoom, _zoom, 1);
    });
  }

  void _zoomIn() => _applyZoom(_zoom + _zoomStep);
  void _zoomOut() => _applyZoom(_zoom - _zoomStep);
  void _zoomReset() => _applyZoom(1.0);

  Future<void> _loadProject() async {
    setState(() => _loading = true);
    try {
      final project = await _db.getProject(widget.projectId);
      if (!mounted) return;

      if (project != null) {
        final ps = project.pageSetup;
        for (final c in [
          ps.tibetanFont,
          ps.pronunciationFont,
          ps.translationFont,
          ps.titleTibetanFont,
          ps.titleChineseFont,
        ]) {
          if (c != null) await _fontService.loadFontForPreview(c);
        }
      }

      if (!mounted) return;
      setState(() {
        _project = project;
        _loading = false;
        _error = project == null ? _l10n.projectNotFound : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    showAppSnackBar(context, msg, error: error);
  }

  void _updateSetup(PageSetup Function(PageSetup) updater) {
    if (_project == null) return;
    setState(() {
      _project = _project!.copyWith(pageSetup: updater(_project!.pageSetup));
    });
    _saveProject();
  }

  void _updateMargin(String key, double value) {
    if (_project == null) return;
    setState(() {
      final m = _project!.pageSetup.marginMm;
      final newMargin = switch (key) {
        'top' => m.copyWith(top: value),
        'right' => m.copyWith(right: value),
        'bottom' => m.copyWith(bottom: value),
        'left' => m.copyWith(left: value),
        _ => m,
      };
      _project = _project!.copyWith(
        pageSetup: _project!.pageSetup.copyWith(marginMm: newMargin),
      );
    });
    _saveProject();
  }

  Future<void> _saveProject() async {
    if (_project == null) return;
    setState(() => _saveState = 'saving');
    try {
      await _db.updateProject(_project!);
      if (!mounted) return;
      setState(() => _saveState = 'saved');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _saveState == 'saved') {
          setState(() => _saveState = 'idle');
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveState = 'error');
    }
  }

  Future<void> _exportPdf() async {
    if (_project == null) return;
    setState(() => _pdfBusy = true);
    try {
      final result = await _pdfService.generatePdfWithWarnings(
        _project!,
        appSettings: _appSettings,
      );
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF',
        fileName: '${_project!.name}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (path == null) {
        if (mounted) setState(() => _pdfBusy = false);
        return;
      }
      await File(path).writeAsBytes(result.bytes);
      if (result.warnings.isNotEmpty) {
        _showSnack(
          '${_l10n.projectExported}\n${result.warnings.join('\n')}',
          error: true,
        );
      } else {
        _showSnack(_l10n.projectExported);
      }
    } catch (e, s) {
      debugPrint('PDF export failed: $e\n$s');
      _showSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final meta = HardwareKeyboard.instance.isMetaPressed;
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    final mod = meta || ctrl;

    if (event.logicalKey == LogicalKeyboardKey.equal && mod) {
      _zoomIn();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.minus && mod) {
      _zoomOut();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.digit0 && mod) {
      _zoomReset();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.add) {
      _zoomIn();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.numpadAdd) {
      _zoomIn();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
      _zoomOut();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: AppShell(
        title: _l10n.exportPdf,
        actions: [
          if (_saveState == 'saving')
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  _l10n.saving,
                  style: TextStyle(color: AppColors.textCaption, fontSize: 11),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.download, size: 16, color: Colors.white),
              label: Text(
                _pdfBusy ? _l10n.printing : _l10n.exportPdf,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.sky500,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _pdfBusy || _project == null ? null : _exportPdf,
            ),
          ),
        ],
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.sky500),
              )
            : _error != null
            ? Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.rose300),
                ),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final project = _project!;
    final ps = project.pageSetup;

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _l10n.pageSetup,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                _l10n.sentenceSpacing,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: ps.flowGap.clamp(0.0, 0.08),
                      min: 0,
                      max: 0.08,
                      divisions: 8,
                      activeColor: AppColors.sky500,
                      inactiveColor: AppColors.border,
                      onChanged: (v) =>
                          _updateSetup((s) => s.copyWith(flowGap: v)),
                    ),
                  ),
                  SizedBox(
                    width: 42,
                    child: Text(
                      '${(ps.flowGap * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.textCaption,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: ps.pageWidthMm.toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      decoration: numberDecor(_l10n.pageWidth),
                      onChanged: (v) {
                        final n = double.tryParse(v);
                        if (n != null && n >= 50) {
                          _updateSetup((s) => s.copyWith(pageWidthMm: n));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: ps.pageHeightMm.toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      decoration: numberDecor(_l10n.pageHeight),
                      onChanged: (v) {
                        final n = double.tryParse(v);
                        if (n != null && n >= 50) {
                          _updateSetup((s) => s.copyWith(pageHeightMm: n));
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  ...[
                    ('top', _l10n.top),
                    ('bottom', _l10n.bottom),
                    ('left', _l10n.left),
                    ('right', _l10n.right),
                  ].map(
                    (e) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextFormField(
                          initialValue: _getMargin(e.$1).toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                          decoration: numberDecor('${e.$2} (mm)'),
                          onChanged: (v) {
                            final n = double.tryParse(v);
                            if (n != null) _updateMargin(e.$1, n);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: ps.showFrame,
                      onChanged: (v) =>
                          _updateSetup((s) => s.copyWith(showFrame: v)),
                      activeColor: AppColors.sky500,
                      side: BorderSide(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _l10n.showFrame,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: ps.leftVerticalTitle,
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: numberDecor(_l10n.leftVerticalTitle),
                onChanged: (v) =>
                    _updateSetup((s) => s.copyWith(leftVerticalTitle: v)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: ps.pageNumber,
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: numberDecor(_l10n.pageNumberLabel),
                onChanged: (v) =>
                    _updateSetup((s) => s.copyWith(pageNumber: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _l10n.preview,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _l10n.exportPdfHint,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _zoomBtn(Icons.remove, _zoomOut),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${(_zoom * 100).round()}%',
                          style: TextStyle(
                            color: AppColors.textBody,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      _zoomBtn(Icons.add, _zoomIn),
                      const SizedBox(width: 4),
                      _zoomBtn(Icons.refresh, _zoomReset),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRect(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: InteractiveViewer(
                    transformationController: _txController,
                    scaleEnabled: false,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(300),
                    child: SamplePagesWidget(
                      project: project,
                      appSettings: _appSettings,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: Icon(icon, color: AppColors.textBody),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onPressed,
      ),
    );
  }

  double _getMargin(String key) {
    if (_project == null) return 10;
    return switch (key) {
      'top' => _project!.pageSetup.marginMm.top,
      'right' => _project!.pageSetup.marginMm.right,
      'bottom' => _project!.pageSetup.marginMm.bottom,
      'left' => _project!.pageSetup.marginMm.left,
      _ => 10,
    };
  }
}
