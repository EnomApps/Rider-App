import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Primary call-to-action styled with the brand green gradient.
///
/// The label is laid out with [FittedBox] so long translations (Malayalam and
/// Santali run roughly twice the width of "Continue") shrink instead of
/// wrapping into the button's fixed height.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool enabled = onPressed != null;

    final LinearGradient gradient =
        isDark ? AppColors.ctaGradientDark : AppColors.ctaGradientLight;
    final Color foreground =
        isDark ? const Color(0xFF10250A) : AppColors.white;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: enabled
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.greenDeep.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            child: Container(
              height: height,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label,
                      maxLines: 1,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (icon != null) ...<Widget>[
                      const SizedBox(width: 10),
                      Icon(icon, size: 20, color: foreground),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The thin green -> orange rule that sits under the logo lockup.
class BrandRule extends StatelessWidget {
  const BrandRule({super.key, this.width = 120, this.height = 3});

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
