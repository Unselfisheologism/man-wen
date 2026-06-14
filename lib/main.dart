import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart_crash_reporter.dart';
import 'screens/home_screen.dart';
import 'services/preferences_service.dart';
import 'theme/app_theme.dart';

/// App-wide theme mode, updated when the user picks a different one in
/// the Settings screen. ManWenApp listens to this and rebuilds the
/// MaterialApp when it changes. Defaults to light (the cream/ink
/// "faded risograph" theme is the canonical Man Wen look).
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

void main() {
  // Install BEFORE runApp so the framework error handler is in place from
  // the very first frame. runZonedGuarded catches anything that escapes
  // the Flutter framework layer (uncaught async, futures, streams).
  DartCrashReporter.install();
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await PreferencesService.init();
    } catch (e, s) {
      // SharedPreferences can throw if the platform plugin response is
      // empty/malformed. Don't let it block runApp — show UI with empty
      // prefs and report the error.
      DartCrashReporter.report('PreferencesService.init failed', e, s);
    }
    runApp(const ManWenApp());
  }, (error, stack) {
    DartCrashReporter.report('Uncaught zone error', error, stack);
  });
}

class ManWenApp extends StatelessWidget {
  const ManWenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Man Wen',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
