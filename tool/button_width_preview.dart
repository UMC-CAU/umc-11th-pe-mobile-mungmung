import 'package:flutter/material.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/movielog_button.dart';

// Run independently: flutter run -t tool/button_width_preview.dart
void main() => runApp(const ButtonWidthPreviewApp());

class ButtonWidthPreviewApp extends StatefulWidget {
  const ButtonWidthPreviewApp({super.key});
  @override
  State<ButtonWidthPreviewApp> createState() => _ButtonWidthPreviewAppState();
}

class _ButtonWidthPreviewAppState extends State<ButtonWidthPreviewApp> {
  bool _loading = false;
  bool _enabled = true;
  int _taps = 0;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: Scaffold(
      appBar: AppBar(
        title: const Text(
          'MovieLogButton widths',
          style: TextStyle(fontFamily: 'Manrope', fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            for (final example in <(String, double?)>[
              ('null: content width', null),
              ('double.infinity: full width', double.infinity),
              ('160: fixed width', 160),
            ]) ...[
              Text(example.$1),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: MovieLogButton(
                  label: 'Check',
                  width: example.$2,
                  isLoading: _loading,
                  onPressed: _enabled ? () => setState(() => _taps++) : null,
                ),
              ),
              const SizedBox(height: 24),
            ],
            SwitchListTile(
              title: const Text('Loading'),
              value: _loading,
              onChanged: (value) => setState(() => _loading = value),
            ),
            SwitchListTile(
              title: const Text('Enabled'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            Text('Button taps: $_taps'),
          ],
        ),
      ),
    ),
  );
}
