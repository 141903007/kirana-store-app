import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../providers/reports_provider.dart';
import '../../services/pdf_service.dart';
import '../../utils/formatters.dart';

/// Covers both "Daily Sales Report" and "Monthly Sales Report" from the
/// spec as one screen with a period toggle, rather than two near-identical
/// screens.
class SalesReportScreen extends StatefulWidget {
  final ReportPeriod initialPeriod;

  const SalesReportScreen({super.key, this.initialPeriod = ReportPeriod.day});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ReportsProvider>().loadSalesReport(widget.initialPeriod),
    );
  }

  String _periodLabel(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.day:
        return 'reports.period_day'.tr();
      case ReportPeriod.month:
        return 'reports.period_month'.tr();
      case ReportPeriod.year:
        return 'reports.period_year'.tr();
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final provider = context.read<ReportsProvider>();
    final languageCode = context.locale.languageCode;
    final total = provider.salesReport.fold<double>(0, (sum, item) => sum + item.sale.totalAmount);

    await Printing.layoutPdf(
      onLayout: (_) => PdfService.buildSimpleReportBytes(
        title: 'reports.daily_sales_report'.tr(),
        subtitle: _periodLabel(provider.salesReportPeriod),
        columns: [
          'billing.invoice_number_label'.tr(),
          'purchase.purchase_date'.tr(),
          'billing.customer_label'.tr(),
          'billing.total'.tr(),
        ],
        rows: [
          for (final item in provider.salesReport)
            [
              item.sale.invoiceNumber,
              Formatters.date(DateTime.parse(item.sale.saleDate)),
              item.customerName ?? 'billing.walk_in_customer'.tr(),
              Formatters.currency(item.sale.totalAmount),
            ],
        ],
        languageCode: languageCode,
        totalLabel: 'billing.total'.tr(),
        totalValue: Formatters.currency(total),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportsProvider>();
    final total = provider.salesReport.fold<double>(0, (sum, item) => sum + item.sale.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: Text('reports.daily_sales_report'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: provider.salesReport.isEmpty ? null : () => _exportPdf(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<ReportPeriod>(
                segments: [
                  ButtonSegment(value: ReportPeriod.day, label: Text(_periodLabel(ReportPeriod.day))),
                  ButtonSegment(
                      value: ReportPeriod.month, label: Text(_periodLabel(ReportPeriod.month))),
                ],
                selected: {provider.salesReportPeriod},
                onSelectionChanged: (selection) =>
                    provider.loadSalesReport(selection.first),
              ),
            ),
            Expanded(
              child: provider.isLoadingSalesReport
                  ? const Center(child: CircularProgressIndicator())
                  : provider.salesReport.isEmpty
                      ? Center(child: Text('reports.no_data'.tr()))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: provider.salesReport.length,
                          itemBuilder: (context, index) {
                            final item = provider.salesReport[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(item.sale.invoiceNumber),
                                subtitle: Text(
                                  '${Formatters.date(DateTime.parse(item.sale.saleDate))} • '
                                  '${item.customerName ?? 'billing.walk_in_customer'.tr()}',
                                ),
                                trailing: Text(
                                  Formatters.currency(item.sale.totalAmount),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            if (provider.salesReport.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('billing.total'.tr(), style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      Formatters.currency(total),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
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
