// Basic smoke test confirming the app boots and shows the Login screen.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_kirana_store/main.dart';

void main() {
  testWidgets('App boots and shows the Login screen when logged out',
      (WidgetTester tester) async {
    // easy_localization persists the chosen locale via shared_preferences,
    // and AuthProvider reads the persisted login flag the same way;
    // without mocked initial values the platform channel call never
    // resolves in the test environment and pumpAndSettle hangs forever.
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('mr')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const SmartKiranaApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
