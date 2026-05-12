import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/run_record_model.dart';
import '../providers/running_provider.dart';
import 'widgets/running_mock_panel.dart';
import '../../../core/constants/app_env.dart';

const _defaultCamera = NCameraPosition(
  target: NLatLng(35.2475, 129.0914),  // 구서역 1호선
  zoom: 15.0,
);

class RunningScreen extends ConsumerStatefulWidget {
  const RunningScreen({super.key});

  @override
  ConsumerState<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends ConsumerState<RunningScreen> {
  NaverMapController? _mapCtrl;
  StreamSubscription<Position>? _gpsSub;

  // Mock state
  double _mockStepMeters = 3.33;
  bool _mockAutoWalk = false;
  Timer? _mockTimer;
  Position? _mockPos;
  int _mockStep = 0;

  // Bottom panel expand
  bool _bottomExpanded = false;

  // Overlay cache
  final Map<String, NMarker> _spotMarkers = {};
  NPolylineOverlay? _pathPolyline;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _mockTimer?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Init
  // -------------------------------------------------------------------------

  Future<void> _init() async {
    final useMockGps = ref.read(useMockGpsProvider);
    await ref.read(runningProvider.notifier).initialize(useMock: useMockGps);
    if (!mounted) return;

    if (useMockGps) {
      _mockPos = _makeMockPos(lat: 35.2475, lng: 129.0914, speed: 0); // 구서역 1호선
      await ref
          .read(runningProvider.notifier)
          .onPositionUpdate(_mockPos!, isDev: true);
    } else {
      // [iOS 대응] NSLocationWhenInUseUsageDescription 추가 필요
      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((pos) async {
        if (!mounted) return;
        await ref.read(runningProvider.notifier).onPositionUpdate(pos);
        if (!mounted) return;
        await _updateCamera(pos);
      });
    }
  }

  // -------------------------------------------------------------------------
  // Mock controls
  // -------------------------------------------------------------------------

  void _toggleMockAutoWalk() {
    if (!mounted) return;
    setState(() => _mockAutoWalk = !_mockAutoWalk);
    _mockTimer?.cancel();

    if (!_mockAutoWalk) {
      final cur = _mockPos;
      if (cur != null) {
        final stopped =
            _makeMockPos(lat: cur.latitude, lng: cur.longitude, speed: 0);
        _mockPos = stopped;
        unawaited(
          ref
              .read(runningProvider.notifier)
              .onPositionUpdate(stopped, isDev: true),
        );
      }
      return;
    }

    _mockStep = 0;
    _mockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _doMockStep();
      _mockStep++;
    });
  }

  void _doMockStep() {
    double east = 0, north = 0;
    switch (_mockStep % 40) {
      case >= 0 && < 10:
        north = _mockStepMeters;
      case >= 10 && < 20:
        east = _mockStepMeters;
      case >= 20 && < 30:
        north = -_mockStepMeters;
      default:
        east = -_mockStepMeters;
    }
    _nudgeMock(eastMeters: east, northMeters: north);
  }

  void _nudgeMock({required double eastMeters, required double northMeters}) {
    if (!mounted) return;
    final cur = _mockPos;
    if (cur == null) return;

    const metersPerDegLat = 111320.0;
    final metersPerDegLng =
        111320.0 * math.cos(cur.latitude * math.pi / 180.0).abs();

    final dLat = northMeters / metersPerDegLat;
    final dLng = eastMeters / (metersPerDegLng == 0 ? 1 : metersPerDegLng);
    final speed =
        math.sqrt(math.pow(eastMeters, 2) + math.pow(northMeters, 2));

    final next = _makeMockPos(
      lat: cur.latitude + dLat,
      lng: cur.longitude + dLng,
      speed: speed,
    );
    _mockPos = next;

    unawaited(
      ref.read(runningProvider.notifier).onPositionUpdate(next, isDev: true),
    );
    unawaited(_updateCamera(next));
  }

  // -------------------------------------------------------------------------
  // Camera
  // -------------------------------------------------------------------------

  Future<void> _updateCamera(Position pos) async {
    final ctrl = _mapCtrl;
    if (ctrl == null || !mounted) return;

    final record = ref.read(runningProvider);
    final zoom = record.isRunning ? 18.0 : 15.0;
    final tilt = record.isRunning ? 45.0 : 0.0;

    final update = NCameraUpdate.fromCameraPosition(
      NCameraPosition(
        target: NLatLng(pos.latitude, pos.longitude),
        zoom: zoom,
        tilt: tilt,
      ),
    )..setAnimation(
        animation: NCameraAnimation.easing,
        duration: const Duration(milliseconds: 300),
      );

    await ctrl.updateCamera(update);
  }

  // -------------------------------------------------------------------------
  // Overlays
  // -------------------------------------------------------------------------

  void _syncOverlays(RunRecordModel record) {
    final ctrl = _mapCtrl;
    if (ctrl == null) return;

    if (record.path.length >= 2) {
      final coords = record.path.map((p) => NLatLng(p.lat, p.lng)).toList();
      final polyline = NPolylineOverlay(
        id: 'run_path',
        coords: coords,
        width: 5,
        color: AppColors.primary,
      );
      _pathPolyline = polyline;
      ctrl.addOverlay(polyline);
    }

    final newIds = record.nearbySpots.map((s) => 'spot_${s.id}').toSet();
    final oldIds = _spotMarkers.keys.toSet();

    if (newIds != oldIds || record.checkedInSpotIds.isNotEmpty) {
      ctrl.clearOverlays(type: NOverlayType.marker);
      _spotMarkers.clear();

      for (final spot in record.nearbySpots) {
        final markerId = 'spot_${spot.id}';
        final checked = record.checkedInSpotIds.contains(spot.id);
        final marker = NMarker(
          id: markerId,
          position: NLatLng(spot.latitude, spot.longitude),
          caption: NOverlayCaption(text: spot.name),
          subCaption: NOverlayCaption(
            text: checked
                ? '✅ +${spot.rewardAmount}P'
                : '+${spot.rewardAmount}P',
          ),
        );
        marker.setOnTapListener((_) {
          if (!mounted) return;
          unawaited(ref.read(runningProvider.notifier).checkInSpot(spot));
        });
        _spotMarkers[markerId] = marker;
      }
      ctrl.addOverlayAll(_spotMarkers.values.toSet());

      final poly = _pathPolyline;
      if (poly != null) ctrl.addOverlay(poly);
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Position _makeMockPos({
    required double lat,
    required double lng,
    required double speed,
  }) {
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      heading: 0.0,
      speed: speed,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
      isMocked: true,
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final record = ref.watch(runningProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _syncOverlays(record));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // ── Full-screen map ──────────────────────────────────────────────
          Positioned.fill(
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: _defaultCamera,
                locationButtonEnable: false,
                compassEnable: false,
                tiltGesturesEnable: true,
                indoorEnable: true,
                locale: const Locale('ko'),
                contentPadding: EdgeInsets.only(
                  top: topPadding,
                  bottom: 200,
                ),
              ),
              onMapReady: (ctrl) async {
                _mapCtrl = ctrl;
                await Future<void>.delayed(const Duration(milliseconds: 300));
                if (!mounted) return;
                final pos = _mockPos;
                if (pos != null) {
                  await _updateCamera(pos);
                  if (!mounted) return;
                }
                _syncOverlays(ref.read(runningProvider));
              },
              onMapTapped: (_, __) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),

          // ── Bottom panel ─────────────────────────────────────────────────
          // bottom: AppSpacing.sm 으로 네브바와 살짝 띄움
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.sm,
            child: _BottomPanel(
              record: record,
              isDev: ref.read(useMockGpsProvider),
              mockStepMeters: _mockStepMeters,
              mockAutoWalk: _mockAutoWalk,
              bottomExpanded: _bottomExpanded,
              onToggleExpand: () =>
                  setState(() => _bottomExpanded = !_bottomExpanded),
              onStart: () => ref.read(runningProvider.notifier).startRun(),
              onFinish: () => ref.read(runningProvider.notifier).finishRun(),
              onLocateMe: () async {
                final pos = _mockPos;
                if (pos != null) await _updateCamera(pos);
              },
              onChangeStep: (v) => setState(() => _mockStepMeters = v),
              onToggleAutoWalk: _toggleMockAutoWalk,
              onNudgeNorth: () =>
                  _nudgeMock(eastMeters: 0, northMeters: _mockStepMeters),
              onDismissError: () =>
                  ref.read(runningProvider.notifier).clearError(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BottomPanel
// layout: [Mock Panel (dev)] → [white card: metrics + action btn]
// ---------------------------------------------------------------------------

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.record,
    required this.isDev,
    required this.mockStepMeters,
    required this.mockAutoWalk,
    required this.bottomExpanded,
    required this.onToggleExpand,
    required this.onStart,
    required this.onFinish,
    required this.onLocateMe,
    required this.onChangeStep,
    required this.onToggleAutoWalk,
    required this.onNudgeNorth,
    required this.onDismissError,
  });

  final RunRecordModel record;
  final bool isDev;
  final double mockStepMeters;
  final bool mockAutoWalk;
  final bool bottomExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onStart;
  final VoidCallback onFinish;
  final VoidCallback onLocateMe;
  final ValueChanged<double> onChangeStep;
  final VoidCallback onToggleAutoWalk;
  final VoidCallback onNudgeNorth;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Dev: Mock panel ────────────────────────────────────────────────
        if (isDev)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: RunningMockPanel(
              stepMeters: mockStepMeters,
              isAutoWalk: mockAutoWalk,
              isBusy: false,
              onChangeStep: onChangeStep,
              onToggleAutoWalk: onToggleAutoWalk,
              onNudgeNorth: onNudgeNorth,
            ),
          ),

        SizedBox(height: 6.h),

        // ── White card (좌우 여백, 전체 모서리 둥글게) ─────────────────────
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: AppSpacing.verticalMd),

                // Error banner
                if (record.errorMessage != null)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ).copyWith(bottom: AppSpacing.sm),
                    child: _ErrorBanner(
                      message: record.errorMessage!,
                      onDismiss: onDismissError,
                    ),
                  ),

                // ── Main metrics row ──────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 거리
                      _MetricBlock(
                        label: '거리 (KM)',
                        value: (record.distanceMeters / 1000)
                            .toStringAsFixed(1),
                        labelColor: AppColors.primary,
                      ),

                      SizedBox(width: AppSpacing.lg),

                      // 페이스
                      _MetricBlock(
                        label: '페이스',
                        value: record.formattedCurrentPace,
                      ),

                      const Spacer(),

                      // 플레이/정지 버튼 + 화살표
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RunButton(
                            isRunning: record.isRunning,
                            onTap: record.isRunning ? onFinish : onStart,
                          ),
                          SizedBox(height: 4.h),
                          GestureDetector(
                            onTap: onToggleExpand,
                            child: Icon(
                              bottomExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                              size: 24.r,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── 확장: 추가 지표 ───────────────────────────────────────
                if (bottomExpanded) ...[
                  SizedBox(height: AppSpacing.verticalMd),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        _MetricBlock(
                          label: '시간',
                          value: _formatDuration(record.duration),
                          valueFontSize: 28,
                        ),
                        SizedBox(width: AppSpacing.lg),
                        _MetricBlock(
                          label: '평균 페이스',
                          value: record.formattedAveragePace,
                          valueFontSize: 28,
                        ),
                      ],
                    ),
                  ),
                ],

                // ── 스팟 포인트 배지 ──────────────────────────────────────
                if (record.spotPoints > 0) ...[
                  SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars_rounded,
                                size: 14.r, color: AppColors.primary),
                            SizedBox(width: 4.w),
                            Text(
                              '스팟 ${record.checkedInSpotIds.length}개 · +${record.spotPoints}P',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // 카드 내부 하단 여백
                SizedBox(height: AppSpacing.verticalMd),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

// ---------------------------------------------------------------------------
// _RunButton
// ---------------------------------------------------------------------------

class _RunButton extends StatelessWidget {
  const _RunButton({required this.isRunning, required this.onTap});

  final bool isRunning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isRunning ? AppColors.error : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62.r,
        height: 62.r,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 32.r,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MetricBlock
// ---------------------------------------------------------------------------

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    this.labelColor = AppColors.textSecondary,
    this.valueFontSize,
  });

  final String label;
  final String value;
  final Color labelColor;
  final double? valueFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: (valueFontSize ?? 44).sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -1.5,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _ErrorBanner
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 16.r),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, size: 16.r, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
