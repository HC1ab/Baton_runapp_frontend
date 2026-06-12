import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/error_messages.dart';
import '../../../run_share/models/run_share_data.dart';
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
        color: AppColors.dCard,
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
              Icon(
                record.recordedToServer
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: record.recordedToServer
                    ? AppColors.dAccent
                    : AppColors.dMuted,
                size: 22.r,
              ),
              SizedBox(width: 8.w),
              Text(
                record.recordedToServer ? '러닝 완료!' : '러닝 종료',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.dText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // 기록 안 됨 배너
          if (!record.recordedToServer) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.dMuted.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.dMuted, size: 16.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      ErrorMessages.runTooShortNotice,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.dMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ] else
            SizedBox(height: 12.h),

          // 주 지표 — 거리
          Column(
            children: [
              Text(
                '총 거리',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.dAccent,
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
                        color: AppColors.dText,
                        letterSpacing: -2,
                        height: 1.0,
                      ),
                    ),
                    TextSpan(
                      text: ' km',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // 구분선
          Divider(color: AppColors.dMuted.withValues(alpha: 0.12)),
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
              color: AppColors.dAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MetricCell(
                    label: '획득 포인트',
                    value: '+${record.totalPoints}P',
                    valueColor: AppColors.dAccent,
                  ),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _MetricCell(
                    label: '체크인 스팟',
                    value: '${record.checkedInSpotIds.length}개',
                    valueColor: record.checkedInSpotIds.isNotEmpty
                        ? AppColors.dAccent
                        : AppColors.dText,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // 공유 카드 버튼
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                AppRoutes.runShare,
                extra: RunShareData.fromRecord(record),
              ),
              icon: Icon(Icons.share_rounded,
                  size: 18.r, color: AppColors.primary),
              label: Text(
                '공유 카드 만들기',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // 확인 버튼
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dAccent,
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
            color: AppColors.dMuted,
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
                  color: valueColor ?? AppColors.dText,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              if (unit != null)
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.dMuted,
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
      color: AppColors.dMuted.withValues(alpha: 0.15),
    );
  }
}
