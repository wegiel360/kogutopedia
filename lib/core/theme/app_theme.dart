import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.exo2(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.exo2(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.exo2(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.exo2(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.exo2(
          fontSize: 16,
          height: 1.6,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.exo2(
          fontSize: 16,
          height: 1.6,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.exo2(
          fontSize: 14,
          color: AppColors.textMuted,
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          color: AppColors.textMuted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: AppColors.accent.withOpacity(0.15),
          foregroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: AppColors.borderGlow,
              width: 1,
            ),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.borderGlow,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.borderGlow.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.accent,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.exo2(color: AppColors.textMuted),
        hintStyle: GoogleFonts.exo2(color: AppColors.textMuted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.glass,
        selectedColor: AppColors.accent.withOpacity(0.2),
        labelStyle: GoogleFonts.exo2(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderGlow, width: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
      ),
      dividerColor: AppColors.borderGlow.withOpacity(0.3),
      cardTheme: CardThemeData(
        color: AppColors.glass,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderGlow, width: 0.5),
        ),
      ),
    );
  }
}
