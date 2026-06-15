import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

class IosPushNotificationService {
  IosPushNotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

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
      _logger.i('APNs token: $apnsToken');
      _logger.i('FCM token: $fcmToken');
    } catch (e) {
      _logger.w('Failed to initialize iOS push notifications', error: e);
    }

    FirebaseMessaging.onMessage.listen((message) {
      _logger.i('Foreground push message: ${message.messageId}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _logger.i('Opened from push message: ${message.messageId}');
    });
  }
}
