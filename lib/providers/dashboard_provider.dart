import 'package:flutter/material.dart';

import '../models/dashboard_summary.dart';
import '../repository/report_repository.dart';

/// Feeds the Dashboard's stat cards from `report_repository.getTodaySummary()`.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider({ReportRepository? reportRepository})
      : _reportRepository = reportRepository ?? ReportRepository();

  final ReportRepository _reportRepository;

  DashboardSummary summary = DashboardSummary.zero();
  bool isLoading = false;

  Future<void> loadToday() async {
    isLoading = true;
    notifyListeners();

    summary = await _reportRepository.getTodaySummary();

    isLoading = false;
    notifyListeners();
  }
}
