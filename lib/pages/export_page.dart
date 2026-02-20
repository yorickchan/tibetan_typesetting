import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../models/project.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../utils/colors.dart';
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
  final _focusNode = FocusNode();
  final _txController = TransformationController();
  Project? _project;
  bool _loading = true;
  String? _error;
  bool _pdfBusy = false;
  String _saveState = 'idle';
  double _zoom = 1.0;

  static const _zoomMin = 0.2;
  static const _zoomMax = 3.0;
  static const _zoomStep = 0.1;

  @override
  void initState() {
    super.initState();
    _loadProject();
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
      setState(() {
        _project = project;
        _loading = false;
        _error = project == null ? 'Project not found' : null;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.rose600 : AppColors.sky500,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
        if (mounted && _saveState == 'saved')
          setState(() => _saveState = 'idle');
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
      final bytes = await _pdfService.generatePdf(_project!);
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
      await File(path).writeAsBytes(bytes);
      _showSnack('PDF saved to $path');
    } catch (e) {
      _showSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  Future<void> _printPdf() async {
    if (_project == null) return;
    try {
      final bytes = await _pdfService.generatePdf(_project!);
      await Printing.layoutPdf(onLayout: (_) => bytes);
    } catch (e) {
      _showSnack(e.toString(), error: true);
    }
  }

  InputDecoration _numberDecor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.slate200, fontSize: 11),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      filled: true,
      fillColor: AppColors.slate950.withValues(alpha: 0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.slate800),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.slate800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.sky500),
      ),
    );
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
        title: 'Export PDF',
        actions: [
          if (_saveState == 'saving')
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  'Saving...',
                  style: TextStyle(color: AppColors.slate400, fontSize: 11),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton.icon(
              icon: const Icon(Icons.print,
                  size: 16, color: AppColors.slate100),
              label: const Text('Print...',
                  style:
                      TextStyle(color: AppColors.slate100, fontSize: 13)),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.cardBg,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.slate800),
                ),
              ),
              onPressed: _project == null ? null : _printPdf,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.download, size: 16, color: Colors.white),
              label: Text(
                _pdfBusy ? 'Exporting...' : 'Export PDF',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.sky500,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        // Page setup panel
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
              const Text(
                'Page setup',
                style: TextStyle(
                  color: AppColors.slate100,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Page size
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: ps.pageWidthMm.toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: AppColors.slate100,
                        fontSize: 13,
                      ),
                      decoration: _numberDecor('Page width (mm)'),
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
                      style: const TextStyle(
                        color: AppColors.slate100,
                        fontSize: 13,
                      ),
                      decoration: _numberDecor('Page height (mm)'),
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

              // Columns
              const Text(
                'Columns',
                style: TextStyle(
                  color: AppColors.slate200,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: ps.columnCount <= 0,
                      onChanged: (v) => _updateSetup(
                        (s) => s.copyWith(columnCount: v == true ? 0 : 5),
                      ),
                      activeColor: AppColors.sky500,
                      side: const BorderSide(color: AppColors.slate500),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Auto per page',
                    style: TextStyle(color: AppColors.slate300, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: (ps.columnCount <= 0 ? 1 : ps.columnCount)
                          .toDouble()
                          .clamp(1, 8),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      activeColor: AppColors.sky500,
                      inactiveColor: AppColors.slate700,
                      onChanged: ps.columnCount <= 0
                          ? null
                          : (v) => _updateSetup(
                              (s) => s.copyWith(columnCount: v.round()),
                            ),
                    ),
                  ),
                  Text(
                    ps.columnCount <= 0 ? 'Auto' : '${ps.columnCount}',
                    style: const TextStyle(
                      color: AppColors.slate400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Margins
              Row(
                children: [
                  ...[
                    ('top', 'Top'),
                    ('bottom', 'Bottom'),
                    ('left', 'Left'),
                    ('right', 'Right'),
                  ].map(
                    (e) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextFormField(
                          initialValue: _getMargin(e.$1).toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: AppColors.slate100,
                            fontSize: 13,
                          ),
                          decoration: _numberDecor('${e.$2} (mm)'),
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

              // Show frame
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
                      side: const BorderSide(color: AppColors.slate500),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Show frame',
                    style: TextStyle(color: AppColors.slate200, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title page
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: ps.showTitlePage,
                      onChanged: (v) =>
                          _updateSetup((s) => s.copyWith(showTitlePage: v)),
                      activeColor: AppColors.sky500,
                      side: const BorderSide(color: AppColors.slate500),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Title page',
                    style: TextStyle(color: AppColors.slate200, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: ps.titleTibetan,
                style: const TextStyle(
                  fontFamily: 'BabelStoneTibetan',
                  fontSize: 13,
                  color: AppColors.slate100,
                ),
                decoration: _numberDecor('Title (Tibetan)'),
                onChanged: (v) =>
                    _updateSetup((s) => s.copyWith(titleTibetan: v)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: ps.titleChinese,
                style: const TextStyle(
                  fontFamily: 'STHeiti',
                  fontSize: 13,
                  color: AppColors.slate100,
                ),
                decoration: _numberDecor('Title (Chinese)'),
                onChanged: (v) =>
                    _updateSetup((s) => s.copyWith(titleChinese: v)),
              ),
              const SizedBox(height: 12),

              // Vertical title & page number
              TextFormField(
                initialValue: ps.leftVerticalTitle,
                style: const TextStyle(fontSize: 13, color: AppColors.slate100),
                decoration: _numberDecor('Left vertical title'),
                onChanged: (v) =>
                    _updateSetup((s) => s.copyWith(leftVerticalTitle: v)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: ps.pageNumber,
                style: const TextStyle(fontSize: 13, color: AppColors.slate100),
                decoration: _numberDecor('Page number'),
                onChanged: (v) =>
                    _updateSetup((s) => s.copyWith(pageNumber: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Print preview
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
                    children: const [
                      Text(
                        'Print preview',
                        style: TextStyle(
                          color: AppColors.slate100,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Use Export PDF to output. Zoom: Cmd +/−/0',
                        style: TextStyle(
                          color: AppColors.slate500,
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
                          style: const TextStyle(
                            color: AppColors.slate300,
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
                    child: SamplePagesWidget(project: project),
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
        icon: Icon(icon, color: AppColors.slate300),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.slate800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
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
