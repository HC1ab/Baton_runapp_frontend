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

class ShopItem {
  const ShopItem({
    required this.itemId,
    required this.code,
    required this.name,
    required this.price,
    required this.active,
  });

  final int itemId;

  /// Backend code (e.g. CORE_RED, CHAR_RED).
  final String code;

  final String name;

  /// Price in points.
  final int price;

  final bool active;

  /// True for Sphere Color items.
  /// 백엔드가 CHAR_* 또는 CORE_* 코드를 혼용하므로 양쪽 모두 허용.
  bool get isCoreColor => code.startsWith('CHAR_') || code.startsWith('CORE_');

  /// True for Title items.
  bool get isTitle => code.startsWith('TITLE_');

  /// True for Aura items.
  bool get isAura => code.startsWith('AURA_');

  /// True for miscellaneous equip items shown in the Inventory tab
  /// (anything that isn't a color, title, or aura).
  bool get isInventory => !isCoreColor && !isTitle && !isAura;

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      itemId: json['itemId'] as int,
      code: (json['code'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      price: (json['price'] ?? 0) as int,
      active: (json['active'] ?? true) as bool,
    );
  }
}

class PurchaseResult {
  const PurchaseResult({
    required this.purchaseId,
    required this.itemId,
    required this.itemName,
    required this.paidPoints,
    required this.currentTotalPoints,
  });

  final int purchaseId;
  final int itemId;
  final String itemName;
  final int paidPoints;
  final int currentTotalPoints;

  factory PurchaseResult.fromJson(Map<String, dynamic> json) {
    return PurchaseResult(
      purchaseId: (json['purchaseId'] ?? 0) as int,
      itemId: (json['itemId'] ?? 0) as int,
      itemName: (json['itemName'] ?? '') as String,
      paidPoints: (json['paidPoints'] ?? 0) as int,
      currentTotalPoints: (json['currentTotalPoints'] ?? 0) as int,
    );
  }
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class ShopService {
  const ShopService(this._dio);
  final Dio _dio;

  /// GET /api/v1/shop/items
  Future<List<ShopItem>> getItems({bool onlyActive = true}) async {
    try {
      final response = await _dio.get(
        ApiConstants.shopItems,
        queryParameters: {'onlyActive': onlyActive},
      );
      final data = _unwrap(response.data);
      if (data is! Map<String, dynamic>) {
        throw const ServerException(ErrorMessages.invalidResponse);
      }
      final items = data['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => ShopItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('getItems error', error: e);
      throw const UnknownException();
    }
  }

  /// GET /api/v1/points/me — 보유 포인트 조회
  Future<int> fetchPoints() async {
    try {
      final response = await _dio.get(ApiConstants.pointsMe);
      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['success'] == true) {
        final data = raw['data'] as Map<String, dynamic>?;
        return (data?['currentTotalPoints'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      _logger.w('fetchPoints failed', error: e);
      return 0;
    } catch (e) {
      _logger.w('fetchPoints unexpected error', error: e);
      return 0;
    }
  }

  /// POST /api/v1/shop/purchases
  Future<PurchaseResult> purchase(int itemId) async {
    try {
      final response = await _dio.post(
        ApiConstants.shopPurchase,
        data: {'itemId': itemId},
      );
      final data = _unwrap(response.data);
      if (data is! Map<String, dynamic>) {
        throw const ServerException(ErrorMessages.invalidResponse);
      }
      return PurchaseResult.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('purchase error', error: e);
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
    if (body is Map<String, dynamic>) {
      final isFailure = body['success'] == false ||
          body['status'] == 'fail' ||
          body['status'] == 'error';
      if (isFailure) {
        final msg = (body['message'] ?? ErrorMessages.serverError).toString();
        return ServerException(msg);
      }
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

final shopServiceProvider = Provider<ShopService>((ref) {
  return ShopService(ref.watch(dioProvider));
});

final shopItemsProvider = FutureProvider<List<ShopItem>>((ref) {
  return ref.watch(shopServiceProvider).getItems();
});

/// Current user's total points.
/// Initialized from GET /api/v1/points/me on first access via ShopService.
/// Updated after purchase via set().
class UserPointsNotifier extends Notifier<int> {
  @override
  int build() {
    _fetchPoints();
    return 0;
  }

  Future<void> _fetchPoints() async {
    final points = await ref.read(shopServiceProvider).fetchPoints();
    if (state != points) state = points;
  }

  /// Re-fetch points from server (e.g., after login).
  Future<void> refresh() => _fetchPoints();

  void set(int points) => state = points;
}

final userPointsProvider = NotifierProvider<UserPointsNotifier, int>(
  UserPointsNotifier.new,
);
