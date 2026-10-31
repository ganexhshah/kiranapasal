import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';

/// Clean bottom sheet for entering and verifying 6-digit OTP code sent via Resend.
class VerifyOtpSheet extends StatefulWidget {
  const VerifyOtpSheet({
    super.key,
    required this.email,
    required this.onVerified,
  });

  /// The email address the OTP was sent to via Resend.
  final String email;
  final VoidCallback onVerified;

  static Future<bool?> show(
    BuildContext context, {
    required String email,
    required VoidCallback onVerified,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      // Verification must not be abandoned by a stray tap: the account already
      // exists on the server and the user would be stranded unverified. The
      // sheet has its own close button for a deliberate exit.
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: VerifyOtpSheet(
          email: email,
          onVerified: onVerified,
        ),
      ),
    );
  }

  @override
  State<VerifyOtpSheet> createState() => _VerifyOtpSheetState();
}

class _VerifyOtpSheetState extends State<VerifyOtpSheet> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendSeconds = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        if (mounted) setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final res = await AuthService().verifyOtp(
      email: widget.email,
      otp: _otpController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : 'Email verified successfully!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onVerified();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : 'Invalid or expired OTP code.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleResend() async {
    if (_resendSeconds > 0 || _isResending) return;

    setState(() => _isResending = true);
    final res = await AuthService().resendOtp(email: widget.email);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (res.success) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : 'New code sent to your email.'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : 'Could not resend code. Please try again.'),
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

              // Title row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Verify OTP Code',
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
                'We have sent a 6-digit verification code to ${widget.email}. Check your inbox or spam folder.',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.inputLabel,
                  height: 1.4,
                ),
              ),
              const Gap(22),

              // Reusable OTP Input Field with animated floating notch
              AuthTextField(
                controller: _otpController,
                label: 'OTP Code',
                hintText: 'Enter 6-digit code',
                keyboardType: TextInputType.number,
                prefixIcon: Icon(
                  LucideIcons.keyRound,
                  size: 20,
                  color: colors.darkText,
                ),
                validator: (val) {
                  if (val == null || val.trim().length != 6) {
                    return 'Please enter the 6-digit verification code';
                  }
                  return null;
                },
              ),
              const Gap(14),

              // Resend Countdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _resendSeconds > 0
                        ? 'Resend code in 0:${_resendSeconds.toString().padLeft(2, '0')}'
                        : "Didn't receive code?",
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.inputLabel,
                    ),
                  ),
                  if (_resendSeconds == 0)
                    InkWell(
                      onTap: _isResending ? null : _handleResend,
                      child: Text(
                        _isResending ? 'Sending...' : 'Resend OTP',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const Gap(22),

              // Primary Button
              AppPrimaryButton(
                text: 'Verify Code',
                isLoading: _isLoading,
                onPressed: _handleVerify,
              ),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }
}
