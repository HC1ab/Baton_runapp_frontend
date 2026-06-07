import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_routes.dart';
import '../providers/history_providers.dart';
import '../models/monthly_summary_model.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final runsAsync = ref.watch(myRunsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1F1A17)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Baton',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFFDD6A3E),
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFFDD6A3E),
              size: 26,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(monthlySummaryProvider);
            ref.invalidate(myRunsProvider);
          },
          color: const Color(0xFFDD6A3E),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              _buildTabSelector(),
              const SizedBox(height: 24),
              _buildMonthSelector(context, ref, selectedDate),
              const SizedBox(height: 16),
              summaryAsync.when(
                data: (summary) {
                  final runs = runsAsync.maybeWhen(
                    data: (r) => r,
                    orElse: () => <RunListItem>[],
                  );
                  return _buildSummaryContent(summary, runs);
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(
                        color: Color(0xFFDD6A3E)),
                  ),
                ),
                error: (err, stack) => _buildSummaryError(ref, err),
              ),
              const SizedBox(height: 28),
              _buildRecentActivitiesSection(context, ref, runsAsync),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab Selector ──────────────────────────────────────────────────────────

  Widget _buildTabSelector() {
    final tabs = ['Week', 'Month', 'Year', 'All'];
    const activeTab = 'Month';

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EBE6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = tab == activeTab;
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFDD6A3E)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                tab,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : const Color(0xFF8C857F),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Month Selector ────────────────────────────────────────────────────────

  Widget _buildMonthSelector(
      BuildContext context, WidgetRef ref, DateTime selectedDate) {
    final formattedDate = DateFormat('MMMM yyyy').format(selectedDate);

    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            final picked =
                await _showMonthYearPicker(context, selectedDate);
            if (picked != null) {
              ref.read(selectedDateProvider.notifier).changeDate(picked);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F1A17),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 28,
                color: Color(0xFF1F1A17),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<DateTime?> _showMonthYearPicker(
      BuildContext context, DateTime current) {
    int selectedYear = current.year;
    int selectedMonth = current.month;

    return showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '조회 기간 선택',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1A17),
            ),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: selectedYear,
                underline: const SizedBox.shrink(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1A17),
                ),
                items: List.generate(8, (i) => 2022 + i)
                    .map((y) => DropdownMenuItem(
                          value: y,
                          child: Text('$y년'),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedYear = v!),
              ),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: selectedMonth,
                underline: const SizedBox.shrink(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1A17),
                ),
                items: List.generate(12, (i) => i + 1)
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text('$m월'),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedMonth = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '취소',
                style: TextStyle(color: Color(0xFF8C857F)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                DateTime(selectedYear, selectedMonth),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  color: Color(0xFFDD6A3E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary Content ───────────────────────────────────────────────────────

  Widget _buildSummaryContent(
      MonthlySummaryModel summary, List<RunListItem> runs) {
    final totalSeconds =
        (summary.avgPaceSecPerKm * summary.totalDistanceKm).round();
    final durationText = _formatDuration(totalSeconds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          summary.totalDistanceKm.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F1A17),
            height: 1.1,
          ),
        ),
        const Text(
          'KILOMETERS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF8C857F),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(value: '${summary.totalRuns}', label: 'Runs'),
            _buildStatItem(value: summary.avgPaceText, label: 'Avg Pace'),
            _buildStatItem(value: durationText, label: 'Time'),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDD6A3E).withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: 160,
            child: _RunDistanceChart(runs: runs),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({required String value, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1A17),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8C857F),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryError(WidgetRef ref, Object err) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFC62828), size: 32),
          const SizedBox(height: 8),
          Text(
            '요약 정보를 가져오지 못했습니다.\n($err)',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.refresh(monthlySummaryProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDD6A3E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('다시 시도',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Recent Activities ─────────────────────────────────────────────────────

  Widget _buildRecentActivitiesSection(
      BuildContext context, WidgetRef ref, AsyncValue<List<RunListItem>> runsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activities',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1A17),
          ),
        ),
        const SizedBox(height: 16),
        runsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child:
                  CircularProgressIndicator(color: Color(0xFFDD6A3E)),
            ),
          ),
          error: (e, _) => _buildActivitiesError(ref),
          data: (runs) {
            if (runs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    '이번 달 러닝 기록이 없어요.',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF8C857F)),
                  ),
                ),
              );
            }
            // 최신순 정렬
            final sorted = [...runs]
              ..sort((a, b) => b.startTime.compareTo(a.startTime));
            return Column(
              children: sorted
                  .map((r) => _buildRunCard(context, r))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRunCard(BuildContext context, RunListItem run) {
    final dateLabel = DateFormat('MMM d, yyyy').format(run.startTime);
    final title = _runTitle(run.startTime);
    final distanceStr = run.totalDistanceKm.toStringAsFixed(2);

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.runDetail}/${run.runId}'),
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildRunIcon(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1A17),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8C857F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF3EDE9)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActivityStat(value: distanceStr, label: 'KM'),
              _buildActivityStat(value: run.avgPaceText, label: 'PACE'),
              _buildActivityStat(
                  value: _formatDuration(run.durationSeconds), label: 'TIME'),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildRunIcon() {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFFFEECE6),
        shape: BoxShape.circle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: CustomPaint(
          painter: _PathLinePainter(const Color(0xFFDD6A3E)),
        ),
      ),
    );
  }

  Widget _buildActivityStat(
      {required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1A17),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8C857F),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesError(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '러닝 목록을 불러오지 못했습니다.',
            style: TextStyle(
                color: Color(0xFFC62828), fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () => ref.invalidate(myRunsProvider),
            child: const Text('다시 시도',
                style: TextStyle(color: Color(0xFFDD6A3E))),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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

// ---------------------------------------------------------------------------
// Run Distance Bar Chart
// ---------------------------------------------------------------------------

class _RunDistanceChart extends StatelessWidget {
  const _RunDistanceChart({required this.runs});
  final List<RunListItem> runs;

  @override
  Widget build(BuildContext context) {
    if (runs.isEmpty) {
      return const Center(
        child: Text(
          '이번 달 러닝 기록이 없어요.',
          style: TextStyle(fontSize: 13, color: Color(0xFF8C857F)),
        ),
      );
    }

    // 최대 15개 표시 (최신순)
    final display = runs.length > 15
        ? runs.sublist(runs.length - 15)
        : runs;

    final maxDist =
        display.map((r) => r.totalDistanceKm).reduce(max);
    const maxBarHeight = 100.0;

    return Column(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: display.map((run) {
              final ratio = maxDist > 0
                  ? run.totalDistanceKm / maxDist
                  : 0.0;
              final barH =
                  (ratio * maxBarHeight).clamp(6.0, maxBarHeight);

              return Tooltip(
                message:
                    '${run.totalDistanceKm.toStringAsFixed(1)} km',
                child: Container(
                  width: 10,
                  height: barH,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDD6A3E),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF3EDE9)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: display
              .map((run) => Text(
                    '${run.startTime.day}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8C857F),
                      fontWeight: FontWeight.bold,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Path Icon Painter
// ---------------------------------------------------------------------------

class _PathLinePainter extends CustomPainter {
  const _PathLinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.1,
      size.width * 0.8,
      size.height * 0.5,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
