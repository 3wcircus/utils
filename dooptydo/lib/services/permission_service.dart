import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionService {
  /// Request storage permission based on platform
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 11+ requires MANAGE_EXTERNAL_STORAGE for full access
      if (await _getAndroidVersion() >= 30) {
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      } else {
        // Android 10 and below
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS uses document picker, no permission needed
      return true;
    } else {
      // Desktop platforms (Windows, macOS, Linux)
      return true;
    }
  }

  /// Check if storage permission is granted
  Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      if (await _getAndroidVersion() >= 30) {
        return await Permission.manageExternalStorage.isGranted;
      } else {
        return await Permission.storage.isGranted;
      }
    }
    return true;
  }

  /// Get Android SDK version
  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    // This is a simplified version. In production, you might want to use
    // device_info_plus package for accurate version detection
    return 30; // Assume Android 11+ for now
  }

  /// Show permission settings if denied
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
