import 'package:movielog/view_models/session_ratings.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';

import 'fake_token_storage.dart';

import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/screens/movie_detail_loader.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/widgets/rating_dialog.dart';
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

class RecordingRatings extends RatingApiService {
  RecordingRatings() : super(Dio(), Dio());

  CreateRatingRequest? request;
  int? updatedRatingId;
  int? deletedRatingId;

  @override
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    this.request = request;
    return RatingDto(
      ratingId: 1,
      movieId: request.movieId,
      score: request.score,
      comment: request.comment,
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    updatedRatingId = ratingId;
    return RatingDto(
      ratingId: ratingId,
      movieId: request!.movieId,
      score: score,
      comment: comment,
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<void> deleteRating({required int ratingId}) async {
    deletedRatingId = ratingId;
  }
}

void main() {
  testWidgets(
    'short Popular response renders, rebuild keeps request, rating keeps ID',
    (tester) async {
      final service = HomeMovieService();
      final viewModel = MovieHomeViewModel(service);
      final rebuild = ValueNotifier(0);
      final ratings = RecordingRatings();
      final auth = AuthViewModel(
        FakeTokenStorage(),
        AuthApiService(Dio()),
        MemberApiService(Dio()),
      )..status = AuthStatus.signedIn;
      addTearDown(auth.dispose);
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
            builder: (_, state) => MovieDetailLoader(
              movieId: int.parse(state.pathParameters['id']!),
              initialMovie: state.extra! as TmdbMovieDto,
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await viewModel.loadPopular();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => SessionRatings(ratings, auth),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
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
      expect(find.byType(RatingDialog), findsOneWidget);
      await tester.tap(find.byIcon(Icons.star_border).at(3));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '  네 점  ');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(ratings.request?.toJson(), {
        'movieId': 123,
        'score': 4,
        'comment': '네 점',
      });
      expect(find.byType(RatingDialog), findsNothing);
      expect(find.text('이번 세션의 내 평점 4/5'), findsOneWidget);
      await tester.tap(find.text('평점 수정'));
      await tester.pumpAndSettle();
      expect(find.text('네 점'), findsWidgets);
      await tester.enterText(find.byType(TextField), '수정했어요');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(ratings.updatedRatingId, 1);
      expect(find.text('수정했어요'), findsOneWidget);
      await tester.tap(find.byTooltip('평점 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(ratings.deletedRatingId, 1);
      expect(find.text('평점 남기기'), findsOneWidget);
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
