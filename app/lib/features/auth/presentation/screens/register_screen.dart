import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../onboarding/onboarding.dart';
import '../sheets/country_picker_sheet.dart';
import '../sheets/verify_otp_sheet.dart';

/// Clean Create Account Screen with real backend registration,
/// Shop details, and automatic Resend 6-digit OTP verification.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedCountryCode = '+977';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openCountryPicker() async {
    final selected = await CountryPickerSheet.show(
      context,
      selectedDialCode: _selectedCountryCode,
    );
    if (selected != null && mounted) {
      setState(() => _selectedCountryCode = selected.dialCode);
    }
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim().isNotEmpty
        ? '$_selectedCountryCode ${_phoneController.text.trim()}'
        : null;

    final response = await AuthService().register(
      name: _nameController.text.trim(),
      email: email,
      password: _passwordController.text,
      phone: phone,
      shopName: _shopNameController.text.trim().isNotEmpty ? _shopNameController.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : 'Registration successful! Verification code sent to your email.',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Open the OTP sheet and handle the case where the user closes it
      // without verifying, so the account never gets stranded silently.
      await _showOtpSheet(email);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty ? response.message : 'Registration failed. Please check your information.',
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showOtpSheet(String email) async {
    final verified = await VerifyOtpSheet.show(
      context,
      email: email,
      onVerified: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const ShopOnboardingScreen(),
          ),
          (route) => false,
        );
      },
    );

    if (verified == true || !mounted) return;

    // The account exists on the server but is still unverified. Keep a way back
    // to verification instead of leaving the user stuck on the form.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Your account is not verified yet.'),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'Verify',
          onPressed: () => _showOtpSheet(email),
        ),
      ),
    );
  }

  bool get _hasInput =>
      _nameController.text.trim().isNotEmpty ||
      _emailController.text.trim().isNotEmpty ||
      _phoneController.text.trim().isNotEmpty ||
      _shopNameController.text.trim().isNotEmpty ||
      _passwordController.text.isNotEmpty;

  Future<void> _confirmDiscard() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard this form?'),
        content: const Text('Your details will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PopScope(
      canPop: !_hasInput,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmDiscard();
      },
      child: Scaffold(
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo & Header
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/logokirana360.svg',
                      width: 52,
                      height: 52,
                    ),
                  ),
                ),
                const Gap(14),
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: colors.darkText,
                    letterSpacing: -0.5,
                  ),
                ),
                const Gap(6),
                Text(
                  'Join pasal365 and manage your store online.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colors.inputLabel,
                  ),
                ),
                const Gap(24),

                // Full Name Input
                AuthTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hintText: 'e.g. Ram Bahadur Shrestha',
                  prefixIcon: Icon(
                    LucideIcons.user,
                    size: 20,
                    color: colors.darkText,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const Gap(16),

                // Email Address Input (Mandatory for Resend OTP verification)
                AuthTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hintText: 'e.g. ram@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icon(
                    LucideIcons.mail,
                    size: 20,
                    color: colors.darkText,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty || !val.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const Gap(16),

                // Shop / Store Name (Optional or Suggested)
                AuthTextField(
                  controller: _shopNameController,
                  label: 'Shop Name (Optional)',
                  hintText: 'e.g. Shrestha Kirana Store',
                  prefixIcon: Icon(
                    LucideIcons.store,
                    size: 20,
                    color: colors.darkText,
                  ),
                ),
                const Gap(16),

                // Phone Number Input (with country code)
                AuthPhoneField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  hintText: '9841234567',
                  countryCode: _selectedCountryCode,
                  onCountryCodeTap: _openCountryPicker,
                ),
                const Gap(16),

                // Password Input Field
                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Create a password (min 6 characters)',
                  isPassword: true,
                  prefixIcon: Icon(
                    LucideIcons.lock,
                    size: 20,
                    color: colors.darkText,
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const Gap(26),

                // Create Account Button
                AppPrimaryButton(
                  text: 'Create Account',
                  isLoading: _isLoading,
                  onPressed: _handleRegister,
                ),
                const Gap(24),

                // Bottom Footer: Already have an account? Login
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: colors.inputLabel,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(16),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
