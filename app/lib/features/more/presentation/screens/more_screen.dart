import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/printing_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import 'printer_settings_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../credit/credit.dart';
import '../../../customers/customers.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../../../dashboard/presentation/widgets/dashboard_header.dart';
import '../../../notifications/notifications.dart';
import '../../../parties/parties.dart';
import '../../../products/products.dart';
import '../../../profile/profile.dart';
import '../../../sales/sales.dart';
import '../../../suppliers/suppliers.dart';

/// Clean, modern More screen for managing shop settings, customers, suppliers, expenses, and account.
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final int _navIndex = 4;
  final AuthService _authService = AuthService();

  String _userName = '';
  String _userEmail = '';
  String? _avatarUrl;
  String _userInitials = 'KO';
  String? _shopLogoUrl;

  ShopProfileData _shopData = const ShopProfileData(
    shopName: 'My Kirana Store',
    address: 'Kathmandu, Nepal',
    phone: '',
    panNumber: '',
  );

  @override
  void initState() {
    super.initState();
    final cachedName = ApiClient.instance.userName ?? '';
    _userName = cachedName;
    _avatarUrl = ApiClient.instance.userAvatar;
    if (cachedName.isNotEmpty) {
      final parts = cachedName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        _userInitials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty) {
        _userInitials = parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
      }
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final res = await _authService.getProfile();
    if (res.success && res.data != null && mounted) {
      final user = res.data!['user'] as Map<String, dynamic>?;
      final shop = (user?['current_shop'] ?? res.data!['shop']) as Map<String, dynamic>?;

      setState(() {
        if (user != null) {
          _userName = (user['name'] as String?)?.trim() ?? '';
          _userEmail = (user['email'] as String?) ?? '';
          _avatarUrl = user['avatar_url'] as String?;
          if (_userName.isNotEmpty) {
            final parts = _userName
                .split(RegExp(r'\s+'))
                .where((p) => p.isNotEmpty)
                .toList();
            if (parts.length >= 2) {
              _userInitials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
            } else if (parts.isNotEmpty) {
              _userInitials =
                  parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
            }
          }
        }

        if (shop != null) {
          _shopLogoUrl = shop['logo_url'] as String?;
          _shopData = ShopProfileData(
            shopName: (shop['name'] as String?) ?? _shopData.shopName,
            address: (shop['address'] as String?) ?? _shopData.address,
            phone: (shop['phone'] as String?) ?? _shopData.phone,
            panNumber: (shop['pan_vat_number'] as String?) ?? _shopData.panNumber,
          );
          PrintingService.instance.updateSettings(
            storeName: _shopData.shopName,
            storeAddress: _shopData.address,
            storePhone: _shopData.phone,
            panNumber: _shopData.panNumber,
          );
        }
      });
    }
  }

  Future<void> _openProfileScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
    _loadProfile();
  }

  Future<void> _openShopProfile() async {
    final updated = await ShopProfileSheet.show(
      context,
      initialData: _shopData,
    );
    if (updated != null && mounted) {
      setState(() => _shopData = updated);
      await PrintingService.instance.updateSettings(
        storeName: updated.shopName,
        storeAddress: updated.address,
        storePhone: updated.phone,
        panNumber: updated.panNumber,
      );
      await ApiClient.instance.put(
        ApiConfig.shopProfile,
        body: {
          'name': updated.shopName,
          'address': updated.address,
          'phone': updated.phone,
          'pan_vat_number': updated.panNumber,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop profile updated successfully')),
        );
      }
    }
  }

  /// Pulls the latest data from the backend. Replaces the old "Backup & Restore"
  /// tile, which claimed to create backups but only re-fetched data.
  Future<void> _refreshData() async {
    final repo = AppDataRepository.instance;
    await repo.refreshAll();
    if (!mounted) return;

    if (repo.lastError != null && repo.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't refresh. Check your connection and try again."),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Data refreshed — ${repo.products.length} products, '
          '${repo.customers.length} customers, ${repo.todayBills.length} bills today',
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _openExpenseEntry() async {
    final result = await ExpenseEntrySheet.show(context);
    if (result != null && mounted) {
      try {
        final res = await ApiClient.instance.post<Map<String, dynamic>>(
          ApiConfig.expenses,
          body: {
            'category': result.category,
            'amount': result.amount,
            'payment_method': result.paymentMethod,
            'note': result.note,
            'expense_date': DateTime.now().toIso8601String().substring(0, 10),
          },
          fromData: (data) => data as Map<String, dynamic>,
        );
        if (mounted) {
          if (res.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Expense of Rs. ${result.amount.toInt()} saved for ${result.category}'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res.message.isNotEmpty ? res.message : 'Failed to save expense'),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving expense: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  void _openCustomers() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CustomersScreen()),
    );
  }

  void _openCreditManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreditManagementScreen()),
    );
  }

  void _openSuppliers() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SuppliersScreen()),
    );
  }

  void _openTransactions() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TransactionsScreen()),
    );
  }

  void _openTodayBills() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TodayBillsScreen()),
    );
  }

  void _openLowStock() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LowStockScreen()),
    );
  }

  void _openBackendSettings() {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    bool testing = false;
    String? testResult;
    bool isConnected = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(14),
              const Text(
                'Backend API Server',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const Gap(4),
              const Text(
                'Configure the base URL connecting this Flutter app to your Laravel backend & Docker containers.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const Gap(16),
              TextField(
                controller: controller,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'http://10.0.2.2/api/v1',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(LucideIcons.server, size: 18),
                ),
              ),
              const Gap(10),
              if (testResult != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isConnected ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isConnected ? LucideIcons.circleCheck : LucideIcons.circleAlert,
                        size: 16,
                        color: isConnected ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          testResult!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isConnected ? const Color(0xFF166534) : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Gap(14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: testing
                          ? null
                          : () async {
                              setSheetState(() {
                                testing = true;
                                testResult = null;
                              });

                              final testUrl = controller.text.trim();
                              await ApiConfig.setCustomBaseUrl(testUrl);
                              final res = await ApiClient.instance.get('/dashboard/overview');

                              setSheetState(() {
                                testing = false;
                                isConnected = res.statusCode > 0 && res.statusCode < 500;
                                testResult = isConnected
                                    ? 'Connected successfully to backend API!'
                                    : 'Cannot connect: ${res.message}';
                              });
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(testing ? 'Testing...' : 'Test Connection'),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final newUrl = controller.text.trim();
                        await ApiConfig.setCustomBaseUrl(newUrl);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Saved backend URL: ${ApiConfig.baseUrl}')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save & Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSalesFilter() async {
    final options = await SalesFilterSheet.show(context);
    if (options != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Filtering ${options.datePeriod} sales (${options.paymentMethod})')),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await LogoutConfirmationSheet.show(context);
    if (confirm && mounted) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String sectionTitle,
    required List<Widget> children,
  }) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            sectionTitle,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.inputLabel,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const Gap(6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: children,
          ),
        ),
        const Gap(16),
      ],
    );
  }

  Widget _buildMoreTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? const Color(0xFFEF4444) : colors.darkText,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const Gap(2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.inputLabel,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Reusable Top Header (Standardized 56px height, consistent status notch gap)
              Container(
                height: 56.0,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: DashboardHeader(
                  greeting: 'More',
                  userInitials: _userInitials,
                  profileImageUrl: _avatarUrl,
                  onProfileTap: _openProfileScreen,
                  onSearchTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search in More')),
                    );
                  },
                  onNotificationTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                    );
                  },
                ),
              ),

              // 2. Scrollable Body with Drag-to-Refresh
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF0066FF),
                  backgroundColor: Colors.white,
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shop Profile Card (Clean, neutral)
                        InkWell(
                          onTap: _openProfileScreen,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: _shopLogoUrl != null && _shopLogoUrl!.isNotEmpty
                                      ? AppLazyImage(
                                          imageUrl: _shopLogoUrl!,
                                          width: 44,
                                          height: 44,
                                          borderRadius: BorderRadius.circular(12),
                                          fallbackIcon: LucideIcons.store,
                                        )
                                      : Icon(LucideIcons.store, color: colors.darkText, size: 22),
                                ),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _shopData.shopName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: colors.darkText,
                                      ),
                                    ),
                                    const Gap(2),
                                    Text(
                                      _shopData.address.isNotEmpty
                                          ? '${_shopData.address}${_shopData.panNumber.isNotEmpty ? ' • PAN: ${_shopData.panNumber}' : ''}'
                                          : (_shopData.panNumber.isNotEmpty ? 'PAN: ${_shopData.panNumber}' : 'Manage your shop info'),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: colors.inputLabel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _openShopProfile,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0066FF),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(18),

                      // Business Operations Section
                      _buildSectionCard(
                        context: context,
                        sectionTitle: 'Business Operations',
                        children: [
                          _buildMoreTile(
                            context: context,
                            icon: LucideIcons.users,
                            iconColor: const Color(0xFF475569),
                            title: 'Customers Directory',
                            onTap: _openCustomers,
                          ),
                          _buildMoreTile(
                            context: context,
                            icon: LucideIcons.bookOpenCheck,
                            iconColor: const Color(0xFF475569),
                            title: 'Credit & Udhar Khata',
                            onTap: _openCreditManagement,
                          ),
                          _buildMoreTile(
                            context: context,
                            icon: LucideIcons.truck,
                            iconColor: const Color(0xFF475569),
                            title: 'Suppliers & Purchases',
                            onTap: _openSuppliers,
                          ),
                          _buildMoreTile(
                            context: context,
                            icon: LucideIcons.wallet,
                            iconColor: const Color(0xFF475569),
                            title: 'Shop Expenses',
                            onTap: _openExpenseEntry,
                          ),
                          _buildMoreTile(
                            context: context,
                            icon: LucideIcons.receiptText,
                            iconColor: const Color(0xFF475569),
                            title: "Today's Bills",
                            subtitle: 'View all bills generated today',
                            onTap: _openTodayBills,
                          ),
                          _buildMoreTile(
                            context: context,
                            icon: LucideIcons.arrowLeftRight,
                            iconColor: const Color(0xFF475569),
                            title: 'All Transactions',
                            subtitle: 'Ledger & financial transaction history',
                            onTap: _openTransactions,
                          ),
                          _buildMoreTile(
                            context: context,
                            icon: LucideIcons.triangleAlert,
                            iconColor: const Color(0xFF475569),
                            title: 'Low Stock Alert Items',
                            subtitle: 'Manage items below safety threshold',
                            onTap: _openLowStock,
                          ),
                          _buildMoreTile(
                            context: context,
                            icon: LucideIcons.fileText,
                            iconColor: const Color(0xFF475569),
                            title: 'Bills & Sales Reports',
                            onTap: _openSalesFilter,
                          ),
                        ],
                      ),

                      // Settings & Preferences Section
                      _buildSectionCard(
                        context: context,
                        sectionTitle: 'Settings & Preferences',
                        children: [
                          _buildMoreTile(
                            context: context,
                            icon: LucideIcons.printer,
                            iconColor: const Color(0xFF0284C7),
                            title: 'Printer & Receipt Settings',
                            subtitle: '${PrintingService.instance.paperSize.label} • Tap to configure',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PrinterSettingsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildMoreTile(
                            context: context,
                            icon: LucideIcons.store,
                            iconColor: const Color(0xFF475569),
                            title: 'Shop Profile',
                            onTap: _openShopProfile,
                          ),
                          _buildMoreTile(
                            context: context,
                            icon: LucideIcons.refreshCw,
                            iconColor: const Color(0xFF475569),
                            title: 'Refresh Data',
                            subtitle: 'Re-sync products, customers and bills from the server',
                            onTap: _refreshData,
                          ),
                          _buildMoreTile(
                            context: context,
                            icon: LucideIcons.server,
                            iconColor: const Color(0xFF475569),
                            title: 'Backend API Server',
                            subtitle: ApiConfig.baseUrl,
                            onTap: _openBackendSettings,
                          ),
                        ],
                      ),

                      // Account & Session Section
                      _buildSectionCard(
                        context: context,
                        sectionTitle: 'Account',
                        children: [
                          _buildMoreTile(
                            context: context,
                            icon: LucideIcons.user,
                            iconColor: const Color(0xFF0066FF),
                            title: _userName.isNotEmpty ? _userName : 'My Profile',
                            subtitle: _userEmail.isNotEmpty ? _userEmail : 'Manage personal account details',
                            onTap: _openProfileScreen,
                          ),
                          _buildMoreTile(
                            context: context,
                            icon: LucideIcons.logOut,
                            iconColor: const Color(0xFFDC2626),
                            title: 'Log Out',
                            isDestructive: true,
                            onTap: _handleLogout,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
        bottomNavigationBar: DashboardBottomNav(
          currentIndex: _navIndex,
          onTap: (index) {
            if (index == 0) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            } else if (index == 1) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const ProductsScreen()),
              );
            } else if (index == 2) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const SalesScreen()),
              );
            } else if (index == 3) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const PartiesScreen()),
              );
            }
          },
        ),
      ),
    );
  }
}

