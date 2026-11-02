import 'dart:async';

import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/screens/signup_screen.dart';

class ChallengeChecks extends MemberCheckService {
  ChallengeChecks() : super(Dio());
  int nicknameCalls = 0;
  int emailCalls = 0;
  final nickname = Completer<bool>();
  final email = Completer<bool>();
  @override
  Future<bool> checkNickname(String value) {
    nicknameCalls++;
    return nickname.future;
  }

  @override
  Future<bool> checkEmail(String value) {
    emailCalls++;
    return email.future;
  }
}

class AvailableChecks extends MemberCheckService {
  AvailableChecks() : super(Dio());
  @override
  Future<bool> checkNickname(String value) async => true;
  @override
  Future<bool> checkEmail(String value) async => true;
}

class SignupChecks extends MemberCheckService {
  SignupChecks() : super(Dio());
  int nicknameCalls = 0;
  @override
  Future<bool> checkNickname(String value) async {
    nicknameCalls++;
    return false;
  }

  @override
  Future<bool> checkEmail(String value) async => true;
}

void main() {
  for (final fieldIndex in [0, 1]) {
    testWidgets(
      'challenge field $fieldIndex disables duplicates, restores errors without API',
      (tester) async {
        tester.view.physicalSize = const Size(420, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final service = ChallengeChecks();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: SignupScreen(memberCheckService: service),
          ),
        );
        final field = find.byType(TextFormField).at(fieldIndex);
        final button = find.descendant(
          of: find.byType(MovieLogButton).at(fieldIndex),
          matching: find.byType(ElevatedButton),
        );
        final original = fieldIndex == 0
            ? 'duplicatedName'
            : 'duplicate@example.com';
        final edited = fieldIndex == 0 ? 'anotherName' : 'another@example.com';
        String? error() => tester
            .widget<TextField>(find.byType(TextField).at(fieldIndex))
            .decoration
            ?.errorText;
        bool enabled() =>
            tester.widget<ElevatedButton>(button).onPressed != null;
        await tester.enterText(field, original);
        await tester.pump();
        expect(enabled(), isTrue);
        await tester.tap(button);
        await tester.pump();
        expect(enabled(), isFalse);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        (fieldIndex == 0 ? service.nickname : service.email).complete(false);
        await tester.pumpAndSettle();
        final duplicateError = error();
        expect(duplicateError, isNotNull);
        expect(enabled(), isFalse);
        await tester.enterText(field, edited);
        await tester.pump();
        expect(error(), isNull);
        expect(enabled(), isTrue);
        await tester.enterText(field, original);
        await tester.pump();
        expect(error(), duplicateError);
        expect(enabled(), isFalse);
        final decoration = tester
            .widget<TextField>(find.byType(TextField).at(fieldIndex))
            .decoration!;
        expect(decoration.fillColor, const Color(0xFFFFE0DE));
        expect(service.nicknameCalls, fieldIndex == 0 ? 1 : 0);
        expect(service.emailCalls, fieldIndex == 1 ? 1 : 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('valid checked fields and terms complete the sample signup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SignupScreen(
          memberCheckService: AvailableChecks(),
          onSignupComplete: () => completed = true,
        ),
      ),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'tester');
    await tester.enterText(fields.at(1), 'test@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.pump();
    final checks = find.widgetWithText(ElevatedButton, '중복 확인');
    await tester.tap(checks.first);
    await tester.pumpAndSettle();
    await tester.tap(checks.last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(ElevatedButton, '가입하기');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('server errors invalidate Form and cached duplicates return', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = SignupChecks();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SignupScreen(memberCheckService: service),
      ),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'tester');
    await tester.enterText(fields.at(1), 'test@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.pump();
    final buttons = find.widgetWithText(
      ElevatedButton,
      '\uc911\ubcf5 \ud655\uc778',
    );
    await tester.tap(buttons.first);
    await tester.pumpAndSettle();
    final nickname = tester.widget<TextField>(find.byType(TextField).first);
    expect(nickname.decoration?.errorText, isNotNull);
    expect(tester.state<FormState>(find.byType(Form)).validate(), isFalse);
    await tester.pump();
    await tester.enterText(fields.first, 'another');
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .decoration
          ?.errorText,
      isNull,
    );
    await tester.enterText(fields.first, 'tester');
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .decoration
          ?.errorText,
      isNotNull,
    );
    expect(service.nicknameCalls, 1);
    await tester.tap(buttons.last);
    await tester.pumpAndSettle();
    expect(
      find.text(
        '\uc0ac\uc6a9\ud560 \uc218 \uc788\ub294 \uc774\uba54\uc77c\uc785\ub2c8\ub2e4.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .decoration
          ?.errorText,
      isNotNull,
    );
  });
}
