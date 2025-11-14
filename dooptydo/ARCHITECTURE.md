# DooptyDo Architecture

## Overview
DooptyDo is a cross-platform Flutter app using clean architecture principles with clear separation of concerns.

## Project Structure

```
DooptyDo/
├── lib/
│   ├── main.dart                       # App entry point
│   ├── models/                         # Data models
│   │   ├── file_entry.dart            # File metadata
│   │   └── duplicate_group.dart       # Grouped duplicates
│   ├── services/                       # Business logic
│   │   ├── duplicate_finder_service.dart  # Core scanning algorithm
│   │   └── permission_service.dart        # Platform permissions
│   ├── screens/                        # Full-screen views
│   │   └── home_screen.dart           # Main application screen
│   └── widgets/                        # Reusable UI components
│       ├── duplicate_group_card.dart  # Display duplicate group
│       ├── scan_controls.dart         # Directory picker & scan button
│       └── stats_panel.dart           # Statistics display
├── android/                            # Android-specific code
├── ios/                                # iOS-specific code
├── windows/                            # Windows-specific code
├── test/                               # Unit & widget tests
├── pubspec.yaml                        # Dependencies
├── README.md                           # Full documentation
└── QUICKSTART.md                       # Getting started guide
```

## Architecture Layers

### 1. Models Layer (`models/`)
**Purpose**: Define data structures

- `FileEntry`: Represents a single file with path, size, date, and hash
- `DuplicateGroup`: Groups files with identical content hashes

**Characteristics**:
- Pure Dart classes
- No dependencies on Flutter or services
- Immutable where possible
- Contains basic computed properties (fileName, totalSize, wastedSpace)

### 2. Services Layer (`services/`)
**Purpose**: Business logic and platform integration

#### `DuplicateFinderService`
- Multi-stage duplicate detection algorithm
- File system traversal
- Hash computation (SHA-256)
- File deletion
- Progress callbacks

**Key Methods**:
- `collectFiles()`: Recursive directory scan with filtering
- `findDuplicates()`: Three-stage duplicate detection
- `calculateFileHash()`: Full or partial file hashing
- `deleteFile()`: Safe file deletion
- `formatSize()`: Human-readable byte formatting

#### `PermissionService`
- Platform-specific permission requests
- Android: MANAGE_EXTERNAL_STORAGE (API 30+)
- iOS: Document picker (no permission needed)
- Windows: Full access (no permission needed)

**Key Methods**:
- `requestStoragePermission()`: Request appropriate permission
- `hasStoragePermission()`: Check permission status
- `openSettings()`: Navigate to app settings

### 3. Screens Layer (`screens/`)
**Purpose**: Full-screen views with state management

#### `HomeScreen`
- Main application interface
- Stateful widget managing scan state
- Integrates all widgets and services
- Handles user interactions
- Responsive layout (desktop vs mobile)

**State Management**:
- `_duplicateGroups`: List of found duplicates
- `_status`: Current operation status
- `_progress`: Scan progress (0.0 to 1.0)
- `_isScanning`: Scanning in progress flag
- `_selectedDirectory`: User-selected scan path

**Layouts**:
- Desktop: Side-by-side panels (controls | results)
- Mobile: Stacked panels (controls over results)

### 4. Widgets Layer (`widgets/`)
**Purpose**: Reusable UI components

#### `DuplicateGroupCard`
- Displays a group of duplicate files
- Expandable/collapsible
- Shows total size and wasted space
- Individual file delete buttons

#### `ScanControls`
- Directory selection button
- Minimum file size input
- Start scan button
- Disabled state during scanning

#### `StatsPanel`
- Summary statistics
- Total duplicate groups
- Total duplicate files
- Total wasted space

## Data Flow

```
User Interaction
       ↓
HomeScreen (State Management)
       ↓
Services (Business Logic)
       ↓
Platform APIs (File System, Permissions)
       ↓
Models (Data Structures)
       ↓
Widgets (UI Components)
       ↓
User Display
```

## Algorithm Flow

