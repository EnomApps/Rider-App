import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../auth/state/auth_controller.dart';
import '../../data/kyc_models.dart';
import '../../data/rider_failure.dart';
import '../../state/order_controller.dart';
import '../../state/payout_controller.dart';
import '../../state/rider_controller.dart';
import '../onboarding/onboarding_scaffold.dart';
import '../widgets/rider_form_field.dart';

/// The three states between "submitted" and "on the road".
enum KycOutcome {
  /// With an admin. Read-only; the rider waits.
  underReview,

  /// Turned down. The reason is shown and the wizard reopens.
  rejected,

  /// Approved on paper, but the API still refuses to let them work — a lapsed
  /// licence or insurance, most often. `offline_reason` says which.
  blocked,
}

/// Shown when a rider has done everything they can and the decision is not
/// theirs to make.
///
/// One screen for all three because they differ only in tone and in which
/// button sits at the bottom; three near-identical files would drift apart the
/// first time the copy changed.
class KycDecisionScreen extends StatelessWidget {
  const KycDecisionScreen({
    super.key,
    required this.outcome,
    this.onReopenWizard,
  });

  final KycOutcome outcome;

  /// Asks the gate above to swap this screen for the wizard.
  ///
  /// Null for [KycOutcome.underReview], where there is nothing to go back and
  /// fix — the file is locked until an admin decides. For the other two the
  /// server-side status will not change on its own, so refreshing would land
  /// the rider right back here; only the gate can move them.
  final VoidCallback? onReopenWizard;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RiderController rider = context.watch<RiderController>();

    final (IconData icon, Color tint) = switch (outcome) {
      KycOutcome.underReview => (
          Icons.hourglass_top_rounded,
          AppColors.orange,
        ),
      KycOutcome.rejected => (
          Icons.report_gmailerrorred_rounded,
          theme.colorScheme.error,
        ),
      KycOutcome.blocked => (
          Icons.pause_circle_outline_rounded,
          AppColors.orange,
        ),
    };

    final String title = switch (outcome) {
      KycOutcome.underReview => l10n.underReviewTitle,
      KycOutcome.rejected => l10n.rejectedTitle,
      KycOutcome.blocked => l10n.blockedTitle,
    };

    final String body = switch (outcome) {
      KycOutcome.underReview => l10n.underReviewBody,
      KycOutcome.rejected => l10n.rejectedBody,
      // The server's own sentence when it gave one. It is the same string the
      // duty-status 403 carries, so a rider who reaches this screen and one
      // who taps the toggle are told the same thing. The translated strings
      // stay as the fallback for a server that sent nothing.
      KycOutcome.blocked => rider.offlineReason ??
          (rider.profile?.kyc.documentsExpired ?? false
              ? l10n.documentsExpiredMessage
              : l10n.awaitingVerificationMessage),
    };

    // The admin's note, wherever it landed. The profile and the KYC file both
    // carry it and either can be the fresher of the two depending on which
    // call returned last.
    final String? reason = rider.profile?.kyc.rejectionReason ??
        rider.kyc.rejectionReason;

