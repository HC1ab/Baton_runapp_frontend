import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/member_profile_model.dart';

export '../models/member_profile_model.dart' show MemberProfileModel, MemberPublicProfile;

final _logger = Logger();

class MemberProfileService {
  const MemberProfileService(this._dio);
  final Dio _dio;

  Future<MemberProfileModel> getByNickname(String nickname) async {
    try {
      final response = await _dio.get(
        ApiConstants.profileSearch,
        queryParameters: {'nickname': nickname},
      );
      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['success'] == true) {
        final list = raw['data'] as List<dynamic>?;
        if (list == null || list.isEmpty) {
          throw const ServerException(ErrorMessages.invalidResponse);
        }
        final match = list
            .cast<Map<String, dynamic>>()
            .firstWhere(
              (e) => (e['nickname'] as String?) == nickname,
              orElse: () => list.first as Map<String, dynamic>,
            );
        return MemberProfileModel.fromJson(match);
      }
      throw const ServerException(ErrorMessages.invalidResponse);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('getByNickname error', error: e);
      throw const UnknownException();
    }
  }

  /// GET /api/v1/profile/colors?memberIds={memberId}
  /// memberId → coreColorCode 단건 조회. 없으면 null 반환.
  Future<String?> getColorCode(int memberId) async {
    try {
      final response = await _dio.get(
        ApiConstants.profileColors,
        queryParameters: {'memberIds': '$memberId'},
      );
      final list = response.data['data'] as List<dynamic>? ?? [];
      if (list.isEmpty) return null;
      return list.first['coreColorCode'] as String?;
    } catch (e) {
      _logger.w('getColorCode failed id=$memberId', error: e);
      return null;
    }
  }

  /// GET /api/v1/profile/{memberId} — memberId로 공개 프로필 조회
  Future<MemberPublicProfile> getById(int memberId) async {
    try {
      final response = await _dio.get(ApiConstants.profileById(memberId));
      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['success'] == true) {
        final data = raw['data'] as Map<String, dynamic>?;
        if (data == null) throw const ServerException(ErrorMessages.invalidResponse);
        return MemberPublicProfile.fromJson(data);
      }
      throw const ServerException(ErrorMessages.invalidResponse);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('getById error memberId=$memberId', error: e);
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

final memberProfileServiceProvider = Provider<MemberProfileService>((ref) {
  return MemberProfileService(ref.watch(dioProvider));
});

final memberProfileProvider =
    FutureProvider.family<MemberProfileModel, String>((ref, nickname) {
  return ref.watch(memberProfileServiceProvider).getByNickname(nickname);
});

/// memberId → 공개 프로필 조회 (점령자 닉네임 표시 등)
final memberPublicProfileProvider =
    FutureProvider.autoDispose.family<MemberPublicProfile, int>((ref, memberId) {
  return ref.watch(memberProfileServiceProvider).getById(memberId);
});

/// memberId → coreColorCode 단건 조회
final memberColorCodeProvider =
    FutureProvider.family<String?, int>((ref, memberId) {
  return ref.watch(memberProfileServiceProvider).getColorCode(memberId);
});
