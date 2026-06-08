import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Unified SnackBar utility.
///
/// Usage:
///   AppSnackBar.error(context, '메시지');
///   AppSnackBar.success(context, '메시지');
///   AppSnackBar.info(context, '메시지');
abstract final class AppSnackBar {
  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.errorBannerBg,
      textColor: AppColors.errorBannerFg,
      icon: Icons.error_outline_rounded,
    );
  }

  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFFE8F5E9),
      textColor: const Color(0xFF2E7D32),
      icon: Icons.check_circle_outline_rounded,
    );
  }

  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFFE3F2FD),
      textColor: const Color(0xFF1565C0),
      icon: Icons.info_outline_rounded,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: textColor, size: 18.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          duration: const Duration(seconds: 3),
          elevation: 4,
        ),
      );
  }
}
