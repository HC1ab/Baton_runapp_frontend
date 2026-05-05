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
import 'widgets/running_action_bar.dart';
import 'widgets/running_dashboard.dart';
import 'widgets/running_mock_panel.dart';

const bool _isDev = bool.fromEnvironment('IS_DEV', defaultValue: true);

const _defaultCamera = NCameraPosition(
  target: NLatLng(37.5113, 126.9940),
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
    await ref.read(runningProvider.notifier).initialize(useMock: _isDev);

    // mounted check after every async gap before using ref or setState
    if (!mounted) return;

    if (_isDev) {
      _mockPos = _makeMockPos(lat: 37.5113, lng: 126.9940, speed: 0);
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
      ref
          .read(runningProvider.notifier)
          .onPositionUpdate(next, isDev: true),
    );
    unawaited(_updateCamera(next));
  }

  // -------------------------------------------------------------------------
  // Camera
  // -------------------------------------------------------------------------

  Future<void> _updateCamera(Position pos) async {
    final ctrl = _mapCtrl;
    if (ctrl == null) return;
    if (!mounted) return;

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

    // Path polyline (minimum 2 points required)
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

    // Spot markers — redraw only when set or check-in state changes
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

      // Re-add polyline after clearing markers
      final poly = _pathPolyline;
      if (poly != null) {
        ctrl.addOverlay(poly);
      }
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
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
                  bottom: 200 + bottomPadding,
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

          // ── Top status chip ──────────────────────────────────────────────
          Positioned(
            top: topPadding + AppSpacing.sm,
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            child: SafeArea(
              bottom: false,
              child: _StatusChip(record: record, isDev: _isDev),
            ),
          ),

          // ── Bottom sheet area ────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomArea(
              record: record,
              isDev: _isDev,
              mockStepMeters: _mockStepMeters,
              mockAutoWalk: _mockAutoWalk,
              bottomPadding: bottomPadding,
              onStart: () => ref.read(runningProvider.notifier).startRun(),
              onFinish: () => ref.read(runningProvider.notifier).finishRun(),
              onLocateMe: () async {
                final pos = _mockPos;
                if (pos != null) {
                  await _updateCamera(pos);
                }
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
// Sub-widgets
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.record, required this.isDev});

  final RunRecordModel record;
  final bool isDev;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.r,
            height: 8.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: record.isRunning
                  ? AppColors.runningActive
                  : AppColors.textSecondary,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            record.isRunning
                ? '러닝 중 · 스팟 ${record.checkedInSpotIds.length}개'
                : isDev
                    ? '개발 모드 (Mock GPS)'
                    : '주변 스팟을 확인하세요',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomArea extends StatelessWidget {
  const _BottomArea({
    required this.record,
    required this.isDev,
    required this.mockStepMeters,
    required this.mockAutoWalk,
    required this.bottomPadding,
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
  final double bottomPadding;
  final VoidCallback onStart;
  final VoidCallback onFinish;
  final VoidCallback onLocateMe;
  final ValueChanged<double> onChangeStep;
  final VoidCallback onToggleAutoWalk;
  final VoidCallback onNudgeNorth;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppSpacing.sm),

          if (record.isRunning)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: RunningDashboard(record: record),
            ),

          if (record.errorMessage != null)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: _ErrorBanner(
                message: record.errorMessage!,
                onDismiss: onDismissError,
              ),
            ),

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

          SizedBox(height: AppSpacing.verticalMd),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: RunningActionBar(
              isRunning: record.isRunning,
              isBusy: false,
              onStart: onStart,
              onFinish: onFinish,
              onLocateMe: onLocateMe,
            ),
          ),

          SizedBox(height: AppSpacing.verticalMd + bottomPadding),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
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
