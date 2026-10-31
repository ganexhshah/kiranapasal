import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../products/domain/models/product.dart';
import '../../../products/presentation/widgets/product_thumbnail.dart';

/// Clean 3-column product card for POS grid matching mockup exactly.
class POSProductCard extends StatelessWidget {
  const POSProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
    this.onTap,
  });

  final Product product;
  final VoidCallback onAddToCart;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLowStock = product.isLowStock;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF0F2F6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap ?? onAddToCart,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ProductThumbnail(
                        imageUrl: product.imageUrl,
                        category: product.category,
                        size: 56,
                      ),
                    ),
                  ),
                ),
                const Gap(6),

                // Product Title
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.darkText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(3),

                // Price with Unit
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: product.formattedPrice,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0066FF),
                    ),
                    children: [
                      TextSpan(
                        text: ' /${product.priceUnit}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: colors.inputLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(6),

                // Bottom Row: Stock Badge & "+" Add Button (Flexible to prevent right overflow)
                Row(
                  children: [
                    // Stock Badge
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                        decoration: BoxDecoration(
                          color: isLowStock ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.formattedStock,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: isLowStock ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const Gap(6),

                    // Round Plus Button — 44dp hit area, 30dp visual chip, so it
                    // is reliably tappable on a cheap 320dp phone.
                    Semantics(
                      button: true,
                      label: 'Add ${product.name} to cart',
                      child: Tooltip(
                        message: 'Add to cart',
                        child: InkWell(
                          onTap: onAddToCart,
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 44,
                            height: 34,
                            child: Center(
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0066FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  LucideIcons.plus,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

