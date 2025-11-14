import 'dart:io';
import 'package:flutter/material.dart';
import 'package:args/args.dart';
import 'screens/home_screen.dart';
import 'utils/app_logger.dart';

void main(List<String> arguments) {
  // Parse command-line arguments
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Display this help message',
    )
    ..addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Display version information',
    )
    ..addFlag('no-logging', negatable: false, help: 'Disable logging output');

  try {
    final results = parser.parse(arguments);

    // Handle --help
    if (results['help'] as bool) {
      _printHelp(parser);
      exit(0);
    }

    // Handle --version
    if (results['version'] as bool) {
      _printVersion();
      exit(0);
    }

    // Configure logging
    AppLogger.isLoggingEnabled = !(results['no-logging'] as bool);

    // Run the app
    runApp(const DooptyDoApp());
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln('');
    _printHelp(parser);
    exit(1);
  }
}

void _printHelp(ArgParser parser) {
  stdout.writeln('''
DooptyDo - Duplicate File Finder
A cross-platform application for finding and managing duplicate files.

USAGE:
    flutter run [OPTIONS]
    
    Or after building:
    DooptyDo.exe [OPTIONS]           (Windows)
    ./DooptyDo [OPTIONS]             (Linux/macOS)

OPTIONS:
${parser.usage}

DESCRIPTION:
    DooptyDo helps you find and remove duplicate files on your system using
    a smart multi-stage algorithm:
    
    1. Groups files by size (instant)
    2. Computes partial hash of first 8KB (fast)
    3. Computes full SHA-256 hash (only when needed)
    
    This approach is 10-100x faster than naive duplicate detection.

FEATURES:
    • Cross-platform support (Windows, Android, iOS)
    • Smart duplicate detection with minimal CPU usage
    • Safe deletion with confirmation dialogs
    • Real-time progress tracking
    • Statistics and space savings calculation
    • File size filtering
    • Responsive UI for desktop and mobile

EXAMPLES:
    # Run with default settings
    flutter run -d windows
    
    # Run with logging disabled
    flutter run -d windows --dart-define=no-logging
    
    # Show this help message
    flutter run -d windows -- --help
    
    # Show version information
    flutter run -d windows -- --version

KEYBOARD SHORTCUTS (Desktop):
    Ctrl+O        Select directory
    Ctrl+S        Start scan
    F5            Refresh results
    Delete        Delete selected file

PLATFORM-SPECIFIC NOTES:

    Windows:
        • Full file system access
        • No additional permissions required
        • Best performance for large scans
    
    Android:
        • Requires MANAGE_EXTERNAL_STORAGE permission (Android 11+)
        • Request permission on first run
        • May need manual activation in Settings
    
    iOS:
        • Sandboxed environment
        • Uses document picker for directory selection
        • Limited to user-accessible directories

DOCUMENTATION:
    README.md           Full user guide
    QUICKSTART.md       Getting started tutorial
    ARCHITECTURE.md     Technical documentation
    LOGGING.md          Logging configuration
    TODO.md             Feature roadmap

PROJECT WEBSITE:
    https://github.com/3wcircus/utils

SUPPORT:
    For issues, questions, or contributions, please visit:
    https://github.com/3wcircus/utils/issues

LICENSE:
    MIT License - See LICENSE file for details
''');
}

void _printVersion() {
  stdout.writeln('''
DooptyDo v1.0.0
Duplicate File Finder

Build Date: November 13, 2025
Flutter SDK: 3.9.2+
Platform: ${Platform.operatingSystem}

Copyright (c) 2025
License: MIT
''');
}

class DooptyDoApp extends StatelessWidget {
  const DooptyDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DooptyDo - Duplicate Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
