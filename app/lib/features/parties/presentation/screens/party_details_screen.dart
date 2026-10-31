import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/services/printing_service.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../sales/domain/models/customer.dart';
import '../../../sales/domain/models/supplier.dart';
import '../../../sales/presentation/screens/transaction_details_screen.dart';
import '../../../sales/presentation/screens/transactions_screen.dart';
import '../../../sales/presentation/sheets/add_edit_customer_sheet.dart';
import '../../../sales/presentation/sheets/add_edit_supplier_sheet.dart';
import '../../../sales/presentation/sheets/customer_credit_limit_sheet.dart';
import '../../../sales/presentation/sheets/customer_ledger_filter_sheet.dart';
import '../../../sales/presentation/sheets/payment_history_detail_sheet.dart';
import '../../../sales/presentation/sheets/purchase_payment_sheet.dart';
import '../../../sales/presentation/sheets/receive_udhar_payment_sheet.dart';
import '../../../sales/presentation/sheets/record_purchase_sheet.dart';

/// Clean transaction entry for customer/supplier ledger.
class PartyLedgerEntry {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final double amount;
  final double balanceAfter;
  final bool isDebit; // true: balance owed increases, false: payment cleared
  final String? paymentMethod;
  final String? referenceNo;
  final List<TransactionDetailItem> items;
  final double subtotal;
  final double discount;
  final double tax;

  const PartyLedgerEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.balanceAfter,
    required this.isDebit,
    this.paymentMethod,
    this.referenceNo,
    this.items = const [],
    this.subtotal = 0,
    this.discount = 0,
    this.tax = 0,
  });
}

/// Lineless, modern Party Details Screen for viewing Customer or Supplier ledger & profile.
class PartyDetailsScreen extends StatefulWidget {
  const PartyDetailsScreen({
    super.key,
    this.customer,
    this.supplier,
  }) : assert(customer != null || supplier != null, 'Either customer or supplier must be provided');

  final Customer? customer;
  final Supplier? supplier;

  const PartyDetailsScreen.customer(this.customer, {super.key}) : supplier = null;
  const PartyDetailsScreen.supplier(this.supplier, {super.key}) : customer = null;

  @override
  State<PartyDetailsScreen> createState() => _PartyDetailsScreenState();
}

