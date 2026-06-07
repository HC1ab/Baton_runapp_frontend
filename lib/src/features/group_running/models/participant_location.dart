/// Real-time location of a group run participant.
class ParticipantLocation {
  const ParticipantLocation({
    required this.memberId,
    required this.latitude,
    required this.longitude,
    this.nickname,
    this.titleName,
    this.coreColorCode,
    this.updatedAt,
  });

  final int memberId;
  final double latitude;
  final double longitude;
  final String? nickname;
  final String? titleName;
  final String? coreColorCode;
  final DateTime? updatedAt;

  factory ParticipantLocation.fromJson(Map<String, dynamic> json) {
    final memberId = _readInt(json['memberId'] ?? json['member_id'] ?? json['userId']);
    final latitude = _readDouble(json['latitude'] ?? json['lat']);
    final longitude = _readDouble(json['longitude'] ?? json['lng'] ?? json['lon']);

    if (memberId == null || latitude == null || longitude == null) {
      throw FormatException('Invalid location payload: $json');
    }

    return ParticipantLocation(
      memberId: memberId,
      latitude: latitude,
      longitude: longitude,
      nickname: json['nickname'] as String? ?? json['nickName'] as String?,
      updatedAt: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toPublishJson({
    required int groupId,
    required int memberId,
  }) =>
      {
        'groupId': groupId,
        'memberId': memberId,
        'lat': latitude,
        'lng': longitude,
      };

  ParticipantLocation copyWith({
    double? latitude,
    double? longitude,
    String? nickname,
    String? titleName,
    String? coreColorCode,
    DateTime? updatedAt,
  }) {
    return ParticipantLocation(
      memberId: memberId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      nickname: nickname ?? this.nickname,
      titleName: titleName ?? this.titleName,
      coreColorCode: coreColorCode ?? this.coreColorCode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
