// Verifies SettingsRepository.update only touches store-info columns,
// leaving invoice_prefix/last_invoice_number untouched — against a real
// SQLite engine (sqflite_common_ffi), no Android device needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smart_kirana_store/database/app_database.dart';
import 'package:smart_kirana_store/repository/settings_repository.dart';

void main() {
  final settingsRepository = SettingsRepository();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    final dbPath = await databaseFactory.getDatabasesPath();
    await databaseFactory.deleteDatabase('$dbPath/smart_kirana_store.db');
  });

  test('update saves store info fields and preserves invoice numbering state', () async {
    final db = await AppDatabase.instance.database;
    // Simulate a few invoices already issued before store info is edited.
    await db.update(
      'store_settings',
      {'last_invoice_number': 42},
      where: 'id = ?',
      whereArgs: [1],
    );

    final existing = await settingsRepository.get();
    await settingsRepository.update(existing.copyWith(
      storeName: 'Ramesh Kirana Store',
      storeAddress: 'Main Road, Pune',
      storePhone: '9876543210',
      storeGstNumber: '27ABCDE1234F1Z5',
    ));

    final updated = await settingsRepository.get();
    expect(updated.storeName, 'Ramesh Kirana Store');
    expect(updated.storeAddress, 'Main Road, Pune');
    expect(updated.storePhone, '9876543210');
    expect(updated.storeGstNumber, '27ABCDE1234F1Z5');
    expect(updated.lastInvoiceNumber, 42); // untouched by the store-info update
    expect(updated.invoicePrefix, 'INV-');
  });
}
