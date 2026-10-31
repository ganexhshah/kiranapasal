import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/cart_item.dart';

/// Floating/docked bottom cart bar displaying total items and direct checkout action.
class CartBottomBar extends StatelessWidget {
  const CartBottomBar({
    super.key,
    required this.items,
    required this.onCheckout,
    required this.onClearCart,
  });

  final List<CartItem> items;
  final VoidCallback onCheckout;
  final VoidCallback onClearCart;

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);

  /// Total units in the cart, not the number of rows: 2 line items of 6 packets
  /// each reads "12 items in cart", matching the receipt.
  double get totalQuantity => items.fold(0.0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final quantityStr = formatQuantity(totalQuantity);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.darkText,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cart Icon & Item Count
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.shoppingBag, size: 18, color: Colors.white),
          ),
          const Gap(12),

          // Total Items & Total Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$quantityStr ${totalQuantity == 1 ? 'item' : 'items'} in cart',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  formatMoney(totalAmount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Checkout Button
          ElevatedButton(
            onPressed: onCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Checkout',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Gap(4),
                Icon(LucideIcons.chevronRight, size: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

