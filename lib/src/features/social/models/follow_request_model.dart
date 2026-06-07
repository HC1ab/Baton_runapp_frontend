class FollowRequestModel {
  const FollowRequestModel({
    required this.followId,
    required this.memberId,
    required this.nickname,
  });

  final String followId;
  final int memberId;
  final String nickname;

  factory FollowRequestModel.fromJson(Map<String, dynamic> json) {
    return FollowRequestModel(
      followId: (json['followId'] ?? '') as String,
      memberId: (json['memberId'] as num? ?? 0).toInt(),
      nickname: (json['nickname'] ?? '') as String,
    );
  }
}
