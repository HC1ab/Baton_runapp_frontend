import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../running/models/run_path_point_model.dart';
import '../running/services/run_service.dart';

/// Mock implementation of RunServiceBase.
/// Swap in via ProviderScope overrides in main.dart when _isDev is true.
class MockRunService implements RunServiceBase {
  const MockRunService();

  @override
  Future<int> startRun({required String startTimeIsoLocal}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return 1; // Always returns runId = 1
  }

  @override
  Future<void> finishRun({
    required int runId,
    required String endTimeIsoLocal,
    required List<RunPathPoint> path,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}

final mockRunServiceProvider = Provider<RunServiceBase>((ref) {
  return const MockRunService();
});
