import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class TmdbLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(options);
      return;
    }
    final maskedHeaders = Map<String, dynamic>.from(options.headers);
    for (final key in maskedHeaders.keys.toList()) {
      if (key.toLowerCase() == 'authorization') {
        maskedHeaders[key] = 'Bearer ***';
      }
    }
    debugPrint('[TMDB 요청] ${options.method} ${options.uri}');
    debugPrint('[TMDB 요청 Header] $maskedHeaders');
    if (options.queryParameters.isNotEmpty) {
      debugPrint('[TMDB 요청 Query] ${options.queryParameters}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(response);
      return;
    }
    debugPrint(
      '[TMDB 응답] ${response.statusCode} ${response.requestOptions.uri}',
    );
    debugPrint('[TMDB 응답 Body] ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(err);
      return;
    }
    debugPrint('[TMDB 오류] ${err.requestOptions.uri}');
    debugPrint('[TMDB 오류 Status Code] ${err.response?.statusCode ?? '응답 없음'}');
    debugPrint('[TMDB 오류 유형] ${err.type.name}');
    var safeMessage = err.message ?? '요청에 실패했습니다.';
    for (final entry in err.requestOptions.headers.entries) {
      if (entry.key.toLowerCase() == 'authorization') {
        final authorization = entry.value.toString();
        if (authorization.isNotEmpty) {
          safeMessage = safeMessage.replaceAll(authorization, 'Bearer ***');
          final token = authorization.replaceFirst(
            RegExp(r'^Bearer\s+', caseSensitive: false),
            '',
          );
          if (token.isNotEmpty) {
            safeMessage = safeMessage.replaceAll(token, '***');
          }
        }
      }
    }
    debugPrint('[TMDB 오류 메시지] $safeMessage');
    handler.next(err);
  }
}
