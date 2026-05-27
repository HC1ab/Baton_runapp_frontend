import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';

final _logger = Logger();

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// Single color item in the MyRoom palette.
class MyRoomColorItem {
  const MyRoomColorItem({
    required this.code,
    required this.name,
    required this.hex,
    required this.owned,
  });

  /// Backend CORE_* code (e.g. CORE_RED).
  final String code;

  /// Display name (e.g. 빨간색 코어).
  final String name;

  /// Hex color value (e.g. #C85A3E) — from server.
  final String hex;

  /// Whether the user has purchased this color.
  final bool owned;

  factory MyRoomColorItem.fromJson(Map<String, dynamic> json) {
    return MyRoomColorItem(
      code: json['code'] as String,
      name: json['name'] as String,
      hex: json['hex'] as String,
      owned: json['owned'] as bool,
    );
  }
}

/// Full MyRoom response from GET /api/v1/myroom.
class MyRoomResult {
  const MyRoomResult({
    required this.memberId,
    required this.nickname,
    required this.equippedTitle,
    required this.currentColorCode,
    required this.colors,
  });

  final int memberId;
  final String nickname;
  final String equippedTitle;
  final String currentColorCode;
  final List<MyRoomColorItem> colors;

  factory MyRoomResult.fromJson(Map<String, dynamic> json) {
    return MyRoomResult(
      memberId: json['memberId'] as int,
      nickname: json['nickname'] as String,
      equippedTitle: (json['equippedTitle'] ?? '') as String,
      currentColorCode: json['currentColorCode'] as String,
      colors: (json['colors'] as List<dynamic>)
          .map((e) => MyRoomColorItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class MyRoomService {
  const MyRoomService(this._dio);
  final Dio _dio;

  /// GET /api/v1/myroom — fetch nickname, equipped title, color palette.
  Future<MyRoomResult> getMyRoom() async {
    try {
      final response = await _dio.get(ApiConstants.myRoom);
      final data = _unwrap(response.data);
      if (data is! Map<String, dynamic>) {
        throw const ServerException(ErrorMessages.invalidResponse);
      }
      return MyRoomResult.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('getMyRoom error', error: e);
      throw const UnknownException();
    }
  }

  /// PATCH /api/v1/myroom/core-color — change color.
  /// Returns the confirmed [currentColorCode] from server.
  Future<String> changeCoreColor(String colorCode) async {
    try {
      final response = await _dio.patch(
        ApiConstants.myCoreColor,
        data: {'colorCode': colorCode},
      );
      final data = _unwrap(response.data);
      if (data is! Map<String, dynamic>) {
        throw const ServerException(ErrorMessages.invalidResponse);
      }
      return (data['currentColorCode'] ?? colorCode) as String;
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('changeCoreColor error', error: e);
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

final myRoomServiceProvider = Provider<MyRoomService>((ref) {
  return MyRoomService(ref.watch(dioProvider));
});

/// Loads MyRoom data (palette + owned status) on screen entry.
/// Invalidate with ref.invalidate(myRoomProvider) after purchase.
final myRoomProvider = FutureProvider<MyRoomResult>((ref) {
  return ref.watch(myRoomServiceProvider).getMyRoom();
});
