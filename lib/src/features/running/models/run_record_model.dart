import 'package:flutter/foundation.dart';

import '../../../core/utils/running_utils.dart';
import '../../../core/utils/format_utils.dart';
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
    this.runId,
    this.startTime,
    this.errorMessage,
  });

  final RunStatus status;
  final double distanceMeters;
  final Duration duration;
  final double currentPaceSecondsPerKm;
  final double averagePaceSecondsPerKm;
  final List<RunPathPoint> path;
  final List<SpotSummary> nearbySpots;
  final Set<int> checkedInSpotIds;
  final int spotPoints;        // Points earned from spot check-ins
  final int? runId;
  final DateTime? startTime;
  final String? errorMessage;

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
    int? runId,
    DateTime? startTime,
    String? errorMessage,
    bool clearError = false,
    bool clearRunId = false,
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
      runId: clearRunId ? null : (runId ?? this.runId),
      startTime: startTime ?? this.startTime,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
