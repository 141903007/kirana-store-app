import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../models/product_price_variant_model.dart';
import '../../models/product_unit.dart';
import '../../providers/product_provider.dart';
import '../../utils/stock_breakdown.dart';
import '../../utils/validators.dart';
import 'widgets/category_picker_field.dart';
import 'widgets/opening_stock_input.dart';
import 'widgets/price_variant_editor.dart';

const _gstQuickPicks = [0.0, 5.0, 12.0, 18.0, 28.0];

class ProductFormScreen extends StatefulWidget {
  final int? productId;

  const ProductFormScreen({super.key, this.productId});

  bool get isEditMode => productId != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _skuController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _gstController = TextEditingController();
  final _minStockAlertController = TextEditingController();
  final _stockController = TextEditingController(text: '0');

  bool _isLoading = false;
  bool _isSaving = false;
  int? _categoryId;
  ProductUnit _baseUnit = ProductUnit.piece;
  bool _isFavorite = false;
  bool _isActive = true;
  List<ProductPriceVariantModel> _variants = [];

  ProductModel? _originalProduct;
  double _originalCurrentStock = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    final result = await context.read<ProductProvider>().loadForEdit(widget.productId!);
    if (!mounted || result == null) return;

    final product = result.product;
    setState(() {
      _originalProduct = product;
      _originalCurrentStock = product.currentStock;
      _nameController.text = product.name;
      _barcodeController.text = product.barcode ?? '';
      _skuController.text = product.sku ?? '';
      _purchasePriceController.text = _trimZero(product.purchasePrice);
      _gstController.text = product.gstPercent == null ? '' : _trimZero(product.gstPercent!);
      _minStockAlertController.text = _trimZero(product.minStockAlert);
      _stockController.text = _trimZero(product.currentStock);
      _categoryId = product.categoryId;
      _baseUnit = product.baseUnit;
      _isFavorite = product.isFavorite;
      _isActive = product.isActive;
      _variants = result.variants;
      _isLoading = false;
    });
  }

  String _trimZero(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    _purchasePriceController.dispose();
    _gstController.dispose();
    _minStockAlertController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  double? get _boxQuantity {
    final boxLike = _variants.where((v) => v.quantityInBaseUnit > 1).toList()
      ..sort((a, b) => b.quantityInBaseUnit.compareTo(a.quantityInBaseUnit));
    return boxLike.isEmpty ? null : boxLike.first.quantityInBaseUnit;
  }

  String? get _boxLabel {
    final boxLike = _variants.where((v) => v.quantityInBaseUnit > 1).toList()
      ..sort((a, b) => b.quantityInBaseUnit.compareTo(a.quantityInBaseUnit));
    return boxLike.isEmpty ? null : boxLike.first.label;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('products.at_least_one_price_required'.tr())));
      return;
    }

    final barcode = _barcodeController.text.trim();
    final provider = context.read<ProductProvider>();
    if (barcode.isNotEmpty) {
      final taken = await provider.isBarcodeTaken(barcode, excludingProductId: widget.productId);
      if (taken) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('products.duplicate_barcode_warning'.tr())),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final now = DateTime.now().toIso8601String();
    final stockValue = double.tryParse(_stockController.text.trim()) ?? 0;

    final product = ProductModel(
      id: widget.productId,
      name: _nameController.text.trim(),
      categoryId: _categoryId,
      barcode: barcode.isEmpty ? null : barcode,
      sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
      baseUnit: _baseUnit,
      purchasePrice: double.parse(_purchasePriceController.text.trim()),
      gstPercent: _gstController.text.trim().isEmpty
          ? null
          : double.parse(_gstController.text.trim()),
      openingStock: widget.isEditMode ? _originalProduct!.openingStock : stockValue,
      currentStock: widget.isEditMode ? _originalProduct!.currentStock : stockValue,
      minStockAlert: double.parse(_minStockAlertController.text.trim()),
      isFavorite: _isFavorite,
      isActive: _isActive,
      createdAt: widget.isEditMode ? _originalProduct!.createdAt : now,
      updatedAt: now,
    );

    final success = await provider.saveProduct(product: product, variants: _variants);
    if (!mounted) return;

    if (!success) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(provider.errorMessage!.tr())));
      return;
    }

    if (widget.isEditMode && stockValue != _originalCurrentStock) {
      await provider.adjustCurrentStock(widget.productId!, stockValue, _originalCurrentStock);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('products.product_saved'.tr())));
    Navigator.of(context).pop();
  }

  Future<void> _confirmDeactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_isActive
            ? 'products.deactivate_confirm_title'.tr()
            : 'products.reactivate'.tr()),
        content: _isActive ? Text('products.deactivate_confirm_message'.tr()) : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_isActive ? 'products.deactivate'.tr() : 'products.reactivate'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<ProductProvider>().setActive(widget.productId!, !_isActive);
    if (!mounted) return;
    setState(() => _isActive = !_isActive);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('products.edit_product'.tr())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final breakdown = _originalProduct == null
        ? null
        : computeStockBreakdown(_originalProduct!, _variants);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'products.edit_product'.tr() : 'products.add_product'.tr()),
        actions: [
          if (widget.isEditMode)
            IconButton(
              icon: Icon(_isActive ? Icons.archive_outlined : Icons.unarchive_outlined),
              tooltip: _isActive ? 'products.deactivate'.tr() : 'products.reactivate'.tr(),
              onPressed: _confirmDeactivate,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'products.name'.tr()),
                validator: (value) => Validators.required(value, 'common.required_field'.tr()),
              ),
              const SizedBox(height: 12),
              CategoryPickerField(
                selectedCategoryId: _categoryId,
                onChanged: (id) => setState(() => _categoryId = id),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(labelText: 'products.barcode'.tr()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _skuController,
                decoration: InputDecoration(labelText: 'products.sku'.tr()),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<ProductUnit>(
                initialValue: _baseUnit,
                decoration: InputDecoration(
                  labelText: 'products.base_unit'.tr(),
                  helperText: widget.isEditMode ? 'products.base_unit_locked_hint'.tr() : null,
                ),
                items: [
                  for (final unit in ProductUnit.values)
                    DropdownMenuItem(value: unit, child: Text(unit.displayLabel)),
                ],
                onChanged: widget.isEditMode
                    ? null
                    : (unit) => setState(() => _baseUnit = unit ?? _baseUnit),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _purchasePriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText:
                      'products.purchase_price'.tr(namedArgs: {'unit': _baseUnit.displayLabel}),
                ),
                validator: (value) => Validators.nonNegativeNumber(
                  value,
                  'common.required_field'.tr(),
                  'common.invalid_number'.tr(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gstController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'products.gst_percent'.tr()),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final pick in _gstQuickPicks)
                    ChoiceChip(
                      label: Text('${pick.toStringAsFixed(0)}%'),
                      selected: _gstController.text.trim() == _trimZero(pick),
                      onSelected: (_) => setState(() => _gstController.text = _trimZero(pick)),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (breakdown != null) ...[
                Text(
                  'products.stock_breakdown'.tr(namedArgs: {
                    'boxes': breakdown.boxCount.toString(),
                    'boxLabel': breakdown.boxLabel,
                    'remainder': breakdown.remainder.toStringAsFixed(0),
                    'unit': _baseUnit.displayLabel,
                    'total': breakdown.totalInBaseUnit.toStringAsFixed(0),
                  }),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              OpeningStockInput(
                controller: _stockController,
                fieldLabel: widget.isEditMode
                    ? 'products.current_stock'.tr()
                    : 'products.opening_stock'.tr(namedArgs: {'unit': _baseUnit.displayLabel}),
                unitLabel: _baseUnit.displayLabel,
                boxQuantity: _boxQuantity,
                boxLabel: _boxLabel,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minStockAlertController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'products.min_stock_alert'.tr()),
                validator: (value) => Validators.nonNegativeNumber(
                  value,
                  'common.required_field'.tr(),
                  'common.invalid_number'.tr(),
                ),
              ),
              const SizedBox(height: 24),
              PriceVariantEditor(
                variants: _variants,
                baseUnit: _baseUnit,
                purchasePricePerBaseUnit:
                    double.tryParse(_purchasePriceController.text.trim()) ?? 0,
                onChanged: (variants) => setState(() => _variants = variants),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('products.mark_favorite'.tr()),
                value: _isFavorite,
                onChanged: (value) => setState(() => _isFavorite = value),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('common.save'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
