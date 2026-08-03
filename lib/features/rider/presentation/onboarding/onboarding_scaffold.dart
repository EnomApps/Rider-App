import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../generated/l10n/app_localizations.dart';

/// Shared chrome for every onboarding step: a progress rail, the step's own
/// headline, a scrolling body, and a pinned action bar.
///
/// The action bar is pinned to the viewport rather than to the end of the
/// content, which is the opposite of what `AuthScaffold` does. An auth screen
/// has one field; an onboarding step has five, and a rider who has scrolled to
/// the bottom of a long form should not have to hunt for the button that
/// saves it.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.stepIndex,
    required this.stepCount,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.onPrimary,
    required this.primaryLabel,
    this.isBusy = false,
    this.onBack,
    this.banner,
    this.formKey,
  });

  /// Zero-based.
  final int stepIndex;
  final int stepCount;

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Null disables the primary button — used while a required choice is
  /// unmade, rather than letting the rider submit a form the API will refuse.
  final VoidCallback? onPrimary;

  final String primaryLabel;
  final bool isBusy;

  /// Null on the first step, where there is nothing behind.
  final VoidCallback? onBack;

  /// Error banner shown above the action bar.
  final Widget? banner;

  /// Wraps the scrolling body in a [Form] when given.
  ///
  /// The form lives here rather than inside each step because a step's fields
  /// are handed over as a flat list and dropped straight into a `ListView`;
  /// a step that wrapped some of them in its own `Form` would silently leave
  /// the rest unvalidated. One form around the whole body makes that mistake
  /// impossible.
  final GlobalKey<FormState>? formKey;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (onBack != null)
                        IconButton(
                          onPressed: isBusy ? null : onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 40,
                            height: 40,
                          ),
                          tooltip: l10n.backLabel,
                        ),
                      if (onBack != null) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.stepOfSteps(stepIndex + 1, stepCount),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ProgressRail(current: stepIndex, total: stepCount),
                  const SizedBox(height: 20),
                  Text(title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: _body()),
            _ActionBar(
              banner: banner,
              label: primaryLabel,
              isBusy: isBusy,
              onPressed: onPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final Widget list = ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: children,
    );
    final GlobalKey<FormState>? key = formKey;
    return key == null ? list : Form(key: key, child: list);
  }
}

/// Segmented bar rather than a numbered stepper: seven numbered circles do not
/// fit a narrow phone once translated, and the rider only needs to know how
/// much is left.
class _ProgressRail extends StatelessWidget {
  const _ProgressRail({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        for (int i = 0; i < total; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: i <= current ? AppColors.brandGradient : null,
                color: i <= current ? null : theme.colorScheme.outlineVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.label,
    required this.isBusy,
    required this.onPressed,
    this.banner,
  });

  final String label;
  final bool isBusy;
  final VoidCallback? onPressed;
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (banner != null) ...<Widget>[
            banner!,
            const SizedBox(height: 14),
          ],
          if (isBusy)
            const _BusyButton()
          else
            GradientButton(
              label: label,
              icon: Icons.arrow_forward_rounded,
              onPressed: onPressed,
            ),
        ],
      ),
    );
  }
}

class _BusyButton extends StatelessWidget {
  const _BusyButton();

  @override
  Widget build(BuildContext context) {
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
