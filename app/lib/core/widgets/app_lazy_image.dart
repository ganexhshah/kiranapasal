import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/theme.dart';

/// High-performance lazy network & local image component with automatic disk/memory caching,
/// memory decode limits (to prevent mobile OOM), shimmer placeholder, and graceful fallback.
class AppLazyImage extends StatelessWidget {
  const AppLazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.isCircle = false,
    this.fallbackIcon = LucideIcons.image,
    this.fallbackInitials,
    this.memCacheWidth = 300,
    this.memCacheHeight = 300,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final bool isCircle;
  final IconData fallbackIcon;
  final String? fallbackInitials;
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectiveBorderRadius = isCircle
        ? BorderRadius.circular(1000)
        : (borderRadius ?? BorderRadius.circular(8));

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildFallback(colors, effectiveBorderRadius);
    }

    final trimmedUrl = imageUrl!.trim();
    final isNetwork = trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://');

    Widget imageWidget;

    if (isNetwork) {
      imageWidget = CachedNetworkImage(
        imageUrl: trimmedUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 150),
        placeholder: (context, url) => _buildShimmerPlaceholder(),
        errorWidget: (context, url, error) => _buildFallback(colors, effectiveBorderRadius),
      );
    } else {
      // Local file
      final file = File(trimmedUrl);
      if (!file.existsSync()) {
        return _buildFallback(colors, effectiveBorderRadius);
      }

      imageWidget = Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: memCacheWidth,
        cacheHeight: memCacheHeight,
        errorBuilder: (context, error, stackTrace) => _buildFallback(colors, effectiveBorderRadius),
      );
    }

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: imageWidget,
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF1F5F9),
      highlightColor: const Color(0xFFFFFFFF),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: isCircle ? null : borderRadius,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }

  Widget _buildFallback(AppColorsExtension colors, BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: isCircle ? null : radius,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
      alignment: Alignment.center,
      child: fallbackInitials != null && fallbackInitials!.trim().isNotEmpty
          ? Text(
              fallbackInitials!.trim().toUpperCase(),
              style: TextStyle(
                fontSize: (width != null ? width! * 0.38 : 14.0).clamp(10.0, 24.0),
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            )
          : Icon(
              fallbackIcon,
              size: (width != null ? width! * 0.42 : 20.0).clamp(14.0, 32.0),
              color: const Color(0xFF94A3B8),
            ),
    );
  }
}

