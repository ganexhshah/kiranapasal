import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';

enum POSActionType {
  scanBarcode,
  addNote,
  applyDiscount,
  clearCart,
}

/// Modal bottom sheet for POS overflow actions (Scan, Discount, Note, Clear Cart).
class POSActionsSheet extends StatelessWidget {
  const POSActionsSheet({super.key});

  static Future<POSActionType?> show(BuildContext context) {
    return showModalBottomSheet<POSActionType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const POSActionsSheet(),
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'POS Actions',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.darkText,
                ),
              ),
            ),
            const Gap(8),

            _actionTile(
              context: context,
              icon: LucideIcons.scanLine,
              iconColor: const Color(0xFF2563EB),
              title: 'Scan Barcode',
              onTap: () => Navigator.pop(context, POSActionType.scanBarcode),
            ),
            _actionTile(
              context: context,
              icon: LucideIcons.percent,
              iconColor: const Color(0xFF16A34A),
              title: 'Apply Discount',
              onTap: () => Navigator.pop(context, POSActionType.applyDiscount),
            ),
            _actionTile(
              context: context,
              icon: LucideIcons.fileText,
              iconColor: const Color(0xFF7C3AED),
              title: 'Add Sale Note',
              onTap: () => Navigator.pop(context, POSActionType.addNote),
            ),
            const Gap(4),
            _actionTile(
              context: context,
              icon: LucideIcons.trash2,
              iconColor: const Color(0xFFEF4444),
              title: 'Clear Cart',
              isDestructive: true,
              onTap: () => Navigator.pop(context, POSActionType.clearCart),
            ),
          ],
        ),
      ),
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
}

