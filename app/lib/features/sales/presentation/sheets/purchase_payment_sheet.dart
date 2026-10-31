import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../domain/models/supplier.dart';

class PurchasePaymentResult {
  final double amount;
  final String method;
  final String reference;

  String get paymentMethod => method;
  String? get note => reference;

  const PurchasePaymentResult({
    required this.amount,
    required this.method,
    required this.reference,
  });
}

/// Modal bottom sheet to pay supplier outstanding invoices.
class PurchasePaymentSheet extends StatefulWidget {
  const PurchasePaymentSheet({
    super.key,
    required this.supplier,
  });

  final Supplier supplier;

  static Future<PurchasePaymentResult?> show(
    BuildContext context, {
    required Supplier supplier,
  }) {
    return showModalBottomSheet<PurchasePaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => PurchasePaymentSheet(supplier: supplier),
    );
  }

  @override
  State<PurchasePaymentSheet> createState() => _PurchasePaymentSheetState();
}

class _PurchasePaymentSheetState extends State<PurchasePaymentSheet> {
  late final TextEditingController _amountController;
  final _refController = TextEditingController();
  String _method = 'Bank Transfer';
  late double _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.supplier.outstandingBalance > 0 ? widget.supplier.outstandingBalance : 5000;
    _amountController = TextEditingController(text: _amount.toInt().toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
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
                    color: colors.inputBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(14),
              Text(
                'Supplier Payment',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.darkText),
              ),
              const Gap(14),

              // Supplier balance header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.supplier.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.darkText)),
                    Text('Due: Rs. ${widget.supplier.outstandingBalance.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
                  ],
                ),
              ),
              const Gap(14),

              AuthTextField(
                controller: _amountController,
                label: 'Payment Amount',
                prefixText: 'Rs. ',
                keyboardType: TextInputType.number,
                onChanged: (val) => setState(() => _amount = double.tryParse(val) ?? 0),
              ),
              const Gap(14),

              // Payment Method Chips
              Row(
                children: ['Bank Transfer', 'Cheque', 'Cash'].map((m) {
                  final isSelected = m == _method;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _method = m),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : colors.darkText,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Gap(14),

              AuthTextField(
                controller: _refController,
                label: 'Reference / Cheque # (Optional)',
                hintText: 'e.g. CHQ-99021',
              ),
              const Gap(16),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      PurchasePaymentResult(
                        amount: _amount,
                        method: _method,
                        reference: _refController.text.trim(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Record Supplier Payment', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

