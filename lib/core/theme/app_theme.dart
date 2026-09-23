import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const primary = Color(0xFFD32F2F);
  static const primaryLight = Color(0xFFFFEBEE);
  static const primaryDark = Color(0xFFB71C1C);
  static const secondary = Color(0xFF1565C0);
  static const secondaryLight = Color(0xFFE3F2FD);
  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFFE8F5E9);
  static const warning = Color(0xFFF57F17);
  static const warningLight = Color(0xFFFFF8E1);
  static const error = Color(0xFFC62828);
  static const errorLight = Color(0xFFFFEBEE);
  static const info = Color(0xFF01579B);
  static const infoLight = Color(0xFFE1F5FE);
  static const background = Color(0xFFF5F6FA);
  static const surface = Color(0xFFFFFFFF);
  static const cardBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0D1117);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFFB0B8C4);
  static const border = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFF3F4F6);
  static const inputFill = Color(0xFFF8F9FC);
  static const shadow = Color(0x14000000);

  static const riskCritical = Color(0xFFB71C1C);
  static const riskHigh = Color(0xFFD32F2F);
  static const riskMedium = Color(0xFFF57F17);
  static const riskLow = Color(0xFF2E7D32);

  static const List<Color> chartColors = [
    Color(0xFFD32F2F),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFF57F17),
    Color(0xFF7B1FA2),
    Color(0xFF00838F),
  ];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFF57F17), Color(0xFFE65100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTextStyles {
  static const String _font = 'Roboto';

  static const h1 = TextStyle(fontFamily: _font, fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2, letterSpacing: -0.5);
  static const h2 = TextStyle(fontFamily: _font, fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.25);
  static const h3 = TextStyle(fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3);
  static const h4 = TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.35);
  static const h5 = TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4);
  static const h6 = TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4);
  static const bodyLarge = TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5);
  static const bodyMedium = TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5);
  static const bodySmall = TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);
  static const caption = TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.4, letterSpacing: 0.2);
  static const button = TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2);
  static const label = TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.4);
  static const numeric = TextStyle(fontFamily: _font, fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.1, letterSpacing: -1.0);
  static const numericMd = TextStyle(fontFamily: _font, fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.1);
  static const overline = TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 1.2, height: 1.4);
}

ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary, secondary: AppColors.secondary, surface: AppColors.surface),
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 1,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    titleTextStyle: AppTextStyles.h5,
    centerTitle: false,
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardBg,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.borderLight)),
    margin: const EdgeInsets.symmetric(vertical: 4),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: AppTextStyles.button,
      elevation: 0,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.inputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
    labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
  ),
  dividerTheme: const DividerThemeData(color: AppColors.borderLight, thickness: 1, space: 1),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: AppColors.surface, selectedItemColor: AppColors.primary, unselectedItemColor: AppColors.textSecondary, type: BottomNavigationBarType.fixed, elevation: 8),
  chipTheme: ChipThemeData(backgroundColor: AppColors.primaryLight, labelStyle: AppTextStyles.caption, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), side: BorderSide.none),
  snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
  bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
);
