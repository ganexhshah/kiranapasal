import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../features/sales/domain/models/customer.dart';
import '../../../../features/sales/domain/models/supplier.dart';
import '../app_database.dart';
import '../database_constants.dart';
import 'sync_outbox_dao.dart';

/// DAO for Customer, Supplier, and Udhar Khata Ledger database operations.
class PartyDao {
  const PartyDao();

  Database get _db => AppDatabase.instance.database;

  /// Fetch all active customers.
  Future<List<Customer>> getAllCustomers() async {
    final rows = await _db.query(
      DatabaseConstants.tableCustomers,
      where: 'is_deleted = 0',
      orderBy: 'name ASC',
    );

    return rows.map((r) {
      return Customer(
        id: r['id'] as String,
        name: r['name'] as String,
        phone: r['phone'] as String,
        address: r['address'] as String? ?? '',
        udharBalance: (r['outstanding_udhar'] as num?)?.toDouble() ?? 0.0,
        creditLimit: (r['credit_limit'] as num?)?.toDouble() ?? 10000.0,
      );
    }).toList();
  }

  /// Get single customer by ID.
  Future<Customer?> getCustomerById(String id) async {
    final rows = await _db.query(
      DatabaseConstants.tableCustomers,
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final r = rows.first;
    return Customer(
      id: r['id'] as String,
      name: r['name'] as String,
      phone: r['phone'] as String,
      address: r['address'] as String? ?? '',
      udharBalance: (r['outstanding_udhar'] as num?)?.toDouble() ?? 0.0,
      creditLimit: (r['credit_limit'] as num?)?.toDouble() ?? 10000.0,
    );
  }

  /// Upsert a customer into SQLite.
  Future<void> upsertCustomer(
    Customer customer, {
    String shopId = 'default_shop',
    bool markLocalDirty = true,
    Transaction? txn,
  }) async {
    final executor = txn ?? _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = customer.id.isNotEmpty ? customer.id : const Uuid().v4();

    await executor.rawInsert('''
      INSERT INTO ${DatabaseConstants.tableCustomers} (
        id, shop_id, name, phone, address, credit_limit, outstanding_udhar,
        is_active, is_deleted, created_at, updated_at, sync_status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 1, 0, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        phone = excluded.phone,
        address = excluded.address,
        credit_limit = excluded.credit_limit,
        outstanding_udhar = excluded.outstanding_udhar,
        updated_at = excluded.updated_at,
        sync_status = excluded.sync_status
    ''', [
      id,
      shopId,
      customer.name,
      customer.phone,
      customer.address,
      customer.creditLimit,
      customer.udharBalance,
      now,
      now,
      markLocalDirty ? DatabaseConstants.syncStatusPending : DatabaseConstants.syncStatusSynced,
    ]);
  }

  /// Batch upsert customers.
  Future<void> upsertCustomersBatch(
    List<Customer> customers, {
    String shopId = 'default_shop',
    bool markLocalDirty = false,
  }) async {
    if (customers.isEmpty) return;
    await _db.transaction((txn) async {
      for (final c in customers) {
        await upsertCustomer(c, shopId: shopId, markLocalDirty: markLocalDirty, txn: txn);
      }
    });
  }

  /// Record a customer payment against outstanding Udhar.
  Future<double> recordCustomerPayment({
    required String customerId,
    required double amount,
    String paymentMethod = 'Cash',
    String? note,
    String shopId = 'default_shop',
  }) async {
    const uuid = Uuid();
    final now = DateTime.now().millisecondsSinceEpoch;
    double newBalance = 0.0;

    await _db.transaction((txn) async {
      final rows = await txn.query(
        DatabaseConstants.tableCustomers,
        columns: ['outstanding_udhar'],
        where: 'id = ?',
        whereArgs: [customerId],
      );

      final currentUdhar = rows.isNotEmpty
          ? (rows.first['outstanding_udhar'] as num).toDouble()
          : 0.0;

      newBalance = (currentUdhar - amount).clamp(0.0, 999999.0);

      await txn.update(
        DatabaseConstants.tableCustomers,
        {
          'outstanding_udhar': newBalance,
          'updated_at': now,
          'sync_status': DatabaseConstants.syncStatusPending,
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );

      final ledgerId = uuid.v4();
      await txn.insert(DatabaseConstants.tableCustomerLedgers, {
        'id': ledgerId,
        'shop_id': shopId,
        'customer_id': customerId,
        'transaction_type': 'PAYMENT_RECEIVED',
        'reference_no': 'PAY-${DateFormat('yyMMdd').format(DateTime.now())}',
        'amount': amount,
        'balance_after': newBalance,
        'payment_method': paymentMethod,
        'note': note,
        'created_at': now,
        'sync_status': DatabaseConstants.syncStatusPending,
      });

      // Enqueue to outbox
      const outboxDao = SyncOutboxDao();
      await outboxDao.enqueue(
        shopId: shopId,
        entityType: DatabaseConstants.entityCustomerLedger,
        entityId: ledgerId,
        action: DatabaseConstants.actionCreate,
        payload: {
          'customer_id': customerId,
          'amount': amount,
          'payment_method': paymentMethod,
          'note': note,
          'balance_after': newBalance,
          'created_at': now,
        },
        txn: txn,
      );
    });

    return newBalance;
  }

  /// Fetch all suppliers.
  Future<List<Supplier>> getAllSuppliers() async {
    final rows = await _db.query(
      DatabaseConstants.tableSuppliers,
      where: 'is_deleted = 0',
      orderBy: 'name ASC',
    );

    return rows.map((r) {
      return Supplier(
        id: r['id'] as String,
        name: r['name'] as String,
        phone: r['phone'] as String,
        address: r['address'] as String? ?? '',
        panNumber: r['pan_number'] as String? ?? '',
        outstandingBalance: (r['outstanding_payable'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  /// Upsert a supplier into SQLite.
  Future<void> upsertSupplier(
    Supplier supplier, {
    String shopId = 'default_shop',
    bool markLocalDirty = true,
    Transaction? txn,
  }) async {
    final executor = txn ?? _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = supplier.id.isNotEmpty ? supplier.id : const Uuid().v4();

    await executor.rawInsert('''
      INSERT INTO ${DatabaseConstants.tableSuppliers} (
        id, shop_id, name, company_name, phone, pan_number, address,
        outstanding_payable, is_deleted, created_at, updated_at, sync_status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        company_name = excluded.company_name,
        phone = excluded.phone,
        pan_number = excluded.pan_number,
        address = excluded.address,
        outstanding_payable = excluded.outstanding_payable,
        updated_at = excluded.updated_at,
        sync_status = excluded.sync_status
    ''', [
      id,
      shopId,
      supplier.name,
      supplier.name,
      supplier.phone,
      supplier.panNumber,
      supplier.address,
      supplier.outstandingBalance,
      now,
      now,
      markLocalDirty ? DatabaseConstants.syncStatusPending : DatabaseConstants.syncStatusSynced,
    ]);
  }

  /// Batch upsert suppliers.
  Future<void> upsertSuppliersBatch(
    List<Supplier> suppliers, {
    String shopId = 'default_shop',
    bool markLocalDirty = false,
  }) async {
    if (suppliers.isEmpty) return;
    await _db.transaction((txn) async {
      for (final s in suppliers) {
        await upsertSupplier(s, shopId: shopId, markLocalDirty: markLocalDirty, txn: txn);
      }
    });
  }
}
