import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

class LiveHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('live Discover loads genres and thirty unique OR-filtered movies', () async {
    await dotenv.load(fileName: '.env');
    final client = createTmdbClient();
    final vm = MovieListViewModel(TmdbMovieService(client));
    final originalDebugPrint = debugPrint;
    final logs = <String>[];
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
    try {
      await HttpOverrides.runWithHttpOverrides(
        () => vm.loadInitial(genreIds: [18, 878]), LiveHttpOverrides());
      expect(vm.status, MovieListLoadStatus.success);
      expect(vm.genres, isNotEmpty);
      expect(vm.movies.length, 30);
      expect(vm.movies.map((m) => m.id).toSet().length, 30);
      expect(vm.movies.every((m) => m.genreIds.any([18, 878].contains)), isTrue);
      expect(logs.any((line) => line.contains('with_genres: 18|878')), isTrue);
      final token = dotenv.env['TMDB_ACCESS_TOKEN']!;
      expect(logs.any((line) => line.contains(token)), isFalse);
      originalDebugPrint('Genre/Discover HTTP 200; OR=18|878; unique count=30');
    } finally {
      vm.dispose();
      client.close(force: true);
      debugPrint = originalDebugPrint;
    }
  }, skip: !const bool.fromEnvironment('RUN_TMDB_LIVE_TEST'));

  test('live invalid token produces masked 401 troubleshooting log', () async {
    final client = createTmdbClient();
    const invalidToken = 'deliberately-invalid-verification-token';
    client.options.headers['Authorization'] = 'Bearer $invalidToken';
    final originalDebugPrint = debugPrint;
    final logs = <String>[];
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
    try {
      try {
        await HttpOverrides.runWithHttpOverrides(
          () => TmdbMovieService(client).discoverMovies(page: 1, genreIds: [18, 878]),
          LiveHttpOverrides());
        fail('Invalid token must fail');
      } on DioException catch (error) {
        expect(error.response?.statusCode, 401);
      }
      expect(logs.any((line) => line.contains('[TMDB 오류 Status Code] 401')), isTrue);
      expect(logs.any((line) => line.contains('[TMDB 오류 메시지]')), isTrue);
      expect(logs.any((line) => line.contains(invalidToken)), isFalse);
      final safeLog = logs.where((line) => !line.contains('[TMDB 응답 Body]')).join('\n');
      await File('docs/verification/tmdb-failure.log').writeAsString('$safeLog\n');
      originalDebugPrint(safeLog);
    } finally {
      client.close(force: true);
      debugPrint = originalDebugPrint;
    }
  }, skip: !const bool.fromEnvironment('RUN_TMDB_LIVE_TEST'));

  test('live Popular request masks Authorization and returns DTOs', () async {
    await dotenv.load(fileName: '.env');
    final token = dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';
    expect(token.isNotEmpty, isTrue, reason: 'TMDB_ACCESS_TOKEN is missing');

    final logs = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
    final client = createTmdbClient();
    try {
      // Widget tests normally replace all HTTP responses with status 400.
      final page = await HttpOverrides.runWithHttpOverrides(
        () => TmdbMovieService(client).fetchPopular(),
        LiveHttpOverrides(),
      );
      final popular = page.results.take(5).toList();
      expect(logs.any((line) => line.contains('[TMDB 응답] 200 ')), isTrue);
      expect(
        logs.any((line) => line.contains('Authorization: Bearer ***')),
        isTrue,
      );
      expect(
        logs.any((line) => line.contains(token)),
        isFalse,
        reason: 'Authorization must never appear unmasked',
      );
      expect(popular.length, lessThanOrEqualTo(5));
      expect(popular, isNotEmpty);
      for (final movie in popular) {
        expect(movie.id, greaterThan(0));
      }
      originalDebugPrint(
        'Popular HTTP 200; DTO count=${page.results.length}; '
        'display count=${popular.length}; Authorization: Bearer ***',
      );
    } on DioException catch (error) {
      originalDebugPrint(
        'Popular HTTP ${error.response?.statusCode ?? 'no response'}; '
        'Authorization: Bearer ***',
      );
      fail(
        'Popular request failed: HTTP ${error.response?.statusCode ?? 'no response'}',
      );
    } finally {
      client.close(force: true);
      debugPrint = originalDebugPrint;
    }
  }, skip: !const bool.fromEnvironment('RUN_TMDB_LIVE_TEST'));
}
