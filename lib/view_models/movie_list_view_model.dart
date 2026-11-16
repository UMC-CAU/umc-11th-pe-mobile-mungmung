import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);
  final TmdbMovieService _service;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];
  List<int>? _selectedGenreIds;
  List<int>? get selectedGenreIds => _selectedGenreIds;
  List<int>? _displayedGenreIds;
  List<int>? get displayedGenreIds => _displayedGenreIds;
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;
  int errorVersion = 0;
  bool isRefreshing = false;
  bool _disposed = false;
  bool _genresLoaded = false;
  bool _hasSuccessfulLoad = false;
  List<TmdbMovieDto> _lastSuccessfulMovies = const [];
  List<int>? _lastSuccessfulGenreIds;

  bool get isLoading => status == MovieListLoadStatus.loading;
  bool get hasSuccessfulLoad => _hasSuccessfulLoad;

  List<int>? _normalize(List<int>? ids) {
    final result = ids?.where((id) => id > 0).toSet().toList() ?? <int>[];
    result.sort();
    return result.isEmpty ? null : List<int>.unmodifiable(result);
  }

  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({
    List<int>? genreIds,
  }) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    while (!_disposed && byId.length < 30) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreIds: genreIds,
      );
      if (_disposed) return const [];
      for (final movie in page.results) {
        byId.putIfAbsent(movie.id, () => movie);
        if (byId.length == 30) break;
      }
      if (pageNumber >= page.totalPages || page.results.isEmpty) break;
      pageNumber++;
    }
    return byId.values.toList();
  }

  Future<void> loadInitial({List<int>? genreIds}) async {
    if (isLoading || _disposed) return;
    _selectedGenreIds = _normalize(genreIds);
    await _load(clearList: true);
  }

  Future<void> selectGenres(List<int>? genreIds) async {
    if (isLoading || _disposed) return;
    final next = _normalize(genreIds);
    if (listEquals(next, _selectedGenreIds) &&
        _hasSuccessfulLoad &&
        status != MovieListLoadStatus.error) {
      return;
    }
    _selectedGenreIds = next;
    await _load(clearList: true);
  }

  Future<void> refresh() async {
    if (isLoading || _disposed) return;
    await _load(clearList: false, refreshing: true);
  }

  Future<void> retry() async {
    if (isLoading || _disposed) return;
    await _load(clearList: false);
  }

  void cancelError() {
    if (_disposed || isLoading) return;
    // The failed request's IDs stay selected for the next refresh/retry.
    status = _hasSuccessfulLoad
        ? (movies.isEmpty
              ? MovieListLoadStatus.empty
              : MovieListLoadStatus.success)
        : MovieListLoadStatus.error;
    notifyListeners();
  }

  Future<void> _load({required bool clearList, bool refreshing = false}) async {
    final requestGenres = _selectedGenreIds;
    status = MovieListLoadStatus.loading;
    isRefreshing = refreshing;
    message = null;
    if (clearList) {
      movies = const [];
      _displayedGenreIds = requestGenres;
    }
    notifyListeners();
    try {
      if (!_genresLoaded) {
        final result = await _service.fetchGenres();
        if (_disposed) return;
        genres = result;
        _genresLoaded = true;
      }
      final result = await fetchUpToThirtyMovies(genreIds: requestGenres);
      if (_disposed) return;
      movies = List<TmdbMovieDto>.unmodifiable(result);
      _displayedGenreIds = requestGenres;
      _lastSuccessfulMovies = movies;
      _lastSuccessfulGenreIds = requestGenres;
      _hasSuccessfulLoad = true;
      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } catch (_) {
      if (_disposed) return;
      movies = _lastSuccessfulMovies;
      _displayedGenreIds = _lastSuccessfulGenreIds;
      status = MovieListLoadStatus.error;
      message = '네트워크 상태를 확인하고\n다시 시도해 주세요.';
      errorVersion++;
    } finally {
      if (!_disposed) {
        isRefreshing = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
