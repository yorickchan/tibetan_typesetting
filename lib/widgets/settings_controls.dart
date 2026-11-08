import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../models/font_config.dart';
import '../services/font_service.dart';
import '../utils/colors.dart';
import 'font_picker.dart';

TextStyle settingsSectionStyle() => TextStyle(
  color: AppColors.textMuted,
  fontSize: 10,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.0,
);

InputDecoration compactNumberDecor(String? label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    filled: true,
    fillColor: AppColors.inputFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.borderSubtle),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.borderSubtle),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.sky500),
    ),
  );
}

class SettingsSectionLabel extends StatelessWidget {
  final String text;

  const SettingsSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: settingsSectionStyle());
}

/// A narrow numeric field used for margins, sizes and spacing values.
class CompactNumberField extends StatelessWidget {
  final double initialValue;
  final String? label;
  final double width;
  final bool signed;
  final bool decimal;
  final ValueChanged<double> onChanged;

  const CompactNumberField({
    super.key,
    required this.initialValue,
    this.label,
    this.width = 76,
    this.signed = false,
    this.decimal = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextFormField(
        initialValue: decimal
            ? initialValue.toStringAsFixed(1)
            : initialValue.toStringAsFixed(0),
        keyboardType: TextInputType.numberWithOptions(
          signed: signed,
          decimal: decimal,
        ),
        style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: compactNumberDecor(label),
        onChanged: (value) {
          final number = double.tryParse(value);
          if (number != null) onChanged(number);
        },
      ),
    );
  }
}

/// One labelled row of four margin fields (Top / Bottom / Left / Right).
class MarginRow extends StatelessWidget {
  final String label;
  final double top;
  final double bottom;
  final double left;
  final double right;
  final double min;
  final double max;
  final AppLocalizations l10n;
  final ValueChanged<double> onTop;
  final ValueChanged<double> onBottom;
  final ValueChanged<double> onLeft;
  final ValueChanged<double> onRight;

  const MarginRow({
    super.key,
    required this.label,
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    required this.l10n,
    required this.onTop,
    required this.onBottom,
    required this.onLeft,
    required this.onRight,
    this.min = 0,
    this.max = 100,
  });

  void _update(double value, ValueChanged<double> callback) {
    if (value >= min && value <= max) callback(value);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 190, child: SettingsSectionLabel(label)),
        CompactNumberField(
          initialValue: top,
          label: l10n.top,
          width: 72,
          onChanged: (v) => _update(v, onTop),
        ),
        const SizedBox(width: 8),
        CompactNumberField(
          initialValue: bottom,
          label: l10n.bottom,
          width: 72,
          onChanged: (v) => _update(v, onBottom),
        ),
        const SizedBox(width: 8),
        CompactNumberField(
          initialValue: left,
          label: l10n.left,
          width: 72,
          onChanged: (v) => _update(v, onLeft),
        ),
        const SizedBox(width: 8),
        CompactNumberField(
          initialValue: right,
          label: l10n.right,
          width: 72,
          onChanged: (v) => _update(v, onRight),
        ),
      ],
    );
  }
}

/// Small template preview shown next to a template dropdown.
class TemplateThumb extends StatelessWidget {
  final String? svgContent;
  final double width;
  final double height;

  const TemplateThumb({
    super.key,
    this.svgContent,
    this.width = 112,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: svgContent == null
          ? Center(
              child: Icon(
                Icons.article_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
            )
          : SvgPicture.string(svgContent!, fit: BoxFit.contain),
    );
  }
}

class PanelCheckbox extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  const PanelCheckbox({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.sky500,
              side: BorderSide(color: AppColors.textMuted),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Single-line font row: label, picker, size, and reset action.
class CompactFontRow extends StatelessWidget {
  final String label;
  final FontConfig? current;
  final String defaultName;
  final double defaultSize;
  final AppLocalizations l10n;
  final ValueChanged<SystemFontInfo> onSelected;
  final ValueChanged<String> onSizeChanged;
  final VoidCallback onReset;

  const CompactFontRow({
    super.key,
    required this.label,
    required this.current,
    required this.defaultName,
    required this.defaultSize,
    required this.l10n,
    required this.onSelected,
    required this.onSizeChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final hasOverride = current != null;
    final effectiveSize = current?.fontSize ?? defaultSize;

    return Row(
      children: [
        SizedBox(width: 120, child: SettingsSectionLabel(label)),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: FontPicker(
              label: '',
              placeholder: hasOverride
                  ? (current?.fontFamily ?? defaultName)
                  : 'Default: $defaultName',
              selectedPath: current?.fontPath,
              onSelected: onSelected,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 70,
          child: TextFormField(
            initialValue: effectiveSize.toStringAsFixed(1),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: onSizeChanged,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: compactNumberDecor(l10n.size),
          ),
        ),
        SizedBox(
          width: 24,
          child: hasOverride
              ? IconButton(
                  icon: const Icon(Icons.restart_alt, size: 15),
                  tooltip: l10n.resetToDefault,
                  onPressed: onReset,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
