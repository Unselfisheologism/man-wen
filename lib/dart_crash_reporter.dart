import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Routes Dart-level errors (widget build failures, async unhandled exceptions,
/// platform-dispatcher errors) to the native side via a MethodChannel, where
/// CrashReporter can persist them to /sdcard/Download/ManWen-dart-errors.log
/// and /sdcard/Android/data/com.manwen.app/files/dart_errors.log — same
/// discoverable locations as JVM crash logs.
///
/// Without this, Dart errors only go to logcat (which you can't see without
/// adb), so a Dart exception during startup just leaves the LaunchTheme
/// white background visible forever with no indication anything went wrong.
class DartCrashReporter {
  static const _channel = MethodChannel('com.manwen.app/dart_errors');

  static bool _installed = false;

  static void install() {
    if (_installed) return;
    _installed = true;

    // Widget build / framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      _send(
        'Flutter framework error',
        details.exceptionAsString(),
        details.stack?.toString() ?? '(no stack)',
      );
    };

    // Errors that bubble up to PlatformDispatcher (uncaught zone errors)
    PlatformDispatcher.instance.onError = (error, stack) {
      _send(
        'PlatformDispatcher error',
        error.toString(),
        stack.toString(),
      );
      return true; // mark as handled
    };
  }

  /// Report a caught error manually (e.g., from a try-catch around an init step).
  static void report(String message, Object error, StackTrace stack) {
    _send('Manual report: $message', error.toString(), stack.toString());
  }

  static void _send(String title, String message, String stack) {
    // Fire and forget — we can't await in onError handlers.
    _channel.invokeMethod('reportError', {
      'title': title,
      'message': message,
      'stack': stack,
    }).catchError((e) {
      // Last resort: write to debug console. User won't see this without adb
      // but at least it's logged somewhere.
      // ignore: avoid_print
      print('DartCrashReporter: failed to forward error: $e');
      return null;
    });
  }
}
