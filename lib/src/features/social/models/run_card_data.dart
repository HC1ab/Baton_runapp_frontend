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
    );
  }
}
