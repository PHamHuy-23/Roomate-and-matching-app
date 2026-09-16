import 'package:flutter/material.dart';

abstract final class RoommateHubColors {
  static const Color canvas = Color(0xFFF5F8F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF142523);
  static const Color textSecondary = Color(0xFF52625F);
  static const Color border = Color(0xFFDCE6E3);
  static const Color primary = Color(0xFF087E6B);
  static const Color primaryContainer = Color(0xFFEAF8F5);
  static const Color primaryContainerStrong = Color(0xFFCDEFE7);
  static const Color accent = Color(0xFFF36F56);
  static const Color accentContainer = Color(0xFFFFF1ED);
  static const Color success = Color(0xFF2E9C65);
  static const Color warning = Color(0xFFE99A21);
  static const Color danger = Color(0xFFD9485F);
}

abstract final class RoommateHubSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class RoommateHubRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}

abstract final class RoommateHubTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: RoommateHubColors.primary,
      onPrimary: Colors.white,
      primaryContainer: RoommateHubColors.primaryContainer,
      onPrimaryContainer: RoommateHubColors.primary,
      secondary: RoommateHubColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: RoommateHubColors.accentContainer,
      onSecondaryContainer: RoommateHubColors.danger,
      error: RoommateHubColors.danger,
      onError: Colors.white,
      surface: RoommateHubColors.surface,
      onSurface: RoommateHubColors.ink,
      outline: RoommateHubColors.border,
    );

    const textTheme = TextTheme(
      displaySmall: TextStyle(
        fontSize: 32,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: RoommateHubColors.ink,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        height: 1.33,
        fontWeight: FontWeight.w700,
        color: RoommateHubColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: RoommateHubColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: RoommateHubColors.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.57,
        color: RoommateHubColors.ink,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.5,
        color: RoommateHubColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: RoommateHubColors.canvas,
      fontFamily: 'Be Vietnam Pro',
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: RoommateHubColors.canvas,
        foregroundColor: RoommateHubColors.ink,
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: RoommateHubColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(RoommateHubRadius.lg)),
          side: BorderSide(color: RoommateHubColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RoommateHubRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          side: const BorderSide(color: RoommateHubColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RoommateHubRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: RoommateHubColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(RoommateHubRadius.md)),
          borderSide: BorderSide(color: RoommateHubColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(RoommateHubRadius.md)),
          borderSide: BorderSide(color: RoommateHubColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(RoommateHubRadius.md)),
          borderSide: BorderSide(color: RoommateHubColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(RoommateHubRadius.md)),
          borderSide: BorderSide(color: RoommateHubColors.danger),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: RoommateHubColors.surface,
        indicatorColor: RoommateHubColors.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: RoommateHubColors.ink,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
