import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../sales/domain/models/customer.dart';
import '../../../sales/domain/models/supplier.dart';
import '../../../sales/presentation/sheets/customer_ledger_filter_sheet.dart';
import '../../../sales/presentation/sheets/purchase_payment_sheet.dart';
import '../../../sales/presentation/sheets/receive_udhar_payment_sheet.dart';
import '../../../sales/presentation/sheets/supplier_credit_sheet.dart';
import '../../../parties/presentation/screens/party_details_screen.dart';

/// Clean, comprehensive Udhar & Credit Management Screen (Customer Receivables & Supplier Payables).
class CreditManagementScreen extends StatefulWidget {
  const CreditManagementScreen({super.key});

  @override
  State<CreditManagementScreen> createState() => _CreditManagementScreenState();
}

class _CreditManagementScreenState extends State<CreditManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Customer> get _customers => AppDataRepository.instance.customers;
  List<Supplier> get _suppliers => AppDataRepository.instance.suppliers;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppDataRepository.instance.refreshAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _viewCustomerDetails(Customer customer) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (_) => PartyDetailsScreen.customer(customer)),
    );
    if (result is Customer && mounted) {
      setState(() {
        final idx = _customers.indexWhere((c) => c.id == result.id);
        if (idx != -1) _customers[idx] = result;
      });
    }
  }

  Future<void> _viewSupplierDetails(Supplier supplier) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (_) => PartyDetailsScreen.supplier(supplier)),
    );
    if (result is Supplier && mounted) {
      setState(() {
        final idx = _suppliers.indexWhere((s) => s.id == result.id);
        if (idx != -1) _suppliers[idx] = result;
      });
    }
  }

  Future<void> _receiveCustomerPayment(Customer customer) async {
    final result = await ReceiveUdharPaymentSheet.show(context, customer: customer);
    if (result != null && mounted) {
      await AppDataRepository.instance.receiveUdharPayment(
        customerId: customer.id,
        amount: result.amount,
        paymentMethod: result.paymentMethod,
        note: result.note,
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Received Rs. ${result.amount.toInt()} from ${customer.name}')),
        );
      }
    }
  }

  Future<void> _paySupplier(Supplier supplier) async {
    final result = await PurchasePaymentSheet.show(context, supplier: supplier);
    if (result != null && mounted) {
      await AppDataRepository.instance.recordSupplierPayment(
        supplierId: supplier.id,
        amount: result.amount,
        paymentMethod: result.paymentMethod,
        note: result.note,
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paid Rs. ${result.amount.toInt()} to ${supplier.name}')),
        );
      }
    }
  }

  void _sendReminder(Customer customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment reminder sent to ${customer.name} (${customer.phone})'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalReceivable = _customers.fold<double>(0, (sum, c) => sum + c.udharBalance);
    final totalPayable = _suppliers.fold<double>(0, (sum, s) => sum + s.outstandingBalance);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 56.0,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 20, color: colors.darkText),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          splashRadius: 20,
        ),
        title: Text(
          'Credit & Udhar Khata',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.darkText,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              tooltip: 'Filter Ledger',
              icon: Icon(LucideIcons.filter, size: 18, color: colors.darkText),
              onPressed: () => CustomerLedgerFilterSheet.show(context),
              splashRadius: 20,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              labelColor: colors.darkText,
              unselectedLabelColor: colors.inputLabel,
              labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.arrowDownLeft, size: 14, color: Color(0xFF16A34A)),
                      const Gap(6),
                      Text('To Collect (Rs. ${totalReceivable.toInt()})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.arrowUpRight, size: 14, color: Color(0xFFDC2626)),
                      const Gap(6),
                      Text('To Pay (Rs. ${totalPayable.toInt()})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const Gap(10),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
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
                  hintText: 'Search by party name or mobile...',
                  hintStyle: TextStyle(fontSize: 12.5, color: colors.inputBorder),
                ),
              ),
            ),
          ),
          const Gap(12),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Customers Udhar List (Receivable)
                _buildCustomerUdharList(),

                // 2. Suppliers Credit List (Payable)
                _buildSupplierCreditList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerUdharList() {
    final colors = context.colors;
    final query = _searchQuery.toLowerCase().trim();
    final list = _customers.where((c) {
      if (c.udharBalance <= 0) return false;
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) || c.phone.contains(query);
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFF2563EB),
      backgroundColor: Colors.white,
      onRefresh: () async {
        await AppDataRepository.instance.refreshAll();
      },
      child: AppDataRepository.instance.isLoading && list.isEmpty
          ? const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: TransactionListSkeleton(itemCount: 5),
            )
          : list.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const Gap(80),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.checkCircle2, size: 40, color: Color(0xFF16A34A)),
                          const Gap(10),
                          Text(
                            'No pending customer udhar!',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.darkText),
                          ),
                          const Gap(4),
                          Text(
                            'All accounts are settled.',
                            style: TextStyle(fontSize: 12, color: colors.inputLabel),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: list.length + 1,
                  separatorBuilder: (_, _) => const Gap(10),
                  itemBuilder: (ctx, index) {
                    if (index == list.length) {
                      return const AppBottomLoader(hasMore: false);
                    }
                    final customer = list[index];
                    final limitPercent = (customer.udharBalance / customer.creditLimit).clamp(0.0, 1.0);

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _viewCustomerDetails(customer),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFFEF2F2),
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0] : 'C',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.darkText,
                          ),
                        ),
                        Text(
                          customer.phone,
                          style: TextStyle(fontSize: 12, color: colors.inputLabel),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs. ${customer.udharBalance.toInt()}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      Text(
                        'Due Balance',
                        style: TextStyle(fontSize: 11, color: colors.inputLabel),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(10),

              // Credit Limit Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Credit Limit Used: ${(limitPercent * 100).toInt()}%',
                    style: TextStyle(fontSize: 11, color: colors.inputLabel),
                  ),
                  Text(
                    'Limit: Rs. ${customer.creditLimit.toInt()}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.darkText),
                  ),
                ],
              ),
              const Gap(6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: limitPercent,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation(
                    limitPercent > 0.8 ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
                  ),
                ),
              ),
              const Gap(12),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _receiveCustomerPayment(customer),
                      icon: const Icon(LucideIcons.arrowDownLeft, size: 14),
                      label: const Text('Receive Payment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const Gap(8),
                  OutlinedButton.icon(
                    onPressed: () => _sendReminder(customer),
                    icon: const Icon(LucideIcons.bellRing, size: 14),
                    label: const Text('Remind', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  },
    ),
  );
}

  Widget _buildSupplierCreditList() {
    final colors = context.colors;
    final query = _searchQuery.toLowerCase().trim();
    final list = _suppliers.where((s) {
      if (s.outstandingBalance <= 0) return false;
      if (query.isEmpty) return true;
      return s.name.toLowerCase().contains(query) || s.phone.contains(query);
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFF2563EB),
      backgroundColor: Colors.white,
      onRefresh: () async {
        await AppDataRepository.instance.refreshAll();
      },
      child: AppDataRepository.instance.isLoading && list.isEmpty
          ? const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: TransactionListSkeleton(itemCount: 5),
            )
          : list.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const Gap(80),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.checkCircle2, size: 40, color: Color(0xFF16A34A)),
                          const Gap(10),
                          Text(
                            'No outstanding supplier credit!',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.darkText),
                          ),
                          const Gap(4),
                          Text(
                            'All supplier invoices are paid.',
                            style: TextStyle(fontSize: 12, color: colors.inputLabel),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: list.length + 1,
                  separatorBuilder: (_, _) => const Gap(10),
                  itemBuilder: (ctx, index) {
                    if (index == list.length) {
                      return const AppBottomLoader(hasMore: false);
                    }
                    final supplier = list[index];

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _viewSupplierDetails(supplier),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFF1F5F9),
                    child: Text(
                      supplier.name.isNotEmpty ? supplier.name[0] : 'S',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.darkText,
                          ),
                        ),
                        Text(
                          '${supplier.phone} • ${supplier.address}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: colors.inputLabel),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs. ${supplier.outstandingBalance.toInt()}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      Text(
                        'To Pay',
                        style: TextStyle(fontSize: 11, color: colors.inputLabel),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(12),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _paySupplier(supplier),
                      icon: const Icon(LucideIcons.arrowUpRight, size: 14),
                      label: const Text('Pay Supplier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const Gap(8),
                  OutlinedButton.icon(
                    onPressed: () => SupplierCreditSheet.show(context, supplier: supplier),
                    icon: const Icon(LucideIcons.fileSpreadsheet, size: 14),
                    label: const Text('Statement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.darkText,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  },
    ),
  );
}
}
