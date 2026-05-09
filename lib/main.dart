import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'src/app.dart';

final _logger = Logger();

const _env = String.fromEnvironment('ENV', defaultValue: 'dev');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.$_env');
  await _initNaverMap();

  runApp(
    const ProviderScope(
      child: RunApp(),
    ),
  );
}

Future<void> _initNaverMap() async {
  try {
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