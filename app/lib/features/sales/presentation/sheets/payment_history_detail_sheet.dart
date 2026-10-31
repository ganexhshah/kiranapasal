import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme.dart';

/// Modal bottom sheet showing details of a historic payment transaction.
class PaymentHistoryDetailSheet extends StatelessWidget {
  const PaymentHistoryDetailSheet({
    super.key,
    required this.receiptNumber,
    required this.customerName,
    required this.amount,
    required this.paymentMethod,
    required this.dateStr,
  });

  final String receiptNumber;
  final String customerName;
  final double amount;
  final String paymentMethod;
  final String dateStr;

  static Future<void> show(
    BuildContext context, {
    required String receiptNumber,
    required String customerName,
    required double amount,
    required String paymentMethod,
    required String dateStr,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => PaymentHistoryDetailSheet(
        receiptNumber: receiptNumber,
        customerName: customerName,
        amount: amount,
        paymentMethod: paymentMethod,
        dateStr: dateStr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
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
              'Payment Details',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.darkText),
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
                  _row('Receipt Number', receiptNumber, colors),
                  const Gap(8),
                  _row('Customer', customerName, colors),
                  const Gap(8),
                  _row('Payment Method', paymentMethod, colors),
                  const Gap(8),
                  _row('Date & Time', dateStr, colors),
                  const Gap(10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                      Text('Rs. ${amount.toInt()}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, AppColorsExtension colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: colors.inputLabel)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.darkText)),
      ],
    );
  }
}

