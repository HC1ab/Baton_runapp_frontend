import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/core/storage/shared_prefs_provider.dart';

final _logger = Logger();

const _env = String.fromEnvironment('ENV', defaultValue: 'dev');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Google Maps 플랫폼 뷰 설정
  // ① initializeWithRenderer(LATEST): Play Services가 지원하면 SurfaceView 렌더러 사용
  //    → Virtual Display 없음 → insets 피드백 루프 원천 차단
  // ② useAndroidViewSurface = true: LATEST가 불가(구형 에뮬/기기)일 때도 Hybrid Composition
  //    강제 적용 → LEGACY 렌더러라도 Virtual Display 대신 AndroidView 호스팅
  //    → MapView.onLayout() 이벤트가 Activity 윈도우 insets 까지 전파 안 됨
  //    → ImageReader 표면 반복 생성/해제(GPU 메모리 고갈 → ANR) 방지
  final mapsImpl = GoogleMapsFlutterPlatform.instance;
  if (mapsImpl is GoogleMapsFlutterAndroid) {
    await mapsImpl.initializeWithRenderer(AndroidMapRenderer.latest);
    mapsImpl.useAndroidViewSurface = true;
  }

  await dotenv.load(fileName: '.env.$_env');

  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    _logger.e('GOOGLE_MAPS_API_KEY is missing in .env.$_env');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const RunApp(),
    ),
  );
}
