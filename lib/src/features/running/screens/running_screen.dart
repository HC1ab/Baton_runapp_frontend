import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';

import '../../../core/character/character_provider.dart';
import '../../../core/character/character_style.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/shell/tab_providers.dart' show GroupJoinRequest, pendingGroupJoinProvider;
import '../services/glb_sphere_renderer.dart';
import '../../group_running/providers/run_location_provider.dart';
import '../../group_running/services/group_run_api_service.dart';
import '../../group_running/widgets/participant_marker_builder.dart';
import '../models/run_path_point_model.dart';
import '../models/lap_record_model.dart';
import '../models/run_record_model.dart';
import '../models/spot_model.dart';
import '../providers/running_provider.dart';
import '../widgets/character_shadow_overlay.dart';
import '../widgets/character_sphere_overlay.dart';
import '../widgets/countdown_overlay.dart';
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
  const RunningScreen({
    super.key,
    this.groupId,
    this.isHost = false,
  });

  /// null = solo run, non-null = group run mode
  final int? groupId;
  final bool isHost;

  @override
  ConsumerState<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends ConsumerState<RunningScreen> {
  GoogleMapController? _mapCtrl;
  StreamSubscription<Position>? _gpsSub;
  StreamSubscription<CompassEvent>? _compassSub;
  double? _currentHeading; // 기기 나침반 heading (null = 미수신)

  // Mock state
  double _mockStepMeters = 3.33;
  bool _mockAutoWalk = false;
  Timer? _mockTimer;
  Position? _mockPos;
  double _mockHeading = 0.0; // 0° = 북, 시계방향

  // Bottom panel expand
  bool _bottomExpanded = false;

  // 카운트다운
  bool _isCountingDown = false;

  // 활성 그룹 런 정보 — widget param(push) 또는 pendingGroupJoin(탭) 경유 모두 저장
  int? _activeGroupId;
  bool _activeIsHost = false;

  // 마커 아이콘 캐시 — initState에서 한 번만 생성
  BitmapDescriptor? _iconDefault;
  BitmapDescriptor? _iconChecked;
  BytesMapBitmap? _iconCharacter;

  // 현재 위치 (mock + 실 GPS 공통)
  LatLng? _myLatLng;

  // 그룹 참가자 마커 캐시
  final Map<int, Marker> _participantMarkers = {};
  final Map<int, BytesMapBitmap?> _participantBitmapCache = {};

  // AppLifecycle — 호스트 방 삭제용
  AppLifecycleListener? _lifecycleListener;

  // GroundOverlay 캐시 — 위치 변경 시만 재생성
  // Set도 캐시: 클럭 틱마다 동일 참조 반환 → GoogleMap.didUpdateWidget에서 변경 없음 판정
  bool _isMapReadyForOverlays = false;
  GroundOverlay? _cachedGroundOverlay;
  LatLng? _cachedGroundOverlayPos;
  double? _cachedGroundOverlayBearing;
  Set<GroundOverlay> _cachedGroundOverlaySet = const {};

  // Marker/Circle/Polyline 캐시 — 소스 데이터 identity 변경 시만 재계산
  // (클럭 틱은 duration만 바꾸므로 nearbySpots/checkedInSpotIds/path ref 불변 → 재계산 없음)
  Set<Marker> _cachedMarkers = {};
  Set<Circle> _cachedCircles = {};
  Set<Polyline> _cachedPolylines = {};
  List<SpotSummary>? _prevNearbySpots;
  Set<int>? _prevCheckedInIds;
  List<RunPathPoint>? _prevPath;
  Color? _prevTrailColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _compassSub?.cancel();
    _mockTimer?.cancel();
    _mapCtrl?.dispose();
    _lifecycleListener?.dispose();
    // 그룹 러닝 STOMP 연결 해제 (widget param 또는 provider 경유 진입 모두 대응)
    final hasGroup = widget.groupId != null ||
        ref.read(runLocationProvider).groupId != null;
    if (hasGroup) {
      unawaited(ref.read(runLocationProvider.notifier).leaveRoom());
    }
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

    final style = ref.read(selectedCharacterStyleProvider);
    _iconCharacter = await _buildCharacterSphereBitmap(style.baseColor);
  }

  /// GLB 구체 메시를 baseColor로 flat 렌더링한 비트맵.
  Future<BytesMapBitmap?> _buildCharacterSphereBitmap(Color baseColor) async {
    try {
      final dpr =
          WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
      final bytes = await GlbSphereRenderer.render(
        baseColor: baseColor,
        logicalSize: 96.0,
        devicePixelRatio: dpr,
      );
      if (bytes == null) return null;
      return BytesMapBitmap(bytes, bitmapScaling: MapBitmapScaling.none);
    } catch (e) {
      _logger.w('Character sphere bitmap build failed', error: e);
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Group run helpers
  // -------------------------------------------------------------------------

  void _registerLifecycleListener(int groupId, {required bool isHost}) {
    if (!isHost) return;
    _lifecycleListener?.dispose();
    _lifecycleListener = AppLifecycleListener(
      onPause: () => _bestEffortDeleteGroup(groupId),
      onDetach: () => _bestEffortDeleteGroup(groupId),
    );
  }

  void _bestEffortDeleteGroup(int groupId) {
    // 러닝 중일 때만 — 정상 종료 후에는 방이 이미 없음
    if (!ref.read(runningProvider).isRunning) return;
    ref.read(groupRunApiServiceProvider).deleteGroup(groupId);
  }

  /// SESSION_ENDED 수신 (호스트 종료 브로드캐스트) → 참가자 자동 종료
  void _onSessionEnded() {
    if (!mounted) return;
    _logger.i('SESSION_ENDED → auto finishRun');
    ref.read(runningProvider.notifier).finishRun();
  }

  /// 그룹 참가자 마커 빌드 — 위치 변경 시 호출
  Future<void> _updateParticipantMarkers(RunLocationState locState) async {
    final newMarkers = <int, Marker>{};

    for (final entry in locState.participants.entries) {
      final p = entry.value;
      final markerId = entry.key;

      // 비트맵 캐시 미스 시 생성
      if (!_participantBitmapCache.containsKey(markerId)) {
        _participantBitmapCache[markerId] = await buildParticipantMarkerBitmap(
          nickname: p.nickname,
          titleName: null, // API에 칭호 없음 — 추후 확장
        );
        if (!mounted) return;
      }

      final bitmap = _participantBitmapCache[markerId];
      newMarkers[markerId] = Marker(
        markerId: MarkerId('participant_$markerId'),
        position: LatLng(p.latitude, p.longitude),
        icon: bitmap ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title: p.nickname ?? '러너 $markerId',
        ),
        zIndexInt: 5,
      );
    }

    if (!mounted) return;
    setState(() {
      _participantMarkers
        ..clear()
        ..addAll(newMarkers);
    });
  }

  void _rebuildCharacterMarker(CharacterStyle style) {
    _buildCharacterSphereBitmap(style.baseColor).then((bitmap) {
      if (!mounted) return;
      setState(() => _iconCharacter = bitmap);
    });
  }

  /// 소셜 탭에서 pendingGroupJoinProvider를 통해 진입할 때 호출.
  Future<void> _joinGroupFromPending(int groupId, {required bool isHost}) async {
    _activeGroupId = groupId;
    _activeIsHost = isHost;
    await ref.read(runLocationProvider.notifier).joinRoom(
          groupId,
          onSessionEnded: _onSessionEnded,
        );
    _registerLifecycleListener(groupId, isHost: isHost);
  }

  Future<void> _init() async {
    // 그룹 러닝 — widget param 경유 진입 (레거시 push 경로)
    final groupId = widget.groupId;
    if (groupId != null) {
      _activeGroupId = groupId;
      _activeIsHost = widget.isHost;
      await ref.read(runLocationProvider.notifier).joinRoom(
            groupId,
            onSessionEnded: _onSessionEnded,
          );
      _registerLifecycleListener(groupId, isHost: widget.isHost);
    }

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

        // 기기 나침반 — heading 실시간 갱신
        // [iOS] NSMotionUsageDescription in Info.plist 필요
        _compassSub = FlutterCompass.events?.listen((event) {
          final heading = event.heading;
          if (heading == null || !mounted) return;
          // setState로 _currentHeading 갱신 → build() 재실행 → GroundOverlay bearing 즉시 반영
          setState(() => _currentHeading = heading);
          // 현재 위치 있으면 카메라 bearing 즉시 갱신 (이동 없어도 회전 반영)
          final latLng = _myLatLng;
          if (latLng != null) {
            final pos = _makeMockPos(
              lat: latLng.latitude,
              lng: latLng.longitude,
              speed: 0,
              heading: heading,
            );
            unawaited(_updateCamera(pos));
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

    _mockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _doMockStep();
    });
  }

  void _doMockStep() {
    final rad = _mockHeading * math.pi / 180;
    _nudgeMock(
      eastMeters: _mockStepMeters * math.sin(rad),
      northMeters: _mockStepMeters * math.cos(rad),
    );
  }

  void _turnLeft() {
    setState(() => _mockHeading = (_mockHeading - 45 + 360) % 360);
  }

  void _turnRight() {
    setState(() => _mockHeading = (_mockHeading + 45) % 360);
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
    // 이동 벡터로 heading 계산 (북: 0°, 동: 90°, 남: 180°, 서: 270°)
    final heading = speed > 0
        ? (math.atan2(eastMeters, northMeters) * 180 / math.pi + 360) % 360
        : 0.0;

    final next = _makeMockPos(
      lat: cur.latitude + dLat,
      lng: cur.longitude + dLng,
      speed: speed,
      heading: heading,
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
            // 나침반 값 우선, 미수신 시 GPS heading 폴백
            bearing: _currentHeading ?? pos.heading,
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

  Set<Polyline> _buildPolylines(RunRecordModel record, Color trailColor) {
    if (record.path.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('run_path'),
        points: record.path.map((p) => LatLng(p.lat, p.lng)).toList(),
        color: trailColor,
        width: 6,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  // 위치 변경 시만 GroundOverlay 재생성 (BytesMapBitmap 네이티브 재전송 방지)
  // Set 자체도 캐시 → 위치 불변 시 동일 Set 참조 반환 → GoogleMap이 변경 없음으로 판정
  Set<GroundOverlay> _buildGroundOverlays({double bearing = 0.0}) {
    final pos = _myLatLng;
    final bitmap = _iconCharacter;
    if (pos == null || bitmap == null) return const {};

    // 위치 또는 bearing 변경 시 재생성
    final bearingChanged =
        (_cachedGroundOverlayBearing ?? -1).toInt() != bearing.toInt();
    if (_cachedGroundOverlayPos != pos || bearingChanged) {
      _cachedGroundOverlayPos = pos;
      _cachedGroundOverlayBearing = bearing;
      _cachedGroundOverlay = GroundOverlay.fromPosition(
        groundOverlayId: const GroundOverlayId('my_character'),
        image: bitmap,
        position: pos,
        width: 16,
        zoomLevel: _defaultZoom,
        bearing: bearing,
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
    double heading = 0.0,
  }) {
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      heading: heading,
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
    final characterStyle = ref.watch(selectedCharacterStyleProvider);
    final topPadding = MediaQuery.of(context).padding.top;
    final mapHeight = MediaQuery.of(context).size.height;

    // 스타일 변경 시 맵 마커 재생성 (async)
    ref.listen(selectedCharacterStyleProvider, (prev, next) {
      if (prev?.code != next.code) {
        _rebuildCharacterMarker(next);
      }
    });

    // 소셜 탭에서 pendingGroupJoinProvider로 진입 시 그룹 연결 시작
    ref.listen<GroupJoinRequest?>(
      pendingGroupJoinProvider,
      (_, next) {
        if (next == null) return;
        ref.read(pendingGroupJoinProvider.notifier).clear();
        unawaited(_joinGroupFromPending(next.groupId, isHost: next.isHost));
      },
    );

    // 그룹 러닝 — 참가자 위치 변경 시 마커 갱신
    final activeGroupId =
        widget.groupId ?? ref.watch(runLocationProvider).groupId;
    if (activeGroupId != null) {
      ref.listen<RunLocationState>(runLocationProvider, (prev, next) {
        if (prev?.participants != next.participants) {
          unawaited(_updateParticipantMarkers(next));
        }
      });
    }

    // identical() 체크 — 소스 ref 바뀔 때만 재계산
    // copyWith(duration:...) 는 nearbySpots/checkedInSpotIds/path ref 유지 → 클럭 틱에서 재계산 없음
    if (!identical(_prevNearbySpots, record.nearbySpots) ||
        !identical(_prevCheckedInIds, record.checkedInSpotIds)) {
      _prevNearbySpots = record.nearbySpots;
      _prevCheckedInIds = record.checkedInSpotIds;
      _cachedMarkers = _buildSpotMarkers(record);
      _cachedCircles = _buildSpotCircles(record);
    }
    if (!identical(_prevPath, record.path) ||
        _prevTrailColor != characterStyle.baseColor) {
      _prevPath = record.path;
      _prevTrailColor = characterStyle.baseColor;
      _cachedPolylines = _buildPolylines(record, characterStyle.baseColor);
    }
    final groundOverlays = _isMapReadyForOverlays
        ? _buildGroundOverlays(bearing: _currentHeading ?? 0.0)
        : const <GroundOverlay>{};

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
              // 맵 영역 기준 10% 패딩 → 카메라 중심 위로 이동 → 캐릭터 하단 10% 위치
              // 구글 로고도 함께 위로 이동해 BottomPanel 뒤로 자연스럽게 숨겨짐
              // top 패딩 → 카메라 중심 아래로 이동 → 캐릭터 하단 10% 위치
              // 구글 로고는 bottom 기준 유지되므로 BottomPanel과 함께 자연스럽게 가려짐
              padding: EdgeInsets.only(top: mapHeight * 0.3),
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              buildingsEnabled: true,
              fortyFiveDegreeImageryEnabled: true,
              markers: {
                ..._cachedMarkers,
                ..._participantMarkers.values,
              },
              circles: _cachedCircles,
              polylines: _cachedPolylines,
              groundOverlays: groundOverlays,
              onMapCreated: (ctrl) async {
                _mapCtrl = ctrl;
                if (!mounted) return;
                final pos = _mockPos;
                if (pos != null) await _updateCamera(pos);
                await Future<void>.delayed(const Duration(milliseconds: 300));
                if (!mounted) return;
                setState(() => _isMapReadyForOverlays = true);
              },
              onTap: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),

          // ── 그림자 오버레이 (화면 좌표계 — bearing/tilt 무관) ─────────────
          if (_mapCtrl != null && _myLatLng != null)
            CharacterShadowOverlay(
              latLng: _myLatLng,
              mapController: _mapCtrl!,
            ),

          // ── 구체 오버레이 (그림자 기준점 위) ─────────────────────────────
          if (_mapCtrl != null && _myLatLng != null)
            CharacterSphereOverlay(
              latLng: _myLatLng,
              mapController: _mapCtrl!,
              characterStyle: characterStyle,
              titleName: ref.watch(myEquippedTitleNameProvider),
            ),

          // ── Mock 방향 조작 버튼 (autoWalk 중에만 표시) ───────────────────
          if (_mockAutoWalk && ref.read(useMockGpsProvider)) ...[
            Positioned(
              left: 16.w,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.center,
                child: _TurnButton(
                  icon: Icons.turn_left_rounded,
                  onTap: _turnLeft,
                ),
              ),
            ),
            Positioned(
              right: 16.w,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.center,
                child: _TurnButton(
                  icon: Icons.turn_right_rounded,
                  onTap: _turnRight,
                ),
              ),
            ),
          ],

          // ── 체크인 결과 카드 ──────────────────────────────────────────────
          if (record.lastCheckIn != null)
            Positioned(
              top: topPadding + 16.h,
              left: 0,
              right: 0,
              child: CheckInResultCard(result: record.lastCheckIn!),
            ),

          // ── Mock 패널 (개발자용 — 상단 고정) ──────────────────────────────
          if (ref.read(useMockGpsProvider))
            Positioned(
              top: topPadding + 8.h,
              left: AppSpacing.screenHorizontal,
              right: AppSpacing.screenHorizontal,
              child: RunningMockPanel(
                stepMeters: _mockStepMeters,
                isAutoWalk: _mockAutoWalk,
                isBusy: false,
                onChangeStep: (v) => setState(() => _mockStepMeters = v),
                onToggleAutoWalk: _toggleMockAutoWalk,
                onNudge: () {
                  final rad = _mockHeading * math.pi / 180;
                  _nudgeMock(
                    eastMeters: _mockStepMeters * math.sin(rad),
                    northMeters: _mockStepMeters * math.cos(rad),
                  );
                },
              ),
            ),

          // ── Bottom panel ──────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 70.h + AppSpacing.sm - 40.h,
            child: _BottomPanel(
              record: record,
              isDev: ref.read(useMockGpsProvider),
              mockStepMeters: _mockStepMeters,
              mockAutoWalk: _mockAutoWalk,
              bottomExpanded: _bottomExpanded,
              onToggleExpand: () =>
                  setState(() => _bottomExpanded = !_bottomExpanded),
              onStart: () => setState(() => _isCountingDown = true),
              onFinish: () => ref.read(runningProvider.notifier).finishRun(),
              onLocateMe: () async {
                final pos = _mockPos;
                if (pos != null) await _updateCamera(pos);
              },
              onChangeStep: (v) => setState(() => _mockStepMeters = v),
              onToggleAutoWalk: _toggleMockAutoWalk,
              onNudge: () {
                final rad = _mockHeading * math.pi / 180;
                _nudgeMock(
                  eastMeters: _mockStepMeters * math.sin(rad),
                  northMeters: _mockStepMeters * math.cos(rad),
                );
              },
              onDismissError: () =>
                  ref.read(runningProvider.notifier).clearError(),
            ),
          ),

          // ── 카운트다운 오버레이 ────────────────────────────────────────────
          if (_isCountingDown)
            CountdownOverlay(
              onComplete: () {
                setState(() => _isCountingDown = false);
                ref.read(runningProvider.notifier).startRun(
                      groupId: _activeGroupId,
                      isHost: _activeIsHost,
                    );
              },
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
    required this.onNudge,
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
  final VoidCallback onNudge;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (record.errorMessage != null)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ).copyWith(bottom: AppSpacing.sm),
            child: _ErrorBanner(
              message: record.errorMessage!,
              onDismiss: onDismissError,
            ),
          ),

        if (!record.isRunning)
          Center(child: _RunButton(isRunning: false, onTap: onStart))
        else
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
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

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _MetricBlock(
                          label: '거리 (KM)',
                          value: (record.distanceMeters / 1000)
                              .toStringAsFixed(2),
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
                        ],
                      ),
                    ),
                    if (record.laps.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.verticalMd),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '랩',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            ...record.laps.reversed.map(
                              (lap) => _LapRow(lap: lap),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _TurnButton extends StatelessWidget {
  const _TurnButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52.r,
        height: 52.r,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 26.r),
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

class _LapRow extends StatelessWidget {
  const _LapRow({required this.lap});
  final LapRecord lap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          SizedBox(
            width: 28.w,
            child: Text(
              '${lap.lapNumber}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  lap.formattedDuration,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  '1km',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            lap.formattedPace,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
