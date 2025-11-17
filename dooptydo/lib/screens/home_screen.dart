import 'package:flutter/material.dart';
// ...existing code...
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/duplicate_finder_service.dart';
import '../services/permission_service.dart';
import '../models/duplicate_group.dart';
import '../widgets/duplicate_group_card.dart';
import '../widgets/scan_controls.dart';
import '../widgets/stats_panel.dart';
import '../utils/app_logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s';
    } else if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds % 60}s';
    } else {
      return '${d.inSeconds}s';
    }
  }

  final _finderService = DuplicateFinderService();
  final _permissionService = PermissionService();
  final _fileSizeController = TextEditingController(text: '0');

  List<DuplicateGroup> _duplicateGroups = [];
  String _status = 'Ready to scan';
  double _progress = 0.0;
  bool _isScanning = false;
  List<String> _selectedDirectories = [];
  bool _scanAllDrives = false;
  // int _collectedFileCount = 0; // Removed, not used

  @override
  void initState() {
    super.initState();
    _finderService.onStatusUpdate = (status) {
      setState(() {
        _status = status;
        // Removed _collectedFileCount logic
      });
      // Log status changes for better feedback
      AppLogger.info(status);
    };
    _finderService.onProgressUpdate = (progress) {
      setState(() => _progress = progress);
    };
  }

  @override
  void dispose() {
    _fileSizeController.dispose();
    super.dispose();
  }

  Future<void> _selectDirectory() async {
    if (!await _permissionService.hasStoragePermission()) {
      final granted = await _permissionService.requestStoragePermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Storage permission is required'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => _permissionService.openSettings(),
              ),
            ),
          );
        }
        return;
      }
    }
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        if (!_selectedDirectories.contains(selectedDirectory)) {
          _selectedDirectories.add(selectedDirectory);
        }
      });
    }
  }

  void _removeDirectory(String directory) {
    setState(() {
      _selectedDirectories.remove(directory);
    });
  }

  void _toggleScanAllDrives(bool? value) {
    setState(() {
      _scanAllDrives = value ?? false;
      if (_scanAllDrives) {
        _selectedDirectories.clear();
      }
    });
  }

  Future<void> _startScan() async {
    if (_selectedDirectories.isEmpty && !_scanAllDrives) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select directories or enable scan all drives'),
        ),
      );
      return;
    }
    setState(() {
      _isScanning = true;
      _progress = 0.0;
      _duplicateGroups.clear();
    });
    final scanStart = DateTime.now();
    try {
      final minSize = int.tryParse(_fileSizeController.text) ?? 0;
      List<String> pathsToScan;
      if (_scanAllDrives) {
        pathsToScan = _finderService.getAvailableDrives();
        if (pathsToScan.isEmpty) {
          throw Exception('No drives found');
        }
      } else {
        pathsToScan = _selectedDirectories;
      }
      final files = await _finderService.collectFilesFromMultiplePaths(
        pathsToScan,
        minSize: minSize * 1024,
      );
      final groups = await _finderService.findDuplicates(files);
      final scanEnd = DateTime.now();
      final scanDuration = scanEnd.difference(scanStart);
      setState(() {
        _duplicateGroups = groups;
        _isScanning = false;
      });
      AppLogger.info('Scan completed in ${_formatDuration(scanDuration)}');
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isScanning = false;
      });
    }
  }

  Future<void> _deleteFile(DuplicateGroup group, String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete:\n$filePath'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await _finderService.deleteFile(filePath);
      if (success) {
        setState(() {
          group.files.removeWhere((f) => f.path == filePath);
          if (group.files.length <= 1) {
            _duplicateGroups.remove(group);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File deleted successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete file')),
          );
        }
      }
    }
  }

  Future<void> _deleteMultipleFiles(
    DuplicateGroup group,
    List<String> filePaths,
  ) async {
    int successCount = 0;
    int failCount = 0;
    for (final path in filePaths) {
      final success = await _finderService.deleteFile(path);
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }
    setState(() {
      for (final path in filePaths) {
        group.files.removeWhere((f) => f.path == path);
      }
      if (group.files.length <= 1) {
        _duplicateGroups.remove(group);
      }
    });
    if (mounted) {
      if (failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted $successCount file(s) successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deleted $successCount file(s), failed to delete $failCount',
            ),
          ),
        );
      }
    }
  }

  int get _totalWastedSpace {
    return _duplicateGroups.fold(0, (sum, g) => sum + g.wastedSpace);
  }

  int get _totalDuplicateFiles {
    return _duplicateGroups.fold(0, (sum, g) => sum + (g.files.length - 1));
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Enable Logging'),
                  subtitle: const Text('Show debug logs in console'),
                  value: AppLogger.isLoggingEnabled,
                  onChanged: (value) {
                    setDialogState(() {
                      AppLogger.isLoggingEnabled = value;
                    });
                    if (value) {
                      AppLogger.info('Logging enabled');
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Exit Application'),
                  onTap: () {
                    Navigator.pop(context);
                    exit(0);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dooptydo - Duplicate Finder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(right: BorderSide(color: Colors.grey[300]!)),
          ),
          child: _buildControlsPanel(),
        ),
        Expanded(child: _buildResultsPanel()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildControlsPanel(),
        const Divider(height: 1),
        Expanded(child: _buildResultsPanel()),
      ],
    );
  }

  Widget _buildControlsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScanControls(
            selectedDirectories: _selectedDirectories,
            scanAllDrives: _scanAllDrives,
            fileSizeController: _fileSizeController,
            isScanning: _isScanning,
            onSelectDirectory: _selectDirectory,
            onStartScan: _startScan,
            onRemoveDirectory: _removeDirectory,
            onToggleScanAllDrives: _toggleScanAllDrives,
          ),
          const SizedBox(height: 24),
          StatsPanel(
            totalGroups: _duplicateGroups.length,
            totalDuplicateFiles: _totalDuplicateFiles,
            totalWastedSpace: _totalWastedSpace,
            formatSize: _finderService.formatSize,
          ),
          const SizedBox(height: 16),
          _buildStatusPanel(),
        ],
      ),
    );
  }

  Widget _buildStatusPanel() {
    final lastLog = AppLogger.instance.history.isNotEmpty
        ? AppLogger.instance.history.last.message
        : '';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_isScanning && _progress == 0.0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              Expanded(
                child: Text(
                  _isScanning && _status.contains('Collecting files')
                      ? 'Collecting files... (this may take a while)'
                      : _status,
                  style: TextStyle(
                    fontWeight: _isScanning
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          if (_isScanning && _progress > 0.0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _progress),
          ],
          const SizedBox(height: 8),
          if (lastLog != null && lastLog.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Last log: $lastLog',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ExpansionTile(
            title: const Text('Details'),
            children: [SizedBox(height: 180, child: _buildLogDetails())],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel() {
    if (_duplicateGroups.isEmpty) {
      return Center(
        child: _isScanning
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Scanning...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take some time...',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              )
            : Text(
                'No duplicates found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Delete All Old Duplicates'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: _duplicateGroups.any((g) => g.oldFiles.isNotEmpty)
                  ? () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete All Old Duplicates'),
                          content: const Text(
                            'This will delete all duplicate files except the most recent version in each group. Are you sure you want to proceed?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete All'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        int totalDeleted = 0;
                        int totalFailed = 0;
                        int totalToDelete = _duplicateGroups.fold(
                          0,
                          (sum, g) => sum + g.oldFiles.length,
                        );
                        int currentDeleted = 0;
                        // Show progress dialog and update it
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setDialogState) {
                                return AlertDialog(
                                  title: const Text('Deleting Duplicates'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Deleting old duplicate files...'),
                                      const SizedBox(height: 16),
                                      LinearProgressIndicator(
                                        value: totalToDelete > 0
                                            ? currentDeleted / totalToDelete
                                            : null,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$currentDeleted / $totalToDelete deleted',
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                        // Actual deletion loop
                        for (final group in List<DuplicateGroup>.from(
                          _duplicateGroups,
                        )) {
                          final oldFiles = group.oldFiles
                              .map((f) => f.path)
                              .toList();
                          if (oldFiles.isNotEmpty) {
                            int successCount = 0;
                            int failCount = 0;
                            for (final path in oldFiles) {
                              final success = await _finderService.deleteFile(
                                path,
                              );
                              await Future.delayed(
                                const Duration(milliseconds: 10),
                              ); // Yield to event loop
                              success ? successCount++ : failCount++;
                              currentDeleted++;
                              // Update progress dialog
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setDialogState) {
                                      setDialogState(() {});
                                      return AlertDialog(
                                        title: const Text(
                                          'Deleting Duplicates',
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Deleting old duplicate files...',
                                            ),
                                            const SizedBox(height: 16),
                                            LinearProgressIndicator(
                                              value: totalToDelete > 0
                                                  ? currentDeleted /
                                                        totalToDelete
                                                  : null,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '$currentDeleted / $totalToDelete deleted',
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            }
                            setState(() {
                              for (final path in oldFiles) {
                                group.files.removeWhere((f) => f.path == path);
                              }
                              if (group.files.length <= 1) {
                                _duplicateGroups.remove(group);
                              }
                            });
                            totalDeleted += successCount;
                            totalFailed += failCount;
                          }
                        }
                        // Dismiss progress dialog
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                        if (mounted) {
                          if (totalFailed == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Deleted $totalDeleted old duplicate file(s) successfully',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Deleted $totalDeleted file(s), failed to delete $totalFailed',
                                ),
                              ),
                            );
                          }
                        }
                      }
                    }
                  : null,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _duplicateGroups.length,
            itemBuilder: (context, index) {
              final group = _duplicateGroups[index];
              return DuplicateGroupCard(
                group: group,
                formatSize: _finderService.formatSize,
                onDeleteFile: (filePath) => _deleteFile(group, filePath),
                onDeleteMultiple: (filePaths) =>
                    _deleteMultipleFiles(group, filePaths),
                onRemoveGroup: () {
                  setState(() {
                    _duplicateGroups.removeAt(index);
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogDetails() {
    final infoLogs = AppLogger.instance.history
        .where((log) => log.key == 'info')
        .toList();
    if (infoLogs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No info logs yet.'),
      );
    }
    return ListView.builder(
      itemCount: infoLogs.length,
      itemBuilder: (context, index) {
        final log = infoLogs[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          child: Text(
            '[${log.time.toLocal().toIso8601String()}] ${log.message}',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        );
      },
    );
  }
}
