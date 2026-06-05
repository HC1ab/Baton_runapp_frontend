import 'package:intl/intl.dart';

/// 소셜 피드 카드 및 상세 화면에서 공유하는 데이터 모델.
class RunCardData {
  const RunCardData({
    this.groupId,
    this.isHost = false,
    this.isParticipating = false,
    required this.title,
    required this.time,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.currentMembers,
    required this.maxMembers,
    required this.participantImageUrls,
    this.endTimeLabel,
    this.targetDistance,
    this.placeName,
    this.detailAddress,
    this.body,
    this.hostNickname,
    this.participantNicknames = const [],
  });

  final int? groupId;
  final bool isHost;
  final bool isParticipating;
  final String title;
  final String time;
  final String location;
  final double latitude;
  final double longitude;
  final int currentMembers;
  final int maxMembers;
  final List<String> participantImageUrls;
  final String? hostNickname;
  final List<String> participantNicknames;

  /// 상세: 종료 시간 라벨 (예: 오후 9:30)
  final String? endTimeLabel;

  /// 상세: 목표 거리
  final String? targetDistance;

  /// 상세: 장소명
  final String? placeName;

  /// 상세: 상세 주소
  final String? detailAddress;

  /// 상세: 모집 본문
  final String? body;

  String get effectivePlaceName => placeName ?? title;

  String get effectiveDetailAddress => detailAddress ?? location;

  String get effectiveEndTime => endTimeLabel ?? '—';

  String get effectiveTargetDistance => targetDistance ?? '5km';

  String get effectiveBody =>
      body ??
      '모집 내용이 준비 중입니다.\n함께 달릴 분을 기다리고 있어요.';

