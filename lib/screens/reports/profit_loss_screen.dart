import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/reports_provider.dart';
import '../../repository/report_repository.dart';
import '../../utils/formatters.dart';
import '../../widgets/stat_card.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ReportsProvider>().loadForPeriod(ReportPeriod.day),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('reports.profit_loss_title'.tr())),
      body: SafeArea(
        child: provider.isLoading && provider.dailyTrend.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SegmentedButton<ReportPeriod>(
                    segments: [
                      for (final period in ReportPeriod.values)
                        ButtonSegment(value: period, label: Text(_periodLabel(period))),
                    ],
                    selected: {provider.period},
                    onSelectionChanged: (selection) =>
                        provider.loadForPeriod(selection.first),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      StatCard(
                        icon: Icons.trending_up,
                        label: 'dashboard.todays_profit'.tr(),
                        value: Formatters.currency(provider.summary.profit),
                        valueColor: Colors.green.shade600,
                        backgroundColor: Colors.green.withValues(alpha: 0.12),
                      ),
                      StatCard(
                        icon: Icons.trending_down,
                        label: 'dashboard.todays_loss'.tr(),
                        value: Formatters.currency(provider.summary.loss),
                        valueColor: Colors.red.shade600,
                        backgroundColor: Colors.red.withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'reports.net_profit'.tr(),
                    value: Formatters.currency(provider.summary.netProfit),
                    valueColor: provider.summary.netProfit >= 0
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                  ),
                  const SizedBox(height: 24),
                  if (provider.dailyTrend.isNotEmpty) ...[
                    Text('reports.daily_trend'.tr(),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(height: 200, child: _TrendChart(points: provider.dailyTrend)),
                    const SizedBox(height: 24),
                  ],
                  Text('reports.profit_per_product'.tr(),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (provider.profitPerProduct.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('reports.no_data'.tr()),
                    )
                  else
                    for (final item in provider.profitPerProduct)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item.productName),
                          trailing: Text(
                            Formatters.currency(item.profit),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: item.profit >= 0
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: 24),
                  Text('reports.profit_per_bill'.tr(),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (provider.profitPerBill.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('reports.no_data'.tr()),
                    )
                  else
                    for (final bill in provider.profitPerBill)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(bill.invoiceNumber),
                          subtitle: Text(Formatters.date(DateTime.parse(bill.saleDate))),
                          trailing: Text(
                            Formatters.currency(bill.profit),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: bill.profit >= 0
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<DailyProfitPoint> points;

  const _TrendChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxValue = points
        .map((p) => p.profit > p.loss ? p.profit : p.loss)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue == 0 ? 10 : maxValue * 1.2,
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(toY: points[i].profit, color: Colors.green, width: 8),
                BarChartRodData(toY: points[i].loss, color: Colors.red, width: 8),
              ],
              barsSpace: 4,
            ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    points[index].date.day.toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }
}
