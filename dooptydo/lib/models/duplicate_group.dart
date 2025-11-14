import 'file_entry.dart';

class DuplicateGroup {
  final String hash;
  final List<FileEntry> files;

  DuplicateGroup({required this.hash, required this.files}) {
    // Sort files by modification date (newest first)
    files.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
  }

  int get totalSize => files.fold(0, (sum, file) => sum + file.size);

  int get wastedSpace => files.length > 1 ? totalSize - files.first.size : 0;

  /// Get the file name (without path) - uses the first file as representative
  String get fileName => files.isNotEmpty ? files.first.fileName : 'Unknown';

  /// Get the newest file (first in sorted list)
  FileEntry get newestFile => files.first;

  /// Get all files except the newest one
  List<FileEntry> get oldFiles => files.length > 1 ? files.sublist(1) : [];

  @override
  String toString() => 'DuplicateGroup(hash: $hash, files: ${files.length})';
}
