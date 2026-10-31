import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/printing_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../products/presentation/sheets/image_source_picker_sheet.dart';
import '../../../sales/presentation/sheets/shop_profile_sheet.dart';

/// Clean, production-ready Profile Screen displaying live authenticated user info,
/// avatar cropping/uploading, shop metadata, and security settings.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';
  String? _userPhone;
  String? _avatarUrl;
  String _roleName = 'Owner';

  String _shopName = '';
  String _shopAddress = '';
  String _shopPhone = '';
  String _shopPan = '';
  String? _shopLogoUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final res = await _authService.getProfile();

    if (res.success && res.data != null && mounted) {
      final user = res.data!['user'] as Map<String, dynamic>?;
      final shop = (user?['current_shop'] ?? res.data!['shop']) as Map<String, dynamic>?;
      final roles = res.data!['roles'] as List<dynamic>?;

      setState(() {
        if (user != null) {
          _userName = (user['name'] as String?) ?? 'Store Owner';
          _userEmail = (user['email'] as String?) ?? '';
          _userPhone = user['phone'] as String?;
          _avatarUrl = user['avatar_url'] as String?;
        }

        if (roles != null && roles.isNotEmpty) {
          _roleName = roles.first.toString().toUpperCase();
        }

        if (shop != null) {
          _shopName = (shop['name'] as String?) ?? 'My Kirana Store';
          _shopAddress = (shop['address'] as String?) ?? '';
          _shopPhone = (shop['phone'] as String?) ?? '';
          _shopPan = (shop['pan_vat_number'] as String?) ?? '';
          _shopLogoUrl = shop['logo_url'] as String?;
          PrintingService.instance.updateSettings(
            storeName: _shopName,
            storeAddress: _shopAddress,
            storePhone: _shopPhone,
            panNumber: _shopPan,
          );
        }
      });
    }

    if (mounted) setState(() => _isLoading = false);
  }

  String get _initials {
    if (_userName.trim().isEmpty) return 'KO';
    final parts = _userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _userName.substring(0, _userName.length >= 2 ? 2 : 1).toUpperCase();
  }

  Future<void> _handleUpdateAvatar() async {
    final picked = await ImageSourcePickerSheet.show(
      context,
      currentImageUrl: _avatarUrl,
      title: 'Profile Photo',
      showPresets: false,
    );

    if (picked != null && mounted) {
      if (picked.isEmpty) {
        setState(() => _avatarUrl = null);
        await _authService.updateProfile(
          name: _userName,
          phone: _userPhone,
          avatarUrl: '',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture removed'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Optimistically preview newly picked / cropped image immediately
      setState(() => _avatarUrl = picked);

      String finalUrl = picked;
      if (!picked.startsWith('http')) {
        final file = File(picked);
        if (file.existsSync()) {
          final uploadRes = await ApiClient.instance.uploadMultipart<Map<String, dynamic>>(
            ApiConfig.mediaUpload,
            file: file,
            fileField: 'image',
            fromData: (data) => data as Map<String, dynamic>,
          );
          if (uploadRes.success && uploadRes.data != null && uploadRes.data!['url'] != null) {
            finalUrl = uploadRes.data!['url'] as String;
          }
        }
      }

      setState(() => _avatarUrl = finalUrl);
      final updateRes = await _authService.updateProfile(
        name: _userName,
        phone: _userPhone,
        avatarUrl: finalUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updateRes.success ? 'Profile picture updated & saved!' : 'Could not save picture: ${updateRes.message}'),
            backgroundColor: updateRes.success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleEditProfile() async {
    final nameCtrl = TextEditingController(text: _userName);
    final phoneCtrl = TextEditingController(text: _userPhone ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(16),
            const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Gap(16),
            AuthTextField(
              controller: nameCtrl,
              label: 'Full Name',
              hintText: 'Your name',
              prefixIcon: const Icon(LucideIcons.user, size: 20),
            ),
            const Gap(14),
            AuthTextField(
              controller: phoneCtrl,
              label: 'Phone Number',
              hintText: 'e.g. +977 9841234567',
              prefixIcon: const Icon(LucideIcons.phone, size: 20),
            ),
            const Gap(20),
            AppPrimaryButton(
              text: 'Save Changes',
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final updatedName = nameCtrl.text.trim();
      final updatedPhone = phoneCtrl.text.trim();

      final res = await _authService.updateProfile(
        name: updatedName,
        phone: updatedPhone.isNotEmpty ? updatedPhone : null,
        avatarUrl: _avatarUrl,
      );

      if (mounted) {
        if (res.success) {
          setState(() {
            _userName = updatedName;
            _userPhone = updatedPhone.isNotEmpty ? updatedPhone : null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleEditShopProfile() async {
    final updated = await ShopProfileSheet.show(
      context,
      initialData: ShopProfileData(
        shopName: _shopName,
        address: _shopAddress,
        phone: _shopPhone,
        panNumber: _shopPan,
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _shopName = updated.shopName;
        _shopAddress = updated.address;
        _shopPhone = updated.phone;
        _shopPan = updated.panNumber;
      });

      await PrintingService.instance.updateSettings(
        storeName: updated.shopName,
        storeAddress: updated.address,
        storePhone: updated.phone,
        panNumber: updated.panNumber,
      );

      // Save to real backend
      await ApiClient.instance.put<Map<String, dynamic>>(
        ApiConfig.shopProfile,
        body: {
          'name': updated.shopName,
          'address': updated.address,
          'phone': updated.phone,
          'pan_vat_number': updated.panNumber,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop profile updated successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of your KRM account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildAvatarWidget(AppColorsExtension colors) {
    return AppLazyImage(
      imageUrl: _avatarUrl,
      width: 88,
      height: 88,
      isCircle: true,
      fallbackInitials: _initials,
      fallbackIcon: LucideIcons.user,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.darkText,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: const [
                  Center(child: ShimmerBlock(width: 88, height: 88, shape: BoxShape.circle)),
                  Gap(16),
                  Center(child: ShimmerBlock(width: 140, height: 20, borderRadius: 6)),
                  Gap(8),
                  Center(child: ShimmerBlock(width: 80, height: 14, borderRadius: 6)),
                  Gap(24),
                  ShimmerBlock(height: 70, borderRadius: 14),
                  Gap(16),
                  ShimmerBlock(height: 120, borderRadius: 14),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchProfile,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    const Gap(8),
                    // 1. Clean Avatar with Camera Action
                    Center(
                      child: Stack(
                        children: [
                          InkWell(
                            onTap: _handleUpdateAvatar,
                            borderRadius: BorderRadius.circular(44),
                            child: _buildAvatarWidget(colors),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _handleUpdateAvatar,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(14),

                    // 2. User Name & Role
                    Text(
                      _userName.isNotEmpty ? _userName : 'User',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: colors.darkText,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      _roleName,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                    const Gap(16),

                    // 3. Edit Profile Quick Action Button
                    OutlinedButton.icon(
                      onPressed: _handleEditProfile,
                      icon: const Icon(LucideIcons.pencil, size: 14),
                      label: const Text('Edit Personal Info', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.darkText,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const Gap(24),

                    // 4. Contact Details (Clean, no harsh borders or dividers)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.mail, size: 16, color: colors.inputLabel),
                              const Gap(12),
                              Expanded(
                                child: Text(
                                  _userEmail.isNotEmpty ? _userEmail : 'No email added',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: colors.darkText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_userPhone != null && _userPhone!.isNotEmpty) ...[
                            const Gap(12),
                            Row(
                              children: [
                                Icon(LucideIcons.phone, size: 16, color: colors.inputLabel),
                                const Gap(12),
                                Expanded(
                                  child: Text(
                                    _userPhone!,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: colors.darkText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Gap(14),

                    // 5. Shop Card (Clean, borderless, informative)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: _shopLogoUrl != null && _shopLogoUrl!.isNotEmpty
                                    ? AppLazyImage(
                                        imageUrl: _shopLogoUrl!,
                                        width: 34,
                                        height: 34,
                                        borderRadius: BorderRadius.circular(8),
                                        fallbackIcon: LucideIcons.store,
                                      )
                                    : Icon(LucideIcons.store, size: 17, color: colors.primary),
                              ),
                              const Gap(10),
                              Expanded(
                                child: Text(
                                  _shopName.isNotEmpty ? _shopName : 'My Shop',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: colors.darkText,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _handleEditShopProfile,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0066FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_shopAddress.isNotEmpty) ...[
                            const Gap(8),
                            Row(
                              children: [
                                Icon(LucideIcons.mapPin, size: 14, color: colors.inputLabel),
                                const Gap(6),
                                Expanded(
                                  child: Text(
                                    _shopAddress,
                                    style: TextStyle(fontSize: 12.5, color: colors.inputLabel),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_shopPhone.isNotEmpty) ...[
                            const Gap(4),
                            Row(
                              children: [
                                Icon(LucideIcons.phone, size: 14, color: colors.inputLabel),
                                const Gap(6),
                                Text(
                                  _shopPhone,
                                  style: TextStyle(fontSize: 12.5, color: colors.inputLabel),
                                ),
                              ],
                            ),
                          ],
                          if (_shopPan.isNotEmpty) ...[
                            const Gap(4),
                            Row(
                              children: [
                                Icon(LucideIcons.fileText, size: 14, color: colors.inputLabel),
                                const Gap(6),
                                Text(
                                  'PAN/VAT: $_shopPan',
                                  style: TextStyle(fontSize: 12.5, color: colors.inputLabel),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Gap(28),

                    // 6. Log Out Button (Clean, soft red pill)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(LucideIcons.logOut, size: 16, color: Color(0xFFEF4444)),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFEF2F2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const Gap(20),
                  ],
                ),
              ),
            ),
    );
  }
}

