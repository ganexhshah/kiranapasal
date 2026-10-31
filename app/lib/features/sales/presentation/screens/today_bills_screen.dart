import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/services/printing_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/parse_utils.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../sheets/bill_actions_sheet.dart';
import 'sales_screen.dart';
import 'transaction_details_screen.dart';

class TodayBillItem {
  final String billNumber;
  final String customerName;
  final String customerPhone;
  final DateTime timestamp;
  final double amount;
  final String paymentMethod; // 'Cash', 'Fonepay QR', 'Card', 'Credit (Udhar)'
  final String status;
  final int itemsCount;
  final String itemsSummary;
  final List<TransactionDetailItem> items;
  final double subtotal;
  final double discount;
  final double taxAmount;
  final double additionalCharges;
  final double cashReceived;
  final double changeReturned;
  final double udharAmount;

  const TodayBillItem({
    required this.billNumber,
    required this.customerName,
    this.customerPhone = '',
    required this.timestamp,
    required this.amount,
    required this.paymentMethod,
    this.status = 'PAID',
    required this.itemsCount,
    required this.itemsSummary,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.taxAmount = 0,
    this.additionalCharges = 0,
    this.cashReceived = 0,
    this.changeReturned = 0,
    this.udharAmount = 0,
  });

  factory TodayBillItem.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems.map((it) {
      if (it is Map<String, dynamic>) {
        return TransactionDetailItem(
          name: it['product_name']?.toString() ?? it['name']?.toString() ?? 'Item',
          quantity: parseDouble(it['quantity'], 1.0),
          unit: it['unit']?.toString() ?? 'pkt',
          rate: parseDouble(it['unit_price'] ?? it['rate']),
          total: parseDouble(it['subtotal'] ?? it['total']),
        );
      }
      return const TransactionDetailItem(name: 'Item', quantity: 1, unit: 'pkt', rate: 0, total: 0);
    }).toList();

    final cust = json['customer'];
    String cName = 'Walk-in Customer';
    String cPhone = '';
    if (cust is Map) {
      cName = cust['name']?.toString() ?? 'Walk-in Customer';
      cPhone = cust['phone']?.toString() ?? '';
    } else if (json['customer_name'] != null) {
      cName = json['customer_name'].toString();
      cPhone = json['customer_phone']?.toString() ?? '';
    }

    DateTime ts;
    try {
      ts = DateTime.parse(json['created_at']?.toString() ?? json['timestamp']?.toString() ?? '');
    } catch (_) {
      ts = DateTime.now();
    }

    final totalAmt = parseDouble(json['grand_total'] ?? json['amount']);
    final subtotalAmt = parseDouble(json['subtotal'], totalAmt);
    final discountAmt = parseDouble(json['discount_amount'] ?? json['discount']);

    return TodayBillItem(
      billNumber: json['receipt_number']?.toString() ?? json['billNumber']?.toString() ?? '',
      customerName: cName,
      customerPhone: cPhone,
      timestamp: ts,
      amount: totalAmt,
      paymentMethod: json['primary_payment_method']?.toString() ?? json['paymentMethod']?.toString() ?? 'Cash',
      status: json['is_cancelled'] == true ? 'VOID' : (json['status']?.toString() ?? 'PAID'),
      itemsCount: itemsList.isNotEmpty ? itemsList.length : parseInt(json['items_count'], 1),
      itemsSummary: itemsList.isNotEmpty
          ? itemsList.map((e) => '${e.name} (${e.quantity})').join(', ')
          : (json['items_summary']?.toString() ?? 'Retail Goods'),
      items: itemsList,
      subtotal: subtotalAmt,
      discount: discountAmt,
      taxAmount: parseDouble(json['tax_amount']),
      cashReceived: parseDouble(json['cash_received'], totalAmt),
      changeReturned: parseDouble(json['change_returned']),
      udharAmount: parseDouble(json['udhar_amount']),
    );
  }
}

/// Comprehensive screen listing all invoices and sales generated today.
class TodayBillsScreen extends StatefulWidget {
  const TodayBillsScreen({super.key});

  @override
  State<TodayBillsScreen> createState() => _TodayBillsScreenState();
}

