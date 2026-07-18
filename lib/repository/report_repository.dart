import '../database/app_database.dart';
import '../database/db_tables.dart';
import '../models/dashboard_summary.dart';
import '../models/sale_model.dart';

/// A sale plus its customer's name (or null for a walk-in sale), for the
/// Sales Report — avoids an N+1 customer lookup per row.
class SaleReportItem {
  final SaleModel sale;
  final String? customerName;

  const SaleReportItem({required this.sale, this.customerName});
}

class ProfitLossSummary {
  final double profit;
  final double loss;

  const ProfitLossSummary({required this.profit, required this.loss});

  double get netProfit => profit - loss;
}

class DailyProfitPoint {
  final DateTime date;
  final double profit;
  final double loss;

  const DailyProfitPoint({required this.date, required this.profit, required this.loss});
}

class ProductProfitItem {
  final String productName;
  final double profit;

  const ProductProfitItem({required this.productName, required this.profit});
}

class BillProfitItem {
  final String invoiceNumber;
  final String saleDate;
  final double profit;

  const BillProfitItem({required this.invoiceNumber, required this.saleDate, required this.profit});
}

/// Shared by Dashboard's "today" stats and Reports' arbitrary date ranges —
/// one SQL implementation for both rather than duplicating queries.
class ReportRepository {
  Future<DashboardSummary> getTodaySummary() async {
    final db = await AppDatabase.instance.database;

    final salesToday = await db.rawQuery('''
      SELECT ${SalesTable.totalAmount}, ${SalesTable.totalProfit}
      FROM ${SalesTable.table}
      WHERE date(${SalesTable.saleDate}) = date('now', 'localtime')
    ''');

    double todaySales = 0;
    double todayProfit = 0;
    double todayLoss = 0;
    for (final row in salesToday) {
      todaySales += (row[SalesTable.totalAmount] as num).toDouble();
      final profit = (row[SalesTable.totalProfit] as num).toDouble();
      if (profit >= 0) {
        todayProfit += profit;
      } else {
        todayLoss += -profit;
      }
    }

    final purchaseRows = await db.rawQuery('''
      SELECT COALESCE(SUM(${PurchasesTable.totalAmount}), 0) AS total
      FROM ${PurchasesTable.table}
      WHERE date(${PurchasesTable.purchaseDate}) = date('now', 'localtime')
    ''');
    final todayPurchase = (purchaseRows.first['total'] as num).toDouble();

    final stockValueRows = await db.rawQuery('''
      SELECT COALESCE(SUM(${ProductsTable.currentStock} * ${ProductsTable.purchasePrice}), 0) AS value
      FROM ${ProductsTable.table}
      WHERE ${ProductsTable.isActive} = 1
    ''');
    final stockValue = (stockValueRows.first['value'] as num).toDouble();

    final lowStockRows = await db.rawQuery('''
      SELECT COUNT(*) AS count FROM ${ProductsTable.table}
      WHERE ${ProductsTable.isActive} = 1
        AND ${ProductsTable.currentStock} > 0
        AND ${ProductsTable.currentStock} <= ${ProductsTable.minStockAlert}
    ''');
    final lowStockCount = (lowStockRows.first['count'] as num).toInt();

    final outOfStockRows = await db.rawQuery('''
      SELECT COUNT(*) AS count FROM ${ProductsTable.table}
      WHERE ${ProductsTable.isActive} = 1 AND ${ProductsTable.currentStock} <= 0
    ''');
    final outOfStockCount = (outOfStockRows.first['count'] as num).toInt();

    final totalProductsRows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${ProductsTable.table} WHERE ${ProductsTable.isActive} = 1',
    );
    final totalProducts = (totalProductsRows.first['count'] as num).toInt();

    final totalCustomersRows =
        await db.rawQuery('SELECT COUNT(*) AS count FROM ${CustomersTable.table}');
    final totalCustomers = (totalCustomersRows.first['count'] as num).toInt();

