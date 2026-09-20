import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/motion/app_motion.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../auth/data/auth_user.dart';
import '../../auth/state/auth_controller.dart';
import '../data/rider_failure.dart';
import '../state/order_controller.dart';
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
      if (!mounted || !rider.shouldLoad) return;
      // Signing out clears the rider, which makes `shouldLoad` true again for
      // the frame before the navigation lands — so without this the gate fires
      // one last fetch with a token that was just revoked and gets a 401 for
      // its trouble.
      final AuthController auth = context.read<AuthController>();
      if (!auth.isSignedIn) return;
      // Nor is there any point asking the rider endpoints about an account
      // that is not a rider; they are role-gated and will only ever 403.
      if (_wrongRole(auth.user) != null) return;
      rider.load();
    });
  }

  /// The signed-in account's role, when it is one this app cannot serve.
  ///
  /// `/v1/auth/otp/verify` returns the user, so the app knows the role the
  /// moment sign-in completes — well before any rider endpoint is called.
  /// Reading it here turns a wasted round-trip and a guessed error message
  /// into an immediate, accurate one that can name the actual role.
  ///
  /// [UserRole.unknown] is deliberately not caught: it means the API grew a
  /// role this build predates, and refusing to proceed on a value we simply do
  /// not recognise would lock out riders over a backend deploy. That case
  /// falls through to the request, and the 403 handling catches it.
  static UserRole? _wrongRole(AuthUser? user) {
    if (user == null) return null;
    switch (user.role) {
      case UserRole.customer:
      case UserRole.merchant:
      case UserRole.admin:
        return user.role;
      case UserRole.rider:
      case UserRole.unknown:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watched, not read: signing out clears the user, and this has to stop
    // claiming the account is a merchant the instant that happens.
    final AuthUser? user = context.watch<AuthController>().user;
    final UserRole? wrongRole = _wrongRole(user);
    if (wrongRole != null) return _GateWrongAccount(role: wrongRole);

    return Consumer<RiderController>(
      builder: (BuildContext context, RiderController rider, _) {
        _loadIfNeeded(rider);

        switch (rider.stage) {
          case RiderStage.loading:
            return const _GateLoading();

          case RiderStage.unavailable:
            return _GateUnavailable(
              failure: rider.loadFailure,
              onRetry: () => rider.load(),
            );

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

    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // The mark sits inside the same pulse the duty card uses, so the
            // first thing a rider sees after sign-in already speaks the app's
            // language rather than Material's default spinner.
            SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  BreathingDot(
                    colour: isDark
                        ? AppColors.greenLight
                        : AppColors.greenDeep,
                    size: 64,
                    spread: 62,
                  ),
                  const BrandMark(size: 64, radius: 20),
                ],
              ),
            ),
            const SizedBox(height: 26),
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

/// Dead end for an account that is not a rider.
///
/// A role is fixed when the account is created and the API refuses to let
/// anyone promote themselves, so there is nothing to retry — only a different
/// email or mobile number will do. The screen therefore offers exactly one
/// action, and it is the one that works.
class _GateWrongAccount extends StatelessWidget {
  const _GateWrongAccount({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    // Naming the role beats a generic line: a merchant who downloaded the
    // wrong app needs to know that is what happened, not that "something is
    // registered".
    final String? roleName = switch (role) {
      UserRole.customer => l10n.roleCustomer,
      UserRole.merchant => l10n.roleMerchant,
      UserRole.admin => l10n.roleAdmin,
      UserRole.rider || UserRole.unknown => null,
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.person_off_outlined,
                size: 46,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.notARiderAccountTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                roleName == null
                    ? l10n.notARiderAccount
                    : l10n.notARiderAccountFor(roleName),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              GradientButton(
                label: l10n.useAnotherAccount,
                icon: Icons.logout_rounded,
                onPressed: () => signOutToLogin(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateUnavailable extends StatelessWidget {
  const _GateUnavailable({required this.onRetry, this.failure});

  final VoidCallback onRetry;

  /// What actually went wrong. Null falls back to the generic line, but the
  /// specific one is worth showing: telling a rider on full signal to "check
  /// your connection" when the server returned a 500 sends them chasing the
  /// wrong problem, and it hides a real outage from whoever they call.
  final RiderFailure? failure;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool offline = failure == RiderFailure.network;

    // An account's role is fixed when it is created and the API refuses to let
    // anyone promote themselves, so this one is permanent. Offering "Try
    // again" would be a button that is guaranteed to fail; the only thing that
    // helps is a different identifier.
    final bool wrongAccount = failure == RiderFailure.notARider;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                offline
                    ? Icons.cloud_off_rounded
                    : wrongAccount
                        ? Icons.person_off_outlined
                        : Icons.error_outline_rounded,
                size: 46,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 20),
              if (wrongAccount) ...<Widget>[
                Text(
                  l10n.notARiderAccountTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
              ],
              Text(
                failure?.message(l10n) ?? l10n.couldNotLoadAccount,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              if (wrongAccount)
                GradientButton(
                  label: l10n.useAnotherAccount,
                  icon: Icons.logout_rounded,
                  onPressed: () => signOutToLogin(context),
                )
              else ...<Widget>[
                GradientButton(label: l10n.retry, onPressed: onRetry),
                const SizedBox(height: 10),
                // The escape hatch. Without it a rider whose session is valid
                // but whose profile will not load is stuck on this screen with
                // no way back to sign-in.
                TextButton(
                  onPressed: () => signOutToLogin(context),
                  child: Text(l10n.signOut),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}

/// Revokes the session server-side, drops the cached rider, and returns to
/// sign-in.
///
/// Goes through `AuthController` rather than just navigating: leaving a live
/// token on the device would restore the same dead-end session on the next
/// launch, and the rider would be stuck in a loop they cannot see the cause
/// of.
Future<void> signOutToLogin(BuildContext context) async {
  final NavigatorState navigator = Navigator.of(context);
  final AuthController auth = context.read<AuthController>();
  final RiderController rider = context.read<RiderController>();
  final OrderController orders = context.read<OrderController>();

  await auth.signOut();
  rider.reset();
  // Stops the board poll and the position heartbeat as well as dropping the
  // order. A timer that outlived its session would keep a signed-out rider on
  // the dispatch map.
  orders.reset();

  navigator.pushNamedAndRemoveUntil(
    AppRoutes.login,
    (Route<void> route) => false,
  );
}
