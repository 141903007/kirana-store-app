import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../utils/validators.dart';

class CustomerFormScreen extends StatefulWidget {
  final int? customerId;

  const CustomerFormScreen({super.key, this.customerId});

  bool get isEditMode => customerId != null;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  CustomerModel? _original;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    final customer = await context.read<CustomerProvider>().getById(widget.customerId!);
    if (!mounted || customer == null) return;
    setState(() {
      _original = customer;
      _nameController.text = customer.name;
      _mobileController.text = customer.mobile ?? '';
      _addressController.text = customer.address ?? '';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final now = DateTime.now().toIso8601String();
    final customer = CustomerModel(
      id: widget.customerId,
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      createdAt: widget.isEditMode ? _original!.createdAt : now,
      updatedAt: now,
    );

    await context.read<CustomerProvider>().saveCustomer(customer);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('customers.customer_saved'.tr())));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('customers.edit_customer'.tr())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode
            ? 'customers.edit_customer'.tr()
            : 'customers.add_customer'.tr()),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'customers.name'.tr()),
                validator: (value) => Validators.required(value, 'common.required_field'.tr()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'customers.mobile'.tr()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'customers.address'.tr()),
                maxLines: 2,
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
