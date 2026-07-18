import '../database/app_database.dart';
import '../database/db_tables.dart';
import '../models/customer_model.dart';
import '../models/sale_model.dart';

/// A customer plus their lifetime purchase total, flattened for the list
/// screen. There is no stored running total on `customers` — it's always
/// computed via `SUM(sales.total_amount)` at read time, so it can never
/// drift from the sales that actually happened.
class CustomerListItem {
  final CustomerModel customer;
  final double totalPurchaseAmount;

  const CustomerListItem({required this.customer, required this.totalPurchaseAmount});
}

class CustomerRepository {
  Future<int> insertCustomer(CustomerModel customer) async {
    final db = await AppDatabase.instance.database;
    final map = customer.toMap()..remove(CustomersTable.id);
    return db.insert(CustomersTable.table, map);
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    final db = await AppDatabase.instance.database;
    final map = customer.toMap()..remove(CustomersTable.id);
    await db.update(
      CustomersTable.table,
      map,
      where: '${CustomersTable.id} = ?',
      whereArgs: [customer.id],
    );
  }

  /// Safe to hard-delete (unlike products): `sales.customer_id` is
  /// `ON DELETE SET NULL`, so past invoices just become walk-in sales
  /// rather than being orphaned or blocked.
  Future<void> deleteCustomer(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(CustomersTable.table, where: '${CustomersTable.id} = ?', whereArgs: [id]);
  }

  Future<CustomerModel?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      CustomersTable.table,
      where: '${CustomersTable.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CustomerModel.fromMap(rows.first);
  }

  Future<List<CustomerListItem>> search({String? query}) async {
    final db = await AppDatabase.instance.database;

    final whereClauses = <String>[];
    final whereArgs = <Object?>[];
    if (query != null && query.trim().isNotEmpty) {
      final like = '%${query.trim()}%';
      whereClauses.add(
        '(c.${CustomersTable.name} LIKE ? OR c.${CustomersTable.mobile} LIKE ?)',
      );
      whereArgs.addAll([like, like]);
    }
    final whereSql = whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    final rows = await db.rawQuery('''
      SELECT c.*, COALESCE(SUM(s.${SalesTable.totalAmount}), 0) AS total_purchase_amount
      FROM ${CustomersTable.table} c
      LEFT JOIN ${SalesTable.table} s ON s.${SalesTable.customerId} = c.${CustomersTable.id}
      $whereSql
      GROUP BY c.${CustomersTable.id}
      ORDER BY c.${CustomersTable.name} COLLATE NOCASE
    ''', whereArgs);

    return rows.map((row) {
      return CustomerListItem(
        customer: CustomerModel.fromMap(row),
        totalPurchaseAmount: (row['total_purchase_amount'] as num).toDouble(),
      );
    }).toList();
  }

  Future<double> getTotalPurchaseAmount(int customerId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(${SalesTable.totalAmount}), 0) AS total FROM ${SalesTable.table} '
      'WHERE ${SalesTable.customerId} = ?',
      [customerId],
    );
    return (rows.first['total'] as num).toDouble();
  }

  Future<List<SaleModel>> getPurchaseHistory(int customerId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      SalesTable.table,
      where: '${SalesTable.customerId} = ?',
      whereArgs: [customerId],
      orderBy: '${SalesTable.saleDate} DESC, ${SalesTable.id} DESC',
    );
    return rows.map(SaleModel.fromMap).toList();
  }
}
