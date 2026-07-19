import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer_model.dart';
import '../../models/sale_model.dart';
import '../../providers/customer_provider.dart';
import '../../repository/sale_repository.dart';
import '../../utils/formatters.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _saleRepository = SaleRepository();

  CustomerModel? _customer;
  double _totalPurchaseAmount = 0;
  List<SaleModel> _history = [];

  /// Line items per sale, keyed by sale id — loaded once alongside the
  /// bill list so each invoice can show what was actually bought, not just
  /// its total.
  final Map<int, List<SaleItemDetail>> _itemsBySale = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<CustomerProvider>();
    final results = await Future.wait([
      provider.getById(widget.customerId),
      provider.getTotalPurchaseAmount(widget.customerId),
      provider.getPurchaseHistory(widget.customerId),
    ]);
    final history = results[2] as List<SaleModel>;

    final itemLists = await Future.wait(
      history.map((sale) => _saleRepository.getItemsForSale(sale.id!)),
    );

    if (!mounted) return;
    setState(() {
      _customer = results[0] as CustomerModel?;
      _totalPurchaseAmount = results[1] as double;
      _history = history;
      _itemsBySale
        ..clear()
        ..addEntries(
          Iterable.generate(history.length, (i) => MapEntry(history[i].id!, itemLists[i])),
        );
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('customers.delete_confirm_title'.tr()),
        content: Text('customers.delete_confirm_message'.tr()),
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
    if (confirmed != true || !mounted) return;

    await context.read<CustomerProvider>().deleteCustomer(widget.customerId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final customer = _customer;

    return Scaffold(
      appBar: AppBar(
        title: Text('customers.detail_title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: customer == null
                ? null
                : () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerFormScreen(customerId: widget.customerId),
                      ),
                    );
                    _load();
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: customer == null ? null : _confirmDelete,
          ),
        ],
      ),
      body: customer == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(customer.name, style: Theme.of(context).textTheme.titleLarge),
                  if (customer.mobile != null) ...[
                    const SizedBox(height: 4),
                    Text(customer.mobile!),
                  ],
                  if (customer.address != null) ...[
                    const SizedBox(height: 4),
                    Text(customer.address!),
                  ],
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('customers.total_purchase_amount'.tr(),
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            Formatters.currency(_totalPurchaseAmount),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('customers.purchase_history'.tr(),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_history.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('customers.no_purchase_history'.tr()),
                    )
                  else
                    for (final sale in _history)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          title: Text(sale.invoiceNumber),
                          subtitle: Text(Formatters.date(DateTime.parse(sale.saleDate))),
                          trailing: Text(
                            Formatters.currency(sale.totalAmount),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          children: [
                            for (final detail in _itemsBySale[sale.id] ?? <SaleItemDetail>[])
                              ListTile(
                                dense: true,
                                title: Text(detail.productName),
                                subtitle: Text(
                                  '${detail.item.quantity.toStringAsFixed(2)} × ${detail.item.variantLabel} @ ${Formatters.currency(detail.item.unitSellingPrice)}',
                                ),
                                trailing: Text(Formatters.currency(detail.item.lineTotal)),
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
