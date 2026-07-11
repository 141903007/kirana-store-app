import '../database/db_tables.dart';
import 'product_unit.dart';

class ProductModel {
  final int? id;
  final String name;
  final int? categoryId;
  final String? barcode;
  final String? sku;
  final ProductUnit baseUnit;

  /// Cost of one unit of [baseUnit]. Auto-updated by the Purchase module.
  final double purchasePrice;
  final double? gstPercent;

  /// All stock quantities below are expressed in [baseUnit].
  final double openingStock;
  final double currentStock;
  final double minStockAlert;

  final bool isFavorite;

  /// Soft-delete flag — products are never hard-deleted once referenced by
  /// a purchase/sale, so historical invoices keep resolving their name.
  final bool isActive;

  final String createdAt;
  final String updatedAt;

  const ProductModel({
    this.id,
    required this.name,
    this.categoryId,
    this.barcode,
    this.sku,
    required this.baseUnit,
    required this.purchasePrice,
    this.gstPercent,
    required this.openingStock,
    required this.currentStock,
    required this.minStockAlert,
    this.isFavorite = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOutOfStock => currentStock <= 0;
  bool get isLowStock => !isOutOfStock && currentStock <= minStockAlert;

  ProductModel copyWith({
    int? id,
    String? name,
    int? categoryId,
    String? barcode,
    String? sku,
    ProductUnit? baseUnit,
    double? purchasePrice,
    double? gstPercent,
    double? openingStock,
    double? currentStock,
    double? minStockAlert,
    bool? isFavorite,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      baseUnit: baseUnit ?? this.baseUnit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      gstPercent: gstPercent ?? this.gstPercent,
      openingStock: openingStock ?? this.openingStock,
      currentStock: currentStock ?? this.currentStock,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      isFavorite: isFavorite ?? this.isFavorite,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      ProductsTable.id: id,
      ProductsTable.name: name,
      ProductsTable.categoryId: categoryId,
      ProductsTable.barcode: barcode,
      ProductsTable.sku: sku,
      ProductsTable.baseUnit: baseUnit.dbValue,
      ProductsTable.purchasePrice: purchasePrice,
      ProductsTable.gstPercent: gstPercent,
      ProductsTable.openingStock: openingStock,
      ProductsTable.currentStock: currentStock,
      ProductsTable.minStockAlert: minStockAlert,
      ProductsTable.isFavorite: isFavorite ? 1 : 0,
      ProductsTable.isActive: isActive ? 1 : 0,
      ProductsTable.createdAt: createdAt,
      ProductsTable.updatedAt: updatedAt,
    };
  }

  factory ProductModel.fromMap(Map<String, Object?> map) {
    return ProductModel(
      id: map[ProductsTable.id] as int?,
      name: map[ProductsTable.name] as String,
      categoryId: map[ProductsTable.categoryId] as int?,
      barcode: map[ProductsTable.barcode] as String?,
      sku: map[ProductsTable.sku] as String?,
      baseUnit: ProductUnitX.fromDbValue(map[ProductsTable.baseUnit] as String),
      purchasePrice: (map[ProductsTable.purchasePrice] as num).toDouble(),
      gstPercent: (map[ProductsTable.gstPercent] as num?)?.toDouble(),
      openingStock: (map[ProductsTable.openingStock] as num).toDouble(),
      currentStock: (map[ProductsTable.currentStock] as num).toDouble(),
      minStockAlert: (map[ProductsTable.minStockAlert] as num).toDouble(),
      isFavorite: (map[ProductsTable.isFavorite] as int) == 1,
      isActive: (map[ProductsTable.isActive] as int) == 1,
      createdAt: map[ProductsTable.createdAt] as String,
      updatedAt: map[ProductsTable.updatedAt] as String,
    );
  }
}
