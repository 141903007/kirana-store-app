import '../database/db_tables.dart';

class CategoryModel {
  final int? id;
  final String name;
  final String createdAt;

  const CategoryModel({this.id, required this.name, required this.createdAt});

  CategoryModel copyWith({int? id, String? name, String? createdAt}) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      CategoriesTable.id: id,
      CategoriesTable.name: name,
      CategoriesTable.createdAt: createdAt,
    };
  }

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map[CategoriesTable.id] as int?,
      name: map[CategoriesTable.name] as String,
      createdAt: map[CategoriesTable.createdAt] as String,
    );
  }
}
