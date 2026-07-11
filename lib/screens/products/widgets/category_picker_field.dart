import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/product_provider.dart';

/// Tappable field that opens a searchable bottom sheet of categories, with
/// an inline "+ Add '{query}'" option so a shop owner never has to leave
/// the Add Product form to create a new category.
class CategoryPickerField extends StatelessWidget {
  final int? selectedCategoryId;
  final ValueChanged<int?> onChanged;

  const CategoryPickerField({
    super.key,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    final provider = context.read<ProductProvider>();
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _CategoryPickerSheet(provider: provider),
    );

    // Dismissing the sheet (tap outside / back button) returns null and
    // should leave the current selection untouched. Explicitly choosing
    // "Uncategorized" returns [_uncategorizedSentinel] instead, so it can
    // be told apart from "nothing chosen".
    if (result == null) return;
    onChanged(result == _uncategorizedSentinel ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final category = provider.categoryFor(selectedCategoryId);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(labelText: 'products.category'.tr()),
        child: Text(category?.name ?? 'products.uncategorized'.tr()),
      ),
    );
  }
}

/// Category ids are always positive autoincrement values, so a negative
/// sentinel can never collide with a real id.
const int _uncategorizedSentinel = -1;

class _CategoryPickerSheet extends StatefulWidget {
  final ProductProvider provider;

  const _CategoryPickerSheet({required this.provider});

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createAndSelect(BuildContext context) async {
    final created = await widget.provider.createCategory(_query.trim());
    if (!context.mounted) return;
    Navigator.of(context).pop(created.id);
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.provider.categories
        .where((c) => c.name.toLowerCase().contains(_query.trim().toLowerCase()))
        .toList();
    final exactMatchExists = widget.provider.categories
        .any((c) => c.name.toLowerCase() == _query.trim().toLowerCase());

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
            Text('products.category'.tr(), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'common.search'.tr(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Icons.remove_circle_outline),
                    title: Text('products.uncategorized'.tr()),
                    onTap: () => Navigator.of(context).pop(_uncategorizedSentinel),
                  ),
                  for (final category in categories)
                    ListTile(
                      title: Text(category.name),
                      onTap: () => Navigator.of(context).pop(category.id),
                    ),
                  if (_query.trim().isNotEmpty && !exactMatchExists)
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: Text('products.add_new_category'
                          .tr(namedArgs: {'name': _query.trim()})),
                      onTap: () => _createAndSelect(context),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
