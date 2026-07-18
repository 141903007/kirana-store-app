import 'package:flutter/material.dart';

import '../models/product_price_variant_model.dart';
import '../models/sale_model.dart';
import '../repository/product_repository.dart';
import '../repository/sale_repository.dart';

/// One line in the in-progress cart. Not a DB model — turned into a
/// [SaleItemInput] only at checkout.
class CartLine {
  final int productId;
  final String productName;
  final String variantLabel;
  final double conversionFactor;
  final double unitSellingPrice;
  final double unitPurchasePrice;
  final double gstPercent;
  final double currentStock;
  final String baseUnitLabel;
  final double quantity;

  const CartLine({
    required this.productId,
    required this.productName,
    required this.variantLabel,
    required this.conversionFactor,
    required this.unitSellingPrice,
    required this.unitPurchasePrice,
    required this.gstPercent,
    required this.currentStock,
    required this.baseUnitLabel,
    required this.quantity,
  });

  CartLine copyWith({double? quantity}) {
    return CartLine(
      productId: productId,
      productName: productName,
      variantLabel: variantLabel,
      conversionFactor: conversionFactor,
      unitSellingPrice: unitSellingPrice,
      unitPurchasePrice: unitPurchasePrice,
      gstPercent: gstPercent,
      currentStock: currentStock,
      baseUnitLabel: baseUnitLabel,
      quantity: quantity ?? this.quantity,
    );
  }

  double get lineSubtotal => quantity * unitSellingPrice;

  /// Stock is frequently approximate in a real shop (loose/weighed goods),
  /// so this only drives a warning — checkout is never blocked on it.
  bool get exceedsStock => (quantity * conversionFactor) > currentStock;
}

class SalesProvider extends ChangeNotifier {
  SalesProvider({
    ProductRepository? productRepository,
    SaleRepository? saleRepository,
  })  : _productRepository = productRepository ?? ProductRepository(),
        _saleRepository = saleRepository ?? SaleRepository();

  final ProductRepository _productRepository;
  final SaleRepository _saleRepository;

  List<CartLine> cart = [];
  int? selectedCustomerId;
  String? selectedCustomerName;
  double discountPercent = 0;

  Future<List<ProductListItem>> searchProducts(String query) {
    return _productRepository.search(query: query);
  }

  Future<List<ProductPriceVariantModel>> getVariants(int productId) {
    return _productRepository.getVariants(productId);
  }

  Future<List<SaleItemDetail>> getItemsForSale(int saleId) {
    return _saleRepository.getItemsForSale(saleId);
  }

  void addToCart(CartLine line) {
    final existingIndex = cart.indexWhere(
      (c) => c.productId == line.productId && c.variantLabel == line.variantLabel,
    );
    if (existingIndex != -1) {
      cart[existingIndex] =
          cart[existingIndex].copyWith(quantity: cart[existingIndex].quantity + line.quantity);
    } else {
      cart.add(line);
    }
    notifyListeners();
  }

  void updateQuantity(int index, double quantity) {
    cart[index] = cart[index].copyWith(quantity: quantity);
    notifyListeners();
  }

  void removeFromCart(int index) {
    cart.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    cart = [];
    selectedCustomerId = null;
    selectedCustomerName = null;
    discountPercent = 0;
    notifyListeners();
  }

  void setDiscountPercent(double percent) {
    discountPercent = percent;
    notifyListeners();
  }

  void setCustomer(int? customerId, String? customerName) {
    selectedCustomerId = customerId;
    selectedCustomerName = customerName;
    notifyListeners();
  }

  double get subtotal => cart.fold(0, (sum, line) => sum + line.lineSubtotal);

  double get discountAmount => subtotal * discountPercent / 100;

  double get gstAmount {
    double total = 0;
    for (final line in cart) {
      final lineDiscount = line.lineSubtotal * discountPercent / 100;
      final lineTaxable = line.lineSubtotal - lineDiscount;
      total += lineTaxable * line.gstPercent / 100;
    }
    return total;
  }

  double get total => subtotal - discountAmount + gstAmount;

  Future<SaleModel> checkout() async {
    final items = cart
        .map((line) => SaleItemInput(
              productId: line.productId,
              variantLabel: line.variantLabel,
              conversionFactor: line.conversionFactor,
              quantity: line.quantity,
              unitSellingPrice: line.unitSellingPrice,
              unitPurchasePrice: line.unitPurchasePrice,
              gstPercent: line.gstPercent,
            ))
        .toList();

    final sale = await _saleRepository.createSale(
      items: items,
      customerId: selectedCustomerId,
      discountPercent: discountPercent,
      saleDate: DateTime.now().toIso8601String(),
    );

    clearCart();
    return sale;
  }
}
