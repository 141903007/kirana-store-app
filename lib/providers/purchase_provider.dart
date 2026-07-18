import 'package:flutter/material.dart';

import '../models/product_price_variant_model.dart';
import '../models/purchase_item_model.dart';
import '../models/purchase_model.dart';
import '../repository/product_repository.dart';
import '../repository/purchase_repository.dart';

class PurchaseProvider extends ChangeNotifier {
  PurchaseProvider({
    PurchaseRepository? purchaseRepository,
    ProductRepository? productRepository,
  })  : _purchaseRepository = purchaseRepository ?? PurchaseRepository(),
        _productRepository = productRepository ?? ProductRepository();

  final PurchaseRepository _purchaseRepository;
  final ProductRepository _productRepository;

  List<PurchaseListItem> purchases = [];
  bool isLoading = false;

  Future<void> loadPurchases() async {
    isLoading = true;
    notifyListeners();

    purchases = await _purchaseRepository.getAll();

    isLoading = false;
    notifyListeners();
  }

  Future<List<ProductListItem>> searchProducts(String query) {
    return _productRepository.search(query: query);
  }

  Future<List<ProductPriceVariantModel>> getVariants(int productId) {
    return _productRepository.getVariants(productId);
  }

  Future<List<PurchaseItemDetail>> loadItemsForDetail(int purchaseId) {
    return _purchaseRepository.getItemsForPurchase(purchaseId);
  }

  Future<void> savePurchase({
    required PurchaseModel purchase,
    required List<PurchaseItemModel> items,
  }) async {
    await _purchaseRepository.createPurchase(purchase: purchase, items: items);
    await loadPurchases();
  }
}
