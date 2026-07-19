// Verifies StockHistoryRepository reads back the ledger entries that
// ProductRepository.adjustStock writes, ordered most-recent-first — against
// a real SQLite engine (sqflite_common_ffi), no Android device needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smart_kirana_store/database/app_database.dart';
import 'package:smart_kirana_store/database/db_tables.dart';
import 'package:smart_kirana_store/models/product_model.dart';
import 'package:smart_kirana_store/models/product_unit.dart';
import 'package:smart_kirana_store/repository/product_repository.dart';
import 'package:smart_kirana_store/repository/stock_history_repository.dart';

void main() {
  final productRepository = ProductRepository();
  final stockHistoryRepository = StockHistoryRepository();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    final dbPath = await databaseFactory.getDatabasesPath();
    await databaseFactory.deleteDatabase('$dbPath/smart_kirana_store.db');
  });

  test('getForProduct returns entries most-recent-first and only for that product', () async {
    final now = DateTime.now().toIso8601String();
    final productAId = await productRepository.insertProduct(ProductModel(
      name: 'Sugar',
      baseUnit: ProductUnit.gram,
      purchasePrice: 30,
      openingStock: 1000,
      currentStock: 1000,
      minStockAlert: 100,
      createdAt: now,
      updatedAt: now,
    ));
    final productBId = await productRepository.insertProduct(ProductModel(
      name: 'Rice',
      baseUnit: ProductUnit.gram,
      purchasePrice: 40,
      openingStock: 1000,
      currentStock: 1000,
      minStockAlert: 100,
      createdAt: now,
      updatedAt: now,
    ));

    await productRepository.adjustStock(productAId, 500, StockChangeType.purchase);
    await productRepository.adjustStock(productBId, 200, StockChangeType.purchase);
    await productRepository.adjustStock(productAId, -100, StockChangeType.sale);
    await productRepository.adjustStock(productAId, -50, StockChangeType.adjustment,
        notes: 'Damaged stock');

    final history = await stockHistoryRepository.getForProduct(productAId);
    // 4, not 3: insertProduct also seeds an "opening" entry for the 1000
    // opening stock, ahead of the purchase/sale/adjustment entries below.
    expect(history.length, 4);
    expect(history[0].changeType, StockChangeType.adjustment);
    expect(history[0].notes, 'Damaged stock');
    expect(history[0].resultingStock, 1350); // 1000+500-100-50
    expect(history[1].changeType, StockChangeType.sale);
    expect(history[2].changeType, StockChangeType.purchase);
    expect(history[3].changeType, StockChangeType.opening);
    expect(history[3].quantityChange, 1000);
  });
}
