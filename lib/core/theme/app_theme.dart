import 'package:flutter/material.dart';
import 'app_colors.dart';

const banglaFont = 'Noto Sans Bengali';

TextStyle bangla({
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
  double? height,
}) {
  return TextStyle(
    fontFamily: banglaFont,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

class AppTheme {
  static ThemeData get lightTheme => _theme(Brightness.light);

  static ThemeData get darkTheme => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.slate900;
    final body = dark ? Colors.white70 : AppColors.slate800;
    final soft = dark ? Colors.white60 : AppColors.slate700;
    final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
    final textTheme = base.textTheme.apply(fontFamily: banglaFont).copyWith(
          displayLarge: bangla(fontSize: 30, fontWeight: FontWeight.w800, color: ink),
          displayMedium: bangla(fontSize: 26, fontWeight: FontWeight.w800, color: ink),
          headlineMedium: bangla(fontSize: 22, fontWeight: FontWeight.w700, color: ink),
          headlineSmall: bangla(fontSize: 20, fontWeight: FontWeight.w700, color: ink),
          titleLarge: bangla(fontSize: 19, fontWeight: FontWeight.w700, color: ink),
          titleMedium: bangla(fontSize: 17, fontWeight: FontWeight.w600, color: ink),
          titleSmall: bangla(fontSize: 15, fontWeight: FontWeight.w600, color: dark ? Colors.white70 : ink),
          bodyLarge: bangla(fontSize: 17, fontWeight: FontWeight.w500, color: dark ? Colors.white : ink, height: 1.45),
          bodyMedium: bangla(fontSize: 15, fontWeight: FontWeight.w400, color: body, height: 1.45),
          bodySmall: bangla(fontSize: 13, fontWeight: FontWeight.w400, color: soft),
          labelLarge: bangla(fontSize: 16, fontWeight: FontWeight.w700, color: ink),
          labelMedium: bangla(fontSize: 14, fontWeight: FontWeight.w600, color: dark ? Colors.white70 : ink),
        );

    return base.copyWith(
      scaffoldBackgroundColor: dark ? AppColors.slate900 : AppColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryAmber,
        brightness: brightness,
        primary: AppColors.primaryAmber,
        secondary: AppColors.safetyOrange,
        surface: dark ? AppColors.slate800 : Colors.white,
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.slate900 : AppColors.cream,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: bangla(fontSize: 20, fontWeight: FontWeight.w800, color: ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: bangla(fontSize: 17, fontWeight: FontWeight.w700, color: ink),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: bangla(fontSize: 16, fontWeight: FontWeight.w800, color: ink),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: bangla(fontSize: 15, fontWeight: FontWeight.w700, color: ink),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return bangla(
            fontSize: selected ? 13 : 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? ink : soft,
          );
        }),
      ),
    );
  }
}
