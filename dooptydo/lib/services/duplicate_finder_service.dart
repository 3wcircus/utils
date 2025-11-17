import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import '../models/file_entry.dart';
import '../models/duplicate_group.dart';
import '../utils/app_logger.dart';

/// Isolate entry for hashing a chunk of files (must be top-level for Isolate.spawn)
void _hashChunkIsolateEntry(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final chunk = args[1] as List<FileEntry>;
  final fullHash = args[2] as bool;
  final hashes = <Map<String, dynamic>>[];
  for (final file in chunk) {
    try {
      final fileObj = File(file.path);
      final bytes = await fileObj.readAsBytes();
      final bytesToHash = fullHash ? bytes : bytes.take(8192).toList();
      final digest = sha256.convert(bytesToHash);
      hashes.add({'hash': digest.toString()});
    } catch (e) {
      hashes.add({'hash': null});
    }
  }
  sendPort.send(hashes);
}

class DuplicateFinderService {
  // Callback for progress updates
  Function(String)? onStatusUpdate;
  Function(double)? onProgressUpdate;

  // Chunk size for parallel hashing
  int chunkSize = 8;

  // Known directories that should be skipped (case-insensitive)
  static final List<String> _skipDirectories = [
    r'$Recycle.Bin',
    r'System Volume Information',
    r'Recovery',
    r'$WINDOWS.~BT',
    r'Windows.old',
    r'ProgramData\Microsoft\Windows\WER', // Windows Error Reporting
    r'AppData\Local\Temp',
    r'.svn', // Skip SVN folders
  ];

  DuplicateFinderService({this.onStatusUpdate, this.onProgressUpdate});

  /// Check if a path should be skipped
  bool _shouldSkipPath(String path) {
    final lowerPath = path.toLowerCase();
    return _skipDirectories.any(
      (skip) => lowerPath.contains(skip.toLowerCase()),
    );
  }

  /// Get all available drives on Windows
  List<String> getAvailableDrives() {
    if (!Platform.isWindows) return [];

    final drives = <String>[];
    for (var letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
      final drive = '$letter:\\';
      if (Directory(drive).existsSync()) {
        drives.add(drive);
      }
    }
    return drives;
  }

  /// Recursively collect all files from multiple directories using isolates for parallelism
  Future<List<FileEntry>> collectFilesFromMultiplePaths(
    List<String> directoryPaths, {
    int minSize = 0,
    List<String>? fileExtensions,
  }) async {
    final allFiles = <FileEntry>[];
    final results = <Future<List<FileEntry>>>[];

    for (var i = 0; i < directoryPaths.length; i++) {
      onStatusUpdate?.call(
        'Scanning ${i + 1}/${directoryPaths.length}: ${directoryPaths[i]}',
      );
      // Spawn isolates for each directory scan
      results.add(
        _collectFilesIsolate(directoryPaths[i], minSize, fileExtensions),
      );
    }

    final filesList = await Future.wait(results);
    for (final files in filesList) {
      allFiles.addAll(files);
    }

    onStatusUpdate?.call('Found ${allFiles.length} total files');
    return allFiles;
  }

  /// Helper to run collectFiles in an isolate
  Future<List<FileEntry>> _collectFilesIsolate(
    String directoryPath,
    int minSize,
    List<String>? fileExtensions,
  ) async {
    final p = ReceivePort();
    await Isolate.spawn(_collectFilesIsolateEntry, [
      p.sendPort,
      directoryPath,
      minSize,
      fileExtensions,
    ]);
    return await p.first as List<FileEntry>;
  }

  /// Entry point for collectFiles isolate
  static void _collectFilesIsolateEntry(List<dynamic> args) async {
    final sendPort = args[0] as SendPort;
    final directoryPath = args[1] as String;
    final minSize = args[2] as int;
    final fileExtensions = args[3] as List<String>?;
    final service = DuplicateFinderService();
    final files = await service.collectFiles(
      directoryPath,
      minSize: minSize,
      fileExtensions: fileExtensions,
    );
    sendPort.send(files);
  }

