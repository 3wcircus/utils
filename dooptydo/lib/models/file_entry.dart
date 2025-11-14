class FileEntry {
  final String path;
  final int size;
  final DateTime modifiedDate;
  String? contentHash;
  String? partialHash;

  FileEntry({
    required this.path,
    required this.size,
    required this.modifiedDate,
    this.contentHash,
    this.partialHash,
  });

  String get fileName => path.split('\\').last.split('/').last;

  @override
  String toString() => 'FileEntry(path: $path, size: $size)';
}
