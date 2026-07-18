// Exercises CustomerRepository's core correctness: the computed
// (never-stored) total purchase amount, purchase history ordering, and the
// safe hard-delete behavior — against a real SQLite engine
// (sqflite_common_ffi), no Android device needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smart_kirana_store/database/app_database.dart';
import 'package:smart_kirana_store/models/customer_model.dart';
import 'package:smart_kirana_store/models/product_model.dart';
import 'package:smart_kirana_store/models/product_unit.dart';
import 'package:smart_kirana_store/repository/customer_repository.dart';
import 'package:smart_kirana_store/repository/product_repository.dart';
import 'package:smart_kirana_store/repository/sale_repository.dart';

CustomerModel _customer({String name = 'Ramesh', String? mobile}) {
  final now = DateTime.now().toIso8601String();
  return CustomerModel(name: name, mobile: mobile, createdAt: now, updatedAt: now);
}

ProductModel _sugarProduct() {
  final now = DateTime.now().toIso8601String();
  return ProductModel(
    name: 'Sugar',
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
  final customerRepository = CustomerRepository();
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

  test('search computes total purchase amount from sales, not a stored column', () async {
    final customerId = await customerRepository.insertCustomer(_customer());
    final productId = await productRepository.insertProduct(_sugarProduct());
    final now = DateTime.now().toIso8601String();

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
      saleDate: now,
    );
    await saleRepository.createSale(
      customerId: customerId,
      items: [
        SaleItemInput(
          productId: productId,
          variantLabel: '500g',
          conversionFactor: 500,
          quantity: 1,
          unitSellingPrice: 25,
          unitPurchasePrice: 30,
        ),
      ],
      saleDate: now,
    );

    final results = await customerRepository.search();
    expect(results.length, 1);
    expect(results.first.totalPurchaseAmount, 75);

    final total = await customerRepository.getTotalPurchaseAmount(customerId);
    expect(total, 75);
  });

  test('customer with no sales has zero total purchase amount, not null', () async {
    await customerRepository.insertCustomer(_customer());

    final results = await customerRepository.search();
    expect(results.first.totalPurchaseAmount, 0);
  });

  test('getPurchaseHistory orders sales by date descending', () async {
    final customerId = await customerRepository.insertCustomer(_customer());
    final productId = await productRepository.insertProduct(_sugarProduct());

    final sale1 = await saleRepository.createSale(
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
      saleDate: DateTime(2026, 1, 1).toIso8601String(),
    );
    final sale2 = await saleRepository.createSale(
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
      saleDate: DateTime(2026, 1, 5).toIso8601String(),
    );

    final history = await customerRepository.getPurchaseHistory(customerId);
    expect(history.length, 2);
    expect(history.first.invoiceNumber, sale2.invoiceNumber);
    expect(history.last.invoiceNumber, sale1.invoiceNumber);
  });

  test('search filters by name or mobile substring', () async {
    await customerRepository.insertCustomer(_customer(name: 'Ramesh Kumar', mobile: '9876543210'));
    await customerRepository.insertCustomer(_customer(name: 'Suresh Patel', mobile: '9123456780'));

    final byName = await customerRepository.search(query: 'ramesh');
    expect(byName.length, 1);
    expect(byName.first.customer.name, 'Ramesh Kumar');

    final byMobile = await customerRepository.search(query: '9123');
    expect(byMobile.length, 1);
    expect(byMobile.first.customer.name, 'Suresh Patel');
  });

  test('deleteCustomer sets sales.customer_id to null rather than blocking or cascading', () async {
    final customerId = await customerRepository.insertCustomer(_customer());
    final productId = await productRepository.insertProduct(_sugarProduct());
    final now = DateTime.now().toIso8601String();

    final sale = await saleRepository.createSale(
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
      saleDate: now,
    );

    await customerRepository.deleteCustomer(customerId);

    expect(await customerRepository.getById(customerId), isNull);

    final db = await AppDatabase.instance.database;
    final salesRows = await db.query('sales', where: 'id = ?', whereArgs: [sale.id]);
    expect(salesRows.length, 1);
    expect(salesRows.first['customer_id'], isNull);
  });
}
