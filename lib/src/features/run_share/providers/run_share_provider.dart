import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/share_overlay_config.dart';

class RunShareNotifier extends Notifier<ShareOverlayConfig> {
  @override
  ShareOverlayConfig build() => ShareOverlayConfig.initial();

  // ── 선택 ──────────────────────────────────────────────────────────────────

  void selectStat(String? id) {
    state = state.copyWith(selectedStatId: id);
  }

  // ── 이동 (드래그 delta → 비율 누적) ──────────────────────────────────────

  void moveStat(String id, double dxFraction, double dyFraction) {
    final stat = state.getStat(id);
    state = state.updateStat(stat.copyWith(
      dx: (stat.dx + dxFraction).clamp(0.0, 1.0),
      dy: (stat.dy + dyFraction).clamp(0.0, 1.0),
    ));
  }

  // ── 크기 조절 (핸들 드래그 delta.dy — 위로 = 크게, 아래로 = 작게) ──────────

  void resizeStat(String id, double deltaY) {
    final stat = state.getStat(id);
    final newSize = (stat.fontSize - deltaY * 0.4).clamp(12.0, 96.0);
    state = state.updateStat(stat.copyWith(fontSize: newSize));
  }

  // ── 색상 ──────────────────────────────────────────────────────────────────

  void setStatColor(String id, Color color) {
    state = state.updateStat(state.getStat(id).copyWith(color: color));
  }

  // ── 표시 여부 ─────────────────────────────────────────────────────────────

  void toggleStat(String id) {
    final stat = state.getStat(id);
    state = state.updateStat(stat.copyWith(visible: !stat.visible));
  }
}

final runShareProvider =
    NotifierProvider<RunShareNotifier, ShareOverlayConfig>(
  RunShareNotifier.new,
);
