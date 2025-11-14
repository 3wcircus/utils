# Development TODO & Feature Tracking

## Current Status: MVP Complete ✅

### Working Features
- [x] Directory selection (Windows, Android, iOS)
- [x] Multi-stage duplicate detection (size → partial hash → full hash)
- [x] File deletion with confirmation
- [x] Statistics panel (groups, files, space)
- [x] Progress indicators during scan
- [x] Responsive layout (desktop & mobile)
- [x] Platform permissions (Android)
- [x] Clean architecture (models/services/screens/widgets)

---

## Phase 2: Enhanced Features

### High Priority
- [ ] **Multiple Directory Selection**
  - Allow scanning multiple directories in one operation
  - Show combined results
  - Files: `lib/screens/home_screen.dart`

- [ ] **File Type Filters**
  - Dropdown for file types (All, Images, Videos, Documents, Audio)
  - Extension whitelist/blacklist
  - Files: `lib/services/duplicate_finder_service.dart`

- [ ] **Image Preview**
  - Thumbnail generation for images
  - Preview dialog before deletion
  - Dependency: `image` package
  - Files: `lib/widgets/file_preview.dart` (new)

- [ ] **Auto-Selection Helper**
  - Keep oldest/newest/largest file
  - Auto-select all but one
  - Bulk deletion
  - Files: `lib/widgets/selection_tools.dart` (new)

### Medium Priority
- [ ] **Export Results**
  - Export to CSV
  - Export to JSON
  - Include file paths, sizes, dates
  - Dependency: `csv` package
  - Files: `lib/services/export_service.dart` (new)

- [ ] **Undo Last Deletion**
  - Move files to app-specific trash
  - Restore within session
  - Clear trash on app close
  - Files: `lib/services/trash_service.dart` (new)

- [ ] **Settings Screen**
  - Dark mode toggle
  - Default minimum file size
  - Scan depth limit
  - Files: `lib/screens/settings_screen.dart` (new)

- [ ] **Scan History**
  - Save scan results to database
  - View previous scans
  - Compare scans over time
  - Dependency: `sqflite` package
  - Files: `lib/services/database_service.dart` (new)

### Low Priority
- [ ] **Dark Mode**
  - Implement dark theme
  - Theme switcher in settings
  - Files: `lib/main.dart`, `lib/theme/app_theme.dart` (new)

- [ ] **Localization**
  - Multi-language support
  - Start with English/Spanish
  - Files: `lib/l10n/` (new directory)

---

## Phase 3: Advanced Features

### High Priority
- [ ] **Background Scanning**
  - Use Flutter isolates
  - Scan doesn't block UI
  - Cancel in-progress scan
  - Files: `lib/services/background_scanner.dart` (new)

- [ ] **Scheduled Scans**
  - Weekly/monthly automatic scans
  - Notification of new duplicates
  - Dependency: `flutter_local_notifications`
  - Files: `lib/services/scheduler_service.dart` (new)

- [ ] **Cloud Storage Support**
  - Google Drive integration
  - Dropbox integration
  - OneDrive integration
  - Files: `lib/services/cloud_service.dart` (new)

### Medium Priority
- [ ] **Similar Image Detection**
  - Perceptual hashing (pHash)
  - Find similar (not identical) images
  - Configurable similarity threshold
  - Dependency: `image` package
  - Files: `lib/services/image_similarity_service.dart` (new)

- [ ] **Video Duplicate Detection**
  - Extract video frames
  - Compare keyframes
  - Handle different encodings
  - Dependency: `video_player`, `ffmpeg`
  - Files: `lib/services/video_analyzer_service.dart` (new)

- [ ] **Duplicate Prevention**
  - Monitor downloads folder
  - Warn before saving duplicates
  - Real-time scanning
  - Files: `lib/services/file_monitor_service.dart` (new)

- [ ] **Analytics Dashboard**
  - Scan statistics over time
  - Space saved chart
  - Most common duplicate types
  - Dependency: `fl_chart` package
  - Files: `lib/screens/analytics_screen.dart` (new)

### Low Priority
- [ ] **Network Scan**
  - Scan network drives
  - SMB/CIFS support
  - Handle network latency
  - Files: `lib/services/network_scanner.dart` (new)

