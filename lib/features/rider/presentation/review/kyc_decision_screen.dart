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
import '../../state/rider_controller.dart';
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

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(context, rider, silent: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            physics: const AlwaysScrollableScrollPhysics(),
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton.icon(
                    onPressed: () => _signOut(context),
                    icon: const Icon(Icons.logout_rounded, size: 19),
                    label: Text(l10n.signOut),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 138,
                  height: 138,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(
                        width: 138,
                        height: 138,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tint.withValues(alpha: 0.06),
                        ),
                      ),
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tint.withValues(alpha: 0.09),
                        ),
                      ),
                      Container(
                        width: 78,
                        height: 78,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              tint.withValues(alpha: 0.26),
                              tint.withValues(alpha: 0.11),
                            ],
                          ),
                        ),
                        child: Icon(icon, size: 36, color: tint),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              if (outcome == KycOutcome.rejected && reason != null) ...<Widget>[
                const SizedBox(height: 24),
                _ReasonCard(reason: reason),
              ],
              if (outcome == KycOutcome.underReview &&
                  rider.kyc.verifiedAt == null) ...<Widget>[
                const SizedBox(height: 24),
                const _SubmittedSummary(),
              ],
              const SizedBox(height: 34),
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

    await auth.signOut();
    // Dropped before navigating, so the next rider to sign in on this device
    // never sees the previous one's KYC file on the way to their own.
    rider.reset();
    // Stops the board poll and the position heartbeat as well as dropping
    // the order. A timer that outlived its session would keep a signed-out
    // rider on the dispatch map.
    orders.reset();

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
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: theme.colorScheme.outline),
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
