import '../services/title_service.dart';

/// 하드코딩 칭호 8개.
/// 백엔드 admin이 동일 순서로 추가 → DB id 1~8 보장.
/// README.html "칭호 목록" 섹션과 1:1 대응.
abstract final class TitlePresets {
  static const List<TitleInfo> all = [
    TitleInfo(
      id: 1,
      name: '런린이',
      titleCode: 'TITLE_001',
      rarity: 'NORMAL',
      description: '처음 러닝을 시작한 당신! 가장 중요한 첫걸음을 뗐어요.',
    ),
    TitleInfo(
      id: 2,
      name: '새벽 러너',
      titleCode: 'TITLE_002',
      rarity: 'NORMAL',
      description: '해가 뜨기 전부터 달리는 당신. 새벽의 고요함을 가장 먼저 깨우는 러너.',
    ),
    TitleInfo(
      id: 3,
      name: '꾸준한 발걸음',
      titleCode: 'TITLE_003',
      rarity: 'RARE',
      description: '꾸준함이 실력이 된다. 매일매일 포기하지 않고 달리는 당신에게 주어지는 칭호.',
    ),
    TitleInfo(
      id: 4,
      name: '트랙 탐험가',
      titleCode: 'TITLE_004',
      rarity: 'RARE',
      description: '다양한 코스를 탐험하며 도시 구석구석을 달리는 모험가.',
    ),
    TitleInfo(
      id: 5,
      name: '마라토너',
      titleCode: 'TITLE_005',
      rarity: 'EPIC',
      description: '긴 거리도 두렵지 않아! 마라톤에 도전할 준비가 된 진정한 러너.',
    ),
    TitleInfo(
      id: 6,
      name: '스피드 킹',
      titleCode: 'TITLE_006',
      rarity: 'EPIC',
      description: '빠른 페이스가 인상적인 당신. 속도에서만큼은 따라올 자가 없어요.',
    ),
    TitleInfo(
      id: 7,
      name: '전설의 러너',
      titleCode: 'TITLE_007',
      rarity: 'LEGENDARY',
      description: '전설이 된 러너. 바통 앱에서 가장 빛나는 존재로 기억될 당신.',
    ),
    TitleInfo(
      id: 8,
      name: '바통 마스터',
      titleCode: 'TITLE_008',
      rarity: 'LEGENDARY',
      description: '바통을 이어받아 가장 높은 경지에 오른 마스터. 이 칭호를 가진 이는 극소수뿐이에요.',
    ),
  ];
}
