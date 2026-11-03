import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../features/products/domain/models/product.dart';
import '../app_database.dart';
import '../database_constants.dart';

/// DAO for Product, Category, and Stock Movement SQLite operations.
class ProductDao {
  const ProductDao();

  Database get _db => AppDatabase.instance.database;

  /// Fetch all active (non-deleted) products sorted alphabetically.
  Future<List<Product>> getAllProducts() async {
    final rows = await _db.rawQuery('''
      SELECT p.*, COALESCE(c.name, 'Daily Needs') as category_name
      FROM ${DatabaseConstants.tableProducts} p
      LEFT JOIN ${DatabaseConstants.tableCategories} c ON p.category_id = c.id
      WHERE p.is_deleted = 0
      ORDER BY p.name ASC
    ''');

    return rows.map((row) => _productFromRow(row)).toList();
  }

  /// Find a product by exact ID.
  Future<Product?> getProductById(String id) async {
    final rows = await _db.rawQuery('''
      SELECT p.*, COALESCE(c.name, 'Daily Needs') as category_name
      FROM ${DatabaseConstants.tableProducts} p
      LEFT JOIN ${DatabaseConstants.tableCategories} c ON p.category_id = c.id
      WHERE p.id = ? AND p.is_deleted = 0
      LIMIT 1
    ''', [id]);

    if (rows.isEmpty) return null;
    return _productFromRow(rows.first);
  }

  /// Find product by barcode (instant index scan).
  Future<Product?> getProductByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return null;
    final rows = await _db.rawQuery('''
      SELECT p.*, COALESCE(c.name, 'Daily Needs') as category_name
      FROM ${DatabaseConstants.tableProducts} p
      LEFT JOIN ${DatabaseConstants.tableCategories} c ON p.category_id = c.id
      WHERE p.barcode = ? AND p.is_deleted = 0
      LIMIT 1
    ''', [barcode.trim()]);

