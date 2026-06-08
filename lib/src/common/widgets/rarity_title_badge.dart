import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

/// Displays a title name inside a rarity-tinted "box effect" banner.
///
/// Higher rarities get richer gradients, brighter borders, layered glows,
/// and extra decoration — styled to fit Baton's warm coral/cream palette
/// (no garish game-UI colors). Box size scales with [fontSize] so smaller
/// placements (e.g. profile subtitle) get a proportionally compact badge.
class RarityTitleBadge extends StatelessWidget {
  const RarityTitleBadge({
    super.key,
    required this.title,
    required this.rarity,
    this.fontSize,
  });

  final String title;
  final String rarity;
  final double? fontSize;

  static const double _baseFontSize = 24;

  @override
  Widget build(BuildContext context) {
    final effectiveFontSize = fontSize ?? _baseFontSize.sp;
    final scale = effectiveFontSize / _baseFontSize.sp;

    if (title.isEmpty) {
      return Text(
        'No Title',
        style: AppTextStyles.headlineLarge.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
        ),
      );
    }

    final spec = _RaritySpec.of(rarity);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 18.w * scale,
        vertical: 8.h * scale,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: spec.gradient,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: spec.border, width: spec.borderWidth),
        boxShadow: spec.shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (spec.sheen)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.32),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (spec.sparkle) ...[
                  Icon(Icons.auto_awesome_rounded,
                      size: 12.r * scale, color: spec.text.withValues(alpha: 0.8)),
                  SizedBox(width: 4.w),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: fontSize,
                    color: spec.text,
                    letterSpacing: spec.letterSpacing,
                    shadows: spec.textShadow == null ? null : [spec.textShadow!],
                  ),
                ),
                if (spec.sparkle) ...[
                  SizedBox(width: 4.w),
                  Icon(Icons.auto_awesome_rounded,
                      size: 12.r * scale, color: spec.text.withValues(alpha: 0.8)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Visual recipe per rarity tier — each step up adds more decoration
/// (deeper gradient, brighter border, layered glow, sheen, sparkle).
class _RaritySpec {
  const _RaritySpec({
    required this.gradient,
    required this.border,
    required this.text,
    this.borderWidth = 1,
    this.shadows = const [],
    this.letterSpacing = 0,
    this.textShadow,
    this.sheen = false,
    this.sparkle = false,
  });

  final List<Color> gradient;
  final Color border;
  final Color text;
  final double borderWidth;
  final List<BoxShadow> shadows;
  final double letterSpacing;
  final Shadow? textShadow;

  /// Soft inner highlight across the top of the box.
  final bool sheen;

  /// Small sparkle icons flanking the title text.
  final bool sparkle;

  factory _RaritySpec.of(String rarity) {
    switch (rarity) {
      case 'RARE':
        return _RaritySpec(
          gradient: [
            AppColors.info.withValues(alpha: 0.16),
            AppColors.info.withValues(alpha: 0.05),
          ],
          border: AppColors.info.withValues(alpha: 0.45),
          text: AppColors.info.withValues(alpha: 0.95),
          borderWidth: 1.2,
          shadows: [
            BoxShadow(
              color: AppColors.info.withValues(alpha: 0.16),
              blurRadius: 12,
            ),
          ],
        );
      case 'EPIC':
        return _RaritySpec(
          gradient: [
            AppColors.primary.withValues(alpha: 0.24),
            AppColors.primaryDark.withValues(alpha: 0.09),
          ],
          border: AppColors.primary.withValues(alpha: 0.6),
          text: AppColors.primaryDark,
          borderWidth: 1.5,
          shadows: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 18,
              spreadRadius: 0.5,
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.14),
              blurRadius: 30,
              spreadRadius: 1.5,
            ),
          ],
          letterSpacing: 0.3,
          sheen: true,
        );
      case 'LEGENDARY':
        return _RaritySpec(
          gradient: [
            AppColors.warning.withValues(alpha: 0.34),
            AppColors.primary.withValues(alpha: 0.20),
          ],
          border: AppColors.warning.withValues(alpha: 0.75),
          text: const Color(0xFF8A5A12),
          borderWidth: 1.8,
          shadows: [
            BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.45),
              blurRadius: 14,
              spreadRadius: 0.5,
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 28,
              spreadRadius: 1.5,
            ),
            BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.16),
              blurRadius: 44,
              spreadRadius: 3,
            ),
          ],
          letterSpacing: 0.7,
          textShadow: Shadow(
            color: Colors.white.withValues(alpha: 0.65),
            blurRadius: 6,
          ),
          sheen: true,
          sparkle: true,
        );
      default: // NORMAL
        return _RaritySpec(
          gradient: [
            AppColors.divider.withValues(alpha: 0.9),
            AppColors.divider.withValues(alpha: 0.4),
          ],
          border: AppColors.textSecondary.withValues(alpha: 0.25),
          text: AppColors.textPrimary,
          borderWidth: 1,
        );
    }
  }
}
