import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';

/// Developer-only "Mock Runner" panel for simulating GPS movement.
/// Glass dark card (redesign). Only rendered when _isDev is true.
class RunningMockPanel extends StatelessWidget {
  const RunningMockPanel({
    super.key,
    required this.stepMeters,
    required this.isAutoWalk,
    required this.isBusy,
    required this.onChangeStep,
    required this.onToggleAutoWalk,
    required this.onNudge,
  });

  final double stepMeters;
  final bool isAutoWalk;
  final bool isBusy;
  final ValueChanged<double> onChangeStep;
  final VoidCallback onToggleAutoWalk;
  final VoidCallback onNudge;

  // pace label helper: stepMeters is m/s → pace = 60 / (m/s * 3.6)
  String _paceLabel(double ms) {
    if (ms <= 0) return '--';
    final pace = 60 / (ms * 3.6);
    final min = pace.floor();
    final sec = ((pace - min) * 60).round();
    return "$min'${sec.toString().padLeft(2, '0')}\"";
  }

  static const _paces = <(double, String)>[
    (2.77, "6'00"),
    (3.33, "5'00"),
    (4.16, "4'00"),
    (5.55, "3'00"),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: const Color(0xBC28282B), // card-2 @ 0.74
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppColors.dAccent.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      color: AppColors.dAccentBright,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.dAccentBright.withValues(alpha: 0.7),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Mock Runner',
                    style: TextStyle(
                      fontSize: 15.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dAccentBright,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Text(
                '속도 ${stepMeters.toStringAsFixed(2)} m/s · ${_paceLabel(stepMeters)} /km',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dMuted,
                ),
              ),
              SizedBox(height: 11.h),

              // Pace selector — 4-up
              Row(
                children: [
                  for (var i = 0; i < _paces.length; i++) ...[
                    if (i > 0) SizedBox(width: 7.w),
                    Expanded(
                      child: _PaceButton(
                        label: _paces[i].$2,
                        active: stepMeters == _paces[i].$1,
                        onTap: isBusy ? null : () => onChangeStep(_paces[i].$1),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 11.h),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: isBusy ? null : onToggleAutoWalk,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: isAutoWalk
                              ? AppColors.dRouteEnd
                              : AppColors.dAccent,
                          borderRadius: BorderRadius.circular(13.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isAutoWalk
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 18.r,
                              color: isAutoWalk
                                  ? Colors.white
                                  : const Color(0xFF1A0E06),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              isAutoWalk ? '중단' : '자동 이동',
                              style: TextStyle(
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w800,
                                color: isAutoWalk
                                    ? Colors.white
                                    : const Color(0xFF1A0E06),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: isBusy ? null : onNudge,
                    child: Container(
                      width: 46.r,
                      height: 46.r,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(13.r),
                        border: Border.all(color: AppColors.dLine2, width: 1),
                      ),
                      child: Icon(Icons.north_rounded,
                          size: 19.r, color: AppColors.dText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaceButton extends StatelessWidget {
  const _PaceButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 9.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? AppColors.dAccent
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(11.r),
          border: active
              ? null
              : Border.all(color: AppColors.dLine2, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
            color: active ? const Color(0xFF1A0E06) : AppColors.dMuted,
          ),
        ),
      ),
    );
  }
}
