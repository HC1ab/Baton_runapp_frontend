import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';

import '../../../common/widgets/character_sphere_widget.dart';
import '../../../core/character/character_style.dart';

final _logger = Logger();

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
    this.titleName,
    this.nickname,
  });

  final LatLng? latLng;
  final GoogleMapController mapController;
  final CharacterStyle characterStyle;

  /// 구체 지름 (논리 픽셀).
  final double size;

  /// 장착 칭호 표시 이름. null이면 배지 숨김.
  final String? titleName;

  /// 닉네임 — 칭호 위에 표시. null이면 숨김.
  final String? nickname;

  @override
  State<CharacterSphereOverlay> createState() => _CharacterSphereOverlayState();
}

class _LabelBadge extends StatelessWidget {
  const _LabelBadge({
    required this.text,
    this.backgroundColor,
    this.textColor = Colors.white,
  });
  final String text;
  final Color? backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
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
    } on PlatformException catch (e) {
      if (e.code == 'channel-error') return; // 맵 초기화 전 일시적 에러
      _logger.w('[Overlay] getScreenCoordinate failed', error: e);
    } catch (e) {
      _logger.w('[Overlay] getScreenCoordinate failed', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coord = _screenCoord;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final s = widget.size;
    final title = widget.titleName;
    final nickname = widget.nickname;

    // 기준점(LatLng)에서 구 반지름만큼 위로 올림
    final cx = coord != null ? coord.x / dpr : -500.0;
    final cy = coord != null ? coord.y / dpr - s * 0.25 : -500.0;

    return Positioned(
      left: cx - s / 2,
      top: cy - s / 2,
      width: s,
      height: s,
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 구체 — 항상 고정 위치
            CharacterSphereWidget(
              style: widget.characterStyle,
              size: s,
            ),
            // 칭호 배지 — 구체 위에 overflow 배치, null이면 숨김
            if (title != null)
              Positioned(
                bottom: s + 2.h,
                child: UnconstrainedBox(
                  child: _LabelBadge(text: title),
                ),
              ),
            // 닉네임 배지 — 칭호 위 (칭호 없으면 구체 바로 위)
            if (nickname != null)
              Positioned(
                bottom: s + 2.h + (title != null ? 18.h : 0),
                child: UnconstrainedBox(
                  child: _LabelBadge(
                    text: nickname,
                    backgroundColor: Colors.white.withValues(alpha: 0.85),
                    textColor: Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
