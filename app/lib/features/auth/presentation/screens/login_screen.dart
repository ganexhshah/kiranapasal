import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../dashboard/dashboard.dart';
import '../../../onboarding/onboarding.dart';
import '../sheets/country_picker_sheet.dart';
import '../sheets/forgot_password_sheet.dart';
import 'register_screen.dart';

/// Clean, seamless LoginScreen with real backend authentication,
/// phone/email toggle, country code picker, and password reset.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isEmailMode = true; // Email by default, or Phone
  String _selectedCountryCode = '+977';
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  bool get _isLocked => _isLoading || _isGoogleLoading;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openCountryPicker() async {
    if (_isLocked) return;
    final selected = await CountryPickerSheet.show(
      context,
      selectedDialCode: _selectedCountryCode,
    );
    if (selected != null && mounted) {
      setState(() => _selectedCountryCode = selected.dialCode);
    }
  }

  void _openForgotPassword() {
    if (_isLocked) return;
    ForgotPasswordSheet.show(
      context,
      initialEmail: _isEmailMode ? _emailController.text : '',
    );
  }

  Future<void> _handleLogin() async {
    if (_isLocked) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final identifier = _isEmailMode
          ? _emailController.text.trim()
          : '$_selectedCountryCode ${_phoneController.text.trim()}';

      final res = await AuthService().login(
        identifier: identifier,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (res.success) {
        final userName = res.data?['user']?['name'] ?? res.data?['shop']?['name'];
        final welcomeMsg = userName != null && userName.toString().trim().isNotEmpty
            ? 'Welcome back, $userName!'
            : (res.message.isNotEmpty ? res.message : 'Login successful!');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 20),
                const Gap(10),
                Expanded(
                  child: Text(
                    welcomeMsg,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
                const Gap(10),
                Expanded(
                  child: Text(
                    res.message.isNotEmpty ? res.message : 'Invalid credentials. Please try again.',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLocked) return;

    setState(() => _isGoogleLoading = true);

    try {
      final res = await AuthService().loginWithGoogle();
      if (!mounted) return;

      if (res.success) {
        final isNewUser = res.data?['is_new_user'] == true;
        final user = res.data?['user'] as Map<String, dynamic>?;
        final shop = res.data?['shop'] as Map<String, dynamic>?;
        final name = (user?['name'] ?? shop?['name'] ?? '').toString().trim();

        final welcomeMsg = name.isNotEmpty
            ? 'Welcome, $name! Successfully logged in with Google.'
            : 'Welcome back! Successfully logged in with Google.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 20),
                const Gap(10),
                Expanded(
                  child: Text(
                    welcomeMsg,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );

        if (isNewUser) {
          // First-time user signing in through Google -> Navigate to Shop Onboarding
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ShopOnboardingScreen(),
            ),
          );
        } else {
          // Returning user -> Navigate straight to Dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const DashboardScreen(),
            ),
          );
        }
      } else {
        final isCancelled = res.message.toLowerCase().contains('cancel');
        final errorMsg = isCancelled
            ? 'Google sign-in was cancelled.'
            : (res.message.isNotEmpty
                ? res.message
                : 'Unable to sign in with Google. Please try again or use your password.');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isCancelled ? LucideIcons.info : LucideIcons.alertCircle,
                  color: Colors.white,
                  size: 20,
                ),
                const Gap(10),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: isCancelled ? const Color(0xFF475569) : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
              Gap(10),
              Expanded(
                child: Text(
                  'Unable to complete Google sign-in. Please try again.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: AbsorbPointer(
              absorbing: _isLocked,
              child: Form(
                key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(12),

                  // Header
                  Text(
                    'Kirana Pasal',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: colors.darkText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    'Manage your shop easily',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colors.inputLabel,
                    ),
                  ),
                  const Gap(24),

                  // Toggle Phone vs Email
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.secondarySurface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: _isEmailMode,
                            label: 'Sign in with email',
                            child: InkWell(
                            onTap: () => setState(() => _isEmailMode = true),
                            borderRadius: BorderRadius.circular(9),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isEmailMode ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: _isEmailMode
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.mail,
                                    size: 16,
                                    color: _isEmailMode ? colors.primary : colors.inputLabel,
                                  ),
                                  const Gap(6),
                                  Text(
                                    'Email',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _isEmailMode ? FontWeight.w700 : FontWeight.w500,
                                      color: _isEmailMode ? colors.darkText : colors.inputLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ),
                        ),
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: !_isEmailMode,
                            label: 'Sign in with phone',
                            child: InkWell(
                            onTap: () => setState(() => _isEmailMode = false),
                            borderRadius: BorderRadius.circular(9),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isEmailMode ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: !_isEmailMode
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.smartphone,
                                    size: 16,
                                    color: !_isEmailMode ? colors.primary : colors.inputLabel,
                                  ),
                                  const Gap(6),
                                  Text(
                                    'Phone',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: !_isEmailMode ? FontWeight.w700 : FontWeight.w500,
                                      color: !_isEmailMode ? colors.darkText : colors.inputLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(20),

                  // Input field (Email or Phone)
                  if (_isEmailMode)
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hintText: 'ganesh@krmstore.com',
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icon(
                        LucideIcons.mail,
                        size: 20,
                        color: colors.darkText,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty || !value.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    )
                  else
                    AuthPhoneField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hintText: '9841234567',
                      countryCode: _selectedCountryCode,
                      onCountryCodeTap: _openCountryPicker,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                  const Gap(18),

                  // Password Input Field
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hintText: 'Enter your password',
                    isPassword: true,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icon(
                      LucideIcons.lock,
                      size: 20,
                      color: colors.darkText,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const Gap(10),

                  // Forgot Password Link -> opens ForgotPasswordSheet
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: _openForgotPassword,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Gap(22),

                  // Primary Login Button
                  AppPrimaryButton(
                    text: 'Login',
                    isLoading: _isLoading,
                    onPressed: _isLocked ? null : _handleLogin,
                  ),
                  const Gap(20),

                  // OR Divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: colors.inputBorder.withValues(alpha: 0.3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.inputLabel.withValues(alpha: 0.75),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: colors.inputBorder.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                  const Gap(20),

                  // Continue with Google Button (using official Google SVG from svgl.app)
                  AppOutlinedButton(
                    text: 'Continue with Google',
                    isLoading: _isGoogleLoading,
                    icon: SvgPicture.asset(
                      'assets/icons/google.svg',
                      width: 20,
                      height: 20,
                    ),
                    onPressed: _isLocked ? null : _handleGoogleSignIn,
                  ),
                  const Gap(28),

                  // Bottom Footer: Don't have an account? Create Account
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: colors.inputLabel,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        InkWell(
                          onTap: _isLocked
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterScreen(),
                                    ),
                                  );
                                },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: Text(
                              'Create Account',
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
      ),
    );
  }
}
