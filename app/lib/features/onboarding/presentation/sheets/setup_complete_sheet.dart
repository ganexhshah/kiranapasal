import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../dashboard/dashboard.dart';
import '../../../products/presentation/screens/add_product_screen.dart';

/// Celebratory bottom sheet displayed after shop profile and details are successfully saved.
class SetupCompleteSheet extends StatelessWidget {
  const SetupCompleteSheet({
    super.key,
    required this.shopName,
    required this.ownerName,
    this.shopAddress,
    this.shopPhotoUrl,
  });

  final String shopName;
  final String ownerName;
  final String? shopAddress;
  final String? shopPhotoUrl;

  static Future<void> show(
    BuildContext context, {
    required String shopName,
    required String ownerName,
    String? shopAddress,
    String? shopPhotoUrl,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SetupCompleteSheet(
        shopName: shopName,
        ownerName: ownerName,
        shopAddress: shopAddress,
        shopPhotoUrl: shopPhotoUrl,
      ),
    );
  }

  Widget _buildShopAvatar(AppColorsExtension colors) {
    if (shopPhotoUrl == null || shopPhotoUrl!.trim().isEmpty) {
      return Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF3B82F6), width: 2),
        ),
        child: const Center(
          child: Icon(
            LucideIcons.store,
            size: 36,
            color: Color(0xFF2563EB),
          ),
        ),
      );
    }

    final isNetwork = shopPhotoUrl!.startsWith('http');
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF10B981), width: 2.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: isNetwork
            ? CachedNetworkImage(
                imageUrl: shopPhotoUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const Icon(LucideIcons.store, size: 36),
              )
            : Image.file(
                File(shopPhotoUrl!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(LucideIcons.store, size: 36),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.inputBorder.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(20),

              // Celebratory Badge & Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFECFDF5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.18),
                          blurRadius: 18,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  _buildShopAvatar(colors),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(16),

              // Title
              Text(
                'Store Setup Complete! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colors.darkText,
                  letterSpacing: -0.3,
                ),
              ),
              const Gap(6),
              Text(
                'Your digital kirana store is live and ready for business.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.inputLabel,
                  height: 1.4,
                ),
              ),
              const Gap(20),

              // Shop Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.secondarySurface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.inputBorder.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            LucideIcons.store,
                            size: 18,
                            color: colors.primary,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shopName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colors.darkText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Owner: $ownerName',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colors.inputLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (shopAddress != null && shopAddress!.trim().isNotEmpty) ...[
                      const Gap(10),
                      Divider(
                        height: 1,
                        color: colors.inputBorder.withValues(alpha: 0.2),
                      ),
                      const Gap(10),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 15,
                            color: colors.inputLabel,
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              shopAddress!,
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.darkText.withValues(alpha: 0.85),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(18),

              // Checklist Items
              _ChecklistRow(
                colors: colors,
                title: 'Shop profile & branding saved',
              ),
              const Gap(8),
              _ChecklistRow(
                colors: colors,
                title: 'Real-time billing & receipts configured',
              ),
              const Gap(8),
              _ChecklistRow(
                colors: colors,
                title: 'Customer udhar & inventory ledger initialized',
              ),
              const Gap(24),

              // Primary: Go to Dashboard
              AppPrimaryButton(
                text: 'Go to Dashboard',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
              const Gap(12),

              // Secondary: Add First Product
              AppOutlinedButton(
                text: 'Add Your First Product',
                icon: Icon(
                  LucideIcons.packagePlus,
                  size: 18,
                  color: colors.primary,
                ),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                    (route) => false,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddProductScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.colors,
    required this.title,
  });

  final AppColorsExtension colors;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFFD1FAE5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 13,
            color: Color(0xFF059669),
          ),
        ),
        const Gap(10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.darkText.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}
