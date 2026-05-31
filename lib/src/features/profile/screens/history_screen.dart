import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/history_providers.dart';
import '../models/monthly_summary_model.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F6), // Warm background light style
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F1A17)),
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
          onRefresh: () => ref.refresh(monthlySummaryProvider.future),
          color: const Color(0xFFDD6A3E),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              // 1. Tab Selector (Week, Month, Year, All)
              _buildTabSelector(),
              const SizedBox(height: 24),

              // 2. Month Selector (e.g., May 2026)
              _buildMonthSelector(context, ref, selectedDate),
              const SizedBox(height: 16),

              // 3. API Response Summary Data mapping
              summaryAsync.when(
                data: (summary) => _buildSummaryContent(summary),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: Color(0xFFDD6A3E)),
                  ),
                ),
                error: (err, stack) => _buildErrorState(ref, err),
              ),
              const SizedBox(height: 28),

              // 4. Recent Activities section
              _buildRecentActivitiesSection(),
            ],
          ),
        ),
      ),
    );
  }

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
                color: isActive ? const Color(0xFFDD6A3E) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                tab,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF8C857F),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    final formattedDate = DateFormat('MMMM yyyy').format(selectedDate);

    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            // Show custom simple date picker for selecting year & month
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              initialDatePickerMode: DatePickerMode.year,
              helpText: '조회할 연도와 월을 선택하세요',
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFFDD6A3E),
                      onPrimary: Colors.white,
                      onSurface: Color(0xFF1F1A17),
                    ),
                  ),
                  child: child!,
                );
              },
            );
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

  Widget _buildSummaryContent(MonthlySummaryModel summary) {
    // Smartly compute duration from avgPaceSecPerKm * totalDistanceKm
    final totalSeconds = (summary.avgPaceSecPerKm * summary.totalDistanceKm).round();
    final durationText = _formatDuration(totalSeconds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total Distance
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

        // Sub summary stats grid
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
              value: '${summary.totalRuns}',
              label: 'Runs',
            ),
            _buildStatItem(
              value: summary.avgPaceText,
              label: 'Avg Pace',
            ),
            _buildStatItem(
              value: durationText,
              label: 'Time',
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Custom Bar Chart Card Container
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lightweight Custom Bar Graph
              SizedBox(
                height: 160,
                child: _CustomSummaryChart(totalRuns: summary.totalRuns),
              ),
            ],
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

  Widget _buildRecentActivitiesSection() {
    // 3 Mock running cards as shown in UI reference images
    final mockRuns = [
      _ActivityItem(
        dateLabel: 'May 21, 2026',
        title: 'Thursday Afternoon Run',
        distance: '10.00',
        pace: "5'31\"",
        time: '55:12',
        imageType: _ActivityImageType.map,
      ),
      _ActivityItem(
        dateLabel: 'May 17, 2026',
        title: 'Sunday Morning Run',
        distance: '5.00',
        pace: "5'05\"",
        time: '25:25',
        imageType: _ActivityImageType.phoneCourse,
      ),
      _ActivityItem(
        dateLabel: 'May 10, 2026',
        title: 'Sunday Morning Run',
        distance: '5.00',
        pace: "5'11\"",
        time: '25:54',
        imageType: _ActivityImageType.phoneGps,
      ),
    ];

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
        ...mockRuns.map((run) => _buildActivityCard(run)),
      ],
    );
  }

  Widget _buildActivityCard(_ActivityItem item) {
    return Container(
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
          // Upper Row: Illustration and Date description
          Row(
            children: [
              // Circular / Rectangular Frame Image
              _buildActivityIllustration(item.imageType),
              const SizedBox(width: 14),
              // Text Descriptions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.dateLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1A17),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
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

          // Lower Row: Stats values
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActivityStat(value: item.distance, label: 'KM'),
              _buildActivityStat(value: item.pace, label: 'PACE'),
              _buildActivityStat(value: item.time, label: 'TIME'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityIllustration(_ActivityImageType type) {
    // Generate beautiful custom vector shapes to mock the beautiful map/phone illustration
    Widget child;
    Color bg;

    switch (type) {
      case _ActivityImageType.map:
        bg = const Color(0xFFFEECE6);
        child = Stack(
          alignment: Alignment.center,
          children: [
            // Map roads grid
            Positioned(
              left: 4, right: 4, top: 12, height: 2,
              child: Container(color: Colors.white),
            ),
            Positioned(
              left: 12, right: 12, top: 28, height: 2,
              child: Container(color: Colors.white),
            ),
            Positioned(
              top: 4, bottom: 4, left: 16, width: 2,
              child: Container(color: Colors.white),
            ),
            // Map running path point
            CustomPaint(
              size: const Size(20, 20),
              painter: _PathLinePainter(const Color(0xFFDD6A3E)),
            ),
          ],
        );
        break;

      case _ActivityImageType.phoneCourse:
        bg = const Color(0xFFFFF3EC);
        child = Center(
          child: Container(
            width: 18,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFEBD9CC), width: 1.5),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 2, left: 2, right: 2, bottom: 2,
                  child: CustomPaint(
                    painter: _PathLinePainter(const Color(0xFFDD6A3E)),
                  ),
                ),
              ],
            ),
          ),
        );
        break;

      case _ActivityImageType.phoneGps:
        bg = const Color(0xFFF0F4FF);
        child = Center(
          child: Container(
            width: 18,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFD2DDFC), width: 1.5),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 2, left: 2, right: 2, bottom: 2,
                  child: CustomPaint(
                    painter: _PathLinePainter(Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),
        );
        break;
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: child,
      ),
    );
  }

  Widget _buildActivityStat({required String value, required String label}) {
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

  Widget _buildErrorState(WidgetRef ref, Object err) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828), size: 32),
          const SizedBox(height: 8),
          Text(
            '요약 정보를 가져오지 못했습니다.\n($err)',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.refresh(monthlySummaryProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDD6A3E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('다시 시도', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0:00:00';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    final mStr = m.toString().padLeft(2, '0');
    final sStr = s.toString().padLeft(2, '0');

    return '$h:$mStr:$sStr';
  }
}

enum _ActivityImageType { map, phoneCourse, phoneGps }

class _ActivityItem {
  const _ActivityItem({
    required this.dateLabel,
    required this.title,
    required this.distance,
    required this.pace,
    required this.time,
    required this.imageType,
  });

  final String dateLabel;
  final String title;
  final String distance;
  final String pace;
  final String time;
  final _ActivityImageType imageType;
}

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

/// A custom widget that draws a simple vertical bar chart representing days of the month.
class _CustomSummaryChart extends StatelessWidget {
  const _CustomSummaryChart({required this.totalRuns});
  final int totalRuns;

  @override
  Widget build(BuildContext context) {
    // Generate bars.
    // If totalRuns is 3, we draw 3 active bars. Otherwise, we can draw default active bars based on count.
    final numBars = 7;
    final activeIndexes = {2, 4, 5}; // Matches 10th, 17th, 24th representation roughly

    return Column(
      children: [
        // Chart bars
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(numBars, (index) {
              final isRunActive = totalRuns > 0 && activeIndexes.contains(index);
              final barHeight = isRunActive
                  ? (index == 5 ? 100.0 : 60.0) // May 24th bar is taller in the image
                  : 0.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 10,
                    height: barHeight > 0 ? barHeight : 8,
                    decoration: BoxDecoration(
                      color: isRunActive
                          ? const Color(0xFFDD6A3E)
                          : const Color(0xFFF3EDE9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF3EDE9)),
        const SizedBox(height: 6),
        // Chart labels (X Axis days representation)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('1', style: TextStyle(fontSize: 11, color: Color(0xFF8C857F), fontWeight: FontWeight.bold)),
            Text('3', style: TextStyle(fontSize: 11, color: Color(0xFF8C857F), fontWeight: FontWeight.bold)),
            Text('10', style: TextStyle(fontSize: 11, color: Color(0xFF8C857F), fontWeight: FontWeight.bold)),
            Text('17', style: TextStyle(fontSize: 11, color: Color(0xFF8C857F), fontWeight: FontWeight.bold)),
            Text('24', style: TextStyle(fontSize: 11, color: Color(0xFF8C857F), fontWeight: FontWeight.bold)),
            Text('31', style: TextStyle(fontSize: 11, color: Color(0xFF8C857F), fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
