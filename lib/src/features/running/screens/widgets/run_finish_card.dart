import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../models/run_record_model.dart';

class RunFinishCard extends StatelessWidget {
  const RunFinishCard({
    super.key,
    required this.record,
    required this.onConfirm,
  });

  final RunRecordModel record;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 4.h),

          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22.r),
              SizedBox(width: 8.w),
              Text(
                '러닝 완료!',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary,  
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 주 지표 — 거리
          Column(
            children: [
              Text(
                '총 거리',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4.h),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: (record.distanceMeters / 1000).toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 52.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -2,
                        height: 1.0,
                      ),
                    ),
                    TextSpan(
                      text: ' km',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 구분선
          Divider(color: AppColors.textSecondary.withValues(alpha: 0.12)),
          SizedBox(height: 16.h),

          // 페이스 + 시간
          Row(
            children: [
              Expanded(
                child: _MetricCell(
                  label: '평균 페이스',
                  value: record.formattedAveragePace,
                  unit: '/km',
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _MetricCell(
                  label: '경과 시간',
                  value: record.formattedDuration,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // 포인트 + 스팟
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MetricCell(
                    label: '획득 포인트',
                    value: '+${record.totalPoints}P',
                    valueColor: AppColors.primary,
                  ),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _MetricCell(
                    label: '체크인 스팟',
                    value: '${record.checkedInSpotIds.length}개',
                    valueColor: record.checkedInSpotIds.isNotEmpty
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // 확인 버튼
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              child: Text(
                '확인',
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    this.unit,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? unit;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              if (unit != null)
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36.h,
      color: AppColors.textSecondary.withValues(alpha: 0.15),
    );
  }
}