    if (rows.isEmpty) return null;
    return _productFromRow(rows.first);
  }

  /// Search products by text query and category.
  Future<List<Product>> searchProducts(String query, {String? category}) async {
    final cleanQuery = query.trim().toLowerCase();
    final isCategoryAll = category == null || category.isEmpty || category == 'All';

    String sql = '''
      SELECT p.*, COALESCE(c.name, 'Daily Needs') as category_name
      FROM ${DatabaseConstants.tableProducts} p
      LEFT JOIN ${DatabaseConstants.tableCategories} c ON p.category_id = c.id
      WHERE p.is_deleted = 0
    ''';
    final List<dynamic> args = [];

    if (!isCategoryAll) {
      sql += ' AND LOWER(c.name) = ?';
      args.add(category.toLowerCase());
    }

    if (cleanQuery.isNotEmpty) {
      sql += ' AND (LOWER(p.name) LIKE ? OR LOWER(p.sku) LIKE ? OR LOWER(p.barcode) LIKE ?)';
      final pattern = '%$cleanQuery%';
      args.addAll([pattern, pattern, pattern]);
    }

    sql += ' ORDER BY p.name ASC';

    final rows = await _db.rawQuery(sql, args);
    return rows.map((row) => _productFromRow(row)).toList();
  }

  /// Upsert a product into SQLite.
  Future<void> upsertProduct(
    Product product, {
    String shopId = 'default_shop',
    bool markLocalDirty = true,
    Transaction? txn,
  }) async {
    final executor = txn ?? _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Resolve category ID if category name is supplied
    String? categoryId;
    if (product.category.isNotEmpty && product.category != 'All') {
      categoryId = await _getOrCreateCategoryId(product.category, shopId, executor);
    }

    final id = product.id.isNotEmpty ? product.id : const Uuid().v4();

    await executor.rawInsert('''
      INSERT INTO ${DatabaseConstants.tableProducts} (
        id, shop_id, category_id, name, nepali_name, sku, barcode, description,
        purchase_price, purchase_unit, selling_price, selling_unit,
        stock_quantity, low_stock_threshold, enable_low_stock_alert,
        image_url, is_deleted, created_at, updated_at, sync_status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        category_id = excluded.category_id,
        name = excluded.name,
        sku = excluded.sku,
        barcode = excluded.barcode,
        description = excluded.description,
        purchase_price = excluded.purchase_price,
        purchase_unit = excluded.purchase_unit,
        selling_price = excluded.selling_price,
        selling_unit = excluded.selling_unit,
        stock_quantity = excluded.stock_quantity,
        low_stock_threshold = excluded.low_stock_threshold,
        enable_low_stock_alert = excluded.enable_low_stock_alert,
        image_url = excluded.image_url,
        updated_at = excluded.updated_at,
        sync_status = excluded.sync_status
    ''', [
      id,
      shopId,
      categoryId,
      product.name,
      null,
      product.sku,
      product.barcode,
      product.description,
      product.purchasePrice,
      product.purchaseUnit,
      product.price,
      product.priceUnit,
      product.stock,
      product.lowStockThreshold,
      product.enableLowStockAlert ? 1 : 0,
      product.imageUrl,
      now,
      now,
      markLocalDirty ? DatabaseConstants.syncStatusPending : DatabaseConstants.syncStatusSynced,
    ]);
  }

  /// Bulk upsert products into SQLite (used during initial sync).
  Future<void> upsertProductsBatch(
    List<Product> products, {
    String shopId = 'default_shop',
    bool markLocalDirty = false,
  }) async {
    if (products.isEmpty) return;

    await _db.transaction((txn) async {
      for (final p in products) {
        await upsertProduct(p, shopId: shopId, markLocalDirty: markLocalDirty, txn: txn);
      }
    });
  }

  /// Adjust stock with audit trail in a single ACID transaction.
  Future<double> adjustStock({
    required String productId,
    required double quantityDelta,
    required String movementType,
    String unit = 'pkt',
    String? reason,
    String? note,
    String? referenceId,
    String shopId = 'default_shop',
    Transaction? txn,
  }) async {
    final executor = txn ?? _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    final rows = await executor.query(
      DatabaseConstants.tableProducts,
      columns: ['stock_quantity'],
      where: 'id = ?',
      whereArgs: [productId],
    );

    final currentStock = rows.isNotEmpty ? (rows.first['stock_quantity'] as num).toDouble() : 0.0;
    final newStock = (currentStock + quantityDelta).clamp(0.0, 999999.0);

    // Update product stock
    await executor.update(
      DatabaseConstants.tableProducts,
      {
        'stock_quantity': newStock,
        'updated_at': now,
        'sync_status': DatabaseConstants.syncStatusPending,
      },
      where: 'id = ?',
      whereArgs: [productId],
    );

    // Insert stock movement record
    await executor.insert(DatabaseConstants.tableStockMovements, {
      'id': const Uuid().v4(),
      'shop_id': shopId,
      'product_id': productId,
      'movement_type': movementType,
      'quantity': quantityDelta.abs(),
      'unit': unit,
      'stock_before': currentStock,
      'stock_after': newStock,
      'reference_id': referenceId,
      'reason': reason,
      'note': note,
      'created_at': now,
      'sync_status': DatabaseConstants.syncStatusPending,
    });

    return newStock;
  }

  /// Soft delete a product.
  Future<void> deleteProduct(String id, {Transaction? txn}) async {
    final executor = txn ?? _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await executor.update(
      DatabaseConstants.tableProducts,
      {
        'is_deleted': 1,
        'updated_at': now,
        'sync_status': DatabaseConstants.syncStatusPending,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Fetch all category names.
  Future<List<String>> getAllCategories() async {
    final rows = await _db.query(
      DatabaseConstants.tableCategories,
      columns: ['name'],
      where: 'is_deleted = 0',
      orderBy: 'name ASC',
    );

    final list = rows.map((r) => r['name'] as String).toList();
    if (!list.contains('All')) {
      list.insert(0, 'All');
    }
    return list;
  }

  /// Add a category.
  Future<void> insertCategory(
    String name, {
    String shopId = 'default_shop',
    String? slug,
    String? icon,
    String? color,
  }) async {
    final cleanSlug = slug ?? name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.insert(
      DatabaseConstants.tableCategories,
      {
        'id': const Uuid().v4(),
        'shop_id': shopId,
        'name': name,
        'slug': cleanSlug,
        'icon': icon,
        'color': color,
        'is_deleted': 0,
        'created_at': now,
        'updated_at': now,
        'sync_status': DatabaseConstants.syncStatusPending,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<String> _getOrCreateCategoryId(String categoryName, String shopId, DatabaseExecutor executor) async {
    final rows = await executor.query(
      DatabaseConstants.tableCategories,
      columns: ['id'],
      where: 'LOWER(name) = ? AND is_deleted = 0',
      whereArgs: [categoryName.toLowerCase().trim()],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      return rows.first['id'] as String;
    }

    final newId = const Uuid().v4();
    final slug = categoryName.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    final now = DateTime.now().millisecondsSinceEpoch;

    await executor.insert(
      DatabaseConstants.tableCategories,
      {
        'id': newId,
        'shop_id': shopId,
        'name': categoryName.trim(),
        'slug': slug,
        'created_at': now,
        'updated_at': now,
        'sync_status': DatabaseConstants.syncStatusPending,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    return newId;
  }

  Product _productFromRow(Map<String, dynamic> row) {
    return Product(
      id: row['id'] as String,
      name: row['name'] as String,
      category: row['category_name'] as String? ?? 'Daily Needs',
      sku: row['sku'] as String? ?? '',
      barcode: row['barcode'] as String? ?? '',
      description: row['description'] as String? ?? '',
      price: (row['selling_price'] as num?)?.toDouble() ?? 0.0,
      priceUnit: row['selling_unit'] as String? ?? 'pkt',
      purchasePrice: (row['purchase_price'] as num?)?.toDouble() ?? 0.0,
      purchaseUnit: row['purchase_unit'] as String? ?? 'Bora',
      stock: (row['stock_quantity'] as num?)?.toDouble() ?? 0.0,
      stockUnit: row['selling_unit'] as String? ?? 'pkt',
      lowStockThreshold: (row['low_stock_threshold'] as num?)?.toDouble() ?? 5.0,
      enableLowStockAlert: (row['enable_low_stock_alert'] as num?)?.toInt() == 1,
      imageUrl: row['image_url'] as String?,
    );
  }
}
