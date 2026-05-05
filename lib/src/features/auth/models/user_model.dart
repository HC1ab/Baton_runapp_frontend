/// User profile returned from GET /api/v1/member/me.
/// Immutable — no business logic inside.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.nickname,
    required this.realname,
    this.profileImageUrl,
    this.totalPoints = 0,
  });

  final int id;
  final String email;
  final String nickname;
  final String realname;
  final String? profileImageUrl;
  final int totalPoints;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      realname: json['realname'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      totalPoints: (json['totalPoints'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nickname': nickname,
        'realname': realname,
        'profileImageUrl': profileImageUrl,
        'totalPoints': totalPoints,
      };

  UserModel copyWith({
    int? id,
    String? email,
    String? nickname,
    String? realname,
    String? profileImageUrl,
    int? totalPoints,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      realname: realname ?? this.realname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}
