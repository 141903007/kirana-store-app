import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../providers/customer_provider.dart';
import '../../services/pdf_service.dart';
import '../../utils/formatters.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<CustomerProvider>().loadCustomers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportPdf(BuildContext context, CustomerProvider provider) async {
    final languageCode = context.locale.languageCode;
    final total = provider.customers.fold<double>(0, (sum, item) => sum + item.totalPurchaseAmount);

    await Printing.layoutPdf(
      onLayout: (_) => PdfService.buildSimpleReportBytes(
        title: 'reports.customer_report'.tr(),
        columns: [
          'customers.name'.tr(),
          'customers.mobile'.tr(),
          'customers.total_purchase_amount'.tr(),
        ],
        rows: [
          for (final item in provider.customers)
            [
              item.customer.name,
              item.customer.mobile ?? '',
              Formatters.currency(item.totalPurchaseAmount),
            ],
        ],
        languageCode: languageCode,
        totalLabel: 'customers.total_purchase_amount'.tr(),
        totalValue: Formatters.currency(total),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('nav.customers'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: provider.customers.isEmpty ? null : () => _exportPdf(context, provider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'customers.search_hint'.tr(),
                prefixIcon: const Icon(Icons.search),
                filled: true,
              ),
              onChanged: provider.setSearchQuery,
            ),
          ),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.customers.isEmpty
              ? Center(child: Text('customers.no_customers_found'.tr()))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.customers.length,
                  itemBuilder: (context, index) {
                    final item = provider.customers[index];
                    final customer = item.customer;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomerDetailScreen(customerId: customer.id!),
                          ),
                        ),
                        title: Text(customer.name),
                        subtitle: Text(customer.mobile ?? ''),
                        trailing: Text(
                          Formatters.currency(item.totalPurchaseAmount),
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
            .push(MaterialPageRoute(builder: (_) => const CustomerFormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
