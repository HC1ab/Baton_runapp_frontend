import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/screens/history_screen.dart';
import '../../features/profile/screens/run_detail_screen.dart';
import '../../features/settings/data/legal_documents.dart';
import '../../features/settings/screens/account_screen.dart';
import '../../features/settings/screens/legal_document_screen.dart';
import '../../features/settings/screens/notice_detail_screen.dart';
import '../../features/settings/screens/notice_list_screen.dart';
import '../../features/profile/screens/friends_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/run_share/models/run_share_data.dart';
import '../../features/run_share/screens/run_share_screen.dart';
import '../../features/spot/screens/spot_detail_screen.dart';
import '../../features/shop/screens/shop_screen.dart';
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
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, _) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (_, _) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.shop,
        builder: (_, _) => const ShopScreen(),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (_, _) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.friends,
        builder: (_, _) => const FriendsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.account,
        builder: (_, _) => const AccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (_, _) => const LegalDocumentScreen(
          title: '개인정보처리방침',
          content: LegalDocuments.privacyPolicy,
        ),
      ),
      GoRoute(
        path: AppRoutes.termsOfService,
        builder: (_, _) => const LegalDocumentScreen(
          title: '이용약관',
          content: LegalDocuments.termsOfService,
        ),
      ),
      GoRoute(
        path: AppRoutes.noticeList,
        builder: (_, _) => const NoticeListScreen(),
      ),
      GoRoute(
        path: '/notices/:noticeId',
        builder: (_, state) => NoticeDetailScreen(
          noticeId: int.parse(state.pathParameters['noticeId']!),
          title: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.runDetail}/:runId',
        builder: (_, state) => RunDetailScreen(
          runId: int.parse(state.pathParameters['runId']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.runShare,
        builder: (_, state) => RunShareScreen(
          data: state.extra as RunShareData,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.spotDetail}/:spotId',
        builder: (_, state) => SpotDetailScreen(
          spotId: int.parse(state.pathParameters['spotId']!),
        ),
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
    _ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}
