/// Table and column name constants for the SQLite schema.
///
/// Kept as string constants (mirroring [AppConstants]'s private-constructor
/// pattern) so every repository references the same literal instead of
/// re-typing column names, which is where schema typos usually creep in.
library;

class UsersTable {
  UsersTable._();

  static const String table = 'users';
  static const String id = 'id';
  static const String username = 'username';
  static const String passwordHash = 'password_hash';
  static const String securityQuestion = 'security_question';
  static const String securityAnswerHash = 'security_answer_hash';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

class CategoriesTable {
  CategoriesTable._();

  static const String table = 'categories';
  static const String id = 'id';
  static const String name = 'name';
  static const String createdAt = 'created_at';
}

class ProductsTable {
  ProductsTable._();

  static const String table = 'products';
  static const String id = 'id';
  static const String name = 'name';
  static const String categoryId = 'category_id';
  static const String barcode = 'barcode';
  static const String sku = 'sku';
  static const String baseUnit = 'base_unit';
  static const String purchasePrice = 'purchase_price';
  static const String gstPercent = 'gst_percent';
  static const String openingStock = 'opening_stock';
  static const String currentStock = 'current_stock';
  static const String minStockAlert = 'min_stock_alert';
  static const String isFavorite = 'is_favorite';
  static const String isActive = 'is_active';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

class ProductPriceVariantsTable {
  ProductPriceVariantsTable._();

  static const String table = 'product_price_variants';
  static const String id = 'id';
  static const String productId = 'product_id';
  static const String label = 'label';
  static const String quantityInBaseUnit = 'quantity_in_base_unit';
  static const String sellingPrice = 'selling_price';
  static const String isDefault = 'is_default';
  static const String isActive = 'is_active';
  static const String sortOrder = 'sort_order';
}

class CustomersTable {
  CustomersTable._();

  static const String table = 'customers';
  static const String id = 'id';
  static const String name = 'name';
  static const String mobile = 'mobile';
  static const String address = 'address';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

class PurchasesTable {
  PurchasesTable._();

  static const String table = 'purchases';
  static const String id = 'id';
  static const String dealerName = 'dealer_name';
  static const String invoiceNumber = 'invoice_number';
  static const String purchaseDate = 'purchase_date';
  static const String totalAmount = 'total_amount';
  static const String remarks = 'remarks';
  static const String createdAt = 'created_at';
}

class PurchaseItemsTable {
  PurchaseItemsTable._();

  static const String table = 'purchase_items';
  static const String id = 'id';
  static const String purchaseId = 'purchase_id';
  static const String productId = 'product_id';
  static const String variantLabel = 'variant_label';
  static const String quantity = 'quantity';
  static const String conversionFactor = 'conversion_factor';
  static const String pricePerUnit = 'price_per_unit';
  static const String lineTotal = 'line_total';
}

class SalesTable {
  SalesTable._();

  static const String table = 'sales';
  static const String id = 'id';
  static const String invoiceNumber = 'invoice_number';
  static const String customerId = 'customer_id';
  static const String saleDate = 'sale_date';
  static const String subtotal = 'subtotal';
  static const String discountAmount = 'discount_amount';
  static const String gstAmount = 'gst_amount';
  static const String totalAmount = 'total_amount';
  static const String totalProfit = 'total_profit';
  static const String createdAt = 'created_at';
}

class SaleItemsTable {
  SaleItemsTable._();

  static const String table = 'sale_items';
  static const String id = 'id';
  static const String saleId = 'sale_id';
  static const String productId = 'product_id';
  static const String variantLabel = 'variant_label';
  static const String quantity = 'quantity';
  static const String conversionFactor = 'conversion_factor';
  static const String unitSellingPrice = 'unit_selling_price';
  static const String unitPurchasePrice = 'unit_purchase_price';
  static const String gstPercent = 'gst_percent';
  static const String lineTotal = 'line_total';
  static const String lineProfit = 'line_profit';
}

/// Change types recorded in [StockHistoryTable].
class StockChangeType {
  StockChangeType._();

  static const String purchase = 'purchase';
  static const String sale = 'sale';
  static const String adjustment = 'adjustment';
  static const String opening = 'opening';
}

class StockHistoryTable {
  StockHistoryTable._();

  static const String table = 'stock_history';
  static const String id = 'id';
  static const String productId = 'product_id';
  static const String changeType = 'change_type';
  static const String quantityChange = 'quantity_change';
  static const String resultingStock = 'resulting_stock';
  static const String referenceType = 'reference_type';
  static const String referenceId = 'reference_id';
  static const String notes = 'notes';
  static const String createdAt = 'created_at';
}

/// Single-row table (row id is always [StoreSettingsTable.singletonId]).
class StoreSettingsTable {
  StoreSettingsTable._();

  static const String table = 'store_settings';
  static const int singletonId = 1;

  static const String id = 'id';
  static const String storeName = 'store_name';
  static const String storeAddress = 'store_address';
  static const String storePhone = 'store_phone';
  static const String storeGstNumber = 'store_gst_number';
  static const String logoPath = 'logo_path';
  static const String invoicePrefix = 'invoice_prefix';
  static const String lastInvoiceNumber = 'last_invoice_number';
  static const String updatedAt = 'updated_at';
}
