import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_env.dart';
import '../../../core/constants/app_map_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/error/app_exception.dart';
import '../providers/ghost_providers.dart';

enum _Phase { ready, running }

/// 고스트 런 (3단계).
/// 1) 대기: 시작 지점을 지도에 보여주고 거기까지 걸어가게 함(아직 start API 안 부름).
/// 2) 가까워지면 "시작" → POST /ghost-runs/start (서버 10m 최종검증).
/// 3) 러닝: 2D 정적 지도가 내 GPS를 추종(고정 줌). 타겟 경로(회색)+내 경로(주황) 동시 표시.
/// 4) 완주/종료 → finish API → 승패.
class GhostRunScreen extends ConsumerStatefulWidget {
  const GhostRunScreen({super.key, required this.detail});

  final GhostRankingDetail detail;

  @override
  ConsumerState<GhostRunScreen> createState() => _GhostRunScreenState();
}

class _GhostRunScreenState extends ConsumerState<GhostRunScreen> {
  GoogleMapController? _mapCtrl;
  StreamSubscription<Position>? _posSub;
  Timer? _ticker;

  _Phase _phase = _Phase.ready;
  String? _fatalError;

  // 대기 단계
  double? _distToStart; // m
  bool _starting = false;
  bool _readyFramed = false; // 대기 카메라 자동 프레이밍은 1회만 (이후 수동 줌/이동 보장)

  // 러닝 단계
  int? _runId;
  GhostRunStart? _startInfo;
  DateTime? _realStartTime;
  final List<LatLng> _myPath = [];
  double _myMeters = 0;
  bool _finishing = false;

  LatLng? _myPos;

  // ── Mock GPS (admin/dev: USE_MOCK_GPS=true) — 실GPS 없이 직접 이동 ──
  bool _mock = false;
  double _mockHeading = 0; // 0°=북, 시계방향
  bool _mockAuto = false;
  Timer? _mockTimer;
  static const double _mockStep = 3.33; // m/회 (~5'00" 페이스)

  // ── 고스트(타겟) 경로 재생 ──────────────────────────────────────────────────
  final List<LatLng> _pathPts = [];
  final List<double> _cum = []; // 누적 거리(m), _pathPts와 동일 길이
  double _pathTotal = 0;

  // 점 마커 비트맵 (작은 점)
  BitmapDescriptor? _myDot;
  BitmapDescriptor? _ghostDot;
  bool _dotsRequested = false;

  // 러닝 추종 줌 — 러닝탭(18.5)보다 조금 멀리서지만 충분히 확대
  static const double _runZoom = 17.5;
  // 시작 버튼 활성 거리(m). 최종 10m 검증은 서버가 함.
  static const double _startEnableRadius = 25;
  static final _fmt = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  GhostRankingDetail get detail => widget.detail;
  LatLng get _start => LatLng(detail.startLat, detail.startLng);
  double get _myKm => _myMeters / 1000;

  @override
  void initState() {
    super.initState();
    _precomputePath();
    _initTracking();
  }

  // 타겟 경로의 누적 거리 미리 계산 (고스트 위치 보간용)
  void _precomputePath() {
    _pathPts
      ..clear()
      ..addAll([for (final p in detail.path) LatLng(p.lat, p.lng)]);
    _cum
      ..clear()
      ..addAll(List<double>.filled(_pathPts.length, 0));
    for (var i = 1; i < _pathPts.length; i++) {
      _cum[i] = _cum[i - 1] +
          Geolocator.distanceBetween(
            _pathPts[i - 1].latitude,
            _pathPts[i - 1].longitude,
            _pathPts[i].latitude,
            _pathPts[i].longitude,
          );
    }
    _pathTotal = _cum.isNotEmpty ? _cum.last : 0;
  }

  /// 고스트(타겟)가 지금까지 경로 위를 진행한 거리(m) — 경과시간 × 타겟 페이스.
  double _ghostMeters() {
    if (_realStartTime == null) return 0;
    final elapsedMin =
        DateTime.now().difference(_realStartTime!).inMilliseconds / 60000.0;
    final pace = _startInfo?.targetAvgPace ?? detail.avgPace;
    return pace > 0 ? elapsedMin / pace * 1000 : 0;
  }

