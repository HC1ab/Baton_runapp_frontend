import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/group_running/providers/run_location_provider.dart';

class GroupConnectionBadge extends StatelessWidget {
  const GroupConnectionBadge({super.key, required this.connectionState});

  final RunLocationConnectionState connectionState;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (connectionState) {
      RunLocationConnectionState.connected =>
        (Icons.wifi_rounded, const Color(0xFF34C759)),
      RunLocationConnectionState.connecting =>
        (Icons.wifi_tethering_rounded, const Color(0xFFFFCC00)),
      RunLocationConnectionState.error =>
        (Icons.wifi_off_rounded, const Color(0xFFFF3B30)),
      RunLocationConnectionState.idle =>
        (Icons.wifi_tethering_off_rounded, const Color(0xFFAAAAAA)),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18.r),
          SizedBox(width: 4.w),
          Text(
            switch (connectionState) {
              RunLocationConnectionState.connected => '연결됨',
              RunLocationConnectionState.connecting => '연결 중',
              RunLocationConnectionState.error => '연결 오류',
              RunLocationConnectionState.idle => '대기 중',
            },
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
