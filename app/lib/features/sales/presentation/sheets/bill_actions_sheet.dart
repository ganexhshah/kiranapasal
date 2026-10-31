import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';

enum BillActionType { view, print, share, cancel }

/// Modal bottom sheet providing invoice/bill actions: view, reprint, share, return.
class BillActionsSheet extends StatelessWidget {
  const BillActionsSheet({
    super.key,
    required this.billNumber,
    required this.amount,
  });

  final String billNumber;
  final double amount;

  static Future<BillActionType?> show(
    BuildContext context, {
    required String billNumber,
    required double amount,
  }) {
    return showModalBottomSheet<BillActionType>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BillActionsSheet(billNumber: billNumber, amount: amount),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDestructive ? const Color(0xFFEF4444) : context.colors.darkText,
        ),
      ),
      trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bill #$billNumber',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.darkText),
                  ),
                  Text(
                    'Rs. ${amount.toInt()}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0066FF)),
                  ),
                ],
              ),
            ),
            const Gap(12),
            _actionTile(
              context: context,
              icon: LucideIcons.eye,
              iconColor: const Color(0xFF0066FF),
              title: 'View Full Invoice',
              onTap: () => Navigator.pop(context, BillActionType.view),
            ),
            _actionTile(
              context: context,
              icon: LucideIcons.printer,
              iconColor: const Color(0xFF16A34A),
              title: 'Print Thermal Receipt',
              onTap: () => Navigator.pop(context, BillActionType.print),
            ),
            _actionTile(
              context: context,
              icon: LucideIcons.share2,
              iconColor: const Color(0xFF7C3AED),
              title: 'Share via WhatsApp',
              onTap: () => Navigator.pop(context, BillActionType.share),
            ),
            const Gap(4),
            _actionTile(
              context: context,
              icon: LucideIcons.undo2,
              iconColor: const Color(0xFFEF4444),
              title: 'Cancel & Return Bill',
              isDestructive: true,
              onTap: () => Navigator.pop(context, BillActionType.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