- [ ] **Smart Suggestions**
  - ML-based file importance
  - Suggest which duplicates to keep
  - Learn from user patterns
  - Dependency: `tflite_flutter`
  - Files: `lib/services/ml_service.dart` (new)

---

## Technical Debt & Improvements

### Code Quality
- [ ] Add comprehensive unit tests
  - Test duplicate detection algorithm
  - Test file hashing
  - Test deletion logic
  - Target: 80% coverage

- [ ] Add widget tests
  - Test all custom widgets
  - Test user interactions
  - Test responsive layouts

- [ ] Add integration tests
  - Test full app flow
  - Test on multiple platforms
  - Test with large file sets

- [ ] Implement error boundaries
  - Graceful error handling
  - User-friendly error messages
  - Error reporting

- [ ] Add logging
  - Structured logging
  - Log levels (debug, info, warning, error)
  - Log file export for debugging

### Performance
- [ ] Optimize large directory scanning
  - Parallel file traversal
  - Batch processing
  - Memory pooling

- [ ] Implement caching
  - Cache file hashes
  - Cache directory structure
  - Invalidate on file changes

- [ ] Profile and optimize
  - Use Flutter DevTools profiler
  - Identify bottlenecks
  - Optimize hot paths

### UI/UX
- [ ] Improve mobile layout
  - Better touch targets
  - Swipe actions for deletion
  - Pull-to-refresh

- [ ] Add animations
  - Smooth transitions
  - Loading animations
  - Delete animations

- [ ] Accessibility
  - Screen reader support
  - High contrast mode
  - Keyboard navigation

- [ ] Onboarding
  - First-run tutorial
  - Feature highlights
  - Permission explanation

### Platform-Specific
- [ ] **Android**
  - Support scoped storage properly
  - Handle Android 14+ restrictions
  - Add Material You theming

- [ ] **iOS**
  - Improve document picker UX
  - Add iOS-specific features
  - Support iPad split view

- [ ] **Windows**
  - Context menu integration
  - File Explorer integration
  - Windows 11 styling

---

## Bug Fixes & Known Issues

### High Priority
- [ ] Handle permission denial gracefully
- [ ] Fix potential memory leak in long scans
- [ ] Validate all user inputs

### Medium Priority
- [ ] Improve error messages
- [ ] Handle symbolic links correctly
- [ ] Support Unicode filenames

### Low Priority
- [ ] Polish UI animations
- [ ] Improve progress accuracy
- [ ] Add tooltips to all buttons

---

## Documentation

- [x] README.md with full documentation
- [x] QUICKSTART.md for getting started
- [x] ARCHITECTURE.md explaining code structure
- [x] TODO.md (this file) for tracking work
- [ ] API documentation (dartdoc comments)
- [ ] Video tutorial/demo
- [ ] Blog post about the project
- [ ] Contributing guidelines

---

## Release Checklist

### Before v1.0 Release
- [ ] All Phase 1 features complete
- [ ] Unit tests for core logic
- [ ] Tested on Windows, Android, iOS
- [ ] Performance acceptable on large directories (10,000+ files)
- [ ] No critical bugs
- [ ] Documentation complete
- [ ] Privacy policy written
- [ ] Terms of service written

### Before v2.0 Release
- [ ] All Phase 2 features complete
- [ ] Widget tests complete
- [ ] Integration tests complete
- [ ] Accessibility tested
- [ ] Beta testing complete
- [ ] User feedback incorporated

### Before v3.0 Release
- [ ] All Phase 3 features complete
- [ ] Production-grade error handling
- [ ] Analytics implemented (optional)
- [ ] App Store/Play Store ready
- [ ] Marketing materials prepared

---

## Ideas for Future Consideration

- Blockchain-based file verification
- P2P duplicate detection across devices
- AI-powered file organization
- Integration with NAS systems
- Command-line interface version
- Web dashboard for remote monitoring
- Browser extension for download monitoring
- Duplicate detection as a service (API)

---

## Notes

- Keep features focused on core mission: find & remove duplicates
- Prioritize performance and reliability over features
- Always maintain cross-platform compatibility
- User privacy is paramount - no telemetry without consent
- Open source friendly - well-documented, modular code

---

**Last Updated**: November 13, 2025
**Current Version**: 1.0.0 (MVP)
**Next Milestone**: Phase 2 - Enhanced Features
