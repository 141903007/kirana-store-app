// Verifies ReportRepository's Profit & Loss queries: date-range summary,
// daily trend grouping, and per-product/per-bill breakdowns — against a
// real SQLite engine (sqflite_common_ffi), no Android device needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smart_kirana_store/database/app_database.dart';
import 'package:smart_kirana_store/models/product_model.dart';
import 'package:smart_kirana_store/models/product_unit.dart';
import 'package:smart_kirana_store/repository/product_repository.dart';
import 'package:smart_kirana_store/repository/report_repository.dart';
import 'package:smart_kirana_store/repository/sale_repository.dart';

ProductModel _product(String name) {
  final now = DateTime.now().toIso8601String();
  return ProductModel(
    name: name,
    baseUnit: ProductUnit.gram,
    purchasePrice: 30,
    openingStock: 5000,
    currentStock: 5000,
    minStockAlert: 100,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final productRepository = ProductRepository();
  final saleRepository = SaleRepository(productRepository: productRepository);
  final reportRepository = ReportRepository();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    final dbPath = await databaseFactory.getDatabasesPath();
    await databaseFactory.deleteDatabase('$dbPath/smart_kirana_store.db');
  });

  test('getProfitLossSummary sums profit/loss within an inclusive date range', () async {
    final productId = await productRepository.insertProduct(_product('Sugar'));
    final inRange = DateTime(2026, 3, 15);
    final outOfRange = DateTime(2026, 4, 1);

    await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 1,
          unitSellingPrice: 100,
          unitPurchasePrice: 0.03,
        ),
      ],
      saleDate: inRange.toIso8601String(),
    );
    await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 1,
          unitSellingPrice: 10,
          unitPurchasePrice: 0.03,
        ),
      ],
      saleDate: outOfRange.toIso8601String(), // must be excluded
    );

    final summary = await reportRepository.getProfitLossSummary(
      DateTime(2026, 3, 1),
      DateTime(2026, 3, 31),
    );
    expect(summary.profit, 70);
    expect(summary.loss, 0);
    expect(summary.netProfit, 70);
  });

  test('getDailyProfitTrend groups multiple sales on the same day into one point', () async {
    final productId = await productRepository.insertProduct(_product('Sugar'));
    final day = DateTime(2026, 3, 10);

    await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 1,
          unitSellingPrice: 100,
          unitPurchasePrice: 0.03,
        ),
      ],
      saleDate: day.toIso8601String(),
    );
    await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 1,
          unitSellingPrice: 10,
          unitPurchasePrice: 0.03,
        ),
      ],
      saleDate: day.add(const Duration(hours: 5)).toIso8601String(),
    );

    final trend = await reportRepository.getDailyProfitTrend(
      DateTime(2026, 3, 1),
      DateTime(2026, 3, 31),
    );
    expect(trend.length, 1);
    expect(trend.first.profit, 70);
    expect(trend.first.loss, 20);
  });

  test('getProfitPerProduct aggregates line profit across sales, sorted descending', () async {
    final sugarId = await productRepository.insertProduct(_product('Sugar'));
    final riceId = await productRepository.insertProduct(_product('Rice'));
    final day = DateTime(2026, 3, 10).toIso8601String();

    await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: sugarId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 1,
          unitSellingPrice: 100,
          unitPurchasePrice: 0.03,
        ),
        SaleItemInput(
          productId: riceId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 1,
          unitSellingPrice: 200,
          unitPurchasePrice: 0.03,
        ),
      ],
      saleDate: day,
    );

    final perProduct = await reportRepository.getProfitPerProduct(
      DateTime(2026, 3, 1),
      DateTime(2026, 3, 31),
    );
    expect(perProduct.length, 2);
    expect(perProduct.first.productName, 'Rice'); // higher profit (170) sorts first
    expect(perProduct.first.profit, 170);
    expect(perProduct.last.productName, 'Sugar');
    expect(perProduct.last.profit, 70);
  });

  test('getProfitPerBill returns one row per sale with its invoice number', () async {
    final productId = await productRepository.insertProduct(_product('Sugar'));
    final day = DateTime(2026, 3, 10).toIso8601String();

    final sale = await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 1,
          unitSellingPrice: 100,
          unitPurchasePrice: 0.03,
        ),
      ],
      saleDate: day,
    );

    final perBill = await reportRepository.getProfitPerBill(
      DateTime(2026, 3, 1),
      DateTime(2026, 3, 31),
    );
    expect(perBill.length, 1);
    expect(perBill.first.invoiceNumber, sale.invoiceNumber);
    expect(perBill.first.profit, 70);
  });
}
