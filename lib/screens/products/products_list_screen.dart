import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/product_unit.dart';
import '../../providers/product_provider.dart';
import '../../services/pdf_service.dart';
import '../../utils/formatters.dart';
import 'product_form_screen.dart';
import 'widgets/product_filter_bar.dart';
import 'widgets/product_list_tile.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      provider.loadCategories();
      provider.loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportPdf(BuildContext context, ProductProvider provider) async {
    final languageCode = context.locale.languageCode;
    final totalValue = provider.items.fold<double>(
      0,
      (sum, item) => sum + (item.product.currentStock * item.product.purchasePrice),
    );

    await Printing.layoutPdf(
      onLayout: (_) => PdfService.buildSimpleReportBytes(
        title: 'reports.stock_report'.tr(),
        columns: [
          'products.name'.tr(),
          'products.category'.tr(),
          'products.current_stock'.tr(),
          'reports.purchase_price_label'.tr(),
        ],
        rows: [
          for (final item in provider.items)
            [
              item.product.name,
              provider.categoryFor(item.product.categoryId)?.name ?? 'products.uncategorized'.tr(),
              '${item.product.currentStock.toStringAsFixed(0)} ${item.product.baseUnit.displayLabel}',
              Formatters.currency(item.product.purchasePrice),
            ],
        ],
        languageCode: languageCode,
        totalLabel: 'dashboard.stock_value'.tr(),
        totalValue: Formatters.currency(totalValue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('nav.products'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: provider.items.isEmpty ? null : () => _exportPdf(context, provider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'products.search_hint'.tr(),
                prefixIcon: const Icon(Icons.search),
                filled: true,
              ),
              onChanged: provider.setSearchQuery,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const ProductFilterBar(),
          const SizedBox(height: 8),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.items.isEmpty
                    ? Center(child: Text('products.no_products_found'.tr()))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.items.length,
                        itemBuilder: (context, index) {
                          final item = provider.items[index];
                          return ProductListTile(
                            item: item,
                            categoryName: provider.categoryFor(item.product.categoryId)?.name,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductFormScreen(productId: item.product.id),
                              ),
                            ),
                            onToggleFavorite: () => provider.toggleFavorite(item.product),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ProductFormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
