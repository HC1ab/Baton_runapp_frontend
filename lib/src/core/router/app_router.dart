import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/screens/history_screen.dart';
import '../constants/app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;

      if (authState is AuthStateLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (authState is AuthStateUnauthenticated) {
        final allowedAuthPaths = {
          AppRoutes.login,
          AppRoutes.signup,
        };
        return allowedAuthPaths.contains(location) ? null : AppRoutes.login;
      }

      if (authState is AuthStateAuthenticated) {
        if (location == AppRoutes.splash || location == AppRoutes.login) {
          return AppRoutes.home;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (_, __) => const HistoryScreen(),
      ),
      // RunningScreen은 HomeScreen의 IndexedStack 안에 포함됨
      // GoRoute(path: AppRoutes.running, ...) 제거
    ],
  );
});

/// Bridges Riverpod [AuthState] changes → GoRouter refresh signal.
/// Uses [ChangeNotifier] directly (go_router 14.x removed RouterNotifier).
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    // Listen to auth state — any change triggers GoRouter to re-run redirect.
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
