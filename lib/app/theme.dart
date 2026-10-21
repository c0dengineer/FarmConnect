import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF033621);
  static const primaryDark = Color(0xFF002112);
  static const primarySoft = Color(0xFFE5EEE5);
  static const accent = Color(0xFF9C431D);
  static const accentSoft = Color(0xFFFFDBCE);
  static const bg = Color(0xFFFCF9F4);
  static const text = Color(0xFF1C1C19);
  static const muted = Color(0xFF414943);
  static const border = Color(0xFFC0C9C1);
  static const danger = Color(0xFFD64545);
  static const info = Color(0xFF2563EB);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(primary: AppColors.primary);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: AppColors.bg);
    final radius = BorderRadius.circular(14);
    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c, width: w));

    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme)
          .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.primary, 1.6),
        errorBorder: border(AppColors.danger),
        focusedErrorBorder: border(AppColors.danger, 1.6),
        labelStyle: const TextStyle(color: AppColors.muted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primarySoft,
        elevation: 0,
        height: 66,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
    );
  }
}
