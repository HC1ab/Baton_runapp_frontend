import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/error_messages.dart';
import '../../services/spot_service.dart';

/// 체크인 성공 / 이미 체크인 시 지도 위에 표시되는 팝업 카드
class CheckInResultCard extends StatelessWidget {
  const CheckInResultCard({super.key, required this.result});

  final CheckInResult result;

  @override
  Widget build(BuildContext context) {
    final isAlready = result.isAlreadyCheckedIn;
    final accentColor = isAlready ? AppColors.dMuted : AppColors.dAccent;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.dCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAlready
                  ? Icons.check_circle_outline_rounded
                  : Icons.location_on_rounded,
              color: accentColor,
              size: 22.r,
            ),
          ),

          SizedBox(width: AppSpacing.sm),

          // 스팟 이름 + 상태 메시지
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result.spotName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.dText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  isAlready
                      ? ErrorMessages.spotAlreadyCheckedInCard
                      : '체크인 완료! 현재 ${result.currentTotalPoints}P 보유',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.dMuted,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: AppSpacing.sm),

          // 포인트 배지 or 차단 아이콘
          if (!isAlready)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.dAccent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                '+${result.earnedPoints}P',
                style: AppTextStyles.labelSmall.copyWith(
                  color: const Color(0xFF1A0E06),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Icon(Icons.block_rounded, color: AppColors.dMuted, size: 20.r),
        ],
      ),
    );
  }
}
