import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../parties/parties.dart';
import '../../../products/products.dart';
import '../../../sales/sales.dart';
import '../../domain/models/shop_notification.dart';

/// Tab-wise Notification Screen providing filterable shop alerts (All, Stock, Sales/Udhar, System).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<ShopNotification> _notifications;

  final List<String> _tabs = const [
    'All',
    'Stock Alerts',
    'Sales & Udhar',
    'System',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _notifications = NotificationService.instance.build();

    // Load persisted read state, then rebuild so badges match what the
    // shopkeeper actually saw last time.
    NotificationService.instance.load().then((_) {
      if (!mounted) return;
      setState(() => _notifications = NotificationService.instance.build());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  List<ShopNotification> _getFilteredNotifications(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _notifications.where((n) => n.category == NotificationCategory.stock).toList();
      case 2:
        return _notifications.where((n) => n.category == NotificationCategory.sales).toList();
      case 3:
        return _notifications.where((n) => n.category == NotificationCategory.system).toList();
      case 0:
      default:
        return _notifications;
    }
  }

  Future<void> _markAllAsRead() async {
    final ids = _notifications.map((n) => n.id).toList();
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    await NotificationService.instance.markAllRead(ids);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  Future<void> _toggleRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index < 0) return;
    final nowRead = !_notifications[index].isRead;
    setState(() {
      _notifications[index] = _notifications[index].copyWith(isRead: nowRead);
    });
    await NotificationService.instance.setRead(id, read: nowRead);
  }

  /// The action pill ("Restock" / "View Bill" / "Collect") opens the screen
  /// where the shopkeeper can act, instead of being an inert label.
  Future<void> _openAction(ShopNotification item) async {
    await _toggleRead(item.id);
    if (!mounted) return;

    Widget target;
    switch (item.category) {
      case NotificationCategory.stock:
        target = const LowStockScreen();
        break;
      case NotificationCategory.sales:
        target = item.id.startsWith('udhar_')
            ? const PartiesScreen()
            : const TodayBillsScreen();
        break;
      case NotificationCategory.system:
        return;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => target));
  }

  void _deleteNotification(String id) {
    final removed = _notifications.firstWhere((n) => n.id == id);
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification dismissed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _notifications.insert(0, removed));
          },
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  (IconData, Color) _getCategoryStyle(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.stock:
        return (LucideIcons.alertTriangle, const Color(0xFFEF4444));
      case NotificationCategory.sales:
        return (LucideIcons.wallet, const Color(0xFF0066FF));
      case NotificationCategory.system:
        return (LucideIcons.bellRing, const Color(0xFF7C3AED));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Top Pinned Header (Standardized 56px height, consistent status notch gap)
              Container(
                height: 56.0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.arrowLeft, size: 20),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                    const Gap(6),
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.darkText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (_unreadCount > 0) ...[
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_unreadCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (_unreadCount > 0)
                      TextButton.icon(
                        onPressed: _markAllAsRead,
                        icon: const Icon(LucideIcons.checkCheck, size: 14, color: Color(0xFF0066FF)),
                        label: const Text(
                          'Mark all read',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0066FF),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),

              // 2. Tab Bar Selector (Clean Segmented / Pill Style)
              Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF0066FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: colors.inputLabel,
                  labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                  tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                ),
              ),
              const Gap(6),

              // 3. Tab Bar View Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: List.generate(_tabs.length, (tabIndex) {
                    final items = _getFilteredNotifications(tabIndex);

                    return RefreshIndicator(
                      color: const Color(0xFF0066FF),
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        await AppDataRepository.instance.refreshAll();
                        if (mounted) {
                          setState(() =>
                              _notifications = NotificationService.instance.build());
                        }
                      },
                      child: items.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const Gap(80),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF1F5F9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          LucideIcons.bellOff,
                                          size: 24,
                                          color: colors.inputLabel,
                                        ),
                                      ),
                                      const Gap(12),
                                      Text(
                                        'No notifications',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: colors.darkText,
                                        ),
                                      ),
                                      const Gap(4),
                                      Text(
                                        'You are all caught up in ${_tabs[tabIndex]}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.inputLabel,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                              itemCount: items.length + 1,
                              separatorBuilder: (ctx, i) => const Gap(8),
                              itemBuilder: (ctx, i) {
                                if (i == items.length) {
                                  return const AppBottomLoader(hasMore: false);
                                }
                                final item = items[i];
                                final (icon, iconColor) = _getCategoryStyle(item.category);

                                return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 20),
                          ),
                          onDismissed: (_) => _deleteNotification(item.id),
                          child: InkWell(
                            onTap: () => _toggleRead(item.id),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: item.isRead ? const Color(0xFFF8FAFC) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: item.isRead
                                    ? null
                                    : Border.all(color: const Color(0xFFBFDBFE), width: 1),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category Icon Accent
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: iconColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(icon, size: 18, color: iconColor),
                                  ),
                                  const Gap(12),

                                  // Notification Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                                  color: colors.darkText,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatTimestamp(item.timestamp),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: colors.inputLabel,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Gap(4),
                                        Text(
                                          item.message,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.inputLabel,
                                            height: 1.35,
                                          ),
                                        ),
                                        if (item.actionLabel != null) ...[
                                          const Gap(8),
                                          InkWell(
                                            onTap: () => _openAction(item),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: colors.inputBorder.withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Text(
                                                item.actionLabel!,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF0066FF),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (!item.isRead) ...[
                                    const Gap(8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF0066FF),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

