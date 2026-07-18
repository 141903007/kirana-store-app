import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants/app_constants.dart';
import '../utils/password_hasher.dart';
import 'db_tables.dart';

/// Lazily-opened singleton for the app's single SQLite database.
///
/// All repositories go through [database] to get a connection; nothing
/// outside this file should call `openDatabase` directly.
class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  /// The on-disk path of the database file — used by [BackupService] to
  /// read/overwrite the file directly. Nothing else should need this.
  Future<String> get databasePath async {
    final databasesDir = await getDatabasesPath();
    return join(databasesDir, AppConstants.databaseName);
  }

  Future<Database> _initDatabase() async {
    final dbPath = await databasePath;

    return openDatabase(
      dbPath,
      version: AppConstants.databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${UsersTable.table} (
        ${UsersTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${UsersTable.username} TEXT UNIQUE NOT NULL,
        ${UsersTable.passwordHash} TEXT NOT NULL,
        ${UsersTable.securityQuestion} TEXT,
        ${UsersTable.securityAnswerHash} TEXT,
        ${UsersTable.createdAt} TEXT NOT NULL,
        ${UsersTable.updatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${CategoriesTable.table} (
        ${CategoriesTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${CategoriesTable.name} TEXT UNIQUE NOT NULL,
        ${CategoriesTable.createdAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${ProductsTable.table} (
        ${ProductsTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${ProductsTable.name} TEXT NOT NULL,
        ${ProductsTable.categoryId} INTEGER,
        ${ProductsTable.barcode} TEXT,
        ${ProductsTable.sku} TEXT,
        ${ProductsTable.baseUnit} TEXT NOT NULL,
        ${ProductsTable.purchasePrice} REAL NOT NULL DEFAULT 0,
        ${ProductsTable.gstPercent} REAL,
        ${ProductsTable.openingStock} REAL NOT NULL DEFAULT 0,
        ${ProductsTable.currentStock} REAL NOT NULL DEFAULT 0,
        ${ProductsTable.minStockAlert} REAL NOT NULL DEFAULT 0,
        ${ProductsTable.isFavorite} INTEGER NOT NULL DEFAULT 0,
        ${ProductsTable.isActive} INTEGER NOT NULL DEFAULT 1,
        ${ProductsTable.createdAt} TEXT NOT NULL,
        ${ProductsTable.updatedAt} TEXT NOT NULL,
        FOREIGN KEY (${ProductsTable.categoryId}) REFERENCES ${CategoriesTable.table} (${CategoriesTable.id}) ON DELETE SET NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_products_name ON ${ProductsTable.table} (${ProductsTable.name})');
    await db.execute(
        'CREATE INDEX idx_products_barcode ON ${ProductsTable.table} (${ProductsTable.barcode})');
    await db.execute(
        'CREATE INDEX idx_products_category ON ${ProductsTable.table} (${ProductsTable.categoryId})');

    await db.execute('''
      CREATE TABLE ${ProductPriceVariantsTable.table} (
        ${ProductPriceVariantsTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${ProductPriceVariantsTable.productId} INTEGER NOT NULL,
        ${ProductPriceVariantsTable.label} TEXT NOT NULL,
        ${ProductPriceVariantsTable.quantityInBaseUnit} REAL NOT NULL,
        ${ProductPriceVariantsTable.sellingPrice} REAL NOT NULL,
        ${ProductPriceVariantsTable.isDefault} INTEGER NOT NULL DEFAULT 0,
        ${ProductPriceVariantsTable.isActive} INTEGER NOT NULL DEFAULT 1,
        ${ProductPriceVariantsTable.sortOrder} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${ProductPriceVariantsTable.productId}) REFERENCES ${ProductsTable.table} (${ProductsTable.id}) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_variants_product ON ${ProductPriceVariantsTable.table} (${ProductPriceVariantsTable.productId})');

    await db.execute('''
      CREATE TABLE ${CustomersTable.table} (
        ${CustomersTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${CustomersTable.name} TEXT NOT NULL,
        ${CustomersTable.mobile} TEXT,
        ${CustomersTable.address} TEXT,
        ${CustomersTable.createdAt} TEXT NOT NULL,
        ${CustomersTable.updatedAt} TEXT NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_customers_mobile ON ${CustomersTable.table} (${CustomersTable.mobile})');

    await db.execute('''
      CREATE TABLE ${PurchasesTable.table} (
        ${PurchasesTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${PurchasesTable.dealerName} TEXT NOT NULL,
        ${PurchasesTable.invoiceNumber} TEXT,
        ${PurchasesTable.purchaseDate} TEXT NOT NULL,
        ${PurchasesTable.totalAmount} REAL NOT NULL DEFAULT 0,
        ${PurchasesTable.remarks} TEXT,
        ${PurchasesTable.createdAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${PurchaseItemsTable.table} (
        ${PurchaseItemsTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${PurchaseItemsTable.purchaseId} INTEGER NOT NULL,
        ${PurchaseItemsTable.productId} INTEGER NOT NULL,
        ${PurchaseItemsTable.variantLabel} TEXT NOT NULL,
        ${PurchaseItemsTable.quantity} REAL NOT NULL,
        ${PurchaseItemsTable.conversionFactor} REAL NOT NULL,
        ${PurchaseItemsTable.pricePerUnit} REAL NOT NULL,
        ${PurchaseItemsTable.lineTotal} REAL NOT NULL,
        FOREIGN KEY (${PurchaseItemsTable.purchaseId}) REFERENCES ${PurchasesTable.table} (${PurchasesTable.id}) ON DELETE CASCADE,
        FOREIGN KEY (${PurchaseItemsTable.productId}) REFERENCES ${ProductsTable.table} (${ProductsTable.id})
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_purchase_items_purchase ON ${PurchaseItemsTable.table} (${PurchaseItemsTable.purchaseId})');
    await db.execute(
        'CREATE INDEX idx_purchase_items_product ON ${PurchaseItemsTable.table} (${PurchaseItemsTable.productId})');

    await db.execute('''
      CREATE TABLE ${SalesTable.table} (
        ${SalesTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${SalesTable.invoiceNumber} TEXT UNIQUE NOT NULL,
        ${SalesTable.customerId} INTEGER,
        ${SalesTable.saleDate} TEXT NOT NULL,
        ${SalesTable.subtotal} REAL NOT NULL DEFAULT 0,
        ${SalesTable.discountAmount} REAL NOT NULL DEFAULT 0,
        ${SalesTable.gstAmount} REAL NOT NULL DEFAULT 0,
        ${SalesTable.totalAmount} REAL NOT NULL DEFAULT 0,
        ${SalesTable.totalProfit} REAL NOT NULL DEFAULT 0,
        ${SalesTable.createdAt} TEXT NOT NULL,
        FOREIGN KEY (${SalesTable.customerId}) REFERENCES ${CustomersTable.table} (${CustomersTable.id}) ON DELETE SET NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_sales_customer ON ${SalesTable.table} (${SalesTable.customerId})');
    await db.execute(
        'CREATE INDEX idx_sales_date ON ${SalesTable.table} (${SalesTable.saleDate})');

    await db.execute('''
      CREATE TABLE ${SaleItemsTable.table} (
        ${SaleItemsTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${SaleItemsTable.saleId} INTEGER NOT NULL,
        ${SaleItemsTable.productId} INTEGER NOT NULL,
        ${SaleItemsTable.variantLabel} TEXT NOT NULL,
        ${SaleItemsTable.quantity} REAL NOT NULL,
        ${SaleItemsTable.conversionFactor} REAL NOT NULL,
        ${SaleItemsTable.unitSellingPrice} REAL NOT NULL,
        ${SaleItemsTable.unitPurchasePrice} REAL NOT NULL,
        ${SaleItemsTable.gstPercent} REAL NOT NULL DEFAULT 0,
        ${SaleItemsTable.lineTotal} REAL NOT NULL,
        ${SaleItemsTable.lineProfit} REAL NOT NULL,
        FOREIGN KEY (${SaleItemsTable.saleId}) REFERENCES ${SalesTable.table} (${SalesTable.id}) ON DELETE CASCADE,
        FOREIGN KEY (${SaleItemsTable.productId}) REFERENCES ${ProductsTable.table} (${ProductsTable.id})
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_sale_items_sale ON ${SaleItemsTable.table} (${SaleItemsTable.saleId})');
    await db.execute(
        'CREATE INDEX idx_sale_items_product ON ${SaleItemsTable.table} (${SaleItemsTable.productId})');

    await db.execute('''
      CREATE TABLE ${StockHistoryTable.table} (
        ${StockHistoryTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${StockHistoryTable.productId} INTEGER NOT NULL,
        ${StockHistoryTable.changeType} TEXT NOT NULL,
        ${StockHistoryTable.quantityChange} REAL NOT NULL,
        ${StockHistoryTable.resultingStock} REAL NOT NULL,
        ${StockHistoryTable.referenceType} TEXT,
        ${StockHistoryTable.referenceId} INTEGER,
        ${StockHistoryTable.notes} TEXT,
        ${StockHistoryTable.createdAt} TEXT NOT NULL,
        FOREIGN KEY (${StockHistoryTable.productId}) REFERENCES ${ProductsTable.table} (${ProductsTable.id}) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_stock_history_product ON ${StockHistoryTable.table} (${StockHistoryTable.productId})');

    await db.execute('''
      CREATE TABLE ${StoreSettingsTable.table} (
        ${StoreSettingsTable.id} INTEGER PRIMARY KEY,
        ${StoreSettingsTable.storeName} TEXT,
        ${StoreSettingsTable.storeAddress} TEXT,
        ${StoreSettingsTable.storePhone} TEXT,
        ${StoreSettingsTable.storeGstNumber} TEXT,
        ${StoreSettingsTable.logoPath} TEXT,
        ${StoreSettingsTable.invoicePrefix} TEXT NOT NULL DEFAULT 'INV-',
        ${StoreSettingsTable.lastInvoiceNumber} INTEGER NOT NULL DEFAULT 0,
        ${StoreSettingsTable.updatedAt} TEXT NOT NULL
      )
    ''');

    await _seedDefaults(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // No migrations yet — databaseVersion is still 1. Future schema changes
    // add `if (oldVersion < X) { ... }` blocks here.
  }

  Future<void> _seedDefaults(Database db) async {
    final now = DateTime.now().toIso8601String();

    await db.insert(UsersTable.table, {
      UsersTable.username: AppConstants.defaultUsername,
      UsersTable.passwordHash: PasswordHasher.hash(AppConstants.defaultPassword),
      UsersTable.securityQuestion: null,
      UsersTable.securityAnswerHash: null,
      UsersTable.createdAt: now,
      UsersTable.updatedAt: now,
    });

    await db.insert(StoreSettingsTable.table, {
      StoreSettingsTable.id: StoreSettingsTable.singletonId,
      StoreSettingsTable.storeName: AppConstants.appName,
      StoreSettingsTable.invoicePrefix: 'INV-',
      StoreSettingsTable.lastInvoiceNumber: 0,
      StoreSettingsTable.updatedAt: now,
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
