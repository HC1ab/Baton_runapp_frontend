import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'stat_item_config.dart';

enum TagStyle { dark, light }

enum CardStyle {
  /// 자유1 — 개별 드래그/리사이즈/색상 자유 배치
  freestyle,

  /// 차지1 — 지도 스냅샷 배경 + 하단 고정 스탯 바
  chagi1,

  /// 자유2 — 자유 배치 두 번째 스타일
  free2,

  /// 차지2 — 상단 대형 거리 + 하단 페이스·시간
  chagi2,
}

/// 공유 카드 오버레이 전체 설정.
/// 각 스탯은 독립적 위치/크기/색상을 가짐.
class ShareOverlayConfig {
  const ShareOverlayConfig({
    required this.distanceStat,
    required this.durationStat,
    required this.paceStat,
    this.selectedStatId,
    this.cardStyle = CardStyle.chagi1,
    this.tagStyle = TagStyle.dark,
    this.showRoute = false,
    this.routeColor = AppColors.dAccent,
    this.routeStrokeWidth = 3.0,
    this.routeOffsetX = 0.5,
    this.routeOffsetY = 0.5,
    this.routeScale = 1.0,
    this.routeSelected = false,
  });

  final StatItemConfig distanceStat;
  final StatItemConfig durationStat;
  final StatItemConfig paceStat;

  /// 현재 선택된 스탯 id — 리사이즈 핸들/선택 테두리 표시 여부 결정.
  /// 저장 전 null로 초기화해 핸들이 이미지에 포함되지 않도록 함.
  final String? selectedStatId;

  final CardStyle cardStyle;
  final TagStyle tagStyle;

  /// 자유 배치 모드에서 글로우 경로 오버레이 표시 여부.
  final bool showRoute;

  /// 글로우 경로 색상.
  final Color routeColor;

  /// 글로우 경로 코어 라인 두께 (1.0 ~ 8.0).
  final double routeStrokeWidth;

  /// 글로우 경로 중심 위치 (캔버스 대비 비율 0~1).
  final double routeOffsetX;
  final double routeOffsetY;

  /// 글로우 경로 스케일 (0.2 ~ 2.0).
  final double routeScale;

  /// 글로우 경로 선택 상태.
  final bool routeSelected;

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
    TagStyle? tagStyle,
    bool? showRoute,
    Color? routeColor,
    double? routeStrokeWidth,
    double? routeOffsetX,
    double? routeOffsetY,
    double? routeScale,
    bool? routeSelected,
  }) {
    return ShareOverlayConfig(
      distanceStat: distanceStat ?? this.distanceStat,
      durationStat: durationStat ?? this.durationStat,
      paceStat: paceStat ?? this.paceStat,
      selectedStatId: selectedStatId == _sentinel
          ? this.selectedStatId
          : selectedStatId as String?,
      cardStyle: cardStyle ?? this.cardStyle,
      tagStyle: tagStyle ?? this.tagStyle,
      showRoute: showRoute ?? this.showRoute,
      routeColor: routeColor ?? this.routeColor,
      routeStrokeWidth: routeStrokeWidth ?? this.routeStrokeWidth,
      routeOffsetX: routeOffsetX ?? this.routeOffsetX,
      routeOffsetY: routeOffsetY ?? this.routeOffsetY,
      routeScale: routeScale ?? this.routeScale,
      routeSelected: routeSelected ?? this.routeSelected,
    );
  }

  static const _sentinel = Object();

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
