import 'package:flutter/material.dart';

/// App color palette definition.
class AppColors {
  AppColors._();

  /// Background: #FFFFFF (White)
  static const Color background = Color(0xFFFFFFFF);

  /// Primary blue: #2563EB (Clean, professional, non-neon royal blue)
  static const Color primary = Color(0xFF2563EB);

  /// Deep blue cards: #1E3A8A (Subdued, elegant navy)
  static const Color deepBlueCards = Color(0xFF1E3A8A);

  /// Input border: #CBD5E1
  static const Color inputBorder = Color(0xFFCBD5E1);

  /// Input label: #64748B
  static const Color inputLabel = Color(0xFF64748B);

  /// Soft Teal / secondary: #0D9488
  static const Color lightTeal = Color(0xFF0D9488);

  /// Dark text: #0F172A
  static const Color darkText = Color(0xFF0F172A);

  /// Secondary surface: #F8FAFC
  static const Color secondarySurface = Color(0xFFF8FAFC);
}

/// ThemeExtension to access custom palette tokens via `Theme.of(context).extension<AppColorsExtension>()`
/// or convenient extension on [BuildContext].
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.background,
    required this.primary,
    required this.deepBlueCards,
    required this.inputBorder,
    required this.inputLabel,
    required this.lightTeal,
    required this.darkText,
    required this.secondarySurface,
  });

  final Color background;
  final Color primary;
  final Color deepBlueCards;
  final Color inputBorder;
  final Color inputLabel;
  final Color lightTeal;
  final Color darkText;
  final Color secondarySurface;

  static const light = AppColorsExtension(
    background: AppColors.background,
    primary: AppColors.primary,
    deepBlueCards: AppColors.deepBlueCards,
    inputBorder: AppColors.inputBorder,
    inputLabel: AppColors.inputLabel,
    lightTeal: AppColors.lightTeal,
    darkText: AppColors.darkText,
    secondarySurface: AppColors.secondarySurface,
  );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? primary,
    Color? deepBlueCards,
    Color? inputBorder,
    Color? inputLabel,
    Color? lightTeal,
    Color? darkText,
    Color? secondarySurface,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      primary: primary ?? this.primary,
      deepBlueCards: deepBlueCards ?? this.deepBlueCards,
      inputBorder: inputBorder ?? this.inputBorder,
      inputLabel: inputLabel ?? this.inputLabel,
      lightTeal: lightTeal ?? this.lightTeal,
      darkText: darkText ?? this.darkText,
      secondarySurface: secondarySurface ?? this.secondarySurface,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      deepBlueCards: Color.lerp(deepBlueCards, other.deepBlueCards, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      inputLabel: Color.lerp(inputLabel, other.inputLabel, t)!,
      lightTeal: Color.lerp(lightTeal, other.lightTeal, t)!,
      darkText: Color.lerp(darkText, other.darkText, t)!,
      secondarySurface: Color.lerp(secondarySurface, other.secondarySurface, t)!,
    );
  }
}

extension AppColorsBuildContextExtension on BuildContext {
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light;
}

