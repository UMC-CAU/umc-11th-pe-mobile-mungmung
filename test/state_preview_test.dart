import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/my_rating_screen.dart';
import 'package:movielog/widgets/movielog_button.dart';

import '../tool/state_preview.dart';

void main() {
  testWidgets(
    'preview routes reproduce signup duplicates and all ratings states',
    (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Use the system Korean font for readable exported test captures.
      await tester.runAsync(() async {
        final koreanFont = File('C:/Windows/Fonts/malgun.ttf');
        final font = FontLoader('Manrope')
          ..addFont(
            await koreanFont.exists()
                ? koreanFont.readAsBytes().then(ByteData.sublistView)
                : rootBundle.load('assets/fonts/Manrope-VariableFont_wght.ttf'),
          );
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
      });
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: key, child: const StatePreviewApp()),
      );
      await tester.pumpAndSettle();
      Future<void> capture(String filename) async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('docs/verification').create(recursive: true);
          await File('docs/verification/$filename.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tester.tap(find.text('Signup: duplicate nickname / email'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'movielog');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'movie@example.com',
      );
      await tester.pump();
      for (final index in [0, 1]) {
        final button = find.descendant(
          of: find.byType(MovieLogButton).at(index),
          matching: find.byType(ElevatedButton),
        );
        await tester.tap(button);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(
        find.text(
          '\uc774\ubbf8 \uc0ac\uc6a9 \uc911\uc778 \ub2c9\ub124\uc784\uc785\ub2c8\ub2e4.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          '\uc774\ubbf8 \uc0ac\uc6a9 \uc911\uc778 \uc774\uba54\uc77c\uc785\ub2c8\ub2e4.',
        ),
        findsOneWidget,
      );
      await capture('signup-duplicated');
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      for (final status in ['loading', 'empty', 'error', 'success']) {
        await tester.tap(find.text('Ratings: $status'));
        if (status == 'loading') {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          expect(find.byType(MyRatingsLoading), findsOneWidget);
        } else {
          await tester.pumpAndSettle();
          if (status == 'empty') {
            expect(find.byType(MyRatingsEmpty), findsOneWidget);
          }
          if (status == 'error') {
            expect(find.byType(MyRatingsError), findsOneWidget);
          }
          if (status == 'success') {
            expect(find.byType(MyRatingsSuccess), findsOneWidget);
          }
        }
        await capture('ratings-$status');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    },
  );
}
