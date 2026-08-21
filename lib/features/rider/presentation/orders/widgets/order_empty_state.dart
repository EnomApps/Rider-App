import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';

/// A centred icon, a headline and a line of copy, with an optional action.
///
/// The board has five of these and they are the screen most of the time — an
/// idle rider stares at an empty list far longer than a full one — so it is
/// worth them saying which of the five situations the rider is in rather than
/// all reading "nothing here".
class OrderEmptyState extends StatelessWidget {
  const OrderEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? AppColors.greenLight : AppColors.greenDeep)
                  .withValues(alpha: isDark ? 0.14 : 0.10),
            ),
            child: Icon(
              icon,
              size: 34,
              color: isDark ? AppColors.greenLight : AppColors.greenDeep,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (body != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (action != null) ...<Widget>[
            const SizedBox(height: 22),
            action!,
          ],
        ],
      ),
    );
  }
}

/// A warning strip above a list — a location refusal, a failed refresh.
///
/// Sits above the content rather than replacing it: whatever the board last
/// fetched does not stop being true because the next poll missed.
class OrderBanner extends StatelessWidget {
  const OrderBanner({
    super.key,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color base = AppColors.orangeDeep;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: base.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: base.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 20, color: base),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (action != null) ...<Widget>[
            const SizedBox(height: 10),
            Align(alignment: AlignmentDirectional.centerEnd, child: action!),
          ],
        ],
      ),
    );
  }
}
