import 'package:flutter/material.dart';

import '../models/project.dart';
import '../utils/colors.dart';

class BlockEditorWidget extends StatelessWidget {
  final TextBlock? selectedBlock;
  final int selectedIndex;
  final int totalBlocks;
  final ValueChanged<Map<String, dynamic>> onUpdateBlock;
  final ValueChanged<int> onMoveBlock;
  final VoidCallback onDeleteBlock;
  final VoidCallback onToggleColumnBreak;
  final VoidCallback onTogglePageBreak;
  final VoidCallback onToggleSmallText;
  final VoidCallback onSelectPrev;
  final VoidCallback onSelectNext;
  final String tibetanFontFamily;
  final String pronunciationFontFamily;
  final String translationFontFamily;

  const BlockEditorWidget({
    super.key,
    required this.selectedBlock,
    required this.selectedIndex,
    required this.totalBlocks,
    required this.onUpdateBlock,
    required this.onMoveBlock,
    required this.onDeleteBlock,
    required this.onToggleColumnBreak,
    required this.onTogglePageBreak,
    required this.onToggleSmallText,
    required this.onSelectPrev,
    required this.onSelectNext,
    this.tibetanFontFamily = 'BabelStoneTibetan',
    this.pronunciationFontFamily = 'STHeiti',
    this.translationFontFamily = 'STHeiti',
  });

