import 'package:flutter/material.dart';

import 'stat_item_config.dart';

enum CardStyle {
  /// 개별 드래그/리사이즈/색상 자유 배치
  freestyle,

  /// NRC 스타일 — 하단 고정 바 (아이콘 + 값 + 단위)
  nrc,
}

/// 공유 카드 오버레이 전체 설정.
/// 각 스탯은 독립적 위치/크기/색상을 가짐.
class ShareOverlayConfig {
  const ShareOverlayConfig({
    required this.distanceStat,
    required this.durationStat,
    required this.paceStat,
    this.selectedStatId,
    this.cardStyle = CardStyle.freestyle,
  });

  final StatItemConfig distanceStat;
  final StatItemConfig durationStat;
  final StatItemConfig paceStat;

  /// 현재 선택된 스탯 id — 리사이즈 핸들/선택 테두리 표시 여부 결정.
  /// 저장 전 null로 초기화해 핸들이 이미지에 포함되지 않도록 함.
  final String? selectedStatId;

  final CardStyle cardStyle;

  List<StatItemConfig> get stats => [distanceStat, durationStat, paceStat];

  StatItemConfig getStat(String id) => switch (id) {
        'distance' => distanceStat,
        'duration' => durationStat,
        _ => paceStat,
      };

  /// 특정 stat을 교체한 새 config 반환
  ShareOverlayConfig updateStat(StatItemConfig updated) {
    return copyWith(
      distanceStat: updated.id == 'distance' ? updated : distanceStat,
      durationStat: updated.id == 'duration' ? updated : durationStat,
      paceStat: updated.id == 'pace' ? updated : paceStat,
    );
  }

  ShareOverlayConfig copyWith({
    StatItemConfig? distanceStat,
    StatItemConfig? durationStat,
    StatItemConfig? paceStat,
    Object? selectedStatId = _sentinel,
    CardStyle? cardStyle,
  }) {
    return ShareOverlayConfig(
      distanceStat: distanceStat ?? this.distanceStat,
      durationStat: durationStat ?? this.durationStat,
      paceStat: paceStat ?? this.paceStat,
      selectedStatId: selectedStatId == _sentinel
          ? this.selectedStatId
          : selectedStatId as String?,
      cardStyle: cardStyle ?? this.cardStyle,
    );
  }

  static const _sentinel = Object();

  // ── 기본 초기 설정 ───────────────────────────────────────────────────────────
  // 거리 → 중앙 큰 폰트 / 시간 → 좌하단 / 페이스 → 우하단
  static ShareOverlayConfig initial() => const ShareOverlayConfig(
        distanceStat: StatItemConfig(
          id: 'distance',
          dx: 0.5,
          dy: 0.5,
          fontSize: 52,
          color: Colors.white,
        ),
        durationStat: StatItemConfig(
          id: 'duration',
          dx: 0.22,
          dy: 0.82,
          fontSize: 26,
          color: Colors.white,
        ),
        paceStat: StatItemConfig(
          id: 'pace',
          dx: 0.78,
          dy: 0.82,
          fontSize: 26,
          color: Colors.white,
        ),
      );
}
