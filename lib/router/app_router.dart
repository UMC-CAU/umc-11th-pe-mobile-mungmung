import 'package:go_router/go_router.dart';
import 'package:movielog/main.dart'
    show
        AppShell,
        HomeScreen,
        MovieDetailScreen,
        MoviesScreen,
        OnboardingScreen,
        findMovieById;
import 'package:movielog/screens/profile_screen.dart';
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
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                builder: (context, state) => MoviesScreen(
                  selectedGenres: (state.uri.queryParameters['genre'] ?? '')
                      .split(',')
                      .where((genre) => genre.isNotEmpty)
                      .toSet(),
                ),
                routes: [
                  GoRoute(
                    path: ':movieId',
                    builder: (context, state) => MovieDetailScreen(
                      movie: findMovieById(state.pathParameters['movieId']!),
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
