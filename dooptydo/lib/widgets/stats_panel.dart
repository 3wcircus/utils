import 'package:flutter/material.dart';

class StatsPanel extends StatelessWidget {
  final int totalGroups;
  final int totalDuplicateFiles;
  final int totalWastedSpace;
  final String Function(int) formatSize;

  const StatsPanel({
    super.key,
    required this.totalGroups,
    required this.totalDuplicateFiles,
    required this.totalWastedSpace,
    required this.formatSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildStatRow('Duplicate Groups:', totalGroups.toString()),
          _buildStatRow('Duplicate Files:', totalDuplicateFiles.toString()),
          _buildStatRow('Space Wasted:', formatSize(totalWastedSpace)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