  @override
  Widget build(BuildContext context) {
    if (selectedBlock == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Select a block above to start editing.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _Toolbar(
            selectedIndex: selectedIndex,
            totalBlocks: totalBlocks,
            block: selectedBlock!,
            onSelectPrev: onSelectPrev,
            onSelectNext: onSelectNext,
            onMoveBlock: onMoveBlock,
            onToggleColumnBreak: onToggleColumnBreak,
            onTogglePageBreak: onTogglePageBreak,
            onToggleSmallText: onToggleSmallText,
            onDeleteBlock: onDeleteBlock,
          ),
          Container(height: 1, color: AppColors.divider),
          _EditorFields(
            block: selectedBlock!,
            onUpdateBlock: onUpdateBlock,
            tibetanFontFamily: tibetanFontFamily,
            pronunciationFontFamily: pronunciationFontFamily,
            translationFontFamily: translationFontFamily,
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final int selectedIndex;
  final int totalBlocks;
  final TextBlock block;
  final VoidCallback onSelectPrev;
  final VoidCallback onSelectNext;
  final ValueChanged<int> onMoveBlock;
  final VoidCallback onToggleColumnBreak;
  final VoidCallback onTogglePageBreak;
  final VoidCallback onToggleSmallText;
  final VoidCallback onDeleteBlock;

  const _Toolbar({
    required this.selectedIndex,
    required this.totalBlocks,
    required this.block,
    required this.onSelectPrev,
    required this.onSelectNext,
    required this.onMoveBlock,
    required this.onToggleColumnBreak,
    required this.onTogglePageBreak,
    required this.onToggleSmallText,
    required this.onDeleteBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _iconBtn(Icons.arrow_upward, onSelectPrev,
                enabled: selectedIndex > 0, size: 18),
            Text(
              'Block ${selectedIndex + 1}',
              style: TextStyle(
                  color: AppColors.textBody, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            Text(
              ' / $totalBlocks',
              style: TextStyle(color: AppColors.textFaint, fontSize: 11),
            ),
            _iconBtn(Icons.arrow_downward, onSelectNext,
                enabled: selectedIndex < totalBlocks - 1, size: 18),
            const SizedBox(width: 8),
            _smallBtn(Icons.arrow_upward, 'Move', () => onMoveBlock(-1),
                enabled: selectedIndex > 0),
            const SizedBox(width: 4),
            _smallBtn(Icons.arrow_downward, 'Move', () => onMoveBlock(1),
                enabled: selectedIndex < totalBlocks - 1),
            _divider(),
            _toggleBtn(
              Icons.view_column_outlined, 'Line break',
              block.columnBreakBefore, AppColors.sky500, onToggleColumnBreak,
            ),
            const SizedBox(width: 4),
            _toggleBtn(
              Icons.insert_page_break_outlined, 'New page',
              block.pageBreakBefore, AppColors.rose500, onTogglePageBreak,
            ),
            const SizedBox(width: 4),
            _toggleBtn(
              Icons.text_fields, 'Small',
              block.smallText, AppColors.amber400, onToggleSmallText,
            ),
            _divider(),
            _iconBtn(Icons.delete_outline, onDeleteBlock,
                color: AppColors.rose400, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 1,
      height: 14,
      color: AppColors.border,
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onPressed,
      {bool enabled = true, Color? color, double size = 16}) {
    final c = color ?? AppColors.textCaption;
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: size,
        icon: Icon(icon, color: enabled ? c : c.withValues(alpha: 0.3)),
        onPressed: enabled ? onPressed : null,
      ),
    );
  }

  Widget _smallBtn(IconData icon, String label, VoidCallback onPressed,
      {bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 10,
                color: enabled
                    ? AppColors.textCaption
                    : AppColors.textCaption.withValues(alpha: 0.3)),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                  color: enabled
                      ? AppColors.textCaption
                      : AppColors.textCaption.withValues(alpha: 0.3),
                  fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(
      IconData icon, String label, bool active, Color activeColor, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active ? activeColor.withValues(alpha: 0.4) : AppColors.border,
          ),
          color: active ? activeColor.withValues(alpha: 0.15) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 10,
                color: active ? activeColor.withValues(alpha: 0.8) : AppColors.textMuted),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                  color: active ? activeColor.withValues(alpha: 0.8) : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorFields extends StatefulWidget {
  final TextBlock block;
  final ValueChanged<Map<String, dynamic>> onUpdateBlock;
  final String tibetanFontFamily;
  final String pronunciationFontFamily;
  final String translationFontFamily;

  const _EditorFields({
    required this.block,
    required this.onUpdateBlock,
    required this.tibetanFontFamily,
    required this.pronunciationFontFamily,
    required this.translationFontFamily,
  });

  @override
  State<_EditorFields> createState() => _EditorFieldsState();
}

class _EditorFieldsState extends State<_EditorFields> {
  late TextEditingController _tibetanCtrl;
  late TextEditingController _pronCtrl;
  late TextEditingController _transCtrl;
  String? _lastBlockId;

  @override
  void initState() {
    super.initState();
    _tibetanCtrl = TextEditingController(text: widget.block.tibetan);
    _pronCtrl = TextEditingController(text: widget.block.chinesePronunciation);
    _transCtrl = TextEditingController(text: widget.block.chineseTranslation);
    _lastBlockId = widget.block.id;
  }

  @override
  void didUpdateWidget(covariant _EditorFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block.id != _lastBlockId) {
      _tibetanCtrl.text = widget.block.tibetan;
      _pronCtrl.text = widget.block.chinesePronunciation;
      _transCtrl.text = widget.block.chineseTranslation;
      _lastBlockId = widget.block.id;
    }
  }

  @override
  void dispose() {
    _tibetanCtrl.dispose();
    _pronCtrl.dispose();
    _transCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, String placeholder) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2),
      hintText: placeholder,
      hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5), fontSize: 13),
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _tibetanField()),
                const SizedBox(width: 8),
                Expanded(child: _pronField()),
                const SizedBox(width: 8),
                Expanded(child: _transField()),
              ],
            );
          }
          return Column(
            children: [
              _tibetanField(),
              const SizedBox(height: 8),
              _pronField(),
              const SizedBox(height: 8),
              _transField(),
            ],
          );
        },
      ),
    );
  }

  Widget _tibetanField() {
    return TextField(
      controller: _tibetanCtrl,
      onChanged: (v) => widget.onUpdateBlock({'tibetan': v}),
      style: TextStyle(
          fontFamily: widget.tibetanFontFamily,
          fontSize: 13,
          color: AppColors.textPrimary),
      maxLines: null,
      minLines: 3,
      decoration: _fieldDecoration('TIBETAN', 'Tibetan text'),
    );
  }

  Widget _pronField() {
    return TextField(
      controller: _pronCtrl,
      onChanged: (v) => widget.onUpdateBlock({'chinesePronunciation': v}),
      style: TextStyle(
          fontFamily: widget.pronunciationFontFamily,
          fontSize: 13,
          color: AppColors.textPrimary),
      maxLines: null,
      minLines: 3,
      decoration: _fieldDecoration('PRONUNCIATION', 'Chinese pronunciation'),
    );
  }

  Widget _transField() {
    return TextField(
      controller: _transCtrl,
      onChanged: (v) => widget.onUpdateBlock({'chineseTranslation': v}),
      style: TextStyle(
          fontFamily: widget.translationFontFamily,
          fontSize: 13,
          color: AppColors.textPrimary),
      maxLines: null,
      minLines: 3,
      decoration: _fieldDecoration('TRANSLATION', 'Chinese translation'),
    );
  }
}
