import '../database/app_database.dart';
import '../database/db_tables.dart';
import '../models/category_model.dart';

class CategoryRepository {
  Future<List<CategoryModel>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(CategoriesTable.table, orderBy: CategoriesTable.name);
    return rows.map(CategoryModel.fromMap).toList();
  }

  /// Case-insensitive get-or-create, so "Snacks" and "snacks" resolve to the
  /// same row instead of tripping the table's UNIQUE constraint.
  Future<CategoryModel> getOrCreate(String name) async {
    final db = await AppDatabase.instance.database;
    final trimmed = name.trim();

    final existing = await db.query(
      CategoriesTable.table,
      where: '${CategoriesTable.name} = ? COLLATE NOCASE',
      whereArgs: [trimmed],
      limit: 1,
    );
    if (existing.isNotEmpty) return CategoryModel.fromMap(existing.first);

    final id = await db.insert(CategoriesTable.table, {
      CategoriesTable.name: trimmed,
      CategoriesTable.createdAt: DateTime.now().toIso8601String(),
    });
    return CategoryModel(id: id, name: trimmed, createdAt: DateTime.now().toIso8601String());
  }
}
