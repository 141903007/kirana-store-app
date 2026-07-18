/// Single implementation of `profit = selling - purchase`, used both when
/// a sale is written (snapshotting `sale_items.line_profit`) and later when
/// reports aggregate profit — so the formula never gets reimplemented ad
/// hoc in a provider or widget.
class ProfitCalculationService {
  ProfitCalculationService._();

  /// [lineTaxable] is the line's revenue after discount but before GST
  /// (GST isn't revenue, so it never enters a profit calculation).
  static double lineProfit({
    required double lineTaxable,
    required double quantity,
    required double conversionFactor,
    required double unitPurchasePrice,
  }) {
    final costOfGoods = quantity * conversionFactor * unitPurchasePrice;
    return lineTaxable - costOfGoods;
  }

  static double billProfit(List<double> lineProfits) {
    return lineProfits.fold(0, (sum, profit) => sum + profit);
  }
}
