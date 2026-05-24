import 'package:flutter/foundation.dart';

/// Debug logging helper for the app
class DebugHelper {
  /// Print debug message to console
  static void log(String tag, String message) {
    if (kDebugMode) {
      print('🔵 [$tag] $message');
    }
  }

  /// Print error message to console
  static void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (kDebugMode) {
      print('🔴 [$tag] ERROR: $message');
      if (error != null) {
        print('   Exception: $error');
      }
      if (stackTrace != null) {
        print('   StackTrace: $stackTrace');
      }
    }
  }

  /// Print warning message to console
  static void warning(String tag, String message) {
    if (kDebugMode) {
      print('🟡 [$tag] WARNING: $message');
    }
  }

  /// Print success message to console
  static void success(String tag, String message) {
    if (kDebugMode) {
      print('🟢 [$tag] SUCCESS: $message');
    }
  }
}
