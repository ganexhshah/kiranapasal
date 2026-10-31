import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable shimmer box placeholder for building customized skeletons.
class ShimmerBlock extends StatelessWidget {
  const ShimmerBlock({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF1F5F9),
      highlightColor: const Color(0xFFFFFFFF),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(borderRadius) : null,
          shape: shape,
        ),
      ),
    );
  }
}

/// Skeleton loader for Dashboard Screen during initial overview / stats fetch.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick actions shimmer row
          Row(
            children: const [
              Expanded(child: ShimmerBlock(height: 76, borderRadius: 14)),
              Gap(12),
              Expanded(child: ShimmerBlock(height: 76, borderRadius: 14)),
              Gap(12),
              Expanded(child: ShimmerBlock(height: 76, borderRadius: 14)),
            ],
          ),
          const Gap(18),

          // Today's Sales Banner Shimmer
          const ShimmerBlock(height: 124, borderRadius: 16),
          const Gap(18),

          // 2x2 Stats Grid Shimmer
          Row(
            children: const [
              Expanded(child: ShimmerBlock(height: 84, borderRadius: 14)),
              Gap(12),
              Expanded(child: ShimmerBlock(height: 84, borderRadius: 14)),
            ],
          ),
          const Gap(12),
          Row(
            children: const [
              Expanded(child: ShimmerBlock(height: 84, borderRadius: 14)),
              Gap(12),
              Expanded(child: ShimmerBlock(height: 84, borderRadius: 14)),
            ],
          ),
          const Gap(22),

          // Recent Transactions Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBlock(width: 140, height: 18, borderRadius: 4),
              ShimmerBlock(width: 60, height: 16, borderRadius: 4),
            ],
          ),
          const Gap(12),

          // Transactions List Items Shimmer
          ...List.generate(
            5,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const ShimmerBlock(width: 36, height: 36, shape: BoxShape.circle),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerBlock(width: 120, height: 14, borderRadius: 4),
                          Gap(6),
                          ShimmerBlock(width: 80, height: 11, borderRadius: 4),
                        ],
                      ),
                    ),
                    const ShimmerBlock(width: 64, height: 16, borderRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a single product card in catalog grid.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(child: ShimmerBlock(height: double.infinity, borderRadius: 10)),
          Gap(10),
          ShimmerBlock(width: 100, height: 13, borderRadius: 4),
          Gap(6),
          Row(
            children: [
              Expanded(flex: 5, child: ShimmerBlock(height: 14, borderRadius: 4)),
              Gap(6),
              Expanded(flex: 4, child: ShimmerBlock(height: 12, borderRadius: 4)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton grid for Products catalog & POS screen.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.78,
  });

  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) => const ProductCardSkeleton(),
    );
  }
}

/// Skeleton list for Transactions / Sales history screen.
class TransactionListSkeleton extends StatelessWidget {
  const TransactionListSkeleton({super.key, this.itemCount = 7});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const Gap(10),
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const ShimmerBlock(width: 40, height: 40, borderRadius: 10),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBlock(width: 130, height: 14, borderRadius: 4),
                  Gap(6),
                  ShimmerBlock(width: 90, height: 11, borderRadius: 4),
                ],
              ),
            ),
            const ShimmerBlock(width: 70, height: 16, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

