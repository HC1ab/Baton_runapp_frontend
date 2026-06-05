import 'package:flutter/material.dart';

import '../services/title_service.dart';

/// 전체 칭호 목록 (하드코딩).
/// DB 실제 id와 1:1 대응 — README.html "칭호 목록" 섹션 참고.
///
/// id 1  : 새싹 러너  (기존 TITLE_001_START — 기본 지급 칭호)
/// id 2~9: 상점 구매 칭호 (TITLE_001 ~ TITLE_008)
abstract final class TitlePresets {
  // ── 데이터 ────────────────────────────────────────────────────────────────

  static const List<TitleInfo> all = [
    // 기본 칭호 (id:1, 기존 DB 데이터)
    TitleInfo(
      id: 1,
      name: '새싹 러너',
      titleCode: 'TITLE_001_START',
      rarity: 'NORMAL',
      expBonusRatio: 0.0,
      pointBonusRatio: 0.0,
      description: '새로운 출발과 함께 러닝이라는 재미를 느껴볼까? 당신의 열정이 너무 뜨거워!',
    ),
    // 상점 구매 칭호 (id:2~9)
    TitleInfo(
      id: 2,
      name: '런린이',
      titleCode: 'TITLE_001',
      rarity: 'NORMAL',
      expBonusRatio: 0.0,
      pointBonusRatio: 0.0,
      description: '처음 러닝을 시작한 당신! 가장 중요한 첫걸음을 뗐어요.',
    ),
    TitleInfo(
      id: 3,
      name: '새벽 러너',
      titleCode: 'TITLE_002',
      rarity: 'NORMAL',
      expBonusRatio: 0.0,
      pointBonusRatio: 0.0,
      description: '해가 뜨기 전부터 달리는 당신. 새벽의 고요함을 가장 먼저 깨우는 러너.',
    ),
    TitleInfo(
      id: 4,
      name: '꾸준한 발걸음',
      titleCode: 'TITLE_003',
      rarity: 'RARE',
      expBonusRatio: 0.0,
      pointBonusRatio: 0.0,
      description: '꾸준함이 실력이 된다. 매일매일 포기하지 않고 달리는 당신에게 주어지는 칭호.',
    ),
    TitleInfo(
      id: 5,
      name: '트랙 탐험가',
      titleCode: 'TITLE_004',
      rarity: 'RARE',
      expBonusRatio: 0.0,
      pointBonusRatio: 0.0,
      description: '다양한 코스를 탐험하며 도시 구석구석을 달리는 모험가.',
    ),
    TitleInfo(
      id: 6,
      name: '마라토너',
      titleCode: 'TITLE_005',
      rarity: 'EPIC',
      expBonusRatio: 0.0,
      pointBonusRatio: 0.0,
      description: '긴 거리도 두렵지 않아! 마라톤에 도전할 준비가 된 진정한 러너.',
    ),
    TitleInfo(
      id: 7,
      name: '스피드 킹',
      titleCode: 'TITLE_006',
      rarity: 'EPIC',
      expBonusRatio: 0.0,
      pointBonusRatio: 0.0,
      description: '빠른 페이스가 인상적인 당신. 속도에서만큼은 따라올 자가 없어요.',
    ),
    TitleInfo(
      id: 8,
      name: '전설의 러너',
      titleCode: 'TITLE_007',
      rarity: 'LEGENDARY',
      expBonusRatio: 0.0,
      pointBonusRatio: 0.0,
      description: '전설이 된 러너. 바통 앱에서 가장 빛나는 존재로 기억될 당신.',
    ),
    TitleInfo(
      id: 9,
      name: '바통 마스터',
      titleCode: 'TITLE_008',
      rarity: 'LEGENDARY',
      expBonusRatio: 0.0,
      pointBonusRatio: 0.0,
      description: '바통을 이어받아 가장 높은 경지에 오른 마스터. 이 칭호를 가진 이는 극소수뿐이에요.',
    ),
  ];

  // ── 디스플레이 헬퍼 ───────────────────────────────────────────────────────

  /// 칭호 코드 → 아이콘 (Material Icons 코드 기반).
  static IconData iconFor(String titleCode) => switch (titleCode) {
        'TITLE_001_START' => Icons.eco_rounded,
        'TITLE_001' => Icons.directions_run_rounded,
        'TITLE_002' => Icons.star_rounded,
        'TITLE_003' => Icons.trending_up_rounded,
        'TITLE_004' => Icons.explore_rounded,
        'TITLE_005' => Icons.emoji_events_rounded,
        'TITLE_006' => Icons.bolt_rounded,
        'TITLE_007' => Icons.auto_awesome_rounded,
        'TITLE_008' => Icons.workspace_premium_rounded,
        _ => Icons.military_tech_rounded,
      };

  /// 칭호 코드 → 표시 이름. 없는 코드면 null.
  static String? nameFor(String titleCode) {
    try {
      return all.firstWhere((t) => t.titleCode == titleCode).name;
    } catch (_) {
      return null;
    }
  }

  /// 칭호 코드 → 한 줄 서브텍스트.
  static String subtitleFor(String titleCode) => switch (titleCode) {
        'TITLE_001_START' => '러닝 앱 첫 시작',
        'TITLE_001' => '첫 러닝을 완주한 당신',
        'TITLE_002' => '새벽 전문 러너',
        'TITLE_003' => '꾸준함의 상징',
        'TITLE_004' => '루트 탐험 전문가',
        'TITLE_005' => '42.195km 완주',
        'TITLE_006' => '최고 속도 달성',
        'TITLE_007' => '레전드 러너',
        'TITLE_008' => '바통의 최고봉',
        _ => '',
      };
}
