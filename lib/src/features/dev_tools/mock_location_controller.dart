import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Simulates GPS position updates for development/testing.
/// Only used when _isDev is true — never referenced outside dev_tools/.
class MockLocationController {
  MockLocationController({
    required this.onPositionChanged,
    required this.onStateChanged,
  });

  final void Function(Position position) onPositionChanged;
  final VoidCallback onStateChanged;

  Timer? _timer;
  bool _autoWalk = false;
  double _stepMeters = 3.33; // Default: ~5'00" pace
  int _dirStep = 0;
  Position? _currentPos;

  bool get isAutoWalk => _autoWalk;
  double get stepMeters => _stepMeters;

  void dispose() {
    _timer?.cancel();
  }

  /// Sets the initial position and returns it.
  Position initPosition({required double lat, required double lng}) {
    final pos = _makePosition(lat: lat, lng: lng, speed: 0);
    _currentPos = pos;
    return pos;
  }

  void setStepMeters(double value) {
    _stepMeters = value;
    onStateChanged();
  }

  void toggleAutoWalk() {
    _autoWalk = !_autoWalk;
    onStateChanged();

    _timer?.cancel();
    if (!_autoWalk) {
      // Emit speed=0 so pace display resets
      final cur = _currentPos;
      if (cur != null) {
        final stopped =
            _makePosition(lat: cur.latitude, lng: cur.longitude, speed: 0);
        _currentPos = stopped;
        onPositionChanged(stopped);
      }
      return;
    }

    _dirStep = 0;
    // Emit one position update per second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _walk();
      _dirStep++;
    });
  }

  /// Manually move by [eastMeters] east and [northMeters] north.
  void nudge({required double eastMeters, required double northMeters}) {
    final cur = _currentPos;
    if (cur == null) return;

    final mLat = 111320.0;
    final mLng =
        111320.0 * math.cos(cur.latitude * math.pi / 180.0).abs();

    final dLat = northMeters / mLat;
    final dLng = eastMeters / (mLng == 0 ? 1 : mLng);

    // Speed = distance moved in 1 second → m/s
    final speed =
        math.sqrt(math.pow(eastMeters, 2) + math.pow(northMeters, 2));

    final next = _makePosition(
      lat: cur.latitude + dLat,
      lng: cur.longitude + dLng,
      speed: speed,
    );
    _currentPos = next;
    onPositionChanged(next);
  }

  // Simulates a rectangular walking pattern (N→E→S→W, 10 steps each)
  void _walk() {
    switch (_dirStep % 40) {
      case >= 0 && < 10:
        nudge(eastMeters: 0, northMeters: _stepMeters);
      case >= 10 && < 20:
        nudge(eastMeters: _stepMeters, northMeters: 0);
      case >= 20 && < 30:
        nudge(eastMeters: 0, northMeters: -_stepMeters);
      default:
        nudge(eastMeters: -_stepMeters, northMeters: 0);
    }
  }

  Position _makePosition({
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
}
