import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../constants/title_presets.dart';

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
    required this.description,
  });

  final int id;
  final String name;

  /// 프론트-백 약속 코드 (e.g. TITLE_001_GOLD). ShopItem.code와 매핑.
  final String titleCode;

  /// NORMAL | RARE | EPIC | LEGENDARY
  final String rarity;

  final String description;

  factory TitleInfo.fromJson(Map<String, dynamic> json) {
    return TitleInfo(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      titleCode: (json['titleCode'] ?? '') as String,
      rarity: (json['rarity'] ?? 'NORMAL') as String,
      description: (json['description'] ?? '') as String,
    );
  }
}

class EquippedTitleResult {
  const EquippedTitleResult({
    required this.titleId,
    required this.name,
  });

  final int titleId;
  final String name;

  factory EquippedTitleResult.fromJson(Map<String, dynamic> json) {
    return EquippedTitleResult(
      titleId: (json['titleId'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
    );
  }
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class TitleService {
  const TitleService(this._dio);
  final Dio _dio;

  /// POST /api/v1/profile/equip?titleId={titleId} — 칭호 장착.
  /// Returns the equipped title name.
  Future<EquippedTitleResult> equipTitle(int titleId) async {
    try {
      final response = await _dio.post(
        ApiConstants.profileEquip,
        queryParameters: {'titleId': titleId},
      );
      final data = _unwrap(response.data);
      if (data is! Map<String, dynamic>) {
        throw const ServerException(ErrorMessages.invalidResponse);
      }
      return EquippedTitleResult.fromJson(data);
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

/// 전체 칭호 목록 (하드코딩 — README.html 칭호 테이블과 1:1).
/// ShopScreen: titleCode → id 매핑.
/// MyRoomScreen: Titles 탭 렌더링.
final allTitlesProvider = Provider<List<TitleInfo>>((ref) {
  return TitlePresets.all;
});
