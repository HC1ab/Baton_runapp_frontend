import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/spot_providers.dart';

class SpotScreen extends ConsumerStatefulWidget {
  const SpotScreen({super.key});

  @override
  ConsumerState<SpotScreen> createState() => _SpotScreenState();
}

class _SpotScreenState extends ConsumerState<SpotScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // 쿨타임 카운트다운을 1초마다 갱신
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final spotsAsync = ref.watch(spotCooldownsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 ────────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              topPadding + AppSpacing.verticalSm,
              AppSpacing.screenHorizontal,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SPOT',
                  style: TextStyle(
                    color: AppColors.sectionLabel,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '내가 방문한 스팟',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // ── 목록 ────────────────────────────────────────────────────────
          Expanded(
            child: spotsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => _buildError(),
              data: (spots) => spots.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async =>
                          ref.invalidate(spotCooldownsProvider),
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.screenHorizontal,
                          0,
                          AppSpacing.screenHorizontal,
                          AppSpacing.xxl + 20.h, // nav bar 여유
                        ),
                        itemCount: spots.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (_, i) => _SpotCooldownCard(spot: spots[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off_rounded,
            size: 52.r,
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
          SizedBox(height: 16.h),
          Text(
            '아직 방문한 스팟이 없어요',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '러닝 중 스팟 근처를 지나면\n자동으로 체크인돼요!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40.r, color: AppColors.error),
          SizedBox(height: 12.h),
          Text(
            '목록을 불러오지 못했어요.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => ref.invalidate(spotCooldownsProvider),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

// ── 카드 ──────────────────────────────────────────────────────────────────────

class _SpotCooldownCard extends StatelessWidget {
  const _SpotCooldownCard({required this.spot});
  final SpotCooldownModel spot;

  @override
  Widget build(BuildContext context) {
    final isAvailable = spot.isAvailable;
    final progress = spot.cooldownProgress;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 스팟 아이콘
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 22.r,
                ),
              ),
              SizedBox(width: 12.w),

              // 스팟 이름 + 방문일
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.spotName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      '마지막 방문: ${_formatDate(spot.lastCheckinAt)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),

              // 쿨타임 원형 인디케이터
              _CooldownIndicator(
                progress: progress,
                isAvailable: isAvailable,
                remainingSeconds: spot.liveRemainingSeconds,
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // 구분선
          Divider(height: 1, color: AppColors.divider),
          SizedBox(height: 12.h),

          // EXP / 포인트 배지
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _RewardBadge(
                icon: Icons.bolt_rounded,
                label: '+${spot.expAmount} EXP',
                iconColor: const Color(0xFFFF8C42),
                bgColor: const Color(0xFFFFF3EC),
                textColor: const Color(0xFFCC5500),
              ),
              SizedBox(width: 8.w),
              _RewardBadge(
                icon: Icons.monetization_on_rounded,
                label: '${spot.rewardAmount}P',
                iconColor: const Color(0xFFE8A800),
                bgColor: const Color(0xFFFFF8E1),
                textColor: const Color(0xFFB07800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      DateFormat('yyyy.MM.dd').format(dt);
}

// ── 쿨타임 원형 인디케이터 ─────────────────────────────────────────────────────

class _CooldownIndicator extends StatelessWidget {
  const _CooldownIndicator({
    required this.progress,
    required this.isAvailable,
    required this.remainingSeconds,
  });

  final double progress;
  final bool isAvailable;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 54.r,
          height: 54.r,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 배경 트랙
              SizedBox(
                width: 54.r,
                height: 54.r,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 5.r,
                  color: AppColors.divider,
                ),
              ),
              // 진행 링
              SizedBox(
                width: 54.r,
                height: 54.r,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5.r,
                  strokeCap: StrokeCap.round,
                  color: isAvailable
                      ? AppColors.success
                      : AppColors.warning,
                  backgroundColor: Colors.transparent,
                ),
              ),
              // 체크 아이콘 (가능할 때만)
              if (isAvailable)
                Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 22.r,
                ),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          isAvailable ? '체크인 가능' : _formatRemaining(remainingSeconds),
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: isAvailable ? AppColors.success : AppColors.warning,
            letterSpacing: isAvailable ? 0 : 0.4,
          ),
        ),
      ],
    );
  }

  String _formatRemaining(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
}

// ── 보상 배지 ─────────────────────────────────────────────────────────────────

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 13.r),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
