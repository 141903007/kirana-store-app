import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';

class StoreInfoFormScreen extends StatefulWidget {
  const StoreInfoFormScreen({super.key});

  @override
  State<StoreInfoFormScreen> createState() => _StoreInfoFormScreenState();
}

class _StoreInfoFormScreenState extends State<StoreInfoFormScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<SettingsProvider>();
    await provider.loadStoreSettings();
    if (!mounted) return;
    final settings = provider.storeSettings;
    setState(() {
      _nameController.text = settings?.storeName ?? '';
      _addressController.text = settings?.storeAddress ?? '';
      _phoneController.text = settings?.storePhone ?? '';
      _gstController.text = settings?.storeGstNumber ?? '';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    final provider = context.read<SettingsProvider>();
    final existing = provider.storeSettings!;

    await provider.saveStoreSettings(existing.copyWith(
      storeName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      storeAddress:
          _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      storePhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      storeGstNumber: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
    ));
    if (!mounted) return;

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('settings.store_info_saved'.tr())));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings.store_information'.tr())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'settings.shop_name'.tr()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(labelText: 'settings.shop_address'.tr()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: 'settings.shop_phone'.tr()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gstController,
                    decoration: InputDecoration(labelText: 'settings.shop_gst_number'.tr()),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('common.save'.tr()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
