import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/services/printing_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/models/sale_record.dart';
import '../sheets/bill_actions_sheet.dart';

/// Item in a transaction invoice / receipt.
class TransactionDetailItem {
  final String name;
  final double quantity;
  final String unit;
  final double rate;
  final double total;

  const TransactionDetailItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.total,
  });
}

/// Comprehensive, lineless View Details Screen for any Sale, Bill, Purchase, or Udhar transaction.
class TransactionDetailsScreen extends StatefulWidget {
  const TransactionDetailsScreen({
    super.key,
    required this.receiptNumber,
    this.title = 'Sale Invoice',
    this.customerName = 'Walk-in Customer',
    this.customerPhone = '',
    this.customerAddress = '',
    required this.timestamp,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    required this.totalAmount,
    this.paymentMethod = 'Cash',
    this.paymentStatus = 'PAID',
    this.cashReceived = 0.0,
    this.changeReturned = 0.0,
    this.udharAmount = 0.0,
    this.note = '',
    this.isPurchase = false,
  });

  final String receiptNumber;
  final String title;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final DateTime timestamp;
  final List<TransactionDetailItem> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus; // 'PAID', 'CREDIT', 'PARTIAL', 'REFUNDED'
  final double cashReceived;
  final double changeReturned;
  final double udharAmount;
  final String note;
  final bool isPurchase;

  /// Factory constructor to display a [SaleRecord] directly.
  factory TransactionDetailsScreen.fromSaleRecord(SaleRecord sale) {
    return TransactionDetailsScreen(
      receiptNumber: sale.receiptNumber,
      title: 'Sale #${sale.receiptNumber}',
      customerName: sale.customer.name,
      customerPhone: sale.customer.phone,
      customerAddress: sale.customer.address,
      timestamp: sale.timestamp,
      items: sale.items
          .map(
            (item) => TransactionDetailItem(
              name: item.product.name,
              quantity: item.quantity,
              unit: item.unit,
              rate: item.unitPrice,
              total: item.totalPrice,
            ),
          )
          .toList(),
      subtotal: sale.subtotal,
      discountAmount: sale.discountAmount,
      taxAmount: 0.0,
      totalAmount: sale.totalAmount,
      paymentMethod: sale.paymentMethodName,
      paymentStatus: sale.paymentMethod == PaymentMethod.credit
          ? 'CREDIT'
          : 'PAID',
      cashReceived: sale.cashReceived,
      changeReturned: sale.changeReturned,
      udharAmount: sale.udharAmount,
      note: sale.note,
    );
  }

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  bool _isCancelled = false;

  /// The tax rate is derived from the stored tax and taxable base instead of
  /// being hardcoded to 13% on every bill.
  String get _taxLabel {
    final base = widget.subtotal - widget.discountAmount;
    if (widget.taxAmount <= 0 || base <= 0) return 'VAT / Tax';
    final rate = (widget.taxAmount / base * 100);
    return 'VAT / Tax (${rate.round()}%)';
  }

  InvoicePrintData _toInvoiceData() {
    return InvoicePrintData(
      invoiceNumber: widget.receiptNumber,
      date: widget.timestamp,
      customerName: widget.customerName,
      customerPhone: widget.customerPhone,
      items: widget.items
          .map((item) => InvoiceItemData(
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                unitPrice: item.rate,
                total: item.total,
              ))
          .toList(),
      subtotal: widget.subtotal,
      discount: widget.discountAmount,
      tax: widget.taxAmount,
      grandTotal: widget.totalAmount,
      paymentMethod: widget.paymentMethod,
      cashReceived: widget.cashReceived,
      changeDue: widget.changeReturned,
      note: widget.note,
    );
  }

