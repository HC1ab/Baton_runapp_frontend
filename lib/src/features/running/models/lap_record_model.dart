import 'package:flutter/foundation.dart';

import '../../../core/utils/running_utils.dart';

/// A single lap record captured every 1 km during a run.
@immutable
class LapRecord {
  const LapRecord({
    required this.lapNumber,
    required this.distanceMeters,
    required this.duration,
    required this.paceSecondsPerKm,
  });

  /// 1-based lap index.
  final int lapNumber;

  /// Distance covered in this lap (should be ~1000 m).
  final double distanceMeters;

  /// Time taken for this lap.
  final Duration duration;

  /// Pace for this lap in seconds/km.
  final double paceSecondsPerKm;

  String get formattedPace => RunningUtils.formatPace(paceSecondsPerKm);

  String get formattedDuration {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
