import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/run_share_data.dart';
import '../models/share_overlay_config.dart';

/// NRC 스타일 고정 하단 바.
/// 아이콘 + 값 3칸 수평 배치 — 색상은 각 StatItemConfig.color 적용.
class ShareNrcBarWidget extends StatelessWidget {
  const ShareNrcBarWidget({
    super.key,
    required this.data,
    required this.config,
  });

  final RunShareData data;
  final ShareOverlayConfig config;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (config.durationStat.visible)
        _NrcStatItem(
          icon: Icons.timer_outlined,
          value: data.durationText,
          color: config.durationStat.color,
        ),
      if (config.distanceStat.visible)
        _NrcStatItem(
          icon: null,
          value: data.distanceText,
          unit: 'KM',
          color: config.distanceStat.color,
          isCenter: true,
        ),
      if (config.paceStat.visible)
        _NrcStatItem(
          icon: Icons.speed_outlined,
          value: data.paceText,
          color: config.paceStat.color,
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.black.withValues(alpha: 0.55),
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _interleave(items),
      ),
    );
  }

  List<Widget> _interleave(List<Widget> items) {
    if (items.length <= 1) return items.map((e) => Expanded(child: e)).toList();
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(Expanded(child: items[i]));
      if (i < items.length - 1) {
        result.add(Container(
          width: 1,
          height: 28.h,
          color: Colors.white.withValues(alpha: 0.2),
        ));
      }
    }
    return result;
  }
}

// ── _NrcStatItem ─────────────────────────────────────────────────────────────

class _NrcStatItem extends StatelessWidget {
  const _NrcStatItem({
    required this.value,
    required this.color,
    this.icon,
    this.unit,
    this.isCenter = false,
  });

  final IconData? icon;
  final String value;
  final String? unit;
  final Color color;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: color.withValues(alpha: 0.8), size: 14.r),
          SizedBox(height: 3.h),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: isCenter ? 22.sp : 18.sp,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
                height: 1.0,
                shadows: const [
                  Shadow(color: Colors.black45, blurRadius: 6),
                ],
              ),
            ),
            if (unit != null) ...[
              SizedBox(width: 3.w),
              Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Text(
                  unit!,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
