import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/app_notification_model.dart';

final _logger = Logger();

class NotificationService {
  const NotificationService(this._dio);

  final Dio _dio;

  Future<List<AppNotificationModel>> getNotifications() async {
    try {
      final response = await _dio.get(ApiConstants.notifications);
      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['success'] == true) {
        final list = raw['data'] as List<dynamic>? ?? const [];
        return list
            .whereType<Map>()
            .map(
              (item) => AppNotificationModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
      throw const ServerException(ErrorMessages.invalidResponse);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('getNotifications error', error: e);
      throw const UnknownException();
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get(ApiConstants.notificationUnreadCount);
      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['success'] == true) {
        final data = raw['data'];
        if (data is int) return data;
        if (data is num) return data.toInt();
        if (data is Map<String, dynamic>) {
          final value = data['count'] ?? data['unreadCount'];
          if (value is int) return value;
          if (value is num) return value.toInt();
          return int.tryParse(value?.toString() ?? '') ?? 0;
        }
        return int.tryParse(data?.toString() ?? '') ?? 0;
      }
      throw const ServerException(ErrorMessages.invalidResponse);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('getUnreadCount error', error: e);
      throw const UnknownException();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.patch(ApiConstants.notificationRead(notificationId));
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('markAsRead error', error: e);
      throw const UnknownException();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch(ApiConstants.notificationReadAll);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('markAllAsRead error', error: e);
      throw const UnknownException();
    }
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return const AuthException();
    if (status != null && status >= 500) return const ServerException();
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const TimeoutException();
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }
    return const UnknownException();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(dioProvider));
});