    return DashboardSummary(
      todaySales: todaySales,
      todayPurchase: todayPurchase,
      todayProfit: todayProfit,
      todayLoss: todayLoss,
      stockValue: stockValue,
      lowStockCount: lowStockCount,
      outOfStockCount: outOfStockCount,
      totalProducts: totalProducts,
      totalCustomers: totalCustomers,
    );
  }

  /// [from]/[to] are compared by date only (time-of-day is ignored), and
  /// the range is inclusive on both ends.
  Future<ProfitLossSummary> getProfitLossSummary(DateTime from, DateTime to) async {
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN ${SalesTable.totalProfit} >= 0 THEN ${SalesTable.totalProfit} ELSE 0 END), 0) AS profit,
        COALESCE(SUM(CASE WHEN ${SalesTable.totalProfit} < 0 THEN -${SalesTable.totalProfit} ELSE 0 END), 0) AS loss
      FROM ${SalesTable.table}
      WHERE date(${SalesTable.saleDate}) BETWEEN date(?) AND date(?)
    ''', [from.toIso8601String(), to.toIso8601String()]);

    return ProfitLossSummary(
      profit: (rows.first['profit'] as num).toDouble(),
      loss: (rows.first['loss'] as num).toDouble(),
    );
  }

  Future<List<DailyProfitPoint>> getDailyProfitTrend(DateTime from, DateTime to) async {
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery('''
      SELECT date(${SalesTable.saleDate}) AS day,
        COALESCE(SUM(CASE WHEN ${SalesTable.totalProfit} >= 0 THEN ${SalesTable.totalProfit} ELSE 0 END), 0) AS profit,
        COALESCE(SUM(CASE WHEN ${SalesTable.totalProfit} < 0 THEN -${SalesTable.totalProfit} ELSE 0 END), 0) AS loss
      FROM ${SalesTable.table}
      WHERE date(${SalesTable.saleDate}) BETWEEN date(?) AND date(?)
      GROUP BY day
      ORDER BY day
    ''', [from.toIso8601String(), to.toIso8601String()]);

    return rows.map((row) {
      return DailyProfitPoint(
        date: DateTime.parse(row['day'] as String),
        profit: (row['profit'] as num).toDouble(),
        loss: (row['loss'] as num).toDouble(),
      );
    }).toList();
  }

  Future<List<ProductProfitItem>> getProfitPerProduct(DateTime from, DateTime to) async {
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery('''
      SELECT p.${ProductsTable.name} AS product_name, SUM(si.${SaleItemsTable.lineProfit}) AS profit
      FROM ${SaleItemsTable.table} si
      JOIN ${SalesTable.table} s ON s.${SalesTable.id} = si.${SaleItemsTable.saleId}
      JOIN ${ProductsTable.table} p ON p.${ProductsTable.id} = si.${SaleItemsTable.productId}
      WHERE date(s.${SalesTable.saleDate}) BETWEEN date(?) AND date(?)
      GROUP BY si.${SaleItemsTable.productId}
      ORDER BY profit DESC
    ''', [from.toIso8601String(), to.toIso8601String()]);

    return rows.map((row) {
      return ProductProfitItem(
        productName: row['product_name'] as String,
        profit: (row['profit'] as num).toDouble(),
      );
    }).toList();
  }

  Future<List<SaleReportItem>> getSalesForRange(DateTime from, DateTime to) async {
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery('''
      SELECT s.*, c.${CustomersTable.name} AS customer_name
      FROM ${SalesTable.table} s
      LEFT JOIN ${CustomersTable.table} c ON c.${CustomersTable.id} = s.${SalesTable.customerId}
      WHERE date(s.${SalesTable.saleDate}) BETWEEN date(?) AND date(?)
      ORDER BY s.${SalesTable.saleDate} DESC, s.${SalesTable.id} DESC
    ''', [from.toIso8601String(), to.toIso8601String()]);

    return rows.map((row) {
      return SaleReportItem(
        sale: SaleModel.fromMap(row),
        customerName: row['customer_name'] as String?,
      );
    }).toList();
  }

  Future<List<BillProfitItem>> getProfitPerBill(DateTime from, DateTime to) async {
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery('''
      SELECT ${SalesTable.invoiceNumber}, ${SalesTable.saleDate}, ${SalesTable.totalProfit}
      FROM ${SalesTable.table}
      WHERE date(${SalesTable.saleDate}) BETWEEN date(?) AND date(?)
      ORDER BY ${SalesTable.saleDate} DESC, ${SalesTable.id} DESC
    ''', [from.toIso8601String(), to.toIso8601String()]);

    return rows.map((row) {
      return BillProfitItem(
        invoiceNumber: row[SalesTable.invoiceNumber] as String,
        saleDate: row[SalesTable.saleDate] as String,
        profit: (row[SalesTable.totalProfit] as num).toDouble(),
      );
    }).toList();
  }
}
