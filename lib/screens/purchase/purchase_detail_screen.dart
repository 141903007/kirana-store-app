import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/purchase_model.dart';
import '../../providers/purchase_provider.dart';
import '../../repository/purchase_repository.dart';
import '../../utils/formatters.dart';

/// Read-only view of a past purchase. Editing/deleting past purchases isn't
/// supported — reversing stock/purchase_price changes after the fact isn't
/// well-defined without a full cost-history model, which is out of scope.
class PurchaseDetailScreen extends StatefulWidget {
  final int purchaseId;

  const PurchaseDetailScreen({super.key, required this.purchaseId});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  List<PurchaseItemDetail>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await context.read<PurchaseProvider>().loadItemsForDetail(widget.purchaseId);
    if (!mounted) return;
    setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();
    PurchaseModel? purchase;
    for (final item in provider.purchases) {
      if (item.purchase.id == widget.purchaseId) {
        purchase = item.purchase;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('purchase.detail_title'.tr())),
      body: _items == null || purchase == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(purchase.dealerName, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(Formatters.date(DateTime.parse(purchase.purchaseDate))),
                  if (purchase.invoiceNumber != null) ...[
                    const SizedBox(height: 4),
                    Text('${'purchase.invoice_number'.tr()}: ${purchase.invoiceNumber}'),
                  ],
                  if (purchase.remarks != null) ...[
                    const SizedBox(height: 4),
                    Text(purchase.remarks!),
                  ],
                  const SizedBox(height: 20),
                  Text('purchase.items_section_title'.tr(),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final detail in _items!)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(detail.productName),
                        subtitle: Text(
                          '${detail.item.quantity.toStringAsFixed(2)} × ${detail.item.variantLabel} @ ${Formatters.currency(detail.item.pricePerUnit)}',
                        ),
                        trailing: Text(
                          Formatters.currency(detail.item.lineTotal),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('purchase.total_amount'.tr(),
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        Formatters.currency(purchase.totalAmount),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
