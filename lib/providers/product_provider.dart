import 'package:flutter/material.dart';

import '../database/db_tables.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_price_variant_model.dart';
import '../repository/category_repository.dart';
import '../repository/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({
    ProductRepository? productRepository,
    CategoryRepository? categoryRepository,
  })  : _productRepository = productRepository ?? ProductRepository(),
        _categoryRepository = categoryRepository ?? CategoryRepository();

  final ProductRepository _productRepository;
  final CategoryRepository _categoryRepository;

  List<ProductListItem> items = [];
  List<CategoryModel> categories = [];

  String searchQuery = '';
  int? categoryFilterId;
  bool lowStockOnly = false;
  bool outOfStockOnly = false;
  bool favoritesOnly = false;
  bool includeInactive = false;

  bool isLoading = false;
  String? errorMessage;

  Future<void> loadCategories() async {
    categories = await _categoryRepository.getAll();
    notifyListeners();
  }

  Future<void> loadProducts() async {
    isLoading = true;
    notifyListeners();

    items = await _productRepository.search(
      query: searchQuery,
      categoryId: categoryFilterId,
      lowStockOnly: lowStockOnly,
      outOfStockOnly: outOfStockOnly,
      favoritesOnly: favoritesOnly,
      includeInactive: includeInactive,
    );

    isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    loadProducts();
  }

  void setCategoryFilter(int? categoryId) {
    categoryFilterId = categoryId;
    loadProducts();
  }

  void setLowStockOnly(bool value) {
    lowStockOnly = value;
    loadProducts();
  }

  void setOutOfStockOnly(bool value) {
    outOfStockOnly = value;
    loadProducts();
  }

  void setFavoritesOnly(bool value) {
    favoritesOnly = value;
    loadProducts();
  }

  void setIncludeInactive(bool value) {
    includeInactive = value;
    loadProducts();
  }

  /// Resets every filter to its default, then applies exactly one — used
  /// by Dashboard's stock-alert cards so jumping there never combines with
  /// a stale filter left over from a previous visit to the Products list.
  void applyQuickFilter({bool lowStockOnly = false, bool outOfStockOnly = false}) {
    searchQuery = '';
    categoryFilterId = null;
    this.lowStockOnly = lowStockOnly;
    this.outOfStockOnly = outOfStockOnly;
    favoritesOnly = false;
    includeInactive = false;
    loadProducts();
  }

  Future<({ProductModel product, List<ProductPriceVariantModel> variants})?>
      loadForEdit(int id) async {
    final product = await _productRepository.getById(id);
    if (product == null) return null;
    final variants = await _productRepository.getVariants(id);
    return (product: product, variants: variants);
  }

  Future<bool> isBarcodeTaken(String barcode, {int? excludingProductId}) {
    return _productRepository.isBarcodeTaken(barcode, excludingProductId: excludingProductId);
  }

  /// Validates "at least one variant" before hitting the repository, then
  /// inserts/updates the product and replaces its price variants.
  Future<bool> saveProduct({
    required ProductModel product,
    required List<ProductPriceVariantModel> variants,
  }) async {
    if (variants.isEmpty) {
      errorMessage = 'products.at_least_one_price_required';
      notifyListeners();
      return false;
    }

    errorMessage = null;
    int productId;
    if (product.id == null) {
      productId = await _productRepository.insertProduct(product);
    } else {
      productId = product.id!;
      await _productRepository.updateProduct(product);
    }

    final variantsForProduct = variants
        .map((variant) => variant.copyWith(productId: productId))
        .toList();
    await _productRepository.replaceVariants(productId, variantsForProduct);

    await loadProducts();
    return true;
  }

  Future<void> adjustCurrentStock(int productId, double newValue, double oldValue) async {
    final delta = newValue - oldValue;
    if (delta == 0) return;
    await _productRepository.adjustStock(
      productId,
      delta,
      StockChangeType.adjustment,
      notes: 'Manual correction via Edit Product',
    );
    await loadProducts();
  }

  Future<void> setActive(int id, bool isActive) async {
    await _productRepository.setActive(id, isActive);
    await loadProducts();
  }

  Future<void> toggleFavorite(ProductModel product) async {
    await _productRepository.toggleFavorite(product.id!, !product.isFavorite);
    await loadProducts();
  }

  Future<CategoryModel> createCategory(String name) async {
    final category = await _categoryRepository.getOrCreate(name);
    await loadCategories();
    return category;
  }

  CategoryModel? categoryFor(int? id) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }
}
