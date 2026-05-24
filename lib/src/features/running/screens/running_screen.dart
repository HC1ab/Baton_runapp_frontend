import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/run_path_point_model.dart';
import '../models/run_record_model.dart';
import '../models/spot_model.dart';
import '../providers/running_provider.dart';
import 'widgets/run_finish_card.dart';
import 'widgets/running_mock_panel.dart';
import 'widgets/check_in_result_card.dart';
import '../../../core/constants/app_env.dart';

final _logger = Logger();

// 구서역 1호선 기본 카메라 위치
const _defaultLatLng = LatLng(35.2475, 129.0914);
const _defaultZoom = 18.5;
const _defaultTilt = 45.0;

// 흰색 맵 스타일 JSON
const _whiteMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#f5f5f5"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#f5f5f5"}]},
  {"featureType": "administrative.land_parcel", "stylers": [{"visibility": "off"}]},
  {"featureType": "administrative.neighborhood", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi", "stylers": [{"visibility": "off"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]},
  {"featureType": "road.arterial", "elementType": "labels", "stylers": [{"visibility": "off"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#dadada"}]},
  {"featureType": "road.highway", "elementType": "labels", "stylers": [{"visibility": "off"}]},
  {"featureType": "road.local", "stylers": [{"visibility": "on"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#c9c9c9"}]},
  {"featureType": "water", "elementType": "labels.text", "stylers": [{"visibility": "off"}]}
]
''';

class RunningScreen extends ConsumerStatefulWidget {
  const RunningScreen({super.key});

  @override
  ConsumerState<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends ConsumerState<RunningScreen> {
  GoogleMapController? _mapCtrl;
  StreamSubscription<Position>? _gpsSub;

  // Mock state
  double _mockStepMeters = 3.33;
  bool _mockAutoWalk = false;
  Timer? _mockTimer;
  Position? _mockPos;
  int _mockStep = 0;

  // Bottom panel expand
  bool _bottomExpanded = false;

  // 마커 아이콘 캐시 — initState에서 한 번만 생성
  BitmapDescriptor? _iconDefault;
  BitmapDescriptor? _iconChecked;
  BytesMapBitmap? _iconCharacter;

  // 현재 위치 (mock + 실 GPS 공통)
  LatLng? _myLatLng;

  // GroundOverlay 캐시 — 위치 변경 시만 재생성
  // Set도 캐시: 클럭 틱마다 동일 참조 반환 → GoogleMap.didUpdateWidget에서 변경 없음 판정
  GroundOverlay? _cachedGroundOverlay;
  LatLng? _cachedGroundOverlayPos;
  Set<GroundOverlay> _cachedGroundOverlaySet = const {};

  // Marker/Circle/Polyline 캐시 — 소스 데이터 identity 변경 시만 재계산
  // (클럭 틱은 duration만 바꾸므로 nearbySpots/checkedInSpotIds/path ref 불변 → 재계산 없음)
  Set<Marker> _cachedMarkers = {};
  Set<Circle> _cachedCircles = {};
  Set<Polyline> _cachedPolylines = {};
  List<SpotSummary>? _prevNearbySpots;
  Set<int>? _prevCheckedInIds;
  List<RunPathPoint>? _prevPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _mockTimer?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Init
  // -------------------------------------------------------------------------

  Future<void> _loadMarkerIcons() async {
    try {
      _iconDefault = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/spot_default.png',
      );
      _iconChecked = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/spot_checked.png',
      );
    } catch (e) {
      _logger.w('Spot marker icons failed to load', error: e);
    }

    _iconCharacter = await _buildCircularMarker(
      'assets/images/test_charactor.png',
      logicalSize: 96,
    );
  }

  Future<BytesMapBitmap?> _buildCircularMarker(
    String assetPath, {
    required double logicalSize,
  }) async {
    try {
      final dpr =
          WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
      final px = (logicalSize * dpr).round();

      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: px,
        targetHeight: px,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 원형 클리핑
      canvas.clipPath(
        Path()..addOval(Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble())),
      );
      canvas.drawImage(image, Offset.zero, Paint()..isAntiAlias = true);

      // 브랜드 컬러 테두리
      canvas.drawCircle(
        Offset(px / 2, px / 2),
        px / 2 - 2,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = (4 * dpr),
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(px, px);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;

      // GroundOverlay는 MapBitmapScaling.none 필수
      return BytesMapBitmap(
        bytes.buffer.asUint8List(),
        bitmapScaling: MapBitmapScaling.none,
      );
    } catch (e) {
      _logger.w('Character marker build failed: $assetPath', error: e);
      return null;
    }
  }

  Future<void> _init() async {
    // 이미지 로딩 실패해도 GPS 초기화는 반드시 실행
    await _loadMarkerIcons();

    try {
      final useMockGps = ref.read(useMockGpsProvider);
      await ref.read(runningProvider.notifier).initialize(useMock: useMockGps);
      if (!mounted) return;

      if (useMockGps) {
        _mockPos = _makeMockPos(lat: 35.2475, lng: 129.0914, speed: 0);
        _myLatLng = LatLng(_mockPos!.latitude, _mockPos!.longitude);
        await ref
            .read(runningProvider.notifier)
            .onPositionUpdate(_mockPos!, isDev: true);
      } else {
        _gpsSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((pos) async {
          try {
            if (!mounted) return;
            _myLatLng = LatLng(pos.latitude, pos.longitude);
            await ref.read(runningProvider.notifier).onPositionUpdate(pos);
            if (!mounted) return;
            await _updateCamera(pos);
          } catch (e) {
            _logger.e('GPS update error', error: e);
          }
        });
      }
    } catch (e) {
      _logger.e('RunningScreen init error', error: e);
    }

    // 아이콘 로드 완료 후 화면 갱신 (setState로 rebuild 유발 → build()에서 오버레이 재계산)
    if (mounted) setState(() {});
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
    _myLatLng = LatLng(next.latitude, next.longitude);

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

    try {
      await ctrl.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: _defaultZoom,
            tilt: _defaultTilt,
          ),
        ),
      );
    } catch (e) {
      _logger.w('Camera update failed', error: e);
    }
  }

  // -------------------------------------------------------------------------
  // Overlay helpers — build()에서 동기 계산, setState 없음
  // -------------------------------------------------------------------------

  Set<Marker> _buildSpotMarkers(RunRecordModel record) {
    return {
      for (final spot in record.nearbySpots)
        Marker(
          markerId: MarkerId('spot_${spot.id}'),
          position: LatLng(spot.latitude, spot.longitude),
          icon: (record.checkedInSpotIds.contains(spot.id) || !spot.canCheckIn)
              ? (_iconChecked ?? BitmapDescriptor.defaultMarker)
              : (_iconDefault ?? BitmapDescriptor.defaultMarker),
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: spot.name,
            snippet: (record.checkedInSpotIds.contains(spot.id) || !spot.canCheckIn)
                ? '✅ +${spot.rewardAmount}P'
                : '+${spot.rewardAmount}P',
          ),
          // onTap 없음 — Marker.== 에 onTap 포함되므로 클로저 재생성 시
          // 매 build마다 "변경됨" 판정 → 20개 마커를 platform channel로 재전송 → ANR
          // 체크인은 _autoCheckIn(위치 기반)으로 처리
        ),
    };
  }

  Set<Circle> _buildSpotCircles(RunRecordModel record) {
    final result = <Circle>{};
    for (final spot in record.nearbySpots) {
      final checked =
          record.checkedInSpotIds.contains(spot.id) || !spot.canCheckIn;
      result.add(Circle(
        circleId: CircleId('circle_${spot.id}'),
        center: LatLng(spot.latitude, spot.longitude),
        radius: 30,
        fillColor: checked
            ? AppColors.primary.withValues(alpha: 0.25)
            : AppColors.spotNeutral.withValues(alpha: 0.15),
        strokeColor: checked
            ? AppColors.primary.withValues(alpha: 0.6)
            : AppColors.spotNeutral.withValues(alpha: 0.4),
        strokeWidth: checked ? 2 : 1,
      ));
    }
    return result;
  }

  Set<Polyline> _buildPolylines(RunRecordModel record) {
    if (record.path.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('run_path'),
        points: record.path.map((p) => LatLng(p.lat, p.lng)).toList(),
        color: AppColors.primary,
        width: 6,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  // 위치 변경 시만 GroundOverlay 재생성 (BytesMapBitmap 네이티브 재전송 방지)
  // Set 자체도 캐시 → 위치 불변 시 동일 Set 참조 반환 → GoogleMap이 변경 없음으로 판정
  Set<GroundOverlay> _buildGroundOverlays() {
    final pos = _myLatLng;
    final bitmap = _iconCharacter;
    if (pos == null || bitmap == null) return const {};

    if (_cachedGroundOverlayPos != pos) {
      _cachedGroundOverlayPos = pos;
      _cachedGroundOverlay = GroundOverlay.fromPosition(
        groundOverlayId: const GroundOverlayId('my_character'),
        image: bitmap,
        position: pos,
        width: 16,
        anchor: const Offset(0.5, 0.5),
        zIndex: 10,
      );
      _cachedGroundOverlaySet = {_cachedGroundOverlay!};
    }
    return _cachedGroundOverlaySet;
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

    // identical() 체크 — 소스 ref 바뀔 때만 재계산
    // copyWith(duration:...) 는 nearbySpots/checkedInSpotIds/path ref 유지 → 클럭 틱에서 재계산 없음
    if (!identical(_prevNearbySpots, record.nearbySpots) ||
        !identical(_prevCheckedInIds, record.checkedInSpotIds)) {
      _prevNearbySpots = record.nearbySpots;
      _prevCheckedInIds = record.checkedInSpotIds;
      _cachedMarkers = _buildSpotMarkers(record);
      _cachedCircles = _buildSpotCircles(record);
    }
    if (!identical(_prevPath, record.path)) {
      _prevPath = record.path;
      _cachedPolylines = _buildPolylines(record);
    }
    final groundOverlays = _buildGroundOverlays();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      resizeToAvoidBottomInset: false, // 키보드 inset이 지도 크기를 변경하지 않도록 방지
      body: Stack(
        children: [
          // ── Full-screen Google Map ────────────────────────────────────────
          Positioned.fill(
            child: GoogleMap(
              style: _whiteMapStyle,
              mapType: MapType.normal,
              initialCameraPosition: const CameraPosition(
                target: _defaultLatLng,
                zoom: _defaultZoom,
                tilt: _defaultTilt,
              ),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              tiltGesturesEnabled: true,
              buildingsEnabled: true,
              fortyFiveDegreeImageryEnabled: true,
              markers: _cachedMarkers,
              circles: _cachedCircles,
              polylines: _cachedPolylines,
              groundOverlays: groundOverlays,
              onMapCreated: (ctrl) async {
                _mapCtrl = ctrl;
                if (!mounted) return;
                final pos = _mockPos;
                if (pos != null) await _updateCamera(pos);
              },
              onTap: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),

          // ── 체크인 결과 카드 ──────────────────────────────────────────────
          if (record.lastCheckIn != null)
            Positioned(
              top: topPadding + 16.h,
              left: 0,
              right: 0,
              child: CheckInResultCard(result: record.lastCheckIn!),
            ),

          // ── Bottom panel ──────────────────────────────────────────────────
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

          // ── 러닝 종료 결과 카드 (최상위 — BottomPanel 위) ─────────────────
          if (record.status == RunStatus.finished)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => ref.read(runningProvider.notifier).resetToIdle(),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {}, // 카드 탭 시 배경 닫힘 방지
                    child: RunFinishCard(
                      record: record,
                      onConfirm: () =>
                          ref.read(runningProvider.notifier).resetToIdle(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BottomPanel
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

        if (!record.isRunning)
          Center(child: _RunButton(isRunning: false, onTap: onStart))
        else
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

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _MetricBlock(
                          label: '거리 (KM)',
                          value: (record.distanceMeters / 1000)
                              .toStringAsFixed(1),
                          labelColor: AppColors.primary,
                        ),
                        SizedBox(width: AppSpacing.lg),
                        _MetricBlock(
                          label: '페이스',
                          value: record.formattedCurrentPace,
                        ),
                        const Spacer(),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _RunButton(
                              isRunning: true,
                              onTap: onFinish,
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

                  if (bottomExpanded) ...[
                    SizedBox(height: AppSpacing.verticalMd),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: AppSpacing.md),
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

                  if (record.spotPoints > 0) ...[
                    SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull),
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
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child:
                Icon(Icons.close, size: 16.r, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
