import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';

final _logger = Logger();

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class ProfileModel {
  const ProfileModel({
    required this.nickname,
    required this.level,
    required this.totalDistance,
    required this.avgPace,
    required this.equippedTitleName,
  });

  final String nickname;
  final int level;

  /// 총 달린 거리 (km)
  final double totalDistance;

  /// 평균 페이스 — MM.SS 포맷 (예: 5.42 = 5분 42초/km)
  final double avgPace;

  final String equippedTitleName;

  /// "M'SS\"" 형식으로 변환 (예: 5.42분/km → "5'42\"")
  String get avgPaceText {
    if (avgPace <= 0) return "0'00\"";
    final min = avgPace.truncate();
    final sec = ((avgPace * 100) % 100).round();
    return "$min'${sec.toString().padLeft(2, '0')}\"";
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      nickname: (json['nickname'] ?? '') as String,
      level: (json['level'] as num? ?? 0).toInt(),
      totalDistance: (json['totalDistance'] as num? ?? 0.0).toDouble(),
      avgPace: (json['avgPace'] as num? ?? 0.0).toDouble(),
      equippedTitleName: (json['equippedTitleName'] ?? '') as String,
    );
  }
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class ProfileService {
  const ProfileService(this._dio);
  final Dio _dio;

  /// GET /api/v1/profile/me — 레벨, 총 거리, 평균 페이스 등 조회
  Future<ProfileModel> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.profileMe);
      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['success'] == true) {
        final data = raw['data'] as Map<String, dynamic>?;
        if (data == null) {
          throw const ServerException(ErrorMessages.invalidResponse);
        }
        return ProfileModel.fromJson(data);
      }
      throw const ServerException(ErrorMessages.invalidResponse);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('getProfile error', error: e);
      throw const UnknownException();
    }
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) { return const AuthException(); }
    if (status != null && status >= 500) { return const ServerException(); }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const TimeoutException();
    }
    if (e.type == DioExceptionType.connectionError) { return const NetworkException(); }
    return const UnknownException();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(dioProvider));
});

final profileProvider = FutureProvider<ProfileModel>((ref) {
  return ref.watch(profileServiceProvider).getProfile();
});
