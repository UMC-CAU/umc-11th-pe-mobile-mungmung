import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/screens/my_rating_screen.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/main.dart'
    show
        AppShell,
        HomeScreen,
        MovieDetailScreen,
        OnboardingScreen,
        findMovieById;
import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/main.dart' show Movie;
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:provider/provider.dart';
import 'package:movielog/screens/signup_screen.dart' as signup;

/// Central definition of every route used by MovieLog.
abstract final class AppRouter {
  AppRouter._();
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const OnboardingScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => signup.SignupScreen(
          memberCheckService: context.read<MemberCheckService>(),
          onSignupComplete: () => context.go('/home'),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => ChangeNotifierProvider(
                  lazy: false,
                  create: (context) =>
                      MovieHomeViewModel(context.read<TmdbMovieService>())
                        ..loadPopular(),
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                builder: (context, state) => ChangeNotifierProvider(
                  lazy: false,
                  create: (context) =>
                      MovieListViewModel(context.read<TmdbMovieService>())
                        ..loadInitial(
                          genreIds: (state.uri.queryParameters['genre'] ?? '')
                              .split(',')
                              .map(int.tryParse)
                              .whereType<int>()
                              .toList(),
                        ),
                  child: const MoviesScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':movieId',
                    builder: (context, state) => MovieDetailScreen(
                      movie: state.extra is Movie
                          ? state.extra as Movie
                          : findMovieById(state.pathParameters['movieId']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'ratings', // 최종 경로: /my/ratings
                    parentNavigatorKey: rootNavigatorKey, // root Navigator 위에 표시해 하단 NavigationBar를 가립니다.
                    builder: (context, state) =>
                        ChangeNotifierProvider<MyRatingsViewModel>(
                          create: (context) => MyRatingsViewModel(
                            context.read<RatingApiService>(),
                            context.read<TmdbMovieService>(),
                            sampleMemberId, // 6주차는 학습용 ID 1입니다.
                          )..load(),
                          child: const MyRatingsScreen(),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  static int indexFromLocation(String path) {
    if (path.startsWith('/movies')) return 1;
    if (path.startsWith('/my')) return 2;

    return 0;
  }
}
