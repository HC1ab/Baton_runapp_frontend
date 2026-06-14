import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'stat_item_config.dart';

enum NrcBackground { dark, orange }

enum CardStyle {
  /// 개별 드래그/리사이즈/색상 자유 배치
  freestyle,

  /// NRC 스타일 — 아이콘 + 값, 개별 드래그 가능
  nrc,

  /// 한글 스타일 — 한글 레이블 위 + 큰 수치 아래, 세로 정렬
  korean,

  /// BATON1 — 지도 스냅샷 배경 + 하단 고정 스탯 바
  baton1,

  /// BATON2 — 상단 대형 거리 + 하단 페이스·시간
  baton2,

  /// BATON3 — 추후 추가 예정
  baton3,

  /// 히스토리 — 지도 스냅샷 배경 + 드래그 스탯 + 경로
  history,

  /// 다크 — 검정 단색 배경 + 경로 + 드래그 스탯
  dark,

  /// 오렌지 — 주황 단색 배경 + 경로 + 드래그 스탯
  orange,
}

/// 공유 카드 오버레이 전체 설정.
/// 각 스탯은 독립적 위치/크기/색상을 가짐.
class ShareOverlayConfig {
  const ShareOverlayConfig({
    required this.distanceStat,
    required this.durationStat,
    required this.paceStat,
    this.selectedStatId,
    this.cardStyle = CardStyle.baton1,
    this.showRoute = false,
    this.routeColor = AppColors.dAccent,
    this.routeStrokeWidth = 3.0,
    this.routeOffsetX = 0.5,
    this.routeOffsetY = 0.5,
    this.routeScale = 1.0,
    this.routeSelected = false,
    this.nrcBackground = NrcBackground.dark,
  });

  final StatItemConfig distanceStat;
  final StatItemConfig durationStat;
  final StatItemConfig paceStat;

  /// 현재 선택된 스탯 id — 리사이즈 핸들/선택 테두리 표시 여부 결정.
  /// 저장 전 null로 초기화해 핸들이 이미지에 포함되지 않도록 함.
  final String? selectedStatId;

  final CardStyle cardStyle;

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

