import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../profile/screens/member_public_profile_screen.dart';
import '../../profile/services/member_profile_service.dart';
import '../providers/spot_providers.dart';

/// 스팟 상세 화면 — 스팟 정보 + 현재 점령자 현황을 보여줌.
class SpotDetailScreen extends ConsumerWidget {
  const SpotDetailScreen({super.key, required this.spotId});

  final int spotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(spotDetailProvider(spotId));

    return Scaffold(
      backgroundColor: AppColors.dScreen,
      appBar: AppBar(
        backgroundColor: AppColors.dScreen,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.dText, size: 20.r),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '스팟 상세',
          style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.dAccent),
        ),
        error: (e, _) => _buildError(ref),
        data: (detail) => _buildBody(detail),
      ),
    );
  }

  Widget _buildBody(SpotDetail detail) {
    final hasOccupier = detail.occupierMemberId != null;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        0,
        AppSpacing.screenHorizontal,
        40.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),

          // ── 스팟 이름 + 설명 ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: AppColors.dAccentSoft,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.dAccentBright,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.name,
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.dText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (detail.description.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        detail.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.dMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // ── 체크인 리워드 ────────────────────────────────────────────
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

          SizedBox(height: 24.h),

          // ── 점령자 현황 ──────────────────────────────────────────────
          Text(
            '점령 현황',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.dMuted,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.dCard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: hasOccupier
                    ? AppColors.dGold.withValues(alpha: 0.3)
                    : AppColors.dLine,
                width: 1,
              ),
            ),
            child: hasOccupier
                ? _OccupierCard(
                    memberId: detail.occupierMemberId!,
                    checkinCount: detail.occupierCheckinCount ?? 0,
                  )
                : Row(
                    children: [
                      Icon(Icons.flag_outlined, color: AppColors.dFaint, size: 22.r),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          '아직 이 스팟의 점령자가 없어요.\n가장 많이 체크인하면 점령자가 될 수 있어요!',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.dMuted,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          SizedBox(height: 24.h),

          // ── 나의 체크인 ──────────────────────────────────────────────
          Text(
            '나의 체크인',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.dMuted,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.dCard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.dLine, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: AppColors.dAccentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.how_to_reg_rounded,
                    color: AppColors.dAccentBright,
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    '이 스팟에 체크인한 횟수',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.dMuted,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  '${detail.myCheckinCount ?? 0}회',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.dText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40.r, color: AppColors.dRouteEnd),
          SizedBox(height: 12.h),
          Text(
            '스팟 정보를 불러오지 못했어요.',
            style: TextStyle(color: AppColors.dMuted, fontSize: 14.sp),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => ref.invalidate(spotDetailProvider(spotId)),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

/// 현재 점령자 정보 카드 — memberId로 닉네임/레벨을 함께 보여줌.
class _OccupierCard extends ConsumerWidget {
  const _OccupierCard({required this.memberId, required this.checkinCount});

  final int memberId;
  final int checkinCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(memberPublicProfileProvider(memberId));
    final profile = profileAsync.value;
    final nickname = profile?.nickname;
    final level = profile?.level;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: profile == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MemberPublicProfileScreen(profile: profile),
                ),
              ),
      child: Row(
      children: [
        Container(
          width: 48.r,
          height: 48.r,
          decoration: BoxDecoration(
            color: AppColors.dGoldSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.emoji_events_rounded,
            color: AppColors.dGold,
            size: 24.r,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '현재 점령자',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.dMuted,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                nickname ?? '멤버 #$memberId',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.dText,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (level != null) ...[
                SizedBox(height: 2.h),
                Text(
                  'Lv.$level',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.dFaint,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.dGold,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            '체크인 $checkinCount회',
            style: AppTextStyles.labelSmall.copyWith(
              color: const Color(0xFF1A0E06),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      ),
    );
  }
}
