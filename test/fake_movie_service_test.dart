import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/services/fake_movie_service.dart';

void main() {
  test('Success returns the existing mock list', () async {
    final movies = await const FakeMovieService().fetchMovies();
    expect(movies, mockMovies);
  });

  test('Empty returns an empty list', () async {
    final movies = await const FakeMovieService(result: FakeMovieResult.empty)
        .fetchMovies();
    expect(movies, isEmpty);
  });

  test('Failure completes the Future with an exception', () async {
    await expectLater(
      const FakeMovieService(result: FakeMovieResult.error).fetchMovies(),
      throwsA(isA<Exception>()),
    );
  });
}
