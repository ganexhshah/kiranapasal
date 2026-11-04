import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/theme/theme.dart';
import '../screens/today_bills_screen.dart';
import '../screens/transaction_details_screen.dart';

enum CancelReturnActionType {
  voided,
  returned,
}

/// Modal bottom sheet allowing shopkeepers to either:
/// 1. Void / Cancel an entire bill with complete inventory restock & financial reversal.
/// 2. Process partial or full item returns with quantity steppers and refund method selection.
class CancelReturnBillSheet extends StatefulWidget {
  const CancelReturnBillSheet({
    super.key,
    required this.billNumber,
    required this.totalAmount,
    required this.paymentMethod,
    required this.items,
    this.customerName = 'Walk-in Customer',
    this.customerPhone = '',
    this.timestamp,
    this.udharAmount = 0.0,
    this.initialIsReturn = false,
    this.status = 'PAID',
  });

  final String billNumber;
  final double totalAmount;
  final String paymentMethod;
  final List<TransactionDetailItem> items;
  final String customerName;
  final String customerPhone;
  final DateTime? timestamp;
  final double udharAmount;
  final bool initialIsReturn;
  final String status;

  /// Helper launcher from a [TodayBillItem]
  static Future<CancelReturnActionType?> showFromBill(
    BuildContext context, {
    required TodayBillItem bill,
    bool initialIsReturn = false,
  }) {
    return show(
      context,
      billNumber: bill.billNumber,
      totalAmount: bill.amount,
      paymentMethod: bill.paymentMethod,
      items: bill.items,
      customerName: bill.customerName,
      customerPhone: bill.customerPhone,
      timestamp: bill.timestamp,
      udharAmount: bill.udharAmount,
      initialIsReturn: initialIsReturn,
      status: bill.status,
    );
  }

  /// Show the sheet modal
  static Future<CancelReturnActionType?> show(
    BuildContext context, {
    required String billNumber,
    required double totalAmount,
    required String paymentMethod,
    required List<TransactionDetailItem> items,
    String customerName = 'Walk-in Customer',
    String customerPhone = '',
    DateTime? timestamp,
    double udharAmount = 0.0,
    bool initialIsReturn = false,
    String status = 'PAID',
  }) {
    return showModalBottomSheet<CancelReturnActionType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CancelReturnBillSheet(
        billNumber: billNumber,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        items: items,
        customerName: customerName,
        customerPhone: customerPhone,
        timestamp: timestamp,
        udharAmount: udharAmount,
        initialIsReturn: initialIsReturn,
        status: status,
      ),
    );
  }

  @override
  State<CancelReturnBillSheet> createState() => _CancelReturnBillSheetState();
}

class _CancelReturnBillSheetState extends State<CancelReturnBillSheet> {
  late int _selectedTab; // 0: Void Bill, 1: Return Items
  bool _isProcessing = false;

  // Void Tab State
  String _voidReason = 'Customer cancelled';
  final TextEditingController _voidNoteController = TextEditingController();

  static const List<String> _voidReasons = [
    'Customer cancelled',
    'Entered wrong items / price',
    'Duplicate bill generated',
    'Payment failed',
    'Customer returned all goods',
    'Other reason',
  ];

  // Return Tab State
  late List<bool> _selectedItems;
  late List<double> _returnQuantities;
  bool _restockReturnedItems = true;
  String _returnReason = 'Customer returned (good condition)';
  late String _refundMethod;

  static const List<String> _returnReasons = [
    'Customer returned (good condition)',
    'Defective / damaged item',
    'Expired product',
    'Wrong item given',
    'Customer changed mind',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialIsReturn ? 1 : 0;

    // Initialize item selection state
    _selectedItems = List<bool>.filled(widget.items.length, true);
    _returnQuantities = widget.items.map((it) => it.quantity).toList();

    // Default refund method based on original payment
    if (widget.paymentMethod.contains('Credit') || widget.udharAmount > 0) {
      _refundMethod = 'Credit (Udhar) Reversal';
    } else {
      _refundMethod = 'Cash';
    }
  }

  @override
  void dispose() {
    _voidNoteController.dispose();
    super.dispose();
  }

  double get _calculatedRefundTotal {
    double total = 0.0;
    for (int i = 0; i < widget.items.length; i++) {
      if (i < _selectedItems.length && _selectedItems[i]) {
        final qty = _returnQuantities[i];
        final rate = widget.items[i].rate;
        total += qty * rate;
      }
    }
    return total;
  }

  int get _selectedItemsCount {
    return _selectedItems.where((sel) => sel).length;
  }

  Future<void> _handleConfirmVoid() async {
    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);

    final finalReason = _voidNoteController.text.trim().isNotEmpty
        ? '$_voidReason - ${_voidNoteController.text.trim()}'
        : _voidReason;

