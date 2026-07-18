// Exercises SaleRepository's core correctness: atomic invoice numbering,
// discount-before-GST math, per-line profit snapshotting, and stock
// decrement — against a real SQLite engine (sqflite_common_ffi), no
// Android device needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smart_kirana_store/database/app_database.dart';
import 'package:smart_kirana_store/models/product_model.dart';
import 'package:smart_kirana_store/models/product_unit.dart';
import 'package:smart_kirana_store/repository/product_repository.dart';
import 'package:smart_kirana_store/repository/sale_repository.dart';

ProductModel _sugarProduct({double currentStock = 1000, double purchasePrice = 30}) {
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
  final saleRepository = SaleRepository(productRepository: productRepository);

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    final dbPath = await databaseFactory.getDatabasesPath();
    await databaseFactory.deleteDatabase('$dbPath/smart_kirana_store.db');
  });

  test('createSale assigns sequential invoice numbers starting at INV-000001', () async {
    final productId = await productRepository.insertProduct(_sugarProduct());
    final now = DateTime.now().toIso8601String();

    final sale1 = await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 1,
          unitSellingPrice: 50,
          unitPurchasePrice: 30,
        ),
      ],
      saleDate: now,
    );
    final sale2 = await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 1,
          unitSellingPrice: 50,
          unitPurchasePrice: 30,
        ),
      ],
      saleDate: now,
    );

    expect(sale1.invoiceNumber, 'INV-000001');
    expect(sale2.invoiceNumber, 'INV-000002');
  });

  test('createSale applies discount before GST, matching the documented formula', () async {
    final productId = await productRepository.insertProduct(_sugarProduct());
    final now = DateTime.now().toIso8601String();

    // subtotal = 2 * 100 = 200; discount 10% = 20; taxable = 180; gst 5% = 9; total = 189
    final sale = await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 2,
          unitSellingPrice: 100,
          unitPurchasePrice: 30,
          gstPercent: 5,
        ),
      ],
      discountPercent: 10,
      saleDate: now,
    );

    expect(sale.subtotal, 200);
    expect(sale.discountAmount, 20);
    expect(sale.gstAmount, 9);
    expect(sale.totalAmount, 189);
  });

  test('createSale snapshots line profit as taxable revenue minus cost of goods', () async {
    final productId = await productRepository.insertProduct(_sugarProduct(purchasePrice: 30));
    final now = DateTime.now().toIso8601String();

    // qty 2 * 1000g conversion, unit sell 100/kg, no discount/gst:
    // taxable = 200; cost = 2*1000*0.03 (purchasePrice is per-gram here) = 60; profit = 140
    final sale = await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 2,
          unitSellingPrice: 100,
          unitPurchasePrice: 0.03,
        ),
      ],
      saleDate: now,
    );

    expect(sale.totalProfit, closeTo(140, 0.001));

    final items = await saleRepository.getItemsForSale(sale.id!);
    expect(items.first.item.lineProfit, closeTo(140, 0.001));
  });

  test('createSale decreases stock by quantity * conversionFactor', () async {
    final productId = await productRepository.insertProduct(_sugarProduct(currentStock: 5000));
    final now = DateTime.now().toIso8601String();

    await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 3,
          unitSellingPrice: 50,
          unitPurchasePrice: 30,
        ),
      ],
      saleDate: now,
    );

    final updated = await productRepository.getById(productId);
    expect(updated!.currentStock, 2000); // 5000 - 3*1000
  });

  test('getAll orders sales by date descending and reports item counts', () async {
    final productId = await productRepository.insertProduct(_sugarProduct());
    final day1 = DateTime(2026, 1, 1).toIso8601String();
    final day2 = DateTime(2026, 1, 2).toIso8601String();

    await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 1,
          unitSellingPrice: 50,
          unitPurchasePrice: 30,
        ),
      ],
      saleDate: day1,
    );
    await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 1,
          unitSellingPrice: 50,
          unitPurchasePrice: 30,
        ),
        SaleItemInput(
          productId: productId,
          variantLabel: '500g',
          conversionFactor: 500,
          quantity: 1,
          unitSellingPrice: 25,
          unitPurchasePrice: 30,
        ),
      ],
      saleDate: day2,
    );

    final all = await saleRepository.getAll();
    expect(all.length, 2);
    expect(all.first.sale.saleDate, day2);
    expect(all.first.itemCount, 2);
    expect(all.last.itemCount, 1);
  });
}
