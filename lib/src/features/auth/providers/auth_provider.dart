import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/character/character_provider.dart';
import '../../../core/character/character_style.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/token_storage.dart';
import '../../group_running/providers/run_location_provider.dart';
import '../../group_running/services/group_run_api_service.dart';
import '../../running/providers/running_provider.dart';
import '../../social/social_providers.dart';
import '../services/auth_service.dart';

final _logger = Logger();

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Represents the entire authentication state of the app.
sealed class AuthState {
  const AuthState();
}

/// App is reading tokens from secure storage on startup.
final class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// User is authenticated.
/// UserModel은 /me API 구현 후 추가 예정
final class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated();
}

/// User is not authenticated (no token, token invalid, or logged out).
final class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Start loading and kick off async init.
    _initialize();
    return const AuthStateLoading();
  }

  /// Called once on app startup.
  /// Reads stored token → token 존재 여부만 확인 → sets state.
  /// (getMe 검증은 /me API 구현 후 추가 예정)
  Future<void> _initialize() async {
    try {
      final storage = ref.read(tokenStorageProvider);
      final pair = await storage.read();

      if (pair == null) {
        state = const AuthStateUnauthenticated();
        return;
      }

      // 토큰이 존재하면 인증된 상태로 처리
      // TODO: /me API 구현 후 토큰 유효성 검증 추가
      state = const AuthStateAuthenticated();
    } catch (e) {
      _logger.w('Auth initialization failed', error: e);
      await ref.read(tokenStorageProvider).clear();
      state = const AuthStateUnauthenticated();
    }
  }

  /// Called from LoginNotifier after a successful login response.
  /// Saves token pair to SecureStorage and coreColorCode to SharedPreferences.
  Future<void> onLoginSuccess(LoginResult result) async {
    await ref.read(tokenStorageProvider).write(result.tokenPair);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(StorageKeys.coreColorCode, result.coreColorCode);
    if (result.nickname.isNotEmpty) {
      await prefs.setString(StorageKeys.myNickname, result.nickname);
    }
    if (result.equippedTitleCode.isNotEmpty) {
      await prefs.setString(StorageKeys.equippedTitleCode, result.equippedTitleCode);
    }

    // 캐릭터 색상 즉시 반영 — provider 재빌드 없이 state 직접 갱신
    final style = CharacterStylePresets.fromCode(result.coreColorCode);
    await ref.read(selectedCharacterStyleProvider.notifier).setStyle(style);

    _logger.i(
      'Login saved — access: ${result.tokenPair.accessToken.substring(0, 20)}... '
      'coreColor: ${result.coreColorCode} title: ${result.equippedTitleCode} '
      'nickname: ${result.nickname}',
    );
    state = const AuthStateAuthenticated();
  }

  /// 토큰 만료/무효 시 API 호출 없이 즉시 로그아웃.
  /// AuthInterceptor에서 A001/A002/A003 감지 시 호출.
  Future<void> forceLogout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AuthStateUnauthenticated();
    _logger.w('Force logout — auth token invalid/expired');
  }

  /// Clears token and returns to unauthenticated state.
  Future<void> logout() async {
    // ── 활성 그룹 러닝 정리 ──────────────────────────────────────────────────
    // runLocationProvider(WebSocket) 기준으로 groupId + isHost 확인.
    // activeHostGroupIdProvider는 fallback (push 경로 호환).
    final locState = ref.read(runLocationProvider);
    final runState = ref.read(runningProvider);
    final activeGroupId = locState.groupId ?? ref.read(activeHostGroupIdProvider);

    if (activeGroupId != null) {
      final isHost = runState.isHost ||
          (ref.read(activeHostGroupIdProvider) == activeGroupId);

      if (isHost) {
        // 호스트 → 방 삭제 (best-effort)
        _logger.i('logout: host → deleteGroup($activeGroupId)');
        await ref
            .read(groupRunApiServiceProvider)
            .deleteGroup(activeGroupId);
      } else {
        // 참가자 → 방 나가기 (best-effort)
        _logger.i('logout: participant → leave($activeGroupId)');
        try {
          await ref
              .read(groupApiProvider)
              .leave(groupId: activeGroupId);
        } catch (e) {
          _logger.w('logout leave failed (best-effort)', error: e);
        }
      }

      // WebSocket 해제 + 상태 초기화
      await ref.read(runLocationProvider.notifier).leaveRoom();
      ref.read(runningProvider.notifier).resetToIdle();
      ref.read(activeHostGroupIdProvider.notifier).set(null);
    }

    try {
      await ref.read(authServiceProvider).logout();
    } catch (e) {
      _logger.w('Logout API call failed', error: e);
    } finally {
      await ref.read(tokenStorageProvider).clear();
      state = const AuthStateUnauthenticated();
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
