import 'package:flutter/material.dart';

import 'colors.dart';

InputDecoration fieldDecoration({
  required String label,
  required String placeholder,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      color: AppColors.textMuted,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    ),
    hintText: placeholder,
    hintStyle: TextStyle(
      color: AppColors.textMuted.withValues(alpha: 0.5),
      fontSize: 13,
    ),
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

InputDecoration numberDecor(String label) {
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
