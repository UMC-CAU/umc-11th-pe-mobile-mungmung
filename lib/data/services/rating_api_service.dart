import 'package:dio/dio.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';

class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);
  final Dio _publicDio;
  final Dio _authDio;

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _publicDio.get('/v7/members/$memberId/ratings');
    final data = response.data;
    final list = data is List<dynamic>
        ? data
        : parseResult(response, (value) => value as List<dynamic>);
    return list.map(_parseRating).toList();
  }

  Future<RatingDto> createRating(CreateRatingRequest request) async =>
      parseResult(
        await _authDio.post('/v7/ratings', data: request.toJson()),
        _parseRating,
      );

  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async => parseResult(
    await _authDio.patch(
      '/v7/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    ),
    _parseRating,
  );

  Future<void> deleteRating({required int ratingId}) async {
    final response = await _authDio.delete('/v7/ratings/$ratingId');
    if (response.statusCode != 200) {
      throw DioException.badResponse(
        statusCode: response.statusCode ?? 0,
        requestOptions: response.requestOptions,
        response: response,
      );
    }
    parseResponse<Object>(response, (value) => value as Object);
  }

  static RatingDto _parseRating(Object? value) =>
      RatingDto.fromJson(value as Map<String, dynamic>);
}

String writeErrorMessage(DioException error) => switch (apiErrorCode(error)) {
  'RATING409_1' => '이미 평점을 남긴 영화예요. 기존 평점을 확인해 주세요.',
  'RATING404_1' => '이미 삭제됐거나 존재하지 않는 평점이에요.',
  'COMMON403' || 'RATING403_1' => '본인이 작성한 평점만 수정하거나 삭제할 수 있어요.',
  _ => apiErrorMessage(error) ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.',
};

bool shouldRefreshAfterRatingError(DioException error) =>
    const {'RATING404_1', 'MEMBER404_1'}.contains(apiErrorCode(error)) ||
    error.response?.statusCode == 404;

String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return '회원 ID를 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}
