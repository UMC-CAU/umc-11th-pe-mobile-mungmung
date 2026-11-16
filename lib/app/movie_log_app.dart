import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/session_ratings.dart';
import 'package:provider/provider.dart';

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({super.key, this.tokenStorage});

  final TokenStorage? tokenStorage;

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  final _publicClient = createMovieLogClient();
  final _authClient = createMovieLogClient();
  final _tmdbClient = createTmdbClient();
  late final _storage = widget.tokenStorage ?? SecureTokenStorage();
  late final _memberApi = MemberApiService(_authClient);
  late final _auth = AuthViewModel(
    _storage,
    AuthApiService(_publicClient),
    _memberApi,
  );
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authClient.interceptors.add(
      AuthInterceptor(
        _storage,
        origin: Uri.parse(_authClient.options.baseUrl),
        sessionVersion: () => _auth.sessionVersion,
        canAuthorize: () => _auth.mayAuthorize,
        onExpired: _auth.expireSession,
      ),
    );
    _router = AppRouter.create(_auth);
    _auth.restoreSession();
  }

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    _publicClient.close(force: true);
    _authClient.close(force: true);
    _tmdbClient.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: _auth),
      Provider.value(value: _memberApi),
      Provider(create: (_) => TmdbMovieService(_tmdbClient)),
      Provider(create: (_) => SignUpService(_publicClient)),
      Provider(create: (_) => RatingApiService(_publicClient, _authClient)),
      ChangeNotifierProvider(
        create: (context) =>
            SessionRatings(context.read<RatingApiService>(), _auth),
      ),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      routerConfig: _router,
    ),
  );
}
