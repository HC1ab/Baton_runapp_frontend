import '../models/participant_location.dart';

/// Runtime participant combining location + profile info.
class GroupParticipant {
  const GroupParticipant({
    required this.memberId,
    required this.latitude,
    required this.longitude,
    this.nickname,
    this.titleName,
    this.updatedAt,
  });

  final int memberId;
  final double latitude;
  final double longitude;
  final String? nickname;
  final String? titleName;
  final DateTime? updatedAt;

  factory GroupParticipant.fromLocation(ParticipantLocation loc) =>
      GroupParticipant(
        memberId: loc.memberId,
        latitude: loc.latitude,
        longitude: loc.longitude,
        nickname: loc.nickname,
        updatedAt: loc.updatedAt,
      );

  GroupParticipant copyWith({
    double? latitude,
    double? longitude,
    String? nickname,
    String? titleName,
    DateTime? updatedAt,
  }) =>
      GroupParticipant(
        memberId: memberId,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        nickname: nickname ?? this.nickname,
        titleName: titleName ?? this.titleName,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
