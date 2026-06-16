import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Editorial typography stack from the App Design v2.0 prototype:
/// - Fraunces (serif, often italic) — headlines, scores, accent words
/// - DM Sans (sans) — body
/// - Bebas Neue — score pads, team codes, scoring buttons
/// - JetBrains Mono — labels, meta, captions (uppercase + letter-spacing)
class AppTextStyles {
  AppTextStyles._();

  // Fraunces — serif headlines
  static TextStyle fraunces({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.ink,
    double letterSpacing = -0.01,
    bool italic = false,
    double height = 1.15,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        height: height,
      );

  // DM Sans — body
  static TextStyle dm({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double letterSpacing = 0,
    double height = 1.4,
  }) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  // Bebas Neue — display numerics
  static TextStyle bebas({
    double size = 16,
    Color color = AppColors.ink,
    double letterSpacing = 0.08,
  }) =>
      GoogleFonts.bebasNeue(
        fontSize: size,
        color: color,
        letterSpacing: letterSpacing,
      );

  // JetBrains Mono — labels (usually uppercase with letter-spacing)
  static TextStyle mono({
    double size = 10,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.grey,
    double letterSpacing = 0.2,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  // Common named slots
  static TextStyle get displayLarge =>
      fraunces(size: 38, weight: FontWeight.w900, color: AppColors.navyDeep);
  static TextStyle get displayMedium =>
      fraunces(size: 28, weight: FontWeight.w900, color: AppColors.navyDeep);
  static TextStyle get headlineLarge =>
      fraunces(size: 24, weight: FontWeight.w700, color: AppColors.navyDeep);
  static TextStyle get headlineMedium =>
      fraunces(size: 20, weight: FontWeight.w700, color: AppColors.navyDeep);
  static TextStyle get titleLarge =>
      fraunces(size: 18, weight: FontWeight.w700, color: AppColors.ink);
  static TextStyle get titleMedium => dm(size: 15, weight: FontWeight.w600);

  static TextStyle get bodyLarge => dm(size: 15);
  static TextStyle get bodyMedium => dm(size: 14);
  static TextStyle get bodySmall => dm(size: 12, color: AppColors.grey);

  static TextStyle get labelLarge => mono(
      size: 11,
      weight: FontWeight.w700,
      color: AppColors.ink,
      letterSpacing: 0.18);
  static TextStyle get caption =>
      mono(size: 10, color: AppColors.grey, letterSpacing: 0.25);

  static TextStyle get button => GoogleFonts.bebasNeue(
        fontSize: 17,
        color: Colors.white,
        letterSpacing: 0.1,
      );

  static TextStyle get scoreLarge => fraunces(
      size: 42,
      weight: FontWeight.w900,
      color: AppColors.cream,
      letterSpacing: -0.02);
  static TextStyle get scoreMedium =>
      fraunces(size: 24, weight: FontWeight.w900, color: AppColors.navyDeep);

  static TextStyle get teamCode =>
      bebas(size: 15, color: Colors.white, letterSpacing: 0.04);

  // Section number ribbons "01 — Entry"
  static TextStyle get sectionNum => mono(
      size: 11,
      weight: FontWeight.w400,
      color: AppColors.goldDeep,
      letterSpacing: 0.3);

  // Italic Fraunces accent words (the gold em)
  static TextStyle italicAccent(
          {double size = 22, Color color = AppColors.goldDeep}) =>
      fraunces(size: size, weight: FontWeight.w400, italic: true, color: color);
}
