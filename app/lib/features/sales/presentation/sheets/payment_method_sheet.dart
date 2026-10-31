import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/sale_record.dart';

/// Modal bottom sheet allowing selection of the primary payment method.
class PaymentMethodSheet extends StatelessWidget {
  const PaymentMethodSheet({
    super.key,
    required this.totalAmount,
    this.selectedMethod = PaymentMethod.cash,
  });

  final double totalAmount;
  final PaymentMethod selectedMethod;

  static Future<PaymentMethod?> show(
    BuildContext context, {
    required double totalAmount,
    PaymentMethod selectedMethod = PaymentMethod.cash,
  }) {
    return showModalBottomSheet<PaymentMethod>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => PaymentMethodSheet(
        totalAmount: totalAmount,
        selectedMethod: selectedMethod,
      ),
    );
  }

  Widget _buildMethodTile({
    required BuildContext context,
    required PaymentMethod method,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final colors = context.colors;
    final isSelected = selectedMethod == method;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.pop(context, method),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: color, width: 1.5) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: color),
              ),
              const Gap(14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: colors.darkText,
                  ),
                ),
              ),
              if (isSelected)
                Icon(LucideIcons.check, size: 18, color: color)
              else
                Icon(LucideIcons.chevronRight, size: 16, color: colors.inputLabel),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isInt = totalAmount == totalAmount.roundToDouble();
    final amountStr = isInt ? totalAmount.toInt().toString() : totalAmount.toStringAsFixed(2);

    return SafeArea(
      child: Padding(
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

            // Header & Due Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.darkText,
                  ),
                ),
                Text(
                  'Rs. $amountStr',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ],
            ),
            const Gap(16),

            _buildMethodTile(
              context: context,
              method: PaymentMethod.cash,
              title: 'Cash Payment',
              icon: LucideIcons.banknote,
              color: const Color(0xFF16A34A),
            ),
            _buildMethodTile(
              context: context,
              method: PaymentMethod.qr,
              title: 'QR / Fonepay',
              icon: LucideIcons.qrCode,
              color: const Color(0xFF0066FF),
            ),
            _buildMethodTile(
              context: context,
              method: PaymentMethod.card,
              title: 'Card (POS Machine)',
              icon: LucideIcons.creditCard,
              color: const Color(0xFF7C3AED),
            ),
            _buildMethodTile(
              context: context,
              method: PaymentMethod.credit,
              title: 'Udhar (Store Credit)',
              icon: LucideIcons.bookOpen,
              color: const Color(0xFFEA580C),
            ),
            _buildMethodTile(
              context: context,
              method: PaymentMethod.split,
              title: 'Split (Cash + Udhar)',
              icon: LucideIcons.split,
              color: const Color(0xFFD97706),
            ),
          ],
        ),
      ),
    );
  }
}

