import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens lifted directly from the hi-fi design reference
/// (`Expense Tracker Hi-Fi.dc.html` / `README.md`).
class AppColors {
  AppColors._();

  static const bgBlack = Color(0xFF000000); // phone background
  static const bgSurface = Color(0xFF0D0D0D); // cards
  static const bgSurface2 = Color(0xFF141414); // nav border, numpad keys
  static const borderSubtle = Color(0xFF1C1C1C); // card borders
  static const borderFaint = Color(0xFF1A1A1A); // icon button borders / track

  static const gold = Color(0xFFC9A84C); // primary accent
  static const goldDeep = Color(0xFF8A6A28); // progress-bar gradient start

  static const textPrimary = Color(0xFFF0EDE8); // main text
  static const textSecondary = Color(0xFF8A8680); // calendar days
  static const textMuted = Color(0xFF555555); // labels, subtitles
  static const textGhost = Color(0xFF333333); // least important text
  static const textDark = Color(0xFF2A2828); // future days, placeholders
  static const textFaint = Color(0xFF3A3830); // card sub-labels

  static const green = Color(0xFF4CAF82); // under-budget status
  static const red = Color(0xFFE05555); // over-budget status

  // Gold tints
  static Color goldDim = const Color(0xFFC9A84C).withValues(alpha: 0.4);
  static Color goldHalf = const Color(0xFFC9A84C).withValues(alpha: 0.5);
  static Color goldBorder = const Color(0xFFC9A84C).withValues(alpha: 0.35);
  static Color goldTint12 = const Color(0xFFC9A84C).withValues(alpha: 0.12);
  static Color goldTint10 = const Color(0xFFC9A84C).withValues(alpha: 0.10);
  static Color goldRing = const Color(0xFFC9A84C).withValues(alpha: 0.45);
  static Color goldCell = const Color(0xFFC9A84C).withValues(alpha: 0.18);
  static Color redCell = const Color(0xFFE05555).withValues(alpha: 0.12);
}

/// Cormorant Garamond text styles. All typography in the design uses this
/// serif face, so we centralise the [TextStyle] factory here.
class AppText {
  AppText._();

  /// Cormorant Garamond reads small for its nominal size. Roughly DOUBLES the
  /// previously-rendered sizes: small/body type → 2×size+16 (10→36, 14→44),
  /// large display type → 2.5×size. Single knob for overall legibility.
  static double _scaledSize(double size) =>
      size <= 16 ? size + 10 : size * 1.3;

  static TextStyle _base(double size, FontWeight weight, Color color,
      {double? spacing, double? height}) {
    return GoogleFonts.cormorantGaramond(
      fontSize: _scaledSize(size),
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
    );
  }

  // Big gold display numbers (budget spend, amount entry).
  static TextStyle display(double size) =>
      _base(size, FontWeight.w300, AppColors.gold, spacing: -2, height: 1.0);

  // Uppercase gold card headings ("SPENT TODAY", "THIS WEEK", "CATEGORY").
  static final cardHeading = _base(11, FontWeight.w600, AppColors.gold,
      spacing: 2, height: 1.2);

  static final screenTitle =
      _base(26, FontWeight.w600, AppColors.textPrimary, height: 1.1);

  static final sectionTitle = _base(15, FontWeight.w600, AppColors.textPrimary);

  static TextStyle body(Color color) => _base(14, FontWeight.w400, color);

  static TextStyle label(double size, Color color, {FontWeight? weight}) =>
      _base(size, weight ?? FontWeight.w400, color);

  /// Literal-size Cormorant with NO legibility upscaling — for dense grids
  /// (e.g. the month calendar) where the +10 boost makes cells unwieldy.
  static TextStyle dense(double size, Color color,
          {FontWeight? weight, double? spacing}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        color: color,
        letterSpacing: spacing,
      );
}
