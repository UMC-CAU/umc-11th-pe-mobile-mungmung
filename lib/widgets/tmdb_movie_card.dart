import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/main.dart' show Movie;
import 'package:movielog/widgets/tmdb_poster_image.dart';

/// Keeps the TMDB ID intact when passing a movie to detail and rating screens.
Movie movieForDetail(TmdbMovieDto movie, {String genres = ''}) => Movie(
  id: movie.id.toString(),
  title: movie.title,
  genre: genres,
  year: DateTime.tryParse(movie.releaseDate ?? '')?.year ?? 0,
  poster: movie.posterPath == null || movie.posterPath!.isEmpty
      ? ''
      : 'https://image.tmdb.org/t/p/w500${movie.posterPath}',
  synopsis: movie.overview,
  rating: movie.voteAverage / 2,
);

class TmdbMovieCard extends StatelessWidget {
  const TmdbMovieCard({super.key, required this.movie, this.featured = false});

  final TmdbMovieDto movie;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    void openDetail() =>
        context.push('/movies/${movie.id}', extra: movieForDetail(movie));

    return GestureDetector(
      onTap: openDetail,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: featured ? 500 : 205,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TmdbPosterImage(
                posterPath: movie.posterPath,
                width: double.infinity,
                height: double.infinity,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: .82),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Chip(
                  avatar: const Icon(Icons.star, size: 16),
                  label: Text('${movie.voteAverage.toStringAsFixed(1)} / 10'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: featured ? 26 : 16,
                      ),
                    ),
                    Text(
                      movie.releaseDate?.isNotEmpty == true
                          ? movie.releaseDate!
                          : '개봉일 미정',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (featured) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: openDetail,
                          icon: const Icon(Icons.info),
                          label: const Text('상세보기'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
