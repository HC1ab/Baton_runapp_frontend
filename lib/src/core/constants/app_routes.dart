/// Route path constants used by GoRouter.
/// Always reference these instead of hardcoding path strings.
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const running = '/running';
}

/// Bottom navigation tab index constants.
abstract final class AppTabs {
  static const running = 0;
  static const spot = 1;
  static const social = 2;
  static const myRoom = 3;
  static const profile = 4;
}
