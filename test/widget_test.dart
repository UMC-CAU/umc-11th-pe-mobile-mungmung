import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';

void main() {
  testWidgets('MovieLog opens the onboarding screen', (tester) async {
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();
    expect(find.text('영화의 순간을 기록하세요'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '시작하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
