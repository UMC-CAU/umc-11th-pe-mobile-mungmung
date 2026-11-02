import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

// Public learning data, never an authenticated member ID.
const int sampleMemberId = 1;

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._service,
    this._movieService, [
    this.memberId = sampleMemberId,
  ]);
  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;
  final Map<int, TmdbMovieDto?> _moviesById = {};
  final Map<int, Future<TmdbMovieDto?>> _pendingMovies = {};
  Map<int, TmdbMovieDto?> get moviesById => Map.unmodifiable(_moviesById);
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  bool _isCurrent(int version) => !_disposed && version == _requestVersion;

  Future<TmdbMovieDto?> _fetchMovie(int id) async {
    try {
      return await _movieService.findMovieById(id);
    } catch (_) {
      // Movie enrichment must never discard a successful ratings response.
      return null;
    }
  }

  Future<void> load() async {
    if (_disposed) return;
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();
    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (!_isCurrent(version)) return;
      for (final id in rawRatings.map((rating) => rating.movieId).toSet()) {
        if (!_isCurrent(version)) return;
        if (!_moviesById.containsKey(id)) {
          final pending = _pendingMovies.putIfAbsent(id, () => _fetchMovie(id));
          final movie = await pending;
          if (!_isCurrent(version)) return;
          _moviesById[id] = movie;
          _pendingMovies.remove(id);
        }
      }
      if (!_isCurrent(version)) return;
      ratings = List.unmodifiable(
        rawRatings.map(
          (rating) => RatingWithMovie(
            rating: rating,
            movie: _moviesById[rating.movieId],
          ),
        ),
      );
      status = ratings.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = MyRatingsLoadStatus.error;
      message = '평점 응답을 읽지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }
    if (_isCurrent(version)) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    _pendingMovies.clear();
    super.dispose();
  }
}
