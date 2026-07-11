import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../models/product_unit.dart';
import '../../../repository/product_repository.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/stock_badge.dart';

class ProductListTile extends StatelessWidget {
  final ProductListItem item;
  final String? categoryName;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const ProductListTile({
    super.key,
    required this.item,
    required this.categoryName,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final colorScheme = Theme.of(context).colorScheme;

    final StockBadgeLevel level;
    final String badgeLabel;
    if (product.isOutOfStock) {
      level = StockBadgeLevel.outOfStock;
      badgeLabel = 'dashboard.out_of_stock_items'.tr();
    } else if (product.isLowStock) {
      level = StockBadgeLevel.low;
      badgeLabel = '${product.currentStock.toStringAsFixed(0)} ${product.baseUnit.displayLabel}';
    } else {
      level = StockBadgeLevel.normal;
      badgeLabel = '${product.currentStock.toStringAsFixed(0)} ${product.baseUnit.displayLabel}';
    }

    final subtitleParts = <String>[categoryName ?? 'products.uncategorized'.tr()];
    if (item.defaultVariantLabel != null) {
      subtitleParts.add(
        '${item.defaultVariantLabel} — ${Formatters.currency(item.defaultVariantPrice ?? 0)}',
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
            style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitleParts.join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StockBadge(level: level, label: badgeLabel),
            IconButton(
              icon: Icon(
                product.isFavorite ? Icons.star : Icons.star_border,
                color: product.isFavorite ? Colors.amber.shade700 : null,
              ),
              onPressed: onToggleFavorite,
            ),
          ],
        ),
      ),
    );
  }
}
