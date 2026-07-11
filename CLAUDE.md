# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Smart Kirana Store — an offline-first Flutter app for managing a grocery/kirana store (billing, products, purchases, reports, customers). Android is currently the only configured platform (no ios/windows/macos/linux/web directories exist yet).

Development is proceeding in numbered modules (see the conversation/plan that built it): Modules 1-4 (Project Setup, Database Foundation, Auth, Dashboard shell) are done; Products, Purchase, Billing, Customers, Stock, Profit & Loss, Reports, and Settings follow in that order. The Dashboard (`lib/screens/dashboard/dashboard_screen.dart`) is a real, final layout already, but its stat values are always zero (`DashboardProvider` has no real data source yet — wired up in a later module) and its quick-nav tiles show a "coming soon" snackbar for every destination that doesn't exist yet.

## Commands

```
flutter pub get                     # install dependencies
flutter run                         # run on connected device/emulator
flutter test                        # run all tests
flutter test test/widget_test.dart  # run a single test file
flutter analyze                     # static analysis / lints
flutter build apk --debug           # build a debug APK (no signing needed)
flutter build apk                   # build Android release APK
```

There is no CI config, no lint-fix script, and no custom build tooling beyond the standard Flutter CLI.

**Local dev environment note**: Flutter SDK lives at `C:\src\flutter` (not on PATH by default) and `JAVA_HOME` must point at `C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot` for Gradle/Android builds — see the `build_environment` memory for full details (device serial, adb path, etc.) if picking this project back up in a new session. `android/gradle.properties` sets `kotlin.incremental=false` to work around a Kotlin/Gradle crash that happens when the project drive and the Flutter/Gradle cache drive differ (D: vs C: here) — don't remove that line.

## Architecture

- **Local-first persistence**: `sqflite` is the primary data store. The full schema (11 tables: `users`, `categories`, `products`, `product_price_variants`, `customers`, `purchases`, `purchase_items`, `sales`, `sale_items`, `stock_history`, `store_settings`) lives in [lib/database/app_database.dart](lib/database/app_database.dart) (singleton, `onCreate`/`onConfigure`/seeding) and [lib/database/db_tables.dart](lib/database/db_tables.dart) (column-name constants). `shared_preferences` is used only for small key-value settings (theme mode, persisted login flag — keys in `AppConstants`). No backend/API layer exists.
- **Multi-pricing / box-pricing data model**: a product's sellable price options (e.g. Sugar's 1kg/500g/250g/100g, or a Box vs a loose Packet) are all rows in `product_price_variants`, not separate tables. Every product has one `base_unit` and `current_stock` is always expressed in it; each variant's `quantity_in_base_unit` converts to/from that. "Remaining boxes vs packets" must always be computed from `current_stock` at display time — never store it separately, or it will drift.
- **Stock integrity rule**: only repository code (`purchase_repository`, `sale_repository`, `stock_history_repository` — added in later modules) may write `products.current_stock`, always inside a `db.transaction`, always paired with a `stock_history` row. Providers/UI never touch stock directly.
- **State management**: `provider`, via one `ChangeNotifier` per feature registered in `main.dart`'s `MultiProvider` (currently `ThemeProvider`, `AuthProvider`). `AuthGate` ([lib/screens/auth/auth_gate.dart](lib/screens/auth/auth_gate.dart)) swaps between the Login screen and the post-login home based on `AuthProvider.isLoggedIn` — no explicit navigation needed for login/logout, just provider state changes.
- **Auth**: single admin account, seeded by `AppDatabase` with `AppConstants.defaultUsername`/`defaultPassword` (SHA-256 hashed via [lib/utils/password_hasher.dart](lib/utils/password_hasher.dart) — no per-user salt, since there's no server round-trip to protect against, only this device's own DB file). Login session persists across app restarts via `AppConstants.prefKeyIsLoggedIn`. Offline "forgot password" is a security-question flow ([lib/screens/auth/forgot_password_screen.dart](lib/screens/auth/forgot_password_screen.dart)) set up from Account Settings — if no question is configured yet, the recovery screen just says so and sends the user back to log in normally.
- **Localization**: `easy_localization` drives all user-facing strings, loaded from `assets/translations/{en,mr}.json` (English and Marathi). Any new UI text must be added to both JSON files under the appropriate nested key (`common`, `settings`, `nav`, `auth`, `home`, etc.) and referenced via `'key.path'.tr()`, never hardcoded. Provider `errorMessage` fields hold translation *keys* (e.g. `'auth.invalid_credentials'`), not display text — screens call `.tr()` on them, keeping providers free of localization/BuildContext concerns.
- **Theming**: centralized in [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart) via `AppTheme.lightTheme`/`AppTheme.darkTheme`. Both are Material 3, generated from a single seed color (`AppTheme.seedColor`, grocery green). `ThemeProvider` persists the user's light/dark/system choice; update the seed/theme itself in `AppTheme`, not per-widget.
- **Constants**: app-wide constants (db name/version, default admin credentials, shared_preferences keys) live in [lib/core/constants/app_constants.dart](lib/core/constants/app_constants.dart) as static members on a private-constructor class — the same pattern is used for DB table/column names in `db_tables.dart`.
- **Entry point**: [lib/main.dart](lib/main.dart) wraps the app in `EasyLocalization`, then `SmartKiranaApp` builds a `MultiProvider` (each provider's `create:` calls `..initialize()` to restore persisted state asynchronously) feeding a `Consumer<ThemeProvider>` that builds `MaterialApp` with `home: const AuthGate()`.
- **Widget tests**: because `easy_localization` reads persisted locale via `shared_preferences`, and `AuthProvider.initialize()` reads the persisted login flag the same way, any widget test that pumps `SmartKiranaApp` must call `SharedPreferences.setMockInitialValues({})` before `EasyLocalization.ensureInitialized()` — otherwise the platform channel call never resolves and `pumpAndSettle` hangs indefinitely (see [test/widget_test.dart](test/widget_test.dart)).
- **Database tests**: [test/database/app_database_test.dart](test/database/app_database_test.dart) overrides sqflite's global `databaseFactory` with `sqflite_common_ffi` so schema/seed/cascade behavior can be verified against a real SQLite engine on the desktop test host, without needing a connected Android device.
