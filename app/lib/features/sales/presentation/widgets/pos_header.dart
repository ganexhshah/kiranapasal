import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';

/// Top header for the POS Sales screen matching the design mockup.
class POSHeader extends StatelessWidget {
  const POSHeader({
    super.key,
    required this.onScanTap,
    required this.onActionsTap,
  });

  final VoidCallback onScanTap;
  final VoidCallback onActionsTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 56.0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'POS - New Sale',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.darkText,
                letterSpacing: -0.4,
              ),
            ),
          ),
          // Barcode Quick Action Button
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: onScanTap,
              tooltip: 'Scan barcode',
              icon: Icon(LucideIcons.scanLine, size: 18, color: colors.darkText),
              padding: EdgeInsets.zero,
              splashRadius: 20,
            ),
          ),
          const Gap(8),
          // 3-Dots Quick Action Button
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: onActionsTap,
              tooltip: 'POS actions',
              icon: Icon(LucideIcons.moreVertical, size: 18, color: colors.darkText),
              padding: EdgeInsets.zero,
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }
}

