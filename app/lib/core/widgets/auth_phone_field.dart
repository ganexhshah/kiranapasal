import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

/// Reusable phone number field with country code prefix and animated floating label notch.
class AuthPhoneField extends StatelessWidget {
  const AuthPhoneField({
    super.key,
    this.controller,
    this.label = 'Phone Number',
    this.hintText = '9841234567',
    this.countryCode = '+977',
    this.onCountryCodeTap,
    this.validator,
    this.onChanged,
    this.focusNode,
    this.enabled = true,
    this.floatingLabelBehavior = FloatingLabelBehavior.auto,
  });

  final TextEditingController? controller;
  final String label;
  final String hintText;
  final String countryCode;
  final VoidCallback? onCountryCodeTap;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final bool enabled;
  final FloatingLabelBehavior floatingLabelBehavior;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: colors.inputBorder.withValues(alpha: 0.2),
        width: 1.0,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: colors.primary.withValues(alpha: 0.8),
        width: 1.3,
      ),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Colors.redAccent,
        width: 1.2,
      ),
    );

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(
        color: colors.darkText,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        floatingLabelBehavior: floatingLabelBehavior,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(
          color: colors.inputLabel,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: TextStyle(
          color: colors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: colors.inputBorder.withValues(alpha: 0.85),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: InkWell(
          onTap: onCountryCodeTap,
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.only(left: 14, right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.smartphone,
                  size: 20,
                  color: colors.darkText,
                ),
                const Gap(8),
                Text(
                  countryCode,
                  style: TextStyle(
                    color: colors.darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(2),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: colors.darkText.withValues(alpha: 0.7),
                ),
                const Gap(8),
                Container(
                  width: 1.2,
                  height: 22,
                  color: colors.inputBorder.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 120,
          minHeight: 24,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder.copyWith(
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
      ),
    );
  }
}

