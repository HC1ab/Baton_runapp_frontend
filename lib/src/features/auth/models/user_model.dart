/// User profile returned from GET /api/v1/member/me.
/// Immutable — no business logic inside.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.nickname,
    required this.realname,
  });

  final int id;
  final String email;
  final String nickname;
  final String realname;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      realname: json['realname'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nickname': nickname,
        'realname': realname,
      };

  UserModel copyWith({
    int? id,
    String? email,
    String? nickname,
    String? realname,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      realname: realname ?? this.realname,
    );
  }
}
