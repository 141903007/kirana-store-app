// Exercises PurchaseRepository's core correctness: stock increases, cost
// (purchase_price) updates, totals are server-recomputed, and the join
// queries for list/detail work — against a real SQLite engine
// (sqflite_common_ffi), no Android device needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smart_kirana_store/database/app_database.dart';
import 'package:smart_kirana_store/models/product_model.dart';
import 'package:smart_kirana_store/models/product_unit.dart';
import 'package:smart_kirana_store/models/purchase_item_model.dart';
import 'package:smart_kirana_store/models/purchase_model.dart';
import 'package:smart_kirana_store/repository/product_repository.dart';
import 'package:smart_kirana_store/repository/purchase_repository.dart';

ProductModel _sugarProduct({double currentStock = 0, double purchasePrice = 0}) {
  final now = DateTime.now().toIso8601String();
  return ProductModel(
    name: 'Sugar',
    baseUnit: ProductUnit.gram,
    purchasePrice: purchasePrice,
    openingStock: currentStock,
    currentStock: currentStock,
    minStockAlert: 100,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final productRepository = ProductRepository();
  final purchaseRepository = PurchaseRepository(productRepository: productRepository);

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    final dbPath = await databaseFactory.getDatabasesPath();
    await databaseFactory.deleteDatabase('$dbPath/smart_kirana_store.db');
  });

  test('createPurchase increases stock by quantity * conversionFactor', () async {
    final productId = await productRepository.insertProduct(_sugarProduct(currentStock: 1000));
    final now = DateTime.now().toIso8601String();

    await purchaseRepository.createPurchase(
      purchase: PurchaseModel(
        dealerName: 'ABC Traders',
        purchaseDate: now,
        totalAmount: 0, // ignored — repository recomputes
        createdAt: now,
      ),
      items: [
        PurchaseItemModel(
          purchaseId: 0,
          productId: productId,
          variantLabel: '1kg',
          quantity: 5,
          conversionFactor: 1000, // 5 * 1000g = 5000g
          pricePerUnit: 45,
          lineTotal: 0, // ignored — repository recomputes
        ),
      ],
    );

    final updated = await productRepository.getById(productId);
    expect(updated!.currentStock, 6000); // 1000 + 5*1000
  });

  test('createPurchase updates purchase_price to pricePerUnit / conversionFactor', () async {
    final productId = await productRepository.insertProduct(_sugarProduct(purchasePrice: 30));
    final now = DateTime.now().toIso8601String();

    await purchaseRepository.createPurchase(
      purchase: PurchaseModel(
        dealerName: 'ABC Traders',
        purchaseDate: now,
        totalAmount: 0,
        createdAt: now,
      ),
      items: [
        PurchaseItemModel(
          purchaseId: 0,
          productId: productId,
          variantLabel: '1kg',
          quantity: 2,
          conversionFactor: 1000,
          pricePerUnit: 45, // cost per kg -> 45/1000 = 0.045 per gram
          lineTotal: 0,
        ),
      ],
    );

    final updated = await productRepository.getById(productId);
    expect(updated!.purchasePrice, closeTo(0.045, 0.0001));
  });

  test('createPurchase recomputes totalAmount server-side from all line items', () async {
    final productAId = await productRepository.insertProduct(_sugarProduct());
    final productBId = await productRepository.insertProduct(_sugarProduct().copyWith(name: 'Rice'));
    final now = DateTime.now().toIso8601String();

    await purchaseRepository.createPurchase(
      purchase: PurchaseModel(
        dealerName: 'ABC Traders',
        purchaseDate: now,
        totalAmount: 999999, // deliberately wrong — must be ignored
        createdAt: now,
      ),
      items: [
        PurchaseItemModel(
          purchaseId: 0,
          productId: productAId,
          variantLabel: '1kg',
          quantity: 2,
          conversionFactor: 1000,
          pricePerUnit: 50,
          lineTotal: 0,
        ),
        PurchaseItemModel(
          purchaseId: 0,
          productId: productBId,
          variantLabel: '1kg',
          quantity: 3,
          conversionFactor: 1000,
          pricePerUnit: 60,
          lineTotal: 0,
        ),
      ],
    );

    final all = await purchaseRepository.getAll();
    expect(all.length, 1);
    expect(all.first.purchase.totalAmount, (2 * 50) + (3 * 60));
    expect(all.first.itemCount, 2);
  });

  test('getItemsForPurchase returns line items joined with product name', () async {
    final productId = await productRepository.insertProduct(_sugarProduct());
    final now = DateTime.now().toIso8601String();

    final purchaseId = await purchaseRepository.createPurchase(
      purchase: PurchaseModel(
        dealerName: 'ABC Traders',
        purchaseDate: now,
        totalAmount: 0,
        createdAt: now,
      ),
      items: [
        PurchaseItemModel(
          purchaseId: 0,
          productId: productId,
          variantLabel: 'Box of 12',
          quantity: 1,
          conversionFactor: 12,
          pricePerUnit: 480,
          lineTotal: 0,
        ),
      ],
    );

    final details = await purchaseRepository.getItemsForPurchase(purchaseId);
    expect(details.length, 1);
    expect(details.first.productName, 'Sugar');
    expect(details.first.item.variantLabel, 'Box of 12');
    expect(details.first.item.lineTotal, 480);
  });

  test('createPurchase writes a stock_history row referencing the purchase', () async {
    final productId = await productRepository.insertProduct(_sugarProduct());
    final now = DateTime.now().toIso8601String();

    final purchaseId = await purchaseRepository.createPurchase(
      purchase: PurchaseModel(
        dealerName: 'ABC Traders',
        purchaseDate: now,
        totalAmount: 0,
        createdAt: now,
      ),
      items: [
        PurchaseItemModel(
          purchaseId: 0,
          productId: productId,
          variantLabel: '1kg',
          quantity: 1,
          conversionFactor: 1000,
          pricePerUnit: 40,
          lineTotal: 0,
        ),
      ],
    );

    final db = await AppDatabase.instance.database;
    final history = await db.query('stock_history', where: 'product_id = ?', whereArgs: [productId]);
    expect(history.length, 1);
    expect(history.first['change_type'], 'purchase');
    expect(history.first['reference_id'], purchaseId);
    expect(history.first['quantity_change'], 1000);
  });
}
