// Exercises ProductRepository's trickiest behavior — variant replacement
// defaulting, the stock ledger, and search filters — against a real SQLite
// engine (sqflite_common_ffi), no Android device needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smart_kirana_store/database/app_database.dart';
import 'package:smart_kirana_store/database/db_tables.dart';
import 'package:smart_kirana_store/models/product_model.dart';
import 'package:smart_kirana_store/models/product_price_variant_model.dart';
import 'package:smart_kirana_store/models/product_unit.dart';
import 'package:smart_kirana_store/repository/product_repository.dart';

ProductModel _sugarProduct({double currentStock = 1000, double minStockAlert = 200}) {
  final now = DateTime.now().toIso8601String();
  return ProductModel(
    name: 'Sugar',
    baseUnit: ProductUnit.gram,
    purchasePrice: 40,
    openingStock: currentStock,
    currentStock: currentStock,
    minStockAlert: minStockAlert,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final repository = ProductRepository();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    final dbPath = await databaseFactory.getDatabasesPath();
    await databaseFactory.deleteDatabase('$dbPath/smart_kirana_store.db');
  });

  test('replaceVariants forces the first variant to default when none is marked', () async {
    final productId = await repository.insertProduct(_sugarProduct());

    await repository.replaceVariants(productId, [
      const ProductPriceVariantModel(productId: 0, label: '1kg', quantityInBaseUnit: 1000, sellingPrice: 50),
      const ProductPriceVariantModel(productId: 0, label: '500g', quantityInBaseUnit: 500, sellingPrice: 25),
    ]);

    final variants = await repository.getVariants(productId);
    expect(variants.length, 2);
    expect(variants.where((v) => v.isDefault).length, 1);
    expect(variants.first.isDefault, isTrue);
  });

  test('replaceVariants keeps exactly one default when caller marks one', () async {
    final productId = await repository.insertProduct(_sugarProduct());

    await repository.replaceVariants(productId, [
      const ProductPriceVariantModel(productId: 0, label: '1kg', quantityInBaseUnit: 1000, sellingPrice: 50),
      const ProductPriceVariantModel(
          productId: 0, label: '500g', quantityInBaseUnit: 500, sellingPrice: 25, isDefault: true),
    ]);

    final variants = await repository.getVariants(productId);
    expect(variants.where((v) => v.isDefault).length, 1);
    expect(variants.firstWhere((v) => v.label == '500g').isDefault, isTrue);
  });

  test('adjustStock updates current_stock and writes a stock_history row', () async {
    final productId = await repository.insertProduct(_sugarProduct(currentStock: 1000));

    await repository.adjustStock(productId, -300, StockChangeType.sale, notes: 'test sale');

    final updated = await repository.getById(productId);
    expect(updated!.currentStock, 700);

    final db = await AppDatabase.instance.database;
    final history = await db.query(StockHistoryTable.table,
        where: '${StockHistoryTable.productId} = ?', whereArgs: [productId]);
    expect(history.length, 1);
    expect(history.first[StockHistoryTable.quantityChange], -300);
    expect(history.first[StockHistoryTable.resultingStock], 700);
    expect(history.first[StockHistoryTable.changeType], StockChangeType.sale);
  });

  test('search finds a product by partial barcode match', () async {
    final product = _sugarProduct().copyWith(barcode: '8901030875021');
    final productId = await repository.insertProduct(product);
    await repository.replaceVariants(productId, [
      const ProductPriceVariantModel(
          productId: 0, label: '1kg', quantityInBaseUnit: 1000, sellingPrice: 50, isDefault: true),
    ]);

    final results = await repository.search(query: '890103');
    expect(results.length, 1);
    expect(results.first.product.name, 'Sugar');
    expect(results.first.defaultVariantLabel, '1kg');
    expect(results.first.defaultVariantPrice, 50);
  });

  test('search respects lowStockOnly and outOfStockOnly filters', () async {
    final lowId = await repository.insertProduct(
        _sugarProduct(currentStock: 50, minStockAlert: 200).copyWith(name: 'Low Sugar'));
    final outId = await repository.insertProduct(
        _sugarProduct(currentStock: 0, minStockAlert: 200).copyWith(name: 'Out Sugar'));
    final healthyId = await repository.insertProduct(
        _sugarProduct(currentStock: 900, minStockAlert: 200).copyWith(name: 'Healthy Sugar'));

    final lowResults = await repository.search(lowStockOnly: true);
    expect(lowResults.map((i) => i.product.id), contains(lowId));
    expect(lowResults.map((i) => i.product.id), isNot(contains(outId)));
    expect(lowResults.map((i) => i.product.id), isNot(contains(healthyId)));

    final outResults = await repository.search(outOfStockOnly: true);
    expect(outResults.map((i) => i.product.id), contains(outId));
    expect(outResults.map((i) => i.product.id), isNot(contains(lowId)));
  });

  test('deactivated products are excluded by default and included with includeInactive', () async {
    final productId = await repository.insertProduct(_sugarProduct());
    await repository.setActive(productId, false);

    final defaultResults = await repository.search();
    expect(defaultResults.map((i) => i.product.id), isNot(contains(productId)));

    final withInactive = await repository.search(includeInactive: true);
    expect(withInactive.map((i) => i.product.id), contains(productId));
  });

  test('isBarcodeTaken respects excludingProductId', () async {
    final productId =
        await repository.insertProduct(_sugarProduct().copyWith(barcode: '12345'));

    expect(await repository.isBarcodeTaken('12345'), isTrue);
    expect(await repository.isBarcodeTaken('12345', excludingProductId: productId), isFalse);
    expect(await repository.isBarcodeTaken('99999'), isFalse);
  });
}