    // The header's colour carries the verdict before the words do: brand
    // green while it is with the team, red when it came back, amber when
    // something has lapsed.
    final LinearGradient header = switch (outcome) {
      KycOutcome.underReview => kOnboardingHeaderGradient,
      KycOutcome.rejected => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF9F1D1D), Color(0xFFD64545)],
        ),
      KycOutcome.blocked => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFC2410C), AppColors.orange],
        ),
    };

    return Scaffold(
      backgroundColor: onboardingPageColour(theme),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context, rider, silent: true),
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(32)),
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: header),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 12, 30),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton.icon(
                              onPressed: () => _signOut(context),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.logout_rounded, size: 19),
                              label: Text(l10n.signOut),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 112,
                          height: 112,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Icon(icon, size: 40, color: tint),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: Column(
                            children: <Widget>[
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                body,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (outcome == KycOutcome.rejected && reason != null) ...<Widget>[
                    _ReasonCard(reason: reason),
                    const SizedBox(height: 16),
                  ],
                  if (outcome == KycOutcome.underReview) ...<Widget>[
                    const _Timeline(),
                    const SizedBox(height: 14),
                    if (rider.kyc.verifiedAt == null) ...<Widget>[
                      const _SubmittedSummary(),
                      const SizedBox(height: 14),
                    ],
                  ],
                  const SizedBox(height: 10),
                  if (outcome == KycOutcome.underReview)
                    GradientButton(
                      label: l10n.checkAgain,
                      icon: Icons.refresh_rounded,
                      onPressed: rider.isLoading
                          ? null
                          : () => _refresh(context, rider),
                    )
                  else
                    GradientButton(
                      label: outcome == KycOutcome.rejected
                          ? l10n.fixAndResubmit
                          : l10n.updateDocuments,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: rider.isLoading ? null : onReopenWizard,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(
    BuildContext context,
    RiderController rider, {
    bool silent = false,
  }) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final KycOutcome before = outcome;

    final RiderFailure? failure = await rider.refresh();
    if (silent) return;

    final String message;
    if (failure != null) {
      message = failure.message(l10n);
    } else if (rider.stage == RiderStage.underReview &&
        before == KycOutcome.underReview) {
      // Nothing changed. Saying so beats a screen that flashes and looks
      // identical, which reads as a button that did not work.
      message = l10n.stillUnderReview;
    } else {
      // The gate swaps the body out on its own; no message needed.
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signOut(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final AuthController auth = context.read<AuthController>();
    final RiderController rider = context.read<RiderController>();
    final OrderController orders = context.read<OrderController>();
    final PayoutController payouts = context.read<PayoutController>();

    await auth.signOut();
    // Dropped before navigating, so the next rider to sign in on this device
    // never sees the previous one's KYC file on the way to their own.
    rider.reset();
    // Stops the board poll and the position heartbeat as well as dropping
    // the order. A timer that outlived its session would keep a signed-out
    // rider on the dispatch map.
    orders.reset();
    payouts.reset();

    navigator.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (Route<void> route) => false,
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Color tint = theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.rejectionReasonLabel,
            style: theme.textTheme.labelMedium?.copyWith(color: tint),
          ),
          const SizedBox(height: 6),
          Text(reason, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Shows what was sent and when, so the waiting room is not an empty promise.
class _SubmittedSummary extends StatelessWidget {
  const _SubmittedSummary();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RiderController rider = context.watch<RiderController>();

    final DateTime? latest = rider.kyc.documents
        .map((KycDocument document) => document.uploadedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (DateTime? newest, DateTime candidate) =>
              newest == null || candidate.isAfter(newest) ? candidate : newest,
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.folder_open_outlined,
            size: 22,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.documentsProgress(
                    rider.kyc.uploadedCount,
                    // Required, not allowed — see KycOverview.uploadedCount.
                    rider.kyc.requiredCount,
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (latest != null) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    formatDate(latest),
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the application is: sent, being checked, then on the road. The
/// middle stop carries a halo, so the screen reads as something in progress
/// rather than something stuck. Still rather than pulsing: this screen can sit
/// open for days, and a light that never stops blinking reads as a fault.
class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    final List<(String, int)> stops = <(String, int)>[
      (l10n.kycStepSubmitted, 0),
      (l10n.kycStepVerifying, 1),
      (l10n.kycStepApproved, 2),
    ];

    Widget dot(int state) {
      // 0 done, 1 in progress, 2 still to come.
      if (state == 0) {
        return Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.greenDeep,
          ),
          child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
        );
      }
      if (state == 1) {
        return SizedBox.square(
          dimension: 30,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange.withValues(alpha: 0.22),
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
        );
      }
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.outline, width: 2),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < stops.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      dot(stops[i].$2),
                      if (i < stops.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            color: i == 0
                                ? AppColors.greenDeep
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 18),
                      child: Text(
                        stops[i].$1,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: stops[i].$2 == 1
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: stops[i].$2 == 2
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
