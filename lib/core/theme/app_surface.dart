import 'package:flutter/material.dart';

import '../motion/app_motion.dart';
import 'app_colors.dart';

/// Depth, for a palette that has to work on both grounds.
///
/// The app was built on hairline outlines — every card the same 1px box on the
/// same flat field — which reads as a form, not as a product someone uses at
/// speed. These give the same cards a soft, brand-tinted lift instead, so the
/// eye can tell what sits on top of what.
///
/// The shadows are green rather than grey. A neutral drop shadow under a green
/// accent on a warm-white ground reads as dirt; borrowing the brand hue at
/// very low alpha keeps the shade feeling like part of the same light.
class AppSurface {
  const AppSurface._();

  /// Radii. Larger than the old 16/22 — a food app is soft-cornered, and at
  /// this size the difference between a card and a button is legible at a
  /// glance rather than on inspection.
  static const double radiusSmall = 14;
  static const double radius = 20;
  static const double radiusLarge = 28;

  /// Resting elevation for a card in a list.
  static List<BoxShadow> card(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      // On a near-black ground a shadow is nearly invisible, so dark mode gets
      // its separation from the surface colour and a hairline instead. What is
      // left here is only enough to stop a card sitting flush.
      return const <BoxShadow>[
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ];
    }
    return <BoxShadow>[
      BoxShadow(
        color: AppColors.greenDeep.withValues(alpha: 0.055),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: AppColors.inkStrong.withValues(alpha: 0.035),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ];
  }

  /// The one card on a screen that matters most — the duty card, the order in
  /// hand. Lifted further and tinted with the accent it carries.
  static List<BoxShadow> hero(BuildContext context, Color accent) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return <BoxShadow>[
      BoxShadow(
        color: accent.withValues(alpha: dark ? 0.20 : 0.16),
        blurRadius: 30,
        offset: const Offset(0, 12),
      ),
      if (!dark)
        BoxShadow(
          color: AppColors.inkStrong.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
    ];
  }

  /// Border colour for a card that is not carrying an accent.
  ///
  /// Nearly invisible in light — the shadow is doing the separating — and
  /// doing most of the work in dark, where a shadow cannot.
  static Color line(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.outline
        : theme.colorScheme.outline.withValues(alpha: 0.55);
  }

  /// A very soft wash of [accent] over the card surface.
  ///
  /// Used where a card should read as *live* rather than merely present: the
  /// duty card while online, the cash banner on a delivery. Kept under 8% so
  /// text contrast is unaffected in either theme.
  static Gradient wash(BuildContext context, Color accent) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color surface = Theme.of(context).colorScheme.surfaceContainerLow;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color.alphaBlend(accent.withValues(alpha: dark ? 0.14 : 0.09), surface),
        Color.alphaBlend(accent.withValues(alpha: dark ? 0.04 : 0.02), surface),
      ],
    );
  }

  /// The standard card decoration: surface, radius, hairline, soft lift.
  static BoxDecoration decoration(
    BuildContext context, {
    Color? accent,
    double? radius,
    bool elevated = true,
  }) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius shape =
        BorderRadius.circular(radius ?? AppSurface.radius);

    return BoxDecoration(
      color: accent == null ? theme.colorScheme.surfaceContainerLow : null,
      gradient: accent == null ? null : wash(context, accent),
      borderRadius: shape,
      border: Border.all(
        color: accent == null
            ? line(context)
            : accent.withValues(alpha: 0.42),
        width: accent == null ? 1 : 1.4,
      ),
      boxShadow: !elevated
          ? null
          : accent == null
              ? card(context)
              : hero(context, accent),
    );
  }
}

/// A card with the app's standard depth, radius and optional accent wash.
///
/// Exists so the treatment lives in one place: every screen that needs "a
/// surface holding some content" gets the same corner, the same lift and the
/// same hairline, and changing that is one edit rather than fifteen.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.radius,
    this.elevated = true,
  });

  final Widget child;

  /// Tints the surface, the border and the shadow. Null is the resting card.
  final Color? accent;

  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? radius;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final BorderRadius shape =
        BorderRadius.circular(radius ?? AppSurface.radius);

    final Widget body = DecoratedBox(
      decoration: AppSurface.decoration(
        context,
        accent: accent,
        radius: radius,
        elevated: elevated,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return body;

    return Pressable(
      onTap: onTap,
      borderRadius: shape,
      // The ripple still runs underneath, so the card reports the tap twice —
      // once physically as it presses in, once visually as the ink spreads.
      child: Material(
        color: Colors.transparent,
        borderRadius: shape,
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: body,
        ),
      ),
    );
  }
}

/// The green-to-orange rule that marks off a screen's heading from its body.
///
/// Carries the full brand sweep, the same one under the splash lockup, so the
/// mark that opens the app and the rule under every headline are recognisably
/// the same gesture.
class BrandRule extends StatelessWidget {
  const BrandRule({super.key, this.width = 46, this.height = 4});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(height),
      ),
    );
  }
}

