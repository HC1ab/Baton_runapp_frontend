import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/follow_request_model.dart';

final _logger = Logger();

class FollowService {
  const FollowService(this._dio);
  final Dio _dio;

  Future<void> sendRequest(String targetNickname) async {
    try {
      await _dio.post(
        ApiConstants.followRequest,
        data: {'targetNickname': targetNickname},
      );
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('sendRequest error', error: e);
      throw const UnknownException();
    }
  }

  Future<List<FollowRequestModel>> getRequests() async {
    try {
      final response = await _dio.get(ApiConstants.followRequests);
      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['success'] == true) {
        final list = (raw['data'] as List<dynamic>? ?? []);
        return list
            .cast<Map<String, dynamic>>()
            .map(FollowRequestModel.fromJson)
            .toList();
      }
      throw const ServerException(ErrorMessages.invalidResponse);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('getRequests error', error: e);
      throw const UnknownException();
    }
  }

  Future<void> accept(String followId) async {
    try {
      await _dio.post(ApiConstants.followAccept(followId));
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('accept error', error: e);
      throw const UnknownException();
    }
  }

  Future<void> reject(String followId) async {
    try {
      await _dio.post(ApiConstants.followReject(followId));
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('reject error', error: e);
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
    if (e.type == DioExceptionType.connectionError) return const NetworkException();
    return const UnknownException();
  }
}

final followServiceProvider = Provider<FollowService>((ref) {
  return FollowService(ref.watch(dioProvider));
});

final pendingFollowRequestsProvider =
    FutureProvider<List<FollowRequestModel>>((ref) {
  return ref.watch(followServiceProvider).getRequests();
});
