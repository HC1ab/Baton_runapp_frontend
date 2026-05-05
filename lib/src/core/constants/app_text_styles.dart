import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// App-wide text styles.
/// Always use .sp for font sizes to support responsive scaling.
abstract final class AppTextStyles {
  // --- Display ---
  static TextStyle get displayLarge => TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.bold,
      );

  // --- Headline ---
  static TextStyle get headlineLarge => TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get headlineMedium => TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get headlineSmall => TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
      );

  // --- Body ---
  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.normal,
      );

  // --- Label ---
  static TextStyle get labelLarge => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  // --- Running specific ---
  static TextStyle get runningMetricLarge => TextStyle(
        fontSize: 48.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: -1,
      );

  static TextStyle get runningMetricSmall => TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
      );
}
