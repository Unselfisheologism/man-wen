import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart_crash_reporter.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'services/preferences_service.dart';
import 'theme/app_theme.dart';

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
    return MaterialApp(
      title: 'Man Wen',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppLauncher(),
    );
  }
}

class AppLauncher extends StatefulWidget {
  const AppLauncher({super.key});

  @override
  State<AppLauncher> createState() => _AppLauncherState();
}

class _AppLauncherState extends State<AppLauncher> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    bool onboarded = false;
    try {
      onboarded = await PreferencesService.isOnboardingComplete();
    } catch (e, s) {
      DartCrashReporter.report('isOnboardingComplete failed', e, s);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => onboarded ? const HomeScreen() : const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
