import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


/// 러닝 시작 전 3초 카운트다운 전체화면 오버레이.
/// 3 → 2 → 1 → GO! 순서로 1초 간격 표시.
/// 완료 시 [onComplete] 콜백 호출.
class CountdownOverlay extends StatefulWidget {
  const CountdownOverlay({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  int _count = 3;
  Timer? _timer;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 1.2, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );

    _scaleCtrl.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_count <= 1) {
        _timer?.cancel();
        if (mounted) widget.onComplete();
      } else {
        setState(() => _count--);
        _scaleCtrl
          ..reset()
          ..forward();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = '$_count';
    const color = Colors.white;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 120.sp,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
