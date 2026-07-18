import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/db_tables.dart';
import '../../providers/stock_provider.dart';
import '../../utils/formatters.dart';

class StockHistoryScreen extends StatefulWidget {
  final int productId;
  final String productName;

  const StockHistoryScreen({super.key, required this.productId, required this.productName});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<StockProvider>().loadHistory(widget.productId));
  }

  String _changeTypeLabel(String changeType) {
    switch (changeType) {
      case StockChangeType.purchase:
        return 'stock.change_purchase'.tr();
      case StockChangeType.sale:
        return 'stock.change_sale'.tr();
      case StockChangeType.adjustment:
        return 'stock.change_adjustment'.tr();
      case StockChangeType.opening:
        return 'stock.change_opening'.tr();
      default:
        return changeType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.productName)),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.history.isEmpty
              ? Center(child: Text('stock.no_history'.tr()))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.history.length,
                  itemBuilder: (context, index) {
                    final entry = provider.history[index];
                    final isIncrease = entry.quantityChange > 0;
                    final color = isIncrease ? Colors.green.shade700 : Colors.red.shade700;
                    final sign = isIncrease ? '+' : '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(_changeTypeLabel(entry.changeType)),
                        subtitle: Text(
                          '${Formatters.dateTime(DateTime.parse(entry.createdAt))}'
                          '${entry.notes != null ? '\n${entry.notes}' : ''}',
                        ),
                        isThreeLine: entry.notes != null,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$sign${entry.quantityChange.toStringAsFixed(0)}',
                              style: TextStyle(color: color, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'stock.resulting_stock'
                                  .tr(namedArgs: {'stock': entry.resultingStock.toStringAsFixed(0)}),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