  Future<void> _handlePrint() async {
    HapticFeedback.lightImpact();
    try {
      await PrintingService.instance.printInvoice(_toInvoiceData());
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
  }

  Future<void> _handleShare() async {
    HapticFeedback.lightImpact();
    try {
      await PrintingService.instance.shareInvoicePdf(_toInvoiceData());
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
  }

  void _handleCopyReceipt() {
    Clipboard.setData(ClipboardData(text: widget.receiptNumber));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied Bill #${widget.receiptNumber} to clipboard'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openMoreActions() async {
    final action = await BillActionsSheet.show(
      context,
      billNumber: widget.receiptNumber,
      amount: widget.totalAmount,
    );

    if (action != null && mounted) {
      if (action == BillActionType.print) {
        _handlePrint();
      } else if (action == BillActionType.share) {
        _handleShare();
      } else if (action == BillActionType.cancel) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Void this bill?'),
            content: Text(
              'Bill #${widget.receiptNumber} will be cancelled and its items returned to stock. '
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

        await AppDataRepository.instance
            .voidBill(widget.receiptNumber, 'Voided from bill details');
        if (!mounted) return;
        setState(() => _isCancelled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill #${widget.receiptNumber} voided'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(widget.timestamp);

    final isCredit = widget.paymentStatus == 'CREDIT' && !_isCancelled;
    final isCancelled = _isCancelled || widget.paymentStatus == 'REFUNDED';

    final statusBg = isCancelled
        ? const Color(0xFFFEE2E2)
        : isCredit
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFDCFCE7);
    final statusColor = isCancelled
        ? const Color(0xFFDC2626)
        : isCredit
            ? const Color(0xFFD97706)
            : const Color(0xFF16A34A);
    final statusText = isCancelled
        ? 'CANCELLED'
        : isCredit
            ? 'CREDIT'
            : 'PAID';

    return DefaultTabController(
      length: 2,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Clean Top Bar
                AppTopBar(
                  title: 'Bill #${widget.receiptNumber}',
                  leading: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, size: 20, color: Color(0xFF0F172A)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(LucideIcons.printer, size: 20, color: Color(0xFF475569)),
                      tooltip: 'Print',
                      onPressed: _handlePrint,
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.share2, size: 20, color: Color(0xFF475569)),
                      tooltip: 'Share',
                      onPressed: _handleShare,
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.moreVertical, size: 20, color: Color(0xFF475569)),
                      tooltip: 'More',
                      onPressed: _openMoreActions,
                    ),
                  ],
                ),

                // Tab Bar
                Container(
                  color: Colors.white,
                  child: const TabBar(
                    indicatorColor: Color(0xFF2563EB),
                    indicatorWeight: 3,
                    labelColor: Color(0xFF2563EB),
                    unselectedLabelColor: Color(0xFF64748B),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.receipt, size: 16),
                            Gap(6),
                            Text('Receipt'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.fileText, size: 16),
                            Gap(6),
                            Text('Details'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Content View
                Expanded(
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: _buildPrintedReceipt(colors),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: _buildDetailsBreakdown(colors, dateStr, statusBg, statusColor, statusText),
                      ),
                    ],
                  ),
                ),

                // Bottom Quick Actions Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: _handleShare,
                          icon: const Icon(LucideIcons.share2, size: 16),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _handlePrint,
                          icon: const Icon(LucideIcons.printer, size: 17, color: Colors.white),
                          label: const Text(
                            'Print Bill',
                            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mirror of the exact printed thermal POS receipt format generated by [PrintingService].
  Widget _buildPrintedReceipt(AppColorsExtension colors) {
    return ListenableBuilder(
      listenable: PrintingService.instance,
      builder: (context, _) {
        final printing = PrintingService.instance;
        final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
        final dateFormatted = dateFormat.format(widget.timestamp);
        final isCancelled = _isCancelled || widget.paymentStatus == 'REFUNDED';
        final isCredit = widget.paymentStatus == 'CREDIT' && !isCancelled;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                // Thermal Paper Container
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Stamp watermark if Cancelled or Credit
                      if (isCancelled || isCredit)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isCancelled ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isCancelled ? 'VOID / CANCELLED' : 'CREDIT / UDHAR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: isCancelled ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ),

                      // Store Header (Matches PrintingService)
                      Text(
                        printing.storeName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (printing.storeAddress.isNotEmpty) ...[
                        const Gap(2),
                        Text(
                          printing.storeAddress,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                        ),
                      ],
                      if (printing.storePhone.isNotEmpty) ...[
                        const Gap(1),
                        Text(
                          'Tel: ${printing.storePhone}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                        ),
                      ],
                      if (printing.panNumber.isNotEmpty) ...[
                        const Gap(2),
                        Text(
                          'PAN / VAT: ${printing.panNumber}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],

                      const Gap(10),
                      const _DashedDivider(),
                      const Gap(8),

                      // Invoice Metadata
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _handleCopyReceipt,
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Bill #${widget.receiptNumber}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Gap(4),
                                  const Icon(LucideIcons.copy, size: 11, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            dateFormatted,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (widget.customerName.isNotEmpty &&
                          widget.customerName.toLowerCase() != 'walk-in customer') ...[
                        const Gap(4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer: ',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                            Expanded(
                              child: Text(
                                widget.customerName,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (widget.customerPhone.isNotEmpty)
                              Text(
                                widget.customerPhone,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                          ],
                        ),
                      ],

                      const Gap(10),
                      const _DashedDivider(),
                      const Gap(8),

                      // Table Header (Item | Qty | Rate | Total)
                      Row(
                        children: const [
                          Expanded(
                            flex: 5,
                            child: Text(
                              'Item',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Qty',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Rate',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Total',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(6),
                      const _DashedDivider(dashWidth: 3, dashSpace: 2, color: Color(0xFFE2E8F0)),
                      const Gap(6),

                      // Items List (Renders full individual item details)
                      if (widget.items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Text(
                                  widget.note.isNotEmpty ? widget.note : 'Udhar Goods',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  '1',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  formatAmount(widget.totalAmount),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  formatAmount(widget.totalAmount),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...widget.items.map((item) {
                          final qtyStr = formatQuantity(item.quantity);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    qtyStr,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    formatAmount(item.rate),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    formatAmount(item.total),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                      const Gap(8),
                      const _DashedDivider(),
                      const Gap(8),

                      // Totals & Billing Breakdown
                      _buildReceiptRow('Subtotal', 'Rs. ${formatAmount(widget.subtotal)}'),
                      if (widget.discountAmount > 0)
                        _buildReceiptRow(
                          'Discount',
                          '- Rs. ${formatAmount(widget.discountAmount)}',
                          color: const Color(0xFF16A34A),
                        ),
                      if (widget.taxAmount > 0)
                        _buildReceiptRow(_taxLabel, 'Rs. ${formatAmount(widget.taxAmount)}'),

                      const Gap(4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'GRAND TOTAL',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const Gap(8),
                          Text(
                            'Rs. ${formatAmount(widget.totalAmount)}',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),

                      _buildReceiptRow('Payment Method', widget.paymentMethod),
                      if (widget.cashReceived > 0)
                        _buildReceiptRow('Cash Received', 'Rs. ${formatAmount(widget.cashReceived)}'),
                      if (widget.changeReturned > 0)
                        _buildReceiptRow(
                          'Change Returned',
                          'Rs. ${formatAmount(widget.changeReturned)}',
                          color: const Color(0xFF16A34A),
                        ),
                      if (widget.udharAmount > 0)
                        _buildReceiptRow(
                          'Udhar / Due Added',
                          'Rs. ${formatAmount(widget.udharAmount)}',
                          color: const Color(0xFFDC2626),
                        ),

                      const Gap(10),
                      const _DashedDivider(),
                      const Gap(12),

                      // Barcode Widget (Matches PrintingService thermal print)
                      Center(
                        child: Column(
                          children: [
                            BarcodeWidget(
                              barcode: Barcode.code128(),
                              data: widget.receiptNumber.isNotEmpty ? widget.receiptNumber : 'INV-0001',
                              width: 170,
                              height: 40,
                              drawText: false,
                            ),
                            const Gap(4),
                            Text(
                              widget.receiptNumber,
                              style: const TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (printing.footerMessage.isNotEmpty) ...[
                        const Gap(10),
                        Text(
                          printing.footerMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],

                      if (widget.note.isNotEmpty) ...[
                        const Gap(8),
                        Text(
                          'Note: ${widget.note}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Serrated / Zigzag bottom tear-off paper edge
                const SizedBox(
                  width: double.infinity,
                  height: 8,
                  child: CustomPaint(
                    painter: _ZigzagEdgePainter(
                      color: Colors.white,
                      triangleHeight: 7,
                      triangleWidth: 12,
                    ),
                  ),
                ),
                const Gap(16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Gap(8),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color ?? const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  /// Full digital card breakdown with contact shortcuts and void actions.
  Widget _buildDetailsBreakdown(
    AppColorsExtension colors,
    String dateStr,
    Color statusBg,
    Color statusColor,
    String statusText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Digital Invoice Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              // Store Branding Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          PrintingService.instance.storeName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.darkText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Gap(3),
                        if (PrintingService.instance.panNumber.isNotEmpty ||
                            PrintingService.instance.storeAddress.isNotEmpty)
                          Text(
                            '${PrintingService.instance.panNumber.isNotEmpty ? 'PAN: ${PrintingService.instance.panNumber} • ' : ''}${PrintingService.instance.storeAddress.isNotEmpty ? PrintingService.instance.storeAddress : 'Nepal'}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (PrintingService.instance.storePhone.isNotEmpty)
                          Text(
                            'Phone: ${PrintingService.instance.storePhone}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(16),

              // Invoice Number & Date Pill Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _handleCopyReceipt,
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Invoice #${widget.receiptNumber}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Gap(6),
                            const Icon(LucideIcons.copy, size: 13, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Gap(14),

        // Customer / Supplier Info Card (shown when party is known)
        if (widget.customerName.isNotEmpty &&
            widget.customerName.toLowerCase() != 'walk-in customer') ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: Icon(
                    widget.isPurchase ? LucideIcons.truck : LucideIcons.user,
                    size: 18,
                    color: const Color(0xFF475569),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customerName,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: colors.darkText,
                        ),
                      ),
                      if (widget.customerPhone.isNotEmpty)
                        Text(
                          widget.customerPhone,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.customerPhone.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(LucideIcons.phone, size: 16, color: Color(0xFF2563EB)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling ${widget.customerPhone}...')),
                      );
                    },
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  const Gap(4),
                  IconButton(
                    icon: const Icon(LucideIcons.messageCircle, size: 16, color: Color(0xFF16A34A)),
                    onPressed: _handleShare,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ],
            ),
          ),
          const Gap(14),
        ],

        // Items Table Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Items (${widget.items.isNotEmpty ? widget.items.length : 1})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Gap(12),

              // Items List
              if (widget.items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.note.isNotEmpty ? widget.note : 'Udhar / Credit Goods',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: colors.darkText,
                              ),
                            ),
                            const Gap(2),
                            Text(
                              '1 entry × ${formatMoney(widget.totalAmount)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatMoney(widget.totalAmount),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.darkText,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.items.length,
                  separatorBuilder: (_, _) => const Gap(10),
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final qtyStr = formatQuantity(item.quantity);
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: colors.darkText,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  '$qtyStr ${item.unit} × ${formatMoney(item.rate)}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatMoney(item.total),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: colors.darkText,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const Gap(14),

        // Billing Breakdown & Payment Method
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _calcRow('Subtotal', formatMoney(widget.subtotal)),
              if (widget.discountAmount > 0) ...[
                const Gap(8),
                _calcRow(
                  'Discount Applied',
                  '- ${formatMoney(widget.discountAmount)}',
                  color: const Color(0xFF16A34A),
                ),
              ],
              if (widget.taxAmount > 0) ...[
                const Gap(8),
                _calcRow(
                  _taxLabel,
                  '+ ${formatMoney(widget.taxAmount)}',
                ),
              ],
              const Gap(12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Grand Total',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      formatMoney(widget.totalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(14),

              // Payment Method Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Payment Mode',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Gap(8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.paymentMethod.toLowerCase().contains('cash')
                                  ? LucideIcons.banknote
                                  : widget.paymentMethod.toLowerCase().contains('qr')
                                      ? LucideIcons.qrCode
                                      : widget.paymentMethod.toLowerCase().contains('credit')
                                          ? LucideIcons.clock
                                          : LucideIcons.creditCard,
                              size: 14,
                              color: const Color(0xFF2563EB),
                            ),
                            const Gap(6),
                            Text(
                              widget.paymentMethod,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (widget.cashReceived > 0) ...[
                      const Gap(6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Cash Tendered',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            formatMoney(widget.cashReceived),
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    if (widget.changeReturned > 0) ...[
                      const Gap(6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Change Returned',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            formatMoney(widget.changeReturned),
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    ],
                    if (widget.udharAmount > 0) ...[
                      const Gap(6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Udhar / Due Added',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFFDC2626)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            formatMoney(widget.udharAmount),
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.note.isNotEmpty) ...[
                const Gap(10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.notepadText, size: 13, color: Color(0xFF94A3B8)),
                    const Gap(6),
                    Expanded(
                      child: Text(
                        'Note: ${widget.note}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Gap(24),
      ],
    );
  }

  Widget _calcRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Gap(8),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

/// Realistic dashed divider line matching thermal receipts without RenderFlex layout overflow.
class _DashedDivider extends StatelessWidget {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const _DashedDivider({
    this.color = const Color(0xFFCBD5E1),
    this.dashWidth = 5,
    this.dashSpace = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: color,
          dashWidth: dashWidth,
          dashSpace: dashSpace,
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const _DashedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || !size.width.isFinite) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;

    double currentX = 0;
    while (currentX < size.width) {
      final nextX = (currentX + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(
        Offset(currentX, 0),
        Offset(nextX, 0),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace;
}

/// Custom painter for the zigzag / serrated tear-off bottom edge of the receipt paper.
class _ZigzagEdgePainter extends CustomPainter {
  final Color color;
  final double triangleHeight;
  final double triangleWidth;

  const _ZigzagEdgePainter({
    required this.color,
    this.triangleHeight = 7,
    this.triangleWidth = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || !size.width.isFinite || triangleWidth <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);

    double currentX = 0;
    while (currentX < size.width) {
      currentX += triangleWidth / 2;
      path.lineTo(currentX, triangleHeight);
      currentX += triangleWidth / 2;
      path.lineTo(currentX.clamp(0.0, size.width), 0);
    }

    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

