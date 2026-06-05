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

class TitleInfo {
  const TitleInfo({
    required this.id,
    required this.name,
    required this.titleCode,
    required this.rarity,
    required this.expBonusRatio,
    required this.pointBonusRatio,
    required this.description,
  });

  final int id;
  final String name;
  final String titleCode;

  /// NORMAL / RARE / EPIC / LEGENDARY
  final String rarity;

  /// 경험치 보너스 비율 (0.05 = +5%)
  final double expBonusRatio;

  /// 포인트 보너스 비율 (0.06 = +6%)
  final double pointBonusRatio;

  final String description;

  factory TitleInfo.fromJson(Map<String, dynamic> json) {
    return TitleInfo(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      titleCode: (json['titleCode'] ?? '') as String,
      rarity: (json['rarity'] ?? 'NORMAL') as String,
      expBonusRatio: (json['expBonusRatio'] as num? ?? 0).toDouble(),
      pointBonusRatio: (json['pointBonusRatio'] as num? ?? 0).toDouble(),
      description: (json['description'] ?? '') as String,
    );
  }
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class TitleService {
  const TitleService(this._dio);
  final Dio _dio;

  /// GET /api/v1/title/all — fetch entire title list.
  Future<List<TitleInfo>> getAllTitles() async {
    try {
      final response = await _dio.get(ApiConstants.titleAll);
      final data = _unwrap(response.data);
      if (data is! List<dynamic>) {
        throw const ServerException(ErrorMessages.invalidResponse);
      }
      return data
          .map((e) => TitleInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('getAllTitles error', error: e);
      throw const UnknownException();
    }
  }

  /// POST /api/v1/profile/equip?titleId= — equip a title.
  Future<void> equipTitle(int titleId) async {
    try {
      await _dio.post(
        ApiConstants.profileEquip,
        queryParameters: {'titleId': titleId},
      );
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('equipTitle error', error: e);
      throw const UnknownException();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  dynamic _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['success'] == true) return raw['data'];
      final msg = (raw['message'] ?? ErrorMessages.serverError).toString();
      throw ServerException(msg);
    }
    throw const ServerException(ErrorMessages.invalidResponse);
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    if (body is Map<String, dynamic> && body['success'] == false) {
      final msg = (body['message'] ?? ErrorMessages.serverError).toString();
      return ServerException(msg);
    }
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

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final titleServiceProvider = Provider<TitleService>((ref) {
  return TitleService(ref.watch(dioProvider));
});

/// Full title list from API.
/// Invalidate after equipping to refresh UI if needed.
final allTitlesProvider = FutureProvider<List<TitleInfo>>((ref) {
  return ref.watch(titleServiceProvider).getAllTitles();
});
