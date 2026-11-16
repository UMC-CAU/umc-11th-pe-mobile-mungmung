import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/session_ratings.dart';
import 'package:movielog/core/network/api_error.dart';

// Public learning data, never an authenticated member ID.
const int sampleMemberId = 1;

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._service,
    this._movieService, [
    this.memberId = sampleMemberId,
    this._sessionRatings,
  ]);
  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;
  final SessionRatings? _sessionRatings;
  final Map<int, TmdbMovieDto?> _moviesById = {};
  final Map<int, Future<TmdbMovieDto?>> _pendingMovies = {};
  Map<int, TmdbMovieDto?> get moviesById => Map.unmodifiable(_moviesById);
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  String? refreshWarning;
  String? bulkDeleteMessage;
  final Set<int> _selectedRatingIds = {};
  Set<int> get selectedRatingIds => Set.unmodifiable(_selectedRatingIds);
  bool isDeletingSelected = false;

  void setSelected(int ratingId, bool selected) {
    if (isDeletingSelected) return;
    if (selected) {
      _selectedRatingIds.add(ratingId);
    } else {
      _selectedRatingIds.remove(ratingId);
    }
    notifyListeners();
  }

  Future<void> _refreshAfterWrite() async {
    await load();
    if (_disposed || status != MyRatingsLoadStatus.error) return;
    refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
    notifyListeners();
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    await _writeRating(ratingId, () async {
      final updated = await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
      if (!_disposed) _sessionRatings?.updateCached(updated);
    });
  }

  Future<void> deleteRating(int ratingId) => _writeRating(ratingId, () async {
    await _service.deleteRating(ratingId: ratingId);
    if (!_disposed) _sessionRatings?.removeCached(ratingId);
  });

  Future<void> _writeRating(int ratingId, Future<void> Function() write) async {
    try {
      await write();
    } on DioException catch (error) {
      if (!_disposed && apiErrorCode(error) == 'RATING404_1') {
        _sessionRatings?.removeCached(ratingId);
      }
      if (shouldRefreshAfterRatingError(error)) await load();
      rethrow;
    }
    await _refreshAfterWrite();
  }

  Future<void> deleteSelectedRatings() async {
    if (_disposed || isDeletingSelected || _selectedRatingIds.isEmpty) return;
    isDeletingSelected = true;
    bulkDeleteMessage = null;
    notifyListeners();
    var failed = 0;
    try {
      for (final id in _selectedRatingIds.toList()) {
        if (_disposed) return;
        try {
          await _service.deleteRating(ratingId: id);
          if (_disposed) return;
          _sessionRatings?.removeCached(id);
          _selectedRatingIds.remove(id);
        } catch (_) {
          failed++;
        }
      }
      await _refreshAfterWrite();
      if (failed > 0) {
        bulkDeleteMessage = '$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.';
      }
    } finally {
      isDeletingSelected = false;
      if (!_disposed) notifyListeners();
    }
  }

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
    refreshWarning = null;
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
      final visibleIds = ratings.map((entry) => entry.rating.ratingId).toSet();
      _selectedRatingIds.retainAll(visibleIds);
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
