import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../common/widgets/character_sphere_widget.dart';
import '../../../core/character/character_style.dart';

/// 캐릭터 구체를 화면 좌표계에 오버레이.
///
/// getScreenCoordinate()로 LatLng → 화면 픽셀 변환.
/// 그림자 기준점(LatLng)보다 위쪽(Y-)에 구를 배치.
/// 맵 bearing/tilt 무관 — 항상 동일하게 표시.
class CharacterSphereOverlay extends StatefulWidget {
  const CharacterSphereOverlay({
    super.key,
    required this.latLng,
    required this.mapController,
    required this.characterStyle,
    this.size = 48.0,
  });

  final LatLng? latLng;
  final GoogleMapController mapController;
  final CharacterStyle characterStyle;

  /// 구체 지름 (논리 픽셀).
  final double size;

  @override
  State<CharacterSphereOverlay> createState() => _CharacterSphereOverlayState();
}

class _CharacterSphereOverlayState extends State<CharacterSphereOverlay> {
  ScreenCoordinate? _screenCoord;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateCoord();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _updateCoord() async {
    final pos = widget.latLng;
    if (pos == null || !mounted) return;
    try {
      final coord = await widget.mapController.getScreenCoordinate(pos);
      if (!mounted) return;
      setState(() => _screenCoord = coord);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final coord = _screenCoord;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final s = widget.size;

    // 기준점(LatLng)에서 구 반지름만큼 위로 올림
    final cx = coord != null ? coord.x / dpr : -500.0;
    final cy = coord != null ? coord.y / dpr - s * 0.25 : -500.0;

    return Positioned(
      left: cx - s / 2,
      top: cy - s / 2,
      width: s,
      height: s,
      child: IgnorePointer(
        child: CharacterSphereWidget(
          style: widget.characterStyle,
          size: s,
        ),
      ),
    );
  }
}
