import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/parse_utils.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../sheets/date_range_picker_sheet.dart';
import 'today_bills_screen.dart';
import 'transaction_details_screen.dart';

enum TransactionCategory {
  sale,
  udharPayment,
  purchase,
  creditSale,
}

class FullTransactionModel {
  final String id;
  final String receiptNumber;
  final String title;
  final String subtitle;
  final String partyName;
  final String partyPhone;
  final DateTime timestamp;
  final double amount;
  final TransactionCategory category;
  final String paymentMethod;
  final String status;
  final List<TransactionDetailItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double cashReceived;
  final double changeReturned;
  final double udharAmount;
  final String note;

  const FullTransactionModel({
    required this.id,
    required this.receiptNumber,
    required this.title,
    required this.subtitle,
    required this.partyName,
    this.partyPhone = '',
    required this.timestamp,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    this.status = 'PAID',
    this.items = const [],
    this.subtotal = 0,
    this.discount = 0,
    this.tax = 0,
    this.cashReceived = 0,
    this.changeReturned = 0,
    this.udharAmount = 0,
    this.note = '',
  });

  bool get isInflow =>
      category == TransactionCategory.sale ||
      category == TransactionCategory.udharPayment;

  factory FullTransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime ts;
    try {
      ts = DateTime.parse(
          json['timestamp']?.toString() ?? json['created_at']?.toString() ?? '');
    } catch (_) {
      ts = DateTime.now();
    }

    TransactionCategory cat = TransactionCategory.sale;
    final typeStr = json['type']?.toString().toUpperCase() ??
        json['category']?.toString().toUpperCase() ??
        '';
    if (typeStr.contains('UDHAR') ||
        typeStr.contains('PAYMENT_IN') ||
        typeStr.contains('CUSTOMER_PAYMENT')) {
      cat = TransactionCategory.udharPayment;
    } else if (typeStr.contains('PURCHASE')) {
      cat = TransactionCategory.purchase;
    } else if (typeStr.contains('CREDIT')) {
      cat = TransactionCategory.creditSale;
    }

    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems.map((it) {
      if (it is Map<String, dynamic>) {
        return TransactionDetailItem(
          name: it['product_name']?.toString() ??
              it['name']?.toString() ??
              'Item',
          quantity: parseDouble(it['quantity'], 1.0),
          unit: it['unit']?.toString() ?? 'pkt',
          rate: parseDouble(it['unit_price'] ?? it['rate']),
          total: parseDouble(it['subtotal'] ?? it['total']),
        );
      }
      return const TransactionDetailItem(
          name: 'Item', quantity: 1, unit: 'pkt', rate: 0, total: 0);
    }).toList();

    final amt = parseDouble(json['grand_total'] ?? json['amount']);

    return FullTransactionModel(
      id: json['id']?.toString() ?? '',
      receiptNumber: json['receipt_number']?.toString() ??
          json['receiptNumber']?.toString() ??
          '',
      title: json['title']?.toString() ??
          'Sale #${json['receipt_number'] ?? json['id'] ?? ''}',
      subtitle: json['subtitle']?.toString() ??
          '${json['primary_payment_method'] ?? 'Cash'}',
      partyName: json['customer_name']?.toString() ??
          json['partyName']?.toString() ??
          'Walk-in Customer',
      partyPhone: json['partyPhone']?.toString() ?? '',
      timestamp: ts,
      amount: amt,
      category: cat,
      paymentMethod: json['primary_payment_method']?.toString() ??
          json['paymentMethod']?.toString() ??
          'Cash',
      status: json['status']?.toString() ??
          (json['is_cancelled'] == true ? 'VOID' : 'PAID'),
      items: itemsList,
      subtotal: parseDouble(json['subtotal'], amt),
      discount: parseDouble(json['discount_amount'] ?? json['discount']),
      tax: parseDouble(json['tax_amount'] ?? json['tax']),
      cashReceived: parseDouble(json['cash_received'], amt),
      changeReturned: parseDouble(json['change_returned']),
      udharAmount: parseDouble(json['udhar_amount']),
      note: json['note']?.toString() ?? '',
    );
  }
}

