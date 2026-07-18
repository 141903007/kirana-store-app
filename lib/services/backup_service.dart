import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../database/app_database.dart';

enum BackupResult { success, cancelled, failed }

/// Backs up/restores the app's single SQLite file. Uses `file_picker`'s
/// bytes-based API (not raw paths) for both directions — Android's scoped
/// storage means a picked directory/file path isn't a plain filesystem path
/// the app can just open with `dart:io`, so we always let file_picker do
/// the actual read/write and hand bytes across the boundary instead.
class BackupService {
  Future<BackupResult> backupDatabase() async {
    try {
      final dbPath = await AppDatabase.instance.databasePath;
      final bytes = await File(dbPath).readAsBytes();
      final fileName = 'smart_kirana_store_backup_${DateTime.now().millisecondsSinceEpoch}.db';

      final savedPath = await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: bytes,
      );
      return savedPath != null ? BackupResult.success : BackupResult.cancelled;
    } catch (_) {
      return BackupResult.failed;
    }
  }

  /// Closes the live database connection before overwriting the file — the
  /// app must be restarted afterwards for the restored data to take effect.
  Future<BackupResult> restoreDatabase() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null || result.files.single.bytes == null) {
        return BackupResult.cancelled;
      }
      final bytes = result.files.single.bytes!;

      await AppDatabase.instance.close();
      final dbPath = await AppDatabase.instance.databasePath;
      await File(dbPath).writeAsBytes(bytes, flush: true);
      return BackupResult.success;
    } catch (_) {
      return BackupResult.failed;
    }
  }
}
