import 'package:flutter/material.dart';

enum StockBadgeLevel { outOfStock, low, normal }

/// Small color-coded pill showing a stock level. Generic enough to reuse
/// outside Products (e.g. Reports, Stock screens later).
class StockBadge extends StatelessWidget {
  final StockBadgeLevel level;
  final String label;

  const StockBadge({super.key, required this.level, required this.label});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (level) {
      case StockBadgeLevel.outOfStock:
        color = Colors.red.shade700;
        break;
      case StockBadgeLevel.low:
        color = Colors.orange.shade700;
        break;
      case StockBadgeLevel.normal:
        color = Theme.of(context).colorScheme.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
