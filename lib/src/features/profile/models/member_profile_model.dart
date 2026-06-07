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

  String get avgPaceText {
    if (avgPace <= 0) return "0'00\"";
    final min = avgPace.truncate();
    final sec = ((avgPace * 100) % 100).round();
    return "$min'${sec.toString().padLeft(2, '0')}\"";
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
