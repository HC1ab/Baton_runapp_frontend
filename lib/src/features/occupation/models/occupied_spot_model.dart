/// 점령된 스팟 — 점령 지도(BATON / 내 점령)에서 회색 원으로 표시.
///
/// 백엔드 계약(가정 — 확정 시 갱신 필요):
///   GET /api/v1/spots/occupied      → 모든 사용자의 점령 스팟
///   GET /api/v1/spots/occupied/me   → 내가 점령한 스팟
/// 각 항목 응답 필드:
///   { spotId, name, latitude, longitude,
///     occupierMemberId, occupierNickname, occupiedAt }
class OccupiedSpot {
  const OccupiedSpot({
    required this.spotId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.occupierMemberId,
    required this.occupierNickname,
    this.occupiedAt,
  });

  final int spotId;
  final String name;
  final double latitude;
  final double longitude;

  /// 현재 점령자 memberId
  final int occupierMemberId;

  /// 현재 점령자 닉네임
  final String occupierNickname;

  /// 점령된 시각 (서버가 안 주면 null)
  final DateTime? occupiedAt;

  factory OccupiedSpot.fromJson(Map<String, dynamic> json) {
    return OccupiedSpot(
      // spotId / id 둘 다 허용 (백엔드 명칭 확정 전 방어적 파싱)
      spotId: (json['spotId'] ?? json['id'] as num? ?? 0 as num).toInt(),
      name: (json['name'] ?? '').toString(),
      latitude: (json['latitude'] as num? ?? 0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0).toDouble(),
      occupierMemberId: (json['occupierMemberId'] as num? ?? 0).toInt(),
      occupierNickname:
          (json['occupierNickname'] ?? json['nickname'] ?? '').toString(),
      occupiedAt: _parseDate(json['occupiedAt'] ?? json['occupiedTime']),
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
