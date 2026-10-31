import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../customers/customers.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../../../more/more.dart';
import '../../../products/presentation/screens/products_screen.dart';
import '../../../sales/domain/models/customer.dart';
import '../../../sales/domain/models/supplier.dart';
import '../../../sales/presentation/screens/sales_screen.dart';
import '../../../sales/presentation/sheets/add_edit_customer_sheet.dart';
import '../../../sales/presentation/sheets/add_edit_supplier_sheet.dart';
import '../../../sales/presentation/sheets/customer_actions_sheet.dart';
import '../../../sales/presentation/sheets/customer_credit_limit_sheet.dart';
import '../../../sales/presentation/sheets/customer_ledger_filter_sheet.dart';
import '../../../sales/presentation/sheets/purchase_payment_sheet.dart';
import '../../../sales/presentation/sheets/receive_udhar_payment_sheet.dart';
import '../../../sales/presentation/sheets/record_purchase_sheet.dart';
import '../../../suppliers/suppliers.dart';

/// Clean, unified Parties Screen displaying Customers and Suppliers with Udhar tracking,
/// search bar, Total Udhar Due KPI cards, filter chips, and a settings gear icon.
class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  final int _navIndex = 3; // Parties tab is index 3
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Customers', 'Suppliers', 'With Udhar'

  List<Customer> get _customers => AppDataRepository.instance.customers;
  List<Supplier> get _suppliers => AppDataRepository.instance.suppliers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppDataRepository.instance.refreshAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Add Party Sheet (Customer or Supplier) ---
  void _openAddPartySheet() {
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Add Customer or Supplier',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.darkText,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const Gap(10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.userPlus, size: 20, color: Color(0xFF0066FF)),
                ),
                title: Text(
                  'Add Customer',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.darkText),
                ),
                trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _addNewCustomer();
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.truck, size: 20, color: Color(0xFF7C3AED)),
                ),
                title: Text(
                  'Add Supplier',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.darkText),
                ),
                trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _addNewSupplier();
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.contactRound, size: 20, color: Color(0xFF16A34A)),
                ),
                title: Text(
                  'Import from Contacts',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.darkText),
                ),
                trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _addNewCustomer();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Quick Actions / Gear Settings Sheet ---
  void _openPartiesSettings() {
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.inputBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Parties & Ledger Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(10),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.userPlus, size: 18, color: Color(0xFF0066FF)),
                ),
                title: const Text('Add New Customer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _addNewCustomer();
                },
              ),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.truck, size: 18, color: Color(0xFF334155)),
                ),
                title: const Text('Add New Supplier', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _addNewSupplier();
                },
              ),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.user, size: 18, color: Color(0xFF334155)),
                ),
                title: const Text('Add New Customer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _addNewCustomer();
                },
              ),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.receipt, size: 18, color: Color(0xFFDC2626)),
                ),
                title: const Text('Filter & Export Ledger', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  CustomerLedgerFilterSheet.show(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addNewCustomer() async {
    final newCustomer = await AddEditCustomerSheet.show(context);
    if (newCustomer != null && mounted) {
      await AppDataRepository.instance.addCustomer(newCustomer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Customer "${newCustomer.name}" added successfully')),
        );
      }
    }
  }

  Future<void> _addNewSupplier() async {
    final newSupplier = await AddEditSupplierSheet.show(context);
    if (newSupplier != null && mounted) {
      await AppDataRepository.instance.addSupplier(newSupplier);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Supplier "${newSupplier.name}" added successfully')),
        );
      }
    }
  }

  Future<void> _receiveCustomerPayment(Customer customer) async {
    final result = await ReceiveUdharPaymentSheet.show(context, customer: customer);
    if (result == null || !mounted) return;

    // Persist through the repository so the payment reaches the backend, the
    // ledger and every other screen listening to repository changes.
    await AppDataRepository.instance.receiveUdharPayment(
      customerId: customer.id,
      amount: result.amount,
      paymentMethod: result.method,
      note: result.note,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Received Rs. ${result.amount.toInt()} from ${customer.name}'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _viewCustomerDetails(Customer customer) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (_) => PartyDetailsScreen.customer(customer)),
    );
    if (result is Customer && mounted) {
      AppDataRepository.instance.updateCustomer(result);
    }
  }

  Future<void> _viewSupplierDetails(Supplier supplier) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (_) => PartyDetailsScreen.supplier(supplier)),
    );
    if (result is Supplier && mounted) {
      AppDataRepository.instance.updateSupplier(result);
    }
  }

  Future<void> _openCustomerActions(Customer customer) async {
    final action = await CustomerActionsSheet.show(context, customer: customer);
    if (action == null || !mounted) return;

    switch (action) {
      case CustomerActionType.recordPayment:
        _receiveCustomerPayment(customer);
        break;
      case CustomerActionType.viewProfile:
      case CustomerActionType.viewLedger:
        _viewCustomerDetails(customer);
        break;
      case CustomerActionType.editDetails:
        final updated = await AddEditCustomerSheet.show(context, customer: customer);
        if (updated != null && mounted) {
          setState(() {
            final idx = _customers.indexWhere((c) => c.id == customer.id);
            if (idx != -1) _customers[idx] = updated;
          });
        }
        break;
      case CustomerActionType.setCreditLimit:
        final limit = await CustomerCreditLimitSheet.show(context, customer: customer);
        if (limit != null && mounted) {
          setState(() {
            final idx = _customers.indexWhere((c) => c.id == customer.id);
            if (idx != -1) _customers[idx] = _customers[idx].copyWith(creditLimit: limit);
          });
        }
        break;
    }
  }

  Future<void> _recordPurchase(Supplier supplier) async {
    final purchase = await RecordPurchaseSheet.show(context, initialSupplier: supplier);
    if (purchase != null && mounted) {
      setState(() {
        final idx = _suppliers.indexWhere((s) => s.id == supplier.id);
        if (idx != -1) {
          final newBal = _suppliers[idx].outstandingBalance + purchase.totalAmount;
          _suppliers[idx] = Supplier(
            id: supplier.id,
            name: supplier.name,
            phone: supplier.phone,
            address: supplier.address,
            panNumber: supplier.panNumber,
            outstandingBalance: newBal,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase of Rs. ${purchase.totalAmount.toInt()} recorded')),
      );
    }
  }

  Future<void> _paySupplier(Supplier supplier) async {
    final payment = await PurchasePaymentSheet.show(context, supplier: supplier);
    if (payment != null && mounted) {
      setState(() {
        final idx = _suppliers.indexWhere((s) => s.id == supplier.id);
        if (idx != -1) {
          final newBal = (_suppliers[idx].outstandingBalance - payment.amount).clamp(0.0, double.infinity);
          _suppliers[idx] = Supplier(
            id: supplier.id,
            name: supplier.name,
            phone: supplier.phone,
            address: supplier.address,
            panNumber: supplier.panNumber,
            outstandingBalance: newBal,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paid Rs. ${payment.amount.toInt()} to ${supplier.name}')),
      );
    }
  }

  void _onBottomNavTap(int index) {
    if (index == _navIndex) return;
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
    } else if (index == 4) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MoreScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final query = _searchQuery.toLowerCase().trim();

    // Filter customers
    final filteredCustomers = _customers.where((c) {
      if (_selectedFilter == 'Suppliers') return false;
      if (_selectedFilter == 'With Udhar' && c.udharBalance <= 0) return false;
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          c.phone.contains(query) ||
          c.address.toLowerCase().contains(query);
    }).toList();

    // Filter suppliers
    final filteredSuppliers = _suppliers.where((s) {
      if (_selectedFilter == 'Customers') return false;
      if (_selectedFilter == 'With Udhar' && s.outstandingBalance <= 0) return false;
      if (query.isEmpty) return true;
      return s.name.toLowerCase().contains(query) ||
          s.phone.contains(query) ||
          s.panNumber.contains(query) ||
          s.address.toLowerCase().contains(query);
    }).toList();

    // KPIs
    final totalUdharDue = _customers.fold<double>(0, (sum, c) => sum + c.udharBalance);
    final customersWithUdhar = _customers.where((c) => c.udharBalance > 0).length;
    final totalPayable = _suppliers.fold<double>(0, (sum, s) => sum + s.outstandingBalance);
    final suppliersWithBalance = _suppliers.where((s) => s.outstandingBalance > 0).length;

    // Combine list items for unified party scrolling
    final partyItems = <_PartyListItem>[
      ...filteredCustomers.map((c) => _PartyListItem.customer(c)),
      ...filteredSuppliers.map((s) => _PartyListItem.supplier(s)),
    ];

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
              // 1. Standardized 56px Top Header with Gear Icon on Right
              Container(
                height: 56.0,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Parties',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.darkText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Add Party',
                          icon: Icon(
                            LucideIcons.plus,
                            color: colors.darkText,
                            size: 22,
                          ),
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                          onPressed: _openAddPartySheet,
                        ),
                        const Gap(4),
                        IconButton(
                          tooltip: 'Parties Settings & Actions',
                          icon: Icon(
                            LucideIcons.settings,
                            color: colors.darkText,
                            size: 20,
                          ),
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                          onPressed: _openPartiesSettings,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Search Bar, Total Udhar Due KPI, & Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(fontSize: 13, color: colors.darkText),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          prefixIcon: Icon(LucideIcons.search, size: 16, color: colors.inputLabel),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(LucideIcons.x, size: 14),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          hintText: 'Search customer or supplier by name or phone...',
                          hintStyle: TextStyle(fontSize: 12.5, color: colors.inputBorder),
                        ),
                      ),
                    ),
                    const Gap(10),

                    // Total Udhar Due KPI Card + Payable KPI Card Row
                    Row(
                      children: [
                        // Primary: Total Udhar Due KPI
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.arrowDownLeft, size: 14, color: Color(0xFFDC2626)),
                                    const Gap(4),
                                    const Expanded(
                                      child: Text(
                                        'Udhar Due',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                    const Gap(4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        '$customersWithUdhar',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(5),
                                Text(
                                  'Rs. ${totalUdharDue.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Gap(10),

                        // Secondary: Total Payable KPI
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(LucideIcons.arrowUpRight, size: 14, color: colors.inputLabel),
                                    const Gap(4),
                                    Expanded(
                                      child: Text(
                                        'Payable',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: colors.inputLabel,
                                        ),
                                      ),
                                    ),
                                    const Gap(4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        '$suppliersWithBalance',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: colors.inputLabel,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(5),
                                Text(
                                  'Rs. ${totalPayable.toInt()}',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: colors.darkText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),

                    // Filter Chips (All, Customers, Suppliers, With Udhar)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip(
                            label: 'All (${_customers.length + _suppliers.length})',
                            isSelected: _selectedFilter == 'All',
                            onTap: () => setState(() => _selectedFilter = 'All'),
                          ),
                          const Gap(8),
                          _filterChip(
                            label: 'Customers (${_customers.length})',
                            isSelected: _selectedFilter == 'Customers',
                            onTap: () => setState(() => _selectedFilter = 'Customers'),
                          ),
                          const Gap(8),
                          _filterChip(
                            label: 'Suppliers (${_suppliers.length})',
                            isSelected: _selectedFilter == 'Suppliers',
                            onTap: () => setState(() => _selectedFilter = 'Suppliers'),
                          ),
                          const Gap(8),
                          _filterChip(
                            label: 'With Udhar ($customersWithUdhar)',
                            isSelected: _selectedFilter == 'With Udhar',
                            onTap: () => setState(() => _selectedFilter = 'With Udhar'),
                          ),
                        ],
                      ),
                    ),
                    const Gap(6),
                  ],
                ),
              ),

              // 3. Unified Parties List with Pull-to-Refresh & Shimmer Skeletons
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF0066FF),
                  backgroundColor: Colors.white,
                  onRefresh: () async {
                    await AppDataRepository.instance.refreshAll();
                  },
                  child: AppDataRepository.instance.isLoading && partyItems.isEmpty
                      ? const SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
                          child: TransactionListSkeleton(itemCount: 6),
                        )
                      : partyItems.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const Gap(60),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.users, size: 36, color: colors.inputBorder),
                                      const Gap(8),
                                      Text(
                                        'No parties matching "$_searchQuery"',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.inputLabel),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: partyItems.length + 1,
                              separatorBuilder: (_, _) => const Gap(10),
                              itemBuilder: (ctx, index) {
                                if (index == partyItems.length) {
                                  return const AppBottomLoader(hasMore: false);
                                }
                                final item = partyItems[index];
                                if (item.isCustomer) {
                                  final customer = item.customer!;
                                  return CustomerCard(
                                    customer: customer,
                                    onTap: () => _viewCustomerDetails(customer),
                                    onReceivePayment: () => _receiveCustomerPayment(customer),
                                    onMoreOptions: () => _openCustomerActions(customer),
                                  );
                                } else {
                                  final supplier = item.supplier!;
                                  return SupplierCard(
                                    supplier: supplier,
                                    onTap: () => _viewSupplierDetails(supplier),
                                    onRecordPurchase: () => _recordPurchase(supplier),
                                    onPaySupplier: () => _paySupplier(supplier),
                                    onMoreOptions: () async {
                                      final updated = await AddEditSupplierSheet.show(
                                        context,
                                        supplier: supplier,
                                      );
                                      if (updated != null) {
                                        await AppDataRepository.instance.updateSupplier(updated);
                                      }
                                    },
                                  );
                                }
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: DashboardBottomNav(
          currentIndex: _navIndex,
          onTap: _onBottomNavTap,
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

/// Helper model representing either a Customer or Supplier for unified party listing.
class _PartyListItem {
  final Customer? customer;
  final Supplier? supplier;

  const _PartyListItem.customer(this.customer) : supplier = null;
  const _PartyListItem.supplier(this.supplier) : customer = null;

  bool get isCustomer => customer != null;
}
