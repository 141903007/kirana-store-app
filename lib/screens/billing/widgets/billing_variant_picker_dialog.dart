import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../models/product_model.dart';
import '../../../models/product_price_variant_model.dart';
import '../../../models/product_unit.dart';
import '../../../providers/sales_provider.dart';
import '../../../utils/validators.dart';

/// Shown right after a product is picked from the search sheet. Only
/// active price variants are offered (unlike Purchase, which also allows
/// the raw base unit) — a variant's `sellingPrice` is the only place a
/// retail price exists; the base unit itself has no selling price, only a
/// cost. Every product should already have >=1 default variant.
Future<CartLine?> showBillingVariantPicker(
  BuildContext context, {
  required ProductModel product,
  required List<ProductPriceVariantModel> variants,
}) {
  final activeVariants = variants.where((v) => v.isActive).toList();
  if (activeVariants.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('billing.no_price_set'.tr())));
    return Future.value(null);
  }

  return showDialog<CartLine>(
    context: context,
    builder: (_) => _BillingVariantDialog(product: product, variants: activeVariants),
  );
}

class _BillingVariantDialog extends StatefulWidget {
  final ProductModel product;
  final List<ProductPriceVariantModel> variants;

  const _BillingVariantDialog({required this.product, required this.variants});

  @override
  State<_BillingVariantDialog> createState() => _BillingVariantDialogState();
}

class _BillingVariantDialogState extends State<_BillingVariantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  late ProductPriceVariantModel _selectedVariant;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.variants.firstWhere(
      (v) => v.isDefault,
      orElse: () => widget.variants.first,
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final line = CartLine(
      productId: widget.product.id!,
      productName: widget.product.name,
      variantLabel: _selectedVariant.label,
      conversionFactor: _selectedVariant.quantityInBaseUnit,
      unitSellingPrice: _selectedVariant.sellingPrice,
      unitPurchasePrice: widget.product.purchasePrice,
      gstPercent: widget.product.gstPercent ?? 0,
      currentStock: widget.product.currentStock,
      baseUnitLabel: widget.product.baseUnit.displayLabel,
      quantity: double.parse(_quantityController.text.trim()),
    );
    Navigator.of(context).pop(line);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product.name),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ProductPriceVariantModel>(
              initialValue: _selectedVariant,
              decoration: InputDecoration(labelText: 'billing.select_variant'.tr()),
              items: [
                for (final variant in widget.variants)
                  DropdownMenuItem(value: variant, child: Text(variant.label)),
              ],
              onChanged: (variant) =>
                  setState(() => _selectedVariant = variant ?? _selectedVariant),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'billing.quantity'.tr()),
              validator: (value) => Validators.positiveNumber(
                value,
                'common.required_field'.tr(),
                'common.invalid_number'.tr(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr()),
        ),
        FilledButton(onPressed: _submit, child: Text('common.add'.tr())),
      ],
    );
  }
}
