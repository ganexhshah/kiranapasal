import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../database/daos/party_dao.dart';
import '../database/daos/product_dao.dart';
import '../database/daos/sync_outbox_dao.dart';
import '../database/database_constants.dart';
import '../network/api_client.dart';
import '../services/party_backend_service.dart';
import '../services/product_backend_service.dart';

/// Central background Synchronization Engine for pasal365.
/// Manages real-time connectivity listening, outbox queue draining,
/// and pulling server updates into local SQLite tables.
class SyncEngine extends ChangeNotifier {
  SyncEngine._();
  static final SyncEngine instance = SyncEngine._();

  final SyncOutboxDao _outboxDao = const SyncOutboxDao();
  final ProductDao _productDao = const ProductDao();
  final PartyDao _partyDao = const PartyDao();

  final ProductBackendService _productBackend = ProductBackendService();
  final PartyBackendService _partyBackend = PartyBackendService();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicTimer;

  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingCount = 0;
  DateTime? _lastSyncedAt;
  String? _lastSyncError;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastSyncError => _lastSyncError;

  /// Initialize connectivity listeners and scheduled sync timer.
  Future<void> initialize() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = !results.contains(ConnectivityResult.none);
    } catch (_) {
      _isOnline = true;
    }

    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);
      notifyListeners();

      // Trigger automatic sync immediately when network is restored
      if (!wasOnline && _isOnline) {
        syncNow();
      }
    });

    // Periodic sync check every 60 seconds
    _periodicTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_isOnline && !_isSyncing) {
        syncNow();
      }
    });

    await refreshPendingCount();
  }

  /// Update count of pending outbox mutations.
  Future<void> refreshPendingCount() async {
    try {
      _pendingCount = await _outboxDao.getPendingCount();
      notifyListeners();
    } catch (_) {}
  }

  /// Trigger a sync cycle (Push local mutations + Pull server updates).
  Future<void> syncNow({bool forcePull = false}) async {
    if (_isSyncing) return;
    if (!_isOnline && !forcePull) return;

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      // 1. Drain pending outbox mutations (Push)
      await _drainOutbox();

      // 2. Pull server changes into SQLite if authenticated
      if (ApiClient.instance.isAuthenticated) {
        await _pullServerChanges();
      }

      _lastSyncedAt = DateTime.now();
      await refreshPendingCount();
    } catch (e) {
      _lastSyncError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Process pending mutations in the outbox in causal order.
  Future<void> _drainOutbox() async {
    final pendingItems = await _outboxDao.getPending(limit: 30);
    if (pendingItems.isEmpty) return;

    for (final item in pendingItems) {
      try {
        await _pushItem(item);
        await _outboxDao.deleteCompleted([item.id]);
      } catch (e) {
        await _outboxDao.recordFailure(item.id, e.toString());
      }
    }
  }

  /// Dispatch individual outbox item to backend API.
  Future<void> _pushItem(OutboxItem item) async {
    switch (item.entityType) {
      case DatabaseConstants.entitySale:
        // Push sale to backend
        final res = await ApiClient.instance.post(
          '/sales',
          body: item.payload,
        );
        if (!res.success && res.statusCode != 409) {
          throw Exception(res.message.isNotEmpty ? res.message : 'Failed to sync sale');
        }
        break;

      case DatabaseConstants.entityProduct:
        final res = await ApiClient.instance.post(
          '/products',
          body: item.payload,
        );
        if (!res.success && res.statusCode != 409) {
          throw Exception(res.message.isNotEmpty ? res.message : 'Failed to sync product');
        }
        break;

      case DatabaseConstants.entityCustomerLedger:
        final res = await ApiClient.instance.post(
          '/parties/customers/${item.payload['customer_id']}/payments',
          body: item.payload,
        );
        if (!res.success && res.statusCode != 409) {
          throw Exception(res.message.isNotEmpty ? res.message : 'Failed to sync customer payment');
        }
        break;

      case DatabaseConstants.entityExpense:
        final res = await ApiClient.instance.post(
          '/expenses',
          body: item.payload,
        );
        if (!res.success && res.statusCode != 409) {
          throw Exception(res.message.isNotEmpty ? res.message : 'Failed to sync expense');
        }
        break;

      default:
        // Generic mutation or no-op
        break;
    }
  }

  /// Pull server catalog and parties into SQLite.
  Future<void> _pullServerChanges() async {
    // 1. Pull products from server
    try {
      final remoteProducts = await _productBackend.fetchProducts();
      if (remoteProducts.isNotEmpty) {
        await _productDao.upsertProductsBatch(remoteProducts, markLocalDirty: false);
      }
    } catch (_) {}

    // 2. Pull customers from server
    try {
      final remoteCustomers = await _partyBackend.fetchCustomers();
      if (remoteCustomers.isNotEmpty) {
        await _partyDao.upsertCustomersBatch(remoteCustomers, markLocalDirty: false);
      }
    } catch (_) {}

    // 3. Pull suppliers from server
    try {
      final remoteSuppliers = await _partyBackend.fetchSuppliers();
      if (remoteSuppliers.isNotEmpty) {
        await _partyDao.upsertSuppliersBatch(remoteSuppliers, markLocalDirty: false);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }
}
