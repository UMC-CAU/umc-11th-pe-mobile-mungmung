import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/main.dart' show MovieDetailScreen;
import 'package:movielog/view_models/session_ratings.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:movielog/widgets/tmdb_movie_card.dart';
import 'package:provider/provider.dart';

class MovieDetailLoader extends StatefulWidget {
  const MovieDetailLoader({
    super.key,
    required this.movieId,
    this.initialMovie,
  });

  final int movieId;
  final TmdbMovieDto? initialMovie;

  @override
  State<MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<MovieDetailLoader> {
  late final Future<TmdbMovieDto> _movieFuture = widget.initialMovie == null
      ? context.read<TmdbMovieService>().fetchMovieDetail(widget.movieId)
      : Future.value(widget.initialMovie!);

  @override
  Widget build(BuildContext context) => FutureBuilder<TmdbMovieDto>(
    future: _movieFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      final movie = snapshot.data;
      if (snapshot.hasError || movie == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('영화를 불러오지 못했습니다.')),
        );
      }
      final session = context.watch<SessionRatings>();
      final rating = session.forMovie(movie.id);
      final busy = session.isBusy(movie.id);
      return MovieDetailScreen(
        movie: movieForDetail(movie),
        sessionRating: rating,
        onRate: busy ? null : () => _openRating(session, movie.id, rating),
        onDeleteRating: rating == null || busy
            ? null
            : () => _deleteRating(session, movie.id),
      );
    },
  );

  Future<void> _openRating(
    SessionRatings session,
    int movieId,
    RatingDto? rating,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        initialScore: rating?.score ?? 0,
        initialComment: rating?.comment,
        onAccessError: _notify,
        onSubmit: (score, comment) => session.save(movieId, score, comment),
      ),
    );
    if (!mounted || saved != true) return;
    _notify(rating == null ? '평점을 등록했습니다.' : '평점을 수정했습니다.');
  }

  Future<void> _deleteRating(SessionRatings session, int movieId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이 평점을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      await session.delete(movieId);
      if (mounted) _notify('평점을 삭제했습니다.');
    } on DioException catch (error) {
      if (mounted) _notify(writeErrorMessage(error));
    } catch (_) {
      if (mounted) _notify('평점을 삭제하지 못했어요.');
    }
  }

  void _notify(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}
