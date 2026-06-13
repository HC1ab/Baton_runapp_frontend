import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/share_overlay_config.dart';
import '../models/stat_item_config.dart';
export '../models/share_overlay_config.dart' show CardStyle;

class RunShareNotifier extends Notifier<ShareOverlayConfig> {
  @override
  ShareOverlayConfig build() => ShareOverlayConfig.initial();

  // ── 선택 ──────────────────────────────────────────────────────────────────

  void selectStat(String? id) {
    state = state.copyWith(selectedStatId: id, routeSelected: false);
  }

  void selectRoute() {
    state = state.copyWith(
      routeSelected: !state.routeSelected,
      selectedStatId: null,
    );
  }

  // ── 이동 ──────────────────────────────────────────────────────────────────

  void moveStat(String id, double dxFraction, double dyFraction) {
    final stat = state.getStat(id);
    state = state.updateStat(stat.copyWith(
      dx: (stat.dx + dxFraction).clamp(0.0, 1.0),
      dy: (stat.dy + dyFraction).clamp(0.0, 1.0),
    ));
  }

  // ── 크기 조절 ──────────────────────────────────────────────────────────────

  void resizeStat(String id, double deltaY) {
    final stat = state.getStat(id);
    final newSize = (stat.fontSize - deltaY * 0.4).clamp(12.0, 96.0);
    state = state.updateStat(stat.copyWith(fontSize: newSize));
  }

  // ── 색상 ──────────────────────────────────────────────────────────────────

  void setStatColor(String id, Color color) {
    state = state.updateStat(state.getStat(id).copyWith(color: color));
  }

  // ── 카드 스타일 전환 ──────────────────────────────────────────────────────

  void setCardStyle(CardStyle style) {
    switch (style) {
      case CardStyle.freestyle:
        // 자유 1 초기 배치
        state = state.copyWith(
          cardStyle: style,
          selectedStatId: null,
          distanceStat: const StatItemConfig(
              id: 'distance', dx: 0.5, dy: 0.5, fontSize: 52, color: Colors.white),
          durationStat: const StatItemConfig(
              id: 'duration', dx: 0.22, dy: 0.82, fontSize: 26, color: Colors.white),
          paceStat: const StatItemConfig(
              id: 'pace', dx: 0.78, dy: 0.82, fontSize: 26, color: Colors.white),
        );
      case CardStyle.baton2:
        // 자유 2 초기 배치: 상단 대형 거리 + 하단 페이스·시간
        state = state.copyWith(
          cardStyle: style,
          selectedStatId: null,
          distanceStat: const StatItemConfig(
              id: 'distance', dx: 0.30, dy: 0.21, fontSize: 72, color: Colors.white),
          durationStat: const StatItemConfig(
              id: 'duration', dx: 0.58, dy: 0.87, fontSize: 22, color: Colors.white),
          paceStat: const StatItemConfig(
              id: 'pace', dx: 0.20, dy: 0.87, fontSize: 22, color: Colors.white),
        );
      default:
        state = state.copyWith(cardStyle: style, selectedStatId: null);
    }
  }

  // ── 표시 여부 ─────────────────────────────────────────────────────────────

  void toggleStat(String id) {
    final stat = state.getStat(id);
    state = state.updateStat(stat.copyWith(visible: !stat.visible));
  }

  void toggleRoute() {
    state = state.copyWith(showRoute: !state.showRoute, routeSelected: false);
  }

  void setRouteColor(Color color) {
    state = state.copyWith(routeColor: color);
  }

  void setRouteStrokeWidth(double width) {
    state = state.copyWith(routeStrokeWidth: width.clamp(1.0, 8.0));
  }

  void moveRoute(double dxFraction, double dyFraction) {
    state = state.copyWith(
      routeOffsetX: (state.routeOffsetX + dxFraction).clamp(0.0, 1.0),
      routeOffsetY: (state.routeOffsetY + dyFraction).clamp(0.0, 1.0),
    );
  }

  void scaleRoute(double deltaY) {
    final newScale = (state.routeScale - deltaY * 0.004).clamp(0.2, 2.0);
    state = state.copyWith(routeScale: newScale);
  }
}

final runShareProvider =
    NotifierProvider<RunShareNotifier, ShareOverlayConfig>(
  RunShareNotifier.new,
);
