import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 캐릭터 위치에 고정된 2D 그림자 오버레이.
///
/// getScreenCoordinate()로 LatLng → 화면 픽셀 변환 후
/// Flutter Positioned 위젯으로 렌더링.
/// 맵 bearing/tilt 무관 — 화면 좌표계 고정 → 항상 동일하게 표시.
class CharacterShadowOverlay extends StatefulWidget {
  const CharacterShadowOverlay({
    super.key,
    required this.latLng,
    required this.mapController,
    this.size = 48.0,
  });

  final LatLng? latLng;
  final GoogleMapController mapController;

  /// 그림자 너비 기준 크기 (논리 픽셀).
  final double size;

  @override
  State<CharacterShadowOverlay> createState() => _CharacterShadowOverlayState();
}

class _CharacterShadowOverlayState extends State<CharacterShadowOverlay> {
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
    // iOS: getScreenCoordinate()는 logical pixel(pt) 반환 → 변환 불필요
    // Android: physical pixel 반환 → dpr로 나눠 logical pixel로 변환
    final scale = Platform.isAndroid ? MediaQuery.devicePixelRatioOf(context) : 1.0;
    final s = widget.size;

    // 그림자 크기: 너비 s, 높이 s * 0.35 (납작한 타원)
    final w = s;
    final h = s * 0.35;

    // 화면 좌표: 캐릭터 위치 기준 약간 아래
    final cx = coord != null ? coord.x / scale : -500.0;
    final cy = coord != null ? coord.y / scale + s * 0.28 : -500.0;

    return Positioned(
      left: cx - w / 2,
      top: cy - h / 2,
      width: w,
      height: h,
      child: IgnorePointer(
        child: CustomPaint(
          size: Size(w, h),
          painter: _ShadowPainter(),
        ),
      ),
    );
  }
}

class _ShadowPainter extends CustomPainter {
  const _ShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // 캔버스를 타원 비율로 스케일 → 원으로 변환 후 circular gradient 적용
    // → 모든 방향에서 동일하게 페이드 (진한 중앙 → 투명 가장자리)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(1.0, size.height / size.width); // 세로를 가로 비율로 압축
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          r,
          [
            const Color(0x66000000),
            const Color(0x33000000),
            const Color(0x00000000),
          ],
          [0.0, 0.55, 1.0],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShadowPainter old) => false;
}
