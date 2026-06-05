import 'package:flutter_riverpod/flutter_riverpod.dart';

class _ForceLogoutNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void signal() => state++;
}

/// AuthInterceptor가 강제 로그아웃이 필요할 때 signal() 호출.
/// AuthNotifier가 이 값 변화를 감지해서 logout() 실행.
final forceLogoutSignalProvider =
    NotifierProvider<_ForceLogoutNotifier, int>(_ForceLogoutNotifier.new);
