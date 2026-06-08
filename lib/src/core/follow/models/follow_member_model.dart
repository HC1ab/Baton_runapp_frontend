/// 팔로워·팔로잉 목록 항목 모델.
/// GET /api/v1/follows/followers, /api/v1/follows/followings 공통 응답.
class FollowMemberModel {
  const FollowMemberModel({
    required this.followId,
    required this.memberId,
    required this.nickname,
  });

  /// Follow 관계 ID — 삭제 시 사용.
  final String followId;
  final int memberId;
  final String nickname;

  factory FollowMemberModel.fromJson(Map<String, dynamic> json) {
    return FollowMemberModel(
      followId: (json['followId'] ?? '') as String,
      memberId: (json['memberId'] as num? ?? 0).toInt(),
      nickname: (json['nickname'] ?? '') as String,
    );
  }
}
