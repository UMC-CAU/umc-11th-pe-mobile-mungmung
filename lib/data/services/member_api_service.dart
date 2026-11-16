import 'package:dio/dio.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/models/member_info.dart';

class MemberApiService {
  MemberApiService(this._dio);
  final Dio _dio;

  Future<MemberInfo> fetchMe() async =>
      _parse(await _dio.get('/v7/members/me'));

  Future<MemberInfo> updateNickname(String nickname) async =>
      _parse(await _dio.patch('/v7/members/me', data: {'nickname': nickname}));

  MemberInfo _parse(Response<dynamic> response) => parseResult(
    response,
    (value) => MemberInfo.fromJson(value as Map<String, dynamic>),
  );
}
