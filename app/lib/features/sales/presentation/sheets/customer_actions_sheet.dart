import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/customer.dart';

enum CustomerActionType {
  viewProfile,
  editDetails,
  viewLedger,
  recordPayment,
  setCreditLimit,
}

/// Modal bottom sheet for quick customer actions: record payment, ledger, limit.
class CustomerActionsSheet extends StatelessWidget {
  const CustomerActionsSheet({
    super.key,
    required this.customer,
  });

  final Customer customer;

  static Future<CustomerActionType?> show(
    BuildContext context, {
    required Customer customer,
  }) {
    return showModalBottomSheet<CustomerActionType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CustomerActionsSheet(customer: customer),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
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
          color: context.colors.darkText,
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

            // Customer Summary Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.darkText),
                        ),
                        Text(
                          'Udhar Balance: Rs. ${customer.udharBalance.toInt()}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),

            _actionTile(
              context: context,
              icon: LucideIcons.wallet,
              iconColor: const Color(0xFF16A34A),
              title: 'Receive Payment',
              onTap: () => Navigator.pop(context, CustomerActionType.recordPayment),
            ),
            _actionTile(
              context: context,
              icon: LucideIcons.bookOpen,
              iconColor: const Color(0xFF2563EB),
              title: 'View Udhar Ledger',
              onTap: () => Navigator.pop(context, CustomerActionType.viewLedger),
            ),
            _actionTile(
              context: context,
              icon: LucideIcons.shieldCheck,
              iconColor: const Color(0xFF7C3AED),
              title: 'Customer Credit Limit',
              onTap: () => Navigator.pop(context, CustomerActionType.setCreditLimit),
            ),
            _actionTile(
              context: context,
              icon: LucideIcons.pencil,
              iconColor: const Color(0xFF0284C7),
              title: 'Edit Customer Details',
              onTap: () => Navigator.pop(context, CustomerActionType.editDetails),
            ),
          ],
        ),
      ),
    );
  }
}

