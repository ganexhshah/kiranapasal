import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../features/products/domain/models/product.dart';
import '../../features/sales/domain/models/cart_item.dart';
import '../../features/sales/domain/models/customer.dart';
import '../../features/sales/domain/models/supplier.dart';
import '../../features/sales/presentation/screens/today_bills_screen.dart';
import '../../features/sales/presentation/screens/transaction_details_screen.dart';
import '../../features/sales/presentation/screens/transactions_screen.dart';
import '../database/app_database.dart';
import '../database/daos/expense_dao.dart';
import '../database/daos/party_dao.dart';
import '../database/daos/product_dao.dart';
import '../database/daos/sale_dao.dart';
import '../sync/sync_engine.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/party_backend_service.dart';
import '../services/printing_service.dart';
import '../services/product_backend_service.dart';
import '../services/sale_backend_service.dart';

/// Central reactive repository connecting Flutter screens to real backend data.
class AppDataRepository extends ChangeNotifier {
  AppDataRepository._();
  static final AppDataRepository instance = AppDataRepository._();

  final ProductBackendService _productService = ProductBackendService();
  final SaleBackendService _saleService = SaleBackendService();
  final PartyBackendService _partyService = PartyBackendService();
  final DashboardService _dashboardService = DashboardService();
  final AuthService _authService = AuthService();

  final ProductDao _productDao = const ProductDao();
  final SaleDao _saleDao = const SaleDao();
  final PartyDao _partyDao = const PartyDao();
  final ExpenseDao _expenseDao = const ExpenseDao();

  // Shop Profile Info
  String _shopName = 'Kirana Store';
  String _shopAddress = '';
  String _shopPhone = '';
  String _shopPan = '';

  String get shopName => _shopName;
  String get shopAddress => _shopAddress;
  String get shopPhone => _shopPhone;
  String get shopPan => _shopPan;

  bool _initialized = false;
  bool _isLoading = false;
  String? _lastError;

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  // Cache & request deduplication
  DateTime? _lastRefreshTime;
  static const Duration _cacheTtl = Duration(seconds: 45);
  Future<void>? _activeRefreshFuture;

  // 1. Products & Inventory
  List<Product> _products = [];
  List<Product> _lowStockProducts = [];
  final List<String> _categories = [
    'All',
    'Grains',
    'Snacks',
    'Beverages',
    'Daily Needs',
    'Household',
  ];

  List<Product> get products => _products;
  List<String> get categories => _categories;
  List<Product> get lowStockProducts => _lowStockProducts;

  // 2. Customers & Suppliers
  List<Customer> _customers = [];
  List<Supplier> _suppliers = [];

  List<Customer> get customers => _customers;
  List<Supplier> get suppliers => _suppliers;

  // 3. Today's Bills & Invoices
  List<TodayBillItem> _todayBills = [];
  List<TodayBillItem> get todayBills => _todayBills;

  // 4. All Transactions Ledger
  List<FullTransactionModel> _transactions = [];
  List<FullTransactionModel> get transactions => _transactions;

  // 5. Dashboard Data
  final Map<String, dynamic> _dashboardOverview = {
    'total_sales': 0.0,
    'cash_amount': 0.0,
    'card_amount': 0.0,
    'udhar_amount': 0.0,
    'bills_count': 0,
    'date': 'Today',
  };

  final Map<String, dynamic> _dashboardStats = {
    'total_products': 0,
    'total_customers': 0,
    'low_stock_items': 0,
    'todays_bills': 0,
  };

  Map<String, dynamic> get dashboardOverview => _dashboardOverview;
  Map<String, dynamic> get dashboardStats => _dashboardStats;

  @visibleForTesting
  void setProductsForTesting(List<Product> products) {
    _products = List.from(products);
    _updateDashboardMetrics();
    notifyListeners();
  }

  @visibleForTesting
  void setTransactionsForTesting(List<FullTransactionModel> transactions) {
    _transactions = List.from(transactions);
    notifyListeners();
  }

  @visibleForTesting
  void setCustomersForTesting(List<Customer> customers) {
    _customers = List.from(customers);
    _updateDashboardMetrics();
    notifyListeners();
  }

  @visibleForTesting
  void setSuppliersForTesting(List<Supplier> suppliers) {
    _suppliers = List.from(suppliers);
    notifyListeners();
  }

