import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';

/// Bottom sheet dialog for resetting account password via Resend email OTP.
class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({
    super.key,
    this.initialEmail = '',
  });

  final String initialEmail;

  static Future<void> show(
    BuildContext context, {
    String initialEmail = '',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ForgotPasswordSheet(
          initialEmail: initialEmail,
        ),
      ),
    );
  }

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    final res = await AuthService().forgotPassword(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : 'Reset code sent to your email!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : 'Could not find account with that email.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text;

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit reset code')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await AuthService().resetPassword(
      email: email,
      otp: otp,
      password: newPassword,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : 'Password reset successfully! You are now logged in.'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : 'Password reset failed. Invalid or expired code.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.inputBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(18),

              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _otpSent ? 'Reset Your Password' : 'Forgot Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.darkText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: colors.inputLabel,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const Gap(6),
              Text(
                _otpSent
                    ? 'Enter the 6-digit PIN sent to ${_emailController.text.trim()} and choose a new password.'
                    : 'Enter your registered email address to receive password reset instructions.',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.inputLabel,
                  height: 1.4,
                ),
              ),
              const Gap(22),

              if (!_otpSent) ...[
                // Email Input
                AuthTextField(
                  controller: _emailController,
                  label: 'Registered Email',
                  hintText: 'name@example.com',
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
                const Gap(20),

                // Send Reset Code Button
                AppPrimaryButton(
                  text: 'Send Reset Code',
                  isLoading: _isLoading,
                  onPressed: _handleSendResetCode,
                ),
              ] else ...[
                // 6-digit OTP Input
                AuthTextField(
                  controller: _otpController,
                  label: '6-Digit Reset PIN',
                  hintText: 'Enter 6-digit code',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icon(
                    LucideIcons.keyRound,
                    size: 20,
                    color: colors.darkText,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length != 6) {
                      return 'Please enter the 6-digit code';
                    }
                    return null;
                  },
                ),
                const Gap(16),

                // New Password Input
                AuthTextField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  hintText: 'Min 6 characters',
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
                const Gap(22),

                // Reset Password Button
                AppPrimaryButton(
                  text: 'Update Password & Login',
                  isLoading: _isLoading,
                  onPressed: _handleResetPassword,
                ),
              ],
              const Gap(16),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
