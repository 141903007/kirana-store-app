import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/backup_service.dart';
import '../auth/account_settings_screen.dart';
import 'store_info_form_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmRestore(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('settings.restore_confirm_title'.tr()),
        content: Text('settings.restore_confirm_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('settings.restore_database'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await context.read<SettingsProvider>().restoreDatabase();
    if (!context.mounted) return;

    switch (result) {
      case BackupResult.success:
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text('settings.restore_success_title'.tr()),
            content: Text('settings.restore_success_message'.tr()),
            actions: [
              FilledButton(
                onPressed: () {
                  if (Platform.isAndroid || Platform.isIOS) {
                    SystemNavigator.pop();
                  } else {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: Text('common.ok'.tr()),
              ),
            ],
          ),
        );
        break;
      case BackupResult.cancelled:
        break;
      case BackupResult.failed:
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('settings.restore_failed'.tr())));
        break;
    }
  }

  Future<void> _backup(BuildContext context) async {
    final result = await context.read<SettingsProvider>().backupDatabase();
    if (!context.mounted) return;

    final messageKey = switch (result) {
      BackupResult.success => 'settings.backup_success',
      BackupResult.cancelled => 'settings.backup_cancelled',
      BackupResult.failed => 'settings.backup_failed',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageKey.tr())));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isMarathi = context.locale.languageCode == 'mr';

    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr())),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text('settings.store_information'.tr()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StoreInfoFormScreen()),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: Text('settings.account'.tr()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('settings.language'.tr(), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: false, label: Text('settings.english'.tr())),
                        ButtonSegment(value: true, label: Text('settings.marathi'.tr())),
                      ],
                      selected: {isMarathi},
                      onSelectionChanged: (selection) => context
                          .setLocale(selection.first ? const Locale('mr') : const Locale('en')),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('home.theme_mode'.tr(), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                            value: ThemeMode.light, label: Text('home.theme_light'.tr())),
                        ButtonSegment(value: ThemeMode.dark, label: Text('home.theme_dark'.tr())),
                        ButtonSegment(
                            value: ThemeMode.system, label: Text('home.theme_system'.tr())),
                      ],
                      selected: {themeProvider.themeMode},
                      onSelectionChanged: (selection) =>
                          themeProvider.setThemeMode(selection.first),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('settings.backup_restore'.tr(), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: Text('settings.backup_database'.tr()),
                onTap: () => _backup(context),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.restore_outlined),
                title: Text('settings.restore_database'.tr()),
                onTap: () => _confirmRestore(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
