import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';

/// A title name shown inside a rarity-tinted pill, tuned for the dark UI.
///
/// Kept deliberately restrained — soft tinted fills + thin borders on the
/// warm near-black surfaces (no blinding glows). Higher rarities step up the
/// accent richness (cool blue → orange → gold) and add a subtle sparkle.
/// The pill wraps its content (never stretches full-width).
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

  static const double _baseFontSize = 16;

  @override
  Widget build(BuildContext context) {
    final fs = fontSize ?? _baseFontSize.sp;
    final scale = fs / _baseFontSize.sp;

    if (title.isEmpty) {
      return Text(
        'No Title',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: fs,
          color: AppColors.dMuted,
        ),
      );
    }

    final spec = _RaritySpec.of(rarity);

    // Align keeps the pill at its intrinsic width even when the parent
    // would otherwise stretch it across the full row.
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w * scale,
          vertical: 7.h * scale,
        ),
        decoration: BoxDecoration(
          color: spec.fill,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(color: spec.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (spec.sparkle) ...[
              Icon(Icons.auto_awesome_rounded,
                  size: 12.r * scale, color: spec.text.withValues(alpha: 0.85)),
              SizedBox(width: 5.w),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: fs,
                color: spec.text,
                letterSpacing: 0.2,
              ),
            ),
            if (spec.sparkle) ...[
              SizedBox(width: 5.w),
              Icon(Icons.auto_awesome_rounded,
                  size: 12.r * scale, color: spec.text.withValues(alpha: 0.85)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RaritySpec {
  const _RaritySpec({
    required this.fill,
    required this.border,
    required this.text,
    this.sparkle = false,
  });

  final Color fill;
  final Color border;
  final Color text;
  final bool sparkle;

  factory _RaritySpec.of(String rarity) {
    switch (rarity) {
      case 'RARE':
        // Cool blue accent (per redesign — titles use a cool tone vs orange core)
        return const _RaritySpec(
          fill: AppColors.dTitleBlueSoft,
          border: AppColors.dTitleBlueBorder,
          text: AppColors.dTitleBlue,
        );
      case 'EPIC':
        return _RaritySpec(
          fill: AppColors.dAccentSoft,
          border: AppColors.dAccent.withValues(alpha: 0.45),
          text: AppColors.dAccentBright,
        );
      case 'LEGENDARY':
        return _RaritySpec(
          fill: AppColors.dGoldSoft,
          border: AppColors.dGold.withValues(alpha: 0.5),
          text: AppColors.dGold,
          sparkle: true,
        );
      default: // NORMAL
        return _RaritySpec(
          fill: AppColors.dCard2,
          border: AppColors.dLine2,
          text: AppColors.dText,
        );
    }
  }
}
