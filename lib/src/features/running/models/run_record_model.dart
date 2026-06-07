import 'package:flutter/foundation.dart';

import '../../../core/utils/running_utils.dart';
import '../../../core/utils/format_utils.dart';
import '../services/spot_service.dart';
import 'lap_record_model.dart';
import 'run_path_point_model.dart';
import 'spot_model.dart';

/// Status of a running session.
enum RunStatus { idle, running, finished }

/// Full runtime state of a running session.
/// Immutable — Notifier creates new instances on each state change.
@immutable
class RunRecordModel {
  const RunRecordModel({
    required this.status,
    required this.distanceMeters,
    required this.duration,
    required this.currentPaceSecondsPerKm,
    required this.averagePaceSecondsPerKm,
    required this.path,
    required this.nearbySpots,
    required this.checkedInSpotIds,
    required this.spotPoints,
    required this.laps,
    this.blockedSpotIds = const {},
    this.recordedToServer = false,
    this.runId,
    this.startTime,
    this.errorMessage,
    this.lastCheckIn,
    this.groupId,
    this.isHost = false,
  });

  final RunStatus status;
  final double distanceMeters;
  final Duration duration;
  final double currentPaceSecondsPerKm;
  final double averagePaceSecondsPerKm;
  final List<RunPathPoint> path;
  final List<SpotSummary> nearbySpots;
  final Set<int> checkedInSpotIds;

  /// C003 수신 스팟 — 서버 기준 이미 체크인(24h 쿨다운). 맵에서 체크인 완료로 표시.
  /// checkedInSpotIds와 분리해 이번 런 포인트/카운트에 영향 없음.
  final Set<int> blockedSpotIds;

  /// 백엔드에 러닝 기록이 저장되었는지 여부.
  /// false = 0.2km 미만 종료 등으로 미저장. 결과 화면에서 "기록 안 됨" 표시.
  final bool recordedToServer;

  final int spotPoints;
  final List<LapRecord> laps;
  final int? runId;
  final DateTime? startTime;
  final String? errorMessage;
  final CheckInResult? lastCheckIn;

  /// null = solo run, non-null = group run
  final int? groupId;
  final bool isHost;

  bool get isRunning => status == RunStatus.running;
  bool get isIdle => status == RunStatus.idle;
  bool get isGroupRun => groupId != null;

  // --- Convenience display getters (use util classes) ---
  String get formattedDistance => FormatUtils.formatDistance(distanceMeters);
  String get formattedDuration => FormatUtils.formatDuration(duration);
  String get formattedCurrentPace =>
      RunningUtils.formatPace(currentPaceSecondsPerKm);
  String get formattedAveragePace =>
      RunningUtils.formatPace(averagePaceSecondsPerKm);
  int get runPoints => RunningUtils.calculateEarnedPoints(distanceMeters);
  int get totalPoints => runPoints + spotPoints;

  factory RunRecordModel.initial() => const RunRecordModel(
        status: RunStatus.idle,
        distanceMeters: 0,
        duration: Duration.zero,
        currentPaceSecondsPerKm: 0,
        averagePaceSecondsPerKm: 0,
        path: [],
        nearbySpots: [],
        checkedInSpotIds: {},
        spotPoints: 0,
        laps: [],
      );

  RunRecordModel copyWith({
    RunStatus? status,
    double? distanceMeters,
    Duration? duration,
    double? currentPaceSecondsPerKm,
    double? averagePaceSecondsPerKm,
    List<RunPathPoint>? path,
    List<SpotSummary>? nearbySpots,
    Set<int>? checkedInSpotIds,
    Set<int>? blockedSpotIds,
    bool? recordedToServer,
    int? spotPoints,
    List<LapRecord>? laps,
    int? runId,
    DateTime? startTime,
    String? errorMessage,
    bool clearError = false,
    bool clearRunId = false,
    bool clearCheckIn = false,
    CheckInResult? lastCheckIn,
    int? groupId,
    bool? isHost,
    bool clearGroup = false,
  }) {
    return RunRecordModel(
      status: status ?? this.status,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      duration: duration ?? this.duration,
      currentPaceSecondsPerKm:
          currentPaceSecondsPerKm ?? this.currentPaceSecondsPerKm,
      averagePaceSecondsPerKm:
          averagePaceSecondsPerKm ?? this.averagePaceSecondsPerKm,
      path: path ?? this.path,
      nearbySpots: nearbySpots ?? this.nearbySpots,
      checkedInSpotIds: checkedInSpotIds ?? this.checkedInSpotIds,
      blockedSpotIds: blockedSpotIds ?? this.blockedSpotIds,
      recordedToServer: recordedToServer ?? this.recordedToServer,
      spotPoints: spotPoints ?? this.spotPoints,
      laps: laps ?? this.laps,
      runId: clearRunId ? null : (runId ?? this.runId),
      startTime: startTime ?? this.startTime,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastCheckIn: clearCheckIn ? null : (lastCheckIn ?? this.lastCheckIn),
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      isHost: isHost ?? this.isHost,
    );
  }
}
