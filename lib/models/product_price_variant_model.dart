import '../database/db_tables.dart';

/// A sellable pricing option for a product (e.g. "1kg", "500g", "Box",
/// "Packet"). [quantityInBaseUnit] converts this variant to/from the
/// product's `base_unit`, which is what makes both multi-pricing and
/// box/packet pricing fall out of the same table.
class ProductPriceVariantModel {
  final int? id;
  final int productId;
  final String label;
  final double quantityInBaseUnit;
  final double sellingPrice;
  final bool isDefault;
  final bool isActive;
  final int sortOrder;

  const ProductPriceVariantModel({
    this.id,
    required this.productId,
    required this.label,
    required this.quantityInBaseUnit,
    required this.sellingPrice,
    this.isDefault = false,
    this.isActive = true,
    this.sortOrder = 0,
  });

  ProductPriceVariantModel copyWith({
    int? id,
    int? productId,
    String? label,
    double? quantityInBaseUnit,
    double? sellingPrice,
    bool? isDefault,
    bool? isActive,
    int? sortOrder,
  }) {
    return ProductPriceVariantModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      label: label ?? this.label,
      quantityInBaseUnit: quantityInBaseUnit ?? this.quantityInBaseUnit,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toMap() {
    return {
      ProductPriceVariantsTable.id: id,
      ProductPriceVariantsTable.productId: productId,
      ProductPriceVariantsTable.label: label,
      ProductPriceVariantsTable.quantityInBaseUnit: quantityInBaseUnit,
      ProductPriceVariantsTable.sellingPrice: sellingPrice,
      ProductPriceVariantsTable.isDefault: isDefault ? 1 : 0,
      ProductPriceVariantsTable.isActive: isActive ? 1 : 0,
      ProductPriceVariantsTable.sortOrder: sortOrder,
    };
  }

  factory ProductPriceVariantModel.fromMap(Map<String, Object?> map) {
    return ProductPriceVariantModel(
      id: map[ProductPriceVariantsTable.id] as int?,
      productId: map[ProductPriceVariantsTable.productId] as int,
      label: map[ProductPriceVariantsTable.label] as String,
      quantityInBaseUnit:
          (map[ProductPriceVariantsTable.quantityInBaseUnit] as num).toDouble(),
      sellingPrice: (map[ProductPriceVariantsTable.sellingPrice] as num).toDouble(),
      isDefault: (map[ProductPriceVariantsTable.isDefault] as int) == 1,
      isActive: (map[ProductPriceVariantsTable.isActive] as int) == 1,
      sortOrder: map[ProductPriceVariantsTable.sortOrder] as int,
    );
  }
}
