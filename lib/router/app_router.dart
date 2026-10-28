import 'package:go_router/go_router.dart';
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
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const OnboardingScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) =>
            signup.SignupScreen(onSignupComplete: () => context.go('/home')),
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
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
