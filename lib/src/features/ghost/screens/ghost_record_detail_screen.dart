import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_map_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/ghost_providers.dart';
import 'ghost_run_screen.dart';

/// 고스트 기록 상세 (2단계) — 선택한 랭킹 기록의 코스/페이스를 보여주고
/// "고스트 런 하기"로 3단계(고스트 런 지도)로 진입.
class GhostRecordDetailScreen extends ConsumerStatefulWidget {
  const GhostRecordDetailScreen({super.key, required this.rankingId});

  final int rankingId;

  @override
  ConsumerState<GhostRecordDetailScreen> createState() =>
      _GhostRecordDetailScreenState();
}

class _GhostRecordDetailScreenState
    extends ConsumerState<GhostRecordDetailScreen> {
  GoogleMapController? _mapCtrl;

  @override
  void dispose() {
    _mapCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(ghostRankingDetailProvider(widget.rankingId));

    return Scaffold(
      backgroundColor: AppColors.dScreen,
      appBar: AppBar(
        backgroundColor: AppColors.dScreen,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.dText, size: 20.r),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          '고스트 기록',
          style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.dAccent),
        ),
        error: (e, _) => _buildError(),
        data: (detail) => _buildBody(detail),
      ),
    );
  }

  Widget _buildBody(GhostRankingDetail detail) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
            children: [
              // ── 러너 + 부문 ────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 52.r,
                    height: 52.r,
                    decoration: const BoxDecoration(
                      color: AppColors.dGoldSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.emoji_events_rounded,
                        color: AppColors.dGold, size: 28.r),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.dAccentSoft,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                '${detail.rankNo}위 · ${detail.category}',
                                style: TextStyle(
                                  color: AppColors.dAccentBright,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          detail.nickname.isEmpty
                              ? '러너 #${detail.recordId}'
                              : detail.nickname,
                          style: TextStyle(
                            color: AppColors.dText,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (detail.dong.isNotEmpty)
                          Text(
                            detail.dong,
                            style: TextStyle(
                              color: AppColors.dFaint,
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // ── 기록 통계 ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.speed_rounded,
                      label: '평균 페이스',
                      value: detail.paceText,
                      unit: '/km',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.straighten_rounded,
                      label: '거리',
                      value: detail.distanceKm.toStringAsFixed(2),
                      unit: 'km',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // ── 코스 미리보기 ──────────────────────────────────────────
              Text(
                '코스 미리보기',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.dMuted,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 10.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: SizedBox(
                  height: 260.h,
                  child: _CourseMap(
                    detail: detail,
                    onMapCreated: (c) {
                      _mapCtrl = c;
                      _fitToPath(detail);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── 고스트 런 하기 버튼 ───────────────────────────────────────────
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dAccent,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                onPressed: () => _startGhostRun(detail),
                icon: Icon(Icons.sports_score_rounded, size: 22.r, color: Colors.white),
                label: Text(
                  '고스트 런 하기',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startGhostRun(GhostRankingDetail detail) {
    // 3단계 — 고스트 런 지도 화면 진입.
    // start API(10m 검증) → 타겟/내 경로 표시 → finish API로 승패·랭킹 갱신.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GhostRunScreen(detail: detail)),
    );
  }

  Future<void> _fitToPath(GhostRankingDetail detail) async {
    final ctrl = _mapCtrl;
    if (ctrl == null || detail.path.isEmpty) return;

    if (detail.path.length == 1) {
      await ctrl.moveCamera(CameraUpdate.newLatLngZoom(
        LatLng(detail.path.first.lat, detail.path.first.lng),
        15,
      ));
      return;
    }

    double minLat = detail.path.first.lat, maxLat = detail.path.first.lat;
    double minLng = detail.path.first.lng, maxLng = detail.path.first.lng;
    for (final p in detail.path) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // newLatLngBounds는 맵이 레이아웃되어 크기를 가진 뒤에야 동작 →
    // 지연 후 시도하고, 실패(맵 크기 0 등) 시 한 번 더 재시도.
    for (var attempt = 0; attempt < 3; attempt++) {
      await Future<void>.delayed(
          Duration(milliseconds: attempt == 0 ? 350 : 400));
      if (!mounted) return;
      try {
        await ctrl.moveCamera(CameraUpdate.newLatLngBounds(bounds, 44));
        return;
      } catch (_) {
        // 재시도
      }
    }
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40.r, color: AppColors.dRouteEnd),
          SizedBox(height: 12.h),
          Text('기록을 불러오지 못했어요.',
              style: TextStyle(color: AppColors.dMuted, fontSize: 14.sp)),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () =>
                ref.invalidate(ghostRankingDetailProvider(widget.rankingId)),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

// ── 코스 지도 (path 폴리라인) ──────────────────────────────────────────────────
class _CourseMap extends StatelessWidget {
  const _CourseMap({required this.detail, required this.onMapCreated});

  final GhostRankingDetail detail;
  final void Function(GoogleMapController) onMapCreated;

  @override
  Widget build(BuildContext context) {
    final points = [
      for (final p in detail.path) LatLng(p.lat, p.lng),
    ];
    return GoogleMap(
      style: AppMapStyles.darkWarm,
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: LatLng(detail.startLat, detail.startLng),
        zoom: 15,
        tilt: 0,
      ),
      myLocationButtonEnabled: false,
      compassEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      // 정적 프리뷰 — 모든 제스처 잠금
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      zoomGesturesEnabled: false,
      scrollGesturesEnabled: false,
      polylines: {
        if (points.length >= 2)
          Polyline(
            polylineId: const PolylineId('ghost_course'),
            points: points,
            color: AppColors.dAccent,
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
      },
      markers: {
        // 출발 지점 (초록)
        Marker(
          markerId: const MarkerId('ghost_start'),
          position: LatLng(detail.startLat, detail.startLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: '출발'),
        ),
        // 도착 지점 (빨강) — 경로의 마지막 좌표
        if (detail.path.isNotEmpty)
          Marker(
            markerId: const MarkerId('ghost_end'),
            position: LatLng(detail.path.last.lat, detail.path.last.lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: '도착'),
          ),
      },
      onMapCreated: onMapCreated,
    );
  }
}

// ── 통계 카드 ───────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;

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
          Icon(icon, color: AppColors.dAccent, size: 22.r),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dText,
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.dFaint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
