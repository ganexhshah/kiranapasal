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

/// Modal bottom sheet allowing shopkeepers to void a bill or return specific items.
/// Styled according to pasal365's clean white theme with zero neon tints and no clutter.
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

  static const List<String> _voidReasons = [
    'Customer cancelled',
    'Wrong items / price',
    'Duplicate bill',
    'Payment failed',
    'Other',
  ];

  // Return Tab State
  late List<bool> _selectedItems;
  late List<double> _returnQuantities;
  bool _restockReturnedItems = true;
  String _returnReason = 'Customer return';
  late String _refundMethod;

  static const List<String> _returnReasons = [
    'Customer return',
    'Damaged / defective',
    'Expired product',
    'Wrong item',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialIsReturn ? 1 : 0;

    _selectedItems = List<bool>.filled(widget.items.length, true);
    _returnQuantities = widget.items.map((it) => it.quantity).toList();

    if (widget.paymentMethod.contains('Credit') || widget.udharAmount > 0) {
      _refundMethod = 'Credit (Udhar) Reversal';
    } else {
      _refundMethod = 'Cash';
    }
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

    try {
      final success = await AppDataRepository.instance.voidBill(
        widget.billNumber,
        _voidReason,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (success) {
        Navigator.pop(context, CancelReturnActionType.voided);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill #${widget.billNumber} voided'),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to void bill. Please try again.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFDC2626),
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
          backgroundColor: Color(0xFFDC2626),
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
            content: Text('Return processed: Rs. ${refundAmount.toInt()} refunded'),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFDC2626),
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
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              const Gap(10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(12),

              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        LucideIcons.receipt,
                        size: 18,
                        color: colors.darkText,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bill #${widget.billNumber}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.darkText,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            '${widget.customerName} • Rs. ${widget.totalAmount.toInt()} (${widget.paymentMethod})',
                            style: TextStyle(
                              fontSize: 12,
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
              const Gap(12),

              if (isAlreadyVoid)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.info, size: 18, color: Color(0xFF64748B)),
                            const Gap(10),
                            Expanded(
                              child: Text(
                                'This bill has already been voided.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.darkText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Close', style: TextStyle(color: colors.darkText)),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // Segmented Pill Tab Switcher
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
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
                              duration: const Duration(milliseconds: 150),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                                border: _selectedTab == 0
                                    ? Border.all(color: const Color(0xFFCBD5E1), width: 0.8)
                                    : null,
                              ),
                              child: Text(
                                'Void Entire Bill',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedTab == 0 ? FontWeight.w700 : FontWeight.w500,
                                  color: _selectedTab == 0 ? colors.darkText : colors.inputLabel,
                                ),
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
                              duration: const Duration(milliseconds: 150),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                                border: _selectedTab == 1
                                    ? Border.all(color: const Color(0xFFCBD5E1), width: 0.8)
                                    : null,
                              ),
                              child: Text(
                                'Return Items',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedTab == 1 ? FontWeight.w700 : FontWeight.w500,
                                  color: _selectedTab == 1 ? colors.darkText : colors.inputLabel,
                                ),
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

                // Bottom Action Buttons
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bill Amount',
                    style: TextStyle(fontSize: 13, color: colors.inputLabel),
                  ),
                  Text(
                    'Rs. ${widget.totalAmount.toInt()}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.darkText),
                  ),
                ],
              ),
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items to Restock',
                    style: TextStyle(fontSize: 13, color: colors.inputLabel),
                  ),
                  Text(
                    '${widget.items.length} items',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.darkText),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Gap(16),

        // Reason Selector
        Text(
          'Reason',
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
              selectedColor: const Color(0xFF0F172A),
              side: BorderSide(
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            );
          }).toList(),
        ),
        const Gap(14),
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
        // Items List
        if (widget.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'No items on this bill. Use "Void Entire Bill".',
              style: TextStyle(fontSize: 12, color: colors.inputLabel),
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
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
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: isSelected
                              ? const Icon(LucideIcons.check, size: 13, color: Colors.white)
                              : null,
                        ),
                      ),
                      const Gap(10),

                      // Item Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.darkText,
                              ),
                            ),
                            const Gap(1),
                            Text(
                              '${item.quantity.toInt()} ${item.unit} • Rs. ${item.rate.toInt()}/${item.unit}',
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? colors.darkText : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),

                  // Quantity Stepper (when checked)
                  if (isSelected) ...[
                    const Gap(8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Return:',
                          style: TextStyle(fontSize: 12, color: colors.inputLabel),
                        ),
                        const Gap(8),
                        Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.minus, size: 13),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                onPressed: returnQty > 1
                                    ? () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _returnQuantities[idx] -= 1);
                                      }
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '${returnQty.toInt()} ${item.unit}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.darkText,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.plus, size: 13),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
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
        const Gap(10),

        // Restock Switch Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Restock items to inventory',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.darkText),
              ),
              Switch.adaptive(
                value: _restockReturnedItems,
                activeTrackColor: const Color(0xFF2563EB),
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
          'Reason',
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
              selectedColor: const Color(0xFF0F172A),
              side: BorderSide(
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            );
          }).toList(),
        ),
        const Gap(14),

        // Refund Method
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
            if (isCustomerKnown) ...[
              _buildRefundMethodChip(
                label: 'Khata Credit',
                icon: LucideIcons.bookOpen,
                isSelected: _refundMethod == 'Credit (Udhar) Reversal',
                onTap: () => setState(() => _refundMethod = 'Credit (Udhar) Reversal'),
              ),
              const Gap(8),
            ],
            _buildRefundMethodChip(
              label: 'Store Credit',
              icon: LucideIcons.ticket,
              isSelected: _refundMethod == 'Store Credit',
              onTap: () => setState(() => _refundMethod = 'Store Credit'),
            ),
          ],
        ),
        const Gap(16),

        // Clean Summary Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Refund',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.darkText),
              ),
              Text(
                'Rs. ${refundTotal.toInt()}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.darkText,
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
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
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          const Gap(10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : (_selectedTab == 0 ? _handleConfirmVoid : _handleConfirmReturn),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                backgroundColor: _selectedTab == 0 ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _selectedTab == 0
                          ? 'Void Bill'
                          : 'Process Return (Rs. ${_calculatedRefundTotal.toInt()})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
