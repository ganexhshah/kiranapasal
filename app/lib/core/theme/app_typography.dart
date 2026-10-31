import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography configuration using Outfit as primary font, with Plus Jakarta Sans, Inter, and Devanagari fallbacks.
class AppTypography {
  AppTypography._();

  static String? get primaryFontFamily => GoogleFonts.outfit().fontFamily;
  static String? get outfitFontFamily => GoogleFonts.outfit().fontFamily;
  static String? get plusJakartaSansFontFamily => GoogleFonts.plusJakartaSans().fontFamily;
  static String? get interFontFamily => GoogleFonts.inter().fontFamily;
  static String? get devanagariFontFamily => GoogleFonts.notoSansDevanagari().fontFamily;

  static List<String> get fontFallbacks {
    final list = <String>[];
    if (plusJakartaSansFontFamily != null) list.add(plusJakartaSansFontFamily!);
    if (interFontFamily != null) list.add(interFontFamily!);
    if (devanagariFontFamily != null) list.add(devanagariFontFamily!);
    list.add('Noto Sans Devanagari');
    return list;
  }

  /// Builds a [TextTheme] styled with Outfit as primary font and Plus Jakarta Sans/Inter/Devanagari fallbacks.
  static TextTheme createTextTheme([TextTheme? base]) {
    final effectiveBase = base ?? ThemeData.light().textTheme;
    final primaryFamily = primaryFontFamily;
    final fallbacks = fontFallbacks;

    return effectiveBase
        .apply(
          fontFamily: primaryFamily,
          bodyColor: AppColors.darkText,
          displayColor: AppColors.darkText,
        )
        .copyWith(
      displayLarge: effectiveBase.displayLarge?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        color: AppColors.darkText,
      ),
      displayMedium: effectiveBase.displayMedium?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        color: AppColors.darkText,
      ),
      displaySmall: effectiveBase.displaySmall?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        color: AppColors.darkText,
      ),
      headlineLarge: effectiveBase.headlineLarge?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        color: AppColors.darkText,
      ),
      headlineMedium: effectiveBase.headlineMedium?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        color: AppColors.darkText,
      ),
      headlineSmall: effectiveBase.headlineSmall?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        color: AppColors.darkText,
      ),
      titleLarge: effectiveBase.titleLarge?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        color: AppColors.darkText,
      ),
      titleMedium: effectiveBase.titleMedium?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        color: AppColors.darkText,
      ),
      titleSmall: effectiveBase.titleSmall?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        color: AppColors.darkText,
      ),
      bodyLarge: effectiveBase.bodyLarge?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        color: AppColors.darkText,
      ),
      bodyMedium: effectiveBase.bodyMedium?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        color: AppColors.darkText,
      ),
      bodySmall: effectiveBase.bodySmall?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        color: AppColors.darkText,
      ),
      labelLarge: effectiveBase.labelLarge?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        color: AppColors.darkText,
      ),
      labelMedium: effectiveBase.labelMedium?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        color: AppColors.darkText,
      ),
      labelSmall: effectiveBase.labelSmall?.copyWith(
        fontFamily: primaryFamily,
        fontFamilyFallback: fallbacks,
        color: AppColors.darkText,
      ),
    );
  }
}

