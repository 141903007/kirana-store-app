import '../database/db_tables.dart';

/// Single-row table holding shop info and invoice numbering state.
/// Always read/written at [StoreSettingsTable.singletonId].
class StoreSettingsModel {
  final int id;
  final String? storeName;
  final String? storeAddress;
  final String? storePhone;
  final String? storeGstNumber;
  final String? logoPath;
  final String invoicePrefix;
  final int lastInvoiceNumber;
  final String updatedAt;

  const StoreSettingsModel({
    this.id = StoreSettingsTable.singletonId,
    this.storeName,
    this.storeAddress,
    this.storePhone,
    this.storeGstNumber,
    this.logoPath,
    this.invoicePrefix = 'INV-',
    this.lastInvoiceNumber = 0,
    required this.updatedAt,
  });

  StoreSettingsModel copyWith({
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? storeGstNumber,
    String? logoPath,
    String? invoicePrefix,
    int? lastInvoiceNumber,
    String? updatedAt,
  }) {
    return StoreSettingsModel(
      id: id,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
      storeGstNumber: storeGstNumber ?? this.storeGstNumber,
      logoPath: logoPath ?? this.logoPath,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      lastInvoiceNumber: lastInvoiceNumber ?? this.lastInvoiceNumber,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      StoreSettingsTable.id: id,
      StoreSettingsTable.storeName: storeName,
      StoreSettingsTable.storeAddress: storeAddress,
      StoreSettingsTable.storePhone: storePhone,
      StoreSettingsTable.storeGstNumber: storeGstNumber,
      StoreSettingsTable.logoPath: logoPath,
      StoreSettingsTable.invoicePrefix: invoicePrefix,
      StoreSettingsTable.lastInvoiceNumber: lastInvoiceNumber,
      StoreSettingsTable.updatedAt: updatedAt,
    };
  }

  factory StoreSettingsModel.fromMap(Map<String, Object?> map) {
    return StoreSettingsModel(
      id: map[StoreSettingsTable.id] as int,
      storeName: map[StoreSettingsTable.storeName] as String?,
      storeAddress: map[StoreSettingsTable.storeAddress] as String?,
      storePhone: map[StoreSettingsTable.storePhone] as String?,
      storeGstNumber: map[StoreSettingsTable.storeGstNumber] as String?,
      logoPath: map[StoreSettingsTable.logoPath] as String?,
      invoicePrefix: map[StoreSettingsTable.invoicePrefix] as String,
      lastInvoiceNumber: map[StoreSettingsTable.lastInvoiceNumber] as int,
      updatedAt: map[StoreSettingsTable.updatedAt] as String,
    );
  }
}
