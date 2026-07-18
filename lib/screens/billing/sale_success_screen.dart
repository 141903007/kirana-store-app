import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/sale_model.dart';
import '../../providers/sales_provider.dart';
import '../../repository/settings_repository.dart';
import '../../services/pdf_service.dart';
import '../../utils/formatters.dart';

/// Shown right after checkout. Doubles as the invoice preview/print screen
/// for v1 — `Printing.layoutPdf` already opens the OS print/share sheet,
/// so a separate PDF-preview screen isn't needed.
class SaleSuccessScreen extends StatelessWidget {
  final SaleModel sale;
  final String? customerName;

  const SaleSuccessScreen({super.key, required this.sale, this.customerName});

  Future<void> _printOrShare(BuildContext context) async {
    final provider = context.read<SalesProvider>();
    final items = await provider.getItemsForSale(sale.id!);
    final settings = await SettingsRepository().get();
    if (!context.mounted) return;
    final languageCode = context.locale.languageCode;

    await Printing.layoutPdf(
      onLayout: (_) => PdfService.buildInvoiceBytes(
        sale: sale,
        items: items,
        settings: settings,
        languageCode: languageCode,
        customerName: customerName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('billing.sale_completed_title'.tr())),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 72, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  '${'billing.invoice_number_label'.tr()}: ${sale.invoiceNumber}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.currency(sale.totalAmount),
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _printOrShare(context),
                    icon: const Icon(Icons.print_outlined),
                    label: Text('billing.print_share_invoice'.tr()),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('billing.new_sale'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