    try {
      final success = await AppDataRepository.instance.voidBill(
        widget.billNumber,
        finalReason,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (success) {
        Navigator.pop(context, CancelReturnActionType.voided);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 20),
                const Gap(10),
                Expanded(
                  child: Text(
                    'Bill #${widget.billNumber} has been successfully voided.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to void bill. Please try again.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error voiding bill: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _handleConfirmReturn() async {
    final refundAmount = _calculatedRefundTotal;
    if (_selectedItemsCount == 0 || refundAmount <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 item to return.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);

    final List<TransactionDetailItem> returnedList = [];
    for (int i = 0; i < widget.items.length; i++) {
      if (_selectedItems[i] && _returnQuantities[i] > 0) {
        final orig = widget.items[i];
        final returnQty = _returnQuantities[i];
        returnedList.add(TransactionDetailItem(
          name: orig.name,
          quantity: returnQty,
          unit: orig.unit,
          rate: orig.rate,
          total: returnQty * orig.rate,
        ));
      }
    }

    try {
      final success = await AppDataRepository.instance.returnBillItems(
        billNumber: widget.billNumber,
        returnedItems: returnedList,
        reason: _returnReason,
        refundMethod: _refundMethod,
        refundAmount: refundAmount,
        restockItems: _restockReturnedItems,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (success) {
        Navigator.pop(context, CancelReturnActionType.returned);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 20),
                const Gap(10),
                Expanded(
                  child: Text(
                    'Return processed: Rs. ${refundAmount.toStringAsFixed(0)} refunded via $_refundMethod.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing return: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAlreadyVoid = widget.status == 'VOID';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              const Gap(10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(14),

              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.undo2,
                        size: 20,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Bill #${widget.billNumber}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: colors.darkText,
                                ),
                              ),
                              const Gap(8),
                              if (isAlreadyVoid)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ALREADY VOID',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Gap(2),
                          Text(
                            '${widget.customerName} • Rs. ${widget.totalAmount.toInt()} (${widget.paymentMethod})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.inputLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const Gap(14),

              if (isAlreadyVoid)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.ban, size: 36, color: Color(0xFFEF4444)),
                        const Gap(10),
                        const Text(
                          'This bill has already been voided / cancelled.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const Gap(16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Segmented Tab Pill Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedTab = 0);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _selectedTab == 0
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.ban,
                                    size: 15,
                                    color: _selectedTab == 0 ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                  ),
                                  const Gap(6),
                                  Text(
                                    'Void Entire Bill',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _selectedTab == 0 ? FontWeight.w700 : FontWeight.w500,
                                      color: _selectedTab == 0 ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedTab = 1);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _selectedTab == 1
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.rotateCcw,
                                    size: 15,
                                    color: _selectedTab == 1 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                  ),
                                  const Gap(6),
                                  Text(
                                    'Return Items',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _selectedTab == 1 ? FontWeight.w700 : FontWeight.w500,
                                      color: _selectedTab == 1 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(14),

                // Tab Content Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _selectedTab == 0 ? _buildVoidTab(colors) : _buildReturnTab(colors),
                  ),
                ),

                // Bottom Sticky Action Buttons
                _buildBottomActions(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== TAB 1: VOID ENTIRE BILL ====================

  Widget _buildVoidTab(AppColorsExtension colors) {
    final isUdhar = widget.paymentMethod.contains('Credit') || widget.udharAmount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warning Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.alertTriangle, size: 18, color: Color(0xFFEF4444)),
              const Gap(10),
              Expanded(
                child: Text(
                  'Voiding will cancel this bill permanently. All ${widget.items.length} items will be restored to store inventory.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF991B1B),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(16),

        // Impact Summary Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildImpactRow(
                icon: LucideIcons.packagePlus,
                iconColor: const Color(0xFF16A34A),
                title: 'Inventory Restock',
                detail: '${widget.items.length} product(s) added back to stock',
              ),
              const Divider(height: 18, color: Color(0xFFE2E8F0)),
              _buildImpactRow(
                icon: isUdhar ? LucideIcons.bookOpen : LucideIcons.wallet,
                iconColor: isUdhar ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                title: isUdhar ? 'Udhar Khata Reversal' : 'Payment Refund',
                detail: isUdhar
                    ? 'Rs. ${widget.totalAmount.toInt()} cleared from ${widget.customerName}\'s balance'
                    : 'Rs. ${widget.totalAmount.toInt()} cash/payment refunded to customer',
              ),
            ],
          ),
        ),
        const Gap(18),

        // Reason Selector
        Text(
          'Reason for Cancellation',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.darkText,
          ),
        ),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _voidReasons.map((reason) {
            final isSelected = _voidReason == reason;
            return ChoiceChip(
              label: Text(reason),
              selected: isSelected,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                setState(() => _voidReason = reason);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
              side: BorderSide(
                color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF475569),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            );
          }).toList(),
        ),
        const Gap(14),

        // Optional Remarks
        Text(
          'Optional Notes',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.darkText,
          ),
        ),
        const Gap(6),
        TextField(
          controller: _voidNoteController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'e.g., Customer brought items back immediately...',
            hintStyle: TextStyle(fontSize: 12, color: colors.inputLabel),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
        const Gap(10),
      ],
    );
  }

  Widget _buildImpactRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const Gap(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const Gap(1),
              Text(
                detail,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== TAB 2: RETURN SPECIFIC ITEMS ====================

  Widget _buildReturnTab(AppColorsExtension colors) {
    final refundTotal = _calculatedRefundTotal;
    final isCustomerKnown = widget.customerName != 'Walk-in Customer' && widget.customerName.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instructions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select items to return:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.darkText,
              ),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                final allSelected = _selectedItems.every((it) => it);
                setState(() {
                  for (int i = 0; i < _selectedItems.length; i++) {
                    _selectedItems[i] = !allSelected;
                  }
                });
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                _selectedItems.every((it) => it) ? 'Deselect All' : 'Select All',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
              ),
            ),
          ],
        ),
        const Gap(8),

        // Items List with Stepper
        if (widget.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('No individual items on this bill. Use "Void Entire Bill".'),
          )
        else
          ...List.generate(widget.items.length, (idx) {
            final item = widget.items[idx];
            final isSelected = _selectedItems[idx];
            final returnQty = _returnQuantities[idx];
            final maxQty = item.quantity;
            final lineTotal = returnQty * item.rate;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2563EB).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Checkbox
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedItems[idx] = !_selectedItems[idx]);
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: isSelected
                              ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                      ),
                      const Gap(10),

                      // Name & Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.darkText,
                              ),
                            ),
                            const Gap(2),
                            Text(
                              'Bought: ${item.quantity.toInt()} ${item.unit} @ Rs. ${item.rate.toInt()}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.inputLabel,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Line Total
                      Text(
                        'Rs. ${lineTotal.toInt()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),

                  // Quantity Stepper (if selected)
                  if (isSelected) ...[
                    const Gap(10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Return Qty: ',
                          style: TextStyle(fontSize: 12, color: colors.inputLabel, fontWeight: FontWeight.w500),
                        ),
                        const Gap(6),
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.minus, size: 14),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                onPressed: returnQty > 1
                                    ? () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _returnQuantities[idx] -= 1);
                                      }
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '${returnQty.toInt()} ${item.unit}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colors.darkText,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.plus, size: 14),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                onPressed: returnQty < maxQty
                                    ? () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _returnQuantities[idx] += 1);
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        const Gap(14),

        // Restock Switch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.boxes, size: 16, color: Color(0xFF16A34A)),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Restock into Store Inventory',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      _restockReturnedItems ? 'Stock will be added back' : 'Items written off / damaged',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _restockReturnedItems,
                activeTrackColor: const Color(0xFF16A34A),
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _restockReturnedItems = val);
                },
              ),
            ],
          ),
        ),
        const Gap(14),

        // Return Reason Chips
        Text(
          'Reason for Return',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.darkText),
        ),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _returnReasons.map((r) {
            final isSelected = _returnReason == r;
            return ChoiceChip(
              label: Text(r),
              selected: isSelected,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                setState(() => _returnReason = r);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
              side: BorderSide(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            );
          }).toList(),
        ),
        const Gap(14),

        // Refund Settlement Method
        Text(
          'Refund Method',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.darkText),
        ),
        const Gap(8),
        Row(
          children: [
            _buildRefundMethodChip(
              label: 'Cash Refund',
              icon: LucideIcons.wallet,
              isSelected: _refundMethod == 'Cash',
              onTap: () => setState(() => _refundMethod = 'Cash'),
            ),
            const Gap(8),
            if (isCustomerKnown)
              _buildRefundMethodChip(
                label: 'Khata Credit',
                icon: LucideIcons.bookOpen,
                isSelected: _refundMethod == 'Credit (Udhar) Reversal',
                onTap: () => setState(() => _refundMethod = 'Credit (Udhar) Reversal'),
              ),
            const Gap(8),
            _buildRefundMethodChip(
              label: 'Store Credit',
              icon: LucideIcons.ticket,
              isSelected: _refundMethod == 'Store Credit',
              onTap: () => setState(() => _refundMethod = 'Store Credit'),
            ),
          ],
        ),
        const Gap(16),

        // Total Refund Calculation Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Refund Amount',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                  ),
                  Text(
                    '$_selectedItemsCount item(s) selected',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                  ),
                ],
              ),
              Text(
                'Rs. ${refundTotal.toInt()}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
        ),
        const Gap(10),
      ],
    );
  }

  Widget _buildRefundMethodChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB).withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
              const Gap(4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== BOTTOM STICKY ACTIONS ====================

  Widget _buildBottomActions(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isProcessing ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.darkText,
                ),
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : (_selectedTab == 0 ? _handleConfirmVoid : _handleConfirmReturn),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: _selectedTab == 0 ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedTab == 0 ? LucideIcons.ban : LucideIcons.rotateCcw,
                          size: 16,
                          color: Colors.white,
                        ),
                        const Gap(8),
                        Text(
                          _selectedTab == 0
                              ? 'Void Entire Bill'
                              : 'Process Return (Rs. ${_calculatedRefundTotal.toInt()})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
