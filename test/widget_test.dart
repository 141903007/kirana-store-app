// Basic smoke test confirming the app boots and shows its branding.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_kirana_store/main.dart';

void main() {
  testWidgets('App boots and shows Module 1 placeholder screen',
      (WidgetTester tester) async {
    await EasyLocalization.ensureInitialized();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('mr')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const SmartKiranaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Module 1: Project Setup Complete'), findsOneWidget);
  });
}
