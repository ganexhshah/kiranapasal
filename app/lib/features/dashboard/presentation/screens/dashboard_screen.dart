import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/parse_utils.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../credit/credit.dart';
import '../../../customers/customers.dart';
import '../../../more/more.dart';
import '../../../notifications/notifications.dart';
import '../../../parties/parties.dart';
import '../../../products/products.dart';
import '../../../profile/profile.dart';
import '../../../sales/sales.dart';
import '../widgets/dashboard_bottom_nav.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/recent_transactions_section.dart';
import '../widgets/today_sales_card.dart';

/// Complete Dashboard screen with fixed pinned header, full white background, and scrollable body.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  int _navIndex = 0;
  String _userName = '';
  String? _avatarUrl;
  String _userInitials = 'KO';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    NotificationService.instance.load().then((_) {
      if (mounted) setState(() {});
    });
    NotificationService.instance.addListener(_onNotificationsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppDataRepository.instance.initialize();
    });
  }

  void _onNotificationsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    NotificationService.instance.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final res = await _authService.getProfile();
    if (res.success && res.data != null && mounted) {
      final user = res.data!['user'] as Map<String, dynamic>?;
      if (user != null) {
        final name = (user['name'] as String?)?.trim() ?? '';
        final avatar = user['avatar_url'] as String?;
        String initials = 'KO';
        if (name.isNotEmpty) {
          final parts = name
              .split(RegExp(r'\s+'))
              .where((p) => p.isNotEmpty)
              .toList();
          if (parts.length >= 2) {
            initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
          } else if (parts.isNotEmpty) {
            initials =
                parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
          }
        }
        setState(() {
          _userName = name;
          _avatarUrl = avatar;
          _userInitials = initials;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Pinned Header at the Top (Standardized 56px height, consistent status notch gap)
                Container(
                  height: 56.0,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: DashboardHeader(
                    greeting: _userName.isNotEmpty
                        ? 'Hi, ${_userName.split(' ').first}!'
                        : 'Hi there!',
                    userInitials: _userInitials,
                    profileImageUrl: _avatarUrl,
                    hasUnreadNotifications:
                        NotificationService.instance.unreadCount > 0,
                    onProfileTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                      _loadProfile();
                    },
                    onSearchTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ProductsScreen()),
                      );
                    },
                    onNotificationTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    },
                  ),
                ),

                // 2. Scrollable Body Content (Solid pure white background with Drag-to-Refresh)
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: RefreshIndicator(
                      color: const Color(0xFF0066FF),
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        await Future.wait([
                          AppDataRepository.instance.refreshAll(),
                          _loadProfile(),
                        ]);
                      },
                      child: ListenableBuilder(
                        listenable: AppDataRepository.instance,
                        builder: (context, _) {
                          final repo = AppDataRepository.instance;
                          final overview = repo.dashboardOverview;
                          final stats = repo.dashboardStats;

                          final totalSalesVal = parseDouble(overview['total_sales']);
                          final cashVal = parseDouble(overview['cash_amount']);
                          final cardVal = parseDouble(overview['card_amount']);
                          final udharVal = parseDouble(overview['udhar_amount']);

                          final totalProductsCount = parseInt(stats['total_products'], repo.products.length);
                          final totalCustomersCount = parseInt(stats['total_customers'], repo.customers.length);
                          final lowStockCount = parseInt(stats['low_stock_items'], repo.lowStockProducts.length);
                          final todaysBillsCount = parseInt(stats['todays_bills'], repo.todayBills.length);

                          if (repo.isLoading && repo.products.isEmpty && repo.todayBills.isEmpty) {
                            return const DashboardSkeleton();
                          }

                          // Nothing cached and the last sync failed: say so
                          // instead of rendering a convincing zero-sales day.
                          final hasNoData = repo.products.isEmpty &&
                              repo.todayBills.isEmpty &&
                              repo.customers.isEmpty;
                          if (repo.lastError != null && hasNoData) {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const Gap(60),
                                AppErrorState(
                                  onRetry: () => repo.refreshAll(force: true),
                                ),
                              ],
                            );
                          }

                          final recentList = repo.transactions.take(5).map((t) {
                            final isSale = t.category == TransactionCategory.sale || t.category == TransactionCategory.creditSale;
                            return TransactionData(
                              title: t.title,
                              subtitle: '${DateFormat('h:mm a').format(t.timestamp)} | ${t.paymentMethod}',
                              amount: '${t.isInflow ? '+' : '-'} Rs. ${t.amount.toStringAsFixed(2)}',
                              amountColor: t.isInflow ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              icon: isSale ? LucideIcons.shoppingCart : (t.category == TransactionCategory.udharPayment ? LucideIcons.user : LucideIcons.package),
                              iconColor: isSale ? const Color(0xFF10B981) : const Color(0xFF0866FF),
                              iconBackgroundColor: isSale ? const Color(0xFFE6F8F0) : const Color(0xFFE8F1FF),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => TransactionDetailsScreen(
                                      receiptNumber: t.receiptNumber,
                                      title: t.title,
                                      customerName: t.partyName,
                                      customerPhone: t.partyPhone,
                                      timestamp: t.timestamp,
                                      items: t.items,
                                      subtotal: t.subtotal,
                                      discountAmount: t.discount,
                                      taxAmount: t.tax,
                                      totalAmount: t.amount,
                                      paymentMethod: t.paymentMethod,
                                      paymentStatus: t.status,
                                      cashReceived: t.cashReceived,
                                      changeReturned: t.changeReturned,
                                      udharAmount: t.udharAmount,
                                      note: t.note,
                                      isPurchase: t.category == TransactionCategory.purchase,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList();

                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Compact Quick Actions
                                QuickActionsSection(
                                  onNewSale: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const SalesScreen()),
                                    );
                                  },
                                  onProducts: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const ProductsScreen()),
                                    );
                                  },
                                  onCustomers: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const CustomersScreen()),
                                    );
                                  },
                                  onViewAll: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const CreditManagementScreen()),
                                    );
                                  },
                                ),
                                const Gap(18),

                                // Today's Sales Deep Blue Card
                                TodaySalesCard(
                                  title: "Today's Sales",
                                  date: overview['date']?.toString() ?? DateFormat('EEE, dd MMM yyyy').format(DateTime.now()),
                                  totalSales: formatMoney(totalSalesVal),
                                  cashAmount: formatMoney(cashVal),
                                  cardAmount: formatMoney(cardVal),
                                  udharAmount: formatMoney(udharVal),
                                  onMoreTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const TodayBillsScreen()),
                                    );
                                  },
                                ),
                                const Gap(18),

                                // 2x2 Statistics Grid
                                DashboardStatsGrid(
                                  totalProducts: totalProductsCount.toString(),
                                  totalCustomers: totalCustomersCount.toString(),
                                  lowStockItems: lowStockCount.toString(),
                                  todaysBills: todaysBillsCount.toString(),
                                  onProductsTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const ProductsScreen()),
                                    );
                                  },
                                  onCustomersTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const CustomersScreen()),
                                    );
                                  },
                                  onLowStockTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const LowStockScreen()),
                                    );
                                  },
                                  onBillsTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const TodayBillsScreen()),
                                    );
                                  },
                                ),
                                const Gap(22),

                                // Recent Transactions Section
                                RecentTransactionsSection(
                                  transactions: recentList,
                                  onViewAllTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const TransactionsScreen()),
                                    );
                                  },
                                ),
                                const Gap(16),
                              ],
                            ),
                          );
                        },
                      ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: DashboardBottomNav(
          currentIndex: _navIndex,
          onTap: (index) {
            if (index == 1) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProductsScreen()),
              );
            } else if (index == 2) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SalesScreen()),
              );
            } else if (index == 3) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PartiesScreen()),
              );
            } else if (index == 4) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MoreScreen()),
              );
            } else {
              setState(() => _navIndex = index);
            }
          },
        ),
      ),
    );
  }
}
