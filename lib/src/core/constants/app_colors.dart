import 'package:flutter/material.dart';

/// Brand & semantic color constants.
/// Use Theme.of(context) for theme-adaptive colors.
/// Use AppColors directly only for fixed brand colors.
abstract final class AppColors {
  // --- Brand (Coral Orange) ---
  static const primary = Color(0xFFE8704A);
  static const primaryLight = Color(0xFFF0906E);
  static const primaryDark = Color(0xFFD05535);

  // --- Background ---
  static const backgroundLight = Color(0xFFF5F0EB); // Warm cream
  static const backgroundDark = Color(0xFF1A1612);  // Warm dark
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF2A2420);

  // --- Map tones ---
  static const mapBackground = Color(0xFFEDE8E3);   // Warm beige for map

  // --- Text ---
  static const textPrimary = Color(0xFF1A1612);
  static const textSecondary = Color(0xFF8A8480);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // --- Semantic ---
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFF5A623);
  static const error = Color(0xFFE53935);
  static const info = Color(0xFF2196F3);

  // --- Running specific ---
  static const runningActive = Color(0xFFE8704A);
  static const runningPaused = Color(0xFFF5A623);

  // --- Neutral ---
  static const divider = Color(0xFFEDE8E3);
  static const cardShadow = Color(0x1AE8704A); // primary @ 10%

  // --- Shop badges ---
  static const shopBadgeColor = Color(0xFF00897B); // COLOR badge (teal)

  // --- Map overlays ---
  static const spotNeutral = Color(0xFF888888);
}
