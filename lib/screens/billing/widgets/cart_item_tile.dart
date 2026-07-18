import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../providers/sales_provider.dart';
import '../../../utils/formatters.dart';

class CartItemTile extends StatelessWidget {
  final CartLine line;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.line,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  Future<void> _editQuantity(BuildContext context) async {
    final controller = TextEditingController(text: line.quantity.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('billing.quantity'.tr()),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: line.variantLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              Navigator.of(dialogContext).pop(value);
            },
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
    if (result != null && result > 0) onQuantityChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _editQuantity(context),
        title: Text(line.productName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${line.quantity.toStringAsFixed(2)} × ${line.variantLabel} @ ${Formatters.currency(line.unitSellingPrice)}',
            ),
            if (line.exceedsStock)
              Text(
                'billing.insufficient_stock_warning'.tr(namedArgs: {
                  'stock': line.currentStock.toStringAsFixed(0),
                  'unit': line.baseUnitLabel,
                }),
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Formatters.currency(line.lineSubtotal),
              style:
                  Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: onRemove),
          ],
        ),
      ),
    );
  }
}
