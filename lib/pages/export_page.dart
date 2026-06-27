import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/chinese_script.dart';
import '../models/project.dart';
import '../models/title_page_template.dart';
import '../services/chinese_conversion_service.dart';
import '../services/database_service.dart';
import '../services/font_service.dart';
import '../services/html_export_service.dart';
import '../services/pdf_service.dart';
import '../services/settings_service.dart';
import '../services/title_page_template_service.dart';
import '../utils/colors.dart';
import '../utils/save_state_mixin.dart';
import '../utils/snackbar.dart';
import '../widgets/app_shell.dart';
import '../widgets/chinese_script_switch.dart';
import '../widgets/export_pdf_settings_panel.dart';
import '../widgets/preview_zoom_toolbar.dart';
import '../widgets/sample_pages.dart';

class ExportPage extends StatefulWidget {
  final String projectId;
  const ExportPage({super.key, required this.projectId});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage>
    with SaveStateMixin<ExportPage> {
  final _db = DatabaseService();
  final _chineseConversionService = const ChineseConversionService();
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
  bool _scriptBusy = false;
  bool _exportAsHtml = false;
  List<TitlePageTemplate> _templates = [];
  double _zoom = 1.0;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadProject();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _settingsService.getSettings();
    final templates = await TitlePageTemplateService().listTemplates();
    if (mounted) setState(() {
      _appSettings = s;
      _templates = templates;
    });
  }

  String? _resolveTemplateSvg() {
    final id = _project?.pageSetup.titlePageTemplateId;
    if (id == null) return null;
    try {
      return _templates.firstWhere((t) => t.id == id).svgContent;
    } on StateError {
      return null;
    }
  }

  String? _resolveContentTemplateSvg(String? templateId) {
    if (templateId == null) return null;
    try {
      return _templates.firstWhere((t) => t.id == templateId).svgContent;
    } on StateError {
      return null;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _txController.dispose();
    super.dispose();
  }

  void _applyZoom(double newZoom) {
    setState(() {
      _zoom = newZoom.clamp(kPreviewZoomMin, kPreviewZoomMax);
      _txController.value = Matrix4.diagonal3Values(_zoom, _zoom, 1);
    });
  }

  void _zoomIn() => _applyZoom(_zoom + kPreviewZoomStep);
  void _zoomOut() => _applyZoom(_zoom - kPreviewZoomStep);
  void _zoomReset() => _applyZoom(1.0);

  Future<void> _loadProject() async {
    setState(() => _loading = true);
    try {
      var project = await _db.getProject(widget.projectId);
      if (!mounted) return;

      if (project?.chineseScript == ChineseScript.unknown) {
        project = project!.copyWith(
          chineseScript: _chineseConversionService.effectiveScript(project),
        );
      }

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

  Future<void> _saveProject() async {
    if (_project == null) return;
    await performSave(() => _db.updateProject(_project!));
  }

  Future<void> _switchChineseScript(ChineseScript target) async {
    if (_project == null || _scriptBusy) return;
    final confirmed = await showChineseScriptConversionDialog(context, target);
    if (!confirmed || !mounted || _project == null) return;

    final original = _project!;
    setState(() => _scriptBusy = true);
    try {
      final saved = await _chineseConversionService.convertAndSave(
        original,
        target,
        _db.updateProject,
      );
      if (!mounted) return;
      setState(() => _project = saved);
    } on Object catch (_) {
      _showSnack(_l10n.chineseConversionFailed, error: true);
    } finally {
      if (mounted) setState(() => _scriptBusy = false);
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
      final path = await FilePicker.saveFile(
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

  Future<void> _exportHtml() async {
    if (_project == null) return;
    setState(() => _pdfBusy = true);
    try {
      final html = HtmlExportService.generateHtml(_project!);
      final path = await FilePicker.saveFile(
        dialogTitle: 'Save HTML',
        fileName: '${_project!.name}.html',
        type: FileType.custom,
        allowedExtensions: ['html', 'htm'],
      );
      if (path == null) {
        if (mounted) setState(() => _pdfBusy = false);
        return;
      }
      await File(path).writeAsString(html);
      _showSnack(_l10n.projectExported);
    } catch (e, s) {
      debugPrint('HTML export failed: $e\n$s');
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
          if (saveState == SaveState.saving)
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
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(value: false, label: Text('PDF')),
                ButtonSegment<bool>(value: true, label: Text('HTML')),
              ],
              selected: {_exportAsHtml},
              onSelectionChanged: (v) => setState(() => _exportAsHtml = v.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.sky500,
                selectedForegroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.download, size: 16, color: Colors.white),
              label: Text(
                _pdfBusy ? _l10n.printing : (_exportAsHtml ? 'Export HTML' : _l10n.exportPdf),
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
              onPressed: _pdfBusy || _scriptBusy || _project == null
                  ? null
                  : (_exportAsHtml ? _exportHtml : _exportPdf),
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
            : AbsorbPointer(absorbing: _scriptBusy, child: _buildContent()),
      ),
    );
  }

  Widget _buildContent() {
    final project = _project!;
    final ps = project.pageSetup;

    return ListView(
      children: [
        ExportPdfSettingsPanel(
          pageSetup: ps,
          l10n: _l10n,
          onUpdateSetup: _updateSetup,
        ),
        const SizedBox(height: 16),

        ChineseScriptSwitch(
          selectedScript: project.chineseScript,
          busy: _scriptBusy,
          onSelected: _switchChineseScript,
        ),
        const SizedBox(height: 12),

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
                  PreviewZoomToolbar(
                    zoom: _zoom,
                    onZoomIn: _zoomIn,
                    onZoomOut: _zoomOut,
                    onReset: _zoomReset,
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
                      svgContent: _resolveTemplateSvg(),
                      contentFirstPageSvg: _resolveContentTemplateSvg(
                        project.pageSetup.contentFirstPageTemplateId,
                      ),
                      contentSubsequentPageSvg: _resolveContentTemplateSvg(
                        project.pageSetup.contentSubsequentPageTemplateId,
                      ),
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
}
