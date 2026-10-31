import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/product.dart';
import '../widgets/product_thumbnail.dart';

enum ProductActionType {
  edit,
  printBarcode,
  adjustStock,
  manageUnits,
  stockHistory,
  lowStockAlert,
  expiryDate,
  delete,
}

/// Modal bottom sheet surfacing all primary actions available on a product item.
class ProductActionsSheet extends StatelessWidget {
  const ProductActionsSheet({
    super.key,
    required this.product,
  });

  final Product product;

  static Future<ProductActionType?> show(
    BuildContext context, {
    required Product product,
  }) {
    return showModalBottomSheet<ProductActionType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ProductActionsSheet(product: product),
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

            // Product Header Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ProductThumbnail(
                    imageUrl: product.imageUrl,
                    category: product.category,
                    size: 40,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(2),
                        Text(
                          '${product.category} • ${product.formattedStock}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.inputLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(8),

            // Action Items - Clean and Lineless
            _actionTile(
              context: context,
              icon: LucideIcons.pencil,
              iconColor: const Color(0xFF2563EB),
              title: 'Edit Product',
              onTap: () => Navigator.pop(context, ProductActionType.edit),
            ),
            _actionTile(
              context: context,
              icon: LucideIcons.printer,
              iconColor: const Color(0xFF0284C7),
              title: 'Print Barcode Labels',
              onTap: () => Navigator.pop(context, ProductActionType.printBarcode),
            ),
            _actionTile(
              context: context,
              icon: LucideIcons.packagePlus,
              iconColor: const Color(0xFF16A34A),
              title: 'Adjust Stock',
              onTap: () => Navigator.pop(context, ProductActionType.adjustStock),
            ),
            _actionTile(
              context: context,
              icon: LucideIcons.scale,
              iconColor: const Color(0xFF7C3AED),
              title: 'Manage Selling Units',
              onTap: () => Navigator.pop(context, ProductActionType.manageUnits),
            ),
            _actionTile(
              context: context,
              icon: LucideIcons.history,
              iconColor: const Color(0xFF0284C7),
              title: 'View Stock History',
              onTap: () => Navigator.pop(context, ProductActionType.stockHistory),
            ),
            _actionTile(
              context: context,
              icon: LucideIcons.bell,
              iconColor: const Color(0xFFEA580C),
              title: 'Low Stock Alert',
              onTap: () => Navigator.pop(context, ProductActionType.lowStockAlert),
            ),
            _actionTile(
              context: context,
              icon: LucideIcons.calendar,
              iconColor: const Color(0xFF0D9488),
              title: 'Expiry Date',
              onTap: () => Navigator.pop(context, ProductActionType.expiryDate),
            ),
            const Gap(4),
            _actionTile(
              context: context,
              icon: LucideIcons.trash2,
              iconColor: const Color(0xFFEF4444),
              title: 'Delete Product',
              isDestructive: true,
              onTap: () => Navigator.pop(context, ProductActionType.delete),
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 17, color: iconColor),
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
