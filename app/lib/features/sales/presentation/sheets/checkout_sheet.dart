import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/theme/theme.dart';
import '../../../products/domain/models/product.dart';
import '../../../products/presentation/widgets/product_thumbnail.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/sale_record.dart';
import 'add_sale_note_sheet.dart';
import 'add_tax_sheet.dart';
import 'add_to_sale_sheet.dart';
import 'additional_charges_sheet.dart';
import 'apply_discount_sheet.dart';
import 'cash_payment_sheet.dart';
import 'clear_cart_confirmation_sheet.dart';
import 'credit_sale_confirmation_sheet.dart';
import 'edit_cart_item_sheet.dart';
import 'partial_payment_sheet.dart';
import 'payment_method_sheet.dart';
import 'sale_success_sheet.dart';
import 'select_customer_sheet.dart';

/// Modal bottom sheet reviewing the active cart, customer, discount, taxes, charges, and launching payments.
class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({
    super.key,
    required this.initialItems,
    this.initialCustomer = Customer.walkIn,
    this.allProducts = const [],
    this.initialDiscount = 0,
    this.initialNote = '',
  });

  final List<CartItem> initialItems;
  final Customer initialCustomer;
  final List<Product> allProducts;

  /// Discount already chosen from the POS actions menu, applied when the sheet
  /// opens so it is visible in the totals instead of being silently dropped.
  final double initialDiscount;
  final String initialNote;

  static Future<bool?> show(
    BuildContext context, {
    required List<CartItem> items,
    Customer customer = Customer.walkIn,
    List<Product> allProducts = const [],
    double initialDiscount = 0,
    String initialNote = '',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CheckoutSheet(
        initialItems: items,
        initialCustomer: customer,
        allProducts: allProducts,
        initialDiscount: initialDiscount,
        initialNote: initialNote,
      ),
    );
  }

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  late List<CartItem> _items;
  late Customer _customer;
  double _discountAmount = 0;
  double _taxAmount = 0;
  double _taxPercent = 0;
  String _taxLabel = '';
  double _additionalCharges = 0;
  String _additionalChargesTitle = '';
  String _saleNote = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
    _customer = widget.initialCustomer;
    _saleNote = widget.initialNote;
    if (widget.initialDiscount > 0) {
      final subtotal = widget.initialItems.fold<double>(0, (sum, it) => sum + it.totalPrice);
      _discountAmount = widget.initialDiscount.clamp(0, subtotal).toDouble();
    }
  }

  double get _subtotal => _items.fold(0, (sum, it) => sum + it.totalPrice);
  double get _taxableBase => (_subtotal - _discountAmount).clamp(0, double.infinity);
  double get _effectiveTax => _taxPercent > 0 ? (_taxableBase * _taxPercent / 100) : _taxAmount;
  double get _finalTotal => (_taxableBase + _effectiveTax + _additionalCharges).clamp(0, double.infinity);

  String _formatAmount(double amount) {
    final isInt = amount == amount.roundToDouble();
    return isInt ? amount.toInt().toString() : amount.toStringAsFixed(2);
  }

  Future<void> _selectCustomer() async {
    final cust = await SelectCustomerSheet.show(
      context,
      selectedCustomerId: _customer.id,
    );
    if (cust != null && mounted) {
      setState(() => _customer = cust);
    }
  }

  Future<void> _confirmClearCart() async {
    final confirmed = await ClearCartConfirmationSheet.show(
      context,
      itemCount: _items.length,
    );
    if (confirmed && mounted) {
      setState(() => _items.clear());
      widget.initialItems.clear();
      Navigator.pop(context, false);
    }
  }

  Future<void> _addNewItem() async {
    if (widget.allProducts.isEmpty) {
      Navigator.pop(context, false);
      return;
    }

    final product = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _QuickProductPickerSheet(products: widget.allProducts),
    );

    if (product != null && mounted) {
      final item = await AddToSaleSheet.show(context, product: product);
      if (item != null && mounted) {
        setState(() {
          final idx = _items.indexWhere(
            (it) => it.product.id == item.product.id && it.unit == item.unit,
          );
          if (idx >= 0) {
            final exist = _items[idx];
            _items[idx] = exist.copyWith(quantity: exist.quantity + item.quantity);
          } else {
            _items.add(item);
          }
          if (_taxPercent > 0) {
            _taxAmount = _taxableBase * _taxPercent / 100;
          }
        });
      }
    }
  }

  Future<void> _applyDiscount() async {
    final res = await ApplyDiscountSheet.show(context, subtotal: _subtotal);
    if (res != null && mounted) {
      setState(() {
        _discountAmount = res.calculatedAmount;
        if (_taxPercent > 0) {
          _taxAmount = (_subtotal - _discountAmount).clamp(0, double.infinity) * _taxPercent / 100;
        }
      });
    }
  }

  Future<void> _applyTax() async {
    final res = await AddTaxSheet.show(
      context,
      taxableBase: _taxableBase,
      initialRate: _taxPercent > 0 ? _taxPercent : 13.0,
    );
    if (res != null && mounted) {
      setState(() {
        _taxPercent = res.ratePercent;
        _taxAmount = res.calculatedAmount;
        _taxLabel = res.label;
      });
    }
  }

  Future<void> _applyAdditionalCharges() async {
    final res = await AdditionalChargesSheet.show(
      context,
      initialTitle: _additionalChargesTitle.isNotEmpty ? _additionalChargesTitle : 'Delivery Charge',
      initialAmount: _additionalCharges > 0 ? _additionalCharges : 50.0,
    );
    if (res != null && mounted) {
      setState(() {
        _additionalCharges = res.amount;
        _additionalChargesTitle = res.title;
      });
    }
  }

  Future<void> _addNote() async {
    final note = await AddSaleNoteSheet.show(context, initialNote: _saleNote);
    if (note != null && mounted) {
      setState(() => _saleNote = note);
    }
  }

  Future<void> _editItem(int index) async {
    final item = _items[index];
    final updated = await EditCartItemSheet.show(context, item: item);
    if (updated != null && mounted) {
      setState(() {
        if (updated.quantity <= 0) {
          _items.removeAt(index);
        } else {
          _items[index] = updated;
        }
        if (_taxPercent > 0) {
          _taxAmount = _taxableBase * _taxPercent / 100;
        }
      });
      if (_items.isEmpty) {
        widget.initialItems.clear();
        Navigator.pop(context, false);
      }
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      if (_taxPercent > 0) {
        _taxAmount = _taxableBase * _taxPercent / 100;
      }
    });
    if (_items.isEmpty) {
      widget.initialItems.clear();
      Navigator.pop(context, false);
    }
  }

  void _showTotalBreakdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.inputBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(14),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.info, size: 16, color: Color(0xFF0066FF)),
                  ),
                  const Gap(10),
                  Text(
                    'Total Amount Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.colors.darkText,
                    ),
                  ),
                ],
              ),
              const Gap(14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _breakdownRow('Items Subtotal (${_items.length})', 'Rs. ${_formatAmount(_subtotal)}'),
                    if (_discountAmount > 0) ...[
                      const Gap(8),
                      _breakdownRow('Discount Savings', '-Rs. ${_formatAmount(_discountAmount)}', isGreen: true),
                    ],
                    if (_effectiveTax > 0) ...[
                      const Gap(8),
                      _breakdownRow(
                        _taxLabel.isNotEmpty ? _taxLabel : 'Tax / VAT (${_formatAmount(_taxPercent)}%)',
                        '+Rs. ${_formatAmount(_effectiveTax)}',
                        isBlue: true,
                      ),
                    ],
                    if (_additionalCharges > 0) ...[
                      const Gap(8),
                      _breakdownRow(
                        _additionalChargesTitle.isNotEmpty ? _additionalChargesTitle : 'Additional Charges',
                        '+Rs. ${_formatAmount(_additionalCharges)}',
                        isAmber: true,
                      ),
                    ],
                    const Gap(10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Payable',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Rs. ${_formatAmount(_finalTotal)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0066FF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {bool isGreen = false, bool isBlue = false, bool isAmber = false}) {
    Color color = context.colors.darkText;
    if (isGreen) color = const Color(0xFF16A34A);
    if (isBlue) color = const Color(0xFF0066FF);
    if (isAmber) color = const Color(0xFFD97706);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: context.colors.inputLabel)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Future<void> _proceedToPayment() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _runPaymentFlow();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _runPaymentFlow() async {
    final method = await PaymentMethodSheet.show(
      context,
      totalAmount: _finalTotal,
    );
    if (method == null || !mounted) return;

    double cashReceived = _finalTotal;
    double changeReturned = 0;
    double udharAmount = 0;

    if (method == PaymentMethod.cash) {
      final cashResult = await CashPaymentSheet.show(
        context,
        totalAmount: _finalTotal,
      );
      if (cashResult == null || !mounted) return;
      cashReceived = cashResult.cashReceived;
      changeReturned = cashResult.changeReturned;
    } else if (method == PaymentMethod.credit) {
      if (_customer.isWalkIn) {
        // Prompt to select regular customer for udhar
        final cust = await SelectCustomerSheet.show(context);
        if (!mounted) return;
        if (cust == null || cust.isWalkIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a customer for Udhar (store credit)')),
          );
          return;
        }
        setState(() => _customer = cust);
      }
      final confirmed = await CreditSaleConfirmationSheet.show(
        context,
        customer: _customer,
        amount: _finalTotal,
      );
      if (!confirmed || !mounted) return;
      cashReceived = 0;
      udharAmount = _finalTotal;
    } else if (method == PaymentMethod.split) {
      if (_customer.isWalkIn) {
        final cust = await SelectCustomerSheet.show(context);
        if (!mounted) return;
        if (cust == null || cust.isWalkIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a customer for the Udhar portion')),
          );
          return;
        }
        setState(() => _customer = cust);
      }
      final splitResult = await PartialPaymentSheet.show(
        context,
        totalAmount: _finalTotal,
        customer: _customer,
      );
      if (splitResult == null || !mounted) return;
      cashReceived = splitResult.paidAmount;
      udharAmount = splitResult.remainingUdhar;
      changeReturned = 0;
    }

    final methodStr = method == PaymentMethod.cash
        ? 'Cash'
        : (method == PaymentMethod.credit
            ? 'Credit (Udhar)'
            : (method == PaymentMethod.split
                ? 'Split (Cash + Udhar)'
                : (method == PaymentMethod.qr ? 'Fonepay QR' : 'Card')));

    final bill = await AppDataRepository.instance.completeSale(
      cartItems: _items,
      customer: _customer,
      subtotal: _subtotal,
      discount: _discountAmount,
      taxAmount: _effectiveTax,
      additionalCharges: _additionalCharges,
      totalAmount: _finalTotal,
      paymentMethod: methodStr,
      cashReceived: cashReceived,
      changeReturned: changeReturned,
      udharAmount: udharAmount,
      note: _saleNote,
    );

    final saleRecord = SaleRecord(
      id: bill.billNumber,
      receiptNumber: bill.billNumber,
      items: List.from(_items),
      customer: _customer,
      subtotal: _subtotal,
      discountAmount: _discountAmount,
      taxAmount: _effectiveTax,
      additionalCharges: _additionalCharges,
      totalAmount: _finalTotal,
      paymentMethod: method,
      cashReceived: cashReceived,
      changeReturned: changeReturned,
      udharAmount: udharAmount,
      note: _saleNote,
      timestamp: DateTime.now(),
    );

    if (mounted) {
      Navigator.pop(context, true); // Pop checkout sheet
      SaleSuccessSheet.show(context, sale: saleRecord);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
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

            // Top Header: Checkout Title, Customer Pill, Trash (Delete Cart) Button
            Row(
              children: [
                Text(
                  'Checkout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.darkText,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _selectCustomer,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _customer.isWalkIn ? LucideIcons.userCheck : LucideIcons.user,
                          size: 14,
                          color: const Color(0xFF0066FF),
                        ),
                        const Gap(6),
                        Text(
                          _customer.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0066FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(8),
                IconButton(
                  onPressed: _confirmClearCart,
                  icon: const Icon(LucideIcons.trash2, size: 18, color: Color(0xFFEF4444)),
                  tooltip: 'Clear Cart',
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const Gap(12),

            // Items List Title & "+ Add Item" Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items (${_items.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.inputLabel,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addNewItem,
                  icon: const Icon(LucideIcons.plus, size: 14, color: Color(0xFF0066FF)),
                  label: const Text(
                    'Add Item',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const Gap(6),

            // Cart Items Scrollable List
            Expanded(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (ctx, i) => const Gap(8),
                itemBuilder: (ctx, i) {
                  final it = _items[i];
                  return InkWell(
                    onTap: () => _editItem(i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          ProductThumbnail(
                            imageUrl: it.product.imageUrl,
                            category: it.product.category,
                            size: 38,
                          ),
                          const Gap(10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it.product.name,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: colors.darkText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Gap(2),
                                Text(
                                  '${it.formattedQuantity} @ Rs. ${_formatAmount(it.unitPrice)}',
                                  style: TextStyle(fontSize: 11.5, color: colors.inputLabel),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            it.formattedTotal,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0066FF),
                            ),
                          ),
                          const Gap(8),
                          InkWell(
                            onTap: () => _editItem(i),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(LucideIcons.pencil, size: 14, color: colors.inputLabel),
                            ),
                          ),
                          const Gap(2),
                          InkWell(
                            onTap: () => _removeItem(i),
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(LucideIcons.trash2, size: 14, color: Color(0xFFEF4444)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Gap(12),

            // Quick Actions: Discount & Tax, Charges & Note Pills
            Row(
              children: [
                // Discount Pill
                Expanded(
                  child: InkWell(
                    onTap: _applyDiscount,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _discountAmount > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.percent,
                            size: 13,
                            color: _discountAmount > 0 ? const Color(0xFF16A34A) : colors.darkText,
                          ),
                          const Gap(6),
                          Flexible(
                            child: Text(
                              _discountAmount > 0
                                  ? '-Rs. ${_formatAmount(_discountAmount)}'
                                  : 'Discount',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _discountAmount > 0 ? const Color(0xFF16A34A) : colors.darkText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(8),
                // Tax / VAT Pill
                Expanded(
                  child: InkWell(
                    onTap: _applyTax,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _effectiveTax > 0 ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.receipt,
                            size: 13,
                            color: _effectiveTax > 0 ? const Color(0xFF0066FF) : colors.darkText,
                          ),
                          const Gap(6),
                          Flexible(
                            child: Text(
                              _effectiveTax > 0
                                  ? '+Rs. ${_formatAmount(_effectiveTax)} (${_taxLabel.isNotEmpty ? _taxLabel : "${_formatAmount(_taxPercent)}%"})'
                                  : 'Add Tax / VAT',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _effectiveTax > 0 ? const Color(0xFF0066FF) : colors.darkText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(8),
            Row(
              children: [
                // Additional Charges Pill
                Expanded(
                  child: InkWell(
                    onTap: _applyAdditionalCharges,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _additionalCharges > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.plusCircle,
                            size: 13,
                            color: _additionalCharges > 0 ? const Color(0xFFD97706) : colors.darkText,
                          ),
                          const Gap(6),
                          Flexible(
                            child: Text(
                              _additionalCharges > 0
                                  ? '+Rs. ${_formatAmount(_additionalCharges)}'
                                  : 'Add Charges',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _additionalCharges > 0 ? const Color(0xFFD97706) : colors.darkText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(8),
                // Note Pill
                Expanded(
                  child: InkWell(
                    onTap: _addNote,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _saleNote.isNotEmpty ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.fileText,
                            size: 13,
                            color: _saleNote.isNotEmpty ? const Color(0xFF0066FF) : colors.darkText,
                          ),
                          const Gap(6),
                          Flexible(
                            child: Text(
                              _saleNote.isNotEmpty ? 'Note Attached' : 'Add Note',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _saleNote.isNotEmpty ? const Color(0xFF0066FF) : colors.darkText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(14),

            // Summary Totals & Proceed Action
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total Payable',
                            style: TextStyle(fontSize: 11.5, color: colors.inputLabel),
                          ),
                          const Gap(4),
                          InkWell(
                            onTap: _showTotalBreakdown,
                            borderRadius: BorderRadius.circular(10),
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(
                                LucideIcons.info,
                                size: 14,
                                color: Color(0xFF0066FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Rs. ${_formatAmount(_finalTotal)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0066FF),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _proceedToPayment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Processing…' : 'Proceed to Payment',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

/// Quick product selection modal embedded in checkout sheet.
class _QuickProductPickerSheet extends StatefulWidget {
  const _QuickProductPickerSheet({required this.products});
  final List<Product> products;

  @override
  State<_QuickProductPickerSheet> createState() => _QuickProductPickerSheetState();
}

class _QuickProductPickerSheetState extends State<_QuickProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = widget.products.where((p) {
      return _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
          p.sku.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(
              'Add Product to Sale',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.darkText),
            ),
            const Gap(10),
            Container(
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
              child: TextField(
                onChanged: (val) => setState(() => _query = val.trim()),
                style: TextStyle(fontSize: 13.5, color: colors.darkText),
                decoration: InputDecoration(
                  hintText: 'Search product...',
                  prefixIcon: Icon(LucideIcons.search, size: 16, color: colors.inputLabel),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (ctx, i) => const Gap(8),
                itemBuilder: (ctx, i) {
                  final p = filtered[i];
                  return InkWell(
                    onTap: () => Navigator.pop(context, p),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          ProductThumbnail(imageUrl: p.imageUrl, category: p.category, size: 36),
                          const Gap(10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.darkText)),
                                Text('${p.formattedPrice} / ${p.priceUnit} • Stock: ${p.formattedStock}', style: TextStyle(fontSize: 11.5, color: colors.inputLabel)),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.plus, size: 18, color: Color(0xFF0066FF)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
