/// App-wide constant values shared across every module.
class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Kirana Store';
  static const String databaseName = 'smart_kirana_store.db';
  static const int databaseVersion = 1;

  // Default admin credentials, seeded into the Users table on first launch.
  // The admin can change these later from Settings.
  static const String defaultUsername = 'admin';
  static const String defaultPassword = 'password';

  // shared_preferences keys
  static const String prefKeyLocale = 'selected_locale';
  static const String prefKeyThemeMode = 'selected_theme_mode';
  static const String prefKeyIsLoggedIn = 'is_logged_in';
}