class _TodayBillsScreenState extends State<TodayBillsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPaymentFilter = 'All'; // 'All', 'Cash', 'QR / Online', 'Credit (Udhar)'

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

  List<TodayBillItem> get _bills => AppDataRepository.instance.todayBills;

  List<TodayBillItem> get _filteredBills {
    return _bills.where((bill) {
      // Payment filter
      if (_selectedPaymentFilter == 'Cash' && bill.paymentMethod != 'Cash') {
        return false;
      }
      if (_selectedPaymentFilter == 'QR / Online' && !bill.paymentMethod.contains('QR') && !bill.paymentMethod.contains('Card')) {
        return false;
      }
      if (_selectedPaymentFilter == 'Credit (Udhar)' && !bill.paymentMethod.contains('Credit')) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchNum = bill.billNumber.toLowerCase().contains(q);
        final matchName = bill.customerName.toLowerCase().contains(q);
        final matchSummary = bill.itemsSummary.toLowerCase().contains(q);
        return matchNum || matchName || matchSummary;
      }

      return true;
    }).toList();
  }

  void _openBillDetails(TodayBillItem bill) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionDetailsScreen(
          receiptNumber: bill.billNumber,
          title: 'Bill #${bill.billNumber}',
          customerName: bill.customerName,
          customerPhone: bill.customerPhone,
          timestamp: bill.timestamp,
          items: bill.items,
          subtotal: bill.subtotal,
          discountAmount: bill.discount,
          taxAmount: 0,
          totalAmount: bill.amount,
          paymentMethod: bill.paymentMethod,
          paymentStatus: bill.status,
          cashReceived: bill.cashReceived,
          changeReturned: bill.changeReturned,
          udharAmount: bill.udharAmount,
        ),
      ),
    );
  }

  InvoicePrintData _toInvoiceData(TodayBillItem bill) {
    return InvoicePrintData(
      invoiceNumber: bill.billNumber,
      date: bill.timestamp,
      customerName: bill.customerName,
      customerPhone: bill.customerPhone,
      items: bill.items.isNotEmpty
          ? bill.items
              .map((item) => InvoiceItemData(
                    name: item.name,
                    quantity: item.quantity,
                    unit: item.unit,
                    unitPrice: item.rate,
                    total: item.total,
                  ))
              .toList()
          : [
              InvoiceItemData(
                name: bill.itemsSummary.isNotEmpty ? bill.itemsSummary : 'General Store Items',
                quantity: bill.itemsCount > 0 ? bill.itemsCount.toDouble() : 1,
                unit: 'item',
                unitPrice: bill.amount / (bill.itemsCount > 0 ? bill.itemsCount : 1),
                total: bill.amount,
              ),
            ],
      subtotal: bill.subtotal > 0 ? bill.subtotal : bill.amount,
      discount: bill.discount,
      tax: bill.taxAmount,
      charges: bill.additionalCharges,
      grandTotal: bill.amount,
      paymentMethod: bill.paymentMethod,
      cashReceived: bill.cashReceived,
      changeDue: bill.changeReturned,
    );
  }

  void _showBillActions(TodayBillItem bill) async {
    final action = await BillActionsSheet.show(
      context,
      billNumber: bill.billNumber,
      amount: bill.amount,
    );

    if (action != null && mounted) {
      if (action == BillActionType.view) {
        _openBillDetails(bill);
      } else if (action == BillActionType.print) {
        HapticFeedback.lightImpact();
        try {
          await PrintingService.instance.printInvoice(_toInvoiceData(bill));
        } catch (e) {
          debugPrint('Print failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Couldn't print this bill. Check the printer and try again."),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
        }
      } else if (action == BillActionType.share) {
        HapticFeedback.lightImpact();
        try {
          await PrintingService.instance.shareInvoicePdf(_toInvoiceData(bill));
        } catch (e) {
          debugPrint('Share failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Couldn't share this bill. Please try again."),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
        }
      } else if (action == BillActionType.cancel) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Void this bill?'),
            content: Text(
              'Bill #${bill.billNumber} will be cancelled and its items returned to stock. '
              'This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep bill'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                child: const Text('Void bill'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        await AppDataRepository.instance.voidBill(
          bill.billNumber,
          'Voided from today\'s bills',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill #${bill.billNumber} voided'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataRepository.instance,
      builder: (context, _) {
        final colors = context.colors;
        final filtered = _filteredBills;

        // Calculate Today's Stats from real bills
        final totalSales = _bills
            .where((b) => b.status != 'VOID')
            .fold<double>(0, (sum, b) => sum + b.amount);
        final cashSales = _bills
            .where((b) => b.status != 'VOID' && b.paymentMethod == 'Cash')
            .fold<double>(0, (sum, b) => sum + b.amount);
        final onlineSales = _bills
            .where((b) =>
                b.status != 'VOID' &&
                (b.paymentMethod.contains('QR') ||
                    b.paymentMethod.contains('Card') ||
                    b.paymentMethod.contains('Fonepay')))
            .fold<double>(0, (sum, b) => sum + b.amount);
        final creditSales = _bills
            .where((b) =>
                b.status != 'VOID' &&
                (b.paymentMethod.contains('Credit') ||
                    b.paymentMethod.contains('Udhar')))
            .fold<double>(0, (sum, b) => sum + b.amount);

    final todayFormatted = DateFormat('EEE, dd MMM yyyy').format(DateTime.now());

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
              // Top Bar
              AppTopBar(
                title: "Today's Bills",
                leading: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, size: 20, color: Color(0xFF0F172A)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      todayFormatted,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),

              // Scrollable Bills List & Summaries with Drag-to-Refresh & Sliver Virtualization
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF0066FF),
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
                              // Today's Sales Banner Card (Dark Navy Modern Hero)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0A192F), Color(0xFF1E3A8A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(LucideIcons.receipt, size: 15, color: Colors.white),
                                    ),
                                    const Gap(8),
                                    const Text(
                                      "Today's Overview",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${_bills.length} Bills Created',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(10),
                            Text(
                              'Rs. ${totalSales.toInt()}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Gap(14),

                            // Payment Mode Breakdown Pills
                            Row(
                              children: [
                                Expanded(
                                  child: _miniPill(
                                    'Cash',
                                    'Rs. ${cashSales.toInt()}',
                                    const Color(0xFF10B981),
                                  ),
                                ),
                                const Gap(8),
                                Expanded(
                                  child: _miniPill(
                                    'Online / QR',
                                    'Rs. ${onlineSales.toInt()}',
                                    const Color(0xFF38BDF8),
                                  ),
                                ),
                                const Gap(8),
                                Expanded(
                                  child: _miniPill(
                                    'Credit / Udhar',
                                    'Rs. ${creditSales.toInt()}',
                                    const Color(0xFFFBBF24),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Gap(14),

                      // Search Bar
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
                                    icon: const Icon(LucideIcons.x, size: 14),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            hintText: 'Search by bill #S1024, customer, or items...',
                            hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ),
                      const Gap(12),

                      // Payment Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _chip('All (${_bills.length})', 'All'),
                            const Gap(6),
                            _chip('Cash (${_bills.where((b) => b.paymentMethod == 'Cash').length})', 'Cash'),
                            const Gap(6),
                            _chip('Online / QR (${_bills.where((b) => b.paymentMethod.contains('QR')).length})', 'QR / Online'),
                            const Gap(6),
                            _chip('Credit / Udhar (${_bills.where((b) => b.paymentMethod.contains('Credit')).length})', 'Credit (Udhar)'),
                          ],
                        ),
                      ),
                      const Gap(16),

                      // Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bills (${filtered.length})',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: colors.darkText,
                            ),
                          ),
                          const Text(
                            'Tap bill for full details',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                      const Gap(10),
                    ],
                  ),
                ),
              ),

              // Bills List, Skeleton, or Empty State
              if (AppDataRepository.instance.isLoading && filtered.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 360,
                      child: TransactionListSkeleton(itemCount: 5),
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
                      child: const Column(
                        children: [
                          Icon(LucideIcons.receiptText, size: 36, color: Color(0xFF94A3B8)),
                          Gap(10),
                          Text('No matching bills found', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                          Gap(4),
                          Text('Try checking another filter or clear search', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
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
                    separatorBuilder: (_, _) => const Gap(10),
                    itemBuilder: (context, index) {
                      final bill = filtered[index];
                      return _buildBillCard(bill);
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

              // Bottom New Sale Action Button
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SalesScreen()),
                      );
                    },
                    icon: const Icon(LucideIcons.plus, size: 18, color: Colors.white),
                    label: const Text(
                      'Create New Bill (POS)',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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

  Widget _miniPill(String label, String amount, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          const Gap(2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final active = _selectedPaymentFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentFilter = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0066FF) : const Color(0xFFF1F5F9),
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

  Widget _buildBillCard(TodayBillItem bill) {
    final timeStr = DateFormat('hh:mm a').format(bill.timestamp);
    final isCash = bill.paymentMethod == 'Cash';
    final isQR = bill.paymentMethod.contains('QR');

    final badgeBg = isCash
        ? const Color(0xFFDCFCE7)
        : isQR
            ? const Color(0xFFE0F2FE)
            : const Color(0xFFFEF3C7);
    final badgeColor = isCash
        ? const Color(0xFF16A34A)
        : isQR
            ? const Color(0xFF0284C7)
            : const Color(0xFFD97706);

    return InkWell(
      onTap: () => _openBillDetails(bill),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Top Row: Bill #, Time, Payment Pill, Three-dot options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Bill #${bill.billNumber}',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bill.paymentMethod,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.moreVertical, size: 15, color: Color(0xFF94A3B8)),
                      onPressed: () => _showBillActions(bill),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.only(left: 6),
                    ),
                  ],
                ),
              ],
            ),
            const Gap(8),

            // Customer Name & Items preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.user, size: 13, color: Color(0xFF64748B)),
                          const Gap(5),
                          Expanded(
                            child: Text(
                              bill.customerName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Gap(3),
                      Text(
                        '${bill.itemsCount} items: ${bill.itemsSummary}',
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
                const Gap(10),
                Text(
                  'Rs. ${bill.amount.toInt()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

