import 'package:movielog/models/movie.dart';

enum FakeMovieResult { success, empty, error }

class FakeMovieService {
  const FakeMovieService({
    this.result = FakeMovieResult.success,
    this.delay = const Duration(seconds: 1),
  });

  final FakeMovieResult result;
  final Duration delay;

  Future<List<Movie>> fetchMovies() async {
    await Future<void>.delayed(delay);
    // TODO(5주차 유저별 평점 조회 API): 이 위치를 실제 API 호출로 교체한다.
    switch (result) {
      case FakeMovieResult.success:
        return mockMovies;
      case FakeMovieResult.empty:
        return const <Movie>[];
      case FakeMovieResult.error:
        throw Exception('Fake movie service failed');
    }
  }
}
