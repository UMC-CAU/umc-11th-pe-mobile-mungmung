import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/view_models/session_ratings.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';

import 'fake_token_storage.dart';

class TestAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final pending = <Completer<ResponseBody>>[];
  final _arrivals = StreamController<int>.broadcast(sync: true);

  Future<void> waitForRequests(int count) async {
    if (requests.length >= count) return;
    await _arrivals.stream
        .firstWhere((length) => length >= count)
        .timeout(const Duration(seconds: 2));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    final next = Completer<ResponseBody>();
    pending.add(next);
    _arrivals.add(requests.length);
    return next.future;
  }

  void reply(int index, int status, Map<String, dynamic> body) {
    pending[index].complete(
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  }

  @override
  void close({bool force = false}) => unawaited(_arrivals.close());
}

const member = {
  'email': 'tester@example.com',
  'nickname': 'Tester',
  'createdAt': '2026-01-01T00:00:00Z',
};
const invalidToken = {
  'isSuccess': false,
  'code': 'AUTH401_3',
  'message': 'Expired',
};

Map<String, dynamic> success(Object result) => {
  'isSuccess': true,
  'code': 'OK',
  'message': 'Success',
  'result': result,
};

void main() {
  late FakeTokenStorage storage;
  late Dio public;
  late Dio protected;
  late TestAdapter publicAdapter;
  late TestAdapter authAdapter;
  late AuthViewModel auth;

  setUp(() {
    const url = 'https://workbook.example';
    storage = FakeTokenStorage('old-token');
    publicAdapter = TestAdapter();
    authAdapter = TestAdapter();
    public = Dio(BaseOptions(baseUrl: url))..httpClientAdapter = publicAdapter;
    protected = Dio(BaseOptions(baseUrl: url))..httpClientAdapter = authAdapter;
    auth = AuthViewModel(
      storage,
      AuthApiService(public),
      MemberApiService(protected),
    );
    protected.interceptors.add(
      AuthInterceptor(
        storage,
        origin: Uri.parse(url),
        sessionVersion: () => auth.sessionVersion,
        canAuthorize: () => auth.mayAuthorize,
        onExpired: auth.expireSession,
      ),
    );
  });

  tearDown(() {
    auth.dispose();
    public.close(force: true);
    protected.close(force: true);
  });

  test(
    'restore holds protected routes, keeps token on 503, and retries',
    () async {
      final restoring = auth.restoreSession();
      await authAdapter.waitForRequests(1);
      expect(authRedirect(auth.status, '/my'), '/splash');
      expect(
        authAdapter.requests.single.headers['Authorization'],
        'Bearer old-token',
      );
      authAdapter.reply(0, 503, {'message': 'Unavailable'});
      await restoring;
      expect(auth.status, AuthStatus.retryRequired);
      expect(storage.token, 'old-token');

      final retry = auth.restoreSession();
      await authAdapter.waitForRequests(2);
      authAdapter.reply(1, 200, success(member));
      await retry;
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.member?.nickname, 'Tester');
      expect(authRedirect(auth.status, '/splash'), '/home');
    },
  );

  test(
    'old 401 responses cannot clear a later login or repeat expiry',
    () async {
      final restoring = auth.restoreSession();
      await authAdapter.waitForRequests(1);
      authAdapter.reply(0, 200, success(member));
      await restoring;

      final first = expectLater(
        protected.get('/v7/ratings'),
        throwsA(isA<DioException>()),
      );
      final second = expectLater(
        protected.get('/v7/ratings/12'),
        throwsA(isA<DioException>()),
      );
      final lateResponse = expectLater(
        protected.get('/v7/ratings/13'),
        throwsA(isA<DioException>()),
      );
      await authAdapter.waitForRequests(4);
      authAdapter.reply(1, 401, invalidToken);
      authAdapter.reply(2, 401, invalidToken);
      await Future.wait([first, second]);
      expect(storage.clears, 1);
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.consumeSessionExpired(), isTrue);
      expect(auth.consumeSessionExpired(), isFalse);

      final login = auth.login('tester@example.com', 'a-password');
      await publicAdapter.waitForRequests(1);
      final request = publicAdapter.requests.single;
      expect(request.path, '/v7/auth/login');
      expect(request.headers, isNot(contains('Authorization')));
      publicAdapter.reply(
        0,
        200,
        success({'accessToken': 'new-token', 'nickname': 'Tester'}),
      );
      await login;
      authAdapter.reply(3, 401, invalidToken);
      await lateResponse;
      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, 'new-token');
      expect(storage.clears, 1);

      await auth.logout();
      expect(storage.token, isNull);
      expect(auth.consumeSessionExpired(), isFalse);
    },
  );

  test(
    'a rating response arriving after logout cannot restore the session card',
    () async {
      final restoring = auth.restoreSession();
      await authAdapter.waitForRequests(1);
      authAdapter.reply(0, 200, success(member));
      await restoring;
      final session = SessionRatings(RatingApiService(public, protected), auth);
      addTearDown(session.dispose);
      final saving = session.save(550, 4, 'draft');
      await authAdapter.waitForRequests(2);
      final request = authAdapter.requests[1];
      expect(request.path, '/v7/ratings');
      expect(request.data, {'movieId': 550, 'score': 4, 'comment': 'draft'});
      await auth.logout();
      authAdapter.reply(
        1,
        201,
        success({
          'ratingId': 7,
          'movieId': 550,
          'score': 4,
          'comment': 'draft',
          'createdAt': '2026-11-16T00:00:00Z',
        }),
      );
      await saving;
      expect(session.forMovie(550), isNull);
      expect(session.isBusy(550), isFalse);
      expect(auth.status, AuthStatus.signedOut);
    },
  );
}
