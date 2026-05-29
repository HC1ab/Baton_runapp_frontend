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
  bool get isCoreColor => code.startsWith('CORE_');

  /// True for Title items.
  bool get isTitle => code.startsWith('TITLE_');

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

final shopServiceProvider = Provider<ShopService>((ref) {
  return ShopService(ref.watch(dioProvider));
});

final shopItemsProvider = FutureProvider<List<ShopItem>>((ref) {
  return ref.watch(shopServiceProvider).getItems();
});

/// Current user's total points.
/// Updated after purchase / spot check-in / run finish transactions.
class UserPointsNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int points) => state = points;
}

final userPointsProvider = NotifierProvider<UserPointsNotifier, int>(
  UserPointsNotifier.new,
);
