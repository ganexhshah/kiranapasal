import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/notifications/domain/models/shop_notification.dart';
import '../repositories/app_data_repository.dart';

/// Builds the in-app notification feed from live repository data and remembers
/// which entries the shopkeeper has already read.
///
/// Read state is persisted in [SharedPreferences] so the bell badge is not red
/// forever: previously it defaulted to `true` and every visit rebuilt the list
/// with `isRead: false`, so "Mark all read" never survived a screen change.
class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _prefKey = 'krm_read_notification_ids';

  final Set<String> _readIds = <String>{};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _readIds
        ..clear()
        ..addAll(prefs.getStringList(_prefKey) ?? const <String>[]);
    } catch (_) {
      // Preferences unavailable: fall back to in-memory read state.
    }
    _loaded = true;
    notifyListeners();
  }

  bool isRead(String id) => _readIds.contains(id);

  Future<void> setRead(String id, {bool read = true}) async {
    if (read) {
      _readIds.add(id);
    } else {
      _readIds.remove(id);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> markAllRead(Iterable<String> ids) async {
    _readIds.addAll(ids);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, _readIds.toList());
    } catch (_) {
      // Ignore persistence failures; UI still reflects the change this session.
    }
  }

  /// Live feed derived from low stock, today's bills and outstanding udhar.
  /// Read state comes from the persisted store instead of always being false.
  List<ShopNotification> build() {
    final repo = AppDataRepository.instance;
    final list = <ShopNotification>[];

    for (final p in repo.lowStockProducts) {
      final id = 'stock_${p.id}';
      list.add(
        ShopNotification(
          id: id,
          title: 'Low Stock: ${p.name}',
          message:
              'Only ${p.formattedStock} remaining in stock (below threshold of ${p.lowStockThreshold.toInt()} ${p.stockUnit}).',
          category: NotificationCategory.stock,
          timestamp: DateTime.now(),
          isRead: isRead(id),
          actionLabel: 'Restock',
        ),
      );
    }

    for (final b in repo.todayBills.take(5)) {
      final id = 'sale_${b.billNumber}';
      list.add(
        ShopNotification(
          id: id,
          title: 'Invoice #${b.billNumber}',
          message: '${b.customerName} - Rs. ${b.amount.toInt()} via ${b.paymentMethod}',
          category: NotificationCategory.sales,
          timestamp: b.timestamp,
          isRead: isRead(id),
          actionLabel: 'View Bill',
        ),
      );
    }

    for (final c in repo.customers.where((c) => c.udharBalance > 0)) {
      final id = 'udhar_${c.id}';
      list.add(
        ShopNotification(
          id: id,
          title: 'Pending Udhar: ${c.name}',
          message: 'Outstanding credit of Rs. ${c.udharBalance.toInt()} pending.',
          category: NotificationCategory.sales,
          timestamp: DateTime.now(),
          isRead: isRead(id),
          actionLabel: 'Collect',
        ),
      );
    }

    return list;
  }

  int get unreadCount => build().where((n) => !n.isRead).length;
}
