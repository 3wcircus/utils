import 'package:talker_flutter/talker_flutter.dart';

/// Global application logger using Talker
class AppLogger {
  static final Talker _talker = TalkerFlutter.init();

  /// Flag to enable/disable logging
  /// Set to false in production to disable all logs
  static bool isLoggingEnabled = true;

  /// Get the Talker instance (for viewing logs in UI if needed)
  static Talker get instance => _talker;

  /// Log an informational message
  static void info(String message) {
    if (isLoggingEnabled) {
      _talker.info(message);
    }
  }

  /// Log a warning message
  static void warning(String message) {
    if (isLoggingEnabled) {
      _talker.warning(message);
    }
  }

  /// Log an error with optional stack trace
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (isLoggingEnabled) {
      _talker.error(message, error, stackTrace);
    }
  }

  /// Log a debug message
  static void debug(String message) {
    if (isLoggingEnabled) {
      _talker.debug(message);
    }
  }

  /// Log a verbose message
  static void verbose(String message) {
    if (isLoggingEnabled) {
      _talker.verbose(message);
    }
  }

  /// Enable logging
  static void enable() {
    isLoggingEnabled = true;
  }

  /// Disable logging
  static void disable() {
    isLoggingEnabled = false;
  }
}
