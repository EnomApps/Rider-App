import 'package:flutter/material.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// A single selectable language.
///
/// Overflow safety, in order of defence:
///
/// * the native name sits in a [FittedBox] with [BoxFit.scaleDown], so a wide
///   script (`ᱥᱟᱱᱛᱟᱲᱤ`, `संस्कृतम्`) shrinks rather than clipping or wrapping;
/// * the English name is single-line with an ellipsis;
/// * the tile is always laid out left-to-right regardless of the app's current
///   direction, because the native name must render in *its own* direction —
///   `اردو` next to `Urdu` would otherwise swap sides mid-list;
/// * the parent supplies a height derived from the live text scale, so the
///   column can never exceed its box.
class LanguageTile extends StatelessWidget {
  const LanguageTile({
    super.key,
    required this.language,
    required this.isSelected,
    required this.onTap,
    required this.selectedSemanticLabel,
    required this.defaultBadgeLabel,
  });

  final AppLanguage language;
  final bool isSelected;
  final VoidCallback onTap;
  final String selectedSemanticLabel;
  final String defaultBadgeLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    final Color background = isSelected
        ? (isDark ? const Color(0xFF1A2A11) : AppColors.greenWash)
        : scheme.surfaceContainerLow;
    final Color border = isSelected
        ? (isDark ? AppColors.greenLight : AppColors.green)
        : scheme.outline;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${language.nativeName}, ${language.englishName}'
          '${isSelected ? ', $selectedSemanticLabel' : ''}',
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(
                color: border,
                width: isSelected ? 1.8 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // The script's own direction, not the app's.
                        Directionality(
                          textDirection: language.textDirection,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                language.nativeName,
                                maxLines: 1,
                                softWrap: false,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isSelected
                                      ? (isDark
                                          ? AppColors.greenLight
                                          : AppColors.greenDeep)
                                      : scheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          language.isDefault
                              ? '${language.englishName} · $defaultBadgeLabel'
                              : language.englishName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _SelectionDot(isSelected: isSelected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color active = isDark ? AppColors.greenLight : AppColors.greenDeep;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? active : Colors.transparent,
        border: Border.all(
          color: isSelected ? active : theme.colorScheme.outline,
          width: 1.6,
        ),
      ),
      child: isSelected
          ? Icon(
              Icons.check_rounded,
              size: 15,
              color: isDark ? AppColors.black : AppColors.white,
            )
          : null,
    );
  }
}
