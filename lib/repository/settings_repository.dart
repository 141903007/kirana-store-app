import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/db_tables.dart';
import '../models/store_settings_model.dart';
import '../services/invoice_number_service.dart';

class SettingsRepository {
  Future<StoreSettingsModel> get({DatabaseExecutor? executor}) async {
    final db = executor ?? await AppDatabase.instance.database;
    final rows = await db.query(
      StoreSettingsTable.table,
      where: '${StoreSettingsTable.id} = ?',
      whereArgs: [StoreSettingsTable.singletonId],
      limit: 1,
    );
    return StoreSettingsModel.fromMap(rows.first);
  }

  /// Updates the store-info columns only — never touches `invoice_prefix`/
  /// `last_invoice_number`, which only `takeNextInvoiceNumber` may write.
  Future<void> update(StoreSettingsModel settings) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      StoreSettingsTable.table,
      {
        StoreSettingsTable.storeName: settings.storeName,
        StoreSettingsTable.storeAddress: settings.storeAddress,
        StoreSettingsTable.storePhone: settings.storePhone,
        StoreSettingsTable.storeGstNumber: settings.storeGstNumber,
        StoreSettingsTable.updatedAt: DateTime.now().toIso8601String(),
      },
      where: '${StoreSettingsTable.id} = ?',
      whereArgs: [StoreSettingsTable.singletonId],
    );
  }

  /// Atomically reads and increments `last_invoice_number`, returning the
  /// newly formatted invoice number. Requires the caller's own open
  /// [executor] — it must only ever run inside `SaleRepository.createSale`'s
  /// single transaction, otherwise two concurrent sales not sharing that
  /// transaction could still race to the same number.
  Future<String> takeNextInvoiceNumber({required DatabaseExecutor executor}) async {
    final rows = await executor.query(
      StoreSettingsTable.table,
      columns: [StoreSettingsTable.invoicePrefix, StoreSettingsTable.lastInvoiceNumber],
      where: '${StoreSettingsTable.id} = ?',
      whereArgs: [StoreSettingsTable.singletonId],
      limit: 1,
    );
    final prefix = rows.first[StoreSettingsTable.invoicePrefix] as String;
    final lastNumber = rows.first[StoreSettingsTable.lastInvoiceNumber] as int;
    final nextNumber = lastNumber + 1;

    await executor.update(
      StoreSettingsTable.table,
      {
        StoreSettingsTable.lastInvoiceNumber: nextNumber,
        StoreSettingsTable.updatedAt: DateTime.now().toIso8601String(),
      },
      where: '${StoreSettingsTable.id} = ?',
      whereArgs: [StoreSettingsTable.singletonId],
    );

    return InvoiceNumberService.format(prefix, nextNumber);
  }
}
