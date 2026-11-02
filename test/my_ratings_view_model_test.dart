import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

RatingDto rating(int id, int movieId) => RatingDto.fromJson({
  'ratingId': id,
  'movieId': movieId,
  'score': 4,
  'comment': null,
  'createdAt': '2026-11-01T19:00:27.956Z',
});

class Ratings extends RatingApiService {
  Ratings() : super(Dio());
  final requests = <Completer<List<RatingDto>>>[];
  final memberIds = <int>[];
  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) {
    memberIds.add(memberId);
    final result = Completer<List<RatingDto>>();
    requests.add(result);
    return result.future;
  }
}

class Movies extends TmdbMovieService {
  Movies() : super(Dio());
  final calls = <int>[];
  Completer<TmdbMovieDto?>? pending;
  bool fail = false;
  @override
  Future<TmdbMovieDto?> findMovieById(int id) async {
    calls.add(id);
    if (pending != null) return pending!.future;
    if (fail) {
      throw DioException(requestOptions: RequestOptions(path: '/movie/$id'));
    }
    return TmdbMovieDto.fromJson({'id': id, 'title': 'TMDB title'});
  }
}

void main() {
  test('Rating JSON supports null comment and ISO registration date', () {
    final result = rating(2, 13);
    expect(result.ratingId, 2);
    expect(result.movieId, 13);
    expect(result.score, 4);
    expect(result.comment, isNull);
    expect(result.createdAt, DateTime.utc(2026, 11, 1, 19, 0, 27, 956));
    expect(
      RatingDto.fromJson({
        'ratingId': 1,
        'movieId': 2,
        'score': 5,
        'comment': 'review',
        'createdAt': '2026-01-01T00:00:00Z',
      }).comment,
      'review',
    );
  });
  test(
    'idle loading success; duplicate movies fetched once and cached',
    () async {
      final service = Ratings();
      final movies = Movies();
      final vm = MyRatingsViewModel(service, movies);
      addTearDown(vm.dispose);
      expect(vm.status, MyRatingsLoadStatus.idle);
      final first = vm.load();
      expect(vm.status, MyRatingsLoadStatus.loading);
      service.requests[0].complete([rating(1, 13), rating(2, 13)]);
      await first;
      expect(service.memberIds, [1]);
      expect(vm.status, MyRatingsLoadStatus.success);
      expect(vm.ratings.length, 2);
      expect(vm.ratings.first.movie?.title, 'TMDB title');
      final second = vm.load();
      service.requests[1].complete([rating(1, 13)]);
      await second;
      expect(movies.calls, [13]);
      expect(vm.moviesById[13]?.title, 'TMDB title');
    },
  );
  test('TMDB failure preserves every rating and caches placeholders', () async {
    final service = Ratings();
    final movies = Movies()..fail = true;
    final vm = MyRatingsViewModel(service, movies);
    addTearDown(vm.dispose);
    final load = vm.load();
    service.requests[0].complete([rating(1, 13), rating(2, 13)]);
    await load;
    expect(vm.status, MyRatingsLoadStatus.success);
    expect(vm.ratings.length, 2);
    expect(vm.ratings.every((entry) => entry.movie == null), isTrue);
    expect(movies.calls, [13]);
  });
  test('empty and API failure use separate states and mapped errors', () async {
    final service = Ratings();
    final vm = MyRatingsViewModel(service, Movies());
    addTearDown(vm.dispose);
    final empty = vm.load();
    service.requests[0].complete([]);
    await empty;
    expect(vm.status, MyRatingsLoadStatus.empty);
    final failed = vm.load();
    final error = DioException(
      requestOptions: RequestOptions(path: '/ratings'),
      response: Response(
        requestOptions: RequestOptions(path: '/ratings'),
        statusCode: 404,
      ),
    );
    service.requests[1].completeError(error);
    await failed;
    expect(vm.status, MyRatingsLoadStatus.error);
    expect(vm.message, writeMyRatingsErrorMessage(error));
  });
  test('old ratings response cannot replace a new request', () async {
    final service = Ratings();
    final vm = MyRatingsViewModel(service, Movies());
    addTearDown(vm.dispose);
    final old = vm.load();
    final current = vm.load();
    service.requests[1].complete([rating(2, 680)]);
    await current;
    service.requests[0].complete([rating(1, 13)]);
    await old;
    expect(vm.ratings.single.rating.movieId, 680);
  });
  test(
    'late movie response after disposal changes neither cache nor state',
    () async {
      final service = Ratings();
      final movies = Movies()..pending = Completer<TmdbMovieDto?>();
      final vm = MyRatingsViewModel(service, movies);
      final load = vm.load();
      service.requests[0].complete([rating(1, 13)]);
      await Future<void>.delayed(Duration.zero);
      vm.dispose();
      movies.pending!.complete(TmdbMovieDto.fromJson({'id': 13}));
      await load;
      expect(vm.moviesById, isEmpty);
      expect(vm.ratings, isEmpty);
    },
  );
  test(
    'overlapping loads share pending detail; only latest applies it',
    () async {
      final service = Ratings();
      final movies = Movies()..pending = Completer<TmdbMovieDto?>();
      final vm = MyRatingsViewModel(service, movies);
      addTearDown(vm.dispose);
      final old = vm.load();
      service.requests[0].complete([rating(1, 13)]);
      await Future<void>.delayed(Duration.zero);
      final current = vm.load();
      service.requests[1].complete([rating(2, 13)]);
      await Future<void>.delayed(Duration.zero);
      movies.pending!.complete(
        TmdbMovieDto.fromJson({'id': 13, 'title': 'shared'}),
      );
      await Future.wait([old, current]);
      expect(movies.calls, [13]);
      expect(vm.ratings.single.rating.ratingId, 2);
    },
  );
}
