import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../models/product_price_variant_model.dart';
import '../../../models/product_unit.dart';
import '../../../providers/purchase_provider.dart';
import '../../../utils/formatters.dart';
import '../../../utils/validators.dart';
import '../../../widgets/product_picker_sheet.dart';

/// One in-progress purchase line item. Not a DB model — this is the
/// in-memory draft the form builds up before a single `savePurchase` call
/// turns each of these into a `PurchaseItemModel`.
class PurchaseLineDraft {
  final int productId;
  final String productName;
  final String baseUnitLabel;
  final String variantLabel;
  final double conversionFactor;
  final double quantity;
  final double pricePerUnit;

  const PurchaseLineDraft({
    required this.productId,
    required this.productName,
    required this.baseUnitLabel,
    required this.variantLabel,
    required this.conversionFactor,
    required this.quantity,
    required this.pricePerUnit,
  });

  double get lineTotal => quantity * pricePerUnit;
}

/// A unit a purchase line can be recorded in: either the product's raw base
/// unit (conversionFactor 1) or one of its sellable price variants. Purchase
/// line items snapshot label + factor directly — they're not tied to
/// `product_price_variants` by a foreign key, so any of these are valid,
/// which is what lets buying "50 kg loose" work even when the product is
/// only ever sold in 1kg/500g bags.
class _PurchaseUnitOption {
  final String label;
  final double conversionFactor;

  const _PurchaseUnitOption({required this.label, required this.conversionFactor});
}

class PurchaseLineItemEditor extends StatelessWidget {
  final List<PurchaseLineDraft> items;
  final PurchaseProvider provider;
  final ValueChanged<List<PurchaseLineDraft>> onChanged;

  const PurchaseLineItemEditor({
    super.key,
    required this.items,
    required this.provider,
    required this.onChanged,
  });

  Future<void> _addItem(BuildContext context) async {
    final picked = await showProductPickerSheet(context, onSearch: provider.searchProducts);
    if (picked == null) return;
    if (!context.mounted) return;

    final variants = await provider.getVariants(picked.product.id!);
    if (!context.mounted) return;

    final draft = await showDialog<PurchaseLineDraft>(
      context: context,
      builder: (_) => _LineItemDialog(
        productId: picked.product.id!,
        productName: picked.product.name,
        baseUnitLabel: picked.product.baseUnit.displayLabel,
        variants: variants,
      ),
    );
    if (draft == null) return;
    onChanged([...items, draft]);
  }

  Future<void> _editItem(BuildContext context, int index) async {
    final existing = items[index];
    final variants = await provider.getVariants(existing.productId);
    if (!context.mounted) return;

    final draft = await showDialog<PurchaseLineDraft>(
      context: context,
      builder: (_) => _LineItemDialog(
        productId: existing.productId,
        productName: existing.productName,
        baseUnitLabel: existing.baseUnitLabel,
        variants: variants,
        initial: existing,
      ),
    );
    if (draft == null) return;

    final updated = [...items];
    updated[index] = draft;
    onChanged(updated);
  }

  Future<void> _removeItem(BuildContext context, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('purchase.remove_item_confirm'.tr()),
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

    final updated = [...items]..removeAt(index);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('purchase.items_section_title'.tr(),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'purchase.no_items_added'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        for (var i = 0; i < items.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => _editItem(context, i),
              title: Text(items[i].productName),
              subtitle: Text(
                '${items[i].quantity.toStringAsFixed(2)} × ${items[i].variantLabel} @ ${Formatters.currency(items[i].pricePerUnit)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.currency(items[i].lineTotal),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeItem(context, i),
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => _addItem(context),
          icon: const Icon(Icons.add),
          label: Text('purchase.add_item'.tr()),
        ),
      ],
    );
  }
}

class _LineItemDialog extends StatefulWidget {
  final int productId;
  final String productName;
  final String baseUnitLabel;
  final List<ProductPriceVariantModel> variants;
  final PurchaseLineDraft? initial;

  const _LineItemDialog({
    required this.productId,
    required this.productName,
    required this.baseUnitLabel,
    required this.variants,
    this.initial,
  });

  @override
  State<_LineItemDialog> createState() => _LineItemDialogState();
}

class _LineItemDialogState extends State<_LineItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late List<_PurchaseUnitOption> _unitOptions;
  late _PurchaseUnitOption _selectedUnit;

  @override
  void initState() {
    super.initState();
    _unitOptions = [
      _PurchaseUnitOption(label: widget.baseUnitLabel, conversionFactor: 1),
      for (final variant in widget.variants.where((v) => v.isActive))
        _PurchaseUnitOption(label: variant.label, conversionFactor: variant.quantityInBaseUnit),
    ];

    final initial = widget.initial;
    _selectedUnit = initial == null
        ? _unitOptions.first
        : _unitOptions.firstWhere(
            (option) =>
                option.label == initial.variantLabel &&
                option.conversionFactor == initial.conversionFactor,
            orElse: () => _unitOptions.first,
          );

    _quantityController =
        TextEditingController(text: initial == null ? '' : _trimZero(initial.quantity));
    _priceController =
        TextEditingController(text: initial == null ? '' : _trimZero(initial.pricePerUnit));
  }

  String _trimZero(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final draft = PurchaseLineDraft(
      productId: widget.productId,
      productName: widget.productName,
      baseUnitLabel: widget.baseUnitLabel,
      variantLabel: _selectedUnit.label,
      conversionFactor: _selectedUnit.conversionFactor,
      quantity: double.parse(_quantityController.text.trim()),
      pricePerUnit: double.parse(_priceController.text.trim()),
    );
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.productName),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<_PurchaseUnitOption>(
                initialValue: _selectedUnit,
                decoration: InputDecoration(labelText: 'purchase.unit_label'.tr()),
                items: [
                  for (final option in _unitOptions)
                    DropdownMenuItem(value: option, child: Text(option.label)),
                ],
                onChanged: (option) => setState(() => _selectedUnit = option ?? _selectedUnit),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'purchase.quantity'.tr()),
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
                decoration: InputDecoration(
                  labelText:
                      'purchase.price_per_unit'.tr(namedArgs: {'unit': _selectedUnit.label}),
                ),
                validator: (value) => Validators.positiveNumber(
                  value,
                  'common.required_field'.tr(),
                  'common.invalid_number'.tr(),
                ),
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
