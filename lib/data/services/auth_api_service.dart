import 'package:dio/dio.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/models/login_models.dart';

class AuthApiService {
  AuthApiService(this._dio);
  final Dio _dio;

  Future<LoginResult> login(LoginRequest request) async => parseResult(
    await _dio.post('/v7/auth/login', data: request.toJson()),
    (value) => LoginResult.fromJson(value as Map<String, dynamic>),
  );
}
