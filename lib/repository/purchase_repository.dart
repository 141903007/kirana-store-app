import '../database/app_database.dart';
import '../database/db_tables.dart';
import '../models/purchase_item_model.dart';
import '../models/purchase_model.dart';
import 'product_repository.dart';

/// A purchase row plus how many line items it has, flattened for the list
/// screen so it doesn't need one query per purchase.
class PurchaseListItem {
  final PurchaseModel purchase;
  final int itemCount;

  const PurchaseListItem({required this.purchase, required this.itemCount});
}

/// A purchase line item plus the product's name, for the detail screen.
class PurchaseItemDetail {
  final PurchaseItemModel item;
  final String productName;

  const PurchaseItemDetail({required this.item, required this.productName});
}

class PurchaseRepository {
  PurchaseRepository({ProductRepository? productRepository})
      : _productRepository = productRepository ?? ProductRepository();

  final ProductRepository _productRepository;

  /// Inserts the purchase header and every line item in one transaction,
  /// increasing stock and updating each product's purchase_price as it
  /// goes. [purchase.totalAmount] and each item's [PurchaseItemModel.lineTotal]
  /// are ignored — this repository recomputes both from quantity * price so
  /// they can never drift from what's actually stored.
  Future<int> createPurchase({
    required PurchaseModel purchase,
    required List<PurchaseItemModel> items,
  }) async {
    final db = await AppDatabase.instance.database;

    return db.transaction<int>((txn) async {
      final totalAmount = items.fold<double>(
        0,
        (sum, item) => sum + (item.quantity * item.pricePerUnit),
      );

      final purchaseMap = purchase.toMap()
        ..remove(PurchasesTable.id)
        ..[PurchasesTable.totalAmount] = totalAmount;
      final purchaseId = await txn.insert(PurchasesTable.table, purchaseMap);

      for (final item in items) {
        final lineTotal = item.quantity * item.pricePerUnit;
        final itemMap = item.toMap()
          ..remove(PurchaseItemsTable.id)
          ..[PurchaseItemsTable.purchaseId] = purchaseId
          ..[PurchaseItemsTable.lineTotal] = lineTotal;
        await txn.insert(PurchaseItemsTable.table, itemMap);

        await _productRepository.adjustStock(
          item.productId,
          item.quantity * item.conversionFactor,
          StockChangeType.purchase,
          referenceType: PurchasesTable.table,
          referenceId: purchaseId,
          notes: 'Purchase from ${purchase.dealerName}',
          executor: txn,
        );

        await txn.update(
          ProductsTable.table,
          {
            ProductsTable.purchasePrice: item.pricePerUnit / item.conversionFactor,
            ProductsTable.updatedAt: DateTime.now().toIso8601String(),
          },
          where: '${ProductsTable.id} = ?',
          whereArgs: [item.productId],
        );
      }

      return purchaseId;
    });
  }

  Future<List<PurchaseListItem>> getAll() async {
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery('''
      SELECT p.*, COUNT(i.${PurchaseItemsTable.id}) AS item_count
      FROM ${PurchasesTable.table} p
      LEFT JOIN ${PurchaseItemsTable.table} i
        ON i.${PurchaseItemsTable.purchaseId} = p.${PurchasesTable.id}
      GROUP BY p.${PurchasesTable.id}
      ORDER BY p.${PurchasesTable.purchaseDate} DESC, p.${PurchasesTable.id} DESC
    ''');

    return rows.map((row) {
      return PurchaseListItem(
        purchase: PurchaseModel.fromMap(row),
        itemCount: (row['item_count'] as num).toInt(),
      );
    }).toList();
  }

  Future<List<PurchaseItemDetail>> getItemsForPurchase(int purchaseId) async {
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery('''
      SELECT i.*, p.${ProductsTable.name} AS product_name
      FROM ${PurchaseItemsTable.table} i
      JOIN ${ProductsTable.table} p ON p.${ProductsTable.id} = i.${PurchaseItemsTable.productId}
      WHERE i.${PurchaseItemsTable.purchaseId} = ?
      ORDER BY i.${PurchaseItemsTable.id}
    ''', [purchaseId]);

    return rows.map((row) {
      return PurchaseItemDetail(
        item: PurchaseItemModel.fromMap(row),
        productName: row['product_name'] as String,
      );
    }).toList();
  }
}
