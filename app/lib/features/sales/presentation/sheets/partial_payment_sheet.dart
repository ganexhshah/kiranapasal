import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/customer.dart';

class PartialPaymentResult {
  final double paidAmount;
  final double remainingUdhar;

  const PartialPaymentResult({
    required this.paidAmount,
    required this.remainingUdhar,
  });
}

/// Modal bottom sheet to split a transaction into an immediate cash payment and remaining Udhar (store credit).
class PartialPaymentSheet extends StatefulWidget {
  const PartialPaymentSheet({
    super.key,
    required this.totalAmount,
    required this.customer,
  });

  final double totalAmount;
  final Customer customer;

  static Future<PartialPaymentResult?> show(
    BuildContext context, {
    required double totalAmount,
    required Customer customer,
  }) {
    return showModalBottomSheet<PartialPaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => PartialPaymentSheet(
        totalAmount: totalAmount,
        customer: customer,
      ),
    );
  }

  @override
  State<PartialPaymentSheet> createState() => _PartialPaymentSheetState();
}

class _PartialPaymentSheetState extends State<PartialPaymentSheet> {
  late final TextEditingController _paidController;
  late double _paidAmount;

  @override
  void initState() {
    super.initState();
    _paidAmount = (widget.totalAmount / 2).roundToDouble();
    _paidController = TextEditingController(text: _paidAmount.toInt().toString());
  }

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  double get _remainingUdhar =>
      (widget.totalAmount - _paidAmount).clamp(0.0, widget.totalAmount);

  Widget _presetChip(String label, double fraction) {
    final amt = (widget.totalAmount * fraction).roundToDouble();
    final isSelected = (_paidAmount - amt).abs() < 1;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _paidAmount = amt;
            _paidController.text = amt.toInt().toString();
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                'Split Payment (Cash + Udhar)',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.darkText,
                ),
              ),
              const Gap(14),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Customer', style: TextStyle(fontSize: 12.5, color: colors.inputLabel)),
                        Text(widget.customer.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.darkText)),
                      ],
                    ),
                    const Gap(6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Bill Amount', style: TextStyle(fontSize: 12.5, color: colors.inputLabel)),
                        Text('Rs. ${widget.totalAmount.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(14),

              // Preset Percentage Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount Paid Now (Cash)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.inputLabel),
                  ),
                  Text(
                    'Total: Rs. ${widget.totalAmount.toInt()}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
              const Gap(8),

              Row(
                children: [
                  _presetChip('50% (Half)', 0.5),
                  const Gap(8),
                  _presetChip('25%', 0.25),
                  const Gap(8),
                  _presetChip('75%', 0.75),
                ],
              ),
              const Gap(10),

              // Paid Now Input
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _paidController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.darkText),
                  decoration: const InputDecoration(
                    prefixText: 'Rs. ',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val) ?? 0;
                    setState(() => _paidAmount = parsed.clamp(0.0, widget.totalAmount));
                  },
                ),
              ),
              const Gap(14),

              // Remaining Balance Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Remaining Udhar Balance',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                    ),
                    Text(
                      'Rs. ${_remainingUdhar.toInt()}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ),
              const Gap(16),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      PartialPaymentResult(
                        paidAmount: _paidAmount,
                        remainingUdhar: _remainingUdhar,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Confirm Split Payment', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