  /// Recursively collect all files from a directory
  Future<List<FileEntry>> collectFiles(
    String directoryPath, {
    int minSize = 0,
    List<String>? fileExtensions,
  }) async {
    final files = <FileEntry>[];
    final dir = Directory(directoryPath);

    onStatusUpdate?.call('Collecting files...');

    try {
      await for (final entity
          in dir.list(recursive: true, followLinks: false).handleError((error) {
            // Handle errors during directory listing (e.g., access denied on subdirectories)
            AppLogger.warning('Cannot access path during scan: $error');
          })) {
        // Skip known problematic directories
        if (_shouldSkipPath(entity.path)) {
          AppLogger.info('Skipping known system location: ${entity.path}');
          continue;
        }

        if (entity is File) {
          try {
            final stat = await entity.stat();

            // Filter by size
            if (stat.size < minSize) continue;

            // Filter by extension if specified
            if (fileExtensions != null && fileExtensions.isNotEmpty) {
              final ext = path.extension(entity.path).toLowerCase();
              if (!fileExtensions.contains(ext)) continue;
            }

            files.add(
              FileEntry(
                path: entity.path,
                size: stat.size,
                modifiedDate: stat.modified,
              ),
            );
            // Update live file count during collection
            onStatusUpdate?.call(
              'Collecting files... Found ${files.length} files',
            );
          } catch (e) {
            // Skip files that can't be accessed
            AppLogger.warning('Cannot access file ${entity.path}: $e');
          }
        } else if (entity is Directory) {
          // Proactively check directory access
          try {
            await entity.stat();
          } catch (e) {
            // Skip directories that can't be accessed
            AppLogger.warning('Cannot access directory ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      // Handle top-level directory access errors
      AppLogger.error('Cannot access directory $directoryPath', e);
      onStatusUpdate?.call('Error accessing $directoryPath - skipping');
    }

    onStatusUpdate?.call('Found ${files.length} files');
    return files;
  }

  /// Calculate hash of a file (full or partial)
  Future<String?> calculateFileHash(
    String filePath, {
    bool fullHash = true,
    int partialBytes = 8192,
  }) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      final bytesToHash = fullHash ? bytes : bytes.take(partialBytes).toList();
      final digest = sha256.convert(bytesToHash);

      return digest.toString();
    } catch (e) {
      AppLogger.warning('Cannot hash file $filePath: $e');
      return null;
    }
  }

  /// Find duplicates using multi-stage approach
  Future<List<DuplicateGroup>> findDuplicates(
    List<FileEntry> files, {
    bool usePartialHash = true,
  }) async {
    // Stage 1: Group by size
    onStatusUpdate?.call('Grouping by size...');
    final sizeGroups = <int, List<FileEntry>>{};

    for (final file in files) {
      sizeGroups.putIfAbsent(file.size, () => []).add(file);
    }

    // Keep only groups with duplicates
    final potentialDuplicates = sizeGroups.values
        .where((group) => group.length > 1)
        .expand((group) => group)
        .toList();

    if (potentialDuplicates.isEmpty) {
      onStatusUpdate?.call('No duplicates found');
      return [];
    }

    onStatusUpdate?.call(
      'Found ${potentialDuplicates.length} potential duplicates',
    );

    // Stage 2: Partial hash (first 8KB) - parallelized
    if (usePartialHash) {
      onStatusUpdate?.call('Computing partial hashes...');
      await _computeHashesParallel(potentialDuplicates, false, (progress) {
        onProgressUpdate?.call(progress);
      });

      // Regroup by partial hash
      final partialHashGroups = <String, List<FileEntry>>{};
      for (final file in potentialDuplicates) {
        if (file.partialHash != null) {
          partialHashGroups.putIfAbsent(file.partialHash!, () => []).add(file);
        }
      }

      potentialDuplicates.clear();
      potentialDuplicates.addAll(
        partialHashGroups.values
            .where((group) => group.length > 1)
            .expand((group) => group),
      );

      if (potentialDuplicates.isEmpty) {
        onStatusUpdate?.call('No duplicates found');
        return [];
      }

      onStatusUpdate?.call(
        '${potentialDuplicates.length} files remain after partial hash',
      );
    }

    // Stage 3: Full hash - parallelized
    onStatusUpdate?.call('Computing full hashes...');
    await _computeHashesParallel(potentialDuplicates, true, (progress) {
      onProgressUpdate?.call(progress);
    });

    // Final grouping by full hash
    final hashGroups = <String, List<FileEntry>>{};
    for (final file in potentialDuplicates) {
      if (file.contentHash != null) {
        hashGroups.putIfAbsent(file.contentHash!, () => []).add(file);
      }
    }

    final duplicateGroups = hashGroups.values
        .where((group) => group.length > 1)
        .map(
          (files) =>
              DuplicateGroup(hash: files.first.contentHash!, files: files),
        )
        .toList();

    // Sort by wasted space (descending)
    duplicateGroups.sort((a, b) => b.wastedSpace.compareTo(a.wastedSpace));

    final totalFiles = duplicateGroups.fold(
      0,
      (sum, g) => sum + g.files.length,
    );
    final totalWasted = duplicateGroups.fold(
      0,
      (sum, g) => sum + g.wastedSpace,
    );

    onStatusUpdate?.call(
      'Found ${duplicateGroups.length} duplicate groups ($totalFiles files, ${_formatSize(totalWasted)} wasted)',
    );

    return duplicateGroups;
  }

  /// Parallel hash computation using isolates
  Future<void> _computeHashesParallel(
    List<FileEntry> files,
    bool fullHash,
    void Function(double) onProgress,
  ) async {
    final chunks = <List<FileEntry>>[];
    for (var i = 0; i < files.length; i += chunkSize) {
      chunks.add(
        files.sublist(
          i,
          i + chunkSize > files.length ? files.length : i + chunkSize,
        ),
      );
    }
    int completed = 0;
    await Future.wait(
      chunks.map((chunk) async {
        final p = ReceivePort();
        await Isolate.spawn(_hashChunkIsolateEntry, [
          p.sendPort,
          chunk,
          fullHash,
        ]);
        final hashes = await p.first as List<Map<String, dynamic>>;
        for (var i = 0; i < chunk.length; i++) {
          if (fullHash) {
            chunk[i].contentHash = hashes[i]['hash'] as String?;
          } else {
            chunk[i].partialHash = hashes[i]['hash'] as String?;
          }
          completed++;
          onProgress(completed / files.length);
        }
      }),
    );
  }

  /// Delete a file
  Future<bool> deleteFile(String filePath) async {
    // Skip deletion for files in known system/VCS folders
    if (_shouldSkipPath(filePath)) {
      AppLogger.warning(
        'Skipping deletion of protected/system file: $filePath',
      );
      return false;
    }
    try {
      final file = File(filePath);
      await file.delete();
      return true;
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 5) {
        AppLogger.error('Access denied when deleting file $filePath', e);
      } else {
        AppLogger.error('Error deleting file $filePath', e);
      }
      return false;
    } catch (e) {
      AppLogger.error('Error deleting file $filePath', e);
      return false;
    }
  }

  /// Format bytes to human-readable size
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Format size helper (public for UI)
  String formatSize(int bytes) => _formatSize(bytes);
}
