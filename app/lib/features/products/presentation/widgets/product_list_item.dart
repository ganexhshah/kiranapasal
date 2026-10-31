import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/product.dart';
import '../sheets/print_barcode_sheet.dart';
import '../sheets/product_actions_sheet.dart';
import 'product_thumbnail.dart';

/// Reusable product list row displaying thumbnail, title, SKU, price, stock badge, and action menu.
class ProductListItem extends StatelessWidget {
  const ProductListItem({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onUpdateStock,
    this.onPrintBarcode,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onUpdateStock;
  final VoidCallback? onPrintBarcode;

  Future<void> _showActionMenu(BuildContext context) async {
    final action = await ProductActionsSheet.show(context, product: product);
    if (action == null) return;

    switch (action) {
      case ProductActionType.edit:
        onEdit?.call();
        break;
      case ProductActionType.adjustStock:
        onUpdateStock?.call();
        break;
      case ProductActionType.delete:
        onDelete?.call();
        break;
      case ProductActionType.printBarcode:
        if (onPrintBarcode != null) {
          onPrintBarcode?.call();
        } else if (context.mounted) {
          PrintBarcodeSheet.show(context, product: product);
        }
        break;
      default:
        onTap?.call();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLow = product.isLowStock;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. Product Thumbnail & Info (flex: 4)
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  ProductThumbnail(
                    imageUrl: product.imageUrl,
                    category: product.category,
                    size: 36,
                    borderRadius: 8,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(1),
                        Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: colors.inputLabel,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'SKU: ${product.sku}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: colors.inputBorder,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(6),

            // 2. Price Column (flex: 2)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.formattedPrice,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.darkText,
                    ),
                  ),
                  Text(
                    '/${product.priceUnit}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: colors.inputLabel,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(4),

            // 3. Stock Badge Column (flex: 2)
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isLow ? const Color(0xFFFEECEC) : const Color(0xFFE6F8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.formattedStock,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isLow ? const Color(0xFFEF4444) : const Color(0xFF059669),
                    ),
                  ),
                ),
              ),
            ),

            // 4. Actions Column (3-dots button)
            SizedBox(
              width: 32,
              child: IconButton(
                icon: Icon(
                  LucideIcons.ellipsisVertical,
                  size: 17,
                  color: colors.inputLabel,
                ),
                padding: EdgeInsets.zero,
                splashRadius: 16,
                onPressed: () => _showActionMenu(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

