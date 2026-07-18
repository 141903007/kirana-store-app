import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../providers/reports_provider.dart';
import '../customers/customers_list_screen.dart';
import '../products/products_list_screen.dart';
import '../purchase/purchase_list_screen.dart';
import 'profit_loss_screen.dart';
import 'sales_report_screen.dart';

/// Landing page for every report type. "Stock Report" and "Product Report"
/// both point at the Products list — it's the same underlying product data
/// either way, so a second near-identical screen would just be duplication.
class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('nav.reports'.tr())),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ReportTile(
              icon: Icons.show_chart,
              title: 'reports.profit_loss_title'.tr(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfitLossScreen()),
              ),
            ),
            _ReportTile(
              icon: Icons.point_of_sale_outlined,
              title: 'reports.daily_sales_report'.tr(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SalesReportScreen(initialPeriod: ReportPeriod.day),
                ),
              ),
            ),
            _ReportTile(
              icon: Icons.calendar_month_outlined,
              title: 'reports.monthly_sales_report'.tr(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SalesReportScreen(initialPeriod: ReportPeriod.month),
                ),
              ),
            ),
            _ReportTile(
              icon: Icons.local_shipping_outlined,
              title: 'reports.purchase_report'.tr(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PurchaseListScreen()),
              ),
            ),
            _ReportTile(
              icon: Icons.people_alt_outlined,
              title: 'reports.customer_report'.tr(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomersListScreen()),
              ),
            ),
            _ReportTile(
              icon: Icons.inventory_2_outlined,
              title: 'reports.stock_report'.tr(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProductsListScreen()),
              ),
            ),
            _ReportTile(
              icon: Icons.category_outlined,
              title: 'reports.product_report'.tr(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProductsListScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ReportTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
