import '../database/db_tables.dart';

/// One entry in the stock audit ledger — the source of truth for every
/// change to a product's stock. [ProductModel.currentStock] is a cached
/// rollup that must always equal the running sum of this table's
/// [quantityChange] for that product.
class StockHistoryModel {
  final int? id;
  final int productId;

  /// One of [StockChangeType].
  final String changeType;

  /// Signed quantity, in the product's base unit.
  final double quantityChange;

  /// Snapshot of the product's stock right after this change, for audit
  /// display without needing to replay the whole ledger.
  final double resultingStock;

  /// Informational pointer to the purchase/sale item that caused this
  /// change. Not a foreign key — a manual adjustment has no such row.
  final String? referenceType;
  final int? referenceId;
  final String? notes;
  final String createdAt;

  const StockHistoryModel({
    this.id,
    required this.productId,
    required this.changeType,
    required this.quantityChange,
    required this.resultingStock,
    this.referenceType,
    this.referenceId,
    this.notes,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      StockHistoryTable.id: id,
      StockHistoryTable.productId: productId,
      StockHistoryTable.changeType: changeType,
      StockHistoryTable.quantityChange: quantityChange,
      StockHistoryTable.resultingStock: resultingStock,
      StockHistoryTable.referenceType: referenceType,
      StockHistoryTable.referenceId: referenceId,
      StockHistoryTable.notes: notes,
      StockHistoryTable.createdAt: createdAt,
    };
  }

  factory StockHistoryModel.fromMap(Map<String, Object?> map) {
    return StockHistoryModel(
      id: map[StockHistoryTable.id] as int?,
      productId: map[StockHistoryTable.productId] as int,
      changeType: map[StockHistoryTable.changeType] as String,
      quantityChange: (map[StockHistoryTable.quantityChange] as num).toDouble(),
      resultingStock: (map[StockHistoryTable.resultingStock] as num).toDouble(),
      referenceType: map[StockHistoryTable.referenceType] as String?,
      referenceId: map[StockHistoryTable.referenceId] as int?,
      notes: map[StockHistoryTable.notes] as String?,
      createdAt: map[StockHistoryTable.createdAt] as String,
    );
  }
}
