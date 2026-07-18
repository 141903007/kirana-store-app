import '../database/app_database.dart';
import '../database/db_tables.dart';
import '../models/sale_item_model.dart';
import '../models/sale_model.dart';
import '../services/profit_calculation_service.dart';
import 'product_repository.dart';
import 'settings_repository.dart';

/// One cart line's data, as needed to write a `sale_items` row. Plain input
/// struct — the cart itself (`CartLine`) lives in the UI/provider layer;
/// this repository doesn't depend on it.
class SaleItemInput {
  final int productId;
  final String variantLabel;
  final double conversionFactor;
  final double quantity;
  final double unitSellingPrice;
  final double unitPurchasePrice;
  final double gstPercent;

  const SaleItemInput({
    required this.productId,
    required this.variantLabel,
    required this.conversionFactor,
    required this.quantity,
    required this.unitSellingPrice,
    required this.unitPurchasePrice,
    this.gstPercent = 0,
  });
}

class SaleListItem {
  final SaleModel sale;
  final int itemCount;

  const SaleListItem({required this.sale, required this.itemCount});
}

class SaleItemDetail {
  final SaleItemModel item;
  final String productName;

  const SaleItemDetail({required this.item, required this.productName});
}

class SaleRepository {
  SaleRepository({
    ProductRepository? productRepository,
    SettingsRepository? settingsRepository,
  })  : _productRepository = productRepository ?? ProductRepository(),
        _settingsRepository = settingsRepository ?? SettingsRepository();

  final ProductRepository _productRepository;
  final SettingsRepository _settingsRepository;

  /// Inserts the sale header and every line item in one transaction:
  /// atomically takes the next invoice number, recomputes every total
  /// server-side from [items] (never trusts a pre-computed total), snapshots
  /// per-line profit, and decreases stock for each product.
  Future<SaleModel> createSale({
    required List<SaleItemInput> items,
    int? customerId,
    double discountPercent = 0,
    required String saleDate,
  }) async {
    final db = await AppDatabase.instance.database;

    return db.transaction<SaleModel>((txn) async {
      final invoiceNumber = await _settingsRepository.takeNextInvoiceNumber(executor: txn);

      double subtotal = 0;
      double discountAmount = 0;
      double gstAmount = 0;
      double totalAmount = 0;
      double totalProfit = 0;

      final lineData = <Map<String, Object?>>[];

      for (final item in items) {
        final lineSubtotal = item.quantity * item.unitSellingPrice;
        final lineDiscount = lineSubtotal * discountPercent / 100;
        final lineTaxable = lineSubtotal - lineDiscount;
        final lineGst = lineTaxable * item.gstPercent / 100;
        final lineTotal = lineTaxable + lineGst;
        final lineProfit = ProfitCalculationService.lineProfit(
          lineTaxable: lineTaxable,
          quantity: item.quantity,
          conversionFactor: item.conversionFactor,
          unitPurchasePrice: item.unitPurchasePrice,
        );

        subtotal += lineSubtotal;
        discountAmount += lineDiscount;
        gstAmount += lineGst;
        totalAmount += lineTotal;
        totalProfit += lineProfit;

        lineData.add({
          'item': item,
          'lineTotal': lineTotal,
          'lineProfit': lineProfit,
        });
      }

      final now = DateTime.now().toIso8601String();
      final saleId = await txn.insert(SalesTable.table, {
        SalesTable.invoiceNumber: invoiceNumber,
        SalesTable.customerId: customerId,
        SalesTable.saleDate: saleDate,
        SalesTable.subtotal: subtotal,
        SalesTable.discountAmount: discountAmount,
        SalesTable.gstAmount: gstAmount,
        SalesTable.totalAmount: totalAmount,
        SalesTable.totalProfit: totalProfit,
        SalesTable.createdAt: now,
      });

      for (final data in lineData) {
        final item = data['item'] as SaleItemInput;
        await txn.insert(SaleItemsTable.table, {
          SaleItemsTable.saleId: saleId,
          SaleItemsTable.productId: item.productId,
          SaleItemsTable.variantLabel: item.variantLabel,
          SaleItemsTable.quantity: item.quantity,
          SaleItemsTable.conversionFactor: item.conversionFactor,
          SaleItemsTable.unitSellingPrice: item.unitSellingPrice,
          SaleItemsTable.unitPurchasePrice: item.unitPurchasePrice,
          SaleItemsTable.gstPercent: item.gstPercent,
          SaleItemsTable.lineTotal: data['lineTotal'],
          SaleItemsTable.lineProfit: data['lineProfit'],
        });

        await _productRepository.adjustStock(
          item.productId,
          -(item.quantity * item.conversionFactor),
          StockChangeType.sale,
          referenceType: SalesTable.table,
          referenceId: saleId,
          notes: 'Sale $invoiceNumber',
          executor: txn,
        );
      }

      return SaleModel(
        id: saleId,
        invoiceNumber: invoiceNumber,
        customerId: customerId,
        saleDate: saleDate,
        subtotal: subtotal,
        discountAmount: discountAmount,
        gstAmount: gstAmount,
        totalAmount: totalAmount,
        totalProfit: totalProfit,
        createdAt: now,
      );
    });
  }

  Future<List<SaleListItem>> getAll() async {
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery('''
      SELECT s.*, COUNT(i.${SaleItemsTable.id}) AS item_count
      FROM ${SalesTable.table} s
      LEFT JOIN ${SaleItemsTable.table} i ON i.${SaleItemsTable.saleId} = s.${SalesTable.id}
      GROUP BY s.${SalesTable.id}
      ORDER BY s.${SalesTable.saleDate} DESC, s.${SalesTable.id} DESC
    ''');

    return rows.map((row) {
      return SaleListItem(
        sale: SaleModel.fromMap(row),
        itemCount: (row['item_count'] as num).toInt(),
      );
    }).toList();
  }

  Future<List<SaleItemDetail>> getItemsForSale(int saleId) async {
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery('''
      SELECT i.*, p.${ProductsTable.name} AS product_name
      FROM ${SaleItemsTable.table} i
      JOIN ${ProductsTable.table} p ON p.${ProductsTable.id} = i.${SaleItemsTable.productId}
      WHERE i.${SaleItemsTable.saleId} = ?
      ORDER BY i.${SaleItemsTable.id}
    ''', [saleId]);

    return rows.map((row) {
      return SaleItemDetail(
        item: SaleItemModel.fromMap(row),
        productName: row['product_name'] as String,
      );
    }).toList();
  }
}
