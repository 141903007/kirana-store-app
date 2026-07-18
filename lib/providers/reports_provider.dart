import 'package:flutter/material.dart';

import '../repository/report_repository.dart';

enum ReportPeriod { day, month, year }

class ReportsProvider extends ChangeNotifier {
  ReportsProvider({ReportRepository? reportRepository})
      : _reportRepository = reportRepository ?? ReportRepository();

  final ReportRepository _reportRepository;

  ReportPeriod period = ReportPeriod.day;
  ProfitLossSummary summary = const ProfitLossSummary(profit: 0, loss: 0);
  List<DailyProfitPoint> dailyTrend = [];
  List<ProductProfitItem> profitPerProduct = [];
  List<BillProfitItem> profitPerBill = [];
  bool isLoading = false;

  ReportPeriod salesReportPeriod = ReportPeriod.day;
  List<SaleReportItem> salesReport = [];
  bool isLoadingSalesReport = false;

  (DateTime, DateTime) rangeFor(ReportPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.day:
        return (now, now);
      case ReportPeriod.month:
        return (DateTime(now.year, now.month, 1), now);
      case ReportPeriod.year:
        return (DateTime(now.year, 1, 1), now);
    }
  }

  Future<void> loadForPeriod(ReportPeriod newPeriod) async {
    period = newPeriod;
    isLoading = true;
    notifyListeners();

    final (from, to) = rangeFor(newPeriod);
    final results = await Future.wait([
      _reportRepository.getProfitLossSummary(from, to),
      _reportRepository.getDailyProfitTrend(from, to),
      _reportRepository.getProfitPerProduct(from, to),
      _reportRepository.getProfitPerBill(from, to),
    ]);

    summary = results[0] as ProfitLossSummary;
    dailyTrend = results[1] as List<DailyProfitPoint>;
    profitPerProduct = results[2] as List<ProductProfitItem>;
    profitPerBill = results[3] as List<BillProfitItem>;

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadSalesReport(ReportPeriod newPeriod) async {
    salesReportPeriod = newPeriod;
    isLoadingSalesReport = true;
    notifyListeners();

    final (from, to) = rangeFor(newPeriod);
    salesReport = await _reportRepository.getSalesForRange(from, to);

    isLoadingSalesReport = false;
    notifyListeners();
  }
}
