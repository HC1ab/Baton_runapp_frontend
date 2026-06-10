/// Running-domain utility functions.
/// Always reuse these — never duplicate pace/calorie/point logic elsewhere.
abstract final class RunningUtils {
  /// Converts pace in seconds/km to "MM'SS\"" display string.
  /// Returns "00'00\"" when pace is invalid or over 30 min/km (e.g. standing still).
  static String formatPace(double paceSecondsPerKm) {
    if (paceSecondsPerKm <= 0 ||
        paceSecondsPerKm.isInfinite ||
        paceSecondsPerKm.isNaN ||
        paceSecondsPerKm > 1800) {
      return "00'00\"";
    }
    final minutes = (paceSecondsPerKm / 60).floor();
    final seconds = (paceSecondsPerKm % 60).floor();
    return "${minutes.toString().padLeft(2, '0')}'${seconds.toString().padLeft(2, '0')}\"";
  }

  /// Estimates burned calories.
  /// Formula: MET * weight(kg) * duration(hours)
  /// Default MET 8.0 ≈ running at ~9 km/h.
  static double calculateCalories({
    required double distanceMeters,
    required Duration duration,
    double weightKg = 70.0,
    double met = 8.0,
  }) {
    if (duration.inSeconds <= 0) return 0.0;
    final hours = duration.inSeconds / 3600.0;
    return met * weightKg * hours;
  }

  /// Calculates points earned from a run.
  /// Rule: 10 points per km (floor).
  static int calculateEarnedPoints(double distanceMeters) {
    if (distanceMeters <= 0) return 0;
    final km = distanceMeters / 1000.0;
    return (km * 10).floor();
  }

  /// Average pace in seconds/km from total distance and duration.
  static double averagePace(double distanceMeters, Duration duration) {
    if (distanceMeters < 10) return 0.0;
    return duration.inSeconds / (distanceMeters / 1000.0);
  }

  /// Real-time pace from speed in m/s.
  /// Returns 0.0 when speed is too slow (stopped).
  static double paceFromSpeed(double speedMs) {
    if (speedMs < 0.5) return 0.0; // below ~1.8 km/h → treat as stopped
    return 1000.0 / speedMs; // seconds/km: 1000m ÷ speed(m/s)
  }
}
