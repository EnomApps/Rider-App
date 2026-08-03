import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A labelled value row: small caption above, prominent value below.
///
/// Tappable when [onTap] is given (and then shows a chevron), otherwise a plain
/// read-only field — which is what the profile screen needs, since the customer
/// profile is display-only until an edit screen exists.
///
/// The value shrinks to fit rather than wrapping, and can be forced into its
/// own text direction so an email or phone number stays left-to-right inside a
/// right-to-left layout.
class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.valueDirection,
    this.trailing,
    this.emphasise = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final TextDirection? valueDirection;

  /// Rendered after the value — a "Verified" badge, for instance.
  final Widget? trailing;

  /// False renders the value in the muted colour, for placeholders such as
  /// "Not added".
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Widget content = Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 22,
            color: isDark ? AppColors.greenLight : AppColors.greenDeep,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Directionality(
                        textDirection:
                            valueDirection ?? Directionality.of(context),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              value,
                              maxLines: 1,
                              softWrap: false,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: emphasise
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (trailing != null) ...<Widget>[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );

    final BorderRadius radius = BorderRadius.circular(AppTheme.radiusLarge);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: radius,
      child: onTap == null
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: content,
            )
          : InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: content,
              ),
            ),
    );
  }
}

/// Small pill used for the account status and the "Verified" badge.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color base;
    switch (tone) {
      case StatusTone.positive:
        base = isDark ? AppColors.greenLight : AppColors.greenDeep;
      case StatusTone.warning:
        base = AppColors.orangeDeep;
      case StatusTone.negative:
        base = theme.colorScheme.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: base.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: base.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: base,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum StatusTone { positive, warning, negative }
