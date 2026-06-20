import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_map_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/shell/tab_providers.dart';
import '../../profile/services/member_profile_service.dart';
import '../../spot/providers/spot_providers.dart';
import '../providers/occupation_providers.dart';

/// 점령 지도 — 차지(전체 점령) / 내 점령 토글 + 2D 탑다운 지도.
/// 점령된 스팟을 회색 원으로 표시하고, 차지에서 원을 누르면
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
  bool _showMap = false;

  /// 스팟 쿨다운 카운트다운용 타이머
  Timer? _spotTicker;

  @override
  void initState() {
    super.initState();
    _spotTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    ref.listenManual<int>(currentTabProvider, (prev, next) {
      if (next != AppTabs.occupation) {
        _mapCtrl = null;
        _cameraPositioned = false;
        if (mounted && _showMap) setState(() => _showMap = false);
      }
    });
    // 토글(차지/내 점령) 전환 시 해당 모드 데이터에 맞춰 카메라를 다시 잡도록.
    ref.listenManual<OccupationMode>(occupationModeProvider, (prev, next) {
      _cameraPositioned = false;
    });
  }

  @override
  void dispose() {
    _spotTicker?.cancel();
    super.dispose();
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
    final topPadding = MediaQuery.of(context).padding.top;

    // 스팟 모드 — 지도 없이 스팟 목록만 표시
    if (mode == OccupationMode.spot) {
      return Scaffold(
        backgroundColor: AppColors.dScreen,
        body: _SpotModeBody(
          topPadding: topPadding,
          mode: mode,
          onModeChanged: (m) =>
              ref.read(occupationModeProvider.notifier).set(m),
        ),
      );
    }

    final spotsAsync = ref.watch(occupiedSpotsProvider);
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
                    // 차지(전체 점령) 화면은 줌을 고정 — 축소/확대 제한
                    zoomGesturesEnabled: mode != OccupationMode.all,
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

          // ── 상단 토글 (차지 / 내 점령) ───────────────────────────────────
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

// ── 토글 (차지 / 내 점령) ────────────────────────────────────────────────────
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
          _segment('차지', OccupationMode.all),
          _segment('내 점령', OccupationMode.mine),
          _segment('스팟', OccupationMode.spot),
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
class _OccupierDetailSheet extends ConsumerWidget {
  const _OccupierDetailSheet({required this.spot});

  final OccupiedSpot spot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occupiedAt = spot.occupiedAt;
    // 점령자/내 체크인 횟수는 스팟 상세, 점령자 레벨은 공개 프로필에서 가져옴
    final detail = ref.watch(spotDetailProvider(spot.spotId)).value;
    final occupierCheckins = detail?.occupierCheckinCount ?? 0;
    final myCheckins = detail?.myCheckinCount ?? 0;
    final profile =
        ref.watch(memberPublicProfileProvider(spot.occupierMemberId)).value;
    final level = profile?.level;
    final nickname = spot.occupierNickname.isNotEmpty
        ? spot.occupierNickname
        : (profile?.nickname ?? '멤버 #${spot.occupierMemberId}');

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

            // ── 스팟 이름 (작은 헤더) ──────────────────────────────────
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    color: AppColors.dAccentBright, size: 18.r),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    spot.name.isEmpty ? '이름 없는 스팟' : spot.name,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: 14.h),

            // ── 점령자 강조 카드 ───────────────────────────────────────
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.dCard2,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: AppColors.dGold.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52.r,
                    height: 52.r,
                    decoration: const BoxDecoration(
                      color: AppColors.dGoldSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.dGold,
                      size: 28.r,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '현재 점령자',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dFaint,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          nickname,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (level != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            'Lv.$level',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dFaint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // 점령자 체크인 — 골드 배지로 강조
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.dGold,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      '체크인 $occupierCheckins회',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A0E06),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // ── 내 체크인 + 점령 시각 (작게, 구분) ─────────────────────
            Row(
              children: [
                Icon(Icons.how_to_reg_rounded,
                    color: AppColors.dMuted, size: 15.r),
                SizedBox(width: 5.w),
                Text(
                  '내 체크인 $myCheckins회',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dMuted,
                  ),
                ),
                const Spacer(),
                Icon(Icons.schedule_rounded, color: AppColors.dFaint, size: 14.r),
                SizedBox(width: 4.w),
                Text(
                  occupiedAt == null
                      ? '점령 시각 —'
                      : '${DateFormat('M월 d일').format(occupiedAt)} '
                          '${DateFormat('HH:mm').format(occupiedAt)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dFaint,
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

// ── 스팟 모드 바디 ─────────────────────────────────────────────────────────────

class _SpotModeBody extends ConsumerWidget {
  const _SpotModeBody({
    required this.topPadding,
    required this.mode,
    required this.onModeChanged,
  });

  final double topPadding;
  final OccupationMode mode;
  final ValueChanged<OccupationMode> onModeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotsAsync = ref.watch(spotCooldownsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 헤더 + 토글 ────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(22.w, topPadding + 8.h, 22.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '스팟',
                style: TextStyle(
                  color: AppColors.dAccent,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                '내가 방문한 스팟',
                style: TextStyle(
                  color: AppColors.dText,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 16.h),
              Center(
                child: _ModeToggle(mode: mode, onChanged: onModeChanged),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        // ── 목록 ────────────────────────────────────────────────────────────
        Expanded(
          child: spotsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.dAccent),
            ),
            error: (_, _) => Center(
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
                    onPressed: () => ref.invalidate(spotCooldownsProvider),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
            data: (spots) => RefreshIndicator(
              color: AppColors.dAccent,
              backgroundColor: AppColors.dCard,
              onRefresh: () async => ref.invalidate(spotCooldownsProvider),
              child: spots.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: Center(
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
                                  '아직 방문한 스팟이 없어요',
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
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(22.w, 0, 22.w, 110.h),
                      itemCount: spots.length,
                      separatorBuilder: (_, _) => SizedBox(height: 12.h),
                      itemBuilder: (_, i) => _SpotCard(spot: spots[i]),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 스팟 카드 ─────────────────────────────────────────────────────────────────

class _SpotCard extends StatelessWidget {
  const _SpotCard({required this.spot});
  final SpotCooldownModel spot;

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
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.spotName,
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
                          '마지막 방문 · ${DateFormat('yyyy.MM.dd').format(spot.lastCheckinAt)}',
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
                _CooldownRing(
                  progress: spot.cooldownProgress,
                  isAvailable: isAvailable,
                  remainingSeconds: spot.liveRemainingSeconds,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _RewardBadge(
                  icon: Icons.bolt_rounded,
                  label: '+${spot.expAmount} EXP',
                  dim: spot.expAmount <= 0,
                  isGold: false,
                ),
                SizedBox(width: 8.w),
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
