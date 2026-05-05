import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../models/run_record_model.dart';

/// Bottom sheet-style dashboard showing real-time run metrics.
/// Design reference: warm white card with large bold numbers.
class RunningDashboard extends StatelessWidget {
  const RunningDashboard({super.key, required this.record});

  final RunRecordModel record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.verticalLg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          SizedBox(height: AppSpacing.verticalMd),

          // Metrics row
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: '거리 (KM)',
                  value: (record.distanceMeters / 1000).toStringAsFixed(1),
                  labelColor: AppColors.primary,
                ),
              ),
              Container(
                width: 1,
                height: 48.h,
                color: AppColors.divider,
              ),
              Expanded(
                child: _MetricItem(
                  label: '페이스',
                  value: record.formattedCurrentPace,
                ),
              ),
              Container(
                width: 1,
                height: 48.h,
                color: AppColors.divider,
              ),
              Expanded(
                child: _MetricItem(
                  label: '시간',
                  value: FormatUtils.formatDurationShort(record.duration),
                ),
              ),
            ],
          ),

          // Points row (if any)
          if (record.spotPoints > 0) ...[
            SizedBox(height: AppSpacing.verticalMd),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars_rounded,
                    size: 16.r,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '스팟 ${record.checkedInSpotIds.length}개 · +${record.spotPoints}P',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    this.labelColor = AppColors.textSecondary,
  });

  final String label;
  final String value;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: AppTextStyles.runningMetricLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
