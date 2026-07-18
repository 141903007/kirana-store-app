import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/db_tables.dart';
import '../models/product_model.dart';
import '../models/product_price_variant_model.dart';

/// A product row plus its default price variant, flattened for the list
/// screen so it doesn't need one query per product to show a price.
class ProductListItem {
  final ProductModel product;
  final String? defaultVariantLabel;
  final double? defaultVariantPrice;

  const ProductListItem({
    required this.product,
    this.defaultVariantLabel,
    this.defaultVariantPrice,
  });
}

class ProductRepository {
  Future<int> insertProduct(ProductModel product) async {
    final db = await AppDatabase.instance.database;
    final map = product.toMap()..remove(ProductsTable.id);
    return db.insert(ProductsTable.table, map);
  }

  /// Never touches current_stock/opening_stock — those only change via
  /// [adjustStock], so the stock ledger stays authoritative.
  Future<void> updateProduct(ProductModel product) async {
    final db = await AppDatabase.instance.database;
    final map = product.toMap()
      ..remove(ProductsTable.id)
      ..remove(ProductsTable.currentStock)
      ..remove(ProductsTable.openingStock);
    await db.update(
      ProductsTable.table,
      map,
      where: '${ProductsTable.id} = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> setActive(int id, bool isActive) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      ProductsTable.table,
      {
        ProductsTable.isActive: isActive ? 1 : 0,
        ProductsTable.updatedAt: DateTime.now().toIso8601String(),
      },
      where: '${ProductsTable.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      ProductsTable.table,
      {ProductsTable.isFavorite: isFavorite ? 1 : 0},
      where: '${ProductsTable.id} = ?',
      whereArgs: [id],
    );
  }

