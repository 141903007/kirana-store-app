import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/product_provider.dart';

class ProductFilterBar extends StatelessWidget {
  const ProductFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _CategoryChip(provider: provider),
          const SizedBox(width: 8),
          FilterChip(
            label: Text('products.filter_low_stock'.tr()),
            selected: provider.lowStockOnly,
            onSelected: provider.setLowStockOnly,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text('products.filter_out_of_stock'.tr()),
            selected: provider.outOfStockOnly,
            onSelected: provider.setOutOfStockOnly,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text('products.filter_favorites'.tr()),
            selected: provider.favoritesOnly,
            onSelected: provider.setFavoritesOnly,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text('products.filter_show_archived'.tr()),
            selected: provider.includeInactive,
            onSelected: provider.setIncludeInactive,
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final ProductProvider provider;

  const _CategoryChip({required this.provider});

  Future<void> _pick(BuildContext context) async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text('products.filter_all_categories'.tr()),
              onTap: () => Navigator.of(sheetContext).pop(-1),
            ),
            for (final category in provider.categories)
              ListTile(
                title: Text(category.name),
                onTap: () => Navigator.of(sheetContext).pop(category.id),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    provider.setCategoryFilter(selected == -1 ? null : selected);
  }

  @override
  Widget build(BuildContext context) {
    final category = provider.categoryFor(provider.categoryFilterId);
    return FilterChip(
      label: Text(category?.name ?? 'products.category'.tr()),
      selected: provider.categoryFilterId != null,
      onSelected: (_) => _pick(context),
    );
  }
}