  /// 경로 시작점에서 [meters] 만큼 진행한 지점 좌표 (선형 보간).
  LatLng? _ghostAt(double meters) {
    if (_pathPts.isEmpty) return null;
    if (meters <= 0) return _pathPts.first;
    if (meters >= _pathTotal) return _pathPts.last;
    for (var i = 1; i < _cum.length; i++) {
      if (_cum[i] >= meters) {
        final seg = _cum[i] - _cum[i - 1];
        final t = seg <= 0 ? 0.0 : (meters - _cum[i - 1]) / seg;
        final a = _pathPts[i - 1], b = _pathPts[i];
        return LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        );
      }
    }
    return _pathPts.last;
  }

  /// 작은 원형 점 마커 비트맵 생성.
  Future<BitmapDescriptor> _dotMarker(
    Color fill,
    double dpr, {
    double logical = 14,
    Color ring = Colors.white,
  }) async {
    final size = logical * dpr;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, size / 2, Paint()..color = ring);
    canvas.drawCircle(center, size / 2 - 2 * dpr, Paint()..color = fill);
    final img =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: dpr,
    );
  }

  Future<void> _buildDots(double dpr) async {
    final me = await _dotMarker(AppColors.dAccentBright, dpr, logical: 14);
    final ghost = await _dotMarker(const Color(0xFFE6E6EA), dpr,
        logical: 16, ring: const Color(0xFF55555A));
    if (!mounted) return;
    setState(() {
      _myDot = me;
      _ghostDot = ghost;
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _ticker?.cancel();
    _mockTimer?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  // ── 위치 추적 시작 (대기 단계부터) ─────────────────────────────────────────
  Future<void> _initTracking() async {
    _mock = ref.read(useMockGpsProvider);

    // 500ms — 경과시간 표시 + 고스트 위치를 부드럽게 갱신.
    // (고스트가 먼저 도착해도 종료하지 않음 — 사용자가 완주해야 종료)
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && _phase == _Phase.running) setState(() {});
    });

    // Mock 모드(admin/dev): 실 GPS 대신 타겟 시작점에서 출발 → 직접 이동
    if (_mock) {
      _onPosition(_mockPosition(detail.startLat, detail.startLng, 0));
      return;
    }

    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _fatalError = '위치 권한이 필요해요.\n설정에서 위치를 허용해 주세요.');
        }
        return;
      }
    } catch (_) {}

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 4,
      ),
    ).listen(_onPosition, onError: (_) {});

    // 초기 위치 빠르게 한 번
    try {
      final p = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 4),
            ),
          );
      _onPosition(p);
    } catch (_) {}
  }

  void _onPosition(Position pos) {
    if (!mounted) return;
    final p = LatLng(pos.latitude, pos.longitude);

    if (_phase == _Phase.ready) {
      setState(() {
        _myPos = p;
        _distToStart = Geolocator.distanceBetween(
            p.latitude, p.longitude, detail.startLat, detail.startLng);
      });
      _frameReady();
    } else {
      final last = _myPath.isNotEmpty ? _myPath.last : null;
      if (last != null) {
        _myMeters += Geolocator.distanceBetween(
            last.latitude, last.longitude, p.latitude, p.longitude);
      }
      setState(() {
        _myPos = p;
        _myPath.add(p);
      });
      _mapCtrl?.moveCamera(CameraUpdate.newLatLng(p)); // 추종(줌 고정)
      if (detail.distanceKm > 0 && _myKm >= detail.distanceKm) {
        _finish();
      }
    }
  }

  // 대기: 내 위치 + 시작 지점이 함께 보이도록 프레이밍 (가까우면 시작점 중심)
  Future<void> _frameReady() async {
    if (_readyFramed) return;
    final ctrl = _mapCtrl;
    final me = _myPos;
    if (ctrl == null || me == null) return;
    _readyFramed = true; // 최초 1회만 자동 프레이밍
    final dist = _distToStart ?? 0;
    try {
      if (dist < 30) {
        await ctrl.moveCamera(CameraUpdate.newLatLngZoom(_start, 18.5));
      } else {
        final sw = LatLng(
          me.latitude < _start.latitude ? me.latitude : _start.latitude,
          me.longitude < _start.longitude ? me.longitude : _start.longitude,
        );
        final ne = LatLng(
          me.latitude > _start.latitude ? me.latitude : _start.latitude,
          me.longitude > _start.longitude ? me.longitude : _start.longitude,
        );
        await ctrl.moveCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: sw, northeast: ne),
          72,
        ));
      }
    } catch (_) {}
  }

  // ── Mock 이동 (admin/dev) ──────────────────────────────────────────────────
  Position _mockPosition(double lat, double lng, double speed) => Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 5,
        altitude: 0,
        heading: _mockHeading,
        speed: speed,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
        isMocked: true,
      );

  void _mockMove(double eastM, double northM) {
    final cur = _myPos;
    if (cur == null) return;
    const mPerDegLat = 111320.0;
    final mPerDegLng =
        111320.0 * math.cos(cur.latitude * math.pi / 180).abs();
    final speed = math.sqrt(eastM * eastM + northM * northM);
    _onPosition(_mockPosition(
      cur.latitude + northM / mPerDegLat,
      cur.longitude + eastM / (mPerDegLng == 0 ? 1 : mPerDegLng),
      speed,
    ));
  }

  void _mockForward() {
    final rad = _mockHeading * math.pi / 180;
    _mockMove(_mockStep * math.sin(rad), _mockStep * math.cos(rad));
  }

  void _turnLeft() => setState(() => _mockHeading = (_mockHeading - 45 + 360) % 360);
  void _turnRight() => setState(() => _mockHeading = (_mockHeading + 45) % 360);

  void _toggleMockAuto() {
    setState(() => _mockAuto = !_mockAuto);
    _mockTimer?.cancel();
    if (_mockAuto) {
      _mockTimer = Timer.periodic(
          const Duration(seconds: 1), (_) => _mockForward());
    }
  }

  // ── 시작 ───────────────────────────────────────────────────────────────────
  Future<void> _beginRun() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final me = _myPos;
      final (lat, lng) =
          me != null ? (me.latitude, me.longitude) : await currentLatLng();
      final now = DateTime.now();
      final start = await ref.read(ghostApiProvider).startRun(
            ghostRankingId: detail.rankingId,
            currentLat: lat,
            currentLng: lng,
            startTime: _fmt.format(now),
          );
      if (!mounted) return;
      setState(() {
        _runId = start.runId;
        _startInfo = start;
        _realStartTime = now;
        _myPos = LatLng(lat, lng);
        _myPath
          ..clear()
          ..add(LatLng(lat, lng));
        _myMeters = 0;
        _starting = false;
        _phase = _Phase.running;
      });
      await _mapCtrl?.moveCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: _runZoom, tilt: 0),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _starting = false);
      _snack(e is AppException ? e.message : '고스트 런을 시작할 수 없어요.');
    }
  }

  // ── 종료 ───────────────────────────────────────────────────────────────────
  Future<void> _finish() async {
    if (_finishing || _runId == null) return;
    setState(() => _finishing = true);
    await _posSub?.cancel();
    _ticker?.cancel();
    try {
      final result = await ref.read(ghostApiProvider).finishRun(
            runId: _runId!,
            ghostRankingId: detail.rankingId,
            endTime: _fmt.format(DateTime.now()),
            realStartTime: _fmt.format(_realStartTime ?? DateTime.now()),
            path: [for (final p in _myPath) GhostPathPoint(p.latitude, p.longitude)],
          );
      if (!mounted) return;
      ref.invalidate(ghostRankingProvider(detail.category));
      await _showResult(result);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _finishing = false);
      _snack(e is AppException ? e.message : '기록 저장에 실패했어요.');
    }
  }

  Future<void> _confirmGiveUp() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.dCard,
        title: Text('고스트 런 종료',
            style: TextStyle(color: AppColors.dText, fontSize: 17.sp)),
        content: Text('지금까지의 기록으로 종료할까요?',
            style: TextStyle(color: AppColors.dMuted, fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('계속'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('종료', style: TextStyle(color: AppColors.dRouteEnd)),
          ),
        ],
      ),
    );
    if (ok == true) _finish();
  }

  Future<void> _showResult(GhostRunResult result) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) =>
          _ResultSheet(result: result, targetNickname: detail.nickname),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.dCard,
    ));
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // 점 마커 비트맵 1회 생성 (devicePixelRatio 필요 → build에서)
    if (!_dotsRequested) {
      _dotsRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _buildDots(MediaQuery.of(context).devicePixelRatio);
      });
    }
    return Scaffold(
      backgroundColor: AppColors.dScreen,
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),

          // 뒤로가기
          Positioned(
            top: MediaQuery.of(context).padding.top + 6.h,
            left: 6.w,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.dText, size: 20.r),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),

          // 상단 타겟 정보
          Positioned(
            top: MediaQuery.of(context).padding.top + 8.h,
            left: 52.w,
            right: 16.w,
            child: _buildTargetBar(),
          ),

          if (_fatalError != null)
            Positioned.fill(
              child: _FatalOverlay(
                message: _fatalError!,
                onClose: () => Navigator.of(context).maybePop(),
              ),
            )
          else if (_phase == _Phase.ready)
            Positioned(
                left: 0, right: 0, bottom: 0, child: _buildReadyPanel())
          else
            Positioned(
                left: 0, right: 0, bottom: 0, child: _buildRunningPanel()),

          // Mock 이동 컨트롤 (admin/dev 전용) — 대기/러닝 모두 표시
          if (_mock && _fatalError == null)
            Positioned(
              right: 14.w,
              bottom: 178.h,
              child: _buildMockControls(),
            ),
        ],
      ),
    );
  }

  Widget _buildMockControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _MockButton(
          icon: _mockAuto ? Icons.pause_rounded : Icons.play_arrow_rounded,
          active: _mockAuto,
          onTap: _toggleMockAuto,
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MockButton(icon: Icons.rotate_left_rounded, onTap: _turnLeft),
            SizedBox(width: 8.w),
            _MockButton(
              icon: Icons.navigation_rounded,
              onTap: _mockForward,
              heading: _mockHeading,
            ),
            SizedBox(width: 8.w),
            _MockButton(icon: Icons.rotate_right_rounded, onTap: _turnRight),
          ],
        ),
      ],
    );
  }

  Widget _buildMap() {
    // 고스트(타겟) 현재 위치 — 경과시간 × 타겟 페이스로 경로 위 진행 지점 계산
    LatLng? ghostPos;
    if (_phase == _Phase.running && _realStartTime != null) {
      ghostPos = _ghostAt(_ghostMeters());
    }

    return GoogleMap(
      style: AppMapStyles.darkWarm,
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: _start,
        zoom: 16,
        tilt: 0, // 2D
      ),
      myLocationButtonEnabled: false,
      compassEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      // 2D 유지(회전/기울기 잠금) + 확대·축소·이동 허용
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      polylines: {
        // 타겟 경로 — 굵은 회색 트랙(아래 레이어). 이 위로 점들이 달림.
        if (_pathPts.length >= 2)
          Polyline(
            polylineId: const PolylineId('target_path'),
            points: _pathPts,
            color: AppColors.spotNeutral,
            width: 11,
            zIndex: 1,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        // 내 경로 — 얇은 주황(위 레이어).
        if (_myPath.length >= 2)
          Polyline(
            polylineId: const PolylineId('my_path'),
            points: _myPath,
            color: AppColors.dAccentBright,
            width: 6,
            zIndex: 2,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
      },
      markers: {
        // 고스트(타겟) — 회색 길 위를 타겟 페이스대로 이동하는 점
        if (ghostPos != null && _ghostDot != null)
          Marker(
            markerId: const MarkerId('ghost'),
            position: ghostPos,
            icon: _ghostDot!,
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 3,
          ),
        // 나 — 회색 길 안에 들어갈 만한 작은 주황 점
        if (_myPos != null)
          Marker(
            markerId: const MarkerId('me'),
            position: _myPos!,
            icon: _myDot ??
                BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange),
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 4,
          ),
      },
      onMapCreated: (c) {
        _mapCtrl = c;
        if (_phase == _Phase.ready) _frameReady();
      },
    );
  }

  Widget _buildTargetBar() {
    final targetPace = _startInfo?.targetAvgPace ?? detail.avgPace;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xF21E1E21),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.dLine2, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: AppColors.dGold, size: 20.r),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${detail.nickname.isEmpty ? "고스트" : detail.nickname} · ${detail.category}',
                  style: TextStyle(
                    color: AppColors.dText,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '목표 페이스 ${formatPace(targetPace)}/km',
                  style: TextStyle(
                    color: AppColors.dMuted,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 대기 패널 (시작 지점으로 이동) ─────────────────────────────────────────
  Widget _buildReadyPanel() {
    final dist = _distToStart;
    final canStart = dist != null && dist <= _startEnableRadius;
    final String distLabel;
    if (dist == null) {
      distLabel = '내 위치 확인 중...';
    } else if (dist <= 10) {
      distLabel = '시작 지점 도착! 출발하세요';
    } else {
      distLabel = '시작 지점까지 약 ${dist.round()}m';
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 0),
      decoration: BoxDecoration(
        color: AppColors.dCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border(top: BorderSide(color: AppColors.dLine2, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.directions_walk_rounded,
                    color: canStart ? AppColors.dAccent : AppColors.dMuted,
                    size: 22.r),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '고스트 시작 지점으로 이동하세요',
                        style: TextStyle(
                          color: AppColors.dText,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        distLabel,
                        style: TextStyle(
                          color: canStart ? AppColors.dAccent : AppColors.dMuted,
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      canStart ? AppColors.dAccent : AppColors.dCard2,
                  disabledBackgroundColor: AppColors.dCard2,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                onPressed: (!canStart || _starting) ? null : _beginRun,
                child: _starting
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        canStart ? '고스트 런 시작' : '시작 지점에 가까이 가세요',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: canStart ? Colors.white : AppColors.dFaint,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  // ── 러닝 패널 ──────────────────────────────────────────────────────────────
  Widget _buildRunningPanel() {
    final elapsed = _realStartTime == null
        ? Duration.zero
        : DateTime.now().difference(_realStartTime!);
    final myPaceDecimal = _myKm > 0 ? (elapsed.inSeconds / 60) / _myKm : 0.0;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 0),
      decoration: BoxDecoration(
        color: AppColors.dCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border(top: BorderSide(color: AppColors.dLine2, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _stat('거리', _myKm.toStringAsFixed(2), 'km'),
                _divider(),
                _stat('페이스', formatPace(myPaceDecimal), '/km'),
                _divider(),
                _stat('시간', _hms(elapsed), ''),
              ],
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dRouteEnd,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                onPressed: _finishing ? null : _confirmGiveUp,
                child: _finishing
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        '종료하기',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, String unit) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.dMuted,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: TextStyle(
                      color: AppColors.dText,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900)),
              if (unit.isNotEmpty) ...[
                SizedBox(width: 2.w),
                Text(unit,
                    style: TextStyle(
                        color: AppColors.dFaint,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 34.h, color: AppColors.dLine2);

  String _hms(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}

// ── Mock 이동 버튼 ──────────────────────────────────────────────────────────────
class _MockButton extends StatelessWidget {
  const _MockButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.heading,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final double? heading;

  @override
  Widget build(BuildContext context) {
    Widget child = Icon(icon,
        color: active ? Colors.white : AppColors.dText, size: 26.r);
    if (heading != null) {
      child = Transform.rotate(angle: heading! * math.pi / 180, child: child);
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52.r,
        height: 52.r,
        decoration: BoxDecoration(
          color: active ? AppColors.dAccent : const Color(0xF21E1E21),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.dLine2, width: 1),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

// ── 치명적 오류(위치 권한 등) 오버레이 ──────────────────────────────────────────
class _FatalOverlay extends StatelessWidget {
  const _FatalOverlay({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xE6141416),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 40.w),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          decoration: BoxDecoration(
            color: AppColors.dCard,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColors.dLine2, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded,
                  size: 44.r, color: AppColors.dRouteEnd),
              SizedBox(height: 16.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.dText,
                  fontSize: 15.sp,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.dAccent,
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onPressed: onClose,
                  child: Text('닫기',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 결과 시트 (WIN / LOSE) ──────────────────────────────────────────────────────
class _ResultSheet extends StatelessWidget {
  const _ResultSheet({required this.result, required this.targetNickname});

  final GhostRunResult result;
  final String targetNickname;

  @override
  Widget build(BuildContext context) {
    final win = result.isWin;
    final accent = win ? AppColors.dGold : AppColors.dRouteEnd;

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.all(12.r),
        padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 20.h),
        decoration: BoxDecoration(
          color: AppColors.dCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(win ? Icons.emoji_events_rounded : Icons.flag_rounded,
                size: 56.r, color: accent),
            SizedBox(height: 12.h),
            Text(
              win ? 'WIN!' : 'LOSE',
              style: TextStyle(
                color: accent,
                fontSize: 32.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              win
                  ? '$targetNickname님의 기록을 이겼어요!'
                  : '$targetNickname님에게 졌어요. 다시 도전해봐요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.dMuted,
                fontSize: 13.5.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: AppColors.dCard2,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Row(
                children: [
                  _paceCol('내 페이스', formatPace(result.myAvgPace),
                      win ? accent : AppColors.dText),
                  Container(width: 1, height: 36.h, color: AppColors.dLine2),
                  _paceCol('목표 페이스', formatPace(result.targetAvgPace),
                      AppColors.dText),
                ],
              ),
            ),
            if (result.rankingUpdated) ...[
              SizedBox(height: 14.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up_rounded,
                      color: AppColors.dGold, size: 18.r),
                  SizedBox(width: 6.w),
                  Text(
                    '랭킹이 갱신됐어요!',
                    style: TextStyle(
                      color: AppColors.dGold,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 22.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dAccent,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text('확인',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paceCol(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.dMuted,
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 4.h),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
