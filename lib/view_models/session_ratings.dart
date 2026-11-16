import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';

class SessionRatings extends ChangeNotifier {
  SessionRatings(this._api, this._auth) : _version = _auth.sessionVersion {
    _auth.addListener(_resetForNewSession);
  }

  final RatingApiService _api;
  final AuthViewModel _auth;
  final _ratings = <int, RatingDto>{};
  final _busy = <int>{};
  int _version;
  bool _disposed = false;

  RatingDto? forMovie(int movieId) => _ratings[movieId];
  bool isBusy(int movieId) => _busy.contains(movieId);

  Future<void> save(int movieId, int score, String? comment) => _mutate(
    movieId,
    (current) async {
      if (current == null) {
        return _api.createRating(
          CreateRatingRequest(movieId: movieId, score: score, comment: comment),
        );
      }
      return _api.updateRating(
        ratingId: current.ratingId,
        score: score,
        comment: comment,
      );
    },
  );

  Future<void> delete(int movieId) => _mutate(movieId, (current) async {
    if (current != null) await _api.deleteRating(ratingId: current.ratingId);
    return null;
  });

  void updateCached(RatingDto rating) {
    if (_ratings[rating.movieId]?.ratingId != rating.ratingId) return;
    _ratings[rating.movieId] = rating;
    notifyListeners();
  }

  void removeCached(int ratingId) {
    final originalSize = _ratings.length;
    _ratings.removeWhere((_, rating) => rating.ratingId == ratingId);
    if (_ratings.length != originalSize) notifyListeners();
  }

  Future<void> _mutate(
    int movieId,
    Future<RatingDto?> Function(RatingDto?) operation,
  ) async {
    if (_disposed ||
        _auth.status != AuthStatus.signedIn ||
        !_busy.add(movieId)) {
      throw StateError('평점 요청을 시작할 수 없어요.');
    }
    final version = _version;
    notifyListeners();
    try {
      final rating = await operation(_ratings[movieId]);
      if (!_isCurrent(version)) return;
      if (rating == null) {
        _ratings.remove(movieId);
      } else {
        if (rating.movieId != movieId) {
          throw const FormatException('평점 응답의 영화 ID가 일치하지 않습니다.');
        }
        _ratings[movieId] = rating;
      }
    } on DioException catch (error) {
      if (_isCurrent(version) && apiErrorCode(error) == 'RATING404_1') {
        _ratings.remove(movieId);
      }
      rethrow;
    } finally {
      if (_isCurrent(version)) {
        _busy.remove(movieId);
        notifyListeners();
      }
    }
  }

  bool _isCurrent(int version) => !_disposed && _auth.isCurrent(version);

  void _resetForNewSession() {
    if (_version == _auth.sessionVersion) return;
    _version = _auth.sessionVersion;
    _ratings.clear();
    _busy.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_resetForNewSession);
    super.dispose();
  }
}
