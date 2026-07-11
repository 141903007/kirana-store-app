import '../database/db_tables.dart';

/// A single product line within a [SaleModel].
///
/// Everything here is a snapshot at sale time (label, prices, conversion
/// factor, GST%) so a later edit to the product's pricing can never alter
/// what was printed on a past invoice, and profit stays historically
/// accurate even if [ProductModel.purchasePrice] changes afterwards.
class SaleItemModel {
  final int? id;
  final int saleId;
  final int productId;
  final String variantLabel;
  final double quantity;
  final double conversionFactor;
  final double unitSellingPrice;
  final double unitPurchasePrice;
  final double gstPercent;
  final double lineTotal;
  final double lineProfit;

  const SaleItemModel({
    this.id,
    required this.saleId,
    required this.productId,
    required this.variantLabel,
    required this.quantity,
    required this.conversionFactor,
    required this.unitSellingPrice,
    required this.unitPurchasePrice,
    this.gstPercent = 0,
    required this.lineTotal,
    required this.lineProfit,
  });

  Map<String, Object?> toMap() {
    return {
      SaleItemsTable.id: id,
      SaleItemsTable.saleId: saleId,
      SaleItemsTable.productId: productId,
      SaleItemsTable.variantLabel: variantLabel,
      SaleItemsTable.quantity: quantity,
      SaleItemsTable.conversionFactor: conversionFactor,
      SaleItemsTable.unitSellingPrice: unitSellingPrice,
      SaleItemsTable.unitPurchasePrice: unitPurchasePrice,
      SaleItemsTable.gstPercent: gstPercent,
      SaleItemsTable.lineTotal: lineTotal,
      SaleItemsTable.lineProfit: lineProfit,
    };
  }

  factory SaleItemModel.fromMap(Map<String, Object?> map) {
    return SaleItemModel(
      id: map[SaleItemsTable.id] as int?,
      saleId: map[SaleItemsTable.saleId] as int,
      productId: map[SaleItemsTable.productId] as int,
      variantLabel: map[SaleItemsTable.variantLabel] as String,
      quantity: (map[SaleItemsTable.quantity] as num).toDouble(),
      conversionFactor: (map[SaleItemsTable.conversionFactor] as num).toDouble(),
      unitSellingPrice: (map[SaleItemsTable.unitSellingPrice] as num).toDouble(),
      unitPurchasePrice: (map[SaleItemsTable.unitPurchasePrice] as num).toDouble(),
      gstPercent: (map[SaleItemsTable.gstPercent] as num).toDouble(),
      lineTotal: (map[SaleItemsTable.lineTotal] as num).toDouble(),
      lineProfit: (map[SaleItemsTable.lineProfit] as num).toDouble(),
    );
  }
}