  Future<ProductModel?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      ProductsTable.table,
      where: '${ProductsTable.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ProductModel.fromMap(rows.first);
  }

  Future<bool> isBarcodeTaken(String barcode, {int? excludingProductId}) async {
    final db = await AppDatabase.instance.database;
    final where = excludingProductId == null
        ? '${ProductsTable.barcode} = ?'
        : '${ProductsTable.barcode} = ? AND ${ProductsTable.id} != ?';
    final args = excludingProductId == null
        ? [barcode]
        : [barcode, excludingProductId];

    final rows = await db.query(ProductsTable.table, where: where, whereArgs: args, limit: 1);
    return rows.isNotEmpty;
  }

  Future<List<ProductPriceVariantModel>> getVariants(int productId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      ProductPriceVariantsTable.table,
      where: '${ProductPriceVariantsTable.productId} = ?',
      whereArgs: [productId],
      orderBy: ProductPriceVariantsTable.sortOrder,
    );
    return rows.map(ProductPriceVariantModel.fromMap).toList();
  }

  /// Replaces every variant row for [productId] with [variants] in one
  /// transaction. If none of the incoming variants is marked default, the
  /// first one is forced to default so the list/billing screens always have
  /// exactly one default price to show.
  Future<void> replaceVariants(
    int productId,
    List<ProductPriceVariantModel> variants,
  ) async {
    final db = await AppDatabase.instance.database;
    final hasDefault = variants.any((variant) => variant.isDefault);

    await db.transaction((txn) async {
      await txn.delete(
        ProductPriceVariantsTable.table,
        where: '${ProductPriceVariantsTable.productId} = ?',
        whereArgs: [productId],
      );

      for (var i = 0; i < variants.length; i++) {
        final variant = variants[i];
        final map = variant.toMap()
          ..remove(ProductPriceVariantsTable.id)
          ..[ProductPriceVariantsTable.productId] = productId
          ..[ProductPriceVariantsTable.sortOrder] = i
          ..[ProductPriceVariantsTable.isDefault] =
              (!hasDefault && i == 0) || variant.isDefault ? 1 : 0;
        await txn.insert(ProductPriceVariantsTable.table, map);
      }
    });
  }

  /// The single choke point for changing a product's stock. Every write
  /// (purchase, sale, manual correction) goes through here so
  /// stock_history stays the ledger of record and products.current_stock
  /// stays a derived rollup, never edited directly elsewhere.
  ///
  /// Pass [executor] (an in-progress `Transaction`) when the caller already
  /// holds a transaction on the same database — sqflite serializes
  /// transactions on one connection, so opening a second nested
  /// `db.transaction()` here would deadlock waiting for the outer one to
  /// finish.
  Future<void> adjustStock(
    int productId,
    double delta,
    String changeType, {
    String? referenceType,
    int? referenceId,
    String? notes,
    DatabaseExecutor? executor,
  }) async {
    Future<void> body(DatabaseExecutor db) async {
      final rows = await db.query(
        ProductsTable.table,
        columns: [ProductsTable.currentStock],
        where: '${ProductsTable.id} = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (rows.isEmpty) return;

      final currentStock = (rows.first[ProductsTable.currentStock] as num).toDouble();
      final resultingStock = currentStock + delta;
      final now = DateTime.now().toIso8601String();

      await db.update(
        ProductsTable.table,
        {ProductsTable.currentStock: resultingStock, ProductsTable.updatedAt: now},
        where: '${ProductsTable.id} = ?',
        whereArgs: [productId],
      );

      await db.insert(StockHistoryTable.table, {
        StockHistoryTable.productId: productId,
        StockHistoryTable.changeType: changeType,
        StockHistoryTable.quantityChange: delta,
        StockHistoryTable.resultingStock: resultingStock,
        StockHistoryTable.referenceType: referenceType,
        StockHistoryTable.referenceId: referenceId,
        StockHistoryTable.notes: notes,
        StockHistoryTable.createdAt: now,
      });
    }

    if (executor != null) return body(executor);
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) => body(txn));
  }

  /// One query with a LEFT JOIN to each product's default active variant,
  /// so the list screen gets a price to show without an N+1 query per row.
  Future<List<ProductListItem>> search({
    String? query,
    int? categoryId,
    bool lowStockOnly = false,
    bool outOfStockOnly = false,
    bool favoritesOnly = false,
    bool includeInactive = false,
  }) async {
    final db = await AppDatabase.instance.database;

    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (!includeInactive) {
      whereClauses.add('p.${ProductsTable.isActive} = 1');
    }
    if (query != null && query.trim().isNotEmpty) {
      final like = '%${query.trim()}%';
      whereClauses.add(
        '(p.${ProductsTable.name} LIKE ? OR p.${ProductsTable.barcode} LIKE ? OR p.${ProductsTable.sku} LIKE ?)',
      );
      whereArgs.addAll([like, like, like]);
    }
    if (categoryId != null) {
      whereClauses.add('p.${ProductsTable.categoryId} = ?');
      whereArgs.add(categoryId);
    }
    if (favoritesOnly) {
      whereClauses.add('p.${ProductsTable.isFavorite} = 1');
    }
    if (lowStockOnly && outOfStockOnly) {
      whereClauses.add(
        '(p.${ProductsTable.currentStock} <= 0 OR (p.${ProductsTable.currentStock} > 0 AND p.${ProductsTable.currentStock} <= p.${ProductsTable.minStockAlert}))',
      );
    } else if (lowStockOnly) {
      whereClauses.add(
        'p.${ProductsTable.currentStock} > 0 AND p.${ProductsTable.currentStock} <= p.${ProductsTable.minStockAlert}',
      );
    } else if (outOfStockOnly) {
      whereClauses.add('p.${ProductsTable.currentStock} <= 0');
    }

    final whereSql = whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    final rows = await db.rawQuery('''
      SELECT p.*, v.${ProductPriceVariantsTable.label} AS variant_label,
             v.${ProductPriceVariantsTable.sellingPrice} AS variant_price
      FROM ${ProductsTable.table} p
      LEFT JOIN ${ProductPriceVariantsTable.table} v
        ON v.${ProductPriceVariantsTable.productId} = p.${ProductsTable.id}
        AND v.${ProductPriceVariantsTable.isDefault} = 1
        AND v.${ProductPriceVariantsTable.isActive} = 1
      $whereSql
      ORDER BY p.${ProductsTable.name} COLLATE NOCASE
    ''', whereArgs);

    return rows.map((row) {
      return ProductListItem(
        product: ProductModel.fromMap(row),
        defaultVariantLabel: row['variant_label'] as String?,
        defaultVariantPrice: (row['variant_price'] as num?)?.toDouble(),
      );
    }).toList();
  }
}
