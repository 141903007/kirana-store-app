import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/purchase_item_model.dart';
import '../../models/purchase_model.dart';
import '../../providers/purchase_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import 'widgets/purchase_line_item_editor.dart';

class PurchaseFormScreen extends StatefulWidget {
  const PurchaseFormScreen({super.key});

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dealerNameController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _remarksController = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  List<PurchaseLineDraft> _items = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _dealerNameController.dispose();
    _invoiceNumberController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.lineTotal);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('purchase.at_least_one_item_required'.tr())));
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now().toIso8601String();
    final purchase = PurchaseModel(
      dealerName: _dealerNameController.text.trim(),
      invoiceNumber:
          _invoiceNumberController.text.trim().isEmpty ? null : _invoiceNumberController.text.trim(),
      purchaseDate: DateTime(_purchaseDate.year, _purchaseDate.month, _purchaseDate.day)
          .toIso8601String(),
      totalAmount: _totalAmount,
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      createdAt: now,
    );

    final items = _items
        .map((draft) => PurchaseItemModel(
              purchaseId: 0,
              productId: draft.productId,
              variantLabel: draft.variantLabel,
              quantity: draft.quantity,
              conversionFactor: draft.conversionFactor,
              pricePerUnit: draft.pricePerUnit,
              lineTotal: draft.lineTotal,
            ))
        .toList();

    await context.read<PurchaseProvider>().savePurchase(purchase: purchase, items: items);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('purchase.purchase_saved'.tr())));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('purchase.new_purchase'.tr())),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _dealerNameController,
                decoration: InputDecoration(labelText: 'purchase.dealer_name'.tr()),
                validator: (value) => Validators.required(value, 'common.required_field'.tr()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _invoiceNumberController,
                decoration: InputDecoration(labelText: 'purchase.invoice_number'.tr()),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(labelText: 'purchase.purchase_date'.tr()),
                  child: Text(Formatters.date(_purchaseDate)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remarksController,
                decoration: InputDecoration(labelText: 'purchase.remarks'.tr()),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              PurchaseLineItemEditor(
                items: _items,
                provider: provider,
                onChanged: (items) => setState(() => _items = items),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('purchase.total_amount'.tr(),
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    Formatters.currency(_totalAmount),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
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
