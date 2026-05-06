import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../models/login_model.dart';

class AuthApi {
  AuthApi({Dio? dio}) : _dio = dio ?? _createDio();

  static const String _loginPath =
      String.fromEnvironment('LOGIN_PATH', defaultValue: '/member/login');

  final Dio _dio;

  static Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeoutMs),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<String?> login(LoginRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _loginPath,
        data: <String, dynamic>{
          ...request.toJson(),
          'loginId': request.email,
          'username': request.email,
        },
        options: Options(
          extra: <String, dynamic>{'requiresAuth': false},
          validateStatus: (int? status) => status != null && status < 500,
        ),
      );
      return _extractAccessToken(response);
    } on DioException {
      return null;
    }
  }

  String? _extractAccessToken(Response<dynamic> response) {
    final String? authorization = response.headers.value('authorization');
    if (authorization != null && authorization.toLowerCase().startsWith('bearer ')) {
      final String token = authorization.substring(7).trim();
      if (token.isNotEmpty) {
        return token;
      }
    }

    final dynamic body = response.data;
    if (body is! Map<String, dynamic>) {
      return null;
    }

    final dynamic rootToken = body['accessToken'] ?? body['token'];
    if (rootToken is String && rootToken.isNotEmpty) {
      return rootToken;
    }

    final dynamic data = body['data'];
    if (data is Map<String, dynamic>) {
      final dynamic dataToken = data['accessToken'] ?? data['token'];
      if (dataToken is String && dataToken.isNotEmpty) {
        return dataToken;
      }
    }

    return null;
  }
}