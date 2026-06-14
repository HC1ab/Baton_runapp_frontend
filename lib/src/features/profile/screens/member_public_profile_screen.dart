import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/widgets/character_sphere_widget.dart';
import '../../../core/character/character_style.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/member_profile_model.dart';

/// memberId로 조회한 공개 프로필을 보여주는 읽기 전용 화면.
/// (스팟 점령자 등 닉네임 검색 없이도 이미 가진 데이터로 표시)
class MemberPublicProfileScreen extends StatelessWidget {
  const MemberPublicProfileScreen({super.key, required this.profile});

  final MemberPublicProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dScreen,
      appBar: AppBar(
        backgroundColor: AppColors.dScreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.r),
          color: AppColors.dAccent,
        ),
        title: Text(
          '멤버 프로필',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.dText,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.sm,
            AppSpacing.screenHorizontal,
            28.h,
          ),
          children: [
            SizedBox(height: 12.h),
            Center(
              child: CharacterSphereWidget(
                style: CharacterStylePresets.fromCode(profile.coreColorCode),
                size: 120.r,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.h),
              child: Column(
                children: [
                  Text(
                    profile.nickname,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dText,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    profile.equippedTitleName.isEmpty
                        ? 'No Title'
                        : profile.equippedTitleName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.h),
              child: _buildLevelCard(profile.level),
            ),
            Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.straighten_rounded,
                      label: '총 거리',
                      value: '${profile.totalDistance.toStringAsFixed(1)} km',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.speed_rounded,
                      label: '평균 페이스',
                      value: profile.avgPaceText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(int level) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: AppColors.dCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.dLine, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '러닝 레벨',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.dMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Lv.$level',
            style: TextStyle(
              fontSize: 38.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.dCard2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.dLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22.r),
          SizedBox(height: 12.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.dMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.dText,
            ),
          ),
        ],
      ),
    );
  }
}
