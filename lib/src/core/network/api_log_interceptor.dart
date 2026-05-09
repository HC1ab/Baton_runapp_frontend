import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

final _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
  ),
);

/// Dev-only request/response logger.
/// Attach to Dio only when ENV=dev.
class ApiLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.i(
      '┌── REQUEST ──────────────────────────\n'
      '│ ${options.method} ${options.baseUrl}${options.path}\n'
      '│ Headers: ${_formatHeaders(options.headers)}\n'
      '│ Body: ${_formatData(options.data)}\n'
      '└─────────────────────────────────────',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i(
      '┌── RESPONSE ─────────────────────────\n'
      '│ ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.path}\n'
      '│ Body: ${_formatData(response.data)}\n'
      '└─────────────────────────────────────',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      '┌── ERROR ────────────────────────────\n'
      '│ ${err.response?.statusCode ?? 'NO STATUS'} '
      '${err.requestOptions.method} ${err.requestOptions.path}\n'
      '│ Message: ${err.message}\n'
      '│ Response: ${_formatData(err.response?.data)}\n'
      '└─────────────────────────────────────',
    );
    handler.next(err);
  }

  String _formatHeaders(Map<String, dynamic> headers) {
    // Authorization 토큰은 보안상 마스킹
    final masked = Map<String, dynamic>.from(headers);
    if (masked.containsKey('Authorization')) {
      final token = masked['Authorization'].toString();
      masked['Authorization'] = token.length > 20
          ? '${token.substring(0, 20)}...'
          : token;
    }
    return masked.toString();
  }

  String _formatData(dynamic data) {
    if (data == null) return 'null';
    if (data is Map || data is List) {
      return data.toString();
    }
    return data.toString();
  }
}
