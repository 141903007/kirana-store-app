import '../database/db_tables.dart';

class SaleModel {
  final int? id;

  /// Our own auto-generated number, e.g. "INV-000123".
  final String invoiceNumber;

  /// Null means a walk-in/cash sale with no linked customer.
  final int? customerId;
  final String saleDate;
  final double subtotal;
  final double discountAmount;
  final double gstAmount;
  final double totalAmount;

  /// Cached rollup of this sale's line profits — recomputable from
  /// [SaleItemModel.lineProfit], kept here only to make P&L queries fast.
  final double totalProfit;
  final String createdAt;

  const SaleModel({
    this.id,
    required this.invoiceNumber,
    this.customerId,
    required this.saleDate,
    required this.subtotal,
    this.discountAmount = 0,
    this.gstAmount = 0,
    required this.totalAmount,
    this.totalProfit = 0,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      SalesTable.id: id,
      SalesTable.invoiceNumber: invoiceNumber,
      SalesTable.customerId: customerId,
      SalesTable.saleDate: saleDate,
      SalesTable.subtotal: subtotal,
      SalesTable.discountAmount: discountAmount,
      SalesTable.gstAmount: gstAmount,
      SalesTable.totalAmount: totalAmount,
      SalesTable.totalProfit: totalProfit,
      SalesTable.createdAt: createdAt,
    };
  }

  factory SaleModel.fromMap(Map<String, Object?> map) {
    return SaleModel(
      id: map[SalesTable.id] as int?,
      invoiceNumber: map[SalesTable.invoiceNumber] as String,
      customerId: map[SalesTable.customerId] as int?,
      saleDate: map[SalesTable.saleDate] as String,
      subtotal: (map[SalesTable.subtotal] as num).toDouble(),
      discountAmount: (map[SalesTable.discountAmount] as num).toDouble(),
      gstAmount: (map[SalesTable.gstAmount] as num).toDouble(),
      totalAmount: (map[SalesTable.totalAmount] as num).toDouble(),
      totalProfit: (map[SalesTable.totalProfit] as num).toDouble(),
      createdAt: map[SalesTable.createdAt] as String,
    );
  }
}
