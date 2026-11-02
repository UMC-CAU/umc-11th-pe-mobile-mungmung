import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';

class LiveOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('live v5 service contracts: nickname, email, member 1 ratings', () async {
    final client = createMovieLogClient();
    try {
      await HttpOverrides.runWithHttpOverrides(() async {
        final checks = MemberCheckService(client);
        expect(await checks.checkNickname('movielog-study-check'), isA<bool>());
        expect(
          await checks.checkEmail('movielog-study-check@example.com'),
          isA<bool>(),
        );
        final ratings = await RatingApiService(client).fetchMyRatings(1);
        expect(ratings, isNotEmpty);
        expect(ratings.every((rating) => rating.movieId > 0), isTrue);
        // ignore: avoid_print
        print(
          'v5 nickname/email: available bool; member 1: ${ratings.length} ratings; null comments: ${ratings.where((r) => r.comment == null).length}',
        );
      }, LiveOverrides());
    } finally {
      client.close(force: true);
    }
  }, skip: !const bool.fromEnvironment('RUN_MOVIELOG_LIVE_TEST'));
}
