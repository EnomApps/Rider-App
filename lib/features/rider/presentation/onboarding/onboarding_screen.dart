import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../generated/l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';
import '../../data/rider_failure.dart';
import '../../data/rider_profile.dart';
import '../../state/rider_controller.dart';
import 'onboarding_scaffold.dart';
import 'steps/bank_step.dart';
import 'steps/documents_step.dart';
import 'steps/identity_numbers_step.dart';
import 'steps/identity_step.dart';
import 'steps/licence_step.dart';
import 'steps/review_step.dart';
import 'steps/vehicle_step.dart';

/// The seven-step rider onboarding wizard.
///
/// Eleven reference numbers and a document checklist is far too much for one
/// screen, so it is split into steps that each save on their own. That is not
/// only a layout decision: `PATCH /v1/rider/kyc/details` takes every field as
/// optional, which means a rider who fills in three steps and closes the app
/// keeps those three. Holding the whole form in memory until a single final
/// save would throw all of it away.
///
/// Step order follows what a rider has to hand. Name and vehicle come from
/// memory; the reference numbers need the documents in front of them; the
/// uploads need the documents in the light. Bank details sit last of the typed
/// steps because that is the one people go and fetch a passbook for.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.initialStep});

  /// Overrides the resume logic and opens on a named step.
  ///
  /// Used when the gate knows better than the wizard does: a rider whose
  /// licence has lapsed is sent straight to the document checklist, because
  /// re-uploading is the only thing that will get them back on the road and
  /// the resume logic — seeing every field filled in — would drop them on the
  /// review step instead.
  final OnboardingStep? initialStep;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Every step, in order. The count drives the progress rail, so adding a step
  /// is a one-line change here.
  static const List<OnboardingStep> _allSteps = <OnboardingStep>[
    OnboardingStep.identity,
    OnboardingStep.vehicle,
    OnboardingStep.identityNumbers,
    OnboardingStep.licence,
    OnboardingStep.bank,
    OnboardingStep.documents,
    OnboardingStep.review,
  ];

  /// The steps this rider actually has to answer.
  ///
  /// A rider on foot or on a bicycle has no licence and no insurance policy,
  /// so that step is dropped rather than shown with nothing they can put in
  /// it. The list is derived from the saved vehicle type on every build, which
  /// is what makes the rail recount itself the moment the vehicle step is
  /// saved — and what lets a rider who goes back and switches to a motorcycle
  /// get the licence step back.
  static List<OnboardingStep> _stepsFor(RiderProfile? profile) {
    final bool papers = profile?.vehicleType.hasPapers ?? true;
    if (papers) return _allSteps;
    return _allSteps
        .where((OnboardingStep step) => step != OnboardingStep.licence)
        .toList(growable: false);
  }

  List<OnboardingStep> get _steps =>
      _stepsFor(context.read<RiderController>().profile);

  int _index = 0;

  /// Set by a step when its save is refused, and cleared the moment the rider
  /// touches anything.
  RiderFailure? _failure;

  bool _resumed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resumeWhereLeftOff();
  }

  /// Opens on the first step the rider has not answered yet.
  ///
  /// A rider who fills in five steps, closes the app and comes back should not
  /// have to tap through five screens of their own answers to reach the
  /// documents. Runs once — after that the index is the rider's own.
  void _resumeWhereLeftOff() {
    if (_resumed) return;
    final RiderController rider = context.read<RiderController>();
    if (!rider.hasLoaded) return;

    _resumed = true;

    // The gate asked for a specific step. It knows things the resume logic
    // does not — see [OnboardingScreen.initialStep].
    final OnboardingStep? requested = widget.initialStep;
    if (requested != null) {
      final int target = _steps.indexOf(requested);
      if (target != -1) {
        setState(() => _index = target);
        return;
      }
    }
    final RiderProfile? profile = rider.profile;
    if (profile == null) return;

    final List<OnboardingStep> steps = _stepsFor(profile);
    void land(OnboardingStep step) {
      final int target = steps.indexOf(step);
      if (target != -1) setState(() => _index = target);
    }

    if (!profile.hasIdentity) return; // Step 0 — the default.
    if (!profile.hasVehicle) {
      land(OnboardingStep.vehicle);
      return;
    }

    // Past the profile steps, the KYC file is the only evidence of progress.
    // `pan` is the one detail field the API echoes back, so it stands in for
    // "the identity-numbers step is done"; the rest are write-only by design
    // (Aadhaar and bank details are hidden on the model and never returned).
    final RiderKycSummary kyc = profile.kyc;
    if (kyc.pan == null) {
      land(OnboardingStep.identityNumbers);
      return;
    }
    // Only asked of a rider who has papers at all. Without this guard a
    // walking rider resumes here forever: the two fields are never filled
    // because the step they live on is not in their wizard.
    if (steps.contains(OnboardingStep.licence) &&
        (kyc.drivingLicenceNo == null || kyc.insuranceExpiry == null)) {
      land(OnboardingStep.licence);
      return;
    }

    // Bank details cannot be read back at all, so there is no way to know
    // whether that step was done. Land on the documents step if anything is
    // still missing there, otherwise on the review step, and let the rider
    // walk back if the bank details still need entering.
    land(
      rider.kyc.missingDocuments.isEmpty
          ? OnboardingStep.review
          : OnboardingStep.documents,
    );
  }

  void _clearFailure() {
    if (_failure != null) setState(() => _failure = null);
  }

  /// Advances after a successful save, or shows why it did not.
  void _handleResult(RiderFailure? failure) {
    if (!mounted) return;
    if (failure != null) {
      setState(() => _failure = failure);
      return;
    }
    setState(() {
      _failure = null;
      if (_index < _steps.length - 1) _index++;
    });
  }

  void _back() {
    _clearFailure();
    if (_index > 0) setState(() => _index--);
  }

  /// Jumps straight to a step. Used by the review summary's edit links.
  void _goTo(OnboardingStep step) {
    final int target = _steps.indexOf(step);
    if (target == -1) return;
    setState(() {
      _failure = null;
      _index = target;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RiderController rider = context.watch<RiderController>();

    final List<OnboardingStep> steps = _stepsFor(rider.profile);
    // Saving "walk" on the vehicle step drops the licence step out from under
    // the index the rider is standing on, and a rider sitting on the last step
    // when that happens would otherwise index past the end.
    final int index = _index.clamp(0, steps.length - 1);

    final Widget? banner = _failure == null
        ? null
        : AuthErrorBanner(message: _failure!.message(l10n));

    // PopScope rather than a back button: the wizard is the whole screen for a
    // rider who cannot work yet, and a system back that dropped them onto a
    // dead route would be worse than one that walks back a step.
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop && index > 0) _back();
      },
      child: _buildStep(
        step: steps[index],
        index: index,
        total: steps.length,
        rider: rider,
        banner: banner,
      ),
    );
  }

  Widget _buildStep({
    required OnboardingStep step,
    required int index,
    required int total,
    required RiderController rider,
    required Widget? banner,
  }) {
    final OnboardingStepContext stepContext = OnboardingStepContext(
      index: index,
      total: total,
      rider: rider,
      banner: banner,
      onBack: index == 0 ? null : _back,
      onResult: _handleResult,
      onEdited: _clearFailure,
      goTo: _goTo,
    );

    switch (step) {
      case OnboardingStep.identity:
        return IdentityStep(context: stepContext);
      case OnboardingStep.vehicle:
        return VehicleStep(context: stepContext);
      case OnboardingStep.identityNumbers:
        return IdentityNumbersStep(context: stepContext);
      case OnboardingStep.licence:
        return LicenceStep(context: stepContext);
      case OnboardingStep.bank:
        return BankStep(context: stepContext);
      case OnboardingStep.documents:
        return DocumentsStep(context: stepContext);
      case OnboardingStep.review:
        return ReviewStep(context: stepContext);
    }
  }
}

/// The steps, in the order the wizard runs them.
enum OnboardingStep {
  identity,
  vehicle,
  identityNumbers,
  licence,
  bank,
  documents,
  review,
}

/// What every step needs from the wizard around it.
///
/// Bundled into one object so a step's constructor does not grow a parameter
/// each time the wizard learns something new, and so [OnboardingScaffold] can
/// be fed from it directly.
@immutable
class OnboardingStepContext {
  const OnboardingStepContext({
    required this.index,
    required this.total,
    required this.rider,
    required this.banner,
    required this.onBack,
    required this.onResult,
    required this.onEdited,
    required this.goTo,
  });

  final int index;
  final int total;
  final RiderController rider;

  /// Rendered above the action bar when the previous save was refused.
  final Widget? banner;

  final VoidCallback? onBack;

  /// Called with the outcome of a save: null advances, anything else shows.
  final ValueChanged<RiderFailure?> onResult;

  /// Called on the first keystroke, to clear a stale server error.
  final VoidCallback onEdited;

  final void Function(OnboardingStep) goTo;
}
