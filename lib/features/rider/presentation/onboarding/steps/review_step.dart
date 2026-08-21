import 'package:flutter/material.dart';

import '../../../../../core/widgets/info_tile.dart';
import '../../../../../generated/l10n/app_localizations.dart';
import '../../../data/kyc_models.dart';
import '../../../data/rider_profile.dart';
import '../../../state/rider_controller.dart';
import '../../widgets/rider_form_field.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_screen.dart';

/// Step 7 — a last look, then `POST /v1/rider/kyc/submit`.
///
/// Only shows what the API will give back. Aadhaar and the bank details are
/// hidden on the model and never returned, so they are summarised as "on file"
/// rather than echoed — this screen cannot show a rider the account number
/// they typed, and pretending otherwise by holding it in memory would be worse
/// than saying so.
class ReviewStep extends StatelessWidget {
  const ReviewStep({super.key, required this.context});

  final OnboardingStepContext context;

  @override
  Widget build(BuildContext buildContext) {
    final AppLocalizations l10n = AppLocalizations.of(buildContext);
    final OnboardingStepContext step = context;
    final RiderController rider = step.rider;
    final RiderProfile? profile = rider.profile;
    final KycOverview kyc = rider.kyc;

    return OnboardingScaffold(
      stepIndex: step.index,
      stepCount: step.total,
      title: l10n.stepReviewTitle,
      subtitle: l10n.stepReviewSubtitle,
      onBack: step.onBack,
      isBusy: rider.isSaving,
      banner: step.banner,
      primaryLabel: l10n.submitForVerification,
      // `canSubmit` is the server's verdict plus the two profile fields the
      // KYC endpoint does not know about. Disabled rather than hidden, so the
      // rider can see the button they are working towards.
      onPrimary: rider.canSubmit ? () => _confirm(buildContext, step) : null,
      children: <Widget>[
        if (profile != null) ...<Widget>[
          InfoTile(
            icon: Icons.person_outline_rounded,
            label: l10n.fullNameLabel,
            value: profile.fullName.isEmpty
                ? l10n.notProvided
                : profile.fullName,
            emphasise: profile.fullName.isNotEmpty,
            onTap: () => step.goTo(OnboardingStep.identity),
          ),
          const SizedBox(height: 12),
          InfoTile(
            icon: Icons.two_wheeler_outlined,
            label: l10n.vehicleLabel,
            value: _vehicleSummary(profile, l10n),
            valueDirection: TextDirection.ltr,
            onTap: () => step.goTo(OnboardingStep.vehicle),
          ),
          const SizedBox(height: 12),
          InfoTile(
            icon: Icons.article_outlined,
            label: l10n.panLabel,
            value: profile.kyc.pan ?? l10n.notProvided,
            emphasise: profile.kyc.pan != null,
            valueDirection: TextDirection.ltr,
            onTap: () => step.goTo(OnboardingStep.identityNumbers),
          ),
          const SizedBox(height: 12),
          InfoTile(
            icon: Icons.credit_card_outlined,
            label: l10n.drivingLicenceExpiryLabel,
            value: profile.kyc.drivingLicenceExpiry == null
                ? l10n.notProvided
                : formatDate(profile.kyc.drivingLicenceExpiry!),
            emphasise: profile.kyc.drivingLicenceExpiry != null,
            valueDirection: TextDirection.ltr,
            onTap: () => step.goTo(OnboardingStep.licence),
          ),
          const SizedBox(height: 12),
          InfoTile(
            icon: Icons.shield_outlined,
            label: l10n.insuranceExpiryLabel,
            value: profile.kyc.insuranceExpiry == null
                ? l10n.notProvided
                : formatDate(profile.kyc.insuranceExpiry!),
            emphasise: profile.kyc.insuranceExpiry != null,
            valueDirection: TextDirection.ltr,
            onTap: () => step.goTo(OnboardingStep.licence),
          ),
          const SizedBox(height: 12),
        ],
        InfoTile(
          icon: Icons.folder_outlined,
          label: l10n.stepDocumentsTitle,
          value: l10n.documentsProgress(
            kyc.uploadedCount,
            // The *required* six, not the allowed eight. Bank proof and
            // profile photo are optional and do not gate submission, so
            // counting them showed "6 of 8" to a rider who had finished.
            kyc.requiredCount,
          ),
          onTap: () => step.goTo(OnboardingStep.documents),
        ),
        const SizedBox(height: 12),
        InfoTile(
          icon: Icons.account_balance_outlined,
          label: l10n.stepBankTitle,
          value: l10n.bankAccountNumberLabel,
          emphasise: false,
          onTap: () => step.goTo(OnboardingStep.bank),
        ),
      ],
    );
  }

  String _vehicleSummary(RiderProfile profile, AppLocalizations l10n) {
    final String type = switch (profile.vehicleType) {
      VehicleType.motorcycle => l10n.vehicleMotorcycle,
      VehicleType.scooter => l10n.vehicleScooter,
      VehicleType.ev => l10n.vehicleEv,
      VehicleType.bicycle => l10n.vehicleBicycle,
      VehicleType.unknown => l10n.notProvided,
    };
    final String? number = profile.vehicleNumber;
    return (number == null || number.isEmpty) ? type : '$type · $number';
  }

  /// Submitting locks the file until an admin decides, so it asks first.
  Future<void> _confirm(
    BuildContext buildContext,
    OnboardingStepContext step,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(buildContext);

    final bool confirmed = await showDialog<bool>(
          context: buildContext,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(l10n.submitConfirmTitle),
            content: Text(l10n.submitConfirmBody),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancelLabel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.submitForVerification),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    // No navigation on success: submitting flips the profile's KYC status,
    // which moves `RiderController.stage` to `underReview`, and the gate above
    // this wizard swaps the body out on its own.
    step.onResult(await step.rider.submit());
  }
}
