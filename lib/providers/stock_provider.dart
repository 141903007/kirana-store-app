import 'package:flutter/material.dart';

import '../models/stock_history_model.dart';
import '../repository/stock_history_repository.dart';

class StockProvider extends ChangeNotifier {
  StockProvider({StockHistoryRepository? stockHistoryRepository})
      : _stockHistoryRepository = stockHistoryRepository ?? StockHistoryRepository();

  final StockHistoryRepository _stockHistoryRepository;

  List<StockHistoryModel> history = [];
  bool isLoading = false;

  Future<void> loadHistory(int productId) async {
    isLoading = true;
    notifyListeners();

    history = await _stockHistoryRepository.getForProduct(productId);

    isLoading = false;
    notifyListeners();
  }
}
