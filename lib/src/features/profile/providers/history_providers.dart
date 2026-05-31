import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/history_api.dart';
import '../models/monthly_summary_model.dart';

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
