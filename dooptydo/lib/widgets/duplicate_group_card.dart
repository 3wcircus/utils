import 'package:flutter/material.dart';
import '../models/duplicate_group.dart';
import '../models/file_entry.dart';

class DuplicateGroupCard extends StatelessWidget {
  final DuplicateGroup group;
  final String Function(int) formatSize;
  final Function(String) onDeleteFile;
  final Function(List<String>) onDeleteMultiple;
  final VoidCallback? onRemoveGroup;

  const DuplicateGroupCard({
    super.key,
    required this.group,
    required this.formatSize,
    required this.onDeleteFile,
    required this.onDeleteMultiple,
    this.onRemoveGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text('${group.files.length} duplicates - ${group.fileName}'),
        subtitle: Text(
          'Total: ${formatSize(group.totalSize)} | '
          'Wasted: ${formatSize(group.wastedSpace)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (group.oldFiles.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.orange),
                onPressed: () => _confirmDeleteOldFiles(context),
                tooltip: 'Delete all except newest',
              ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
              onPressed: onRemoveGroup,
              tooltip: 'Remove group from results',
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          SizedBox(
            height: 180, // Fixed height for scrollable file list
            child: ListView.builder(
              itemCount: group.files.length,
              itemBuilder: (context, index) {
                final file = group.files[index];
                return _buildFileItem(context, file);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteOldFiles(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Old Files'),
        content: Text(
          'Delete ${group.oldFiles.length} old file(s) and keep only the newest version?\n\n'
          'This will keep: ${group.newestFile.path}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Old Files'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final pathsToDelete = group.oldFiles.map((f) => f.path).toList();
      onDeleteMultiple(pathsToDelete);
    }
  }

  Widget _buildFileItem(BuildContext context, FileEntry file) {
    // Check if this is the newest file
    final isNewest = file == group.newestFile;

    return ListTile(
      leading: Icon(Icons.description, color: isNewest ? Colors.green : null),
      title: Row(
        children: [
          Expanded(
            child: Text(
              file.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isNewest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NEWEST',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        '${file.path}\n${formatSize(file.size)} • ${_formatDate(file.modifiedDate)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => onDeleteFile(file.path),
        tooltip: 'Delete file',
      ),
      isThreeLine: true,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
