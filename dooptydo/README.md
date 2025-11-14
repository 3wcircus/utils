# DooptyDo - Duplicate File Finder

A cross-platform Flutter application for finding and managing duplicate files on Windows, Android, and iOS devices.

## Features

- 🔍 **Smart Duplicate Detection**: Multi-stage scanning using size, partial hash, and full hash comparison
- 📊 **Detailed Statistics**: See total duplicates, wasted space, and potential savings
- 🗂️ **File Management**: Preview and selectively delete duplicate files
- 🎯 **Filtering Options**: Set minimum file size to focus on larger files
- 💻 **Cross-Platform**: Works on Windows desktop, Android, and iOS
- 🚀 **Efficient Scanning**: Optimized algorithm reduces unnecessary file hashing

## How It Works

DooptyDo uses a three-stage approach to efficiently find duplicates:

1. **Size Grouping**: Groups files by size (instant comparison)
2. **Partial Hash**: Computes hash of first 8KB for size-matched files
3. **Full Hash**: Only files with matching partial hashes get full SHA-256 hash

This approach significantly reduces CPU and disk I/O compared to hashing every file.

## Installation

### Prerequisites

- Flutter SDK 3.9.2 or higher
- For Windows: Windows 10 or higher
- For Android: Android SDK (API level 21+)
- For iOS: Xcode 14+ and iOS 12+

### Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd DooptyDo
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run on your platform:
   ```bash
   # Windows
   flutter run -d windows

   # Android (device/emulator must be connected)
   flutter run -d android

   # iOS (Mac only, device/simulator must be connected)
   flutter run -d ios
   ```

## Platform-Specific Notes

### Windows
- Full file system access
- No additional permissions required
- Best performance for large directory scans

### Android
- **Android 11+ (API 30+)**: Requires `MANAGE_EXTERNAL_STORAGE` permission
  - App will request this permission on first run
  - You may need to grant this in system settings manually
- **Android 10 and below**: Uses standard `STORAGE` permission
- **Scoped Storage**: On Android 11+, you can use scoped storage for user-selected directories without broad permissions

### iOS
- Sandboxed environment - limited to app documents and user-selected directories
- Uses document picker for directory selection
- Cannot scan system directories or other app data
- Best used for Photos library and user documents

## Usage

1. **Select Directory**: Tap "Select Directory" to choose a folder to scan
2. **Set Filters** (optional): Set minimum file size in KB to ignore small files
3. **Start Scan**: Tap "Start Scan" to begin duplicate detection
4. **Review Results**: Expand duplicate groups to see all files
5. **Delete Files**: Tap the delete icon next to files you want to remove
   - Always keeps at least one copy
   - Confirmation dialog prevents accidental deletion

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   ├── file_entry.dart               # File metadata model
│   └── duplicate_group.dart          # Duplicate group model
├── services/
│   ├── duplicate_finder_service.dart # Core scanning logic
│   └── permission_service.dart       # Permission handling
├── screens/
│   └── home_screen.dart              # Main UI screen
└── widgets/
    ├── duplicate_group_card.dart     # Duplicate group display
    ├── scan_controls.dart            # Scan control panel
    └── stats_panel.dart              # Statistics display
```

## Dependencies

- `file_picker`: Directory and file selection
- `crypto`: SHA-256 hashing for duplicate detection
- `permission_handler`: Storage permission management
- `path_provider`: Access to common directories
- `path`: File path utilities
- `shared_preferences`: User settings persistence

## Development Roadmap

### Phase 1: MVP ✅
- [x] Basic directory scanning
- [x] Multi-stage duplicate detection
- [x] File deletion with confirmation
- [x] Basic statistics
- [x] Cross-platform support (Windows, Android, iOS)

### Phase 2: Enhanced Features (Future)
- [ ] Multiple directory selection
- [ ] File type filters (images, videos, documents, etc.)
- [ ] Image preview for duplicates
- [ ] Auto-select oldest/newest/largest files
- [ ] Export duplicate list to CSV
- [ ] Undo last deletion
- [ ] Dark mode support

### Phase 3: Advanced Features (Future)
- [ ] Background scanning service
- [ ] Scheduled automatic scans
- [ ] Cloud storage integration (Google Drive, Dropbox)
- [ ] Similarity detection for images (perceptual hashing)
- [ ] Duplicate prevention (warn before saving duplicates)
- [ ] Scan history and analytics

## Performance Tips

1. **Start Small**: Test with a smaller directory first
2. **Use Size Filter**: Set minimum file size to skip small files (e.g., 100KB)
3. **Close Other Apps**: Scanning is CPU and I/O intensive
4. **SSD Recommended**: Faster on solid-state drives vs. spinning disks

## Safety Features

- **Confirmation Dialogs**: All deletions require confirmation
- **Keep One Copy**: Algorithm never deletes the last copy
- **Error Handling**: Gracefully handles permission errors and inaccessible files
- **No Automatic Deletion**: User must explicitly choose files to delete

## Troubleshooting

### Android: Permission Issues
- Go to Settings → Apps → DooptyDo → Permissions
- Enable "Files and media" or "All files access"
- Restart the app

### iOS: Can't Access Directory
- iOS restricts file system access
- Use the document picker to select folders
- Consider using Files app to organize documents first

### Windows: Slow Scanning
- Check antivirus software (may slow file access)
- Use SSD for better performance
- Close other disk-intensive applications

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## License

This project is open source and available under the MIT License.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Uses SHA-256 hashing from [crypto](https://pub.dev/packages/crypto)
- File picker from [file_picker](https://pub.dev/packages/file_picker)
