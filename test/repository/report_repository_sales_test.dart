// Verifies ReportRepository.getSalesForRange's date filtering and its
// customer-name join (including the walk-in/null-customer case) — against
// a real SQLite engine (sqflite_common_ffi), no Android device needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smart_kirana_store/database/app_database.dart';
import 'package:smart_kirana_store/models/customer_model.dart';
import 'package:smart_kirana_store/models/product_model.dart';
import 'package:smart_kirana_store/models/product_unit.dart';
import 'package:smart_kirana_store/repository/customer_repository.dart';
import 'package:smart_kirana_store/repository/product_repository.dart';
import 'package:smart_kirana_store/repository/report_repository.dart';
import 'package:smart_kirana_store/repository/sale_repository.dart';

void main() {
  final productRepository = ProductRepository();
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

  test('getSalesForRange includes the customer name when one is linked, null for walk-in',
      () async {
    final now = DateTime.now().toIso8601String();
    final productId = await productRepository.insertProduct(ProductModel(
      name: 'Sugar',
      baseUnit: ProductUnit.gram,
      purchasePrice: 30,
      openingStock: 1000,
      currentStock: 1000,
      minStockAlert: 100,
      createdAt: now,
      updatedAt: now,
    ));
    final customerId = await customerRepository.insertCustomer(
      CustomerModel(name: 'Ramesh', createdAt: now, updatedAt: now),
    );

    final day = DateTime(2026, 3, 10).toIso8601String();

    await saleRepository.createSale(
      customerId: customerId,
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
      saleDate: day,
    );
    await saleRepository.createSale(
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '1kg',
          conversionFactor: 1000,
          quantity: 1,
          unitSellingPrice: 60,
          unitPurchasePrice: 30,
        ),
      ],
      saleDate: day,
    );

    final report = await reportRepository.getSalesForRange(
      DateTime(2026, 3, 1),
      DateTime(2026, 3, 31),
    );

    expect(report.length, 2);
    expect(report.any((r) => r.customerName == 'Ramesh'), isTrue);
    expect(report.any((r) => r.customerName == null), isTrue);
  });

  test('getSalesForRange excludes sales outside the date range', () async {
    final now = DateTime.now().toIso8601String();
    final productId = await productRepository.insertProduct(ProductModel(
      name: 'Sugar',
      baseUnit: ProductUnit.gram,
      purchasePrice: 30,
      openingStock: 1000,
      currentStock: 1000,
      minStockAlert: 100,
      createdAt: now,
      updatedAt: now,
    ));

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
      saleDate: DateTime(2025, 12, 25).toIso8601String(),
    );

    final report = await reportRepository.getSalesForRange(
      DateTime(2026, 3, 1),
      DateTime(2026, 3, 31),
    );
    expect(report, isEmpty);
  });
}
