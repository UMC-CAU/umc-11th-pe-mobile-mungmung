import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

void main() {
  test(
    'DTOs convert snake_case, nullable fields and integer/double numbers',
    () {
      final movie = TmdbMovieDto.fromJson({
        'id': 12.0,
        'title': null,
        'overview': null,
        'poster_path': null,
        'backdrop_path': '/back.jpg',
        'release_date': null,
        'genre_ids': [18.0, 878],
        'vote_average': 8,
        'popularity': 12.5,
      });
      expect(movie.id, 12);
      expect(movie.title, '제목 없음');
      expect(movie.overview, '');
      expect(movie.posterPath, isNull);
      expect(movie.backdropPath, '/back.jpg');
      expect(movie.genreIds, [18, 878]);
      expect(movie.voteAverage, 8.0);
      expect(movie.popularity, 12.5);
      final defaults = TmdbMovieDto.fromJson({'id': 1});
      expect(defaults.genreIds, isEmpty);
      expect(defaults.voteAverage, 0.0);
      final page = TmdbMoviePageDto.fromJson({
        'page': 1.0,
        'results': null,
        'total_pages': 2.0,
        'total_results': 0,
      });
      expect(page.page, 1);
      expect(page.totalPages, 2);
      expect(page.results, isEmpty);
    },
  );

  test('Discover serializes OR IDs and omits with_genres for all', () async {
    final dio = Dio();
    final queries = <Map<String, dynamic>>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          queries.add(Map.of(options.queryParameters));
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'page': 1,
                'results': [],
                'total_pages': 1,
                'total_results': 0,
              },
            ),
          );
        },
      ),
    );
    final service = TmdbMovieService(dio);
    await service.discoverMovies(page: 1, genreIds: [18, 878, 18]);
    await service.discoverMovies(page: 1, genreIds: []);
    await service.discoverMovies(page: 1);
    expect(queries.first['with_genres'], '18|878');
    expect(queries.skip(1).every((q) => !q.containsKey('with_genres')), isTrue);
    expect(queries.every((q) => q['page'] == 1), isTrue);
    dio.close();
  });
}
