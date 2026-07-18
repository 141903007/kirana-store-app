import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/product_unit.dart';
import '../repository/product_repository.dart';
import '../utils/formatters.dart';

/// Opens a searchable bottom sheet of products and returns the selected
/// [ProductListItem], or null if dismissed without a selection. Used by
/// both Purchase and Billing — [onSearch] is whichever repository/provider
/// method the caller already has (e.g. `ProductRepository.search`).
Future<ProductListItem?> showProductPickerSheet(
  BuildContext context, {
  required Future<List<ProductListItem>> Function(String query) onSearch,
}) {
  return showModalBottomSheet<ProductListItem>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ProductPickerSheet(onSearch: onSearch),
  );
}

class _ProductPickerSheet extends StatefulWidget {
  final Future<List<ProductListItem>> Function(String query) onSearch;

  const _ProductPickerSheet({required this.onSearch});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final _searchController = TextEditingController();
  List<ProductListItem> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    final results = await widget.onSearch(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('common.select_product'.tr(),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'common.search_product_hint'.tr(),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final item = _results[index];
                        final product = item.product;
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                            '${'common.current_stock_helper'.tr(namedArgs: {
                                  'stock': product.currentStock.toStringAsFixed(0),
                                  'unit': product.baseUnit.displayLabel,
                                })} • ${'common.last_purchase_price_helper'.tr(namedArgs: {
                                  'price': Formatters.currency(product.purchasePrice),
                                })}',
                          ),
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
