import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../models/run_record_model.dart';
import '../../models/spot_model.dart';

/// 반경 30m 이내 스팟 진입 시 표시되는 정보 카드.
/// 스팟 이름, 체크인 여부, 쿨다운 상태를 보여줌.
class SpotInRangeCard extends StatelessWidget {
  const SpotInRangeCard({
    super.key,
    required this.spots,
    required this.record,
  });

  /// 반경 내 스팟 목록 (spotsInRange ID 기준으로 필터된 SpotSummary)
  final List<SpotSummary> spots;
  final RunRecordModel record;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < spots.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppColors.textSecondary.withValues(alpha: 0.1),
              ),
            _SpotRow(spot: spots[i], record: record),
          ],
        ],
      ),
    );
  }
}

class _SpotRow extends StatelessWidget {
  const _SpotRow({required this.spot, required this.record});

  final SpotSummary spot;
  final RunRecordModel record;

  @override
  Widget build(BuildContext context) {
    final checkedThisRun = record.checkedInSpotIds.contains(spot.id);
    final blocked = record.blockedSpotIds.contains(spot.id);
    final cooldownActive = !spot.canCheckIn;
    final isDone = checkedThisRun || blocked || cooldownActive;

    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    if (checkedThisRun) {
      statusColor = AppColors.success;
      statusText = '체크인 완료';
      statusIcon = Icons.check_circle_rounded;
    } else if (blocked || cooldownActive) {
      statusColor = AppColors.warning;
      statusText = '24h 쿨타임';
      statusIcon = Icons.timelapse_rounded;
    } else {
      statusColor = AppColors.primary;
      statusText = '체크인 가능';
      statusIcon = Icons.radio_button_checked_rounded;
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12.h,
      ),
      child: Row(
        children: [
          // 상태 아이콘
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 18.r),
          ),
          SizedBox(width: 12.w),

          // 스팟 이름
          Expanded(
            child: Text(
              spot.name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8.w),

          // 상태 배지
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isDone) ...[
                  Text(
                    '+${spot.rewardAmount}P',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  SizedBox(width: 4.w),
                ],
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
