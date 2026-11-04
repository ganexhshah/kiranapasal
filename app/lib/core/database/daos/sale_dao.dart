import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../features/sales/domain/models/cart_item.dart';
import '../../../../features/sales/presentation/screens/today_bills_screen.dart';
import '../../../../features/sales/presentation/screens/transaction_details_screen.dart';
import '../../../../features/sales/presentation/screens/transactions_screen.dart';
import '../app_database.dart';
import '../database_constants.dart';
import 'product_dao.dart';
import 'sync_outbox_dao.dart';

/// DAO for complete offline sales, invoices, and payments.
class SaleDao {
  const SaleDao();

  Database get _db => AppDatabase.instance.database;

  /// Generate a collision-free offline receipt number.
  Future<String> _generateReceiptNumber(Transaction txn, {String devicePrefix = 'D1'}) async {
    final countResult = await txn.rawQuery('SELECT COUNT(*) as cnt FROM ${DatabaseConstants.tableSales}');
    final nextSeq = (Sqflite.firstIntValue(countResult) ?? 0) + 1;
    final ym = DateFormat('yyMM').format(DateTime.now());
    return 'INV-$ym-$devicePrefix-${nextSeq.toString().padLeft(5, '0')}';
  }

  /// Record a complete sale atomically in an ACID SQLite transaction.
  /// 1. Inserts into sales
  /// 2. Inserts into sale_items
  /// 3. Updates product stock and records stock_movements
  /// 4. Inserts into payments
  /// 5. Records customer udhar if credit was extended
  /// 6. Enqueues mutation to sync_outbox
  Future<Map<String, dynamic>> createSale({
    required List<CartItem> items,
    required double subtotal,
    required double grandTotal,
    required String paymentMethod, // 'Cash', 'Fonepay QR', 'Card', 'Credit (Udhar)'
    double discount = 0.0,
    String discountType = 'fixed',
    double taxAmount = 0.0,
    double taxPercentage = 0.0,
    double cashReceived = 0.0,
    double changeReturned = 0.0,
    double udharAmount = 0.0,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? cashierName,
    String? note,
    String shopId = 'default_shop',
  }) async {
    const uuid = Uuid();
    final saleId = uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    String finalReceiptNumber = '';

    await _db.transaction((txn) async {
      finalReceiptNumber = await _generateReceiptNumber(txn);

      final paymentStatus = udharAmount > 0
          ? (grandTotal == udharAmount ? 'CREDIT' : 'PARTIAL')
          : 'PAID';

      // 1. Insert into sales table
      await txn.insert(DatabaseConstants.tableSales, {
        'id': saleId,
        'shop_id': shopId,
        'receipt_number': finalReceiptNumber,
        'customer_id': customerId,
        'cashier_id': null,
        'cashier_name': cashierName ?? 'Cashier',
        'subtotal': subtotal,
        'discount_type': discountType,
        'discount_amount': discount,
        'tax_percentage': taxPercentage,
        'tax_amount': taxAmount,
        'grand_total': grandTotal,
        'payment_status': paymentStatus,
        'primary_payment_method': paymentMethod,
        'cash_tendered': cashReceived,
        'change_returned': changeReturned,
        'udhar_amount': udharAmount,
        'items_count': items.length,
        'note': note,
        'is_cancelled': 0,
        'created_at': now,
        'updated_at': now,
        'sync_status': DatabaseConstants.syncStatusPending,
      });

      // 2. Insert line items & deduct stock
      const productDao = ProductDao();
      final List<Map<String, dynamic>> itemsPayload = [];

      for (final item in items) {
        final itemId = uuid.v4();
        final lineTotal = item.totalPrice;

        await txn.insert(DatabaseConstants.tableSaleItems, {
          'id': itemId,
          'sale_id': saleId,
          'product_id': item.product.id,
          'product_name': item.product.name,
          'sku': item.product.sku,
          'quantity': item.quantity,
          'unit_name': item.unit,
          'unit_price': item.unitPrice,
          'purchase_cost': item.product.purchasePrice,
          'discount_amount': 0.0,
          'total_price': lineTotal,
          'created_at': now,
        });

        // Deduct inventory stock
        await productDao.adjustStock(
          productId: item.product.id,
          quantityDelta: -item.quantity,
          movementType: 'SALE',
          unit: item.unit,
          referenceId: saleId,
          note: 'Sold in $finalReceiptNumber',
          shopId: shopId,
          txn: txn,
        );

        itemsPayload.add({
          'product_id': item.product.id,
          'product_name': item.product.name,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_price': lineTotal,
        });
      }

      // 3. Insert Payment
      final paymentId = uuid.v4();
      final paidAmount = grandTotal - udharAmount;
      if (paidAmount > 0) {
        await txn.insert(DatabaseConstants.tablePayments, {
          'id': paymentId,
          'shop_id': shopId,
          'payable_type': 'Sale',
          'payable_id': saleId,
          'payment_method': paymentMethod,
          'amount': paidAmount,
          'transaction_reference': finalReceiptNumber,
          'created_at': now,
          'sync_status': DatabaseConstants.syncStatusPending,
        });
      }

      // 4. Record Udhar Khata if credit extended
      if (udharAmount > 0 && customerId != null && customerId.isNotEmpty) {
        final custRows = await txn.query(
          DatabaseConstants.tableCustomers,
          columns: ['outstanding_udhar'],
          where: 'id = ?',
          whereArgs: [customerId],
        );

        final currentUdhar = custRows.isNotEmpty
            ? (custRows.first['outstanding_udhar'] as num).toDouble()
            : 0.0;
        final newUdhar = currentUdhar + udharAmount;

        await txn.update(
          DatabaseConstants.tableCustomers,
          {
            'outstanding_udhar': newUdhar,
            'updated_at': now,
            'sync_status': DatabaseConstants.syncStatusPending,
          },
          where: 'id = ?',
          whereArgs: [customerId],
        );

        await txn.insert(DatabaseConstants.tableCustomerLedgers, {
          'id': uuid.v4(),
          'shop_id': shopId,
          'customer_id': customerId,
          'transaction_type': 'CREDIT_SALE',
          'reference_no': finalReceiptNumber,
          'amount': udharAmount,
          'balance_after': newUdhar,
          'payment_method': 'Credit (Udhar)',
          'note': 'Bill $finalReceiptNumber',
          'created_at': now,
          'sync_status': DatabaseConstants.syncStatusPending,
        });
      }

      // 5. Enqueue Outbox for background server sync
      const outboxDao = SyncOutboxDao();
      await outboxDao.enqueue(
        shopId: shopId,
        entityType: DatabaseConstants.entitySale,
        entityId: saleId,
        action: DatabaseConstants.actionCreate,
        payload: {
          'id': saleId,
          'receipt_number': finalReceiptNumber,
          'customer_id': customerId,
          'customer_name': customerName,
          'subtotal': subtotal,
          'discount': discount,
          'tax': taxAmount,
          'grand_total': grandTotal,
          'payment_method': paymentMethod,
          'cash_received': cashReceived,
          'change_returned': changeReturned,
          'udhar_amount': udharAmount,
          'items': itemsPayload,
          'created_at': now,
        },
        txn: txn,
      );
    });

    return {
      'sale_id': saleId,
      'receipt_number': finalReceiptNumber,
      'grand_total': grandTotal,
      'timestamp': DateTime.fromMillisecondsSinceEpoch(now),
    };
  }

