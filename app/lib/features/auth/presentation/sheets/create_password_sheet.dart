import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';

/// Clean bottom sheet for creating/resetting a password.
class CreatePasswordSheet extends StatefulWidget {
  const CreatePasswordSheet({
    super.key,
    required this.onPasswordCreated,
  });

  final void Function(String password) onPasswordCreated;

  static Future<bool?> show(
    BuildContext context, {
    required void Function(String password) onPasswordCreated,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CreatePasswordSheet(
          onPasswordCreated: onPasswordCreated,
        ),
      ),
    );
  }

  @override
  State<CreatePasswordSheet> createState() => _CreatePasswordSheetState();
}

class _CreatePasswordSheetState extends State<CreatePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pop(true);
          widget.onPasswordCreated(_newPasswordController.text);
        }
      });
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
                      'Create New Password',
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
                'Please set a secure password for your pasal365 account.',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.inputLabel,
                  height: 1.4,
                ),
              ),
              const Gap(22),

              // New Password
              AuthTextField(
                controller: _newPasswordController,
                label: 'New Password',
                hintText: 'Enter new password',
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
              const Gap(16),

              // Confirm Password
              AuthTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hintText: 'Re-enter your password',
                isPassword: true,
                prefixIcon: Icon(
                  LucideIcons.lock,
                  size: 20,
                  color: colors.darkText,
                ),
                validator: (val) {
                  if (val != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const Gap(22),

              // Primary Button
              AppPrimaryButton(
                text: 'Save Password',
                isLoading: _isLoading,
                onPressed: _handleSubmit,
              ),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }
}

