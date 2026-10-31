import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';

/// Reusable top header for Products screen: "Products" title + barcode icon, plus icon.
class ProductsHeader extends StatelessWidget {
  const ProductsHeader({
    super.key,
    this.title = 'Products',
    this.onBarcodeTap,
    this.onAddTap,
    this.onSettingsTap,
  });

  final String title;
  final VoidCallback? onBarcodeTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Products Title (Standardized 20px w800 matching other root headers)
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.darkText,
            letterSpacing: -0.3,
          ),
        ),

        // Actions: Barcode Icon, Plus Icon Button & Settings Icon Button
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barcode Icon Button (Opens Barcode Printing Screen)
            IconButton(
              onPressed: onBarcodeTap,
              icon: Icon(
                LucideIcons.barcode,
                color: colors.darkText,
                size: 21,
              ),
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              tooltip: 'Print Barcodes',
            ),

            // Normal Plus Icon Button
            IconButton(
              onPressed: onAddTap,
              icon: Icon(
                LucideIcons.plus,
                color: colors.darkText,
                size: 20,
              ),
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              tooltip: 'Add Product',
            ),

            // Settings Icon Button
            if (onSettingsTap != null)
              IconButton(
                onPressed: onSettingsTap,
                icon: Icon(
                  LucideIcons.settings,
                  color: colors.darkText,
                  size: 20,
                ),
                splashRadius: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                tooltip: 'Settings',
              ),
          ],
        ),
      ],
    );
  }
}

