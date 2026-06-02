import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base palette (Tailwind Slate)
  static const slate950 = Color(0xFF020617);
  static const slate900 = Color(0xFF0f172a);
  static const slate800 = Color(0xFF1e293b);
  static const slate700 = Color(0xFF334155);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748b);
  static const slate400 = Color(0xFF94a3b8);
  static const slate300 = Color(0xFFcbd5e1);
  static const slate200 = Color(0xFFe2e8f0);
  static const slate100 = Color(0xFFf1f5f9);

  static const lightSlate50 = Color(0xFFf8fafc);

  // Accent colors (unchanged across themes)
  static const sky500 = Color(0xFF0ea5e9);
  static const sky400 = Color(0xFF38bdf8);

  static const rose600 = Color(0xFFe11d48);
  static const rose500 = Color(0xFFf43f5e);
  static const rose400 = Color(0xFFfb7185);
  static const rose300 = Color(0xFFfda4af);

  static const emerald400 = Color(0xFF34d399);

  static const amber400 = Color(0xFFfbbf24);

  // --- Theme-aware semantic colors ---
  // Updated by setBrightness(); use these everywhere in widgets.

  // Text
  static Color textPrimary = slate100;
  static Color textSecondary = slate200;
  static Color textBody = slate300;
  static Color textCaption = slate400;
  static Color textMuted = slate500;
  static Color textFaint = slate600;

  // Surfaces
  static Color cardBg = slate900.withValues(alpha: 0.4);
  static Color cardBorder = slate800;
  static Color surface = slate900;
  static Color surfaceContainer = slate800;
  static Color inputFill = Color(0x66020617);

  // Borders & dividers
  static Color border = slate700;
  static Color borderSubtle = slate800;
  static Color divider = slate800;

  // Contrasting muted button (light on dark, dark on light)
  static Color buttonMutedBg = slate100;
  static Color buttonMutedFg = slate900;

  /// Call this once before building the widget tree.
  static void setBrightness(Brightness brightness) {
    if (brightness == Brightness.light) {
      textPrimary = slate900;
      textSecondary = slate700;
      textBody = slate600;
      textCaption = slate500;
      textMuted = slate500;
      textFaint = slate400;

      cardBg = const Color(0xFFFFFFFF);
      cardBorder = slate200;
      surface = const Color(0xFFFFFFFF);
      surfaceContainer = lightSlate50;
      inputFill = slate100;

      border = slate300;
      borderSubtle = slate200;
      divider = slate200;

      buttonMutedBg = slate200;
      buttonMutedFg = slate800;
    } else {
      textPrimary = slate100;
      textSecondary = slate200;
      textBody = slate300;
      textCaption = slate400;
      textMuted = slate500;
      textFaint = slate600;

      cardBg = slate900.withValues(alpha: 0.4);
      cardBorder = slate800;
      surface = slate900;
      surfaceContainer = slate800;
      inputFill = slate950.withValues(alpha: 0.4);

      border = slate700;
      borderSubtle = slate800;
      divider = slate800;

      buttonMutedBg = slate100;
      buttonMutedFg = slate900;
    }
  }
}
