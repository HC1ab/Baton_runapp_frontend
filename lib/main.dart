import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'src/app.dart';
import 'src/features/auth/services/auth_service.dart';
import 'src/features/dev_tools/mock_auth_service.dart';

final _logger = Logger();

// Injected via --dart-define=IS_DEV=true
const bool _isDev = bool.fromEnvironment('IS_DEV', defaultValue: true);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initNaverMap();

  runApp(
    ProviderScope(
      overrides: [
        // Swap real service for mock in dev mode.
        if (_isDev)
          authServiceProvider.overrideWith(
            (ref) => const MockAuthService(),
          ),
      ],
      child: const RunApp(),
    ),
  );
}

Future<void> _initNaverMap() async {
  try {
    await FlutterNaverMap().init(
      // [보안] API 키는 --dart-define=NAVER_MAP_CLIENT_ID=xxx 로 주입
      clientId: const String.fromEnvironment(
        'NAVER_MAP_CLIENT_ID',
        defaultValue: '0dz77rdfgy', // dev fallback only
      ),
      onAuthFailed: (ex) {
        _logger.e('Naver Map auth failed', error: ex);
      },
    );
  } catch (e) {
    _logger.e('Naver Map init error', error: e);
  }
}
