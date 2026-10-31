import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/widgets/core_widgets.dart';

/// Reusable product thumbnail displaying an image with lazy loading, shimmer, or category fallback icon.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    super.key,
    this.imageUrl,
    this.category,
    this.size = 44,
    this.borderRadius = 10,
  });

  final String? imageUrl;
  final String? category;
  final double size;
  final double borderRadius;

  IconData _getCategoryIcon(String? cat) {
    if (cat == null) return LucideIcons.package;
    final lower = cat.toLowerCase();
    if (lower.contains('grain') || lower.contains('rice') || lower.contains('flour') || lower.contains('sugar')) {
      return LucideIcons.wheat;
    }
    if (lower.contains('beverage') || lower.contains('tea') || lower.contains('coffee')) {
      return LucideIcons.coffee;
    }
    if (lower.contains('snack') || lower.contains('biscuit') || lower.contains('noodle')) {
      return LucideIcons.cookie;
    }
    if (lower.contains('oil') || lower.contains('daily') || lower.contains('salt')) {
      return LucideIcons.shoppingBag;
    }
    return LucideIcons.package;
  }

  @override
  Widget build(BuildContext context) {
    return AppLazyImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(borderRadius),
      memCacheWidth: (size * 2.5).toInt(),
      memCacheHeight: (size * 2.5).toInt(),
      fallbackIcon: _getCategoryIcon(category),
    );
  }
}

