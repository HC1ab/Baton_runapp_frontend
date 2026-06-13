enum RelationStatus { none, pendingSent, pendingReceived, friend }

class MemberProfileModel {
  const MemberProfileModel({
    required this.memberId,
    required this.nickname,
    required this.level,
    required this.totalDistance,
    required this.avgPace,
    required this.equippedTitleName,
    required this.relationStatus,
  });

  final int memberId;
  final String nickname;
  final int level;
  final double totalDistance;
  final double avgPace;
  final String equippedTitleName;
  final RelationStatus relationStatus;

  /// 백엔드가 "분 단위 소수"로 내려주므로(예: 0.97 = 0.97분/km) 60을 곱해 총 초로 환산 후 분/초로 분해
  String get avgPaceText {
    if (avgPace <= 0) return "0'00\"";
    final totalSec = (avgPace * 60).round();
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }

  factory MemberProfileModel.fromJson(Map<String, dynamic> json) {
    return MemberProfileModel(
      memberId: (json['memberId'] as num? ?? 0).toInt(),
      nickname: (json['nickname'] ?? '') as String,
      level: (json['level'] as num? ?? 0).toInt(),
      totalDistance: (json['totalDistance'] as num? ?? 0.0).toDouble(),
      avgPace: (json['avgPace'] as num? ?? 0.0).toDouble(),
      equippedTitleName: (json['equippedTitleName'] ?? '') as String,
      relationStatus: _parseRelation(json['relationStatus'] as String?),
    );
  }

  static RelationStatus _parseRelation(String? raw) {
    switch (raw) {
      case 'PENDING_SENT':
        return RelationStatus.pendingSent;
      case 'PENDING_RECEIVED':
        return RelationStatus.pendingReceived;
      case 'FRIEND':
        return RelationStatus.friend;
      default:
        return RelationStatus.none;
    }
  }
}

/// GET /api/v1/profile/{memberId} 응답 — memberId로 조회하는 공개 프로필.
/// 점령자 닉네임/프로필 표시 등에 사용.
class MemberPublicProfile {
  const MemberPublicProfile({
    required this.memberId,
    required this.nickname,
    required this.level,
    required this.totalDistance,
    required this.avgPace,
    required this.equippedTitleName,
    required this.coreColorCode,
  });

  final int memberId;
  final String nickname;
  final int level;
  final double totalDistance;
  final double avgPace;
  final String equippedTitleName;
  final String coreColorCode;

  factory MemberPublicProfile.fromJson(Map<String, dynamic> json) {
    return MemberPublicProfile(
      memberId: (json['memberId'] as num? ?? 0).toInt(),
      nickname: (json['nickname'] ?? '') as String,
      level: (json['level'] as num? ?? 0).toInt(),
      totalDistance: (json['totalDistance'] as num? ?? 0.0).toDouble(),
      avgPace: (json['avgPace'] as num? ?? 0.0).toDouble(),
      equippedTitleName: (json['equippedTitleName'] ?? '') as String,
      coreColorCode: (json['coreColorCode'] ?? '') as String,
    );
  }
}
