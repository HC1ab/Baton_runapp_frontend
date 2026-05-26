import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class RunApp extends ConsumerWidget {
  const RunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // ScreenUtil base size: 390x844 (iPhone 14 / standard Android reference)
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'RunApp',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(), // TODO: 다크모드 완성 후 활성화
          themeMode: ThemeMode.light, // 기기 테마 무시 — 항상 라이트 모드
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
