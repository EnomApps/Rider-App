import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../generated/l10n/app_localizations.dart';

/// Shared chrome for every auth screen: brand mark, headline, supporting copy
/// and a scrolling body.
///
/// Everything scrolls. Auth screens combine long translated copy, a stack of
/// fields and an on-screen keyboard, and any one of those can exceed the
/// viewport on a small phone — a fixed header would overflow rather than
/// scroll. `resizeToAvoidBottomInset` plus the scroll view means the focused
/// field always ends up above the keyboard.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBack = true,
    this.footer,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;

  /// Pinned to the bottom of the content (not the viewport) — typically the
  /// "already have an account?" style link.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          // Tapping the background dismisses the keyboard.
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (showBack) ...<Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                    ),
                    const SizedBox(width: 8),
                  ] else ...<Widget>[
                    const BrandMark(size: 42, radius: 13),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      l10n.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const BrandRule(width: 52, height: 4),
              const SizedBox(height: 14),
              Text(title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(subtitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 28),
              ...children,
              if (footer != null) ...<Widget>[
                const SizedBox(height: 24),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "New to Nexmile?  Create account" — a prompt plus an inline action.
///
/// Uses [Wrap] rather than [Row] so a long translated prompt drops the action
/// onto a second line instead of squeezing or clipping it.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onPressed,
  });

  final String prompt;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: <Widget>[
        Text(
          prompt,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              action,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isDark ? AppColors.greenLight : AppColors.greenDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Inline error banner shown above the submit button when the server rejects
/// a request (bad credentials, email taken, and so on).
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foreground = theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline_rounded, size: 19, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Submit button with an inline progress state, so a screen never needs to
/// swap the whole button out while a request is in flight.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.isBusy,
    required this.onPressed,
  });

  final String label;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!isBusy) {
      return GradientButton(
        label: label,
        icon: Icons.arrow_forward_rounded,
        onPressed: onPressed,
      );
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: 0.75,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient:
              isDark ? AppColors.ctaGradientDark : AppColors.ctaGradientLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          height: 56,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppColors.black : AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
