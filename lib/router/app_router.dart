import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/screens/my_rating_screen.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/main.dart' show AppShell, HomeScreen;
import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/screens/movie_detail_loader.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/session_ratings.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/screens/edit_profile_screen.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/screens/public_ratings_screen.dart';
import 'package:movielog/screens/splash_screen.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:provider/provider.dart';
import 'package:movielog/screens/signup_screen.dart' as signup;

/// Central definition of every route used by MovieLog.
abstract final class AppRouter {
  AppRouter._();
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter create(AuthViewModel auth) => GoRouter(
    initialLocation: '/splash',
    navigatorKey: rootNavigatorKey,
    refreshListenable: auth,
    redirect: (context, state) => authRedirect(auth.status, state.uri.path),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) {
          final auth = context.watch<AuthViewModel>();
          return SplashScreen(
            message: auth.message,
            onRetry: auth.status == AuthStatus.retryRequired
                ? auth.restoreSession
                : null,
          );
        },
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', redirect: (_, _) => '/register'),
      GoRoute(
        path: '/register',
        builder: (context, state) => signup.SignupScreen(
          memberCheckService: context.read<SignUpService>(),
          onSignupComplete: () => context.go('/login'),
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
                    builder: (context, state) {
                      final id = int.tryParse(
                        state.pathParameters['movieId'] ?? '',
                      );
                      if (id == null || id < 1) {
                        return Scaffold(
                          appBar: AppBar(),
                          body: const Center(child: Text('영화 ID가 올바르지 않습니다.')),
                        );
                      }
                      final extra = state.extra;
                      return MovieDetailLoader(
                        key: ValueKey(id),
                        movieId: id,
                        initialMovie: extra is TmdbMovieDto && extra.id == id
                            ? extra
                            : null,
                      );
                    },
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
                    path: 'profile/edit',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final auth = context.watch<AuthViewModel>();
                      final member = auth.member;
                      if (member == null) {
                        return Scaffold(
                          appBar: AppBar(title: const Text('프로필 수정')),
                          body: Center(
                            child: auth.memberStatus == MemberLoadStatus.error
                                ? TextButton(
                                    onPressed: auth.loadMember,
                                    child: const Text('내 정보 다시 불러오기'),
                                  )
                                : const CircularProgressIndicator(),
                          ),
                        );
                      }
                      return ChangeNotifierProvider(
                        create: (context) => EditProfileViewModel(
                          context.read<MemberApiService>(),
                          auth,
                        ),
                        child: EditProfileScreen(member: member),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'ratings',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, _) => const PublicRatingsScreen(),
                    routes: [
                      GoRoute(
                        path: ':memberId',
                        parentNavigatorKey: rootNavigatorKey,
                        redirect: (_, state) {
                          final id = int.tryParse(
                            state.pathParameters['memberId'] ?? '',
                          );
                          return id == null || id < 1 ? '/my/ratings' : null;
                        },
                        builder: (context, state) {
                          final id = int.parse(
                            state.pathParameters['memberId']!,
                          );
                          return ChangeNotifierProvider(
                            key: ValueKey(id),
                            create: (context) => MyRatingsViewModel(
                              context.read<RatingApiService>(),
                              context.read<TmdbMovieService>(),
                              id,
                              context.read<SessionRatings>(),
                            )..load(),
                            child: MyRatingsScreen(title: '회원 $id의 평점'),
                          );
                        },
                      ),
                    ],
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

String? authRedirect(AuthStatus status, String path) {
  if (status == AuthStatus.initializing || status == AuthStatus.retryRequired) {
    return path == '/splash' ? null : '/splash';
  }
  final public = const {'/login', '/register', '/signup'}.contains(path);
  if (status != AuthStatus.signedIn) return public ? null : '/login';
  return public || path == '/splash' || path == '/' ? '/home' : null;
}
