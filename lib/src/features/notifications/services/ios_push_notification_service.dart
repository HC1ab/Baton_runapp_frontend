import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

final _logger = Logger();

class IosPushNotificationService {
  IosPushNotificationService({required Dio dio, FirebaseMessaging? messaging})
    : _dio = dio,
      _messaging = messaging ?? FirebaseMessaging.instance;

  final Dio _dio;
  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _logger.i('iOS notification permission: ${settings.authorizationStatus}');

      final apnsToken = await _messaging.getAPNSToken();
      final fcmToken = await _messaging.getToken();
      _logger.i('APNs token available: ${apnsToken != null}');
      _logger.i('FCM token available: ${fcmToken != null}');

      if (fcmToken != null) {
        await _saveFcmToken(fcmToken);
      }
    } catch (e) {
      _logger.w('Failed to initialize iOS push notifications', error: e);
    }

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen(
      (token) async {
        await _saveFcmToken(token);
      },
      onError: (Object e) {
        _logger.w('FCM token refresh listener failed', error: e);
      },
    );

    _foregroundMessageSubscription ??= FirebaseMessaging.onMessage.listen((
      message,
    ) {
      _logger.i('Foreground push message: ${message.messageId}');
    });

    _messageOpenedSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      _logger.i('Opened from push message: ${message.messageId}');
    });
  }

  Future<void> _saveFcmToken(String token) async {
    try {
      await _dio.post(ApiConstants.fcmToken, data: {'fcmToken': token});
      _logger.i('FCM token saved to server');
    } catch (e) {
      _logger.w('Failed to save FCM token to server', error: e);
    }
  }
}

final iosPushNotificationServiceProvider = Provider<IosPushNotificationService>(
  (ref) => IosPushNotificationService(dio: ref.watch(dioProvider)),
);
