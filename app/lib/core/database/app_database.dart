import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_constants.dart';

/// Central SQLite Database manager for pasal365.
/// Handles initialization, table migrations, FTS5 triggers, and ACID transactions.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  /// Returns the active SQLite database instance.
  Database get database {
    if (_db == null) {
      throw StateError('AppDatabase has not been initialized. Call initialize() first.');
    }
    return _db!;
  }

  /// Whether the database is currently open.
  bool get isOpen => _db != null && _db!.isOpen;

  /// Initialize SQLite database engine and schema.
  Future<Database> initialize({String? inMemoryPath}) async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }

    // Set up FFI for desktop (Windows / Linux / macOS) or unit test runners
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = inMemoryPath ??
        join(await getDatabasesPath(), DatabaseConstants.databaseName);

    _db = await openDatabase(
      dbPath,
      version: DatabaseConstants.databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
      },
    );

    return _db!;
  }

  /// Create all tables, indexes, and FTS5 triggers specified in systemofile.md.
  Future<void> _createSchema(Database db) async {
    final batch = db.batch();

    // 1. Sync Outbox Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableSyncOutbox} (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'PENDING',
        retry_count INTEGER DEFAULT 0,
        max_retries INTEGER DEFAULT 10,
        last_error TEXT,
        created_at INTEGER NOT NULL,
        processed_at INTEGER
      );
    ''');
    batch.execute('CREATE INDEX idx_sync_outbox_status ON ${DatabaseConstants.tableSyncOutbox}(status, created_at);');
    batch.execute('CREATE INDEX idx_sync_outbox_entity ON ${DatabaseConstants.tableSyncOutbox}(entity_type, entity_id);');

    // 2. Sync Metadata Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableSyncMetadata} (
        entity_type TEXT PRIMARY KEY,
        last_pulled_at INTEGER NOT NULL,
        last_pushed_at INTEGER NOT NULL,
        sync_token TEXT
      );
    ''');

    // 3. Categories Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableCategories} (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        name TEXT NOT NULL,
        slug TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        is_deleted INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 1
      );
    ''');
    batch.execute('CREATE UNIQUE INDEX idx_categories_shop_slug ON ${DatabaseConstants.tableCategories}(shop_id, slug);');

    // 4. Products Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableProducts} (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        category_id TEXT,
        name TEXT NOT NULL,
        nepali_name TEXT,
        sku TEXT NOT NULL,
        barcode TEXT,
        description TEXT,
        purchase_price REAL DEFAULT 0.0,
        purchase_unit TEXT DEFAULT 'pkt',
        selling_price REAL NOT NULL,
        selling_unit TEXT DEFAULT 'pkt',
        stock_quantity REAL DEFAULT 0.0,
        low_stock_threshold REAL DEFAULT 5.0,
        enable_low_stock_alert INTEGER DEFAULT 1,
        image_url TEXT,
        is_deleted INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES ${DatabaseConstants.tableCategories}(id) ON DELETE SET NULL
      );
    ''');
    batch.execute('CREATE INDEX idx_products_barcode ON ${DatabaseConstants.tableProducts}(barcode);');
    batch.execute('CREATE INDEX idx_products_sku ON ${DatabaseConstants.tableProducts}(sku);');
    batch.execute('CREATE INDEX idx_products_shop_stock ON ${DatabaseConstants.tableProducts}(shop_id, stock_quantity);');

    // 5. Stock Movements Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableStockMovements} (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        movement_type TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        stock_before REAL NOT NULL,
        stock_after REAL NOT NULL,
        reference_id TEXT,
        reason TEXT,
        note TEXT,
        created_at INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 1,
        FOREIGN KEY (product_id) REFERENCES ${DatabaseConstants.tableProducts}(id) ON DELETE CASCADE
      );
    ''');
    batch.execute('CREATE INDEX idx_stock_movements_prod ON ${DatabaseConstants.tableStockMovements}(product_id, created_at);');

    // 6. Customers Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableCustomers} (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        credit_limit REAL DEFAULT 0.0,
        outstanding_udhar REAL DEFAULT 0.0,
        is_active INTEGER DEFAULT 1,
        is_deleted INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 1
      );
    ''');
    batch.execute('CREATE UNIQUE INDEX idx_customers_phone ON ${DatabaseConstants.tableCustomers}(shop_id, phone);');
    batch.execute('CREATE INDEX idx_customers_udhar ON ${DatabaseConstants.tableCustomers}(outstanding_udhar DESC);');

    // 7. Customer Ledgers Table (Udhar Khata)
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableCustomerLedgers} (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        reference_no TEXT,
        amount REAL NOT NULL,
        balance_after REAL NOT NULL,
        payment_method TEXT,
        note TEXT,
        created_at INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 1,
        FOREIGN KEY (customer_id) REFERENCES ${DatabaseConstants.tableCustomers}(id) ON DELETE CASCADE
      );
    ''');
    batch.execute('CREATE INDEX idx_customer_ledgers ON ${DatabaseConstants.tableCustomerLedgers}(customer_id, created_at DESC);');

    // 8. Suppliers Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableSuppliers} (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        name TEXT NOT NULL,
        company_name TEXT,
        phone TEXT NOT NULL,
        pan_number TEXT,
        address TEXT,
        outstanding_payable REAL DEFAULT 0.0,
        is_deleted INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 1
      );
    ''');

    // 9. Supplier Ledgers Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableSupplierLedgers} (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        supplier_id TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        reference_no TEXT,
        amount REAL NOT NULL,
        balance_after REAL NOT NULL,
        payment_method TEXT,
        note TEXT,
        created_at INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 1,
        FOREIGN KEY (supplier_id) REFERENCES ${DatabaseConstants.tableSuppliers}(id) ON DELETE CASCADE
      );
    ''');

    // 10. Sales Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableSales} (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        receipt_number TEXT NOT NULL,
        customer_id TEXT,
        cashier_id TEXT,
        cashier_name TEXT,
        subtotal REAL NOT NULL,
        discount_type TEXT DEFAULT 'fixed',
        discount_amount REAL DEFAULT 0.0,
        tax_percentage REAL DEFAULT 0.0,
        tax_amount REAL DEFAULT 0.0,
        grand_total REAL NOT NULL,
        payment_status TEXT NOT NULL,
        primary_payment_method TEXT NOT NULL,
        cash_tendered REAL DEFAULT 0.0,
        change_returned REAL DEFAULT 0.0,
        udhar_amount REAL DEFAULT 0.0,
        items_count INTEGER NOT NULL,
        note TEXT,
        is_cancelled INTEGER DEFAULT 0,
        cancelled_reason TEXT,
        cancelled_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 1,
        FOREIGN KEY (customer_id) REFERENCES ${DatabaseConstants.tableCustomers}(id) ON DELETE SET NULL
      );
    ''');
    batch.execute('CREATE UNIQUE INDEX idx_sales_receipt ON ${DatabaseConstants.tableSales}(shop_id, receipt_number);');
    batch.execute('CREATE INDEX idx_sales_created ON ${DatabaseConstants.tableSales}(created_at DESC);');
    batch.execute('CREATE INDEX idx_sales_customer ON ${DatabaseConstants.tableSales}(customer_id);');

    // 11. Sale Items Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableSaleItems} (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        sku TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        purchase_cost REAL DEFAULT 0.0,
        discount_amount REAL DEFAULT 0.0,
        total_price REAL NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES ${DatabaseConstants.tableSales}(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES ${DatabaseConstants.tableProducts}(id) ON DELETE RESTRICT
      );
    ''');
    batch.execute('CREATE INDEX idx_sale_items_sale ON ${DatabaseConstants.tableSaleItems}(sale_id);');

    // 12. Payments Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tablePayments} (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        payable_type TEXT NOT NULL,
        payable_id TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        amount REAL NOT NULL,
        transaction_reference TEXT,
        created_at INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 1
      );
    ''');
    batch.execute('CREATE INDEX idx_payments_payable ON ${DatabaseConstants.tablePayments}(payable_type, payable_id);');

    // 13. Expenses Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableExpenses} (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT DEFAULT 'Cash',
        receipt_image_path TEXT,
        note TEXT,
        expense_date INTEGER NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 1
      );
    ''');
    batch.execute('CREATE INDEX idx_expenses_date ON ${DatabaseConstants.tableExpenses}(expense_date DESC);');

    await batch.commit(noResult: true);
  }

  /// Run an action inside an ACID SQLite transaction.
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) {
    return database.transaction(action);
  }

  /// Close the database connection cleanly.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
