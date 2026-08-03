import 'package:flutter/material.dart';

/// Brand palette.
///
/// Every value below was sampled directly from `assets/images/nexmile_logo.png`
/// so the app and the logo stay in sync:
///
/// * the "N" mark runs from `#9DCD2B` (top) to `#2C8B0D` (bottom)
/// * the location pin runs from `#FF8406` (top) to `#FF5400` (bottom)
/// * the lockup sits on pure black
class AppColors {
  const AppColors._();

  // --- Sampled brand colours ------------------------------------------------
  static const Color greenLight = Color(0xFF9DCD2B);
  static const Color green = Color(0xFF62B31A);
  static const Color greenDeep = Color(0xFF2C8B0D);

  static const Color orangeLight = Color(0xFFFF8406);
  static const Color orange = Color(0xFFFF6B00);
  static const Color orangeDeep = Color(0xFFFF5400);

  /// The splash burst — the dot that opens the animation and the glow it
  /// expands into.
  static const Color orangePulse = Color(0xFFFF7A00);

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // --- Derived neutrals -----------------------------------------------------
  /// Slightly green-shifted blacks so dark surfaces feel part of the brand
  /// rather than plain grey.
  static const Color nearBlack = Color(0xFF0B0D0A);
  static const Color charcoal = Color(0xFF151813);
  static const Color slate = Color(0xFF1F241B);

  static const Color inkStrong = Color(0xFF14170F);
  static const Color inkMuted = Color(0xFF5C6356);
  static const Color inkFaint = Color(0xFF8A9182);

  static const Color surfaceTint = Color(0xFFF4F7EF);
  static const Color outlineLight = Color(0xFFE1E6D9);
  static const Color outlineDark = Color(0xFF2A3024);

  /// Selected-tile wash in the light theme.
  static const Color greenWash = Color(0xFFEDF7E0);

  // --- Gradients ------------------------------------------------------------
  /// The "N" mark gradient.
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[greenLight, greenDeep],
  );

  /// The location-pin gradient.
  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[orangeLight, orangeDeep],
  );

  /// Green -> orange, the full brand sweep used for decorative rules.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[greenLight, green, orangeLight, orangeDeep],
    stops: <double>[0.0, 0.35, 0.75, 1.0],
  );

  /// Primary call-to-action fill for the light theme.
  ///
  /// Deliberately darker than [greenGradient]: the lightest stop still holds a
  /// ~3.9:1 contrast ratio against white, which clears WCAG AA for the large,
  /// bold label the button uses.
  static const LinearGradient ctaGradientLight = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[Color(0xFF3F930F), greenDeep],
  );

  /// Primary call-to-action fill for the dark theme (dark label on bright fill).
  static const LinearGradient ctaGradientDark = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[greenLight, green],
  );

  /// Backdrop of the splash screen — the logo's own black, warmed very slightly
  /// towards the brand green so the edges do not read as a dead rectangle.
  static const RadialGradient splashBackdrop = RadialGradient(
    center: Alignment(0, -0.15),
    radius: 1.05,
    colors: <Color>[Color(0xFF101408), black],
    stops: <double>[0.0, 1.0],
  );
}
