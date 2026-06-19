import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../models/lap_record_model.dart';
import '../../models/run_record_model.dart';

class RunningInfoPanel extends StatelessWidget {
  const RunningInfoPanel({
    super.key,
    required this.record,
    required this.onClose,
    required this.onStart,
    required this.onFinish,
  });

  final RunRecordModel record;
  final VoidCallback onClose;
  final VoidCallback onStart;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isRunning = record.isRunning;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          onClose();
        }
      },
      child: Container(
        color: const Color(0xF5141416),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 닫기 핸들 ──────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: 8.h,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: onClose,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.dMuted,
                      size: 28.r,
                    ),
                  ),
                ),
              ),

              // ── 거리 블록 (중앙 정렬) ───────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  12.h,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      isRunning
                          ? (record.distanceMeters / 1000).toStringAsFixed(2)
                          : '--',
                      style: TextStyle(
                        fontSize: 72.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0,
                        letterSpacing: -2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '킬로미터',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.dMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 28.h),

              // ── 페이스 · 시간 · 스팟 3열 ────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Row(
                  children: [
                    _MetricCell(
                      icon: Icons.double_arrow_rounded,
                      value: isRunning ? record.formattedCurrentPace : "--'--\"",
                      label: '현재 페이스',
                    ),
                    _VertDivider(),
                    _MetricCell(
                      icon: Icons.timer_outlined,
                      value: isRunning ? _fmt(record.duration) : '--:--',
                      label: '시간',
                    ),
                    _VertDivider(),
                    _MetricCell(
                      icon: Icons.location_on_outlined,
                      value: isRunning
                          ? '${record.checkedInSpotIds.length}'
                          : '0',
                      label: '스팟',
                    ),
                  ],
                ),
              ),

              SizedBox(height: 28.h),

              // ── 구분선 ─────────────────────────────────────────────────────
              Divider(color: AppColors.dLine, height: 1, thickness: 1),

              // ── 랩 목록 ────────────────────────────────────────────────────
              Expanded(
                child: record.laps.isEmpty
                    ? Center(
                        child: Text(
                          '아직 완료된 랩이 없어요',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.dMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.screenHorizontal,
                          12.h,
                          AppSpacing.screenHorizontal,
                          16.h,
                        ),
                        itemCount: record.laps.length,
                        separatorBuilder: (_, __) => Divider(
                          color: AppColors.dLine,
                          height: 1,
                          thickness: 1,
                        ),
                        itemBuilder: (_, i) {
                          final lap = record.laps[record.laps.length - 1 - i];
                          return _LapRow(lap: lap);
                        },
                      ),
              ),

              // ── 시작 / 종료 버튼 ────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  12.h,
                  AppSpacing.screenHorizontal,
                  bottomPadding + 20.h,
                ),
                child: Center(
                  child: isRunning
                      ? _ActionButton(
                          icon: Icons.stop_rounded,
                          label: '종료',
                          color: AppColors.dRouteEnd,
                          onTap: onFinish,
                        )
                      : _ActionButton(
                          icon: Icons.play_arrow_rounded,
                          label: '시작',
                          color: AppColors.dAccent,
                          onTap: onStart,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

// ── 3열 메트릭 셀 ──────────────────────────────────────────────────────────────

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.r, color: AppColors.dMuted),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.dMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48.h,
      color: AppColors.dLine,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
    );
  }
}

// ── 랩 행 ─────────────────────────────────────────────────────────────────────

class _LapRow extends StatelessWidget {
  const _LapRow({required this.lap});
  final LapRecord lap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          SizedBox(
            width: 32.w,
            child: Text(
              '${lap.lapNumber}',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.dMuted,
              ),
            ),
          ),
          Text(
            '${(lap.distanceMeters / 1000).toStringAsFixed(2)} km',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const Spacer(),
          Text(
            lap.formattedDuration,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(width: 16.w),
          SizedBox(
            width: 56.w,
            child: Text(
              lap.formattedPace,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.dMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 시작/종료 액션 버튼 ────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 36.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(50.r),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22.r),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
