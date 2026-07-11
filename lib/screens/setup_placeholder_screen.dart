import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Temporary home screen for Module 1 (Project Setup).
/// Confirms the theme and English/Marathi localization are wired correctly.
/// This will be replaced by the Login screen in a later module.
class SetupPlaceholderScreen extends StatelessWidget {
  const SetupPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMarathi = context.locale.languageCode == 'mr';

    return Scaffold(
      appBar: AppBar(title: Text('app_name'.tr())),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_rounded, size: 96, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'welcome'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Module 1: Project Setup Complete',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('settings.language'.tr(),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                              value: false, label: Text('settings.english'.tr())),
                          ButtonSegment(
                              value: true, label: Text('settings.marathi'.tr())),
                        ],
                        selected: {isMarathi},
                        onSelectionChanged: (selection) {
                          context.setLocale(
                              selection.first ? const Locale('mr') : const Locale('en'));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
