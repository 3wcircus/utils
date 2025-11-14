import 'package:flutter/material.dart';

class ScanControls extends StatelessWidget {
  final List<String> selectedDirectories;
  final bool scanAllDrives;
  final TextEditingController fileSizeController;
  final bool isScanning;
  final VoidCallback onSelectDirectory;
  final VoidCallback onStartScan;
  final Function(String) onRemoveDirectory;
  final Function(bool?) onToggleScanAllDrives;

  const ScanControls({
    super.key,
    required this.selectedDirectories,
    required this.scanAllDrives,
    required this.fileSizeController,
    required this.isScanning,
    required this.onSelectDirectory,
    required this.onStartScan,
    required this.onRemoveDirectory,
    required this.onToggleScanAllDrives,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scan all drives checkbox
        CheckboxListTile(
          title: const Text('Scan All Drives'),
          subtitle: const Text('Scan all available drives on system'),
          value: scanAllDrives,
          onChanged: isScanning ? null : onToggleScanAllDrives,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),

        // Directory selection
        ElevatedButton.icon(
          onPressed: (isScanning || scanAllDrives) ? null : onSelectDirectory,
          icon: const Icon(Icons.folder_open),
          label: const Text('Add Directory'),
        ),

        // Selected directories list
        if (selectedDirectories.isNotEmpty && !scanAllDrives) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: selectedDirectories.length,
              itemBuilder: (context, index) {
                final dir = selectedDirectories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      dir,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: isScanning
                          ? null
                          : () => onRemoveDirectory(dir),
                      tooltip: 'Remove',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 16),

        // File size filter
        TextField(
          controller: fileSizeController,
          decoration: const InputDecoration(
            labelText: 'Min File Size (KB)',
            border: OutlineInputBorder(),
            helperText: 'Only scan files larger than this',
          ),
          keyboardType: TextInputType.number,
          enabled: !isScanning,
        ),
        const SizedBox(height: 16),

        // Scan button
        ElevatedButton.icon(
          onPressed: isScanning ? null : onStartScan,
          icon: const Icon(Icons.search),
          label: Text(isScanning ? 'Scanning...' : 'Start Scan'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
        ),
      ],
    );
  }
}
