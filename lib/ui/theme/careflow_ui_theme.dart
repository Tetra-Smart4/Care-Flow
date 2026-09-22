import 'package:flutter/material.dart';

class CareFlowUIColors {
  CareFlowUIColors._();

  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const teal = Color(0xFF0F9D8A);
  static const background = Color(0xFFF6F8FC);
  static const surface = Colors.white;
  static const text = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE6EAF0);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
  static const softBlue = Color(0xFFEAF2FF);
  static const softTeal = Color(0xFFE8F8F5);
  static const softOrange = Color(0xFFFFF3E7);
  static const softPurple = Color(0xFFF2EEFF);
}

class CareFlowUITheme {
  CareFlowUITheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: CareFlowUIColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: CareFlowUIColors.primary,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CareFlowUIColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: CareFlowUIColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
  }
}
