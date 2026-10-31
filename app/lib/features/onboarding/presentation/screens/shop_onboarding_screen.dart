import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../products/presentation/sheets/image_crop_sheet.dart';
import '../../../products/presentation/sheets/image_source_picker_sheet.dart';
import '../sheets/setup_complete_sheet.dart';

/// Clean Shop Onboarding Screen featuring interactive shop photo upload,
/// image cropping with ImageCropSheet, shop name, and address.
class ShopOnboardingScreen extends StatefulWidget {
  const ShopOnboardingScreen({super.key});

  @override
  State<ShopOnboardingScreen> createState() => _ShopOnboardingScreenState();
}

class _ShopOnboardingScreenState extends State<ShopOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _ownerNameController = TextEditingController();

  String? _shopPhotoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final res = await AuthService().getProfile();
      if (res.success && res.data != null && mounted) {
        final user = res.data!['user'] as Map<String, dynamic>?;
        final shop = res.data!['shop'] as Map<String, dynamic>?;
        setState(() {
          if (user != null && _ownerNameController.text.isEmpty) {
            _ownerNameController.text = (user['name'] as String?) ?? '';
          }
          if (shop != null) {
            if (_shopNameController.text.isEmpty) {
              _shopNameController.text = (shop['name'] as String?) ?? '';
            }
            if (shop['address'] != null && _shopAddressController.text.isEmpty) {
              _shopAddressController.text = (shop['address'] as String?) ?? '';
            }
            if (shop['logo_url'] != null && _shopPhotoUrl == null) {
              _shopPhotoUrl = shop['logo_url'] as String?;
            }
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  /// Open Image Picker to choose from Camera or Gallery
  Future<void> _handlePickPhoto() async {
    final selected = await ImageSourcePickerSheet.show(
      context,
      currentImageUrl: _shopPhotoUrl,
      title: 'Shop Logo',
      showPresets: false,
    );
    if (selected != null && mounted) {
      setState(() => _shopPhotoUrl = selected);
    }
  }

  /// Open Image Crop Sheet to crop, zoom, and rotate the selected image
  Future<void> _handleCropPhoto() async {
    if (_shopPhotoUrl == null) {
      await _handlePickPhoto();
      return;
    }
    final cropped = await ImageCropSheet.show(
      context,
      imageUrl: _shopPhotoUrl!,
      title: 'Crop Shop Logo',
    );
    if (cropped != null && mounted) {
      setState(() => _shopPhotoUrl = cropped);
    }
  }

  Future<void> _handleFinishSetup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    String? failure;
    try {
      final shopName = _shopNameController.text.trim();
      final address = _shopAddressController.text.trim();
      String? logoUrl = _shopPhotoUrl;

      if (logoUrl != null && logoUrl.isNotEmpty && !logoUrl.startsWith('http')) {
        final file = File(logoUrl);
        if (file.existsSync()) {
          final uploadRes = await ApiClient.instance.uploadMultipart<Map<String, dynamic>>(
            ApiConfig.mediaUpload,
            file: file,
            fileField: 'image',
            fromData: (data) => data as Map<String, dynamic>,
          );
          if (uploadRes.success && uploadRes.data != null && uploadRes.data!['url'] != null) {
            logoUrl = uploadRes.data!['url'] as String;
          }
        }
      }

      final res = await ApiClient.instance.put<Map<String, dynamic>>(
        ApiConfig.shopProfile,
        body: {
          'name': shopName,
          if (address.isNotEmpty) 'address': address,
          'logo_url': ?logoUrl,
        },
      );
      if (!res.success) {
        failure = res.message.isNotEmpty
            ? res.message
            : "We couldn't save your shop details.";
      }
    } catch (e) {
      debugPrint('Shop setup failed: $e');
      failure = "We couldn't save your shop details. Check your connection.";
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    SetupCompleteSheet.show(
      context,
      shopName: _shopNameController.text.trim(),
      ownerName: _ownerNameController.text.trim().isNotEmpty
          ? _ownerNameController.text.trim()
          : 'Store Owner',
      shopAddress: _shopAddressController.text.trim(),
      shopPhotoUrl: _shopPhotoUrl,
    );
  }

  Widget _buildShopPhotoPreview(AppColorsExtension colors) {
    if (_shopPhotoUrl == null || _shopPhotoUrl!.trim().isEmpty) {
      return Center(
        child: Icon(
          LucideIcons.camera,
          size: 38,
          color: colors.inputLabel,
        ),
      );
    }

    return AppLazyImage(
      imageUrl: _shopPhotoUrl!,
      width: 104,
      height: 104,
      borderRadius: BorderRadius.circular(55),
      fit: BoxFit.cover,
      fallbackIcon: LucideIcons.store,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasPhoto = _shopPhotoUrl != null && _shopPhotoUrl!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 56.0,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 20, color: colors.darkText),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          splashRadius: 20,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Set Up Your Shop',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: colors.darkText,
                    letterSpacing: -0.5,
                  ),
                ),
                const Gap(6),
                Text(
                  'Add your kirana shop details to start tracking sales, products, and udhar.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: colors.inputLabel,
                  ),
                ),
                const Gap(28),

                // Shop Photo Circle with Camera Icon and Crop Support
                Center(
                  child: Stack(
                    children: [
                      InkWell(
                        onTap: _handlePickPhoto,
                        borderRadius: BorderRadius.circular(55),
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.secondarySurface,
                            border: Border.all(
                              color: colors.inputBorder.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: _buildShopPhotoPreview(colors),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: hasPhoto ? _handleCropPhoto : _handlePickPhoto,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              hasPhoto ? LucideIcons.crop : Icons.camera_alt,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Center(
                  child: Text(
                    hasPhoto ? 'Shop Photo Selected' : 'Upload Shop Logo / Photo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasPhoto ? colors.primary : colors.inputLabel,
                    ),
                  ),
                ),

                // Crop & Change Options when photo is selected
                if (hasPhoto) ...[
                  const Gap(10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _handleCropPhoto,
                        icon: const Icon(LucideIcons.crop, size: 14),
                        label: const Text('Crop & Adjust', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      const Gap(8),
                      OutlinedButton.icon(
                        onPressed: _handlePickPhoto,
                        icon: const Icon(LucideIcons.refreshCw, size: 14),
                        label: const Text('Change', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      const Gap(8),
                      IconButton(
                        onPressed: () => setState(() => _shopPhotoUrl = null),
                        icon: Icon(LucideIcons.trash2, size: 16, color: Colors.red.shade400),
                        tooltip: 'Remove Photo',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],

                const Gap(24),

                // Shop Name field
                AuthTextField(
                  controller: _shopNameController,
                  label: 'Shop Name',
                  hintText: 'e.g. Baluwatar Kirana Pasal',
                  prefixIcon: Icon(
                    LucideIcons.store,
                    size: 20,
                    color: colors.darkText,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your shop name';
                    }
                    return null;
                  },
                ),
                const Gap(16),

                // Shop Address field
                AuthTextField(
                  controller: _shopAddressController,
                  label: 'Shop Address',
                  hintText: 'e.g. Baluwatar-4, Kathmandu',
                  prefixIcon: Icon(
                    LucideIcons.mapPin,
                    size: 20,
                    color: colors.darkText,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your shop address';
                    }
                    return null;
                  },
                ),
                const Gap(16),

                // Owner Name field
                AuthTextField(
                  controller: _ownerNameController,
                  label: 'Owner Name',
                  hintText: 'e.g. Ram Bahadur Shrestha',
                  prefixIcon: Icon(
                    LucideIcons.user,
                    size: 20,
                    color: colors.darkText,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter owner name';
                    }
                    return null;
                  },
                ),
                const Gap(28),

                // Finish Setup Button
                AppPrimaryButton(
                  text: 'Finish Setup & Open Shop',
                  isLoading: _isLoading,
                  onPressed: _handleFinishSetup,
                ),
                const Gap(16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
