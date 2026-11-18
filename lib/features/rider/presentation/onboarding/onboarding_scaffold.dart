import 'package:flutter/material.dart';

import '../../../../core/motion/app_motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../generated/l10n/app_localizations.dart';

/// The brand panel behind the header of every registration screen.
const LinearGradient kOnboardingHeaderGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: <Color>[Color(0xFF1F6A08), AppColors.greenDeep, AppColors.green],
  stops: <double>[0.0, 0.55, 1.0],
);

/// The soft page colour registration screens sit on in the light theme, so
/// the white form card reads as a card.
Color onboardingPageColour(ThemeData theme) =>
    theme.brightness == Brightness.dark
        ? theme.colorScheme.surface
        : AppColors.surfaceTint;

/// Shared chrome for every onboarding step: a brand header carrying the step
/// count, a progress rail and the step's own headline; a scrolling body; and a
/// pinned action bar.
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
    this.icon,
    this.bodyInCard = true,
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

  /// Shown beside the headline, so each step is recognisable at a glance.
  final IconData? icon;

  /// True wraps [children] in one white card, which is right for a form. A
  /// step whose children are already cards — the document checklist, the
  /// review — passes false so cards do not nest inside a card.
  final bool bodyInCard;

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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: onboardingPageColour(theme),
      body: Column(
        children: <Widget>[
          _Header(
            stepIndex: stepIndex,
            stepCount: stepCount,
            title: title,
            subtitle: subtitle,
            icon: icon,
            onBack: isBusy ? null : onBack,
            showBack: onBack != null,
          ),
          Expanded(child: _body(theme)),
          _ActionBar(
            banner: banner,
            label: primaryLabel,
            isBusy: isBusy,
            onPressed: onPrimary,
          ),
        ],
      ),
    );
  }

  Widget _body(ThemeData theme) {
    final List<Widget> content = bodyInCard
        ? <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0 : 0.035,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ]
        : children;

    final Widget list = ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: content,
    );
    final GlobalKey<FormState>? key = formKey;
    return key == null ? list : Form(key: key, child: list);
  }
}

/// The green panel at the top: back, "Step 3 of 7", the rail, and the step's
/// icon and headline in white.
class _Header extends StatelessWidget {
  const _Header({
    required this.stepIndex,
    required this.stepCount,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onBack,
    required this.showBack,
  });

  final int stepIndex;
  final int stepCount;
  final String title;
  final String subtitle;
  final IconData? icon;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: kOnboardingHeaderGradient),
        child: Stack(
          children: <Widget>[
            // Two soft discs for depth, the way the big delivery apps dress a
            // flat brand panel. Decoration only.
            const Positioned(right: -46, top: -38, child: _Disc(size: 170)),
            const Positioned(right: 60, bottom: -64, child: _Disc(size: 130)),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        if (showBack) ...<Widget>[
                          Material(
                            color: Colors.white.withValues(alpha: 0.16),
                            shape: const CircleBorder(),
                            child: IconButton(
                              onPressed: onBack,
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                              ),
                              tooltip: l10n.backLabel,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ] else
                          const SizedBox(width: 4, height: 48),
                        Expanded(
                          child: Text(
                            l10n.stepOfSteps(stepIndex + 1, stepCount),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 4),
                      child: _ProgressRail(current: stepIndex, total: stepCount),
                    ),
                    const SizedBox(height: 20),
                    // Re-keyed on the step, so moving between steps replays the
                    // entrance and the header reads as new rather than as the
                    // same words silently swapping underneath.
                    ...entranceGroup(
                      <Widget>[
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (icon != null) ...<Widget>[
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      title,
                                      key: ValueKey<String>('title-$stepIndex'),
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      subtitle,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
    );
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
    return Row(
      children: <Widget>[
        for (int i = 0; i < total; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            // Done segments solid, the current one thicker, the rest faint:
            // "how much is left" is the question the rail answers, and on a
            // green panel white at three strengths answers it at a glance.
            child: AnimatedContainer(
              duration: AppMotion.quick,
              curve: AppMotion.change,
              height: i == current ? 6 : 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.white.withValues(
                  alpha: i == current
                      ? 1
                      : i < current
                          ? 0.75
                          : 0.28,
                ),
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
    final AppLocalizations l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
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
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.onboardingSavedNote,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
