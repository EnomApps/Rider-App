import 'package:flutter/material.dart';

/// Type scale tuned for Indic scripts.
///
/// Devanagari, Tamil, Telugu, Malayalam, Bengali and Gurmukhi stack vowel signs
/// above and below the base glyph, so they need noticeably more vertical room
/// than Latin at the same point size. Three rules keep every locale legible and
/// clipping-free:
///
/// 1. Generous [TextStyle.height] — never below 1.28, body copy at 1.5.
/// 2. [TextLeadingDistribution.even] — splits the extra leading above *and*
///    below the glyph instead of dumping it all below, which is what causes
///    clipped Tamil/Devanagari ascenders inside tight rows.
/// 3. No negative letter spacing — it collides conjunct clusters.
class AppTypography {
  const AppTypography._();

  /// Applied to every style so leading is shared evenly around the glyph box.
  static const TextLeadingDistribution _even = TextLeadingDistribution.even;

  /// Minimum system text-scale honoured by the app.
  static const double minTextScale = 0.9;

  /// Maximum system text-scale honoured by the app.
  ///
  /// Android and iOS both allow scale factors above 2.0. Beyond ~1.3 the
  /// two-line language tiles start to collide, so the app clamps here and
  /// relies on shrink-to-fit inside the tiles for the rest.
  static const double maxTextScale = 1.3;

  static TextTheme textTheme(Color primary, Color secondary) {
    TextStyle style(
      double size,
      FontWeight weight,
      double height, {
      double letterSpacing = 0,
      Color? color,
    }) {
      return TextStyle(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        leadingDistribution: _even,
        color: color ?? primary,
      );
    }

    return TextTheme(
      displayLarge: style(40, FontWeight.w800, 1.28),
      displayMedium: style(34, FontWeight.w800, 1.28),
      displaySmall: style(30, FontWeight.w700, 1.30),

      headlineLarge: style(28, FontWeight.w700, 1.32),
      headlineMedium: style(24, FontWeight.w700, 1.34),
      headlineSmall: style(21, FontWeight.w700, 1.36),

      titleLarge: style(19, FontWeight.w700, 1.38),
      titleMedium: style(17, FontWeight.w600, 1.40),
      titleSmall: style(15, FontWeight.w600, 1.42),

      bodyLarge: style(16, FontWeight.w400, 1.50, color: secondary),
      bodyMedium: style(14.5, FontWeight.w400, 1.50, color: secondary),
      bodySmall: style(13, FontWeight.w400, 1.48, color: secondary),

      labelLarge: style(15, FontWeight.w600, 1.34, letterSpacing: 0.1),
      labelMedium: style(13, FontWeight.w600, 1.34, letterSpacing: 0.1),
      labelSmall: style(11.5, FontWeight.w600, 1.36, letterSpacing: 0.2),
    );
  }
}
