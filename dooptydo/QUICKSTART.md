# Quick Start Guide

## First Time Setup

### 1. Install Flutter
If you haven't already:
- Download Flutter SDK from https://flutter.dev/
- Add Flutter to your PATH
- Run `flutter doctor` to verify installation

### 2. Install Dependencies
```bash
cd e:\projects\utils\DooptyDo
flutter pub get
```

### 3. Run on Windows (Easiest)
```bash
flutter run -d windows
```

## Testing the App

### Test Directory Structure
Create a test folder with some duplicate files:

```powershell
# Create test directory
mkdir C:\temp\duplicate_test
cd C:\temp\duplicate_test

# Create some duplicate files
echo "test content" > file1.txt
echo "test content" > file2.txt
echo "different content" > file3.txt

# Create a subdirectory with more duplicates
mkdir subdir
echo "test content" > subdir\file4.txt
```

### Scan the Test Directory
1. Launch the app
2. Click "Select Directory"
3. Choose `C:\temp\duplicate_test`
4. Set Min File Size to `0` KB
5. Click "Start Scan"
6. You should see duplicate groups with file1.txt, file2.txt, and file4.txt

## Building for Production

### Windows
```bash
flutter build windows --release
# Output: build\windows\x64\runner\Release\
```

### Android (requires Android device or emulator)
```bash
flutter build apk --release
# Output: build\app\outputs\flutter-apk\app-release.apk
```

### iOS (requires Mac)
```bash
flutter build ios --release
# Then open Xcode and archive for distribution
```

## Development Tips

### Hot Reload
When running in debug mode, press `r` in the terminal to hot reload changes.

### Hot Restart
Press `R` (capital R) for full restart if hot reload doesn't work.

### Debug on Physical Device

#### Android
1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Connect via USB
4. Run `flutter devices` to verify
5. Run `flutter run -d <device-id>`

#### iOS
1. Connect iPhone/iPad to Mac
2. Trust the computer on device
3. Run `flutter devices`
4. Run `flutter run -d <device-id>`

## Common Commands

```bash
# Check Flutter installation
flutter doctor

# List available devices
flutter devices

# Run in debug mode
flutter run

# Run in release mode
flutter run --release

# Clean build files
flutter clean

# Update dependencies
flutter pub get

# Analyze code for issues
flutter analyze

# Format code
dart format lib/
```

## Next Steps

1. **Test on Windows**: Easiest platform to test
2. **Android Testing**: Use Android Studio emulator or physical device
3. **Add Features**: See README.md Phase 2 & 3 roadmap
4. **Optimize**: Profile performance on large directories

## Troubleshooting

### "No devices found"
- For Windows: Make sure you have Windows 10+ and `flutter config --enable-windows-desktop`
- For Android: Check USB debugging is enabled
- For iOS: Mac only, need Xcode installed

### Package version conflicts
```bash
flutter pub upgrade --major-versions
```

### Build fails
```bash
flutter clean
flutter pub get
flutter run
```

## Need Help?
- Flutter docs: https://docs.flutter.dev/
- Flutter community: https://flutter.dev/community
- Stack Overflow: Tag `flutter`
