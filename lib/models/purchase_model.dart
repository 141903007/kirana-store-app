import '../database/db_tables.dart';

class PurchaseModel {
  final int? id;
  final String dealerName;

  /// The dealer's own invoice reference (free text) — not auto-generated.
  final String? invoiceNumber;
  final String purchaseDate;
  final double totalAmount;
  final String? remarks;
  final String createdAt;

  const PurchaseModel({
    this.id,
    required this.dealerName,
    this.invoiceNumber,
    required this.purchaseDate,
    required this.totalAmount,
    this.remarks,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      PurchasesTable.id: id,
      PurchasesTable.dealerName: dealerName,
      PurchasesTable.invoiceNumber: invoiceNumber,
      PurchasesTable.purchaseDate: purchaseDate,
      PurchasesTable.totalAmount: totalAmount,
      PurchasesTable.remarks: remarks,
      PurchasesTable.createdAt: createdAt,
    };
  }

  factory PurchaseModel.fromMap(Map<String, Object?> map) {
    return PurchaseModel(
      id: map[PurchasesTable.id] as int?,
      dealerName: map[PurchasesTable.dealerName] as String,
      invoiceNumber: map[PurchasesTable.invoiceNumber] as String?,
      purchaseDate: map[PurchasesTable.purchaseDate] as String,
      totalAmount: (map[PurchasesTable.totalAmount] as num).toDouble(),
      remarks: map[PurchasesTable.remarks] as String?,
      createdAt: map[PurchasesTable.createdAt] as String,
    );
  }
}
