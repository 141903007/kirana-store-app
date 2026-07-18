// Verifies ReportRepository.getTodaySummary()'s date filtering and
// aggregation — against a real SQLite engine (sqflite_common_ffi), no
// Android device needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smart_kirana_store/database/app_database.dart';
import 'package:smart_kirana_store/models/customer_model.dart';
import 'package:smart_kirana_store/models/product_model.dart';
import 'package:smart_kirana_store/models/product_unit.dart';
import 'package:smart_kirana_store/models/purchase_item_model.dart';
import 'package:smart_kirana_store/models/purchase_model.dart';
import 'package:smart_kirana_store/repository/customer_repository.dart';
import 'package:smart_kirana_store/repository/product_repository.dart';
import 'package:smart_kirana_store/repository/purchase_repository.dart';
import 'package:smart_kirana_store/repository/report_repository.dart';
import 'package:smart_kirana_store/repository/sale_repository.dart';

ProductModel _product(String name, {double currentStock = 1000, double minStockAlert = 100}) {
  final now = DateTime.now().toIso8601String();
  return ProductModel(
    name: name,
    baseUnit: ProductUnit.gram,
    purchasePrice: 30,
    openingStock: currentStock,
    currentStock: currentStock,
    minStockAlert: minStockAlert,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final productRepository = ProductRepository();
  final purchaseRepository = PurchaseRepository(productRepository: productRepository);
  final saleRepository = SaleRepository(productRepository: productRepository);
  final customerRepository = CustomerRepository();
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

  test('getTodaySummary sums only today\'s sales and purchases, excluding older ones', () async {
    final productId = await productRepository.insertProduct(_product('Sugar'));
    final today = DateTime.now().toIso8601String();
    final lastYear = DateTime.now().subtract(const Duration(days: 400)).toIso8601String();

    await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 1,
          unitSellingPrice: 100,
          unitPurchasePrice: 30,
        ),
      ],
      saleDate: today,
    );
    // an old sale that must NOT be counted in today's summary
    await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 5,
          unitSellingPrice: 100,
          unitPurchasePrice: 30,
        ),
      ],
      saleDate: lastYear,
    );

    await purchaseRepository.createPurchase(
      purchase: PurchaseModel(
        dealerName: 'ABC Traders',
        purchaseDate: DateTime.now().toIso8601String(),
        totalAmount: 0,
        createdAt: today,
      ),
      items: [
        PurchaseItemModel(
          purchaseId: 0,
          productId: productId,
          variantLabel: '1kg',
          quantity: 2,
          conversionFactor: 1000,
          pricePerUnit: 40,
          lineTotal: 0,
        ),
      ],
    );

    final summary = await reportRepository.getTodaySummary();
    expect(summary.todaySales, 100); // only the 1-unit sale from today
    expect(summary.todayPurchase, 80); // 2 * 40
  });

  test('getTodaySummary splits profit and loss from separate sales', () async {
    final productId = await productRepository.insertProduct(_product('Sugar'));
    final today = DateTime.now().toIso8601String();

    // profitable sale: sell at 100/kg, cost 30/kg (0.03/gram) -> profit 70
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
      saleDate: today,
    );
    // loss-making sale: sell at 10/kg, cost 30/kg (0.03/gram) -> loss 20
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
      saleDate: today,
    );

    final summary = await reportRepository.getTodaySummary();
    expect(summary.todayProfit, 70);
    expect(summary.todayLoss, 20);
  });

  test('getTodaySummary computes stock value at cost, only for active products', () async {
    final activeId = await productRepository.insertProduct(_product('Sugar', currentStock: 100));
    // purchasePrice 30, currentStock 100 -> value 3000
    final inactiveId =
        await productRepository.insertProduct(_product('Discontinued', currentStock: 500));
    await productRepository.setActive(inactiveId, false);

    final summary = await reportRepository.getTodaySummary();
    expect(summary.stockValue, 3000); // inactive product's stock excluded
    expect(summary.totalProducts, 1);
    expect(activeId, isNotNull);
  });

  test('getTodaySummary counts low-stock and out-of-stock products correctly', () async {
    await productRepository.insertProduct(_product('Low', currentStock: 50, minStockAlert: 100));
    await productRepository.insertProduct(_product('Out', currentStock: 0, minStockAlert: 100));
    await productRepository.insertProduct(_product('Healthy', currentStock: 900, minStockAlert: 100));

    final summary = await reportRepository.getTodaySummary();
    expect(summary.lowStockCount, 1);
    expect(summary.outOfStockCount, 1);
    expect(summary.totalProducts, 3);
  });

  test('getTodaySummary counts all customers', () async {
    final now = DateTime.now().toIso8601String();
    await customerRepository.insertCustomer(
      CustomerModel(name: 'Ramesh', createdAt: now, updatedAt: now),
    );
    await customerRepository.insertCustomer(
      CustomerModel(name: 'Suresh', createdAt: now, updatedAt: now),
    );

    final summary = await reportRepository.getTodaySummary();
    expect(summary.totalCustomers, 2);
  });
}