class _PartyDetailsScreenState extends State<PartyDetailsScreen> {
  Customer? _customer;
  Supplier? _supplier;
  bool get _isCustomer => _customer != null;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'All'; // 'All', 'Invoices', 'Payments'
  late List<PartyLedgerEntry> _entries;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _supplier = widget.supplier;
    _initData();
  }

  @override
  void didUpdateWidget(covariant PartyDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customer != widget.customer || oldWidget.supplier != widget.supplier) {
      _customer = widget.customer;
      _supplier = widget.supplier;
      _initData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initData() {
    final partyName = (_isCustomer ? _customer?.name : _supplier?.name) ?? '';
    final partyTxs = AppDataRepository.instance.transactions.where((t) =>
        t.partyName.toLowerCase() == partyName.toLowerCase());

    _entries = partyTxs.map((t) {
      final isDebit = t.category == TransactionCategory.creditSale ||
          t.category == TransactionCategory.purchase;
      return PartyLedgerEntry(
        id: t.id,
        title: t.title,
        subtitle: t.subtitle,
        date: t.timestamp,
        amount: t.amount,
        balanceAfter: _isCustomer
            ? (_customer?.udharBalance ?? 0.0)
            : (_supplier?.outstandingBalance ?? 0.0),
        isDebit: isDebit,
        paymentMethod: t.paymentMethod,
        referenceNo: t.receiptNumber,
        items: t.items,
        subtotal: t.subtotal,
        discount: t.discount,
        tax: t.tax,
      );
    }).toList();
  }

  List<PartyLedgerEntry> get _filteredEntries {
    return _entries.where((entry) {
      if (_filter == 'Invoices' && !entry.isDebit) return false;
      if (_filter == 'Payments' && entry.isDebit) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = entry.title.toLowerCase().contains(q);
        final matchRef = entry.referenceNo?.toLowerCase().contains(q) ?? false;
        final matchSub = entry.subtitle.toLowerCase().contains(q);
        return matchTitle || matchRef || matchSub;
      }
      return true;
    }).toList();
  }

  void _callPhone() {
    final phone = _isCustomer ? _customer!.phone : _supplier!.phone;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number saved.')));
      return;
    }
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Phone $phone copied to clipboard.')));
  }

  void _shareReminder(bool isWhatsApp) {
    final name = _isCustomer ? _customer!.name : _supplier!.name;
    final phone = _isCustomer ? _customer!.phone : _supplier!.phone;
    final bal = _isCustomer ? _customer!.udharBalance : _supplier!.outstandingBalance;

    final storeName = PrintingService.instance.storeName.isNotEmpty ? PrintingService.instance.storeName : AppDataRepository.instance.shopName;
    final msg = _isCustomer
        ? 'Namaste $name ji, your pending Udhar at $storeName is Rs. ${bal.toInt()}. Please settle when convenient. Thank you!'
        : 'Namaste $name ji, confirming current payable balance of Rs. ${bal.toInt()}. Thank you!';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isWhatsApp ? 'WhatsApp Reminder' : 'SMS Reminder', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To: ${phone.isNotEmpty ? phone : "No Phone"}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
            const Gap(8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
              child: Text(msg, style: const TextStyle(fontSize: 13, height: 1.4)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066FF), elevation: 0),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: msg));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied!')));
            },
            child: const Text('Copy Text', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _shareStatement() async {
    final name = _isCustomer ? _customer!.name : _supplier!.name;
    final res = await CustomerLedgerFilterSheet.show(context);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Statement exported for $name')));
    }
  }

  Future<void> _editParty() async {
    if (_isCustomer) {
      final updated = await AddEditCustomerSheet.show(context, customer: _customer);
      if (updated != null && mounted) setState(() => _customer = updated);
    } else {
      final updated = await AddEditSupplierSheet.show(context, supplier: _supplier);
      if (updated != null && mounted) setState(() => _supplier = updated);
    }
  }

  Future<void> _setCreditLimit() async {
    if (!_isCustomer) return;
    final limit = await CustomerCreditLimitSheet.show(context, customer: _customer!);
    if (limit != null && mounted) {
      setState(() => _customer = _customer!.copyWith(creditLimit: limit));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Credit limit updated to Rs. ${limit.toInt()}')));
    }
  }

  Future<void> _receivePayment() async {
    if (!_isCustomer) return;
    final result = await ReceiveUdharPaymentSheet.show(context, customer: _customer!);
    if (result != null && mounted) {
      final newBal = (_customer!.udharBalance - result.amount).clamp(0.0, double.infinity);
      final newEntry = PartyLedgerEntry(
        id: 'tx-pay-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Payment Received',
        subtitle: 'Settled via ${result.method}',
        date: DateTime.now(),
        amount: result.amount,
        balanceAfter: newBal,
        isDebit: false,
        paymentMethod: result.method,
        referenceNo: 'RCT-${DateTime.now().millisecondsSinceEpoch % 10000}',
      );
      setState(() {
        _customer = _customer!.copyWith(udharBalance: newBal);
        _entries.insert(0, newEntry);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Received Rs. ${result.amount.toInt()} from ${_customer!.name}')));
    }
  }

  void _giveCredit() {
    if (!_isCustomer) return;
    final amtController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
            const Gap(14),
            Text('Give Udhar to ${_customer!.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const Gap(14),
            AuthTextField(
              controller: amtController,
              label: 'Udhar Amount',
              prefixText: 'Rs. ',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              hintText: '0.00',
            ),
            const Gap(12),
            AuthTextField(
              controller: noteController,
              label: 'Note (Optional)',
              hintText: 'e.g. Rice, Dal',
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  final amt = double.tryParse(amtController.text.trim()) ?? 0;
                  if (amt <= 0) return;
                  Navigator.pop(ctx);
                  final newBal = _customer!.udharBalance + amt;
                  final note = noteController.text.trim().isNotEmpty ? noteController.text.trim() : 'Manual Credit Sale';
                  final entry = PartyLedgerEntry(
                    id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
                    title: 'Credit Sale',
                    subtitle: note,
                    date: DateTime.now(),
                    amount: amt,
                    balanceAfter: newBal,
                    isDebit: true,
                    referenceNo: 'INV-${DateTime.now().millisecondsSinceEpoch % 10000}',
                  );
                  setState(() {
                    _customer = _customer!.copyWith(udharBalance: newBal);
                    _entries.insert(0, entry);
                  });
                },
                child: const Text('Record Credit Given', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _paySupplier() async {
    if (_isCustomer) return;
    final result = await PurchasePaymentSheet.show(context, supplier: _supplier!);
    if (result != null && mounted) {
      final newBal = (_supplier!.outstandingBalance - result.amount).clamp(0.0, double.infinity);
      final newEntry = PartyLedgerEntry(
        id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Payment Made to Supplier',
        subtitle: 'Settled via ${result.method}',
        date: DateTime.now(),
        amount: result.amount,
        balanceAfter: newBal,
        isDebit: false,
        paymentMethod: result.method,
        referenceNo: result.reference.isNotEmpty ? result.reference : 'PAY-${DateTime.now().millisecondsSinceEpoch % 10000}',
      );
      setState(() {
        _supplier = _supplier!.copyWith(outstandingBalance: newBal);
        _entries.insert(0, newEntry);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Paid Rs. ${result.amount.toInt()} to ${_supplier!.name}')));
    }
  }

  Future<void> _recordPurchase() async {
    if (_isCustomer) return;
    final result = await RecordPurchaseSheet.show(context, initialSupplier: _supplier);
    if (result != null && mounted) {
      final newBal = _supplier!.outstandingBalance + result.totalAmount;
      final newEntry = PartyLedgerEntry(
        id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Purchase Bill #${result.invoiceNumber}',
        subtitle: '${result.productName} (${result.quantity.toInt()} ${result.unit})',
        date: DateTime.now(),
        amount: result.totalAmount,
        balanceAfter: newBal,
        isDebit: true,
        referenceNo: result.invoiceNumber,
      );
      setState(() {
        _supplier = _supplier!.copyWith(outstandingBalance: newBal);
        _entries.insert(0, newEntry);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recorded purchase of Rs. ${result.totalAmount.toInt()}')));
    }
  }

  void _onBack() => Navigator.of(context).pop(_isCustomer ? _customer : _supplier);

  @override
  Widget build(BuildContext context) {
    final partyName = _isCustomer ? _customer!.name : _supplier!.name;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppTopBar(
          title: partyName,
          showBackButton: true,
          onBack: _onBack,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.phone, size: 18),
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              onPressed: _callPhone,
              tooltip: 'Copy number',
            ),
            IconButton(
              icon: const Icon(LucideIcons.pencil, size: 18),
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              onPressed: _editParty,
              tooltip: 'Edit',
            ),
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical, size: 18),
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'edit') _editParty();
                if (val == 'limit') _setCreditLimit();
                if (val == 'statement') _shareStatement();
                if (val == 'whatsapp') _shareReminder(true);
                if (val == 'sms') _shareReminder(false);
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Details')),
                if (_isCustomer) const PopupMenuItem(value: 'limit', child: Text('Set Credit Limit')),
                const PopupMenuItem(value: 'statement', child: Text('Export Statement')),
                const PopupMenuItem(value: 'whatsapp', child: Text('WhatsApp Reminder')),
                const PopupMenuItem(value: 'sms', child: Text('SMS Reminder')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF0066FF),
                backgroundColor: Colors.white,
                onRefresh: () async {
                  await AppDataRepository.instance.refreshAll();
                  if (mounted) {
                    setState(() {
                      if (_isCustomer && _customer != null) {
                        _customer = AppDataRepository.instance.customers.firstWhere(
                          (c) => c.id == _customer!.id,
                          orElse: () => _customer!,
                        );
                      } else if (!_isCustomer && _supplier != null) {
                        _supplier = AppDataRepository.instance.suppliers.firstWhere(
                          (s) => s.id == _supplier!.id,
                          orElse: () => _supplier!,
                        );
                      }
                      _initData();
                    });
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      const Gap(12),
                      _buildBalanceBanner(),
                      const Gap(16),
                      _buildLedgerList(),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // --- Lineless Clean Components ---

  Widget _buildProfileHeader() {
    final name = _isCustomer ? _customer!.name : _supplier!.name;
    final phone = _isCustomer ? _customer!.phone : _supplier!.phone;
    final address = _isCustomer ? _customer!.address : _supplier!.address;
    final pan = !_isCustomer ? _supplier!.panNumber : '';
    final limit = _isCustomer ? _customer!.creditLimit : 0.0;
    final initials = name.trim().isNotEmpty ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join() : 'P';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _isCustomer ? const Color(0xFFDBEAFE) : const Color(0xFFEDE9FE),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _isCustomer ? const Color(0xFF0066FF) : const Color(0xFF7C3AED),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.2),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _isCustomer ? const Color(0xFFDCFCE7) : const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _isCustomer ? 'Customer' : 'Supplier',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _isCustomer ? const Color(0xFF16A34A) : const Color(0xFF9333EA)),
                          ),
                        ),
                      ],
                    ),
                    const Gap(3),
                    Row(
                      children: [
                        const Icon(LucideIcons.phone, size: 12, color: Color(0xFF64748B)),
                        const Gap(4),
                        Flexible(
                          child: Text(
                            phone.isNotEmpty ? phone : 'No phone',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                          ),
                        ),
                        if (address.isNotEmpty) ...[
                          const Gap(6),
                          const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                          const Gap(6),
                          Expanded(
                            child: Text(
                              address,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Secondary Tags (PAN / Credit Limit)
          if (pan.isNotEmpty || (_isCustomer && limit > 0)) ...[
            const Gap(12),
            Row(
              children: [
                if (pan.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                    child: Text('PAN: $pan', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  ),
                if (_isCustomer && limit > 0)
                  InkWell(
                    onTap: _setCreditLimit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                      child: Text('Limit: Rs. ${limit.toInt()}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0066FF))),
                    ),
                  ),
              ],
            ),
          ],

          const Gap(14),

          // Clean Lineless Action Pills
          Row(
            children: [
              _actionPill(LucideIcons.copy, 'Copy No.', const Color(0xFF0066FF), _callPhone),
              const Gap(8),
              _actionPill(LucideIcons.messageCircle, 'WhatsApp', const Color(0xFF16A34A), () => _shareReminder(true)),
              const Gap(8),
              _actionPill(LucideIcons.bell, 'Remind', const Color(0xFFEA580C), () => _shareReminder(false)),
              const Gap(8),
              _actionPill(LucideIcons.share2, 'Statement', const Color(0xFF475569), _shareStatement),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionPill(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 15, color: color),
              const Gap(3),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)), maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceBanner() {
    if (_isCustomer) {
      final bal = _customer!.udharBalance;
      final limit = _customer!.creditLimit;
      final hasUdhar = bal > 0;
      final pct = limit > 0 ? (bal / limit).clamp(0.0, 1.0) : 0.0;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasUdhar ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasUdhar ? 'Total Udhar Due (To Collect)' : 'All Udhar Settled',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: hasUdhar ? const Color(0xFF991B1B) : const Color(0xFF166534)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasUdhar ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasUdhar ? 'Due' : 'Clear',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: hasUdhar ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                  ),
                ),
              ],
            ),
            const Gap(6),
            Text(
              'Rs. ${bal.toInt()}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: hasUdhar ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                letterSpacing: -0.5,
              ),
            ),
            if (limit > 0) ...[
              const Gap(8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: hasUdhar ? const Color(0xFFFCA5A5).withValues(alpha: 0.3) : const Color(0xFF86EFAC).withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(pct > 0.8 ? const Color(0xFFDC2626) : const Color(0xFF2563EB)),
                ),
              ),
              const Gap(5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(pct * 100).toInt()}% limit used', style: TextStyle(fontSize: 11, color: hasUdhar ? const Color(0xFF991B1B) : const Color(0xFF166534))),
                  Text('Rs. ${(limit - bal).clamp(0.0, limit).toInt()} remaining', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: hasUdhar ? const Color(0xFF991B1B) : const Color(0xFF166534))),
                ],
              ),
            ],
          ],
        ),
      );
    } else {
      final bal = _supplier!.outstandingBalance;
      final hasPayable = bal > 0;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasPayable ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasPayable ? 'Outstanding Payable (To Pay)' : 'All Payables Settled',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: hasPayable ? const Color(0xFF1E40AF) : const Color(0xFF166534)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasPayable ? const Color(0xFFDBEAFE) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasPayable ? 'Payable' : 'Zero',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: hasPayable ? const Color(0xFF0066FF) : const Color(0xFF16A34A)),
                  ),
                ),
              ],
            ),
            const Gap(6),
            Text(
              'Rs. ${bal.toInt()}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: hasPayable ? const Color(0xFF0066FF) : const Color(0xFF16A34A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLedgerList() {
    final entries = _filteredEntries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Ledger Statement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                  child: Text('${_entries.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                ),
              ],
            ),
            InkWell(
              onTap: _shareStatement,
              child: const Text('Export PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0066FF))),
            ),
          ],
        ),
        const Gap(10),

        // Lineless Search Box
        Container(
          height: 38,
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(fontSize: 13),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              prefixIcon: const Icon(LucideIcons.search, size: 15, color: Color(0xFF94A3B8)),
              prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 13),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              hintText: 'Search ledger entries...',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ),
        ),
        const Gap(10),

        // Lineless Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip('All (${_entries.length})', 'All'),
              const Gap(6),
              _chip(_isCustomer ? 'Udhar Given' : 'Purchases', 'Invoices'),
              const Gap(6),
              _chip('Payments', 'Payments'),
            ],
          ),
        ),
        const Gap(12),

        // Clean Lineless Transaction Rows
        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Text('No transactions found', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Gap(8),
            itemBuilder: (ctx, i) => _buildEntryTile(entries[i]),
          ),
          const Gap(10),
          const AppBottomLoader(hasMore: false),
        ],
      ],
    );
  }

  Widget _chip(String label, String val) {
    final active = _filter == val;
    return InkWell(
      onTap: () => setState(() => _filter = val),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0066FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF475569)),
        ),
      ),
    );
  }

  Widget _buildEntryTile(PartyLedgerEntry e) {
    final dateStr = DateFormat('dd MMM, hh:mm a').format(e.date);

    return InkWell(
      onTap: () {
        if (!e.isDebit) {
          PaymentHistoryDetailSheet.show(
            context,
            receiptNumber: e.referenceNo ?? 'RCT-001',
            customerName: _isCustomer ? _customer!.name : _supplier!.name,
            amount: e.amount,
            paymentMethod: e.paymentMethod ?? 'Cash',
            dateStr: dateStr,
          );
        } else {
          final matchingTx = AppDataRepository.instance.transactions.firstWhere(
            (t) =>
                (e.referenceNo != null &&
                    e.referenceNo!.isNotEmpty &&
                    t.receiptNumber == e.referenceNo) ||
                t.id == e.id,
            orElse: () => FullTransactionModel(
              id: e.id,
              receiptNumber: e.referenceNo ?? '',
              title: e.title,
              subtitle: e.subtitle,
              partyName: _isCustomer ? _customer!.name : _supplier!.name,
              timestamp: e.date,
              amount: e.amount,
              category: _isCustomer
                  ? TransactionCategory.creditSale
                  : TransactionCategory.purchase,
              paymentMethod: e.paymentMethod ?? 'Credit',
              items: e.items,
            ),
          );

          final resolvedItems = e.items.isNotEmpty
              ? e.items
              : (matchingTx.items.isNotEmpty
                  ? matchingTx.items
                  : [
                      TransactionDetailItem(
                        name: e.subtitle.isNotEmpty && !e.subtitle.contains('items')
                            ? e.subtitle
                            : 'Udhar / Credit Goods',
                        quantity: 1,
                        unit: 'lot',
                        rate: e.amount,
                        total: e.amount,
                      ),
                    ]);

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TransactionDetailsScreen(
                receiptNumber: e.referenceNo ?? matchingTx.receiptNumber,
                title: e.title,
                customerName: _isCustomer ? _customer!.name : _supplier!.name,
                customerPhone: _isCustomer ? _customer!.phone : _supplier!.phone,
                customerAddress: _isCustomer ? _customer!.address : _supplier!.address,
                timestamp: e.date,
                items: resolvedItems,
                subtotal: (e.subtotal > 0 ? e.subtotal : matchingTx.subtotal) > 0
                    ? (e.subtotal > 0 ? e.subtotal : matchingTx.subtotal)
                    : e.amount,
                discountAmount: e.discount > 0 ? e.discount : matchingTx.discount,
                taxAmount: e.tax > 0 ? e.tax : matchingTx.tax,
                totalAmount: e.amount,
                paymentMethod: _isCustomer ? 'Credit (Udhar)' : 'Credit / Payable',
                paymentStatus: 'CREDIT',
                udharAmount: e.amount,
                isPurchase: !_isCustomer,
              ),
            ),
          );
        }
      },
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: e.isDebit ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                e.isDebit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                size: 16,
                color: e.isDebit ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
              ),
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  const Gap(2),
                  Text('$dateStr • ${e.subtitle}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Gap(8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${e.isDebit ? '+' : '-'} Rs. ${e.amount.toInt()}',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: e.isDebit ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                ),
                const Gap(2),
                Text('Bal: Rs. ${e.balanceAfter.toInt()}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: _isCustomer
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF334155),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(LucideIcons.plus, size: 15),
                    label: const Text('Give Udhar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    onPressed: _giveCredit,
                  ),
                ),
                const Gap(10),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(LucideIcons.arrowDownLeft, size: 15),
                    label: const Text('Receive Payment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    onPressed: _receivePayment,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF334155),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(LucideIcons.filePlus, size: 15),
                    label: const Text('Record Bill', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    onPressed: _recordPurchase,
                  ),
                ),
                const Gap(10),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(LucideIcons.arrowUpRight, size: 15),
                    label: const Text('Pay Supplier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    onPressed: _paySupplier,
                  ),
                ),
              ],
            ),
    );
  }
}
