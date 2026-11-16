import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

TmdbMovieDto listMovie(int id) => TmdbMovieDto(
  id: id,
  title: 'Movie $id',
  overview: '',
  posterPath: null,
  backdropPath: null,
  releaseDate: null,
  genreIds: [18],
  voteAverage: 8,
  popularity: 1,
);
TmdbMoviePageDto listPage(List<int> ids, {int page = 1, int totalPages = 1}) =>
    TmdbMoviePageDto(
      page: page,
      results: ids.map(listMovie).toList(),
      totalPages: totalPages,
      totalResults: ids.length,
    );

class ListMovieService extends TmdbMovieService {
  ListMovieService() : super(Dio());
  int genreCalls = 0;
  final requests = <({int page, List<int>? genres})>[];
  Future<TmdbMoviePageDto> Function(int, List<int>?)? respond;

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async {
    genreCalls++;
    return const [
      TmdbGenreDto(id: 18, name: '드라마'),
      TmdbGenreDto(id: 878, name: 'SF'),
    ];
  }

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    requests.add((page: page, genres: genreIds?.toList()));
    return respond == null ? listPage([1, 2]) : respond!(page, genreIds);
  }
}

void main() {
  test('deduplicates IDs across pages and stops at 30', () async {
    final service = ListMovieService();
    service.respond = (page, _) async => page == 1
        ? listPage(List.generate(20, (i) => i + 1), totalPages: 10)
        : listPage(
            List.generate(20, (i) => i + 15),
            page: page,
            totalPages: 10,
          );
    final vm = MovieListViewModel(service);
    addTearDown(vm.dispose);
    await vm.loadInitial();
    expect(service.requests.map((r) => r.page), [1, 2]);
    expect(vm.movies.map((m) => m.id), List.generate(30, (i) => i + 1));
    expect(vm.status, MovieListLoadStatus.success);
    expect(service.genreCalls, 1);
  });

  test('empty pages end loading safely', () async {
    final service = ListMovieService()..respond = (_, _) async => listPage([]);
    final vm = MovieListViewModel(service);
    addTearDown(vm.dispose);
    await vm.loadInitial();
    expect(vm.status, MovieListLoadStatus.empty);
    expect(service.requests.length, 1);
  });

  test('genre IDs normalize, reload from page one, all omits IDs', () async {
    final service = ListMovieService();
    final vm = MovieListViewModel(service);
    addTearDown(vm.dispose);
    await vm.loadInitial();
    await vm.selectGenres([878, 18, 18]);
    expect(service.requests.last.page, 1);
    expect(service.requests.last.genres, [18, 878]);
    expect(vm.selectedGenreIds, [18, 878]);
    await vm.selectGenres([]);
    expect(service.requests.last.genres, isNull);
    expect(vm.selectedGenreIds, isNull);
  });

  test(
    'refresh preserves movies and IDs; concurrent actions do not request',
    () async {
      final service = ListMovieService();
      final vm = MovieListViewModel(service);
      addTearDown(vm.dispose);
      await vm.loadInitial(genreIds: [18, 878]);
      final pending = Completer<TmdbMoviePageDto>();
      service.respond = (_, _) => pending.future;
      final refresh = vm.refresh();
      expect(vm.isLoading, isTrue);
      expect(vm.isRefreshing, isTrue);
      expect(vm.movies.map((m) => m.id), [1, 2]);
      await vm.selectGenres([28]);
      await vm.refresh();
      await vm.retry();
      expect(service.requests.length, 2);
      expect(service.requests.last.genres, [18, 878]);
      pending.complete(listPage([3]));
      await refresh;
      expect(vm.movies.single.id, 3);
      expect(vm.isRefreshing, isFalse);
    },
  );

  test(
    'genre failure restores last success; cancel and retry keep failed IDs',
    () async {
      final service = ListMovieService();
      final vm = MovieListViewModel(service);
      addTearDown(vm.dispose);
      await vm.loadInitial(genreIds: [18]);
      final pending = Completer<TmdbMoviePageDto>();
      service.respond = (_, _) => pending.future;
      final change = vm.selectGenres([878]);
      expect(vm.movies, isEmpty);
      pending.completeError(DioException(requestOptions: RequestOptions()));
      await change;
      expect(vm.movies.map((m) => m.id), [1, 2]);
      expect(vm.status, MovieListLoadStatus.error);
      expect(vm.displayedGenreIds, [18]);
      expect(vm.selectedGenreIds, [878]);
      expect(vm.errorVersion, 1);
      vm.cancelError();
      expect(vm.movies.length, 2);
      service.respond = (_, _) async => listPage([99]);
      await vm.retry();
      expect(service.requests.last.page, 1);
    expect(service.requests.last.genres, [878]);
      expect(vm.movies.single.id, 99);
      expect(vm.displayedGenreIds, [878]);
    },
  );

  test(
    'page two failure never publishes partial data; retry restarts page one',
    () async {
      final service = ListMovieService();
      final vm = MovieListViewModel(service);
      addTearDown(vm.dispose);
      await vm.loadInitial();
      service.respond = (page, _) async {
        if (page == 2) throw DioException(requestOptions: RequestOptions());
        return listPage([4], totalPages: 2);
      };
      await vm.refresh();
      expect(vm.movies.map((m) => m.id), [1, 2]);
      service.respond = (page, _) async =>
          listPage([page + 10], page: page, totalPages: 2);
      await vm.retry();
      expect(service.requests.map((r) => r.page), [1, 1, 2, 1, 2]);
      expect(vm.movies.map((m) => m.id), [11, 12]);
    },
  );
}
