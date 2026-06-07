import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/member_profile_model.dart';

export '../models/member_profile_model.dart' show MemberProfileModel;

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

/// memberId → coreColorCode 단건 조회
final memberColorCodeProvider =
    FutureProvider.family<String?, int>((ref, memberId) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.get(
      ApiConstants.profileColors,
      queryParameters: {'memberIds': '$memberId'},
    );
    final list = res.data['data'] as List<dynamic>? ?? [];
    if (list.isEmpty) return null;
    return list.first['coreColorCode'] as String?;
  } catch (e) {
    Logger().w('memberColorCodeProvider failed id=$memberId', error: e);
    return null;
  }
});
