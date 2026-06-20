import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/spot_providers.dart';

/// 스팟 기본 정보(이름/설명/리워드)를 아래에서 위로 올라오는 미니 시트로 표시.
/// 러닝 화면에서 스팟 마커 탭 시 사용.
class SpotInfoSheet extends ConsumerWidget {
  const SpotInfoSheet({super.key, required this.spotId});

  final int spotId;

  /// 모달 바텀시트로 띄우는 헬퍼.
  static Future<void> show(BuildContext context, int spotId) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SpotInfoSheet(spotId: spotId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(spotDetailProvider(spotId));

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.all(10.r),
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 22.h),
        decoration: BoxDecoration(
          color: AppColors.dCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.dLine2, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 18.h),
                decoration: BoxDecoration(
                  color: AppColors.dLine2,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            detailAsync.when(
              loading: () => Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.dAccent),
                ),
              ),
              error: (e, _) => Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                  '스팟 정보를 불러오지 못했어요.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.dMuted),
                ),
              ),
              data: (detail) => _content(detail),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(SpotDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 스팟 이름
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: AppColors.dAccentSoft,
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: AppColors.dAccentBright,
                size: 22.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Text(
                  detail.name.isEmpty ? '이름 없는 스팟' : detail.name,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.dText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),

        // 설명
        if (detail.description.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Text(
            detail.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.dMuted,
              height: 1.45,
            ),
          ),
        ],

        SizedBox(height: 16.h),

        // 체크인 리워드 배지
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.dGoldSoft,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monetization_on_rounded, color: AppColors.dGold, size: 16.r),
              SizedBox(width: 6.w),
              Text(
                '체크인 시 +${detail.rewardAmount}P',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.dGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
