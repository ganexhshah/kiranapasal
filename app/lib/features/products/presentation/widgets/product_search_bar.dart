import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';

/// Reusable search bar with barcode scanner icon for product searching.
class ProductSearchBar extends StatelessWidget {
  const ProductSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onScanBarcodeTap,
    this.hintText = 'Search product name, barcode, or SKU...',
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onScanBarcodeTap;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.inputBorder.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(
            fontSize: 13,
            color: colors.darkText,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            prefixIcon: Icon(
              LucideIcons.search,
              size: 17,
              color: colors.inputLabel,
            ),
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 12.5,
              color: colors.inputBorder,
              fontWeight: FontWeight.w400,
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            suffixIcon: InkWell(
              onTap: onScanBarcodeTap,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Icon(
                    LucideIcons.scanLine,
                    size: 18,
                    color: colors.darkText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

