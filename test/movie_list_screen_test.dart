import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';

import 'movie_list_view_model_test.dart' show ListMovieService, listPage;

Future<void> showList(WidgetTester tester, MovieListViewModel vm) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: vm,
      child: const MaterialApp(home: MoviesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('bottom sheet applies multiple IDs only after confirmation', (
    tester,
  ) async {
    final service = ListMovieService();
    final vm = MovieListViewModel(service);
    addTearDown(vm.dispose);
    await vm.loadInitial();
    await showList(tester, vm);
    await tester.tap(find.byTooltip('장르 필터'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('genre-checkbox-18')));
    await tester.tap(find.byKey(const ValueKey('genre-checkbox-878')));
    expect(service.requests.length, 1);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(service.requests.last.genres, [18, 878]);
    await tester.tap(find.widgetWithText(FilterChip, '전체'));
    await tester.pumpAndSettle();
    expect(service.requests.last.genres, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'refresh failure keeps cards, cancel closes dialog, retry recovers',
    (tester) async {
      final service = ListMovieService();
      final vm = MovieListViewModel(service);
      addTearDown(vm.dispose);
      await vm.loadInitial(genreIds: [18, 878]);
      await showList(tester, vm);
      final pending = Completer<TmdbMoviePageDto>();
      service.respond = (_, _) => pending.future;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(vm.isLoading, isTrue);
      expect(find.text('Movie 1'), findsOneWidget);
      final filter = tester.widget<IconButton>(
        find.byWidgetPredicate((widget) => widget is IconButton && widget.tooltip == '장르 필터'),
      );
      expect(filter.onPressed, isNull);
      final requestCount = service.requests.length;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pump(const Duration(milliseconds: 300));
      expect(service.requests.length, requestCount);
      pending.completeError(DioException(requestOptions: RequestOptions()));
      await tester.pumpAndSettle();
      expect(find.text('영화를 불러오지 못했어요'), findsOneWidget);
      expect(find.text('Movie 1'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      service.respond = (_, _) async =>
          throw DioException(requestOptions: RequestOptions());
      await vm.refresh();
      await tester.pumpAndSettle();
      service.respond = (_, _) async => listPage([99]);
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Movie 99'), findsOneWidget);
      expect(find.text('Movie 1'), findsNothing);
      expect(service.requests.last.genres, [18, 878]);
      expect(service.requests.last.page, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
