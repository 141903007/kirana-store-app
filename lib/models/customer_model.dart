import '../database/db_tables.dart';

class CustomerModel {
  final int? id;
  final String name;
  final String? mobile;
  final String? address;
  final String createdAt;
  final String updatedAt;

  const CustomerModel({
    this.id,
    required this.name,
    this.mobile,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  CustomerModel copyWith({
    int? id,
    String? name,
    String? mobile,
    String? address,
    String? createdAt,
    String? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      CustomersTable.id: id,
      CustomersTable.name: name,
      CustomersTable.mobile: mobile,
      CustomersTable.address: address,
      CustomersTable.createdAt: createdAt,
      CustomersTable.updatedAt: updatedAt,
    };
  }

  factory CustomerModel.fromMap(Map<String, Object?> map) {
    return CustomerModel(
      id: map[CustomersTable.id] as int?,
      name: map[CustomersTable.name] as String,
      mobile: map[CustomersTable.mobile] as String?,
      address: map[CustomersTable.address] as String?,
      createdAt: map[CustomersTable.createdAt] as String,
      updatedAt: map[CustomersTable.updatedAt] as String,
    );
  }
}
