import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../constants/app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // RouterNotifier bridges Riverpod state → GoRouter refresh signal.
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;

      // Still initializing — hold on splash.
      if (authState is AuthStateLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // Not authenticated — send to login.
      if (authState is AuthStateUnauthenticated) {
        return location == AppRoutes.login ? null : AppRoutes.login;
      }

      // Authenticated — redirect away from splash / login.
      if (authState is AuthStateAuthenticated) {
        if (location == AppRoutes.splash || location == AppRoutes.login) {
          return AppRoutes.home;
        }
      }

      return null; // No redirect needed.
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});

/// Converts Riverpod [AuthState] changes into a [ChangeNotifier] signal
/// that GoRouter can listen to for re-evaluating redirects.
class _RouterNotifier extends RouterNotifier {
  _RouterNotifier(this._ref) {
    // Watch auth state — any change triggers GoRouter to re-run redirect.
    _ref.listen(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
}
