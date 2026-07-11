import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/setup_placeholder_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('mr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const SmartKiranaApp(),
    ),
  );
}

class SmartKiranaApp extends StatelessWidget {
  const SmartKiranaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Kirana Store',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SetupPlaceholderScreen(),
    );
  }
}
