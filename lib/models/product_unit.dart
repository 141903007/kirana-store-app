/// Units a product's stock/pricing can be expressed in.
///
/// Stored in the database as [name] (e.g. `'kg'`, `'packet'`) rather than an
/// integer index, so the schema stays readable and safe to reorder.
enum ProductUnit { kg, gram, liter, ml, piece, packet, box, dozen }

extension ProductUnitX on ProductUnit {
  String get dbValue => name;

  /// Short label shown in dropdowns and price-variant editors.
  String get displayLabel {
    switch (this) {
      case ProductUnit.kg:
        return 'Kg';
      case ProductUnit.gram:
        return 'Gram';
      case ProductUnit.liter:
        return 'Liter';
      case ProductUnit.ml:
        return 'ML';
      case ProductUnit.piece:
        return 'Piece';
      case ProductUnit.packet:
        return 'Packet';
      case ProductUnit.box:
        return 'Box';
      case ProductUnit.dozen:
        return 'Dozen';
    }
  }

  static ProductUnit fromDbValue(String value) {
    return ProductUnit.values.firstWhere(
      (unit) => unit.dbValue == value,
      orElse: () => ProductUnit.piece,
    );
  }
}
