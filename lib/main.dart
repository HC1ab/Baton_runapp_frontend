import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'src/app.dart';
import 'src/features/auth/services/auth_service.dart';
import 'src/features/dev_tools/mock_auth_service.dart';
import 'src/features/dev_tools/mock_run_service.dart';
import 'src/features/dev_tools/mock_spot_service.dart';
import 'src/features/running/services/run_service.dart';
import 'src/features/running/services/spot_service.dart';

final _logger = Logger();

// --dart-define=ENV=dev 로 주입
const _env = String.fromEnvironment('ENV', defaultValue: 'dev');
bool get _isDev => _env == 'dev';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env.dev 또는 .env.prod 로드
  await dotenv.load(fileName: '.env.$_env');

  await _initNaverMap();

  runApp(
    ProviderScope(
      overrides: [
        if (_isDev) ...[
          authServiceProvider.overrideWith((_) => const MockAuthService()),
          runServiceProvider.overrideWith((_) => const MockRunService()),
          spotServiceProvider.overrideWith((_) => const MockSpotService()),
        ],
      ],
      child: const RunApp(),
    ),
  );
}

Future<void> _initNaverMap() async {
  try {
    // .env 파일에서 NAVER_MAP_CLIENT_ID 읽기
    final clientId = dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '';

    if (clientId.isEmpty) {
      _logger.e('NAVER_MAP_CLIENT_ID is missing in .env.$_env');
      return;
    }

    await FlutterNaverMap().init(
      clientId: clientId,
      onAuthFailed: (ex) => _logger.e('Naver Map auth failed', error: ex),
    );
  } catch (e) {
    _logger.e('Naver Map init error', error: e);
  }
}
