import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/run_share_data.dart';
import '../models/share_overlay_config.dart';

/// NRC 스타일 고정 하단 스탯 바.
///
/// 레이아웃:
///   페이스값  │  시간값
///   평균 페이스   총 시간
///   8.4  km  (큰 거리)
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
    const textColor = Colors.white;
    final mutedColor = Colors.white.withValues(alpha: 0.60);
    final dividerColor = Colors.white.withValues(alpha: 0.30);

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 22.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 페이스 │ 시간 ─────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 페이스
              if (config.paceStat.visible)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.paceText,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      '평균 페이스',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              if (config.paceStat.visible && config.durationStat.visible) ...[
                SizedBox(width: 16.w),
                Container(width: 1, height: 36.h, color: dividerColor),
                SizedBox(width: 16.w),
              ],
              // 총 시간
              if (config.durationStat.visible)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.durationShortText,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      '총 시간',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── 큰 거리 ─────────────────────────────────────────────────────
          if (config.distanceStat.visible) ...[
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  data.distanceShortText,
                  style: TextStyle(
                    fontSize: 54.sp,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    height: 1.0,
                    letterSpacing: -1.0,
                  ),
                ),
                SizedBox(width: 6.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text(
                    'km',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
