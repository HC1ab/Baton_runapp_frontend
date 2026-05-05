/// General display-formatting utilities.
/// Always reuse these — never duplicate formatting logic in widgets.
abstract final class FormatUtils {
  /// Formats distance in meters → "0.00 km" or "500 m".
  static String formatDistance(double distanceMeters) {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
    }
    return '${distanceMeters.toStringAsFixed(0)} m';
  }

  /// Formats duration → "HH:MM:SS".
  static String formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(duration.inHours)}:${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}';
  }

  /// Formats duration short → "MM:SS" (for elapsed time under 1 hour).
  static String formatDurationShort(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}';
  }

  /// Formats point value → "1,234 P".
  static String formatPoint(int points) {
    final buffer = StringBuffer();
    final str = points.toString();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return '$buffer P';
  }
}
