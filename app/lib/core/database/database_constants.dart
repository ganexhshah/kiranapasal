/// Database constants for tables, columns, and sync statuses.
class DatabaseConstants {
  DatabaseConstants._();

  static const String databaseName = 'pasal365_local.db';
  static const int databaseVersion = 1;

  // Table Names
  static const String tableSyncOutbox = 'sync_outbox';
  static const String tableSyncMetadata = 'sync_metadata';
  static const String tableCategories = 'categories';
  static const String tableProducts = 'products';
  static const String tableProductsFts = 'products_fts';
  static const String tableStockMovements = 'stock_movements';
  static const String tableSales = 'sales';
  static const String tableSaleItems = 'sale_items';
  static const String tablePayments = 'payments';
  static const String tableCustomers = 'customers';
  static const String tableCustomerLedgers = 'customer_ledgers';
  static const String tableSuppliers = 'suppliers';
  static const String tableSupplierLedgers = 'supplier_ledgers';
  static const String tableExpenses = 'expenses';

  // Sync Status Codes
  static const int syncStatusSynced = 0;
  static const int syncStatusPending = 1;

  // Sync Outbox Status Strings
  static const String outboxPending = 'PENDING';
  static const String outboxInFlight = 'IN_FLIGHT';
  static const String outboxCompleted = 'COMPLETED';
  static const String outboxFailed = 'FAILED';

  // Outbox Action Types
  static const String actionCreate = 'CREATE';
  static const String actionUpdate = 'UPDATE';
  static const String actionDelete = 'DELETE';

  // Outbox Entity Types
  static const String entityProduct = 'product';
  static const String entityCategory = 'category';
  static const String entitySale = 'sale';
  static const String entityCustomer = 'customer';
  static const String entitySupplier = 'supplier';
  static const String entityCustomerLedger = 'customer_ledger';
  static const String entitySupplierLedger = 'supplier_ledger';
  static const String entityExpense = 'expense';
  static const String entityStockMovement = 'stock_movement';
}

