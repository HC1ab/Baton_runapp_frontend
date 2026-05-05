import 'package:flutter/material.dart';

/// Brand & semantic color constants.
/// Use Theme.of(context) for theme-adaptive colors.
/// Use AppColors directly only for fixed brand colors.
abstract final class AppColors {
  // --- Brand ---
  static const primary = Color(0xFF00BFCB);
  static const primaryVariant = Color(0xFF00E5FF);

  // --- Semantic ---
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFE53935);
  static const info = Color(0xFF2196F3);

  // --- Running specific ---
  static const runningActive = Color(0xFF00BFCB);
  static const runningPaused = Color(0xFFFFC107);

  // --- Neutral (dark theme base) ---
  static const backgroundDark = Color(0xFF05080D);
  static const backgroundLight = Color(0xFFF7FAFF);
  static const surfaceLight = Color(0xFFEAF2FF);
}
