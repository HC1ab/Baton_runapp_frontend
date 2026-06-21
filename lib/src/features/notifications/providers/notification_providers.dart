import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification_model.dart';
import '../services/notification_service.dart';

export '../services/notification_service.dart' show notificationServiceProvider;

final notificationsProvider = FutureProvider<List<AppNotificationModel>>((ref) {
  return ref.watch(notificationServiceProvider).getNotifications();
});

final notificationUnreadCountProvider = FutureProvider<int>((ref) {
  return ref.watch(notificationServiceProvider).getUnreadCount();
});
