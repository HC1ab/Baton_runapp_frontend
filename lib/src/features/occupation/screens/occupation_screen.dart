import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_map_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/shell/tab_providers.dart';
import '../providers/occupation_providers.dart';

/// 점령 지도 — BATON(전체 점령) / 내 점령 토글 + 2D 탑다운 지도.
/// 점령된 스팟을 회색 원으로 표시하고, BATON에서 원을 누르면
/// 점령자 정보를 보여주는 미니 상세 시트가 아래에서 올라온다.
class OccupationScreen extends ConsumerStatefulWidget {
  const OccupationScreen({super.key});

  @override
  ConsumerState<OccupationScreen> createState() => _OccupationScreenState();
}

class _OccupationScreenState extends ConsumerState<OccupationScreen> {
  // 부산 일대 — 데이터 없을 때 기본 시점
  static const _defaultTarget = LatLng(35.2475, 129.0914);
  static const _defaultZoom = 13.5;

  GoogleMapController? _mapCtrl;

  /// 현재 지도 인스턴스에 대해 초기 카메라 위치를 잡았는지
  bool _cameraPositioned = false;

  /// 탭 활성화 후 레이아웃이 안정된 다음 프레임에 지도를 삽입하기 위한 플래그.
  /// 활성화되는 그 프레임에 지도를 만들면 안드로이드 플랫폼 뷰가 잘못된 초기 크기로
  /// 잡혀 상단 일부만 렌더되고 나머지가 검게 남는 문제를 방지한다.
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    // 점령 탭을 떠나면 GoogleMap 서브트리가 해제되며 컨트롤러가 무효화되므로
    // 참조를 비워 두었다가 재진입 시 다시 안정화 후 삽입한다.
    ref.listenManual<int>(currentTabProvider, (prev, next) {
      if (next != AppTabs.occupation) {
        _mapCtrl = null;
        _cameraPositioned = false;
        if (mounted && _showMap) setState(() => _showMap = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack에서 비활성(offstage) 상태로 GoogleMap platform view가
    // 초기화되면 안드로이드에서 지도가 검게 렌더되는 문제가 있어,
    // 점령 탭이 실제로 선택됐을 때만 지도를 빌드한다.
    final isActive = ref.watch(currentTabProvider) == AppTabs.occupation;
    if (!isActive) {
      return const ColoredBox(color: AppColors.dScreen);
    }

    // 활성화 직후 한 프레임은 지도를 빼고 Scaffold를 전체 크기로 먼저 배치 →
    // 다음 프레임에 _showMap=true로 안정된 레이아웃에 지도를 삽입.
    if (!_showMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showMap = true);
      });
    }

    final mode = ref.watch(occupationModeProvider);
    final spotsAsync = ref.watch(occupiedSpotsProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    final spots = spotsAsync.value ?? const <OccupiedSpot>[];

    // 지도가 준비된 뒤 데이터가 들어오면 한 번만 결정론적으로 카메라 위치 지정
    if (_mapCtrl != null && !_cameraPositioned && spots.isNotEmpty) {
      _cameraPositioned = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _positionCamera(spots));
    }

    return Scaffold(
      backgroundColor: AppColors.dScreen,
      // SizedBox.expand: Stack이 항상 전체 화면을 차지하도록 강제.
      // (없으면 Stack이 유일한 고정 높이 자식인 상단 그라데이션 크기로 줄어
      //  지도가 상단 일부만 그려짐)
      body: SizedBox.expand(
        child: Stack(
          children: [
            // ── 2D 탑다운 지도 ──────────────────────────────────────────────
            Positioned.fill(
            child: _showMap
                ? GoogleMap(
                    style: AppMapStyles.darkWarm,
                    mapType: MapType.normal,
                    initialCameraPosition: const CameraPosition(
                      target: _defaultTarget,
                      zoom: _defaultZoom,
                      tilt: 0, // 위에서 내려다보는 2D 시점
                    ),
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false, // 2D 고정
                    circles: _buildCircles(spots),
                    onMapCreated: (ctrl) {
                      setState(() => _mapCtrl = ctrl);
                      // 지도 생성 시점에 이미 데이터가 있으면 즉시 위치 지정.
                      // (데이터가 늦게 오면 build의 후처리 콜백이 대신 처리)
                      if (spots.isNotEmpty && !_cameraPositioned) {
                        _cameraPositioned = true;
                        _positionCamera(spots);
                      }
                    },
                  )
                : const ColoredBox(color: AppColors.dScreen),
          ),

          // ── 상단 비네트 (토글 가독성) ─────────────────────────────────────
          IgnorePointer(
            child: Container(
              height: topPadding + 120.h,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC141416), Color(0x00141416)],
                ),
              ),
            ),
          ),

          // ── 상단 토글 (BATON / 내 점령) ───────────────────────────────────
          Positioned(
            top: topPadding + 12.h,
            left: 0,
            right: 0,
            child: Center(
              child: _ModeToggle(
                mode: mode,
                onChanged: (m) =>
                    ref.read(occupationModeProvider.notifier).set(m),
              ),
            ),
          ),

          // ── 상태 오버레이 (로딩 / 에러 / 빈 목록) ──────────────────────────
          if (spotsAsync.isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.dAccent),
            )
          else if (spotsAsync.hasError)
            _StatusCard(
              icon: Icons.cloud_off_rounded,
              title: '점령 정보를 불러오지 못했어요',
              subtitle: '잠시 후 다시 시도해 주세요',
              onRetry: () => ref.invalidate(
                mode == OccupationMode.all
                    ? allOccupiedSpotsProvider
                    : myOccupiedSpotsProvider,
              ),
            )
          else if (spots.isEmpty)
            _StatusCard(
              icon: mode == OccupationMode.all
                  ? Icons.flag_outlined
                  : Icons.outlined_flag_rounded,
              title: mode == OccupationMode.all
                  ? '아직 점령된 스팟이 없어요'
                  : '아직 점령한 스팟이 없어요',
              subtitle: mode == OccupationMode.all
                  ? '가장 먼저 스팟을 점령해 보세요!'
                  : '러닝으로 스팟을 점령해 보세요!',
            ),
          ],
        ),
      ),
    );
  }

  // ── 회색 원 마커 ────────────────────────────────────────────────────────
  Set<Circle> _buildCircles(List<OccupiedSpot> spots) {
    return spots.map((s) {
      return Circle(
        circleId: CircleId('occupied_${s.spotId}'),
        center: LatLng(s.latitude, s.longitude),
        radius: 120, // meters — 점령 영역 느낌
        fillColor: AppColors.spotNeutral.withValues(alpha: 0.28),
        strokeColor: AppColors.spotNeutral.withValues(alpha: 0.85),
        strokeWidth: 2,
        consumeTapEvents: true,
        onTap: () => _showDetailSheet(s),
      );
    }).toSet();
  }

  // ── 카메라 위치 지정 (결정론적) ──────────────────────────────────────────
  /// 스팟들의 중심점 + 간격(span)에서 직접 계산한 줌으로 카메라를 1회 이동.
  /// newLatLngBounds(뷰포트·타이밍 의존)와 달리 같은 데이터면 항상 동일한 화면이
  /// 나오고, 한곳에 뭉친 스팟에서 과하게 확대되는 것도 방지(줌 상한 클램프).
  Future<void> _positionCamera(List<OccupiedSpot> spots) async {
    final ctrl = _mapCtrl;
    if (ctrl == null || spots.isEmpty) return;

    double minLat = spots.first.latitude, maxLat = spots.first.latitude;
    double minLng = spots.first.longitude, maxLng = spots.first.longitude;
    for (final s in spots) {
      minLat = math.min(minLat, s.latitude);
      maxLat = math.max(maxLat, s.latitude);
      minLng = math.min(minLng, s.longitude);
      maxLng = math.max(maxLng, s.longitude);
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final span = math.max(maxLat - minLat, maxLng - minLng);

    // span(도 단위)에서 줌 계산. 여유(×1.6)를 둬 스팟이 가장자리에 붙지 않게 함.
    // 클램프: 12.0(넓게) ~ 15.0(뭉친 스팟도 과확대 방지).
    final double zoom = span < 0.0008
        ? 15.0
        : (math.log(360 / (span * 1.6)) / math.ln2).clamp(12.0, 15.0);

    await ctrl.moveCamera(CameraUpdate.newLatLngZoom(center, zoom));
  }

  // ── 미니 상세 시트 ──────────────────────────────────────────────────────
  void _showDetailSheet(OccupiedSpot spot) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _OccupierDetailSheet(spot: spot),
    );
  }
}

