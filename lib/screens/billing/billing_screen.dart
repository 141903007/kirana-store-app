import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/sales_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/product_picker_sheet.dart';
import 'sale_success_screen.dart';
import 'widgets/billing_variant_picker_dialog.dart';
import 'widgets/cart_item_tile.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _discountController = TextEditingController(text: '0');
  bool _isCheckingOut = false;

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _addProduct(BuildContext context) async {
    final provider = context.read<SalesProvider>();
    final picked = await showProductPickerSheet(context, onSearch: provider.searchProducts);
    if (picked == null) return;
    if (!context.mounted) return;

    final variants = await provider.getVariants(picked.product.id!);
    if (!context.mounted) return;

    final line = await showBillingVariantPicker(
      context,
      product: picked.product,
      variants: variants,
    );
    if (line == null) return;
    provider.addToCart(line);
  }

  Future<void> _checkout(BuildContext context) async {
    final provider = context.read<SalesProvider>();
    if (provider.cart.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('billing.at_least_one_item_required'.tr())));
      return;
    }

    setState(() => _isCheckingOut = true);
    final customerName = provider.selectedCustomerName;
    final sale = await provider.checkout();
    if (!context.mounted) return;

    setState(() => _isCheckingOut = false);
    _discountController.text = '0';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SaleSuccessScreen(sale: sale, customerName: customerName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('billing.screen_title'.tr())),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _addProduct(context),
                    icon: const Icon(Icons.add),
                    label: Text('billing.select_product'.tr()),
                  ),
                  const SizedBox(height: 16),
                  if (provider.cart.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'billing.cart_empty'.tr(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    for (var i = 0; i < provider.cart.length; i++)
                      CartItemTile(
                        line: provider.cart[i],
                        onQuantityChanged: (qty) => provider.updateQuantity(i, qty),
                        onRemove: () => provider.removeFromCart(i),
                      ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'billing.discount_percent'.tr()),
                    onChanged: (value) =>
                        provider.setDiscountPercent(double.tryParse(value.trim()) ?? 0),
                  ),
                  const SizedBox(height: 16),
                  _totalRow(context, 'billing.subtotal'.tr(), provider.subtotal),
                  _totalRow(context, 'billing.discount'.tr(), provider.discountAmount),
                  _totalRow(context, 'billing.gst'.tr(), provider.gstAmount),
                  const Divider(),
                  _totalRow(context, 'billing.total'.tr(), provider.total, bold: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isCheckingOut ? null : () => _checkout(context),
                  child: _isCheckingOut
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('billing.checkout'.tr()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(BuildContext context, String label, double value, {bool bold = false}) {
    final style = bold
        ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(Formatters.currency(value), style: style),
        ],
      ),
    );
  }
}
