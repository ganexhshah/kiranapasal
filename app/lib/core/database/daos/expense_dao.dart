import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../app_database.dart';
import '../database_constants.dart';
import 'sync_outbox_dao.dart';

/// DAO for Expense recording and offline tracking.
class ExpenseDao {
  const ExpenseDao();

  Database get _db => AppDatabase.instance.database;

  /// Fetch all active expenses sorted by date descending.
  Future<List<Map<String, dynamic>>> getAllExpenses({int limit = 100}) async {
    return _db.query(
      DatabaseConstants.tableExpenses,
      where: 'is_deleted = 0',
      orderBy: 'expense_date DESC',
      limit: limit,
    );
  }

  /// Record an expense locally and queue for background sync.
  Future<String> recordExpense({
    required String title,
    required double amount,
    required String categoryName,
    String paymentMethod = 'Cash',
    String? note,
    String? receiptImagePath,
    DateTime? expenseDate,
    String shopId = 'default_shop',
  }) async {
    final expenseId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final dateMillis = (expenseDate ?? DateTime.now()).millisecondsSinceEpoch;

    await _db.transaction((txn) async {
      await txn.insert(DatabaseConstants.tableExpenses, {
        'id': expenseId,
        'shop_id': shopId,
        'category_name': categoryName,
        'title': title,
        'amount': amount,
        'payment_method': paymentMethod,
        'receipt_image_path': receiptImagePath,
        'note': note,
        'expense_date': dateMillis,
        'is_deleted': 0,
        'created_at': now,
        'updated_at': now,
        'sync_status': DatabaseConstants.syncStatusPending,
      });

      const outboxDao = SyncOutboxDao();
      await outboxDao.enqueue(
        shopId: shopId,
        entityType: DatabaseConstants.entityExpense,
        entityId: expenseId,
        action: DatabaseConstants.actionCreate,
        payload: {
          'id': expenseId,
          'title': title,
          'amount': amount,
          'category': categoryName,
          'payment_method': paymentMethod,
          'note': note,
          'expense_date': dateMillis,
        },
        txn: txn,
      );
    });

    return expenseId;
  }
}
