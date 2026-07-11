import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../models/product_price_variant_model.dart';
import '../../../models/product_unit.dart';
import '../../../utils/formatters.dart';
import '../../../utils/validators.dart';

const _weightLikeUnits = {ProductUnit.kg, ProductUnit.gram, ProductUnit.liter, ProductUnit.ml};

/// The single UI for both "multi-pricing" (1kg/500g/250g/100g) and
/// "box pricing" (Box vs Packet) — they're the same underlying data
/// (a list of price variants), just described with different hint copy
/// depending on the product's base unit.
class PriceVariantEditor extends StatelessWidget {
  final List<ProductPriceVariantModel> variants;
  final ProductUnit baseUnit;
  final double purchasePricePerBaseUnit;
  final ValueChanged<List<ProductPriceVariantModel>> onChanged;

  const PriceVariantEditor({
    super.key,
    required this.variants,
    required this.baseUnit,
    required this.purchasePricePerBaseUnit,
    required this.onChanged,
  });

  bool get _isWeightLike => _weightLikeUnits.contains(baseUnit);

  Future<void> _openDialog(BuildContext context, {int? editIndex}) async {
    final result = await showDialog<ProductPriceVariantModel>(
      context: context,
      builder: (_) => _VariantDialog(
        baseUnit: baseUnit,
        initial: editIndex == null ? null : variants[editIndex],
      ),
    );
    if (result == null) return;

    final updated = [...variants];
    if (editIndex == null) {
      updated.add(result);
    } else {
      updated[editIndex] = result;
    }
    if (result.isDefault) {
      for (var i = 0; i < updated.length; i++) {
        if (i != (editIndex ?? updated.length - 1)) {
          updated[i] = updated[i].copyWith(isDefault: false);
        }
      }
    }
    onChanged(updated);
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('products.variant_delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final updated = [...variants]..removeAt(index);
    if (updated.isNotEmpty && !updated.any((v) => v.isDefault)) {
      updated[0] = updated[0].copyWith(isDefault: true);
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('products.selling_prices_title'.tr(),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          _isWeightLike
              ? 'products.selling_prices_hint_weight'.tr()
              : 'products.selling_prices_hint_box'.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < variants.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => _openDialog(context, editIndex: i),
              title: Row(
                children: [
                  Text(variants[i].label),
                  if (variants[i].isDefault) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('products.variant_default_badge'.tr()),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: colorScheme.primaryContainer,
                    ),
                  ],
                ],
              ),
              subtitle: variants[i].quantityInBaseUnit > 1
                  ? Text('products.variant_purchase_price_helper'.tr(namedArgs: {
                      'value': Formatters.currency(
                          purchasePricePerBaseUnit * variants[i].quantityInBaseUnit),
                      'label': variants[i].label,
                    }))
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.currency(variants[i].sellingPrice),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, i),
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => _openDialog(context),
          icon: const Icon(Icons.add),
          label: Text('products.add_price_option'.tr()),
        ),
      ],
    );
  }
}

class _VariantDialog extends StatefulWidget {
  final ProductUnit baseUnit;
  final ProductPriceVariantModel? initial;

  const _VariantDialog({required this.baseUnit, this.initial});

  @override
  State<_VariantDialog> createState() => _VariantDialogState();
}

class _VariantDialogState extends State<_VariantDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _labelController = TextEditingController(text: initial?.label ?? '');
    _quantityController =
        TextEditingController(text: initial == null ? '' : _trimZero(initial.quantityInBaseUnit));
    _priceController =
        TextEditingController(text: initial == null ? '' : _trimZero(initial.sellingPrice));
    _isDefault = initial?.isDefault ?? false;
  }

  String _trimZero(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final variant = (widget.initial ?? const ProductPriceVariantModel(
      productId: 0,
      label: '',
      quantityInBaseUnit: 0,
      sellingPrice: 0,
    ))
        .copyWith(
      label: _labelController.text.trim(),
      quantityInBaseUnit: double.parse(_quantityController.text.trim()),
      sellingPrice: double.parse(_priceController.text.trim()),
      isDefault: _isDefault,
    );
    Navigator.of(context).pop(variant);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null
          ? 'products.add_price_option'.tr()
          : 'products.edit_price_option'.tr()),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(labelText: 'products.variant_label'.tr()),
                validator: (value) =>
                    Validators.required(value, 'common.required_field'.tr()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'products.variant_quantity_label'
                      .tr(namedArgs: {'unit': widget.baseUnit.displayLabel}),
                ),
                validator: (value) => Validators.positiveNumber(
                  value,
                  'common.required_field'.tr(),
                  'common.invalid_number'.tr(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    InputDecoration(labelText: 'products.variant_selling_price'.tr()),
                validator: (value) => Validators.positiveNumber(
                  value,
                  'common.required_field'.tr(),
                  'common.invalid_number'.tr(),
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('products.variant_set_default'.tr()),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr()),
        ),
        FilledButton(onPressed: _submit, child: Text('common.save'.tr())),
      ],
    );
  }
}
