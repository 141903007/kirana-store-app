// Verifies the schema created in AppDatabase and the default seed data.
//
// Overrides sqflite's global `databaseFactory` with the FFI implementation
// so this runs against a real SQLite engine on the desktop test host —
// no Android device/emulator needed — while still exercising the actual
// AppDatabase singleton (onCreate/onConfigure/seed), not a copy of it.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smart_kirana_store/core/constants/app_constants.dart';
import 'package:smart_kirana_store/database/app_database.dart';
import 'package:smart_kirana_store/database/db_tables.dart';
import 'package:smart_kirana_store/utils/password_hasher.dart';

const _allTables = [
  UsersTable.table,
  CategoriesTable.table,
  ProductsTable.table,
  ProductPriceVariantsTable.table,
  CustomersTable.table,
  PurchasesTable.table,
  PurchaseItemsTable.table,
  SalesTable.table,
  SaleItemsTable.table,
  StockHistoryTable.table,
  StoreSettingsTable.table,
];

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // AppDatabase is a singleton, so each test closes it and deletes the
  // underlying file first to get a fresh, isolated database.
  setUp(() async {
    await AppDatabase.instance.close();
    final dbPath = await databaseFactory.getDatabasesPath();
    await databaseFactory
        .deleteDatabase('$dbPath${Platform.pathSeparator}${AppConstants.databaseName}');
  });

  test('creates every table declared in db_tables.dart', () async {
    final db = await AppDatabase.instance.database;

    final tables = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ?',
      whereArgs: ['table'],
    );
    final tableNames = tables.map((row) => row['name'] as String).toSet();

    for (final table in _allTables) {
      expect(tableNames.contains(table), isTrue, reason: '$table was not created');
    }
  });

  test('seeds exactly one default admin user with a hashed password',
      () async {
    final db = await AppDatabase.instance.database;

    final users = await db.query(UsersTable.table);
    expect(users.length, 1);
    expect(users.first[UsersTable.username], AppConstants.defaultUsername);
    expect(users.first[UsersTable.passwordHash],
        isNot(AppConstants.defaultPassword));
    expect(
      PasswordHasher.matches(
        AppConstants.defaultPassword,
        users.first[UsersTable.passwordHash] as String,
      ),
      isTrue,
    );
  });

  test('seeds a single store_settings row with id = singletonId', () async {
    final db = await AppDatabase.instance.database;

    final rows = await db.query(StoreSettingsTable.table);
    expect(rows.length, 1);
    expect(rows.first[StoreSettingsTable.id], StoreSettingsTable.singletonId);
  });

  test('cascades product deletion to its price variants', () async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    final productId = await db.insert(ProductsTable.table, {
      ProductsTable.name: 'Sugar',
      ProductsTable.baseUnit: 'gram',
      ProductsTable.purchasePrice: 40.0,
      ProductsTable.openingStock: 1000,
      ProductsTable.currentStock: 1000,
      ProductsTable.minStockAlert: 100,
      ProductsTable.createdAt: now,
      ProductsTable.updatedAt: now,
    });

    await db.insert(ProductPriceVariantsTable.table, {
      ProductPriceVariantsTable.productId: productId,
      ProductPriceVariantsTable.label: '1kg',
      ProductPriceVariantsTable.quantityInBaseUnit: 1000,
      ProductPriceVariantsTable.sellingPrice: 50.0,
      ProductPriceVariantsTable.isDefault: 1,
    });

    await db.delete(ProductsTable.table,
        where: '${ProductsTable.id} = ?', whereArgs: [productId]);

    final remainingVariants = await db.query(ProductPriceVariantsTable.table);
    expect(remainingVariants, isEmpty);
  });
}
