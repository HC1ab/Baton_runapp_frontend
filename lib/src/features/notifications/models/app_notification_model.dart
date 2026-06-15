enum AppNotificationType {
  spotStealRisk,
  spotStolen,
  followRequest,
  followAccepted,
  unknown,
}

enum AppNotificationTargetType { spot, follow, unknown }

class AppNotificationModel {
  const AppNotificationModel({
    required this.notificationId,
    required this.type,
    required this.rawType,
    required this.title,
    required this.message,
    required this.targetType,
    required this.targetId,
    required this.isRead,
    required this.createdAt,
    this.actorMemberId,
    this.actorNickname,
    this.readAt,
  });

  final int notificationId;
  final AppNotificationType type;
  final String rawType;
  final String title;
  final String message;
  final AppNotificationTargetType targetType;
  final String targetId;
  final int? actorMemberId;
  final String? actorNickname;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  int? get targetIdAsInt => int.tryParse(targetId);

  bool get pointsToSpot =>
      targetType == AppNotificationTargetType.spot ||
      type == AppNotificationType.spotStealRisk ||
      type == AppNotificationType.spotStolen;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? '').toString();
    final rawTargetType = (json['targetType'] ?? '').toString();

    return AppNotificationModel(
      notificationId: _asInt(json['notificationId'] ?? json['id']),
      type: _parseType(rawType),
      rawType: rawType,
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      targetType: _parseTargetType(rawTargetType),
      targetId: (json['targetId'] ?? '').toString(),
      actorMemberId: _asNullableInt(json['actorMemberId']),
      actorNickname: json['actorNickname']?.toString(),
      isRead: json['read'] == true || json['isRead'] == true,
      createdAt: _asDateTime(json['createdAt']),
      readAt: _asNullableDateTime(json['readAt']),
    );
  }

  static AppNotificationType _parseType(String value) {
    switch (value) {
      case 'SPOT_STEAL_RISK':
        return AppNotificationType.spotStealRisk;
      case 'SPOT_STOLEN':
        return AppNotificationType.spotStolen;
      case 'FOLLOW_REQUEST':
        return AppNotificationType.followRequest;
      case 'FOLLOW_ACCEPTED':
        return AppNotificationType.followAccepted;
      default:
        return AppNotificationType.unknown;
    }
  }

  static AppNotificationTargetType _parseTargetType(String value) {
    switch (value) {
      case 'SPOT':
        return AppNotificationTargetType.spot;
      case 'FOLLOW':
        return AppNotificationTargetType.follow;
      default:
        return AppNotificationTargetType.unknown;
    }
  }

  static int _asInt(Object? value) => _asNullableInt(value) ?? 0;

  static int? _asNullableInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime _asDateTime(Object? value) {
    return _asNullableDateTime(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _asNullableDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