  /// 서버 `GET /api/v1/groups` 항목을 카드로 변환.
  ///
  /// 백엔드 필드명이 정확히 확정되지 않았을 수 있으므로
  /// 자주 쓰이는 별칭을 모두 시도한다.
  factory RunCardData.fromServerJson(
    Map<String, dynamic> json, {
    int? myMemberId,
  }) {
    final groupId = _readInt(json['groupId'] ?? json['id']);

    final title = (json['title'] ?? '').toString();
    final body = (json['content'] ?? json['body'] ?? json['description'])
        ?.toString();

    final placeName =
        (json['location'] ?? json['placeName'] ?? json['place'])?.toString();
    final detailAddress =
        (json['address'] ?? json['detailAddress'])?.toString();

    final maxMembers = _readInt(
          json['maxParticipants'] ?? json['maxMembers'] ?? json['capacity'],
        ) ??
        0;

    // currentMembers — 숫자 직접 / 참가자 리스트 길이 / +1 (호스트 포함)
    int currentMembers = _readInt(
          json['currentParticipants'] ??
              json['currentMembers'] ??
              json['participantCount'] ??
              json['memberCount'],
        ) ??
        0;
    final participantsRaw = json['participants'] ?? json['members'];
    if (currentMembers == 0 && participantsRaw is List) {
      currentMembers = participantsRaw.length;
    }
    if (currentMembers == 0) currentMembers = 1; // 최소 호스트 1명

    final hostId = _readInt(
      json['hostId'] ??
          json['ownerId'] ??
          json['creatorId'] ??
          json['createdBy'] ??
          json['leaderId'] ??
          json['managerId'] ??
          json['memberId'] ??
          json['userId'] ??
          (json['host'] is Map<String, dynamic>
              ? (json['host'] as Map<String, dynamic>)['id'] ??
                  (json['host'] as Map<String, dynamic>)['memberId']
              : null) ??
          (json['owner'] is Map<String, dynamic>
              ? (json['owner'] as Map<String, dynamic>)['id'] ??
                  (json['owner'] as Map<String, dynamic>)['memberId']
              : null) ??
          (json['creator'] is Map<String, dynamic>
              ? (json['creator'] as Map<String, dynamic>)['id'] ??
                  (json['creator'] as Map<String, dynamic>)['memberId']
              : null),
    );

    final serverIsHost = _readBool(
      json['isHost'] ??
          json['host'] ??
          json['isOwner'] ??
          json['owner'] ??
          json['isCreator'] ??
          json['mine'] ??
          json['myGroup'],
    );
    final isHost =
        serverIsHost ?? (myMemberId != null && hostId != null && myMemberId == hostId);

    final serverJoined = _readBool(
      json['isParticipating'] ??
          json['joined'] ??
          json['isJoined'] ??
          json['participating'] ??
          json['participated'] ??
          json['isMember'] ??
          json['member'],
    );
    bool isParticipating = serverJoined ?? false;
    if (!isParticipating &&
        myMemberId != null &&
        participantsRaw is List) {
      isParticipating = participantsRaw.any((p) {
        if (p is int) return p == myMemberId;
        if (p is Map) {
          final id = _readInt(p['id'] ?? p['memberId'] ?? p['userId']);
          return id == myMemberId;
        }
        return false;
      });
    }
    if (isHost) isParticipating = true;

    final lat = _readDouble(json['latitude'] ?? json['lat']) ?? 35.1631;
    final lng = _readDouble(json['longitude'] ?? json['lng'] ?? json['lon']) ??
        129.0536;

    final startTime = _parseDate(json['startTime'] ?? json['startAt']);
    final endTime = _parseDate(json['endTime'] ?? json['endAt']);

    final distanceNum =
        _readDouble(json['distance'] ?? json['distanceKm'] ?? json['targetDistance']);
    final targetDistance = distanceNum != null
        ? '${distanceNum % 1 == 0 ? distanceNum.toInt() : distanceNum}km'
        : null;

    final hostNickname = (json['hostNickname'] ??
            json['nickname'] ??
            (json['host'] is Map<String, dynamic>
                ? (json['host'] as Map<String, dynamic>)['nickname'] ??
                    (json['host'] as Map<String, dynamic>)['realname']
                : null))
        ?.toString();

    final participantNicknames =
        (json['participantNicknames'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return RunCardData(
      groupId: groupId,
      isHost: isHost,
      isParticipating: isParticipating,
      title: title.isEmpty ? '제목 없음' : title,
      time: startTime != null ? _formatFeedTime(startTime) : '시간 미정',
      location: placeName ?? detailAddress ?? '장소 미정',
      latitude: lat,
      longitude: lng,
      currentMembers: currentMembers,
      maxMembers: maxMembers > 0 ? maxMembers : currentMembers,
      participantImageUrls: List<String>.filled(
        currentMembers.clamp(0, 3),
        '',
      ),
      endTimeLabel: endTime != null ? _formatTimeKo(endTime) : null,
      targetDistance: targetDistance,
      placeName: placeName,
      detailAddress: detailAddress,
      body: body,
      hostNickname: hostNickname,
      participantNicknames: participantNicknames,
    );
  }

  RunCardData copyWith({
    int? groupId,
    bool? isHost,
    bool? isParticipating,
    String? title,
    String? time,
    String? location,
    double? latitude,
    double? longitude,
    int? currentMembers,
    int? maxMembers,
    List<String>? participantImageUrls,
    String? endTimeLabel,
    String? targetDistance,
    String? placeName,
    String? detailAddress,
    String? body,
    String? hostNickname,
    List<String>? participantNicknames,
  }) {
    return RunCardData(
      groupId: groupId ?? this.groupId,
      isHost: isHost ?? this.isHost,
      isParticipating: isParticipating ?? this.isParticipating,
      title: title ?? this.title,
      time: time ?? this.time,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      currentMembers: currentMembers ?? this.currentMembers,
      maxMembers: maxMembers ?? this.maxMembers,
      participantImageUrls: participantImageUrls ?? this.participantImageUrls,
      endTimeLabel: endTimeLabel ?? this.endTimeLabel,
      targetDistance: targetDistance ?? this.targetDistance,
      placeName: placeName ?? this.placeName,
      detailAddress: detailAddress ?? this.detailAddress,
      body: body ?? this.body,
      hostNickname: hostNickname ?? this.hostNickname,
      participantNicknames: participantNicknames ?? this.participantNicknames,
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' ||
        normalized == 'y' ||
        normalized == 'yes' ||
        normalized == '1') {
      return true;
    }
    if (normalized == 'false' ||
        normalized == 'n' ||
        normalized == 'no' ||
        normalized == '0') {
      return false;
    }
  }
  return null;
}

double? _readDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String _formatFeedTime(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(dt.year, dt.month, dt.day);
  final diff = target.difference(today).inDays;
  final timeLabel = _formatTimeKo(dt);
  if (diff == 0) return '오늘 $timeLabel';
  if (diff == 1) return '내일 $timeLabel';
  return '${DateFormat('M월 d일').format(dt)} $timeLabel';
}

String _formatTimeKo(DateTime dt) {
  final isPm = dt.hour >= 12;
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  return '${isPm ? '오후' : '오전'} $hour12:$minute';
}
