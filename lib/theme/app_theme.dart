import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppColors — OKLCH design tokens translated to Flutter Color values
// Source: DESIGN.md (impostor-v2)
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Backgrounds
  static const bg        = Color(0xFF161616); // oklch(0.09 0 0)
  static const surface   = Color(0xFF242424); // oklch(0.14 0 0)
  static const surface2  = Color(0xFF2E2E2E); // oklch(0.18 0 0)
  static const border    = Color(0xFF3A3A3A); // oklch(0.22 0 0)

  // Brand — coral/orange primary
  static const primary    = Color(0xFFD95F38); // oklch(0.62 0.190 35°)
  static const primaryDim = Color(0xFFA3472A); // oklch(0.50 0.150 35°)

  // Brand — yellow-gold accent
  static const accent    = Color(0xFFDDBB18); // oklch(0.82 0.175 88°)
  static const accentDim = Color(0xFFA88E12); // oklch(0.70 0.130 88°)

  // Brand — teal tertiary
  static const tertiary  = Color(0xFF1AB8BC); // oklch(0.65 0.155 195°)

  // Text
  static const ink       = Color(0xFFF2F2F2); // oklch(0.95 0 0)
  static const muted     = Color(0xFF7F7F7F); // oklch(0.55 0 0)
  static const onPrimary = Color(0xFFFAFAFA);
  static const onAccent  = Color(0xFF161616);

  // Glows (for impostor reveal)
  static const glowPrimary = Color(0x73D95F38); // primary @ 45% opacity
  static const glowAccent  = Color(0x66DDBB18); // accent @ 40% opacity
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTextStyles — Syne (display) + DM Sans (body)
// ─────────────────────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  // Display / game headings — Syne
  static TextStyle hero({
    Color color = AppColors.ink,
    double fontSize = 72,
    FontWeight fontWeight = FontWeight.w800,
    double? height,
  }) => GoogleFonts.syne(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: -0.03 * fontSize,
    height: height ?? 1.05,
    color: color,
  );

  static TextStyle display({
    Color color = AppColors.ink,
    double fontSize = 48,
    FontWeight fontWeight = FontWeight.w800,
    double? height,
  }) => GoogleFonts.syne(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: -0.03 * fontSize,
    height: height ?? 1.1,
    color: color,
  );

  static TextStyle heading({
    Color color = AppColors.ink,
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
  }) => GoogleFonts.syne(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: -0.03 * fontSize,
    height: height ?? 1.2,
    color: color,
  );

  static TextStyle subheading({
    Color color = AppColors.ink,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
  }) => GoogleFonts.syne(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: -0.03 * fontSize,
    height: height ?? 1.25,
    color: color,
  );

  // Body — DM Sans
  static TextStyle body({
    Color color = AppColors.ink,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.5,
  }) => GoogleFonts.dmSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    color: color,
  );

  static TextStyle bodyMedium({
    Color color = AppColors.ink,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w500,
    double height = 1.5,
  }) => GoogleFonts.dmSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    color: color,
  );

  static TextStyle bodySemibold({
    Color color = AppColors.ink,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    double height = 1.5,
  }) => GoogleFonts.dmSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    color: color,
  );

  static TextStyle small({
    Color color = AppColors.muted,
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.4,
  }) => GoogleFonts.dmSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    color: color,
  );

  static TextStyle label({
    Color color = AppColors.muted,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    double height = 1.3,
  }) => GoogleFonts.dmSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: 0.08 * fontSize,
    height: height,
    color: color,
  );

  static TextStyle buttonLabel({
    Color color = AppColors.onPrimary,
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w600,
    double height = 1.2,
  }) => GoogleFonts.dmSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: 0.2,
    height: height,
    color: color,
  );

  static TextStyle timerDigits({
    Color color = AppColors.ink,
    double fontSize = 56,
  }) => GoogleFonts.dmSans(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    color: color,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.bg,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      tertiary: AppColors.tertiary,
      onPrimary: AppColors.onPrimary,
      onSurface: AppColors.ink,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
