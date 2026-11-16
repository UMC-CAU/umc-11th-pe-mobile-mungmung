import 'package:dio/dio.dart';
import 'package:movielog/data/models/common_response.dart';

String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  final code = data is Map ? data['code'] : null;
  return code is String ? code : null;
}

String? apiErrorMessage(DioException error) =>
    readServerMessage(error.response?.data);

bool isExpiredSession(DioException error) =>
    error.response?.statusCode == 401 &&
    const {'AUTH401_2', 'AUTH401_3', 'AUTH401_4'}.contains(apiErrorCode(error));

CommonResponse<T> parseResponse<T>(
  Response<dynamic> response,
  T Function(Object?) parse,
) {
  final data = response.data as Map<String, dynamic>;
  if (data['isSuccess'] == false) {
    throw DioException.badResponse(
      statusCode: response.statusCode ?? 0,
      requestOptions: response.requestOptions,
      response: response,
    );
  }
  return CommonResponse<T>.fromJson(data, parse);
}

T parseResult<T>(Response<dynamic> response, T Function(Object?) parse) =>
    parseResponse(response, parse).result ??
    (throw const FormatException('응답에 result가 없습니다.'));
