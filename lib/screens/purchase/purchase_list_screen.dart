import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../providers/purchase_provider.dart';
import '../../services/pdf_service.dart';
import '../../utils/formatters.dart';
import 'purchase_detail_screen.dart';
import 'purchase_form_screen.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<PurchaseProvider>().loadPurchases());
  }

  Future<void> _exportPdf(BuildContext context, PurchaseProvider provider) async {
    final languageCode = context.locale.languageCode;
    final total =
        provider.purchases.fold<double>(0, (sum, item) => sum + item.purchase.totalAmount);

    await Printing.layoutPdf(
      onLayout: (_) => PdfService.buildSimpleReportBytes(
        title: 'reports.purchase_report'.tr(),
        columns: [
          'purchase.dealer_name'.tr(),
          'purchase.purchase_date'.tr(),
          'purchase.items_section_title'.tr(),
          'purchase.total_amount'.tr(),
        ],
        rows: [
          for (final item in provider.purchases)
            [
              item.purchase.dealerName,
              Formatters.date(DateTime.parse(item.purchase.purchaseDate)),
              item.itemCount.toString(),
              Formatters.currency(item.purchase.totalAmount),
            ],
        ],
        languageCode: languageCode,
        totalLabel: 'purchase.total_amount'.tr(),
        totalValue: Formatters.currency(total),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('purchase.list_title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: provider.purchases.isEmpty ? null : () => _exportPdf(context, provider),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.purchases.isEmpty
              ? Center(child: Text('purchase.no_purchases_found'.tr()))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.purchases.length,
                  itemBuilder: (context, index) {
                    final item = provider.purchases[index];
                    final purchase = item.purchase;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PurchaseDetailScreen(purchaseId: purchase.id!),
                          ),
                        ),
                        title: Text(purchase.dealerName),
                        subtitle: Text(
                          '${Formatters.date(DateTime.parse(purchase.purchaseDate))} • '
                          '${'purchase.item_count'.tr(namedArgs: {
                                'count': item.itemCount.toString()
                              })}',
                        ),
                        trailing: Text(
                          Formatters.currency(purchase.totalAmount),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const PurchaseFormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
