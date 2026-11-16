import 'package:movielog/view_models/session_ratings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/my_rating_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/models/member_info.dart';

import 'fake_token_storage.dart';

import 'package:movielog/view_models/my_ratings_view_model.dart';

class SampleRatings extends RatingApiService {
  SampleRatings() : super(Dio(), Dio());
  @override
  Future<List<RatingDto>> fetchMyRatings(int id) async => [];
}

class SampleMovies extends TmdbMovieService {
  SampleMovies() : super(Dio());
}

void main() {
  testWidgets(
    'Consumer renders loading empty error success and null placeholders',
    (tester) async {
      final vm = MyRatingsViewModel(SampleRatings(), SampleMovies());
      addTearDown(vm.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MyRatingsScreen(),
          ),
        ),
      );
      expect(find.byType(MyRatingsLoading), findsOneWidget);
      await vm.load();
      await tester.pump();
      expect(find.byType(MyRatingsEmpty), findsOneWidget);
      vm.status = MyRatingsLoadStatus.error;
      vm.message = 'mapped network error';
      vm.notifyListeners();
      await tester.pump();
      expect(find.text('mapped network error'), findsOneWidget);
      vm.ratings = [
        RatingWithMovie(
          rating: RatingDto(
            ratingId: 1,
            movieId: 13,
            score: 3,
            comment: null,
            createdAt: DateTime(2026, 11, 1),
          ),
        ),
        RatingWithMovie(
          rating: RatingDto(
            ratingId: 2,
            movieId: 680,
            score: 4,
            comment: 'review',
            createdAt: DateTime(2026, 11, 1),
          ),
          movie: TmdbMovieDto.fromJson({'id': 680, 'title': 'TMDB title'}),
        ),
      ];
      vm.status = MyRatingsLoadStatus.success;
      vm.notifyListeners();
      await tester.pump();
      expect(find.text('TMDB title'), findsOneWidget);
      expect(find.textContaining('#13'), findsOneWidget);
      expect(find.text('review'), findsOneWidget);
      expect(find.text('null'), findsNothing);
      expect(find.textContaining('2026.11.01'), findsNWidgets(2));
      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isTrue);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).bottomNavigationBar,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'profile push opens root ratings without tabs and back returns to profile',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth =
          AuthViewModel(
              FakeTokenStorage(),
              AuthApiService(Dio()),
              MemberApiService(Dio()),
            )
            ..status = AuthStatus.signedIn
            ..updateMember(
              MemberInfo(
                email: 'tester@example.com',
                nickname: 'Tester',
                createdAt: DateTime(2026),
              ),
            );
      final router = AppRouter.create(auth);
      final ratings = SampleRatings();
      addTearDown(auth.dispose);
      addTearDown(router.dispose);
      router.go('/my');
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            Provider<RatingApiService>.value(value: ratings),
            ChangeNotifierProvider(
              create: (_) => SessionRatings(ratings, auth),
            ),
            Provider<TmdbMovieService>.value(value: SampleMovies()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tile = find.byType(ListTile);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      await tester.enterText(find.byType(TextFormField), '42');
      await tester.tap(find.text('평점 조회'));
      await tester.pumpAndSettle();
      expect(find.byType(MyRatingsScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.textContaining('memberId 1'), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(MyRatingsScreen), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