  /// Load local data from SQLite immediately (<20ms).
  Future<void> _loadFromLocalDatabase() async {
    try {
      final localProducts = await _productDao.getAllProducts();
      if (localProducts.isNotEmpty) {
        _products = localProducts;
      }

      final localCategories = await _productDao.getAllCategories();
      for (final cat in localCategories) {
        if (!_categories.contains(cat)) {
          _categories.add(cat);
        }
      }

      final localCustomers = await _partyDao.getAllCustomers();
      if (localCustomers.isNotEmpty) {
        _customers = localCustomers;
      }

      final localSuppliers = await _partyDao.getAllSuppliers();
      if (localSuppliers.isNotEmpty) {
        _suppliers = localSuppliers;
      }

      final localBills = await _saleDao.getBillsForDate();
      if (localBills.isNotEmpty) {
        _todayBills = localBills;
      }

      final localTransactions = await _saleDao.getAllTransactions();
      if (localTransactions.isNotEmpty) {
        _transactions = localTransactions;
      }

      _updateDashboardMetrics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading from local SQLite: $e');
    }
  }

  /// Initialize SQLite database and sync engine, then refresh.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await AppDatabase.instance.initialize();
      await _loadFromLocalDatabase();
      await SyncEngine.instance.initialize();
    } catch (e) {
      debugPrint('SQLite initialization note: $e');
    }

    await refreshAll(force: true, silent: true);
  }

  /// Full synchronisation across all backend domains with smart deduplication and cache TTL
  Future<void> refreshAll({bool force = false, bool silent = false}) {
    if (_activeRefreshFuture != null) {
      return _activeRefreshFuture!;
    }
    final now = DateTime.now();
    if (!force &&
        _lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _cacheTtl &&
        _products.isNotEmpty) {
      return Future.value();
    }

    _activeRefreshFuture = _performRefresh(silent: silent);
    return _activeRefreshFuture!;
  }

  Future<void> _performRefresh({bool silent = false}) async {
    final shouldShowLoading = !silent && _products.isEmpty && _todayBills.isEmpty;
    if (shouldShowLoading) {
      _isLoading = true;
      _lastError = null;
      notifyListeners();
    }

    try {
      await Future.wait([
        _loadShopProfile(),
        _loadCategories(),
        _loadProducts(),
        _loadCustomers(),
        _loadSuppliers(),
        _loadTodayBills(),
        _loadTransactions(),
        _loadDashboard(),
      ]);
      _lastRefreshTime = DateTime.now();
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoading = false;
      _updateDashboardMetrics();
      _activeRefreshFuture = null;
      notifyListeners();
    }
  }

  Future<void> _loadShopProfile() async {
    try {
      final res = await _authService.getProfile();
      if (res.success && res.data != null) {
        final user = res.data!['user'] as Map<String, dynamic>?;
        final shop = (user?['current_shop'] ?? res.data!['shop']) as Map<String, dynamic>?;
        if (shop != null) {
          _shopName = (shop['name'] as String?)?.trim() ?? _shopName;
          _shopAddress = (shop['address'] as String?)?.trim() ?? _shopAddress;
          _shopPhone = (shop['phone'] as String?)?.trim() ?? _shopPhone;
          _shopPan = (shop['pan_vat_number'] as String?)?.trim() ?? _shopPan;
          await PrintingService.instance.syncFromShop(shop);
        }
      }
    } catch (_) {}
  }

  // ==================== PRODUCTS & CATEGORIES ====================

  Future<void> _loadCategories() async {
    try {
      final res = await ApiClient.instance.get<List<dynamic>>(
        ApiConfig.categories,
        fromData: (data) => data as List<dynamic>,
      );
      if (res.success && res.data != null) {
        final backendCats = res.data!
            .map((item) => (item as Map<String, dynamic>)['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
        for (final cat in backendCats) {
          if (!_categories.contains(cat)) {
            _categories.add(cat);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadProducts() async {
    try {
      final res = await _productService.getProducts();
      if (res.success && res.data != null) {
        final data = res.data!['data'] as List<dynamic>? ?? [];
        _products = data
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();
        await _productDao.upsertProductsBatch(_products, markLocalDirty: false);
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  Future<bool> addProduct(Product product) async {
    try {
      await _productDao.upsertProduct(product, markLocalDirty: true);
    } catch (_) {}

    _products.removeWhere((p) => p.id == product.id);
    _products.insert(0, product);
    _updateDashboardMetrics();
    notifyListeners();

    try {
      final res = await _productService.createProduct(product.toJson());
      if (res.success && res.data != null) {
        final created = Product.fromJson(res.data!);
        final idx = _products.indexWhere((p) => p.id == product.id || p.id == created.id);
        if (idx >= 0) {
          _products[idx] = created;
          await _productDao.upsertProduct(created, markLocalDirty: false);
          notifyListeners();
        }
      } else {
        SyncEngine.instance.syncNow();
      }
      return true;
    } catch (e) {
      SyncEngine.instance.syncNow();
      return true;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await _productDao.upsertProduct(product, markLocalDirty: true);
    } catch (_) {}

    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      _products[idx] = product;
      _updateDashboardMetrics();
      notifyListeners();
    }
    try {
      final res = await _productService.updateProduct(product.id, product.toJson());
      if (res.success && res.data != null) {
        final updated = Product.fromJson(res.data!);
        final uIdx = _products.indexWhere((p) => p.id == product.id);
        if (uIdx >= 0) {
          _products[uIdx] = updated;
          await _productDao.upsertProduct(updated, markLocalDirty: false);
          notifyListeners();
        }
      }
      return true;
    } catch (_) {
      SyncEngine.instance.syncNow();
      return true;
    }
  }

  Future<Product?> findProductByBarcode(String code) async {
    final cleanCode = code.trim().toLowerCase();
    // 1. Check local in-memory cache first
    final localMatch = _products.where((p) =>
        p.barcode.toLowerCase() == cleanCode ||
        p.sku.toLowerCase() == cleanCode ||
        p.id.toLowerCase() == cleanCode);
    if (localMatch.isNotEmpty) {
      return localMatch.first;
    }

    // 2. Query real backend if not in cache
    try {
      final res = await _productService.findByBarcode(code);
      if (res.success && res.data != null) {
        final product = Product.fromJson(res.data!);
        _products.add(product);
        notifyListeners();
        return product;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _productDao.deleteProduct(productId);
    } catch (_) {}
    try {
      await _productService.deleteProduct(productId);
    } catch (_) {
      SyncEngine.instance.syncNow();
    }
    _products.removeWhere((p) => p.id == productId);
    _updateDashboardMetrics();
    notifyListeners();
    return true;
  }

  Future<bool> adjustStock({
    required String productId,
    required bool isAddition,
    required double quantity,
    required String unit,
    required String reason,
    String? note,
  }) async {
    try {
      await _productDao.adjustStock(
        productId: productId,
        quantityDelta: isAddition ? quantity : -quantity,
        movementType: isAddition ? 'ADJUST_ADD' : 'ADJUST_REMOVE',
        unit: unit,
        reason: reason,
        note: note,
      );
    } catch (_) {}

    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx >= 0) {
      final p = _products[idx];
      final newStock = isAddition ? (p.stock + quantity) : (p.stock - quantity);
      _products[idx] = p.copyWith(stock: newStock.clamp(0.0, 999999.0));
      _updateDashboardMetrics();
      notifyListeners();
    }

    try {
      await _productService.adjustStock(
        productId: productId,
        isAddition: isAddition,
        quantity: quantity,
        unit: unit,
        reason: reason,
        note: note,
      );
      return true;
    } catch (_) {
      SyncEngine.instance.syncNow();
      return true;
    }
  }

  Future<bool> updateLowStockThreshold({
    required String productId,
    required double threshold,
    required bool enabled,
  }) async {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx >= 0) {
      final p = _products[idx];
      _products[idx] = p.copyWith(
        lowStockThreshold: threshold,
        enableLowStockAlert: enabled,
      );
      _updateDashboardMetrics();
      notifyListeners();
    }

    try {
      await _productService.updateLowStockAlert(
        productId: productId,
        threshold: threshold,
        enabled: enabled,
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  // ==================== CUSTOMERS & SUPPLIERS ====================

  Future<void> _loadCustomers() async {
    try {
      final res = await _partyService.getCustomers();
      if (res.success && res.data != null) {
        final list = res.data!['data'] as List<dynamic>? ?? [];
        if (list.isNotEmpty) {
          _customers = list
              .map((c) => Customer.fromJson(c as Map<String, dynamic>))
              .toList();
          await _partyDao.upsertCustomersBatch(_customers, markLocalDirty: false);
        }
      }
    } catch (_) {}
  }

  Future<bool> addCustomer(Customer customer) async {
    try {
      await _partyDao.upsertCustomer(customer, markLocalDirty: true);
    } catch (_) {}
    _customers.insert(0, customer);
    _updateDashboardMetrics();
    notifyListeners();

    try {
      await _partyService.createCustomer(customer.toJson());
      return true;
    } catch (_) {
      SyncEngine.instance.syncNow();
      return true;
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      await _partyDao.upsertCustomer(customer, markLocalDirty: true);
    } catch (_) {}
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx >= 0) {
      _customers[idx] = customer;
      notifyListeners();
    }
    try {
      await _partyService.updateCustomer(customer.id, customer.toJson());
      return true;
    } catch (_) {
      SyncEngine.instance.syncNow();
      return true;
    }
  }

  Future<bool> receiveUdharPayment({
    required String customerId,
    required double amount,
    required String paymentMethod,
    String? note,
  }) async {
    try {
      await _partyDao.recordCustomerPayment(
        customerId: customerId,
        amount: amount,
        paymentMethod: paymentMethod,
        note: note,
      );
      SyncEngine.instance.syncNow();
    } catch (_) {}

    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx >= 0) {
      final c = _customers[idx];
      final newBal = (c.udharBalance - amount).clamp(0.0, 999999.0);
      _customers[idx] = c.copyWith(udharBalance: newBal);

      _transactions.insert(
        0,
        FullTransactionModel(
          id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
          receiptNumber: 'PAY-${DateTime.now().millisecondsSinceEpoch % 10000}',
          title: 'Udhar Payment - ${c.name}',
          subtitle: '$paymentMethod • Payment In',
          partyName: c.name,
          partyPhone: c.phone,
          timestamp: DateTime.now(),
          amount: amount,
          category: TransactionCategory.udharPayment,
          paymentMethod: paymentMethod,
          status: 'SETTLED',
          note: note ?? 'Udhar settled',
        ),
      );

      _updateDashboardMetrics();
      notifyListeners();
    }

    try {
      await _partyService.receiveCustomerPayment(
        customerId: customerId,
        amount: amount,
        paymentMethod: paymentMethod,
        note: note,
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _loadSuppliers() async {
    try {
      final res = await _partyService.getSuppliers();
      if (res.success && res.data != null) {
        final list = res.data!['data'] as List<dynamic>? ?? [];
        if (list.isNotEmpty) {
          _suppliers = list
              .map((s) => Supplier.fromJson(s as Map<String, dynamic>))
              .toList();
          await _partyDao.upsertSuppliersBatch(_suppliers, markLocalDirty: false);
        }
      }
    } catch (_) {}
  }

  Future<bool> addSupplier(Supplier supplier) async {
    try {
      await _partyDao.upsertSupplier(supplier, markLocalDirty: true);
    } catch (_) {}
    _suppliers.insert(0, supplier);
    notifyListeners();

    try {
      await _partyService.createSupplier(supplier.toJson());
      return true;
    } catch (_) {
      SyncEngine.instance.syncNow();
      return true;
    }
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    try {
      await _partyDao.upsertSupplier(supplier, markLocalDirty: true);
    } catch (_) {}
    final idx = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (idx >= 0) {
      _suppliers[idx] = supplier;
      notifyListeners();
    }
    try {
      await _partyService.updateSupplier(supplier.id, supplier.toJson());
      return true;
    } catch (_) {
      SyncEngine.instance.syncNow();
      return true;
    }
  }

  Future<bool> recordSupplierPayment({
    required String supplierId,
    required double amount,
    required String paymentMethod,
    String? note,
  }) async {
    final idx = _suppliers.indexWhere((s) => s.id == supplierId);
    if (idx >= 0) {
      final s = _suppliers[idx];
      final newBal = (s.outstandingBalance - amount).clamp(0.0, 999999.0);
      _suppliers[idx] = s.copyWith(outstandingBalance: newBal);

      _transactions.insert(
        0,
        FullTransactionModel(
          id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
          receiptNumber: 'SUP-${DateTime.now().millisecondsSinceEpoch % 10000}',
          title: 'Supplier Payment - ${s.name}',
          subtitle: '$paymentMethod • Payment Out',
          partyName: s.name,
          partyPhone: s.phone,
          timestamp: DateTime.now(),
          amount: amount,
          category: TransactionCategory.purchase,
          paymentMethod: paymentMethod,
          status: 'PAID',
          note: note ?? 'Supplier balance paid',
        ),
      );

      notifyListeners();
    }

    try {
      await _partyService.makeSupplierPayment(
        supplierId: supplierId,
        amount: amount,
        paymentMethod: paymentMethod,
        note: note,
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> recordPurchase({
    required String supplierId,
    required String supplierName,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String paymentMethod,
    bool isCredit = false,
  }) async {
    for (final it in items) {
      final pId = it['product_id']?.toString();
      final qty = (it['quantity'] as num?)?.toDouble() ?? 0.0;
      if (pId != null) {
        final pIdx = _products.indexWhere((p) => p.id == pId);
        if (pIdx >= 0) {
          final p = _products[pIdx];
          _products[pIdx] = p.copyWith(stock: p.stock + qty);
        }
      }
    }

    if (isCredit) {
      final sIdx = _suppliers.indexWhere((s) => s.id == supplierId);
      if (sIdx >= 0) {
        final s = _suppliers[sIdx];
        _suppliers[sIdx] =
            s.copyWith(outstandingBalance: s.outstandingBalance + totalAmount);
      }
    }

    final billNum = 'PUR-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final detailItems = items.map((it) {
      final pId = it['product_id']?.toString();
      final prod = _products.firstWhere(
        (p) => p.id == pId,
        orElse: () => Product(
          id: pId ?? '',
          name: it['name']?.toString() ?? it['product_name']?.toString() ?? 'Item',
          category: '',
          sku: '',
          price: (it['unit_price'] as num?)?.toDouble() ?? 0,
          priceUnit: it['unit']?.toString() ?? 'pkt',
          stock: 0,
          stockUnit: it['unit']?.toString() ?? 'pkt',
        ),
      );
      final qty = (it['quantity'] as num?)?.toDouble() ?? 1.0;
      final rate = (it['unit_price'] as num?)?.toDouble() ?? prod.price;
      final total = (it['subtotal'] as num?)?.toDouble() ?? (qty * rate);
      return TransactionDetailItem(
        name: prod.name,
        quantity: qty,
        unit: it['unit']?.toString() ?? prod.stockUnit,
        rate: rate,
        total: total,
      );
    }).toList();

    _transactions.insert(
      0,
      FullTransactionModel(
        id: 'pur-${DateTime.now().millisecondsSinceEpoch}',
        receiptNumber: billNum,
        title: 'Purchase from $supplierName',
        subtitle: '$paymentMethod • ${items.length} items',
        partyName: supplierName,
        timestamp: DateTime.now(),
        amount: totalAmount,
        subtotal: totalAmount,
        category: TransactionCategory.purchase,
        paymentMethod: paymentMethod,
        status: isCredit ? 'CREDIT' : 'PAID',
        items: detailItems,
      ),
    );

    _updateDashboardMetrics();
    notifyListeners();

    try {
      await _partyService.recordPurchase(
        supplierId: supplierId,
        billNumber: billNum,
        items: items,
        totalAmount: totalAmount,
        isPaid: !isCredit,
        paymentMethod: paymentMethod,
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  // ==================== POS SALES & BILLS ====================

  Future<void> _loadTodayBills() async {
    try {
      final res = await _saleService.getTodayBills();
      if (res.success && res.data != null) {
        final list = res.data!;
        if (list.isNotEmpty) {
          _todayBills = list
              .map((b) => TodayBillItem.fromJson(b as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
  }

  /// Fetch bills for any specified date (defaults to today if null)
  Future<List<TodayBillItem>> fetchBillsForDate(DateTime date) async {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      final res = await _saleService.getTodayBills(date: dateStr);
      if (res.success && res.data != null) {
        final items = res.data!
            .map((b) => TodayBillItem.fromJson(b as Map<String, dynamic>))
            .toList();
        if (isToday) {
          _todayBills = items;
          notifyListeners();
        }
        return items;
      }
    } catch (_) {}

    if (isToday) {
      return _todayBills;
    }
    return [];
  }

  Future<void> _loadTransactions() async {
    try {
      final res = await _saleService.getTransactions();
      if (res.success && res.data != null) {
        final list = (res.data!['transactions'] ?? res.data!['data']) as List<dynamic>? ?? [];
        if (list.isNotEmpty) {
          _transactions = list
              .map((t) =>
                  FullTransactionModel.fromJson(t as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
  }

  Future<TodayBillItem> completeSale({
    required List<CartItem> cartItems,
    required Customer customer,
    required double subtotal,
    required double discount,
    double taxAmount = 0,
    double additionalCharges = 0,
    required double totalAmount,
    required String paymentMethod,
    required double cashReceived,
    required double changeReturned,
    required double udharAmount,
    String note = '',
  }) async {
    final receiptNum = 'S${1025 + _todayBills.length}';
    final now = DateTime.now();

    for (final item in cartItems) {
      final idx = _products.indexWhere((p) => p.id == item.product.id);
      if (idx >= 0) {
        final p = _products[idx];
        final remaining = (p.stock - item.quantity).clamp(0.0, 999999.0);
        _products[idx] = p.copyWith(stock: remaining);
      }
    }

    if (udharAmount > 0 && !customer.isWalkIn) {
      final cIdx = _customers.indexWhere((c) => c.id == customer.id);
      if (cIdx >= 0) {
        final c = _customers[cIdx];
        _customers[cIdx] =
            c.copyWith(udharBalance: c.udharBalance + udharAmount);
      }
    }

    final detailItems = cartItems
        .map((ci) => TransactionDetailItem(
              name: ci.product.name,
              quantity: ci.quantity,
              unit: ci.unit,
              rate: ci.unitPrice,
              total: ci.totalPrice,
            ))
        .toList();

    final newBill = TodayBillItem(
      billNumber: receiptNum,
      customerName: customer.name,
      customerPhone: customer.phone,
      timestamp: now,
      amount: totalAmount,
      paymentMethod: paymentMethod,
      status: 'PAID',
      itemsCount: cartItems.length,
      itemsSummary: cartItems
          .map((i) => '${i.product.name} (${i.quantity.toInt()})')
          .join(', '),
      items: detailItems,
      subtotal: subtotal,
      discount: discount,
      taxAmount: taxAmount,
      additionalCharges: additionalCharges,
      cashReceived: cashReceived,
      changeReturned: changeReturned,
      udharAmount: udharAmount,
    );

    _todayBills.insert(0, newBill);

    _transactions.insert(
      0,
      FullTransactionModel(
        id: 'sale-${now.millisecondsSinceEpoch}',
        receiptNumber: receiptNum,
        title: 'Sale #$receiptNum',
        subtitle: '$paymentMethod • ${cartItems.length} items',
        partyName: customer.name,
        partyPhone: customer.phone,
        timestamp: now,
        amount: totalAmount,
        category: udharAmount > 0
            ? TransactionCategory.creditSale
            : TransactionCategory.sale,
        paymentMethod: paymentMethod,
        status: 'PAID',
        items: detailItems,
        subtotal: subtotal,
        discount: discount,
        tax: taxAmount,
        cashReceived: cashReceived,
        changeReturned: changeReturned,
        udharAmount: udharAmount,
        note: note,
      ),
    );

    _updateDashboardMetrics();
    notifyListeners();

    // 1. Commit offline to local SQLite database in an ACID transaction
    try {
      await _saleDao.createSale(
        items: cartItems,
        subtotal: subtotal,
        grandTotal: totalAmount,
        paymentMethod: paymentMethod,
        discount: discount,
        taxAmount: taxAmount,
        cashReceived: cashReceived,
        changeReturned: changeReturned,
        udharAmount: udharAmount,
        customerId: customer.isWalkIn ? null : customer.id,
        customerName: customer.name,
        customerPhone: customer.phone,
        note: note,
      );
      SyncEngine.instance.syncNow();
    } catch (e) {
      debugPrint('SQLite sale save note: $e');
    }

    try {
      final res = await _saleService.checkoutSale(
        customerId: customer.isWalkIn ? null : customer.id,
        items: cartItems
            .map((ci) => {
                  'product_id': ci.product.id,
                  'quantity': ci.quantity,
                  'unit_price': ci.unitPrice,
                  'unit': ci.unit,
                  'unit_name': ci.unit,
                  'subtotal': ci.totalPrice,
                })
            .toList(),
        subtotal: subtotal,
        discountAmount: discount,
        taxAmount: taxAmount,
        grandTotal: totalAmount,
        paymentMethod: paymentMethod,
        cashTendered: cashReceived,
        changeReturned: changeReturned,
        udharAmount: udharAmount,
        note: note,
      );

      if (res.success && res.data != null) {
        final serverReceipt = res.data!['receipt_number']?.toString();
        if (serverReceipt != null && serverReceipt.isNotEmpty) {
          final bIdx = _todayBills.indexOf(newBill);
          if (bIdx >= 0) {
            _todayBills[bIdx] = TodayBillItem(
              billNumber: serverReceipt,
              customerName: newBill.customerName,
              customerPhone: newBill.customerPhone,
              timestamp: newBill.timestamp,
              amount: newBill.amount,
              paymentMethod: newBill.paymentMethod,
              status: newBill.status,
              itemsCount: newBill.itemsCount,
              itemsSummary: newBill.itemsSummary,
              items: newBill.items,
              subtotal: newBill.subtotal,
              discount: newBill.discount,
              taxAmount: newBill.taxAmount,
              additionalCharges: newBill.additionalCharges,
              cashReceived: newBill.cashReceived,
              changeReturned: newBill.changeReturned,
              udharAmount: newBill.udharAmount,
            );
          }
          final tIdx = _transactions.indexWhere((t) => t.receiptNumber == receiptNum);
          if (tIdx >= 0) {
            final t = _transactions[tIdx];
            _transactions[tIdx] = FullTransactionModel(
              id: res.data!['id']?.toString() ?? t.id,
              receiptNumber: serverReceipt,
              title: 'Sale #$serverReceipt',
              subtitle: t.subtitle,
              partyName: t.partyName,
              partyPhone: t.partyPhone,
              timestamp: t.timestamp,
              amount: t.amount,
              category: t.category,
              paymentMethod: t.paymentMethod,
              status: t.status,
              items: t.items,
              subtotal: t.subtotal,
              discount: t.discount,
              tax: t.tax,
              cashReceived: t.cashReceived,
              changeReturned: t.changeReturned,
              udharAmount: t.udharAmount,
              note: t.note,
            );
          }
          notifyListeners();
        }
      }
    } catch (_) {}

    return newBill;
  }

  Future<bool> voidBill(String billNumber, String reason) async {
    final bIdx = _todayBills.indexWhere((b) => b.billNumber == billNumber);
    if (bIdx >= 0) {
      final bill = _todayBills[bIdx];

      for (final item in bill.items) {
        final pIdx = _products.indexWhere((p) => p.name == item.name);
        if (pIdx >= 0) {
          final p = _products[pIdx];
          _products[pIdx] = p.copyWith(stock: p.stock + item.quantity);
        }
      }

      // Reverse Udhar if customer had credit on this bill
      if (bill.udharAmount > 0) {
        final cIdx = _customers.indexWhere(
          (c) => c.name == bill.customerName || (bill.customerPhone.isNotEmpty && c.phone == bill.customerPhone),
        );
        if (cIdx >= 0) {
          final c = _customers[cIdx];
          _customers[cIdx] = c.copyWith(
            udharBalance: (c.udharBalance - bill.udharAmount).clamp(0.0, 999999.0),
          );
        }
      }

      _todayBills[bIdx] = TodayBillItem(
        billNumber: bill.billNumber,
        customerName: bill.customerName,
        customerPhone: bill.customerPhone,
        timestamp: bill.timestamp,
        amount: bill.amount,
        paymentMethod: bill.paymentMethod,
        status: 'VOID',
        itemsCount: bill.itemsCount,
        itemsSummary: bill.itemsSummary,
        items: bill.items,
        subtotal: bill.subtotal,
        discount: bill.discount,
        taxAmount: bill.taxAmount,
        additionalCharges: bill.additionalCharges,
        cashReceived: bill.cashReceived,
        changeReturned: bill.changeReturned,
        udharAmount: bill.udharAmount,
      );

      final tIdx =
          _transactions.indexWhere((t) => t.receiptNumber == billNumber);
      if (tIdx >= 0) {
        final t = _transactions[tIdx];
        _transactions[tIdx] = FullTransactionModel(
          id: t.id,
          receiptNumber: t.receiptNumber,
          title: t.title,
          subtitle: t.subtitle,
          partyName: t.partyName,
          partyPhone: t.partyPhone,
          timestamp: t.timestamp,
          amount: t.amount,
          category: t.category,
          paymentMethod: t.paymentMethod,
          status: 'VOID',
          items: t.items,
          subtotal: t.subtotal,
          discount: t.discount,
          tax: t.tax,
          cashReceived: t.cashReceived,
          changeReturned: t.changeReturned,
          udharAmount: t.udharAmount,
          note: 'Cancelled: $reason',
        );
      }

      _updateDashboardMetrics();
      notifyListeners();
    }

    // 1. Commit cancellation locally to SQLite
    try {
      await _saleDao.cancelSale(
        receiptNumber: billNumber,
        reason: reason,
      );
      SyncEngine.instance.syncNow();
    } catch (e) {
      debugPrint('SQLite cancelSale note: $e');
    }

    // 2. Call backend server
    try {
      await _saleService.cancelSale(
        receiptNumber: billNumber,
        reason: reason,
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Process item return / sales return
  Future<bool> returnBillItems({
    required String billNumber,
    required List<TransactionDetailItem> returnedItems,
    required String reason,
    required String refundMethod,
    required double refundAmount,
    bool restockItems = true,
  }) async {
    // 1. Restock items in memory
    if (restockItems) {
      for (final item in returnedItems) {
        final pIdx = _products.indexWhere((p) => p.name == item.name);
        if (pIdx >= 0) {
          final p = _products[pIdx];
          _products[pIdx] = p.copyWith(stock: p.stock + item.quantity);
        }
      }
    }

    // 2. Adjust customer Udhar Khata if refunded via Credit / Udhar
    if (refundMethod.contains('Credit') || refundMethod.contains('Udhar')) {
      final bIdx = _todayBills.indexWhere((b) => b.billNumber == billNumber);
      if (bIdx >= 0) {
        final bill = _todayBills[bIdx];
        final cIdx = _customers.indexWhere(
          (c) => c.name == bill.customerName || (bill.customerPhone.isNotEmpty && c.phone == bill.customerPhone),
        );
        if (cIdx >= 0) {
          final c = _customers[cIdx];
          _customers[cIdx] = c.copyWith(
            udharBalance: (c.udharBalance - refundAmount).clamp(0.0, 999999.0),
          );
        }
      }
    }

    // 3. Add a refund transaction record in memory
    final now = DateTime.now();
    _transactions.insert(
      0,
      FullTransactionModel(
        id: 'ret-${now.millisecondsSinceEpoch}',
        receiptNumber: 'RET-$billNumber',
        title: 'Return • Bill #$billNumber',
        subtitle: '$refundMethod • Returned ${returnedItems.length} items',
        partyName: 'Customer',
        timestamp: now,
        amount: refundAmount,
        category: TransactionCategory.sale,
        paymentMethod: refundMethod,
        status: 'REFUNDED',
        items: returnedItems,
        note: 'Sales Return: $reason',
      ),
    );

    _updateDashboardMetrics();
    notifyListeners();

    // 4. Record in SQLite via SaleDao
    try {
      await _saleDao.returnItems(
        receiptNumber: billNumber,
        returnedItems: returnedItems.map((it) => {
          'name': it.name,
          'quantity': it.quantity,
          'unit': it.unit,
          'rate': it.rate,
          'total': it.total,
          'restock': restockItems,
        }).toList(),
        reason: reason,
        refundMethod: refundMethod,
        refundAmount: refundAmount,
      );
      SyncEngine.instance.syncNow();
    } catch (e) {
      debugPrint('SQLite returnItems note: $e');
    }

    // 5. Sync to backend API if available
    try {
      await _saleService.returnItems(
        receiptNumber: billNumber,
        items: returnedItems.map((it) => {
          'name': it.name,
          'quantity': it.quantity,
          'rate': it.rate,
          'total': it.total,
        }).toList(),
        reason: reason,
        refundMethod: refundMethod,
        refundAmount: refundAmount,
      );
    } catch (_) {}

    return true;
  }

  // ==================== EXPENSES ====================

  /// Record a store expense offline in SQLite and queue for sync.
  Future<bool> recordExpense({
    required String title,
    required double amount,
    required String categoryName,
    String paymentMethod = 'Cash',
    String? note,
  }) async {
    try {
      await _expenseDao.recordExpense(
        title: title,
        amount: amount,
        categoryName: categoryName,
        paymentMethod: paymentMethod,
        note: note,
      );
      SyncEngine.instance.syncNow();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==================== DASHBOARD ====================

  Future<void> _loadDashboard() async {
    try {
      final resOverview = await _dashboardService.getOverview();
      if (resOverview.success && resOverview.data != null) {
        _dashboardOverview.addAll(resOverview.data!);
      }

      final resStats = await _dashboardService.getStats();
      if (resStats.success && resStats.data != null) {
        _dashboardStats.addAll(resStats.data!);
      }
    } catch (_) {
      _updateDashboardMetrics();
    }
  }

  void _updateDashboardMetrics() {
    _lowStockProducts = _products.where((p) => p.isLowStock).toList();

    double total = 0.0;
    double cash = 0.0;
    double card = 0.0;
    double udhar = 0.0;

    for (final bill in _todayBills.where((b) => b.status != 'VOID')) {
      total += bill.amount;
      if (bill.paymentMethod == 'Cash') {
        cash += bill.amount;
      } else if (bill.paymentMethod.contains('Card') ||
          bill.paymentMethod.contains('QR') ||
          bill.paymentMethod.contains('Online') ||
          bill.paymentMethod.contains('Fonepay')) {
        card += bill.amount;
      } else if (bill.paymentMethod.contains('Credit') ||
          bill.paymentMethod.contains('Udhar')) {
        udhar += bill.amount;
      }
    }

    _dashboardOverview['total_sales'] = total;
    _dashboardOverview['cash_amount'] = cash;
    _dashboardOverview['card_amount'] = card;
    _dashboardOverview['udhar_amount'] = udhar;
    _dashboardOverview['bills_count'] =
        _todayBills.where((b) => b.status != 'VOID').length;

    _dashboardStats['total_products'] = _products.length;
    _dashboardStats['total_customers'] = _customers.length;
    _dashboardStats['low_stock_items'] = _lowStockProducts.length;
    _dashboardStats['todays_bills'] =
        _todayBills.where((b) => b.status != 'VOID').length;
  }
}
