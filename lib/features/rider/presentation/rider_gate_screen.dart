import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../state/rider_controller.dart';
import 'home/rider_home_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'review/kyc_decision_screen.dart';

/// The junction every signed-in rider passes through.
///
/// This is the structural difference between the rider app and the customer
/// app. A customer verifies a code and is `active` — the home screen is the
/// next thing they see. A rider verifies the same code, is `pending`, and
/// cannot work until an admin has approved their documents. So sign-in does
/// not navigate to a screen; it navigates *here*, and this widget asks the API
/// which screen the rider is entitled to.
///
/// It swaps the body rather than pushing routes. The stage can change under
/// the rider's feet — a submit moves them to the waiting room, an approval
/// landing during a pull-to-refresh moves them to the home screen — and a
/// route stack would have to be unwound each time. One `Consumer` and a switch
/// keeps that correct by construction.
class RiderGateScreen extends StatefulWidget {
  const RiderGateScreen({super.key});

  @override
  State<RiderGateScreen> createState() => _RiderGateScreenState();
}

class _RiderGateScreenState extends State<RiderGateScreen> {
  /// Set when a rider on a decision screen asks to go back and fix things.
  ///
  /// A rejected rider is still `rejected` server-side until they resubmit, and
  /// a rider with a lapsed licence is still `verified`. Neither status changes
  /// on its own, so without this the "Fix and submit again" and "Update
  /// documents" buttons would refresh into the very screen they were trying to
  /// leave. Cleared as soon as the API moves the rider on.
  OnboardingStep? _reopenAt;
  bool _reopenRequested = false;

  void _reopenWizard({OnboardingStep? at}) {
    setState(() {
      _reopenRequested = true;
      _reopenAt = at;
    });
  }

  void _clearReopen() {
    if (!_reopenRequested) return;
    // Deferred: this runs from inside build, where setState is illegal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_reopenRequested) return;
      setState(() {
        _reopenRequested = false;
        _reopenAt = null;
      });
    });
  }

  /// Kicks off the fetch whenever the controller has nothing and is not
  /// already fetching.
  ///
  /// Driven from `build` rather than `initState` on purpose. A gate that
  /// loaded once on mount would spin forever on an empty profile if the
  /// controller were ever replaced beneath it — which is exactly what a
  /// sign-out followed by a sign-in on the same device looks like. Scheduled
  /// after the frame because `load` notifies its listeners synchronously when
  /// it sets the loading flag, and notifying during build is an error.
  void _loadIfNeeded(RiderController rider) {
    if (!rider.shouldLoad) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && rider.shouldLoad) rider.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RiderController>(
      builder: (BuildContext context, RiderController rider, _) {
        _loadIfNeeded(rider);

        switch (rider.stage) {
          case RiderStage.loading:
            return const _GateLoading();

          case RiderStage.unavailable:
            return _GateUnavailable(onRetry: () => rider.load());

          case RiderStage.onboarding:
            _clearReopen();
            return const OnboardingScreen();

          case RiderStage.rejected:
            if (_reopenRequested) {
              return OnboardingScreen(initialStep: _reopenAt);
            }
            return KycDecisionScreen(
              outcome: KycOutcome.rejected,
              // A rejection already puts the API back in an editable state, so
              // the whole wizard reopens and the rider resumes wherever the
              // saved answers leave them.
              onReopenWizard: _reopenWizard,
            );

          case RiderStage.underReview:
            _clearReopen();
            return const KycDecisionScreen(outcome: KycOutcome.underReview);

          case RiderStage.blocked:
            if (_reopenRequested) {
              return OnboardingScreen(initialStep: _reopenAt);
            }
            return KycDecisionScreen(
              outcome: KycOutcome.blocked,
              // Straight to the checklist: the reference numbers are locked
              // once KYC is verified, so a current licence photo is the only
              // thing this rider can actually change.
              onReopenWizard: () =>
                  _reopenWizard(at: OnboardingStep.documents),
            );

          case RiderStage.ready:
            _clearReopen();
            return const RiderHomeScreen();
        }
      },
    );
  }
}

class _GateLoading extends StatelessWidget {
  const _GateLoading();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const BrandMark(size: 64, radius: 20),
            const SizedBox(height: 26),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.checkingYourAccount,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _GateUnavailable extends StatelessWidget {
  const _GateUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.cloud_off_rounded,
                size: 46,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.couldNotLoadAccount,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              GradientButton(label: l10n.retry, onPressed: onRetry),
              const SizedBox(height: 10),
              // The escape hatch. Without it a rider whose session is valid
              // but whose profile will not load is stuck on this screen with
              // no way back to sign-in.
              TextButton(
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (Route<void> route) => false,
                ),
                child: Text(l10n.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
