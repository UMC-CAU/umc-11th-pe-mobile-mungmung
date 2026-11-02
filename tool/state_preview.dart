import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/my_rating_screen.dart';
import 'package:movielog/screens/signup_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

// Isolated preview: no real API requests or mutations.
void main() => runApp(const StatePreviewApp());

class StatePreviewApp extends StatelessWidget {
  const StatePreviewApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light.copyWith(
      textTheme: AppTheme.light.textTheme.apply(fontFamily: 'Manrope'),
      appBarTheme: AppTheme.light.appBarTheme.copyWith(
        titleTextStyle: AppTheme.light.appBarTheme.titleTextStyle?.copyWith(
          fontFamily: 'Manrope',
        ),
      ),
    ),
    home: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('State preview')),
        body: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Mock responses. No real server requests.'),
            ),
            ListTile(
              title: const Text('Signup: duplicate nickname / email'),
              subtitle: const Text(
                'Enter valid values, then tap each check button.',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      SignupScreen(memberCheckService: PreviewMemberChecks()),
                ),
              ),
            ),
            for (final status in [
              MyRatingsLoadStatus.loading,
              MyRatingsLoadStatus.empty,
              MyRatingsLoadStatus.error,
              MyRatingsLoadStatus.success,
            ])
              ListTile(
                title: Text('Ratings: ${status.name}'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => MyRatingsViewModel(
                        PreviewRatings(status),
                        PreviewMovies(),
                      )..load(),
                      child: const MyRatingsScreen(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class PreviewMemberChecks extends MemberCheckService {
  PreviewMemberChecks() : super(Dio());
  @override
  Future<bool> checkNickname(String value) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return false;
  }

  @override
  Future<bool> checkEmail(String value) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return false;
  }
}

class PreviewRatings extends RatingApiService {
  PreviewRatings(this.status) : super(Dio());
  final MyRatingsLoadStatus status;
  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    if (status == MyRatingsLoadStatus.loading) {
      return Completer<List<RatingDto>>().future;
    }
    if (status == MyRatingsLoadStatus.error) {
      throw DioException(
        requestOptions: RequestOptions(path: '/v5/members/$memberId/ratings'),
        type: DioExceptionType.connectionError,
      );
    }
    if (status == MyRatingsLoadStatus.empty) return [];
    return [
      RatingDto(
        ratingId: 2,
        movieId: 680,
        score: 4,
        comment: '\ub2e4\uc2dc \ubd10\ub3c4 \uc88b\uc544\uc694',
        createdAt: DateTime(2026, 11, 1),
      ),
      RatingDto(
        ratingId: 3,
        movieId: 13,
        score: 3,
        comment: null,
        createdAt: DateTime(2026, 11, 1),
      ),
    ];
  }
}

class PreviewMovies extends TmdbMovieService {
  PreviewMovies() : super(Dio());
  @override
  Future<TmdbMovieDto?> findMovieById(int movieId) async => movieId == 680
      ? TmdbMovieDto.fromJson({'id': 680, 'title': '\ud384\ud504 \ud53d\uc158'})
      : null;
}
