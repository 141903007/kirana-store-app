import '../database/app_database.dart';
import '../database/db_tables.dart';
import '../models/stock_history_model.dart';

/// Read-only — every write to `stock_history` happens exclusively through
/// `ProductRepository.adjustStock` (purchase/sale/manual adjustment all
/// share that one choke point), so this repository never inserts rows
/// itself.
class StockHistoryRepository {
  Future<List<StockHistoryModel>> getForProduct(int productId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      StockHistoryTable.table,
      where: '${StockHistoryTable.productId} = ?',
      whereArgs: [productId],
      orderBy: '${StockHistoryTable.createdAt} DESC, ${StockHistoryTable.id} DESC',
    );
    return rows.map(StockHistoryModel.fromMap).toList();
  }
}
