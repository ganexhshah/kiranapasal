import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/product.dart';

/// Modal bottom sheet confirming product deletion with safeguards against removing items that have sales history.
class DeleteConfirmationSheet extends StatefulWidget {
  const DeleteConfirmationSheet({
    super.key,
    required this.product,
  });

  final Product product;

  static Future<bool> show(
    BuildContext context, {
    required Product product,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DeleteConfirmationSheet(product: product),
    );
    return result ?? false;
  }

  @override
  State<DeleteConfirmationSheet> createState() => _DeleteConfirmationSheetState();
}

class _DeleteConfirmationSheetState extends State<DeleteConfirmationSheet> {
  bool _confirmedRisk = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasSales = widget.product.hasSalesHistory;
    final canDelete = !hasSales || _confirmedRisk;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            const Gap(16),

            // Warning Icon
            Center(
              child: Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.alertTriangle,
                  size: 28,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
            const Gap(14),

            // Title
            Center(
              child: Text(
                'Delete Product?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.darkText,
                ),
              ),
            ),
            const Gap(6),

            // Product Name Highlight
            Center(
              child: Text(
                widget.product.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            const Gap(8),

            // Explanation
            Center(
              child: Text(
                'This will remove this product from active inventory. Unsold quantities will be written off.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.inputLabel,
                  height: 1.4,
                ),
              ),
            ),
            const Gap(16),

            // Protection Warning Banner for Sales History
            if (hasSales) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.shieldAlert, size: 20, color: Color(0xFFD97706)),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Protected: Sales History Detected',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          const Gap(2),
                          const Text(
                            'This product has recorded customer sales. Deleting it will affect past transaction summaries and accounting audits.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFB45309),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(12),

              // Confirmation Checkbox
              CheckboxListTile(
                value: _confirmedRisk,
                onChanged: (val) => setState(() => _confirmedRisk = val ?? false),
                title: const Text(
                  'I understand the impact on historical sales reports and confirm deletion.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFFEF4444),
              ),
              const Gap(14),
            ],

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: colors.inputBorder.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.darkText,
                      ),
                    ),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canDelete ? () => Navigator.pop(context, true) : null,
                    icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.white),
                    label: const Text(
                      'Delete Product',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      disabledBackgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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