```
1. User selects directory
2. HomeScreen calls DuplicateFinderService.collectFiles()
   → Recursively scans directory
   → Filters by minimum size
   → Returns List<FileEntry>

3. HomeScreen calls DuplicateFinderService.findDuplicates()
   
   Stage 1: Size Grouping
   → Group files by size
   → Keep only groups with 2+ files
   
   Stage 2: Partial Hash
   → Hash first 8KB of each file
   → Regroup by partial hash
   → Keep only groups with 2+ files
   
   Stage 3: Full Hash
   → Hash entire file
   → Final grouping by full hash
   → Return List<DuplicateGroup>

4. HomeScreen displays results
   → Updates UI with duplicate groups
   → Shows statistics
   → Enables deletion

5. User deletes file
   → Confirmation dialog
   → DuplicateFinderService.deleteFile()
   → Update UI to remove deleted file
   → Recalculate statistics
```

## Key Design Decisions

### 1. Multi-Stage Hashing
**Why**: Hashing large files is expensive (CPU + disk I/O)
**Solution**: 
- Stage 1: Size comparison (free)
- Stage 2: Partial hash (fast, eliminates most non-duplicates)
- Stage 3: Full hash (only for likely duplicates)

**Result**: 10-100x faster than naive approach

### 2. Platform Abstraction
**Why**: Each platform has different file system capabilities
**Solution**: `PermissionService` abstracts platform differences
**Result**: Same UI code works on all platforms

### 3. Progress Callbacks
**Why**: Large directory scans can take minutes
**Solution**: Services expose callbacks for status and progress
**Result**: Responsive UI that shows real-time progress

### 4. Stateful Screen, Stateless Widgets
**Why**: Single source of truth for state
**Solution**: HomeScreen manages all state, passes data down to widgets
**Result**: Predictable data flow, easier testing

### 5. Confirmation Dialogs
**Why**: File deletion is destructive
**Solution**: Always confirm before deleting
**Result**: Prevents accidental data loss

## Testing Strategy

### Unit Tests (Future)
- Test `FileEntry` and `DuplicateGroup` models
- Test `DuplicateFinderService` algorithm
- Mock file system for predictable tests

### Widget Tests (Future)
- Test individual widgets render correctly
- Test user interactions (button clicks, etc.)
- Mock services for isolation

### Integration Tests (Future)
- Test full app flow
- Test on multiple platforms
- Test with real files

## Performance Considerations

### Memory
- Files are streamed during hashing (not loaded entirely)
- Only file paths stored in memory, not contents
- Typical: ~100 bytes per file in memory

### CPU
- SHA-256 is CPU-intensive
- Partial hash reduces CPU usage by 90%+
- Progress updates prevent UI blocking

### Disk I/O
- Sequential reads preferred over random access
- Partial hash reads only 8KB
- Full hash reads entire file once

### Scalability
- ✅ Handles 10,000+ files efficiently
- ✅ Multi-GB directories work well
- ⚠️ Very large files (10GB+) may be slow
- ⚠️ Network drives slower than local

## Future Improvements

### 1. Background Processing
Use isolates for file hashing to prevent UI blocking

### 2. Database Persistence
Store scan results in SQLite for history and comparison

### 3. File Type Detection
MIME type detection for better filtering and previews

### 4. Image Preview
Show thumbnails for image duplicates

### 5. Similarity Detection
Perceptual hashing for "similar" images (not just exact duplicates)

### 6. Cloud Integration
Scan cloud storage (Google Drive, Dropbox, OneDrive)

## Dependencies Rationale

| Package | Purpose | Why This One? |
|---------|---------|---------------|
| `file_picker` | Directory selection | Best cross-platform file picker |
| `crypto` | SHA-256 hashing | Official Dart crypto library |
| `permission_handler` | Storage permissions | Most popular, well-maintained |
| `path_provider` | System directories | Official Flutter plugin |
| `path` | Path manipulation | Official Dart path library |
| `shared_preferences` | Settings storage | Official Flutter plugin |

## Platform Limitations

### Windows ✅
- Full file system access
- Best performance
- No restrictions

### Android ⚠️
- API 30+ requires special permission
- Some directories restricted
- Performance varies by device

### iOS ⚠️
- Sandboxed environment
- Limited directory access
- Document picker only
- Cannot scan system files

### Web ❌
- Browser security prevents file system access
- Not supported

## Security Considerations

1. **No Network Access**: App doesn't send files anywhere
2. **No Data Collection**: No analytics or tracking
3. **Local Only**: All processing on-device
4. **Permission Minimal**: Only requests necessary permissions
5. **User Confirmation**: All destructive actions require approval

## Conclusion

DooptyDo uses clean architecture with clear separation between UI, business logic, and data models. The multi-stage hashing algorithm provides excellent performance while the platform abstraction ensures consistent behavior across Windows, Android, and iOS.
