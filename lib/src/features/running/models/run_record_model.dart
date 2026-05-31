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
    this.runId,
    this.startTime,
    this.errorMessage,
    this.lastCheckIn,  // 최근 체크인 결과 (카드 표시용)
  });

  final RunStatus status;
  final double distanceMeters;
  final Duration duration;
  final double currentPaceSecondsPerKm;
  final double averagePaceSecondsPerKm;
  final List<RunPathPoint> path;
  final List<SpotSummary> nearbySpots;
  final Set<int> checkedInSpotIds;
  final int spotPoints;
  final List<LapRecord> laps;
  final int? runId;
  final DateTime? startTime;
  final String? errorMessage;
  final CheckInResult? lastCheckIn;

  bool get isRunning => status == RunStatus.running;
  bool get isIdle => status == RunStatus.idle;

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
    int? spotPoints,
    List<LapRecord>? laps,
    int? runId,
    DateTime? startTime,
    String? errorMessage,
    bool clearError = false,
    bool clearRunId = false,
    bool clearCheckIn = false,
    CheckInResult? lastCheckIn,
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
      spotPoints: spotPoints ?? this.spotPoints,
      laps: laps ?? this.laps,
      runId: clearRunId ? null : (runId ?? this.runId),
      startTime: startTime ?? this.startTime,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastCheckIn: clearCheckIn ? null : (lastCheckIn ?? this.lastCheckIn),
    );
  }
}