  /// NRC 스타일 배경 테마 (dark: 검정, orange: 주황).
  final NrcBackground nrcBackground;

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
    bool? showRoute,
    Color? routeColor,
    double? routeStrokeWidth,
    double? routeOffsetX,
    double? routeOffsetY,
    double? routeScale,
    bool? routeSelected,
    NrcBackground? nrcBackground,
  }) {
    return ShareOverlayConfig(
      distanceStat: distanceStat ?? this.distanceStat,
      durationStat: durationStat ?? this.durationStat,
      paceStat: paceStat ?? this.paceStat,
      selectedStatId: selectedStatId == _sentinel
          ? this.selectedStatId
          : selectedStatId as String?,
      cardStyle: cardStyle ?? this.cardStyle,
      showRoute: showRoute ?? this.showRoute,
      routeColor: routeColor ?? this.routeColor,
      routeStrokeWidth: routeStrokeWidth ?? this.routeStrokeWidth,
      routeOffsetX: routeOffsetX ?? this.routeOffsetX,
      routeOffsetY: routeOffsetY ?? this.routeOffsetY,
      routeScale: routeScale ?? this.routeScale,
      routeSelected: routeSelected ?? this.routeSelected,
      nrcBackground: nrcBackground ?? this.nrcBackground,
    );
  }

  static const _sentinel = Object();

  // ── 기본 초기 설정 ───────────────────────────────────────────────────────────

  static ShareOverlayConfig initial() => const ShareOverlayConfig(
        cardStyle: CardStyle.dark,
        showRoute: true,
        distanceStat: _nrcDistanceStat,
        durationStat: _nrcDurationStat,
        paceStat: _nrcPaceStat,
      );

  /// NRC 스타일 초기 위치: 페이스/시간 위 행, 거리 아래 행
  static const _nrcDistanceStat = StatItemConfig(
    id: 'distance',
    dx: 0.28,
    dy: 0.91,
    fontSize: 52,
    color: Colors.white,
  );
  static const _nrcDurationStat = StatItemConfig(
    id: 'duration',
    dx: 0.72,
    dy: 0.79,
    fontSize: 22,
    color: Colors.white,
  );
  static const _nrcPaceStat = StatItemConfig(
    id: 'pace',
    dx: 0.25,
    dy: 0.79,
    fontSize: 22,
    color: Colors.white,
  );

  /// NRC 스타일로 전환 시 위치/크기를 NRC 기본값으로 리셋
  ShareOverlayConfig resetToNrc() => ShareOverlayConfig(
        distanceStat: _nrcDistanceStat.copyWith(color: distanceStat.color),
        durationStat: _nrcDurationStat.copyWith(color: durationStat.color),
        paceStat: _nrcPaceStat.copyWith(color: paceStat.color),
        cardStyle: CardStyle.nrc,
      );

  ShareOverlayConfig resetToDark() => ShareOverlayConfig(
        distanceStat: _nrcDistanceStat.copyWith(color: Colors.white),
        durationStat: _nrcDurationStat.copyWith(color: Colors.white),
        paceStat: _nrcPaceStat.copyWith(color: Colors.white),
        cardStyle: CardStyle.dark,
        showRoute: true,
        routeScale: 0.7,
        routeOffsetY: 0.35,
      );

  ShareOverlayConfig resetToOrange() => ShareOverlayConfig(
        distanceStat: _nrcDistanceStat.copyWith(color: Colors.white),
        durationStat: _nrcDurationStat.copyWith(color: Colors.white),
        paceStat: _nrcPaceStat.copyWith(color: Colors.white),
        cardStyle: CardStyle.orange,
        showRoute: true,
        routeColor: Colors.white,
        routeScale: 0.7,
        routeOffsetY: 0.35,
      );

  ShareOverlayConfig resetToHistory() => ShareOverlayConfig(
        distanceStat: _nrcDistanceStat.copyWith(color: Colors.white),
        durationStat: _nrcDurationStat.copyWith(color: Colors.white),
        paceStat: _nrcPaceStat.copyWith(color: Colors.white),
        cardStyle: CardStyle.history,
        showRoute: true,
      );

  /// freestyle 스타일로 전환 시 위치/크기를 freestyle 기본값으로 리셋
  ShareOverlayConfig resetToFreestyle() {
    final defaults = initial();
    return ShareOverlayConfig(
      distanceStat:
          defaults.distanceStat.copyWith(color: distanceStat.color),
      durationStat:
          defaults.durationStat.copyWith(color: durationStat.color),
      paceStat: defaults.paceStat.copyWith(color: paceStat.color),
      cardStyle: CardStyle.freestyle,
    );
  }

  /// 한글 스타일 초기 위치: 세로 중앙 3단 정렬
  static const _koreanDistanceStat = StatItemConfig(
    id: 'distance',
    dx: 0.5,
    dy: 0.28,
    fontSize: 48,
    color: Colors.white,
  );
  static const _koreanDurationStat = StatItemConfig(
    id: 'duration',
    dx: 0.5,
    dy: 0.52,
    fontSize: 40,
    color: Colors.white,
  );
  static const _koreanPaceStat = StatItemConfig(
    id: 'pace',
    dx: 0.5,
    dy: 0.76,
    fontSize: 40,
    color: Colors.white,
  );

  /// 한글 스타일로 전환 시 위치/크기를 한글 기본값으로 리셋 (색상 유지)
  ShareOverlayConfig resetToKorean() => ShareOverlayConfig(
        distanceStat: _koreanDistanceStat.copyWith(color: distanceStat.color),
        durationStat: _koreanDurationStat.copyWith(color: durationStat.color),
        paceStat: _koreanPaceStat.copyWith(color: paceStat.color),
        cardStyle: CardStyle.korean,
      );
}
