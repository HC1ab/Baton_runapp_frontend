import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/utils/running_utils.dart';
import '../models/run_path_point_model.dart';
import '../models/run_record_model.dart';
import '../models/spot_model.dart';
import '../services/run_service.dart';
import '../services/spot_service.dart';

final _logger = Logger();

// ---------------------------------------------------------------------------
// Check-in radius constant
// ---------------------------------------------------------------------------

/// Maximum distance in meters to allow spot check-in (서버 기준 30m).
const double spotCheckInRadiusMeters = 30.0;

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class RunningNotifier extends Notifier<RunRecordModel> {
  StreamSubscription<Position>? _positionSub;
  Timer? _clockTimer;
  Timer? _spotsDebounce;
  Position? _lastPosition;
  Position? _lastSpotsRefreshPos; // 마지막으로 스팀 조회한 위치
  double _filteredPace = 0.0; // Low-pass filtered pace value

  @override
  RunRecordModel build() {
    ref.onDispose(_cleanUp);
    return RunRecordModel.initial();
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Initializes GPS and loads nearby spots.
  /// Call once when the running screen mounts.
  Future<void> initialize({bool useMock = false}) async {
    state = state.copyWith(clearError: true);

    try {
      if (!useMock) {
        await _checkLocationPermission();
      }

      // Load initial nearby spots (uses last known position or default)
      // Position will be provided externally via [onPositionUpdate] in mock mode
    } catch (e) {
      _logger.e('Running init error', error: e);
      state = state.copyWith(errorMessage: _toMessage(e));
    }
  }

  /// Called by real GPS stream or MockLocationController.
  /// Updates position, path (if running), pace, and triggers spot refresh.
  Future<void> onPositionUpdate(Position position, {bool isDev = false}) async {
    // --- Distance & pace update ---
    double distanceDelta = 0;
    if (_lastPosition != null && state.isRunning) {
      distanceDelta = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
    }

    // Low-pass filter on pace (80% old / 20% new) — from original RunNotifier
    final rawPace = RunningUtils.paceFromSpeed(position.speed);
    if (_filteredPace == 0.0) {
      _filteredPace = rawPace;
    } else if (rawPace > 0) {
      _filteredPace = (_filteredPace * 0.8) + (rawPace * 0.2);
    } else {
      _filteredPace = 0.0;
    }

    _lastPosition = position;

    final newDistance = state.distanceMeters + distanceDelta;
    final newPath = state.isRunning
        ? [...state.path, RunPathPoint(lat: position.latitude, lng: position.longitude)]
        : state.path;

    state = state.copyWith(
      distanceMeters: newDistance,
      path: newPath,
      currentPaceSecondsPerKm: _filteredPace,
      averagePaceSecondsPerKm:
          RunningUtils.averagePace(newDistance, state.duration),
      clearError: true,
    );

    // Debounced nearby spot refresh (only when not running or not frozen)
    _debouncedRefreshSpots(position);

    // Auto check-in 제거 — 마커 탭으로만 체크인 가능
  }

  /// Starts a new running session.
  Future<void> startRun() async {
    if (state.isRunning) return;
    state = state.copyWith(clearError: true);

    try {
      final now = DateTime.now();
      final runId = await ref.read(runServiceProvider).startRun(
            startTimeIsoLocal: _isoLocal(now),
          );

      _filteredPace = 0.0;
      _startClock();

      state = RunRecordModel(
        status: RunStatus.running,
        distanceMeters: 0,
        duration: Duration.zero,
        currentPaceSecondsPerKm: 0,
        averagePaceSecondsPerKm: 0,
        path: _lastPosition != null
            ? [RunPathPoint(lat: _lastPosition!.latitude, lng: _lastPosition!.longitude)]
            : [],
        nearbySpots: state.nearbySpots,    // keep already-loaded spots
        checkedInSpotIds: {},
        spotPoints: 0,
        runId: runId,
        startTime: now,
      );
    } catch (e) {
      _logger.e('startRun error', error: e);
      state = state.copyWith(errorMessage: _toMessage(e));
    }
  }

  /// Finishes the current running session.
  Future<void> finishRun() async {
    final runId = state.runId;
    if (runId == null || !state.isRunning) return;

    _stopClock();
    state = state.copyWith(clearError: true);

    try {
      await ref.read(runServiceProvider).finishRun(
            runId: runId,
            endTimeIsoLocal: _isoLocal(DateTime.now()),
            path: state.path,
          );

      state = state.copyWith(
        status: RunStatus.finished,
        clearRunId: true,
        clearError: true,
      );
    } catch (e) {
      _logger.e('finishRun error', error: e);
      // Revert to running so user can retry
      state = state.copyWith(
        status: RunStatus.running,
        errorMessage: _toMessage(e),
      );
    }
  }

  /// Resets back to idle after viewing the finish summary.
  void resetToIdle() {
    _cleanUp();
    state = RunRecordModel.initial();
  }

  /// Manually triggers a spot check-in (from map marker tap).
  Future<void> checkInSpot(SpotSummary spot) async {
    if (!state.isRunning) {
      state = state.copyWith(errorMessage: '러닝 중에만 체크인할 수 있어요.');
      return;
    }

    // 이미 체크인한 스팟 → 에러 대신 카드로 알려줌
    if (state.checkedInSpotIds.contains(spot.id)) {
      final alreadyResult = CheckInResult.alreadyCheckedIn(spot.name);
      state = state.copyWith(lastCheckIn: alreadyResult);
      Future.delayed(const Duration(seconds: 3), () {
        state = state.copyWith(clearCheckIn: true);
      });
      return;
    }

    final pos = _lastPosition;
    if (pos == null) return;

    final dist = Geolocator.distanceBetween(
      pos.latitude, pos.longitude,
      spot.latitude, spot.longitude,
    );
    if (dist > spotCheckInRadiusMeters) {
      state = state.copyWith(
        errorMessage: '${spotCheckInRadiusMeters.toInt()}m 이내에서만 체크인할 수 있어요.',
      );
      return;
    }

    await _doCheckIn(spot);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isRunning) return;
      state = state.copyWith(
        duration: state.duration + const Duration(seconds: 1),
      );
    });
  }

  void _stopClock() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  void _debouncedRefreshSpots(Position pos) {
    // 러닝 중에는 스팟 목록 고정
    if (state.isRunning) return;

    // 50m 이상 이동했을 때만 재조회
    final lastRefresh = _lastSpotsRefreshPos;
    if (lastRefresh != null) {
      final moved = Geolocator.distanceBetween(
        lastRefresh.latitude,
        lastRefresh.longitude,
        pos.latitude,
        pos.longitude,
      );
      if (moved < 50.0) return;
    }

    _spotsDebounce?.cancel();
    _spotsDebounce = Timer(const Duration(milliseconds: 600), () async {
      await _loadNearbySpots(pos);
    });
  }

  Future<void> _loadNearbySpots(Position pos) async {
    try {
      final spots = await ref.read(spotServiceProvider).nearby(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
      _lastSpotsRefreshPos = pos; // 조회 성공 시에만 위치 저장
      state = state.copyWith(nearbySpots: spots);
    } catch (e) {
      _logger.w('loadNearbySpots failed', error: e);
    }
  }

  Future<void> _doCheckIn(SpotSummary spot) async {
    final runId = state.runId;
    final pos = _lastPosition;
    if (runId == null || pos == null) return;

    try {
      final result = await ref.read(spotServiceProvider).checkIn(
            spotId: spot.id,
            runId: runId,
            latitude: pos.latitude,
            longitude: pos.longitude,
            timestamp: _isoLocal(DateTime.now()),
          );
      final newIds = {...state.checkedInSpotIds, spot.id};
      state = state.copyWith(
        checkedInSpotIds: newIds,
        spotPoints: state.spotPoints + result.earnedPoints,
        lastCheckIn: result,
        clearError: true,
      );

      // 3초 후 체크인 카드 자동 제거
      Future.delayed(const Duration(seconds: 3), () {
        state = state.copyWith(clearCheckIn: true);
      });
    } catch (e) {
      _logger.e('checkIn error spot=${spot.id}', error: e);
      state = state.copyWith(errorMessage: _toMessage(e));
    }
  }

  Future<void> _checkLocationPermission() async {
    // [iOS 대응] NSLocationWhenInUseUsageDescription / NSLocationAlwaysUsageDescription 추가 필요
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw const ServerException('위치 서비스가 꺼져 있어요.');

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw const ServerException('위치 권한이 필요해요.');
    }
  }

  void _cleanUp() {
    _stopClock();
    _positionSub?.cancel();
    _spotsDebounce?.cancel();
    _lastPosition = null;
    _filteredPace = 0.0;
  }

  String _isoLocal(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$mo-${d}T$h:$mi:$s';
  }

  String _toMessage(Object e) {
    if (e is AppException) return e.message;
    return '알 수 없는 오류가 발생했어요.';
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// keepAlive: true — running state must persist across tab switches.
final runningProvider =
    NotifierProvider<RunningNotifier, RunRecordModel>(RunningNotifier.new);
