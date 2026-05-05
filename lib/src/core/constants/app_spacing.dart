import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Spacing constants for padding, margin, and gap.
/// Always use .w or .h suffixes — never hardcode pixel values.
abstract final class AppSpacing {
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
  static double get xxl => 48.w;

  // --- Vertical specific ---
  static double get verticalSm => 8.h;
  static double get verticalMd => 16.h;
  static double get verticalLg => 24.h;
  static double get verticalXl => 32.h;

  // --- Screen horizontal padding ---
  static double get screenHorizontal => 20.w;

  // --- Border radius ---
  static double get radiusSm => 8.r;
  static double get radiusMd => 12.r;
  static double get radiusLg => 20.r;
  static double get radiusXl => 32.r;
  static double get radiusFull => 999.r;
}
