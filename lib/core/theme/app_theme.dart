import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Light and dark Material 3 themes built from the Nexmile logo palette.
class AppTheme {
  const AppTheme._();

  /// Corner radius used by cards, tiles and buttons.
  static const double radius = 16;
  static const double radiusLarge = 22;

  static ThemeData get light {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.greenDeep,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.greenWash,
      onPrimaryContainer: Color(0xFF1B4F06),
      secondary: AppColors.orangeDeep,
      onSecondary: AppColors.white,
      secondaryContainer: Color(0xFFFFEBDD),
      onSecondaryContainer: Color(0xFF7A2A00),
      tertiary: AppColors.green,
      onTertiary: AppColors.white,
      error: Color(0xFFB3261E),
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.inkStrong,
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: AppColors.surfaceTint,
      surfaceContainer: AppColors.surfaceTint,
      onSurfaceVariant: AppColors.inkMuted,
      outline: AppColors.outlineLight,
      outlineVariant: Color(0xFFEFF2E9),
      inverseSurface: AppColors.nearBlack,
      onInverseSurface: AppColors.white,
    );

    return _base(
      scheme,
      textPrimary: AppColors.inkStrong,
      textSecondary: AppColors.inkMuted,
      systemOverlay: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  static ThemeData get dark {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.greenLight,
      onPrimary: Color(0xFF10250A),
      primaryContainer: Color(0xFF1E3D10),
      onPrimaryContainer: AppColors.greenLight,
      secondary: AppColors.orangeLight,
      onSecondary: Color(0xFF3A1500),
      secondaryContainer: Color(0xFF4A2100),
      onSecondaryContainer: Color(0xFFFFD5B8),
      tertiary: AppColors.green,
      onTertiary: AppColors.black,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: AppColors.nearBlack,
      onSurface: Color(0xFFF0F3EB),
      surfaceContainerLowest: AppColors.black,
      surfaceContainerLow: AppColors.charcoal,
      surfaceContainer: AppColors.charcoal,
      onSurfaceVariant: Color(0xFFB6BDAC),
      outline: AppColors.outlineDark,
      outlineVariant: Color(0xFF232A1D),
      inverseSurface: AppColors.white,
      onInverseSurface: AppColors.inkStrong,
    );

    return _base(
      scheme,
      textPrimary: const Color(0xFFF0F3EB),
      textSecondary: const Color(0xFFB6BDAC),
      systemOverlay: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.nearBlack,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  static ThemeData _base(
    ColorScheme scheme, {
    required Color textPrimary,
    required Color textSecondary,
    required SystemUiOverlayStyle systemOverlay,
  }) {
    final TextTheme text = AppTypography.textTheme(textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        systemOverlayStyle: systemOverlay,
        titleTextStyle: text.titleLarge,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        // Vertical padding is intentionally roomy: Devanagari and Tamil
        // descenders clip against a tighter field.
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius - 4),
        ),
        insetPadding: const EdgeInsets.all(16),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: text.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
        ),
      ),
    );
  }
}