/// Lineless, modern View Transactions Screen with date range filter,
/// category chips, financial summaries, and transaction details integration.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Sales', 'Payments In', 'Purchases', 'Udhar'
  String _dateRangeLabel = 'Today'; // 'Today', 'Yesterday', 'This Week', 'This Month', 'All'

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

  List<FullTransactionModel> get _allTransactions =>
      AppDataRepository.instance.transactions;

  List<FullTransactionModel> get _filteredTransactions {
    final now = DateTime.now();

    return _allTransactions.where((tx) {
      // Date filter
      if (_dateRangeLabel == 'Today') {
        if (tx.timestamp.year != now.year ||
            tx.timestamp.month != now.month ||
            tx.timestamp.day != now.day) {
          return false;
        }
      } else if (_dateRangeLabel == 'Yesterday') {
        final yesterday = now.subtract(const Duration(days: 1));
        if (tx.timestamp.year != yesterday.year ||
            tx.timestamp.month != yesterday.month ||
            tx.timestamp.day != yesterday.day) {
          return false;
        }
      }

      // Category filter
      if (_selectedFilter == 'Sales' &&
          tx.category != TransactionCategory.sale &&
          tx.category != TransactionCategory.creditSale) {
        return false;
      }
      if (_selectedFilter == 'Payments In' &&
          tx.category != TransactionCategory.udharPayment) {
        return false;
      }
      if (_selectedFilter == 'Purchases' &&
          tx.category != TransactionCategory.purchase) {
        return false;
      }
      if (_selectedFilter == 'Udhar' &&
          tx.category != TransactionCategory.creditSale) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = tx.title.toLowerCase().contains(q);
        final matchReceipt = tx.receiptNumber.toLowerCase().contains(q);
        final matchParty = tx.partyName.toLowerCase().contains(q);
        final matchMethod = tx.paymentMethod.toLowerCase().contains(q);
        return matchTitle || matchReceipt || matchParty || matchMethod;
      }

      return true;
    }).toList();
  }

  void _openDetails(FullTransactionModel tx) {
    List<TransactionDetailItem> resolvedItems = tx.items;
    if (resolvedItems.isEmpty) {
      final matchingBill = AppDataRepository.instance.todayBills
          .cast<TodayBillItem?>()
          .firstWhere(
            (b) => b?.billNumber == tx.receiptNumber,
            orElse: () => null,
          );
      if (matchingBill != null && matchingBill.items.isNotEmpty) {
        resolvedItems = matchingBill.items;
      }
    }
    if (resolvedItems.isEmpty && tx.amount > 0) {
      resolvedItems = [
        TransactionDetailItem(
          name: tx.note.isNotEmpty ? tx.note : 'Credit Sale',
          quantity: 1,
          unit: 'lot',
          rate: tx.amount,
          total: tx.amount,
        ),
      ];
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionDetailsScreen(
          receiptNumber: tx.receiptNumber,
          title: tx.title,
          customerName: tx.partyName,
          customerPhone: tx.partyPhone,
          timestamp: tx.timestamp,
          items: resolvedItems,
          subtotal: tx.subtotal > 0 ? tx.subtotal : tx.amount,
          discountAmount: tx.discount,
          taxAmount: tx.tax,
          totalAmount: tx.amount,
          paymentMethod: tx.paymentMethod,
          paymentStatus: tx.status,
          cashReceived: tx.cashReceived,
          changeReturned: tx.changeReturned,
          udharAmount: tx.udharAmount,
          note: tx.note,
          isPurchase: tx.category == TransactionCategory.purchase,
        ),
      ),
    );
  }

  void _showDateRangePicker() async {
    final range = await DateRangePickerSheet.show(context);
    if (range != null) {
      setState(() {
        _dateRangeLabel = DateFormat('dd MMM').format(range.from) ==
                DateFormat('dd MMM').format(range.to)
            ? DateFormat('dd MMM').format(range.from)
            : '${DateFormat('dd MMM').format(range.from)} - ${DateFormat('dd MMM').format(range.to)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataRepository.instance,
      builder: (context, _) {
        final colors = context.colors;
        final filtered = _filteredTransactions;

        // Financial KPI Totals for active view
        double totalInflow = 0;
        double totalOutflow = 0;
        for (final tx in filtered) {
          if (tx.isInflow) {
            totalInflow += tx.amount;
          } else if (tx.category == TransactionCategory.purchase) {
            totalOutflow += tx.amount;
          }
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Standard Top Bar
                  AppTopBar(
                    title: 'All Transactions',
                    leading: IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, size: 20, color: Color(0xFF0F172A)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(LucideIcons.calendar, size: 20, color: Color(0xFF475569)),
                        tooltip: 'Date Filter',
                        onPressed: _showDateRangePicker,
                      ),
                    ],
                  ),

                  // Scrollable Transactions Content with Drag-to-Refresh & Sliver Virtualization
                  Expanded(
                    child: RefreshIndicator(
                      color: const Color(0xFF2563EB),
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        await AppDataRepository.instance.refreshAll(force: true);
                      },
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Financial KPI Summary Card (Lineless Modern Row)
                      Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              title: 'Total Inflow',
                              value: 'Rs. ${totalInflow.toInt()}',
                              icon: LucideIcons.arrowDownLeft,
                              color: const Color(0xFF16A34A),
                              bgColor: const Color(0xFFDCFCE7),
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: _summaryCard(
                              title: 'Purchases / Out',
                              value: 'Rs. ${totalOutflow.toInt()}',
                              icon: LucideIcons.arrowUpRight,
                              color: const Color(0xFFDC2626),
                              bgColor: const Color(0xFFFEE2E2),
                            ),
                          ),
                        ],
                      ),
                      const Gap(14),

                      // Search Input Box
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          style: const TextStyle(fontSize: 13.5),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF94A3B8)),
                            prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(LucideIcons.x, size: 15),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            hintText: 'Search bill #, party name, or payment mode...',
                            hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ),
                      const Gap(12),

                      // Quick Date Selector & Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Date Range Pill
                            InkWell(
                              onTap: _showDateRangePicker,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.calendarDays, size: 13, color: Color(0xFF4F46E5)),
                                    const Gap(5),
                                    Text(
                                      _dateRangeLabel,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                    const Gap(4),
                                    const Icon(LucideIcons.chevronDown, size: 12, color: Color(0xFF4F46E5)),
                                  ],
                                ),
                              ),
                            ),
                            const Gap(8),
                            _filterChip('All (${_allTransactions.length})', 'All'),
                            const Gap(6),
                            _filterChip('Sales', 'Sales'),
                            const Gap(6),
                            _filterChip('Payments In', 'Payments In'),
                            const Gap(6),
                            _filterChip('Purchases', 'Purchases'),
                            const Gap(6),
                            _filterChip('Udhar', 'Udhar'),
                          ],
                        ),
                      ),
                      const Gap(16),

                      // Transactions List Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transactions (${filtered.length})',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: colors.darkText,
                            ),
                          ),
                          if (_dateRangeLabel != 'All')
                            InkWell(
                              onTap: () => setState(() => _dateRangeLabel = 'All'),
                              child: const Text(
                                'Show All Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Gap(10),
                    ],
                  ),
                ),
              ),

              // List Items
              if (AppDataRepository.instance.isLoading && filtered.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 400,
                      child: TransactionListSkeleton(itemCount: 6),
                    ),
                  ),
                )
              else if (AppDataRepository.instance.lastError != null &&
                  AppDataRepository.instance.transactions.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: AppErrorState(
                      onRetry: () =>
                          AppDataRepository.instance.refreshAll(force: true),
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(LucideIcons.fileSearch, size: 36, color: Color(0xFF94A3B8)),
                          const Gap(10),
                          const Text(
                            'No transactions found',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                          ),
                          const Gap(4),
                          const Text(
                            'Try clearing your search query or date filters',
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                          const Gap(12),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedFilter = 'All';
                                _dateRangeLabel = 'All';
                              });
                            },
                            child: const Text('Reset Filters'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Gap(8),
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      return _transactionRow(tx);
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 20),
                    child: AppBottomLoader(hasMore: false),
                  ),
                ),
              ],
            ],
          ),
        ),
            ),
          ],
        ),
      ),
    ),
  );
    },
  );
}

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const Gap(2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _transactionRow(FullTransactionModel tx) {
    final dateStr = DateFormat('hh:mm a').format(tx.timestamp);
    final isSale = tx.category == TransactionCategory.sale;
    final isUdharPayment = tx.category == TransactionCategory.udharPayment;
    final isCredit = tx.category == TransactionCategory.creditSale;
    final isPurchase = tx.category == TransactionCategory.purchase;

    final IconData icon = isSale
        ? LucideIcons.shoppingCart
        : isUdharPayment
            ? LucideIcons.handCoins
            : isCredit
                ? LucideIcons.clock
                : LucideIcons.packageCheck;

    final Color iconColor = isSale
        ? const Color(0xFF10B981)
        : isUdharPayment
            ? const Color(0xFF2563EB)
            : isCredit
                ? const Color(0xFFF59E0B)
                : const Color(0xFF64748B);

    final Color iconBg = iconColor.withValues(alpha: 0.12);

    final String amountPrefix = isPurchase ? '- ' : (isUdharPayment ? '+ ' : '');
    final Color amountColor = isPurchase
        ? const Color(0xFFDC2626)
        : (isCredit ? const Color(0xFFD97706) : const Color(0xFF0F172A));

    return InkWell(
      onTap: () => _openDetails(tx),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tx.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Gap(6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tx.paymentMethod,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(2),
                  Text(
                    '${tx.partyName} • $dateStr',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Gap(8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$amountPrefix Rs. ${tx.amount.toInt()}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                  ),
                ),
                const Gap(2),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Details',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                    ),
                    Gap(2),
                    Icon(LucideIcons.chevronRight, size: 12, color: Color(0xFF2563EB)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

