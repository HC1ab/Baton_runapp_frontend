import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
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
    final spotsAsync = ref.watch(spotListProvider);

    return Scaffold(
      backgroundColor: AppColors.dScreen,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 ────────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(22.w, topPadding + 8.h, 22.w, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SPOT',
                  style: TextStyle(
                    color: AppColors.dAccent,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '주변 체크인 스팟',
                  style: TextStyle(
                    color: AppColors.dText,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
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
                child: CircularProgressIndicator(color: AppColors.dAccent),
              ),
              error: (e, _) => e is LocationPermissionException
                  ? _buildPermissionGuide()
                  : _buildError(),
              data: (spots) => RefreshIndicator(
                color: AppColors.dAccent,
                backgroundColor: AppColors.dCard,
                onRefresh: () async => ref.invalidate(spotListProvider),
                child: spots.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: _buildEmpty(),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(22.w, 0, 22.w, 110.h),
                        itemCount: spots.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (_, i) => _SpotCard(spot: spots[i]),
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
            color: AppColors.dAccent.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            '주변에 스팟이 없어요',
            style: TextStyle(
              color: AppColors.dText,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '러닝 중 스팟 근처를 지나면\n자동으로 체크인돼요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.dMuted,
              fontSize: 14.sp,
              height: 1.45,
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
          Icon(Icons.error_outline_rounded,
              size: 40.r, color: AppColors.dRouteEnd),
          SizedBox(height: 12.h),
          Text(
            '목록을 불러오지 못했어요.',
            style: TextStyle(color: AppColors.dMuted, fontSize: 14.sp),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => ref.invalidate(spotListProvider),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionGuide() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 52.r,
              color: AppColors.dAccent.withValues(alpha: 0.4),
            ),
            SizedBox(height: 16.h),
            Text(
              '위치 권한이 필요해요',
              style: TextStyle(
                color: AppColors.dText,
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '주변 스팟을 찾으려면\n위치 권한을 켜주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.dMuted,
                fontSize: 14.sp,
                height: 1.45,
              ),
            ),
            SizedBox(height: 20.h),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.dAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              onPressed: _requestLocationPermission,
              child: Text(
                '위치 권한 허용',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    // 영구 거부 상태면 시스템 설정 화면을 열어 직접 허용하도록 안내
    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
    if (!mounted) return;
    ref.invalidate(spotListProvider);
  }
}

// ── 카드 ──────────────────────────────────────────────────────────────────────

class _SpotCard extends StatelessWidget {
  const _SpotCard({required this.spot});
  final SpotListItem spot;

  @override
  Widget build(BuildContext context) {
    final isAvailable = spot.isAvailable;

    return InkWell(
      borderRadius: BorderRadius.circular(22.r),
      onTap: () => context.push('${AppRoutes.spotDetail}/${spot.spotId}'),
      child: Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.dCard,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.dLine, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 스팟 아이콘 — 체크인 가능: 주황(primary), 쿨타임 중: 회색(spotNeutral)
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppColors.primary
                      : AppColors.spotNeutral.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: isAvailable ? Colors.white : AppColors.spotNeutral,
                  size: 22.r,
                ),
              ),
              SizedBox(width: 12.w),

              // 스팟 이름 + 방문일
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.name,
                        style: TextStyle(
                          fontSize: 15.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dText,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        spot.visited && spot.lastCheckinAt != null
                            ? '마지막 방문 · ${_formatDate(spot.lastCheckinAt!)}'
                            : '주변 스팟 · 미방문',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: AppColors.dFaint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // 쿨타임 원형 인디케이터
              _CooldownRing(
                progress: spot.cooldownProgress,
                isAvailable: isAvailable,
                remainingSeconds: spot.liveRemainingSeconds,
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // EXP / 포인트 배지 (우측 정렬)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (spot.expAmount != null) ...[
                _RewardBadge(
                  icon: Icons.bolt_rounded,
                  label: '+${spot.expAmount} EXP',
                  dim: spot.expAmount! <= 0,
                  isGold: false,
                ),
                SizedBox(width: 8.w),
              ],
              _RewardBadge(
                icon: Icons.monetization_on_rounded,
                label: '${spot.rewardAmount} P',
                dim: false,
                isGold: true,
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => DateFormat('yyyy.MM.dd').format(dt);
}

// ── 쿨타임 원형 인디케이터 ─────────────────────────────────────────────────────

class _CooldownRing extends StatelessWidget {
  const _CooldownRing({
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
          width: 44.r,
          height: 44.r,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 44.r,
                height: 44.r,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 3.r,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              SizedBox(
                width: 44.r,
                height: 44.r,
                child: CircularProgressIndicator(
                  value: isAvailable ? 1.0 : progress,
                  strokeWidth: 3.r,
                  strokeCap: StrokeCap.round,
                  color: AppColors.dAccent,
                  backgroundColor: Colors.transparent,
                ),
              ),
              if (isAvailable)
                Icon(Icons.check_rounded, color: AppColors.dAccent, size: 18.r),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          isAvailable ? '체크인 가능' : _formatRemaining(remainingSeconds),
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.dAccent,
            letterSpacing: isAvailable ? 0 : 0.4,
            fontFeatures: const [FontFeature.tabularFigures()],
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
    required this.dim,
    required this.isGold,
  });

  final IconData icon;
  final String label;
  final bool dim;
  final bool isGold;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (dim) {
      bg = Colors.white.withValues(alpha: 0.05);
      fg = AppColors.dMuted;
    } else if (isGold) {
      bg = AppColors.dGoldSoft;
      fg = AppColors.dGold;
    } else {
      bg = AppColors.dAccentSoft;
      fg = AppColors.dAccentBright;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 13.r),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
