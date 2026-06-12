import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/history_api.dart';
import '../models/monthly_summary_model.dart';
import '../models/run_detail_model.dart';

export '../data/history_api.dart' show RunListItem;
export '../models/run_detail_model.dart' show RunDetailModel, PathPoint;

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
/// 서버에 year/month 전달해 필터링 요청.
/// 서버가 파라미터를 무시할 경우를 대비해 클라이언트 필터 안전망 유지.
final myRunsProvider = FutureProvider<List<RunListItem>>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final api = ref.read(historyApiProvider);

  final runs = await api.getMyRuns(
    year: selectedDate.year,
    month: selectedDate.month,
  );
  return runs
      .where((r) =>
          r.startTime.year == selectedDate.year &&
          r.startTime.month == selectedDate.month)
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
});

/// GET /api/v1/runs/{runId} — 러닝 상세 (경로 포함)
final runDetailProvider =
    FutureProvider.family<RunDetailModel, int>((ref, runId) {
  return ref.read(historyApiProvider).getRunDetail(runId);
});

/// 내 전체 러닝 목록 (기간 필터 없음).
/// Activity 화면이 Week/Month/Year 버킷으로 클라이언트 집계할 때 사용.
final allRunsProvider = FutureProvider<List<RunListItem>>((ref) async {
  final api = ref.read(historyApiProvider);
  final all = await api.getMyRuns();
  return all..sort((a, b) => a.startTime.compareTo(b.startTime));
});

/// Activity 화면 기간 선택. 기본값 = month (리디자인 사양).
enum ActivityPeriod { week, month, year }

class ActivityPeriodNotifier extends Notifier<ActivityPeriod> {
  @override
  ActivityPeriod build() => ActivityPeriod.month;

  void select(ActivityPeriod period) => state = period;
}

final activityPeriodProvider =
    NotifierProvider<ActivityPeriodNotifier, ActivityPeriod>(
  ActivityPeriodNotifier.new,
);