  /// Void / Cancel an entire bill atomically in SQLite.
  /// 1. Marks sale as cancelled (`is_cancelled = 1`, `cancelled_reason`, `cancelled_at`).
  /// 2. Restores inventory stock for all line items with movement_type 'RESTOCK_CANCEL'.
  /// 3. Reverses Udhar Khata if credit was extended.
  /// 4. Enqueues cancellation to sync_outbox.
  Future<bool> cancelSale({
    required String receiptNumber,
    required String reason,
    String shopId = 'default_shop',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    const constProductDao = ProductDao();
    const constOutboxDao = SyncOutboxDao();

    return await _db.transaction((txn) async {
      final saleRows = await txn.query(
        DatabaseConstants.tableSales,
        where: 'receipt_number = ? AND is_cancelled = 0',
        whereArgs: [receiptNumber],
        limit: 1,
      );

      if (saleRows.isEmpty) {
        return false;
      }

      final sale = saleRows.first;
      final saleId = sale['id'] as String;
      final customerId = sale['customer_id'] as String?;
      final udharAmount = (sale['udhar_amount'] as num?)?.toDouble() ?? 0.0;

      // 1. Mark sale cancelled
      await txn.update(
        DatabaseConstants.tableSales,
        {
          'is_cancelled': 1,
          'cancelled_reason': reason,
          'cancelled_at': now,
          'updated_at': now,
          'sync_status': DatabaseConstants.syncStatusPending,
        },
        where: 'id = ?',
        whereArgs: [saleId],
      );

      // 2. Fetch sale items and restore stock
      final itemRows = await txn.query(
        DatabaseConstants.tableSaleItems,
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );

      for (final item in itemRows) {
        final productId = item['product_id'] as String;
        final qty = (item['quantity'] as num).toDouble();
        final unit = item['unit_name'] as String? ?? 'pkt';

        await constProductDao.adjustStock(
          productId: productId,
          quantityDelta: qty,
          movementType: 'RESTOCK_CANCEL',
          unit: unit,
          referenceId: receiptNumber,
          reason: 'Void Bill #$receiptNumber: $reason',
          shopId: shopId,
          txn: txn,
        );
      }

      // 3. Reverse customer udhar if applicable
      if (udharAmount > 0 && customerId != null && customerId.isNotEmpty) {
        final custRows = await txn.query(
          DatabaseConstants.tableCustomers,
          columns: ['outstanding_udhar'],
          where: 'id = ?',
          whereArgs: [customerId],
        );

        if (custRows.isNotEmpty) {
          final currentUdhar = (custRows.first['outstanding_udhar'] as num).toDouble();
          final newUdhar = (currentUdhar - udharAmount).clamp(0.0, 999999.0);

          await txn.update(
            DatabaseConstants.tableCustomers,
            {
              'outstanding_udhar': newUdhar,
              'updated_at': now,
              'sync_status': DatabaseConstants.syncStatusPending,
            },
            where: 'id = ?',
            whereArgs: [customerId],
          );

          await txn.insert(DatabaseConstants.tableCustomerLedgers, {
            'id': const Uuid().v4(),
            'shop_id': shopId,
            'customer_id': customerId,
            'transaction_type': 'CREDIT_VOID',
            'reference_no': receiptNumber,
            'amount': -udharAmount,
            'balance_after': newUdhar,
            'payment_method': 'Credit (Udhar)',
            'note': 'Voided Bill #$receiptNumber: $reason',
            'created_at': now,
            'sync_status': DatabaseConstants.syncStatusPending,
          });
        }
      }

      // 4. Enqueue Outbox mutation for cloud sync
      await constOutboxDao.enqueue(
        shopId: shopId,
        entityType: DatabaseConstants.entitySale,
        entityId: saleId,
        action: DatabaseConstants.actionUpdate,
        payload: {
          'id': saleId,
          'receipt_number': receiptNumber,
          'action': 'CANCEL',
          'cancelled_reason': reason,
          'cancelled_at': now,
        },
        txn: txn,
      );

      return true;
    });
  }

  /// Process partial or full return of items from a bill atomically.
  /// 1. Optionally restocks returned items to inventory.
  /// 2. If refund method is Udhar Khata, reduces customer's balance.
  /// 3. Records refund payment record.
  /// 4. Enqueues mutation to sync_outbox.
  Future<Map<String, dynamic>> returnItems({
    required String receiptNumber,
    required List<Map<String, dynamic>> returnedItems,
    required String reason,
    required String refundMethod,
    required double refundAmount,
    String shopId = 'default_shop',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    const constProductDao = ProductDao();
    const constOutboxDao = SyncOutboxDao();

    return await _db.transaction((txn) async {
      final saleRows = await txn.query(
        DatabaseConstants.tableSales,
        where: 'receipt_number = ?',
        whereArgs: [receiptNumber],
        limit: 1,
      );

      final sale = saleRows.isNotEmpty ? saleRows.first : null;
      final saleId = sale != null ? sale['id'] as String : const Uuid().v4();
      final customerId = sale != null ? sale['customer_id'] as String? : null;

      // 1. Process returned items and restock if requested
      for (final item in returnedItems) {
        final shouldRestock = item['restock'] != false;
        final qty = (item['quantity'] as num?)?.toDouble() ?? 1.0;
        final unit = item['unit'] as String? ?? 'pkt';
        final pId = item['product_id'] as String?;
        final pName = item['name'] as String? ?? '';

        if (shouldRestock) {
          String? targetProductId = pId;
          if (targetProductId == null || targetProductId.isEmpty) {
            final pRows = await txn.query(
              DatabaseConstants.tableProducts,
              columns: ['id'],
              where: 'LOWER(name) = ? AND is_deleted = 0',
              whereArgs: [pName.toLowerCase().trim()],
              limit: 1,
            );
            if (pRows.isNotEmpty) {
              targetProductId = pRows.first['id'] as String;
            }
          }

          if (targetProductId != null && targetProductId.isNotEmpty) {
            await constProductDao.adjustStock(
              productId: targetProductId,
              quantityDelta: qty,
              movementType: 'SALES_RETURN',
              unit: unit,
              referenceId: receiptNumber,
              reason: 'Return Bill #$receiptNumber: $reason',
              shopId: shopId,
              txn: txn,
            );
          }
        }
      }

      // 2. Adjust customer balance if refundMethod is Credit/Udhar
      if (refundMethod.contains('Credit') || refundMethod.contains('Udhar')) {
        if (customerId != null && customerId.isNotEmpty) {
          final custRows = await txn.query(
            DatabaseConstants.tableCustomers,
            columns: ['outstanding_udhar'],
            where: 'id = ?',
            whereArgs: [customerId],
          );

          if (custRows.isNotEmpty) {
            final currentUdhar = (custRows.first['outstanding_udhar'] as num).toDouble();
            final newUdhar = (currentUdhar - refundAmount).clamp(0.0, 999999.0);

            await txn.update(
              DatabaseConstants.tableCustomers,
              {
                'outstanding_udhar': newUdhar,
                'updated_at': now,
                'sync_status': DatabaseConstants.syncStatusPending,
              },
              where: 'id = ?',
              whereArgs: [customerId],
            );

            await txn.insert(DatabaseConstants.tableCustomerLedgers, {
              'id': const Uuid().v4(),
              'shop_id': shopId,
              'customer_id': customerId,
              'transaction_type': 'RETURN_CREDIT',
              'reference_no': receiptNumber,
              'amount': -refundAmount,
              'balance_after': newUdhar,
              'payment_method': 'Credit (Udhar)',
              'note': 'Return Bill #$receiptNumber: $reason',
              'created_at': now,
              'sync_status': DatabaseConstants.syncStatusPending,
            });
          }
        }
      }

      // 3. Record refund payment
      await txn.insert(DatabaseConstants.tablePayments, {
        'id': const Uuid().v4(),
        'shop_id': shopId,
        'payable_type': 'SaleReturn',
        'payable_id': saleId,
        'payment_method': refundMethod,
        'amount': refundAmount,
        'transaction_reference': 'RET-$receiptNumber',
        'created_at': now,
        'sync_status': DatabaseConstants.syncStatusPending,
      });

      // 4. Enqueue to sync outbox
      await constOutboxDao.enqueue(
        shopId: shopId,
        entityType: DatabaseConstants.entitySale,
        entityId: saleId,
        action: 'RETURN',
        payload: {
          'sale_id': saleId,
          'receipt_number': receiptNumber,
          'reason': reason,
          'refund_method': refundMethod,
          'refund_amount': refundAmount,
          'returned_items': returnedItems,
          'created_at': now,
        },
        txn: txn,
      );

      return {
        'success': true,
        'receipt_number': receiptNumber,
        'refund_amount': refundAmount,
        'refund_method': refundMethod,
      };
    });
  }

  /// Get list of bills for a given date (defaults to today).
  Future<List<TodayBillItem>> getBillsForDate({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59, 999).millisecondsSinceEpoch;

    final rows = await _db.rawQuery('''
      SELECT s.*, COALESCE(c.name, 'Walk-in Customer') as customer_name, COALESCE(c.phone, '') as customer_phone
      FROM ${DatabaseConstants.tableSales} s
      LEFT JOIN ${DatabaseConstants.tableCustomers} c ON s.customer_id = c.id
      WHERE s.created_at >= ? AND s.created_at <= ? AND s.is_cancelled = 0
      ORDER BY s.created_at DESC
    ''', [startOfDay, endOfDay]);

    final List<TodayBillItem> bills = [];

    for (final row in rows) {
      final saleId = row['id'] as String;
      final itemRows = await _db.query(
        DatabaseConstants.tableSaleItems,
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );

      final items = itemRows.map((it) {
        return TransactionDetailItem(
          name: it['product_name'] as String,
          quantity: (it['quantity'] as num).toDouble(),
          unit: it['unit_name'] as String? ?? 'pkt',
          rate: (it['unit_price'] as num).toDouble(),
          total: (it['total_price'] as num).toDouble(),
        );
      }).toList();

      final summary = items.isEmpty
          ? '0 items'
          : items.take(2).map((it) => it.name).join(', ') + (items.length > 2 ? ' +${items.length - 2} more' : '');

      bills.add(TodayBillItem(
        billNumber: row['receipt_number'] as String,
        customerName: row['customer_name'] as String,
        customerPhone: row['customer_phone'] as String? ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch((row['created_at'] as num).toInt()),
        amount: (row['grand_total'] as num).toDouble(),
        paymentMethod: row['primary_payment_method'] as String? ?? 'Cash',
        status: row['payment_status'] as String? ?? 'PAID',
        itemsCount: (row['items_count'] as num?)?.toInt() ?? items.length,
        itemsSummary: summary,
        items: items,
        subtotal: (row['subtotal'] as num?)?.toDouble() ?? (row['grand_total'] as num).toDouble(),
        discount: (row['discount_amount'] as num?)?.toDouble() ?? 0.0,
        taxAmount: (row['tax_amount'] as num?)?.toDouble() ?? 0.0,
        cashReceived: (row['cash_tendered'] as num?)?.toDouble() ?? 0.0,
        changeReturned: (row['change_returned'] as num?)?.toDouble() ?? 0.0,
        udharAmount: (row['udhar_amount'] as num?)?.toDouble() ?? 0.0,
      ));
    }

    return bills;
  }

  /// Get all financial transactions for the Ledger & Transactions Screen.
  Future<List<FullTransactionModel>> getAllTransactions({int limit = 100}) async {
    final rows = await _db.rawQuery('''
      SELECT s.*, COALESCE(c.name, 'Walk-in Customer') as customer_name, COALESCE(c.phone, '') as customer_phone
      FROM ${DatabaseConstants.tableSales} s
      LEFT JOIN ${DatabaseConstants.tableCustomers} c ON s.customer_id = c.id
      WHERE s.is_cancelled = 0
      ORDER BY s.created_at DESC
      LIMIT ?
    ''', [limit]);

    final List<FullTransactionModel> list = [];

    for (final row in rows) {
      final saleId = row['id'] as String;
      final itemRows = await _db.query(
        DatabaseConstants.tableSaleItems,
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );

      final items = itemRows.map((it) {
        return TransactionDetailItem(
          name: it['product_name'] as String,
          quantity: (it['quantity'] as num).toDouble(),
          unit: it['unit_name'] as String? ?? 'pkt',
          rate: (it['unit_price'] as num).toDouble(),
          total: (it['total_price'] as num).toDouble(),
        );
      }).toList();

      final customer = row['customer_name'] as String;
      final receipt = row['receipt_number'] as String;
      final total = (row['grand_total'] as num).toDouble();
      final method = row['primary_payment_method'] as String? ?? 'Cash';
      final status = row['payment_status'] as String? ?? 'PAID';
      final udhar = (row['udhar_amount'] as num?)?.toDouble() ?? 0.0;

      final category = status == 'CREDIT'
          ? TransactionCategory.creditSale
          : TransactionCategory.sale;

      list.add(FullTransactionModel(
        id: saleId,
        receiptNumber: receipt,
        title: customer,
        subtitle: '$method • Bill $receipt',
        partyName: customer,
        partyPhone: row['customer_phone'] as String? ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch((row['created_at'] as num).toInt()),
        amount: total,
        category: category,
        paymentMethod: method,
        status: status,
        items: items,
        subtotal: (row['subtotal'] as num?)?.toDouble() ?? total,
        discount: (row['discount_amount'] as num?)?.toDouble() ?? 0.0,
        tax: (row['tax_amount'] as num?)?.toDouble() ?? 0.0,
        cashReceived: (row['cash_tendered'] as num?)?.toDouble() ?? 0.0,
        changeReturned: (row['change_returned'] as num?)?.toDouble() ?? 0.0,
        udharAmount: udhar,
        note: row['note'] as String? ?? '',
      ));
    }

    return list;
  }

  /// Compute dashboard financial overview for today.
  Future<Map<String, dynamic>> getDashboardOverview({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59, 999).millisecondsSinceEpoch;

    final result = await _db.rawQuery('''
      SELECT 
        COALESCE(SUM(grand_total), 0.0) as total_sales,
        COALESCE(SUM(CASE WHEN primary_payment_method = 'Cash' THEN (grand_total - udhar_amount) ELSE 0.0 END), 0.0) as cash_amount,
        COALESCE(SUM(CASE WHEN primary_payment_method IN ('Card', 'Fonepay QR', 'QR', 'Online') THEN (grand_total - udhar_amount) ELSE 0.0 END), 0.0) as card_amount,
        COALESCE(SUM(udhar_amount), 0.0) as udhar_amount,
        COUNT(*) as bills_count
      FROM ${DatabaseConstants.tableSales}
      WHERE created_at >= ? AND created_at <= ? AND is_cancelled = 0
    ''', [startOfDay, endOfDay]);

    final row = result.first;
    return {
      'total_sales': (row['total_sales'] as num).toDouble(),
      'cash_amount': (row['cash_amount'] as num).toDouble(),
      'card_amount': (row['card_amount'] as num).toDouble(),
      'udhar_amount': (row['udhar_amount'] as num).toDouble(),
      'bills_count': (row['bills_count'] as num).toInt(),
      'date': DateFormat('MMM d, yyyy').format(targetDate),
    };
  }
}
