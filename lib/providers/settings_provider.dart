import 'package:flutter/material.dart';

import '../models/store_settings_model.dart';
import '../repository/settings_repository.dart';
import '../services/backup_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    SettingsRepository? settingsRepository,
    BackupService? backupService,
  })  : _settingsRepository = settingsRepository ?? SettingsRepository(),
        _backupService = backupService ?? BackupService();

  final SettingsRepository _settingsRepository;
  final BackupService _backupService;

  StoreSettingsModel? storeSettings;
  bool isLoading = false;

  Future<void> loadStoreSettings() async {
    isLoading = true;
    notifyListeners();

    storeSettings = await _settingsRepository.get();

    isLoading = false;
    notifyListeners();
  }

  Future<void> saveStoreSettings(StoreSettingsModel settings) async {
    await _settingsRepository.update(settings);
    await loadStoreSettings();
  }

  Future<BackupResult> backupDatabase() => _backupService.backupDatabase();

  Future<BackupResult> restoreDatabase() => _backupService.restoreDatabase();
}
