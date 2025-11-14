# Command-Line Arguments Test

## Testing Help Option

To test the `--help` option, run:

```bash
# After building the app
.\build\windows\x64\runner\Release\DooptyDo.exe --help

# Or using flutter run (note: may not work in all scenarios)
flutter run -d windows --dart-define=help
```

## Example Output

```
DooptyDo - Duplicate File Finder
A cross-platform application for finding and managing duplicate files.

USAGE:
    flutter run [OPTIONS]
    
    Or after building:
    DooptyDo.exe [OPTIONS]           (Windows)
    ./DooptyDo [OPTIONS]             (Linux/macOS)

OPTIONS:
-h, --help          Display this help message
-v, --version       Display version information
    --no-logging    Disable logging output

DESCRIPTION:
    DooptyDo helps you find and remove duplicate files on your system using
    a smart multi-stage algorithm:
    
    1. Groups files by size (instant)
    2. Computes partial hash of first 8KB (fast)
    3. Computes full SHA-256 hash (only when needed)
    
    This approach is 10-100x faster than naive duplicate detection.

[... full help output ...]
```

## Testing Version Option

```bash
.\build\windows\x64\runner\Release\DooptyDo.exe --version

# Or short form
.\build\windows\x64\runner\Release\DooptyDo.exe -v
```

## Example Output

```
DooptyDo v1.0.0
Duplicate File Finder

Build Date: November 13, 2025
Flutter SDK: 3.9.2+
Platform: windows

Copyright (c) 2025
License: MIT
```

## Testing No-Logging Option

```bash
# Run with logging disabled
.\build\windows\x64\runner\Release\DooptyDo.exe --no-logging
```

## Available Options

| Option | Short | Description |
|--------|-------|-------------|
| `--help` | `-h` | Display comprehensive help message |
| `--version` | `-v` | Display version information |
| `--no-logging` | | Disable all logging output |

## Notes

- All print statements have been replaced with `stdout.writeln` for CLI output
- This uses the `args` package for proper argument parsing
- Help and version commands exit immediately (exit code 0)
- Invalid arguments show an error and help message (exit code 1)
- The app uses `AppLogger` with talker_flutter for application logging
