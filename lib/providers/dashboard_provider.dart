import 'package:flutter/material.dart';

import '../models/dashboard_summary.dart';

/// Feeds the Dashboard's stat cards. Currently always [DashboardSummary.zero]
/// — a later module wires this to `report_repository.getTodaySummary()` and
/// adds a `loadToday()` method, without the Dashboard screen itself changing.
class DashboardProvider extends ChangeNotifier {
  DashboardSummary summary = DashboardSummary.zero();
}
