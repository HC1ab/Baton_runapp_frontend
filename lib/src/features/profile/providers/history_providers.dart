import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/history_api.dart';
import '../models/monthly_summary_model.dart';

export '../data/history_api.dart' show RunListItem;

/// Provider for HistoryApi using authenticated dioProvider
final historyApiProvider = Provider<HistoryApi>((ref) {
  return HistoryApi(ref.watch(dioProvider));
});

/// Notifier class for selected Year & Month.
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return DateTime.now();
  }

  void changeDate(DateTime newDate) {
    state = newDate;
  }
}

/// NotifierProvider for selecting the currently visible Year & Month.
/// Defaults to current year and month.
final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

/// FutureProvider that fetches MonthlySummary based on selectedDateProvider.
/// Automatically re-triggers API call when selectedDate changes.
final monthlySummaryProvider = FutureProvider<MonthlySummaryModel>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final api = ref.read(historyApiProvider);

  return api.getMonthlySummary(
    year: selectedDate.year,
    month: selectedDate.month,
  );
});

/// 선택된 연/월에 해당하는 러닝 목록.
/// 전체 목록을 받아 클라이언트에서 필터링 후 날짜 오름차순 정렬.
final myRunsProvider = FutureProvider<List<RunListItem>>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final api = ref.read(historyApiProvider);

  final all = await api.getMyRuns();
  return all
      .where((r) =>
          r.startTime.year == selectedDate.year &&
          r.startTime.month == selectedDate.month)
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
});
