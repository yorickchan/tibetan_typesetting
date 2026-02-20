import 'package:flutter/material.dart';

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

  const FontPicker({
    super.key,
    this.selectedPath,
    required this.onSelected,
    this.label = 'Font',
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
    if (mounted) setState(() { _allFonts = fonts; _loading = false; });
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
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.slate400,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _loading ? null : _showPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.slate950.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.slate700),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _loading
                        ? 'Loading fonts...'
                        : (_selectedName ?? 'Select a font...'),
                    style: TextStyle(
                      color: _selectedName != null
                          ? AppColors.slate100
                          : AppColors.slate500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.unfold_more,
                    size: 16, color: AppColors.slate500),
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

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _filtered = widget.fonts;
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
            .where((f) => f.familyName.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.slate900,
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
                style:
                    const TextStyle(color: AppColors.slate100, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search fonts...',
                  hintStyle: TextStyle(
                      color: AppColors.slate500.withValues(alpha: 0.6)),
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: AppColors.slate500),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  filled: true,
                  fillColor: AppColors.slate950.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.slate700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.slate700),
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
                style:
                    const TextStyle(color: AppColors.slate500, fontSize: 10),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _filtered.length,
                itemExtent: 40,
                itemBuilder: (context, index) {
                  final font = _filtered[index];
                  final selected = font.filePath == widget.selectedPath;
                  return ListTile(
                    dense: true,
                    selected: selected,
                    selectedTileColor:
                        AppColors.sky500.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    title: Text(
                      font.familyName,
                      style: TextStyle(
                        color: selected
                            ? AppColors.sky400
                            : AppColors.slate200,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      font.fileType.toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.slate600, fontSize: 9),
                    ),
                    onTap: () => widget.onSelected(font),
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
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.slate400)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
