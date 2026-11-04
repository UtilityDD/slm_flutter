import 'package:flutter/material.dart';

import 'app_colors.dart';

const _latinDigits = [FontFeature.localeAware(enable: false)];

const banglaFont = 'Noto Sans Bengali';

TextStyle bangla({
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
  double? height,
}) {
  return TextStyle(
    fontFamily: banglaFont,
    fontFamilyFallback: const ['Roboto', 'Noto Sans', banglaFont],
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height ?? 1.45,
    fontFeatures: _latinDigits,
  );
}

class AppTheme {
  /// Built once on first use. The app is light-only (no dark theme), which
  /// also saves a second ThemeData + ColorScheme.fromSeed before the first frame.
  static final ThemeData lightTheme = _theme();

  static ThemeData _theme() {
    const ink = AppColors.slate900;
    const body = AppColors.slate800;
    const soft = AppColors.slate700;
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = base.textTheme.apply(fontFamily: banglaFont).copyWith(
          displayLarge: bangla(fontSize: 28, fontWeight: FontWeight.w600, color: ink),
          displayMedium: bangla(fontSize: 24, fontWeight: FontWeight.w600, color: ink),
          headlineMedium: bangla(fontSize: 20, fontWeight: FontWeight.w600, color: ink),
          headlineSmall: bangla(fontSize: 18, fontWeight: FontWeight.w600, color: ink),
          titleLarge: bangla(fontSize: 18, fontWeight: FontWeight.w600, color: ink),
          titleMedium: bangla(fontSize: 16, fontWeight: FontWeight.w500, color: ink),
          titleSmall: bangla(fontSize: 14, fontWeight: FontWeight.w500, color: ink),
          bodyLarge: bangla(fontSize: 16, fontWeight: FontWeight.w400, color: ink, height: 1.55),
          bodyMedium: bangla(fontSize: 15, fontWeight: FontWeight.w400, color: body, height: 1.55),
          bodySmall: bangla(fontSize: 13, fontWeight: FontWeight.w400, color: soft, height: 1.5),
          labelLarge: bangla(fontSize: 15, fontWeight: FontWeight.w600, color: ink),
          labelMedium: bangla(fontSize: 13, fontWeight: FontWeight.w500, color: ink),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryAmber,
        brightness: Brightness.light,
        primary: AppColors.primaryAmber,
        secondary: AppColors.safetyOrange,
        surface: Colors.white,
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: bangla(fontSize: 18, fontWeight: FontWeight.w600, color: ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: bangla(fontSize: 16, fontWeight: FontWeight.w600, color: ink),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: bangla(fontSize: 15, fontWeight: FontWeight.w600, color: ink),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: bangla(fontSize: 15, fontWeight: FontWeight.w500, color: ink),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return bangla(
            fontSize: selected ? 13 : 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? ink : soft,
          );
        }),
      ),
    );
  }
}
