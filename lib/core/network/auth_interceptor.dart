import 'package:dio/dio.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._storage, {
    required this.origin,
    required this.sessionVersion,
    required this.canAuthorize,
    required this.onExpired,
  });

  static const _versionKey = 'movielog.session_version';
  final TokenStorage _storage;
  final Uri origin;
  final int Function() sessionVersion;
  final bool Function() canAuthorize;
  final Future<void> Function(int) onExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final uri = options.uri;
    final path = uri.path;
    final protected =
        uri.origin == origin.origin &&
        (path == '/v7/members/me' ||
            path == '/v7/ratings' ||
            path.startsWith('/v7/ratings/'));
    if (!protected) {
      handler.next(options);
      return;
    }

    final version = sessionVersion();
    try {
      if (!canAuthorize()) throw StateError('로그인이 필요합니다.');
      final token = await _storage.readAccessToken();
      if (version != sessionVersion() ||
          !canAuthorize() ||
          token == null ||
          token.isEmpty) {
        throw StateError('로그인이 필요합니다.');
      }
      options.extra[_versionKey] = version;
      options.headers['Authorization'] = 'Bearer $token';
      // Prevent credentials from following redirects to another origin.
      options.followRedirects = false;
      handler.next(options);
    } catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final version = err.requestOptions.extra[_versionKey];
    if (version is int && isExpiredSession(err)) {
      await onExpired(version);
    }
    handler.next(err);
  }
}
