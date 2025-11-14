# Logging Configuration

DooptyDo uses `talker_flutter` for comprehensive logging with the ability to enable/disable logs at runtime.

## Features

- **Configurable Logging**: Enable/disable logging via settings dialog or in code
- **Multiple Log Levels**: Info, Warning, Error, Debug, Verbose
- **Performance**: When disabled, logging has zero overhead
- **Development Friendly**: Easily enable for debugging, disable for production

## Usage

### Toggle Logging at Runtime

1. Open the app
2. Click the **Settings** icon (⚙️) in the top-right corner
3. Toggle the **"Enable Logging"** switch

### Configure Logging in Code

Edit `lib/main.dart`:

```dart
void main() {
  // Set to false in production to disable all logging
  AppLogger.isLoggingEnabled = true; // Change to false to disable logging
  
  runApp(const DooptyDoApp());
}
```

### Using the Logger

In your code:

```dart
import '../utils/app_logger.dart';

// Log information
AppLogger.info('Starting scan...');

// Log warnings
AppLogger.warning('File access denied: $path');

// Log errors with exception details
try {
  // some code
} catch (e, stackTrace) {
  AppLogger.error('Failed to process file', e, stackTrace);
}

// Debug messages (development only)
AppLogger.debug('Processing file: $path');

// Verbose messages (detailed debugging)
AppLogger.verbose('Hash calculation complete: $hash');
```

## Log Levels

| Level | Method | When to Use |
|-------|--------|-------------|
| Info | `AppLogger.info()` | General informational messages |
| Warning | `AppLogger.warning()` | Non-critical issues that don't stop execution |
| Error | `AppLogger.error()` | Errors that need attention |
| Debug | `AppLogger.debug()` | Development debugging information |
| Verbose | `AppLogger.verbose()` | Detailed step-by-step information |

## Current Logging Points

The app logs the following events:

1. **File Access Errors**: When a file can't be read during scanning
2. **Hash Calculation Errors**: When file hashing fails
3. **File Deletion Errors**: When file deletion fails
4. **Logging State Changes**: When logging is enabled/disabled

## Performance Impact

- **Logging Enabled**: Minimal overhead, logs written to console
- **Logging Disabled**: Zero overhead, all logging calls are skipped

## Production Deployment

For production builds:

1. Set `AppLogger.isLoggingEnabled = false` in `main.dart`
2. This ensures no logging overhead in production
3. Users can still enable it via Settings if needed for troubleshooting

## Viewing Logs

### During Development

Logs appear in the console/terminal where you run `flutter run`.

### Advanced: View Logs in App (Optional)

To add an in-app log viewer, you can use Talker's built-in UI:

```dart
import 'package:talker_flutter/talker_flutter.dart';

// Add a button to view logs
IconButton(
  icon: const Icon(Icons.bug_report),
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TalkerScreen(
          talker: AppLogger.instance,
        ),
      ),
    );
  },
)
```

## Example Output

```
[INFO] Starting scan...
[INFO] Found 1,234 files
[INFO] Computing partial hashes...
[WARNING] Error accessing file C:\temp\locked.txt: Permission denied
[INFO] 567 files remain after partial hash
[INFO] Computing full hashes...
[ERROR] Error hashing file C:\temp\corrupted.dat: Invalid format
[INFO] Found 23 duplicate groups (145 files, 2.34 GB wasted)
```

## Troubleshooting

### Logs not appearing?

1. Check that `AppLogger.isLoggingEnabled` is `true`
2. Make sure you're looking at the correct console/terminal
3. Try toggling the setting in the Settings dialog

### Too many logs?

Adjust the log level or disable logging entirely for cleaner output.

## Dependencies

- `talker_flutter: ^4.4.1` - Logging framework
- Configured in `pubspec.yaml`
- Wrapper class: `lib/utils/app_logger.dart`
