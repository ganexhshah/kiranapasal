import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/database/database_constants.dart';
import 'package:app/core/database/daos/product_dao.dart';
import 'package:app/core/database/daos/party_dao.dart';
import 'package:app/core/database/daos/sale_dao.dart';
import 'package:app/core/database/daos/expense_dao.dart';
import 'package:app/core/database/daos/sync_outbox_dao.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/domain/models/cart_item.dart';
import 'package:app/features/sales/domain/models/customer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI for unit test environment
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ProductDao productDao;
  late PartyDao partyDao;
  late SaleDao saleDao;
  late ExpenseDao expenseDao;
  late SyncOutboxDao syncOutboxDao;

  setUp(() async {
    // Open in-memory SQLite database
    await AppDatabase.instance.initialize(inMemoryPath: inMemoryDatabasePath);
    productDao = const ProductDao();
    partyDao = const PartyDao();
    saleDao = const SaleDao();
    expenseDao = const ExpenseDao();
    syncOutboxDao = const SyncOutboxDao();
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  group('SQLite Database & DAOs Unit Tests', () {
    test('Database opens successfully with foreign keys ON', () async {
      expect(AppDatabase.instance.isOpen, isTrue);
      final fkResult = await AppDatabase.instance.database.rawQuery('PRAGMA foreign_keys;');
      expect(fkResult.first.values.first, 1);
    });

    test('ProductDao: upsert, query, barcode scan, and stock adjustment', () async {
      const p1 = Product(
        id: 'prod_1',
        name: 'Wai Wai Noodles 75g',
        category: 'Noodles & Snacks',
        sku: 'WW-75G',
        price: 25.0,
        priceUnit: 'pkt',
        purchasePrice: 20.0,
        purchaseUnit: 'pkt',
        stock: 50,
        stockUnit: 'pkt',
        barcode: '8901234567890',
        lowStockThreshold: 10,
        enableLowStockAlert: true,
      );

      await productDao.upsertProduct(p1);

      // Verify retrieval by ID
      final retrieved = await productDao.getProductById('prod_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Wai Wai Noodles 75g');
      expect(retrieved.category, 'Noodles & Snacks');
      expect(retrieved.price, 25.0);
      expect(retrieved.stock, 50.0);

      // Verify retrieval by barcode
      final byBarcode = await productDao.getProductByBarcode('8901234567890');
      expect(byBarcode, isNotNull);
      expect(byBarcode!.id, 'prod_1');

      // Adjust stock (Sale deduction or restock)
      await productDao.adjustStock(
        productId: 'prod_1',
        quantityDelta: -5.0,
        movementType: 'sale',
        note: 'Manual POS sale test',
      );

      final updated = await productDao.getProductById('prod_1');
      expect(updated!.stock, 45.0);

      // Verify stock movement ledger in DB
      final movements = await AppDatabase.instance.database.query(
        DatabaseConstants.tableStockMovements,
        where: 'product_id = ?',
        whereArgs: ['prod_1'],
      );
      expect(movements.length, 1);
      expect((movements.first['quantity'] as num).toDouble(), 5.0);
      expect(movements.first['movement_type'], 'sale');
    });

    test('PartyDao: customer creation and udhar khata payment', () async {
      const cust = Customer(
        id: 'cust_ram',
        name: 'Ram Bahadur',
        phone: '9841000000',
        address: 'Kathmandu',
        udharBalance: 1200.0,
        creditLimit: 5000.0,
      );

      await partyDao.upsertCustomer(cust);

      final saved = await partyDao.getCustomerById('cust_ram');
      expect(saved, isNotNull);
      expect(saved!.name, 'Ram Bahadur');
      expect(saved.udharBalance, 1200.0);

      // Record udhar repayment of Rs 500
      final newBalance = await partyDao.recordCustomerPayment(
        customerId: 'cust_ram',
        amount: 500.0,
        paymentMethod: 'Cash',
        note: 'Partial cash payment',
      );
      expect(newBalance, 700.0);

      final updated = await partyDao.getCustomerById('cust_ram');
      expect(updated!.udharBalance, 700.0);

      // Check khata ledger entries
      final ledger = await AppDatabase.instance.database.query(
        DatabaseConstants.tableCustomerLedgers,
        where: 'customer_id = ?',
        whereArgs: ['cust_ram'],
      );
      expect(ledger.length, 1);
      expect(ledger.first['transaction_type'], 'PAYMENT_RECEIVED');
      expect((ledger.first['amount'] as num).toDouble(), 500.0);
    });

    test('SaleDao: atomic offline sale creation and stock deduction', () async {
      // 1. Create a product with stock 20
      const prod = Product(
        id: 'prod_oil',
        name: 'Mustard Oil 1L',
        category: 'Cooking Essentials',
        sku: 'OIL-1L',
        price: 280.0,
        priceUnit: 'ltr',
        purchasePrice: 240.0,
        purchaseUnit: 'ltr',
        stock: 20,
        stockUnit: 'ltr',
      );
      await productDao.upsertProduct(prod);

      // 2. Perform a sale of 2 bottles
      const cartItem = CartItem(
        product: prod,
        unit: 'ltr',
        quantity: 2,
        unitPrice: 280.0,
      );

      final saleResult = await saleDao.createSale(
        items: [cartItem],
        subtotal: 560.0,
        grandTotal: 560.0,
        paymentMethod: 'Cash',
        cashReceived: 600.0,
        changeReturned: 40.0,
        cashierName: 'Hari Sharma',
      );

      final receiptNo = saleResult['receipt_number'] as String;
      expect(receiptNo, startsWith('INV-'));

      // 3. Verify stock auto-deducted
      final updatedProd = await productDao.getProductById('prod_oil');
      expect(updatedProd!.stock, 18.0);

      // 4. Verify today's bills contains the sale
      final todayBills = await saleDao.getBillsForDate(date: DateTime.now());
      expect(todayBills.isNotEmpty, isTrue);
      expect(todayBills.first.billNumber, receiptNo);
      expect(todayBills.first.amount, 560.0);

      // 5. Verify transactions ledger
      final transactions = await saleDao.getAllTransactions();
      expect(transactions.any((tx) => tx.receiptNumber == receiptNo), isTrue);

      // 6. Verify sync_outbox contains the sale
      final pendingMutations = await syncOutboxDao.getPending();
      expect(
        pendingMutations.any((m) => m.entityType == DatabaseConstants.entitySale && m.entityId == saleResult['sale_id']),
        isTrue,
      );
    });

    test('SaleDao: cancelSale voids bill, restores inventory, and enqueues sync', () async {
      const prod = Product(
        id: 'prod_biscuit',
        name: 'Marie Gold Biscuits',
        category: 'Snacks',
        sku: 'MG-100G',
        price: 30.0,
        priceUnit: 'pkt',
        stock: 50,
        stockUnit: 'pkt',
      );
      await productDao.upsertProduct(prod);

      const cartItem = CartItem(
        product: prod,
        unit: 'pkt',
        quantity: 5,
        unitPrice: 30.0,
      );

      final sale = await saleDao.createSale(
        items: [cartItem],
        subtotal: 150.0,
        grandTotal: 150.0,
        paymentMethod: 'Cash',
      );
      final receiptNo = sale['receipt_number'] as String;

      // Stock reduced to 45
      var p = await productDao.getProductById('prod_biscuit');
      expect(p!.stock, 45.0);

      // Void the bill
      final success = await saleDao.cancelSale(
        receiptNumber: receiptNo,
        reason: 'Customer cancelled order',
      );
      expect(success, isTrue);

      // Stock must be restored to 50
      p = await productDao.getProductById('prod_biscuit');
      expect(p!.stock, 50.0);

      // Bill should no longer appear in active today bills
      final bills = await saleDao.getBillsForDate(date: DateTime.now());
      expect(bills.any((b) => b.billNumber == receiptNo), isFalse);
    });

    test('SaleDao: returnItems processes partial item return and restocks inventory', () async {
      const prod = Product(
        id: 'prod_tea',
        name: 'Tokla CTC Tea 500g',
        category: 'Beverages',
        sku: 'TEA-500G',
        price: 350.0,
        priceUnit: 'pkt',
        stock: 20,
        stockUnit: 'pkt',
      );
      await productDao.upsertProduct(prod);

      const cartItem = CartItem(
        product: prod,
        unit: 'pkt',
        quantity: 3,
        unitPrice: 350.0,
      );

      final sale = await saleDao.createSale(
        items: [cartItem],
        subtotal: 1050.0,
        grandTotal: 1050.0,
        paymentMethod: 'Cash',
      );
      final receiptNo = sale['receipt_number'] as String;

      // Stock is 17
      var p = await productDao.getProductById('prod_tea');
      expect(p!.stock, 17.0);

      // Customer returns 1 packet
      final returnResult = await saleDao.returnItems(
        receiptNumber: receiptNo,
        returnedItems: [
          {
            'name': 'Tokla CTC Tea 500g',
            'product_id': 'prod_tea',
            'quantity': 1.0,
            'unit': 'pkt',
            'rate': 350.0,
            'total': 350.0,
            'restock': true,
          }
        ],
        reason: 'Customer took 1 extra by mistake',
        refundMethod: 'Cash',
        refundAmount: 350.0,
      );

      expect(returnResult['success'], isTrue);
      expect(returnResult['refund_amount'], 350.0);

      // Stock must be restored from 17 back to 18
      p = await productDao.getProductById('prod_tea');
      expect(p!.stock, 18.0);
    });

    test('ExpenseDao: record and query expenses', () async {
      final expId = await expenseDao.recordExpense(
        title: 'Shop Electricity Bill',
        amount: 1450.0,
        categoryName: 'Utilities',
        paymentMethod: 'Fonepay QR',
        note: 'Month of Kartik',
      );

      final expenses = await expenseDao.getAllExpenses();
      expect(expenses.isNotEmpty, isTrue);
      final created = expenses.firstWhere((e) => e['id'] == expId);
      expect(created['title'], 'Shop Electricity Bill');
      expect((created['amount'] as num).toDouble(), 1450.0);
      expect(created['payment_method'], 'Fonepay QR');
    });

    test('SyncOutboxDao: markInFlight and deleteCompleted lifecycle', () async {
      final pending = await syncOutboxDao.getPending();
      if (pending.isNotEmpty) {
        final item = pending.first;
        await syncOutboxDao.markInFlight([item.id]);

        // Should no longer be returned by getPending (only status = PENDING is returned)
        final afterInFlight = await syncOutboxDao.getPending();
        expect(afterInFlight.any((m) => m.id == item.id), isFalse);

        await syncOutboxDao.deleteCompleted([item.id]);
        final count = await syncOutboxDao.getPendingCount();
        expect(count, afterInFlight.length);
      }
    });
  });
}
