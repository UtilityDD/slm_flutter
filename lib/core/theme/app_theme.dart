import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.slate50,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryAmber,
        primary: AppColors.primaryAmber,
        secondary: AppColors.safetyOrange,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.hindSiliguriTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.hindSiliguri(
          color: AppColors.slate900,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.slate900,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryAmber,
        brightness: Brightness.dark,
        primary: AppColors.primaryAmber,
        secondary: AppColors.safetyOrange,
        surface: AppColors.slate800,
      ),
      textTheme: GoogleFonts.hindSiliguriTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.slate900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.hindSiliguri(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}
