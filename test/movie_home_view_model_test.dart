import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';

TmdbMovieDto movie(int id) => TmdbMovieDto(
  id: id,
  title: 'Movie $id',
  overview: '',
  posterPath: null,
  backdropPath: null,
  releaseDate: null,
  genreIds: [],
  voteAverage: 8,
  popularity: 1,
);

class ControlledMovieService extends TmdbMovieService {
  ControlledMovieService() : super(Dio());
  final response = Completer<TmdbMoviePageDto>();
  int calls = 0;

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) {
    calls++;
    return response.future;
  }

  void complete(int count) => response.complete(
    TmdbMoviePageDto(
      page: 1,
      results: List.generate(count, (i) => movie(i + 1)),
      totalPages: 1,
      totalResults: count,
    ),
  );
}

void main() {
  for (final count in [0, 2, 8]) {
    test('Popular handles $count results and keeps at most five', () async {
      final service = ControlledMovieService();
      final viewModel = MovieHomeViewModel(service);
      addTearDown(viewModel.dispose);
      final states = <MovieHomeLoadStatus>[];
      viewModel.addListener(() => states.add(viewModel.status));
      final request = viewModel.loadPopular();
      await viewModel.loadPopular();
      expect(service.calls, 1);
      service.complete(count);
      await request;
      expect(viewModel.popularMovies.length, count > 5 ? 5 : count);
      expect(states, [
        MovieHomeLoadStatus.loading,
        count == 0 ? MovieHomeLoadStatus.empty : MovieHomeLoadStatus.success,
      ]);
      if (count > 0) expect(viewModel.popularMovies.first.id, 1);
    });
  }

  test('failed request switches loading to error', () async {
    final service = ControlledMovieService();
    final viewModel = MovieHomeViewModel(service);
    addTearDown(viewModel.dispose);
    final request = viewModel.loadPopular();
    service.response.completeError(
      DioException(requestOptions: RequestOptions()),
    );
    await request;
    expect(viewModel.status, MovieHomeLoadStatus.error);
    expect(viewModel.message, isNotEmpty);
  });

  test('request completing after dispose does not notify', () async {
    final service = ControlledMovieService();
    final viewModel = MovieHomeViewModel(service);
    final request = viewModel.loadPopular();
    viewModel.dispose();
    service.complete(2);
    await request;
  });
}
