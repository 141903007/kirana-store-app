/// Snapshot of the numbers shown on the Dashboard. Populated with real data
/// by [DashboardProvider] once `report_repository` exists (later module) —
/// until then every screen just renders [DashboardSummary.zero].
class DashboardSummary {
  final double todaySales;
  final double todayPurchase;
  final double todayProfit;
  final double todayLoss;
  final double stockValue;
  final int lowStockCount;
  final int outOfStockCount;
  final int totalProducts;
  final int totalCustomers;

  const DashboardSummary({
    required this.todaySales,
    required this.todayPurchase,
    required this.todayProfit,
    required this.todayLoss,
    required this.stockValue,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalProducts,
    required this.totalCustomers,
  });

  factory DashboardSummary.zero() {
    return const DashboardSummary(
      todaySales: 0,
      todayPurchase: 0,
      todayProfit: 0,
      todayLoss: 0,
      stockValue: 0,
      lowStockCount: 0,
      outOfStockCount: 0,
      totalProducts: 0,
      totalCustomers: 0,
    );
  }
}
