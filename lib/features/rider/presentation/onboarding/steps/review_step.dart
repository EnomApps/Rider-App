import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
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
      icon: Icons.fact_check_rounded,
      bodyInCard: false,
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
        if (profile != null)
          _Section(
            title: l10n.reviewSectionDetails,
            icon: Icons.person_rounded,
            children: <Widget>[
              _Row(
                label: l10n.fullNameLabel,
                value: profile.fullName.isEmpty
                    ? l10n.notProvided
                    : profile.fullName,
                done: profile.fullName.isNotEmpty,
                onEdit: () => step.goTo(OnboardingStep.identity),
              ),
              _Row(
                label: l10n.vehicleLabel,
                value: _vehicleSummary(profile, l10n),
                done: profile.hasVehicle,
                ltr: true,
                onEdit: () => step.goTo(OnboardingStep.vehicle),
              ),
              _Row(
                label: l10n.panLabel,
                value: profile.kyc.pan ?? l10n.notProvided,
                done: profile.kyc.pan != null,
                ltr: true,
                onEdit: () => step.goTo(OnboardingStep.identityNumbers),
              ),
              // Asked only of riders with a licence to have; the step is
              // missing from a walking rider's wizard and so is this.
              if (profile.vehicleType.hasPapers) ...<Widget>[
                _Row(
                  label: l10n.drivingLicenceExpiryLabel,
                  value: profile.kyc.drivingLicenceExpiry == null
                      ? l10n.notProvided
                      : formatDate(profile.kyc.drivingLicenceExpiry!),
                  done: profile.kyc.drivingLicenceExpiry != null,
                  ltr: true,
                  onEdit: () => step.goTo(OnboardingStep.licence),
                ),
                _Row(
                  label: l10n.insuranceExpiryLabel,
                  value: profile.kyc.insuranceExpiry == null
                      ? l10n.notProvided
                      : formatDate(profile.kyc.insuranceExpiry!),
                  done: profile.kyc.insuranceExpiry != null,
                  ltr: true,
                  onEdit: () => step.goTo(OnboardingStep.licence),
                ),
              ],
            ],
          ),
        _Section(
          title: l10n.reviewSectionDocuments,
          icon: Icons.folder_copy_rounded,
          children: <Widget>[
            _Row(
              label: l10n.stepDocumentsTitle,
              value: l10n.documentsProgress(
                kyc.uploadedCount,
                // The *required* six, not the allowed eight. Bank proof and
                // profile photo are optional and do not gate submission, so
                // counting them showed "6 of 8" to a rider who had finished.
                kyc.requiredCount,
              ),
              done: kyc.requiredCount > 0 &&
                  kyc.uploadedCount >= kyc.requiredCount,
              onEdit: () => step.goTo(OnboardingStep.documents),
            ),
          ],
        ),
        _Section(
          title: l10n.reviewSectionBank,
          icon: Icons.account_balance_rounded,
          children: <Widget>[
            // Bank details are write-only on the API, so this says they are
            // on file rather than echoing a number it cannot read back.
            _Row(
              label: l10n.stepBankTitle,
              value: l10n.reviewBankHidden,
              done: true,
              onEdit: () => step.goTo(OnboardingStep.bank),
            ),
          ],
        ),
        const _WhatNext(),
      ],
    );
  }

  String _vehicleSummary(RiderProfile profile, AppLocalizations l10n) {
    final String type = switch (profile.vehicleType) {
      VehicleType.motorcycle => l10n.vehicleMotorcycle,
      VehicleType.scooter => l10n.vehicleScooter,
      VehicleType.ev => l10n.vehicleEv,
      VehicleType.bicycle => l10n.vehicleBicycle,
      VehicleType.walk => l10n.vehicleWalk,
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

/// One block of the summary: a heading and its rows, on a white card.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 20, color: AppColors.greenDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

/// A line of the summary: a tick or a gap, the label and value, and Edit.
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.done,
    required this.onEdit,
    this.ltr = false,
  });

  final String label;
  final String value;
  final bool done;
  final VoidCallback onEdit;

  /// Numbers and dates read left to right in every language.
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 20,
              color: done ? AppColors.greenDeep : theme.colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    textDirection: ltr ? TextDirection.ltr : null,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onEdit, child: Text(l10n.reviewEdit)),
          ],
        ),
      ),
    );
  }
}

/// What submitting leads to, as three stops on a line.
class _WhatNext extends StatelessWidget {
  const _WhatNext();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<(IconData, String)> steps = <(IconData, String)>[
      (Icons.send_rounded, l10n.reviewNext1),
      (Icons.verified_user_rounded, l10n.reviewNext2),
      (Icons.delivery_dining_rounded, l10n.reviewNext3),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.greenDeep.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.16 : 0.06,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.reviewNextTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0
                              ? AppColors.greenDeep
                              : theme.colorScheme.surface,
                          border: Border.all(color: AppColors.greenDeep),
                        ),
                        child: Icon(
                          steps[i].$1,
                          size: 17,
                          color: i == 0 ? Colors.white : AppColors.greenDeep,
                        ),
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: AppColors.greenDeep.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 7, bottom: 16),
                      child: Text(
                        steps[i].$2,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
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
