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

  // ===========================================================================
  // Redesign — Modern Dark UI (warm near-black). README Design Tokens.
  // Use these for the dark refresh; legacy light constants above stay intact.
  // ===========================================================================

  // --- Surfaces (refined charcoal — brighter, less blue cast) ---
  static const dBg = Color(0xFF0E0E10);          // --bg (app body)
  static const dScreen = Color(0xFF141416);      // --screen (scaffold)
  static const dCard = Color(0xFF1E1E21);        // --card
  static const dCard2 = Color(0xFF28282B);       // --card-2 (locked / inset)
  static const dCard3 = Color(0xFF323235);       // --card-3
  static const dLine = Color(0x0FFFFFFF);        // --line  white 6%
  static const dLine2 = Color(0x1AFFFFFF);       // --line-2 white 10%

  // --- Brand orange (redesign accent — preserved palette) ---
  static const dAccent = Color(0xFFEC6E2C);      // --accent
  static const dAccentBright = Color(0xFFFF8C42); // --accent-bright
  static const dAccentDeep = Color(0xFFC8551C);  // --accent-deep
  static const dAccentSoft = Color(0x24EC6E2C);  // --accent-soft rgba(236,110,44,0.14)
  static const dAccentGlow = Color(0x73EC6E2C);  // --accent-glow rgba(236,110,44,0.45)

  // --- Support ---
  static const dGold = Color(0xFFE0A437);        // --gold (points)
  static const dGoldSoft = Color(0x29E0A437);    // --gold-soft rgba(224,164,55,0.16)
  static const dRouteStart = Color(0xFF36C26B);  // --green (route start dot)
  static const dRouteEnd = Color(0xFFE8503A);    // --red (route end dot)
  static const dTitleBlue = Color(0xFFAEBFFF);   // title badge text (cool accent)
  static const dTitleBlueSoft = Color(0x293A57D6); // --blue-soft rgba(58,87,214,0.16)
  static const dTitleBlueBorder = Color(0x663A57D6); // rgba(58,87,214,0.4)

  // --- Text (refined charcoal) ---
  static const dText = Color(0xFFF5F5F7);        // --text
  static const dMuted = Color(0xFFA3A3A6);       // --muted
  static const dFaint = Color(0xFF707073);       // --faint
}
