import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/token_storage.dart';
import '../auth/models/user_model.dart';
import '../auth/services/auth_service.dart';

/// Mock implementation of AuthServiceBase for development/testing.
/// Swap in via ProviderScope overrides in main.dart when AppConstants.isDev is true.
/// Never reference this file outside of dev_tools/.
class MockAuthService implements AuthServiceBase {
  const MockAuthService();

  static const _mockAccessToken =
      'mock.access.token_eyJzdWIiOiIxIn0';
  static const _mockRefreshToken =
      'mock.refresh.token_eyJleHAiOjk5OTk5fQ';

  static final _mockUser = UserModel(
    id: 1,
    email: 'dev@runapp.kr',
    nickname: '개발자',
    realname: '홍길동',
    totalPoints: 500,
  );

  @override
  Future<TokenPair> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    // Simulate wrong credentials
    if (password == 'wrong') {
      throw Exception('이메일 또는 비밀번호를 확인해주세요.');
    }
    return const TokenPair(
      accessToken: _mockAccessToken,
      refreshToken: _mockRefreshToken,
    );
  }

  @override
  Future<UserModel> getMe(String accessToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _mockUser;
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}

/// Override provider — use in ProviderScope when isDev is true.
final mockAuthServiceProvider = Provider<AuthServiceBase>((ref) {
  return const MockAuthService();
});
