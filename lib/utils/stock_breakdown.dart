import '../models/product_model.dart';
import '../models/product_price_variant_model.dart';

/// Result of [computeStockBreakdown] — the pieces needed to render a string
/// like "1 Box of 10 + 2 Packets (12 Packets total)". Kept as plain data so
/// the caller (a widget) decides how to localize/format it, not this file.
class StockBreakdownInfo {
  final String boxLabel;
  final int boxCount;
  final double remainder;
  final double totalInBaseUnit;

  const StockBreakdownInfo({
    required this.boxLabel,
    required this.boxCount,
    required this.remainder,
    required this.totalInBaseUnit,
  });
}

/// Returns null when the product has no "box-like" variant (every variant
/// converts 1:1 to the base unit) — in that case the current stock is
/// already in the most natural unit and needs no breakdown.
StockBreakdownInfo? computeStockBreakdown(
  ProductModel product,
  List<ProductPriceVariantModel> variants,
) {
  final boxLikeVariants = variants
      .where((variant) => variant.isActive && variant.quantityInBaseUnit > 1)
      .toList()
    ..sort((a, b) => b.quantityInBaseUnit.compareTo(a.quantityInBaseUnit));

  if (boxLikeVariants.isEmpty) return null;

  final boxVariant = boxLikeVariants.first;
  final boxQty = boxVariant.quantityInBaseUnit;
  final boxCount = (product.currentStock / boxQty).floor();
  final remainder = product.currentStock - (boxCount * boxQty);

  return StockBreakdownInfo(
    boxLabel: boxVariant.label,
    boxCount: boxCount,
    remainder: remainder,
    totalInBaseUnit: product.currentStock,
  );
}
