import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens lifted from the Stitch "Daily Budget Tracker" (Raw Ledger) project.
/// Neo-Brutalist aesthetic: sharp corners (0px), 2-4px black borders, hard offset shadows,
/// Anton display typography, and Archivo Narrow body/labels.
class AppColors {
  AppColors._();

  // Raw Ledger Palette
  static const bgLight = Color(0xFFF9F9F9); // Base canvas
  static const surfaceWhite = Color(0xFFFFFFFF); // Stark white card surface
  static const cardBg = Color(0xFFFFFFFF); // Card background alias
  static const surfaceContainer = Color(0xFFEEEEEE); // Neutral container
  static const surfaceVariant = Color(0xFFE2E2E2); // Container highest
  static const surfaceDim = Color(0xFFDADADA);

  static const primaryRed = Color(0xFFBC0100); // Primary brand red
  static const primaryContainer = Color(0xFFEB0000);
  static const primaryDark = Color(0xFF930100);
  static const onPrimary = Color(0xFFFFFFFF);

  static const borderBlack = Color(0xFF1A1C1C); // Hard brutal borders
  static const onBackground = Color(0xFF1A1C1C);
  static const textPrimary = Color(0xFF1A1C1C);
  static const textSecondary = Color(0xFF5E5E5E);
  static const textMuted = Color(0xFF646464);

  static const alertYellow = Color(0xFFFFEB3B); // Accent yellow for subscriptions / alerts
  static const alertYellowBorder = Color(0xFF1A1C1C);

  static const successGreen = Color(0xFF00AA00);
  static const blueAccent = Color(0xFF0059BA);

  // Backward compatibility alias colors
  static const bgBlack = Color(0xFF1A1C1C);
  static const bgSurface = Color(0xFFFFFFFF);
  static const bgSurface2 = Color(0xFFEEEEEE);
  static const borderSubtle = Color(0xFF1A1C1C);
  static const borderFaint = Color(0xFF1A1C1C);
  static const gold = Color(0xFFBC0100); // Mapped to primary red
  static const red = Color(0xFFBC0100);
  static const green = Color(0xFF00AA00);
  static const textGhost = Color(0xFF888888);
  static const textDark = Color(0xFF1A1C1C);
  static const textFaint = Color(0xFF5E5E5E);

  static Color goldDim = const Color(0xFFBC0100).withValues(alpha: 0.2);
  static Color goldHalf = const Color(0xFFBC0100).withValues(alpha: 0.5);
  static Color goldBorder = const Color(0xFF1A1C1C);
  static Color goldTint12 = const Color(0xFFBC0100).withValues(alpha: 0.12);
  static Color goldTint10 = const Color(0xFFBC0100).withValues(alpha: 0.10);
  static Color goldRing = const Color(0xFFBC0100);
  static Color goldCell = const Color(0xFFBC0100).withValues(alpha: 0.15);
  static Color redCell = const Color(0xFFBC0100).withValues(alpha: 0.2);
}

/// Hard brutal shadows without blur
class AppShadows {
  AppShadows._();

  static const brutalBlack = [
    BoxShadow(
      color: Color(0xFF1A1C1C),
      offset: Offset(4, 4),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static const brutalBlackSm = [
    BoxShadow(
      color: Color(0xFF1A1C1C),
      offset: Offset(2, 2),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static const brutalRed = [
    BoxShadow(
      color: Color(0xFFBC0100),
      offset: Offset(4, 4),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static const brutalRedSm = [
    BoxShadow(
      color: Color(0xFFBC0100),
      offset: Offset(2, 2),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];
}

/// Raw Ledger typography: Anton (Headlines / Currency) & Archivo Narrow (Body / Labels)
class AppText {
  AppText._();

  // Big currency numbers (Anton)
  static TextStyle displayCurrency(double size,
          {Color color = AppColors.textPrimary}) =>
      GoogleFonts.anton(
        fontSize: size,
        color: color,
        letterSpacing: -0.02,
        height: 1.0,
      );

  static TextStyle headlineLg({Color color = AppColors.textPrimary}) =>
      GoogleFonts.anton(
        fontSize: 34,
        color: color,
        letterSpacing: -0.02,
        height: 1.1,
      );

  static TextStyle headlineMd({Color color = AppColors.textPrimary}) =>
      GoogleFonts.anton(
        fontSize: 26,
        color: color,
        letterSpacing: -0.01,
        height: 1.1,
      );

  static TextStyle headlineSm({Color color = AppColors.textPrimary}) =>
      GoogleFonts.anton(
        fontSize: 20,
        color: color,
        letterSpacing: 0,
        height: 1.1,
      );

  static TextStyle displaySm({Color color = AppColors.textPrimary}) =>
      GoogleFonts.anton(
        fontSize: 26,
        color: color,
        letterSpacing: -0.01,
        height: 1.1,
      );

  // Body & Labels (Archivo Narrow)
  static TextStyle bodyLg(
          {Color color = AppColors.textPrimary,
          FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.archivoNarrow(
        fontSize: 17,
        color: color,
        fontWeight: weight,
        height: 1.25,
      );

  static TextStyle bodySm({Color color = AppColors.textSecondary}) =>
      GoogleFonts.archivoNarrow(
        fontSize: 13,
        color: color,
        fontWeight: FontWeight.w600,
        height: 1.25,
      );

  static TextStyle caption({Color color = AppColors.textSecondary}) =>
      GoogleFonts.archivoNarrow(
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );

  static TextStyle body(Color color, {FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.archivoNarrow(
        fontSize: 15,
        color: color,
        fontWeight: weight,
        height: 1.35,
      );

  static TextStyle labelBold(double size, Color color, {double? spacing}) =>
      GoogleFonts.archivoNarrow(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: spacing ?? 0.05,
      );

  static TextStyle label(double size, Color color, {FontWeight? weight}) =>
      GoogleFonts.archivoNarrow(
        fontSize: size,
        color: color,
        fontWeight: weight ?? FontWeight.w500,
      );

  // Compatibility helpers
  static TextStyle display(double size) => displayCurrency(size);
  static final cardHeading = labelBold(12, AppColors.textPrimary, spacing: 1.5);
  static final screenTitle = headlineMd(color: AppColors.primaryRed);
  static final sectionTitle = headlineSm(color: AppColors.textPrimary);
  static TextStyle dense(double size, Color color,
          {FontWeight? weight, double? spacing}) =>
      GoogleFonts.archivoNarrow(
        fontSize: size,
        color: color,
        fontWeight: weight ?? FontWeight.w700,
        letterSpacing: spacing,
      );
}
