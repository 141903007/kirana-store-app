import '../database/db_tables.dart';

/// A single product line within a [PurchaseModel].
///
/// [variantLabel] and [conversionFactor] are snapshots of the price variant
/// chosen at purchase time, not a live reference — so editing a product's
/// variants later never rewrites the numbers on a past purchase invoice.
class PurchaseItemModel {
  final int? id;
  final int purchaseId;
  final int productId;
  final String variantLabel;
  final double quantity;
  final double conversionFactor;
  final double pricePerUnit;
  final double lineTotal;

  const PurchaseItemModel({
    this.id,
    required this.purchaseId,
    required this.productId,
    required this.variantLabel,
    required this.quantity,
    required this.conversionFactor,
    required this.pricePerUnit,
    required this.lineTotal,
  });

  Map<String, Object?> toMap() {
    return {
      PurchaseItemsTable.id: id,
      PurchaseItemsTable.purchaseId: purchaseId,
      PurchaseItemsTable.productId: productId,
      PurchaseItemsTable.variantLabel: variantLabel,
      PurchaseItemsTable.quantity: quantity,
      PurchaseItemsTable.conversionFactor: conversionFactor,
      PurchaseItemsTable.pricePerUnit: pricePerUnit,
      PurchaseItemsTable.lineTotal: lineTotal,
    };
  }

  factory PurchaseItemModel.fromMap(Map<String, Object?> map) {
    return PurchaseItemModel(
      id: map[PurchaseItemsTable.id] as int?,
      purchaseId: map[PurchaseItemsTable.purchaseId] as int,
      productId: map[PurchaseItemsTable.productId] as int,
      variantLabel: map[PurchaseItemsTable.variantLabel] as String,
      quantity: (map[PurchaseItemsTable.quantity] as num).toDouble(),
      conversionFactor: (map[PurchaseItemsTable.conversionFactor] as num).toDouble(),
      pricePerUnit: (map[PurchaseItemsTable.pricePerUnit] as num).toDouble(),
      lineTotal: (map[PurchaseItemsTable.lineTotal] as num).toDouble(),
    );
  }
}
