/// Design tokens ported 1:1 from the FireShield PWA
/// (pwa_app/tailwind.config.js + src/index.css).
///
/// Keep this file as the single source of truth — screens must not hardcode
/// colours. If the Tailwind config changes, change it here.
library;

import 'package:flutter/material.dart';

class FsColors {
  const FsColors._();

  // tailwind.config.js → theme.extend.colors
  static const primary = Color(0xFFD32F2F);
  static const primaryLight = Color(0xFFFFEBEE);
  static const primaryDark = Color(0xFFB71C1C);

  static const eyYellow = Color(0xFFFFE600);
  static const eyDark = Color(0xFF1A1A1A);

  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFFE8F5E9);
  static const warning = Color(0xFFF57F17);
  static const warningLight = Color(0xFFFFF8E1);
  static const danger = Color(0xFFC62828);
  static const dangerLight = Color(0xFFFFEBEE);
  static const info = Color(0xFF01579B);
  static const infoLight = Color(0xFFE1F5FE);

  static const surface = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F6FA);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E7EB);
  static const muted = Color(0xFF6B7280);
  static const subtle = Color(0xFF9CA3AF);

  // Splash / welcome / login use a brighter yellow than the EY brand token.
  static const heroYellow = Color(0xFFFACC15);
  static const ink = Color(0xFF111827);

  // Tailwind greys used across the dark screens.
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);

  // Badge pairs — Tailwind bg-*-100 / text-*-700.
  static const blue100 = Color(0xFFDBEAFE);
  static const blue700 = Color(0xFF1D4ED8);
  static const purple100 = Color(0xFFF3E8FF);
  static const purple700 = Color(0xFF7E22CE);
  static const amber100 = Color(0xFFFEF3C7);
  static const amber700 = Color(0xFFB45309);
  static const green100 = Color(0xFFDCFCE7);
  static const green700 = Color(0xFF15803D);
  static const red100 = Color(0xFFFEE2E2);
  static const red700 = Color(0xFFB91C1C);
  static const orange100 = Color(0xFFFFEDD5);
  static const orange700 = Color(0xFFC2410C);
  static const gray100 = Color(0xFFF3F4F6);

  // Risk dots.
  static const red600 = Color(0xFFDC2626);
  static const red400 = Color(0xFFF87171);
  static const amber400 = Color(0xFFFBBF24);
  static const green500 = Color(0xFF22C55E);

  // Role accents from LoginScreen roleConfig.
  static const roleManager = Color(0xFF2563EB); // bg-blue-600
  static const roleAuditor = Color(0xFFDC2626); // bg-red-600
  static const roleAdmin = Color(0xFF9333EA); // bg-purple-600
  static const roleOrgAdmin = Color(0xFF059669); // bg-emerald-600

  /// linear-gradient(160deg,#0f0f1a 0%,#1a1225 50-60%,#0d1117 100%)
  static const darkGradient = LinearGradient(
    begin: Alignment(-0.34, -1),
    end: Alignment(0.34, 1),
    colors: [Color(0xFF0F0F1A), Color(0xFF1A1225), Color(0xFF0D1117)],
    stops: [0.0, 0.55, 1.0],
  );

  /// linear-gradient(135deg,#D32F2F,#B71C1C) — the flame tile.
  static const flameGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
}

class FsRadius {
  const FsRadius._();

  static const xl = 12.0;
  static const xl2 = 16.0; // rounded-2xl
  static const xl3 = 24.0; // rounded-3xl
  static const xl4 = 32.0; // rounded-4xl
  static const full = 999.0;
}

class FsShadows {
  const FsShadows._();

  /// shadow-card
  static const card = [
    BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// shadow-card-md
  static const cardMd = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// shadow-bottom
  static const bottom = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -2)),
  ];
}

/// Type scale. The PWA uses Inter; the app ships without it, so this falls
/// back to the platform sans. Add Inter to pubspec assets and set
/// [FsText.family] to 'Inter' to match the web exactly.
class FsText {
  const FsText._();

  static const String? family = null;

  static const h1 = TextStyle(
      fontFamily: family,
      fontSize: 30,
      fontWeight: FontWeight.w900,
      height: 1.15,
      letterSpacing: -0.6);
  static const h2 = TextStyle(
      fontFamily: family,
      fontSize: 24,
      fontWeight: FontWeight.w900,
      height: 1.2,
      letterSpacing: -0.4);
  static const title = TextStyle(
      fontFamily: family,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: FsColors.gray900);
  static const cardTitle = TextStyle(
      fontFamily: family,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1F2937));
  static const body = TextStyle(
      fontFamily: family, fontSize: 14, height: 1.5, color: FsColors.gray900);
  static const small = TextStyle(
      fontFamily: family, fontSize: 12, height: 1.5, color: FsColors.muted);
  static const xs = TextStyle(
      fontFamily: family, fontSize: 11, height: 1.45, color: FsColors.muted);
  static const tiny = TextStyle(
      fontFamily: family, fontSize: 10, height: 1.4, color: FsColors.muted);
  static const micro = TextStyle(
      fontFamily: family, fontSize: 9, height: 1.35, color: FsColors.muted);
  static const kpiValue = TextStyle(
      fontFamily: family,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.0,
      color: FsColors.gray900);
}

/// MaterialApp theme matching the PWA shell.
ThemeData buildFireShieldTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: FsColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: FsColors.primary,
      surface: FsColors.surface,
      error: FsColors.danger,
    ),
    textTheme: base.textTheme.apply(fontFamily: FsText.family),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
