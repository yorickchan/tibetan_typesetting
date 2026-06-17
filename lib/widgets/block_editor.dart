import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/block_update.dart';
import '../models/project.dart';
import '../services/pronunciation_service.dart';
import '../utils/colors.dart';
import '../utils/decorations.dart';
import '../utils/font_constants.dart';
import '../utils/sample_layout.dart';
import '../utils/tibetan_segmenter.dart';

class BlockEditorWidget extends StatelessWidget {
  final TextBlock? selectedBlock;
  final int selectedIndex;
  final int totalBlocks;
  final ValueChanged<BlockUpdate> onUpdateBlock;
  final ValueChanged<int> onMoveBlock;
  final VoidCallback onDeleteBlock;
  final VoidCallback onToggleColumnBreak;
  final VoidCallback onTogglePageBreak;
  final VoidCallback onToggleSmallText;
  final VoidCallback onToggleFreeTextFormat;
  final VoidCallback onToggleOpeningMarkFormat;
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
    required this.onToggleFreeTextFormat,
    required this.onToggleOpeningMarkFormat,
    required this.onSelectPrev,
    required this.onSelectNext,
    this.tibetanFontFamily = fallbackTibetanFontFamily,
    this.pronunciationFontFamily = fallbackChineseFontFamily,
    this.translationFontFamily = fallbackChineseFontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
            l10n.selectBlockToEdit,
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
            onToggleFreeTextFormat: onToggleFreeTextFormat,
            onToggleOpeningMarkFormat: onToggleOpeningMarkFormat,
            onSetColumnSpan: (span) => onUpdateBlock(
              BlockUpdate(columnSpan: span, clearColumnSpan: span == null),
            ),
            onDeleteBlock: onDeleteBlock,
            l10n: l10n,
            onToggleFloating: selectedBlock!.isImageBlock
                ? () => onUpdateBlock(
                      BlockUpdate(floatingImage: !selectedBlock!.floatingImage),
                    )
                : null,
          ),
          Container(height: 1, color: AppColors.divider),
          _EditorFields(
            block: selectedBlock!,
            onUpdateBlock: onUpdateBlock,
            tibetanFontFamily: tibetanFontFamily,
            pronunciationFontFamily: pronunciationFontFamily,
            translationFontFamily: translationFontFamily,
            l10n: l10n,
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
  final VoidCallback onToggleFreeTextFormat;
  final VoidCallback onToggleOpeningMarkFormat;
  final ValueChanged<int?> onSetColumnSpan;
  final VoidCallback onDeleteBlock;
  final AppLocalizations l10n;
  final VoidCallback? onToggleFloating;

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
    required this.onToggleFreeTextFormat,
    required this.onToggleOpeningMarkFormat,
    required this.onSetColumnSpan,
    required this.onDeleteBlock,
    required this.l10n,
    this.onToggleFloating,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _iconBtn(
              Icons.arrow_upward,
              onSelectPrev,
              enabled: selectedIndex > 0,
              size: 18,
            ),
            Text(
              l10n.blockNumber(selectedIndex + 1, totalBlocks),
              style: TextStyle(
                color: AppColors.textBody,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            _iconBtn(
              Icons.arrow_downward,
              onSelectNext,
              enabled: selectedIndex < totalBlocks - 1,
              size: 18,
            ),
            const SizedBox(width: 8),
            _smallBtn(
              Icons.arrow_upward,
              l10n.move,
              () => onMoveBlock(-1),
              enabled: selectedIndex > 0,
            ),
            const SizedBox(width: 4),
            _smallBtn(
              Icons.arrow_downward,
              l10n.move,
              () => onMoveBlock(1),
              enabled: selectedIndex < totalBlocks - 1,
            ),
            _divider(),
            _toggleBtn(
              Icons.view_column_outlined,
              l10n.lineBreak,
              block.columnBreakBefore,
              AppColors.sky500,
              onToggleColumnBreak,
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              tooltip: 'Column span',
              color: AppColors.surface,
              initialValue: block.columnSpan?.toString() ?? 'auto',
              onSelected: (value) {
                onSetColumnSpan(value == 'auto' ? null : int.parse(value));
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'auto',
                  child: Text(
                    'Auto',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                for (final span in List<int>.generate(
                  maxColumnSpan,
                  (index) => index + 1,
                ))
                  PopupMenuItem<String>(
                    value: '$span',
                    child: Text(
                      '$span',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
              ],
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: block.columnSpan == null
                        ? AppColors.border
                        : AppColors.sky500,
                  ),
                  color: block.columnSpan == null
                      ? Colors.transparent
                      : AppColors.sky500.withValues(alpha: 0.12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.width_normal_outlined,
                      size: 13,
                      color: block.columnSpan == null
                          ? AppColors.textMuted
                          : AppColors.sky400,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      block.columnSpan == null ? 'Auto' : '${block.columnSpan}',
                      style: TextStyle(
                        color: block.columnSpan == null
                            ? AppColors.textMuted
                            : AppColors.sky400,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            _toggleBtn(
              Icons.insert_page_break_outlined,
              l10n.newPage,
              block.pageBreakBefore,
              AppColors.rose500,
              onTogglePageBreak,
            ),
            const SizedBox(width: 4),
            _toggleBtn(
              Icons.text_fields,
              l10n.smallText,
              block.smallText,
              AppColors.amber400,
              onToggleSmallText,
            ),
            const SizedBox(width: 4),
            _toggleBtn(
              Icons.notes_outlined,
              l10n.freeText,
              block.isFreeText,
              AppColors.sky400,
              onToggleFreeTextFormat,
            ),
            const SizedBox(width: 4),
            _toggleBtn(
              Icons.format_quote,
              l10n.openingMark,
              block.isOpeningMark,
              AppColors.rose600,
              onToggleOpeningMarkFormat,
            ),
            if (block.isImageBlock) ...[
              const SizedBox(width: 4),
              _toggleBtn(
                Icons.layers_outlined,
                'Floating',
                block.floatingImage,
                AppColors.emerald400,
                onToggleFloating ?? () {},
              ),
            ],
            _divider(),
            _iconBtn(
              Icons.delete_outline,
              onDeleteBlock,
              size: 18,
            ),
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

  Widget _iconBtn(
    IconData icon,
    VoidCallback onPressed, {
    bool enabled = true,
    Color? color,
    double size = 16,
  }) {
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

  Widget _smallBtn(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
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
            Icon(
              icon,
              size: 10,
              color: enabled
                  ? AppColors.textCaption
                  : AppColors.textCaption.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                color: enabled
                    ? AppColors.textCaption
                    : AppColors.textCaption.withValues(alpha: 0.3),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(
    IconData icon,
    String label,
    bool active,
    Color activeColor,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active
                ? activeColor.withValues(alpha: 0.4)
                : AppColors.border,
          ),
          color: active ? activeColor.withValues(alpha: 0.15) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 10,
              color: active
                  ? activeColor.withValues(alpha: 0.8)
                  : AppColors.textMuted,
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? activeColor.withValues(alpha: 0.8)
                    : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorFields extends StatefulWidget {
  final TextBlock block;
  final ValueChanged<BlockUpdate> onUpdateBlock;
  final String tibetanFontFamily;
  final String pronunciationFontFamily;
  final String translationFontFamily;
  final AppLocalizations l10n;

  const _EditorFields({
    required this.block,
    required this.onUpdateBlock,
    required this.tibetanFontFamily,
    required this.pronunciationFontFamily,
    required this.translationFontFamily,
    required this.l10n,
  });

  @override
  State<_EditorFields> createState() => _EditorFieldsState();
}

class _EditorFieldsState extends State<_EditorFields> {
  late TextEditingController _tibetanCtrl;
  late TextEditingController _pronCtrl;
  late TextEditingController _transCtrl;
  String? _lastBlockId;
  Timer? _debounce;
  final _pronunciationService = PronunciationService();
  bool _isAutoFilling = false;

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
    _debounce?.cancel();
    _tibetanCtrl.dispose();
    _pronCtrl.dispose();
    _transCtrl.dispose();
    super.dispose();
  }

  Future<void> _autoFillPronunciation(String tibetanText) async {
    if (widget.block.smallText || widget.block.isFreeText) return;
    if (_isAutoFilling) return;
    _isAutoFilling = true;

    try {
      final syllables = extractSyllables(tibetanText);
      if (syllables.isEmpty) {
        return;
      }

      final List<String> pronunciations = [];

      for (final syllable in syllables) {
        final pron = await _pronunciationService.getPronunciation(syllable);
        if (pron != null && pron.isNotEmpty) {
          pronunciations.add(pron);
        } else {
          pronunciations.add('X');
        }
      }

      if (!mounted) return;

      final newPron = pronunciations.join(' ');
      if (newPron != _pronCtrl.text) {
        _pronCtrl.text = newPron;
        widget.onUpdateBlock(BlockUpdate(chinesePronunciation: newPron));
      }
    } finally {
      _isAutoFilling = false;
    }
  }

  void _onTibetanChanged(String v) {
    widget.onUpdateBlock(BlockUpdate(tibetan: v));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _autoFillPronunciation(v);
    });
  }

  void _onPronunciationChanged(String v) {
    widget.onUpdateBlock(BlockUpdate(chinesePronunciation: v));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _savePronunciationToDictionary(v);
    });
  }

  Future<void> _savePronunciationToDictionary(String pronunciation) async {
    if (widget.block.smallText || widget.block.isFreeText) return;
    final tibetan = _tibetanCtrl.text;
    if (tibetan.isEmpty || pronunciation.isEmpty) return;

    final syllables = extractSyllables(tibetan);
    final chars = PronunciationService.savablePronunciationCharacters(
      pronunciation,
    );

    if (syllables.isEmpty || chars.isEmpty) return;

    int charIdx = 0;
    for (final syllable in syllables) {
      if (charIdx >= chars.length) break;

      final wordCount =
          (await _pronunciationService.getWordCount(syllable)) ?? 1;
      final end = (charIdx + wordCount).clamp(0, chars.length);
      final pron = chars.sublist(charIdx, end).join();
      charIdx += wordCount;

      if (pron.isNotEmpty && !pron.contains('X')) {
        await _pronunciationService.savePronunciation(
          syllable,
          pron,
          wordCount: wordCount,
        );
      }
    }
  }

  Widget _imageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(widget.block.imagePath!),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image,
                        size: 24, color: AppColors.textMuted),
                    const SizedBox(height: 4),
                    Text('Image not found',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (widget.block.isImageBlock) {
            return _imageSection();
          }
          if (widget.block.isOpeningMark) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.l10n.openingMark,
                  style: TextStyle(
                    color: AppColors.rose600,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _tibetanField(),
              ],
            );
          }
          if (widget.block.isFreeText) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _freeTextField(),
              ],
            );
          }
          if (constraints.maxWidth > 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _tibetanField()),
                    const SizedBox(width: 8),
                    Expanded(child: _pronField()),
                    const SizedBox(width: 8),
                    Expanded(child: _transField()),
                  ],
                ),
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
      onChanged: _onTibetanChanged,
      style: TextStyle(
        fontFamily: widget.tibetanFontFamily,
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      maxLines: null,
      minLines: 3,
      decoration: fieldDecoration(
        label: widget.l10n.tibetanLabelShort,
        placeholder: widget.l10n.tibetanText,
      ),
    );
  }

  Widget _freeTextField() {
    return TextField(
      controller: _tibetanCtrl,
      onChanged: (v) => widget.onUpdateBlock(BlockUpdate(tibetan: v)),
      style: TextStyle(
        fontFamily: widget.translationFontFamily,
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      maxLines: null,
      minLines: 5,
      decoration: fieldDecoration(
        label: widget.l10n.freeText,
        placeholder: widget.l10n.freeTextContent,
      ),
    );
  }

  Widget _pronField() {
    return TextField(
      controller: _pronCtrl,
      onChanged: _onPronunciationChanged,
      style: TextStyle(
        fontFamily: widget.pronunciationFontFamily,
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      maxLines: null,
      minLines: 3,
      decoration: fieldDecoration(
        label: widget.l10n.pronunciationLabelShort,
        placeholder: widget.l10n.chinesePronunciation,
      ),
    );
  }

  Widget _transField() {
    return TextField(
      controller: _transCtrl,
      onChanged: (v) => widget.onUpdateBlock(BlockUpdate(chineseTranslation: v)),
      style: TextStyle(
        fontFamily: widget.translationFontFamily,
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      maxLines: null,
      minLines: 3,
      decoration: fieldDecoration(
        label: widget.l10n.translationLabelShort,
        placeholder: widget.l10n.chineseTranslation,
      ),
    );
  }
}
