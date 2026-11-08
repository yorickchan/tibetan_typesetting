import 'package:flutter/material.dart';

import '../models/font_config.dart';
import '../services/font_service.dart';
import '../utils/colors.dart';

/// A searchable dropdown that lists system fonts and lets the user pick one.
///
/// [selectedPath] is the currently selected font file path (null = none).
/// [onSelected] fires when the user picks a font, providing the
/// [SystemFontInfo] for the chosen font.
class FontPicker extends StatefulWidget {
  final String? selectedPath;
  final ValueChanged<SystemFontInfo> onSelected;
  final String label;

  /// Text shown when no font is selected.
  final String placeholder;

  const FontPicker({
    super.key,
    this.selectedPath,
    required this.onSelected,
    this.label = 'Font',
    this.placeholder = 'Select a font...',
  });

  @override
  State<FontPicker> createState() => _FontPickerState();
}

class _FontPickerState extends State<FontPicker> {
  List<SystemFontInfo>? _allFonts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFonts();
  }

  Future<void> _loadFonts() async {
    final fonts = await FontService().scanSystemFonts();
    if (mounted) {
      setState(() {
        _allFonts = fonts;
        _loading = false;
      });
    }
  }

  String? get _selectedName {
    if (widget.selectedPath == null || _allFonts == null) return null;
    final match = _allFonts!.where((f) => f.filePath == widget.selectedPath);
    return match.isNotEmpty ? match.first.familyName : null;
  }

  void _showPicker() {
    if (_allFonts == null) return;
    showDialog(
      context: context,
      builder: (_) => _FontPickerDialog(
        fonts: _allFonts!,
        selectedPath: widget.selectedPath,
        onSelected: (info) {
          widget.onSelected(info);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
        ],
        GestureDetector(
          onTap: _loading ? null : _showPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _loading
                        ? 'Loading fonts...'
                        : (_selectedName ?? widget.placeholder),
                    style: TextStyle(
                      color: _selectedName != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.unfold_more, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog with search & scrollable font list
// ---------------------------------------------------------------------------

class _FontPickerDialog extends StatefulWidget {
  final List<SystemFontInfo> fonts;
  final String? selectedPath;
  final ValueChanged<SystemFontInfo> onSelected;

  const _FontPickerDialog({
    required this.fonts,
    this.selectedPath,
    required this.onSelected,
  });

  @override
  State<_FontPickerDialog> createState() => _FontPickerDialogState();
}

class _FontPickerDialogState extends State<_FontPickerDialog> {
  late TextEditingController _searchCtrl;
  List<SystemFontInfo> _filtered = [];
  SystemFontInfo? _previewFont;
  bool _previewLoading = false;
  int _previewToken = 0;
  final _loadedPreviews = <String>{};

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _filtered = widget.fonts;

    final selected = widget.fonts.where(
      (f) => f.filePath == widget.selectedPath,
    );
    final initial = selected.isNotEmpty
        ? selected.first
        : (widget.fonts.isNotEmpty ? widget.fonts.first : null);
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _preview(initial);
      });
    }
  }

  void _preview(SystemFontInfo font) {
    final token = ++_previewToken;
    final already = _loadedPreviews.contains(font.filePath);
    setState(() {
      _previewFont = font;
      _previewLoading = !already;
    });
    if (already) return;

    FontService()
        .loadFontForPreview(
          FontConfig(
            fontFamily: font.familyName,
            fontPath: font.filePath,
            fontSize: 14,
          ),
        )
        .then((_) {
          if (!mounted || token != _previewToken) return;
          setState(() {
            _loadedPreviews.add(font.filePath);
            _previewLoading = false;
          });
        });
  }

  Widget _previewPane() {
    final font = _previewFont;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  font == null ? 'Hover a font to preview' : font.familyName,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_previewLoading)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.sky500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ཨོཾ་མ་ཎི་པདྨེ་ཧཱུྃ',
            style: TextStyle(
              fontFamily: font?.familyName,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '嗡嘛呢叭咪吽 · Aa Bb Cc 123',
            style: TextStyle(
              fontFamily: font?.familyName,
              fontSize: 12,
              color: AppColors.textBody,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = widget.fonts;
      } else {
        _filtered = widget.fonts
            .where(
              (f) =>
                  f.familyName.toLowerCase().contains(q) ||
                  f.filePath.toLowerCase().contains(q),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 420,
        height: 500,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _filter,
                autofocus: true,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search fonts...',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_filtered.length} font${_filtered.length == 1 ? '' : 's'}',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ),
            const SizedBox(height: 4),
            _previewPane(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _filtered.length,
                itemExtent: 40,
                itemBuilder: (context, index) {
                  final font = _filtered[index];
                  final selected = font.filePath == widget.selectedPath;
                  return MouseRegion(
                    onEnter: (_) => _preview(font),
                    cursor: SystemMouseCursors.click,
                    child: Focus(
                      onFocusChange: (hasFocus) {
                        if (hasFocus) _preview(font);
                      },
                      child: ListTile(
                        dense: true,
                        selected: selected,
                        selectedTileColor: AppColors.sky500.withValues(
                          alpha: 0.15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        title: Text(
                          font.familyName,
                          style: TextStyle(
                            color: selected
                                ? AppColors.sky400
                                : AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          font.fileType.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.textFaint,
                            fontSize: 9,
                          ),
                        ),
                        onTap: () => widget.onSelected(font),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, right: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textCaption),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