// ── 토글 (BATON / 내 점령) ────────────────────────────────────────────────────
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final OccupationMode mode;
  final ValueChanged<OccupationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.r),
      decoration: BoxDecoration(
        color: const Color(0xF21E1E21), // 불투명 다크 펄
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.dLine2, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment('BATON', OccupationMode.all),
          _segment('내 점령', OccupationMode.mine),
        ],
      ),
    );
  }

  Widget _segment(String label, OccupationMode value) {
    final selected = mode == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.dAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.dMuted,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ── 점령자 미니 상세 시트 ──────────────────────────────────────────────────────
class _OccupierDetailSheet extends StatelessWidget {
  const _OccupierDetailSheet({required this.spot});

  final OccupiedSpot spot;

  @override
  Widget build(BuildContext context) {
    final occupiedAt = spot.occupiedAt;

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

            // 점령자 + 점령 시간
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: const BoxDecoration(
                    color: AppColors.dCard2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.dMuted,
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '점령자',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dFaint,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        spot.occupierNickname.isEmpty
                            ? '멤버 #${spot.occupierMemberId}'
                            : spot.occupierNickname,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                // 오른쪽: 점령된 시간
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '점령 시각',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dFaint,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      occupiedAt == null
                          ? '—'
                          : DateFormat('M월 d일').format(occupiedAt),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dText,
                      ),
                    ),
                    if (occupiedAt != null) ...[
                      SizedBox(height: 1.h),
                      Text(
                        DateFormat('HH:mm').format(occupiedAt),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.dMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            SizedBox(height: 18.h),
            Divider(color: AppColors.dLine2, height: 1),
            SizedBox(height: 16.h),

            // 스팟 이름
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    color: AppColors.dAccentBright, size: 20.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    spot.name.isEmpty ? '이름 없는 스팟' : spot.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 상태 카드 (로딩/에러/빈 목록 오버레이) ────────────────────────────────────
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 40.w),
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 28.h),
        decoration: BoxDecoration(
          color: const Color(0xF21E1E21),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.dLine2, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46.r, color: AppColors.dAccent.withValues(alpha: 0.5)),
            SizedBox(height: 16.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.dText,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.dMuted,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 18.h),
              TextButton(
                onPressed: onRetry,
                child: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
