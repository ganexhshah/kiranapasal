import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme.dart';

class CashPaymentResult {
  final double cashReceived;
  final double changeReturned;

  const CashPaymentResult({
    required this.cashReceived,
    required this.changeReturned,
  });
}

/// Modal bottom sheet to calculate cash received and change returned.
class CashPaymentSheet extends StatefulWidget {
  const CashPaymentSheet({
    super.key,
    required this.totalAmount,
  });

  final double totalAmount;

  static Future<CashPaymentResult?> show(
    BuildContext context, {
    required double totalAmount,
  }) {
    return showModalBottomSheet<CashPaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CashPaymentSheet(totalAmount: totalAmount),
    );
  }

  @override
  State<CashPaymentSheet> createState() => _CashPaymentSheetState();
}

class _CashPaymentSheetState extends State<CashPaymentSheet> {
  late final TextEditingController _cashController;
  late double _cashReceived;

  @override
  void initState() {
    super.initState();
    _cashReceived = widget.totalAmount;
    _cashController = TextEditingController(text: _formatVal(_cashReceived));
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  String _formatVal(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toStringAsFixed(2);
  }

  double get _changeReturned {
    final diff = _cashReceived - widget.totalAmount;
    return diff > 0 ? diff : 0;
  }

  void _setCash(double val) {
    setState(() {
      _cashReceived = val;
      _cashController.text = _formatVal(_cashReceived);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEnough = _cashReceived >= widget.totalAmount;

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
                'Cash Payment',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.darkText,
                ),
              ),
              const Gap(16),

              // Total Due Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount Due',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.inputLabel,
                      ),
                    ),
                    Text(
                      'Rs. ${_formatVal(widget.totalAmount)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(14),

              // Cash Received Input
              Text(
                'Cash Received',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.inputLabel,
                ),
              ),
              const Gap(6),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                  ),
                ),
                child: TextField(
                  controller: _cashController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.darkText,
                  ),
                  decoration: const InputDecoration(
                    prefixText: 'Rs. ',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val) ?? 0;
                    setState(() => _cashReceived = parsed);
                  },
                ),
              ),
              const Gap(10),

              // Quick Cash Suggestion Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <double>{
                  widget.totalAmount,
                  ((widget.totalAmount / 50).ceil() * 50).toDouble(),
                  ((widget.totalAmount / 100).ceil() * 100).toDouble(),
                  ((widget.totalAmount / 500).ceil() * 500).toDouble(),
                  1000.0,
                }.where((amt) => amt >= widget.totalAmount).map((amt) {
                  return InkWell(
                    onTap: () => _setCash(amt),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Rs. ${_formatVal(amt)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.darkText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Gap(16),

              // Change Return Display
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isEnough ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEnough ? 'Change to Return' : 'Short by',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isEnough ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                      ),
                    ),
                    Text(
                      isEnough
                          ? 'Rs. ${_formatVal(_changeReturned)}'
                          : 'Rs. ${_formatVal(widget.totalAmount - _cashReceived)}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isEnough ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isEnough
                      ? () {
                          Navigator.pop(
                            context,
                            CashPaymentResult(
                              cashReceived: _cashReceived,
                              changeReturned: _changeReturned,
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    disabledBackgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Complete Cash Sale',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
