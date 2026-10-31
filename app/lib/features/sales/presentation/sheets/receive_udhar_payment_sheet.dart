import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../domain/models/customer.dart';

class UdharPaymentResult {
  final double amount;
  final String method;
  final String note;

  String get paymentMethod => method;

  const UdharPaymentResult({
    required this.amount,
    required this.method,
    required this.note,
  });
}

/// Modal bottom sheet to record a customer Udhar balance repayment.
class ReceiveUdharPaymentSheet extends StatefulWidget {
  const ReceiveUdharPaymentSheet({
    super.key,
    required this.customer,
  });

  final Customer customer;

  static Future<UdharPaymentResult?> show(
    BuildContext context, {
    required Customer customer,
  }) {
    return showModalBottomSheet<UdharPaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ReceiveUdharPaymentSheet(customer: customer),
    );
  }

  @override
  State<ReceiveUdharPaymentSheet> createState() => _ReceiveUdharPaymentSheetState();
}

class _ReceiveUdharPaymentSheetState extends State<ReceiveUdharPaymentSheet> {
  late final TextEditingController _amountController;
  final _noteController = TextEditingController();
  String _paymentMethod = 'Cash';
  late double _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.customer.udharBalance;
    _amountController = TextEditingController(text: _amount.toInt().toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _newBalance => (widget.customer.udharBalance - _amount).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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

              Text(
                'Receive Udhar Payment',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.darkText),
              ),
              const Gap(14),

              // Customer & Current Balance
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.customer.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.darkText)),
                        Text('Current Udhar: Rs. ${widget.customer.udharBalance.toInt()}', style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _amount = widget.customer.udharBalance;
                          _amountController.text = _amount.toInt().toString();
                        });
                      },
                      child: const Text('Pay Full', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0066FF))),
                    ),
                  ],
                ),
              ),
              const Gap(14),

              AuthTextField(
                controller: _amountController,
                label: 'Amount Received',
                prefixText: 'Rs. ',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) {
                  final parsed = double.tryParse(val) ?? 0;
                  setState(() => _amount = parsed);
                },
              ),
              const Gap(14),

              // Payment Method Choice Chips
              Row(
                children: ['Cash', 'Fonepay QR', 'Bank Transfer'].map((m) {
                  final isSelected = m == _paymentMethod;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _paymentMethod = m),
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

              // Updated Balance Preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remaining Balance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                    Text('Rs. ${_newBalance.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                  ],
                ),
              ),
              const Gap(16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      UdharPaymentResult(
                        amount: _amount,
                        method: _paymentMethod,
                        note: _noteController.text.trim(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

