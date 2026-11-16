import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:movielog/screens/signup_screen.dart';
import 'package:movielog/screens/login_screen.dart';

import 'fake_token_storage.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';

void main() {
  testWidgets('signed-out startup opens login, and signup returns there', (
    tester,
  ) async {
    dotenv.loadFromString(envString: 'TMDB_ACCESS_TOKEN=test');
    await tester.pumpWidget(MovieLogApp(tokenStorage: FakeTokenStorage()));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SignupScreen), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
