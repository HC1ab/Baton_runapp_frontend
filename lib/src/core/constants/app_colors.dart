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

  // --- Reward badges (EXP / Point) ---
  static const rewardExpIcon    = Color(0xFFFF8C42); // EXP 아이콘
  static const rewardExpBg      = Color(0xFFFFF3EC); // EXP 배지 배경
  static const rewardExpText    = Color(0xFFCC5500); // EXP 텍스트
  static const rewardPointIcon  = Color(0xFFE8A800); // 포인트 아이콘
  static const rewardPointBg    = Color(0xFFFFF8E1); // 포인트 배지 배경
  static const rewardPointText  = Color(0xFFB07800); // 포인트 텍스트

  // --- Social ---
  static const socialAccent = Color(0xFFF7673B);    // point orange (social feed / FAB)
  static const scaffoldGrey = Color(0xFFF4F4F4);    // light grey scaffold bg
  static const cardHighlighted = Color(0xFFBA3B10); // highlighted group run card bg
  static const sectionLabel = Color(0xFF8F2E1A);    // section label text
  static const iconNeutral = Color(0xFF555555);     // muted icon
  static const avatarTeal = Color(0xFF1F7E8A);      // avatar bg
  static const errorBannerBg = Color(0xFFFFEBEE);   // error banner background
  static const errorBannerFg = Color(0xFFC62828);   // error banner foreground
  static const connecting = Color(0xFFFF9800);      // connecting state indicator
  static const textMuted = Color(0xFF444444);       // muted body text
  static const inputAccent = Color(0xFFB33010);     // input field suffix icon accent
}
