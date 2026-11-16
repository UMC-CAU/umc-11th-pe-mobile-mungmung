import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/main.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

class HomeMovieService extends TmdbMovieService {
  HomeMovieService() : super(Dio());
  int calls = 0;

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    calls++;
    return const TmdbMoviePageDto(
      page: 1,
      totalPages: 1,
      totalResults: 1,
      results: [
        TmdbMovieDto(
          id: 123,
          title: 'TMDB test movie',
          overview: 'Test overview',
          posterPath: null,
          backdropPath: null,
          releaseDate: null,
          genreIds: [],
          voteAverage: 8,
          popularity: 1,
        ),
      ],
    );
  }
}

void main() {
  testWidgets(
    'short Popular response renders, rebuild keeps request, rating keeps ID',
    (tester) async {
      final service = HomeMovieService();
      final viewModel = MovieHomeViewModel(service);
      final rebuild = ValueNotifier(0);
      addTearDown(viewModel.dispose);
      addTearDown(rebuild.dispose);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => ChangeNotifierProvider.value(
              value: viewModel,
              child: ValueListenableBuilder<int>(
                valueListenable: rebuild,
                builder: (_, _, _) => HomeScreen(key: ValueKey(rebuild.value)),
              ),
            ),
          ),
          GoRoute(
            path: '/movies/:id',
            builder: (_, state) =>
                MovieDetailScreen(movie: state.extra! as Movie),
          ),
        ],
      );
      addTearDown(router.dispose);
      await viewModel.loadPopular();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('TMDB test movie'), findsWidgets);
      expect(find.byIcon(Icons.image_not_supported_outlined), findsWidgets);
      rebuild.value++;
      await tester.pumpAndSettle();
      expect(service.calls, 1);
      await tester.ensureVisible(find.text('상세보기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('상세보기'));
      await tester.pumpAndSettle();
      final detail = tester.widget<MovieDetailScreen>(
        find.byType(MovieDetailScreen),
      );
      expect(detail.movie.id, '123');
      await tester.tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MovieRatingInput>(find.byType(MovieRatingInput)).movieId,
        '123',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing poster uses placeholder', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TmdbPosterImage(posterPath: null, width: 100, height: 150),
        ),
      ),
    );
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('poster load failure uses placeholder', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TmdbPosterImage(
            posterPath: '/missing.jpg',
            width: 100,
            height: 150,
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
