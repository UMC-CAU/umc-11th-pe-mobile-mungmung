import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../tool/button_width_preview.dart';

import 'package:movielog/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/movielog_button.dart';

void main() {
  testWidgets(
    'preview renders all widths and loading centers with gray buttons',
    (tester) async {
      tester.view.physicalSize = const Size(420, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final loader = FontLoader(
        'Manrope',
      )..addFont(rootBundle.load('assets/fonts/Manrope-VariableFont_wght.ttf'));
      await loader.load();
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: boundaryKey, child: const ButtonWidthPreviewApp()),
      );
      await tester.pumpAndSettle();
      final buttons = find.byType(MovieLogButton);
      expect(tester.getSize(buttons.at(0)).width, lessThan(160));
      expect(tester.getSize(buttons.at(1)).width, 372);
      expect(tester.getSize(buttons.at(2)).width, 160);
      Future<void> capture(String name) async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('docs/verification').create(recursive: true);
          await File('docs/verification/$name.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('button-widths');
      await tester.tap(find.text('Loading'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Check'), findsNothing);
      for (var i = 0; i < 3; i++) {
        final button = find.descendant(
          of: buttons.at(i),
          matching: find.byType(ElevatedButton),
        );
        final spinner = find.descendant(
          of: buttons.at(i),
          matching: find.byType(CircularProgressIndicator),
        );
        final widget = tester.widget<ElevatedButton>(button);
        expect(widget.onPressed, isNull);
        expect(
          widget.style!.backgroundColor!.resolve({WidgetState.disabled}),
          AppColors.gray,
        );
        expect(
          (tester.getCenter(button) - tester.getCenter(spinner)).distance,
          lessThan(0.01),
        );
      }
      await capture('button-widths-loading');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('content width, full width and loading work with the app theme', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              Row(
                children: [
                  const Expanded(child: TextField()),
                  const SizedBox(width: 8),
                  MovieLogButton(label: 'Check', onPressed: () => taps++),
                ],
              ),
              MovieLogButton(
                label: 'Submit',
                width: double.infinity,
                onPressed: () => taps++,
              ),
              MovieLogButton(
                label: 'Loading',
                isLoading: true,
                onPressed: () => taps++,
              ),
            ],
          ),
        ),
      ),
    );
    final buttons = find.byType(MovieLogButton);
    expect(tester.getSize(buttons.at(0)).width, lessThan(200));
    expect(
      tester.getSize(buttons.at(1)).width,
      tester.getSize(find.byType(Scaffold)).width,
    );
    expect(find.text('Loading'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final loading = find.descendant(
      of: buttons.last,
      matching: find.byType(ElevatedButton),
    );
    expect(tester.widget<ElevatedButton>(loading).onPressed, isNull);
    await tester.tap(find.text('Check'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
