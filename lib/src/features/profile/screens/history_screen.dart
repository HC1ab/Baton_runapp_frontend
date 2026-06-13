import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../providers/history_providers.dart';

/// Activity dashboard — Week/Month/Year stats aggregated client-side from the
/// real run list, with an animated flex bar chart (redesign dark UI).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(activityPeriodProvider);
    final anchor = ref.watch(selectedDateProvider);
    final runsAsync = ref.watch(allRunsProvider);

    return Scaffold(
      backgroundColor: AppColors.dScreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.dAccent,
                backgroundColor: AppColors.dCard,
                onRefresh: () async => ref.invalidate(allRunsProvider),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(22.w, 14.h, 22.w, 32.h),
                  children: [
                    _buildPeriodSelector(ref, period),
                    SizedBox(height: 22.h),
                    runsAsync.when(
                      loading: () => _loadingBox(),
                      error: (e, _) => _errorBox(ref, e),
                      data: (runs) {
                        final data = _aggregate(period, anchor, runs);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPeriodLabel(context, ref, anchor, data),
                            SizedBox(height: 14.h),
                            _buildStatsCard(data),
                            SizedBox(height: 28.h),
                            _buildRecentActivities(context, runs),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 6.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.dText, size: 20.r),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          Text(
            'Baton',
            style: TextStyle(
              fontSize: 21.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.dAccent,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_none_rounded,
                color: AppColors.dText, size: 24.r),
          ),
        ],
      ),
    );
  }

  // ── Period selector ───────────────────────────────────────────────────────

  Widget _buildPeriodSelector(WidgetRef ref, ActivityPeriod period) {
    const items = [
      (ActivityPeriod.week, 'Week'),
      (ActivityPeriod.month, 'Month'),
      (ActivityPeriod.year, 'Year'),
    ];

    return Container(
      padding: EdgeInsets.all(5.r),
      decoration: BoxDecoration(
        color: AppColors.dCard,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppColors.dLine, width: 1),
      ),
      child: Row(
        children: items.map((it) {
          final selected = period == it.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(activityPeriodProvider.notifier).select(it.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: selected ? AppColors.dAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  it.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? const Color(0xFF160D06) : AppColors.dMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Period label ──────────────────────────────────────────────────────────

  Widget _buildPeriodLabel(BuildContext context, WidgetRef ref,
      DateTime anchor, _ActivityData data) {
    return GestureDetector(
      onTap: () async {
        final picked = await _showMonthYearPicker(context, anchor);
        if (picked != null) {
          ref.read(selectedDateProvider.notifier).changeDate(picked);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.periodLabel,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.dText,
            ),
          ),
          SizedBox(width: 4.w),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 26.r, color: AppColors.dMuted),
        ],
      ),
    );
  }

  // ── Stats card ──────────────────────────────────────────────────────────

  Widget _buildStatsCard(_ActivityData data) {
    return Container(
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: AppColors.dCard,
        borderRadius: BorderRadius.circular(26.r),
        border: Border.all(color: AppColors.dLine, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KILOMETERS',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.dFaint,
              letterSpacing: 1.6,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                data.totalKm.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 56.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dText,
                  height: 1.0,
                ),
              ),
              SizedBox(width: 6.w),
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
                  'km',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dMuted,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              _statCell('${data.runs}', 'Runs'),
              _statDivider(),
              _statCell(data.avgPaceText, 'Avg Pace'),
              _statDivider(),
              _statCell(data.timeText, 'Time'),
            ],
          ),
          SizedBox(height: 24.h),
          _ActivityBarChart(
            bars: data.bars,
            labels: data.axisLabels,
            highlightIndex: data.highlightIndex,
            showDividers: data.showDividers,
          ),
        ],
      ),
    );
  }

  Widget _statCell(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 19.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.dText,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.dFaint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 34.h,
      color: AppColors.dLine,
      margin: EdgeInsets.symmetric(horizontal: 14.w),
    );
  }

  // ── Recent activities ─────────────────────────────────────────────────────

  Widget _buildRecentActivities(BuildContext context, List<RunListItem> runs) {
    final sorted = [...runs]
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final recent = sorted.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activities',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.dText,
          ),
        ),
        SizedBox(height: 14.h),
        if (recent.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 28.h),
            child: Center(
              child: Text(
                '러닝 기록이 없어요.',
                style: TextStyle(fontSize: 14.sp, color: AppColors.dMuted),
              ),
            ),
          )
        else
          ...recent.map((r) => _buildActivityCard(context, r)),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context, RunListItem run) {
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.runDetail}/${run.runId}'),
      child: Container(
        margin: EdgeInsets.only(bottom: 13.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppColors.dCard,
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(color: AppColors.dLine, width: 1),
        ),
        child: Row(
          children: [
            // route thumbnail
            Container(
              width: 50.r,
              height: 50.r,
              decoration: BoxDecoration(
                color: AppColors.dCard2,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: CustomPaint(painter: _RouteThumbPainter()),
            ),
            SizedBox(width: 11.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _runTitle(run.startTime),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dText,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        DateFormat('MMM d').format(run.startTime),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dFaint,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        _miniStat(
                            run.totalDistanceKm.toStringAsFixed(2), 'KM'),
                        SizedBox(width: 12.w),
                        _miniStat(run.avgPaceText, 'PACE'),
                        SizedBox(width: 12.w),
                        _miniStat(
                            _formatDuration(run.durationSeconds), 'TIME'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right_rounded,
                size: 20.r, color: AppColors.dFaint),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String value, String unit) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.dText,
          ),
        ),
        SizedBox(width: 3.w),
        Text(
          unit,
          style: TextStyle(
            fontSize: 9.5.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.dFaint,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ── States ────────────────────────────────────────────────────────────────

  Widget _loadingBox() => Padding(
        padding: EdgeInsets.symmetric(vertical: 60.h),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.dAccent),
        ),
      );

  Widget _errorBox(WidgetRef ref, Object e) => Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.dCard,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.dLine),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded,
                color: AppColors.dRouteEnd, size: 32.r),
            SizedBox(height: 8.h),
            Text(
              '활동 정보를 가져오지 못했어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.dMuted, fontSize: 13.sp),
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: () => ref.invalidate(allRunsProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );

  // ── Month/Year picker ──────────────────────────────────────────────────────

  Future<DateTime?> _showMonthYearPicker(
      BuildContext context, DateTime current) {
    int selectedYear = current.year;
    int selectedMonth = current.month;

    return showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.dCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            '조회 기간 선택',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.dText,
            ),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: selectedYear,
                dropdownColor: AppColors.dCard2,
                underline: const SizedBox.shrink(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dText,
                ),
                items: List.generate(8, (i) => 2022 + i)
                    .map((y) =>
                        DropdownMenuItem(value: y, child: Text('$y년')))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedYear = v!),
              ),
              SizedBox(width: 12.w),
              DropdownButton<int>(
                value: selectedMonth,
                dropdownColor: AppColors.dCard2,
                underline: const SizedBox.shrink(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dText,
                ),
                items: List.generate(12, (i) => i + 1)
                    .map((m) =>
                        DropdownMenuItem(value: m, child: Text('$m월')))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedMonth = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소',
                  style: TextStyle(color: AppColors.dMuted)),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, DateTime(selectedYear, selectedMonth)),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _runTitle(DateTime time) {
    final hour = time.hour;
    final dayName = DateFormat('EEEE').format(time);
    if (hour < 12) return '$dayName Morning Run';
    if (hour < 17) return '$dayName Afternoon Run';
    return '$dayName Evening Run';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0:00:00';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ===========================================================================
// Aggregation — Week / Month / Year buckets from the real run list
// ===========================================================================

class _ActivityData {
  const _ActivityData({
    required this.bars,
    required this.axisLabels,
    required this.highlightIndex,
    required this.showDividers,
    required this.totalKm,
    required this.runs,
    required this.avgPaceText,
    required this.timeText,
    required this.periodLabel,
  });

  final List<double> bars;
  final List<String> axisLabels;
  final int highlightIndex;
  final bool showDividers;
  final double totalKm;
  final int runs;
  final String avgPaceText;
  final String timeText;
  final String periodLabel;
}

_ActivityData _aggregate(
    ActivityPeriod period, DateTime anchor, List<RunListItem> all) {
  final List<double> bars;
  final List<String> labels;
  final periodRuns = <RunListItem>[];
  bool showDividers = false;
  String periodLabel;

  switch (period) {
    case ActivityPeriod.week:
      final base = DateTime(anchor.year, anchor.month, anchor.day);
      final monday = base.subtract(Duration(days: base.weekday - 1));
      bars = List.filled(7, 0.0);
      for (final run in all) {
        final d = DateTime(
            run.startTime.year, run.startTime.month, run.startTime.day);
        final idx = d.difference(monday).inDays;
        if (idx >= 0 && idx < 7) {
          bars[idx] += run.totalDistanceKm;
          periodRuns.add(run);
        }
      }
      labels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final sunday = monday.add(const Duration(days: 6));
      periodLabel = monday.month == sunday.month
          ? '${DateFormat('MMM d').format(monday)} – ${sunday.day}'
          : '${DateFormat('MMM d').format(monday)} – ${DateFormat('MMM d').format(sunday)}';

    case ActivityPeriod.month:
      final daysInMonth = DateUtils.getDaysInMonth(anchor.year, anchor.month);
      final weeks = (daysInMonth / 7).ceil();
      bars = List.filled(weeks, 0.0);
      for (final run in all) {
        if (run.startTime.year == anchor.year &&
            run.startTime.month == anchor.month) {
          final idx = ((run.startTime.day - 1) ~/ 7).clamp(0, weeks - 1);
          bars[idx] += run.totalDistanceKm;
          periodRuns.add(run);
        }
      }
      labels = List.generate(weeks, (i) => 'W${i + 1}');
      showDividers = true;
      periodLabel = DateFormat('MMMM yyyy').format(anchor);

    case ActivityPeriod.year:
      bars = List.filled(12, 0.0);
      for (final run in all) {
        if (run.startTime.year == anchor.year) {
          bars[run.startTime.month - 1] += run.totalDistanceKm;
          periodRuns.add(run);
        }
      }
      labels = const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      periodLabel = '${anchor.year}';
  }

  final totalKm = periodRuns.fold(0.0, (p, r) => p + r.totalDistanceKm);
  final totalTime = periodRuns.fold(0, (p, r) => p + r.durationSeconds);
  final avgPaceSec = totalKm > 0 ? (totalTime / totalKm).round() : 0;

  // highlight = bucket with the max value
  int highlight = -1;
  double maxV = 0;
  for (var i = 0; i < bars.length; i++) {
    if (bars[i] > maxV) {
      maxV = bars[i];
      highlight = i;
    }
  }

  return _ActivityData(
    bars: bars,
    axisLabels: labels,
    highlightIndex: highlight,
    showDividers: showDividers,
    totalKm: totalKm,
    runs: periodRuns.length,
    avgPaceText: _paceText(avgPaceSec),
    timeText: _durationText(totalTime),
    periodLabel: periodLabel,
  );
}

String _paceText(int secPerKm) {
  if (secPerKm <= 0) return "--'--\"";
  final m = secPerKm ~/ 60;
  final s = secPerKm % 60;
  return "$m'${s.toString().padLeft(2, '0')}\"";
}

String _durationText(int seconds) {
  if (seconds <= 0) return '0:00:00';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

// ===========================================================================
// Bar chart — equal-width flex columns, animated heights, zero stubs
// ===========================================================================

class _ActivityBarChart extends StatelessWidget {
  const _ActivityBarChart({
    required this.bars,
    required this.labels,
    required this.highlightIndex,
    required this.showDividers,
  });

  final List<double> bars;
  final List<String> labels;
  final int highlightIndex;
  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    final maxV = bars.fold(0.0, (p, e) => e > p ? e : p);
    final chartH = 96.h;

    return Column(
      children: [
        SizedBox(
          height: chartH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(bars.length, (i) {
              final v = bars[i];
              final isZero = v <= 0;
              final ratio = maxV > 0 ? (v / maxV) : 0.0;
              final h = isZero
                  ? chartH * 0.04
                  : (ratio * chartH).clamp(chartH * 0.06, chartH);

              return Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: showDividers && i < bars.length - 1
                        ? Border(
                            right: BorderSide(color: AppColors.dLine, width: 1),
                          )
                        : null,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 420),
                      curve: const Cubic(0.2, 0.8, 0.2, 1),
                      width: 16.w,
                      height: h,
                      decoration: BoxDecoration(
                        gradient: isZero
                            ? null
                            : const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.dAccentBright,
                                  AppColors.dAccent,
                                ],
                              ),
                        color: isZero
                            ? Colors.white.withValues(alpha: 0.07)
                            : null,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                          bottom: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Container(height: 1, color: AppColors.dLine),
        SizedBox(height: 8.h),
        Row(
          children: List.generate(labels.length, (i) {
            final highlighted = i == highlightIndex;
            return Expanded(
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
                  color: highlighted ? AppColors.dAccent : AppColors.dFaint,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ===========================================================================
// Route thumbnail painter — mini map line with start/end dots
// ===========================================================================

class _RouteThumbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.dAccent
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.12,
        size.width * 0.78,
        size.height * 0.40,
      );
    canvas.drawPath(path, line);

    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.72),
      2.8,
      Paint()..color = AppColors.dRouteStart,
    );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.40),
      2.8,
      Paint()..color = AppColors.dRouteEnd,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
