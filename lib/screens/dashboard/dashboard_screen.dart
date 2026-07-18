import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/stat_card.dart';
import '../auth/account_settings_screen.dart';
import '../billing/billing_screen.dart';
import '../customers/customers_list_screen.dart';
import '../products/products_list_screen.dart';
import '../purchase/purchase_list_screen.dart';
import '../reports/reports_hub_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/quick_nav_tile.dart';

/// The post-login home screen, backed by real data from
/// `DashboardProvider.loadToday()` (via `ReportRepository`). Reloaded on
/// first open, on pull-to-refresh, and after returning from any screen that
/// could change today's numbers (Billing, Purchase, Products, Customers).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<DashboardProvider>().loadToday());
  }

  Future<void> _pushAndRefresh(BuildContext context, WidgetBuilder builder) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: builder));
    if (!context.mounted) return;
    context.read<DashboardProvider>().loadToday();
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  ThemeMode _nextMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return ThemeMode.light;
      case ThemeMode.light:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.system;
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('home.logout_confirm_title'.tr()),
        content: Text('home.logout_confirm_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('home.logout'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final summary = dashboardProvider.summary;
    final colorScheme = Theme.of(context).colorScheme;
    final username = authProvider.currentUser?.username ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr()),
        actions: [
          IconButton(
            tooltip: 'home.theme_mode'.tr(),
            icon: Icon(_themeIcon(themeProvider.themeMode)),
            onPressed: () =>
                themeProvider.setThemeMode(_nextMode(themeProvider.themeMode)),
          ),
          IconButton(
            tooltip: 'home.account_settings'.tr(),
            icon: const Icon(Icons.manage_accounts_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'home.logout'.tr(),
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<DashboardProvider>().loadToday(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${'home.welcome_back'.tr()}, $username',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              _SectionHeader('dashboard.todays_business'.tr()),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  StatCard(
                    icon: Icons.point_of_sale_outlined,
                    label: 'dashboard.todays_sales'.tr(),
                    value: Formatters.currency(summary.todaySales),
                  ),
                  StatCard(
                    icon: Icons.shopping_cart_outlined,
                    label: 'dashboard.todays_purchase'.tr(),
                    value: Formatters.currency(summary.todayPurchase),
                  ),
                  StatCard(
                    icon: Icons.trending_up,
                    label: 'dashboard.todays_profit'.tr(),
                    value: Formatters.currency(summary.todayProfit),
                    valueColor: Colors.green.shade600,
                    backgroundColor: Colors.green.withValues(alpha: 0.12),
                  ),
                  StatCard(
                    icon: Icons.trending_down,
                    label: 'dashboard.todays_loss'.tr(),
                    value: Formatters.currency(summary.todayLoss),
                    valueColor: Colors.red.shade600,
                    backgroundColor: Colors.red.withValues(alpha: 0.12),
                  ),
                  StatCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'dashboard.stock_value'.tr(),
                    value: Formatters.currency(summary.stockValue),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionHeader('dashboard.inventory_alerts'.tr()),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  StatCard(
                    icon: Icons.warning_amber_outlined,
                    label: 'dashboard.low_stock_items'.tr(),
                    value: '${summary.lowStockCount}',
                    valueColor: Colors.orange.shade700,
                    backgroundColor: Colors.orange.withValues(alpha: 0.12),
                    onTap: () {
                      context.read<ProductProvider>().applyQuickFilter(lowStockOnly: true);
                      _pushAndRefresh(context, (_) => const ProductsListScreen());
                    },
                  ),
                  StatCard(
                    icon: Icons.remove_shopping_cart_outlined,
                    label: 'dashboard.out_of_stock_items'.tr(),
                    value: '${summary.outOfStockCount}',
                    valueColor: Colors.red.shade700,
                    backgroundColor: Colors.red.withValues(alpha: 0.12),
                    onTap: () {
                      context.read<ProductProvider>().applyQuickFilter(outOfStockOnly: true);
                      _pushAndRefresh(context, (_) => const ProductsListScreen());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionHeader('dashboard.overview'.tr()),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  StatCard(
                    icon: Icons.inventory_outlined,
                    label: 'dashboard.total_products'.tr(),
                    value: '${summary.totalProducts}',
                  ),
                  StatCard(
                    icon: Icons.people_outline,
                    label: 'dashboard.total_customers'.tr(),
                    value: '${summary.totalCustomers}',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionHeader('dashboard.quick_actions'.tr()),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: colorScheme.primary,
                  ),
                  onPressed: () => _pushAndRefresh(context, (_) => const BillingScreen()),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(
                    'dashboard.start_billing'.tr(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  QuickNavTile(
                    icon: Icons.inventory_2_outlined,
                    label: 'nav.products'.tr(),
                    onTap: () => _pushAndRefresh(context, (_) => const ProductsListScreen()),
                  ),
                  QuickNavTile(
                    icon: Icons.local_shipping_outlined,
                    label: 'nav.purchase'.tr(),
                    onTap: () => _pushAndRefresh(context, (_) => const PurchaseListScreen()),
                  ),
                  QuickNavTile(
                    icon: Icons.bar_chart_outlined,
                    label: 'nav.reports'.tr(),
                    onTap: () => _pushAndRefresh(context, (_) => const ReportsHubScreen()),
                  ),
                  QuickNavTile(
                    icon: Icons.people_alt_outlined,
                    label: 'nav.customers'.tr(),
                    onTap: () => _pushAndRefresh(context, (_) => const CustomersListScreen()),
                  ),
                  QuickNavTile(
                    icon: Icons.settings_outlined,
                    label: 'nav.settings'.tr(),
                    onTap: () => _pushAndRefresh(context, (_) => const SettingsScreen()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
