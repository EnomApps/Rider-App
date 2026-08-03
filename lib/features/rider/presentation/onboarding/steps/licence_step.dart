import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../generated/l10n/app_localizations.dart';
import '../../../data/kyc_validators.dart';
import '../../../data/rider_profile.dart';
import '../../widgets/rider_form_field.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_screen.dart';
import 'vehicle_step.dart' show UpperCaseTextFormatter;

/// Step 4 — licence and insurance. Detail fields 5 to 8 of 11.
///
/// Both expiry dates are validated as future-dated here rather than left to
/// the server. The API accepts a lapsed date on this endpoint and only refuses
/// later, when the rider tries to go online — which would mean discovering the
/// problem days after onboarding, with no obvious connection to what caused it.
class LicenceStep extends StatefulWidget {
  const LicenceStep({super.key, required this.context});

  final OnboardingStepContext context;

  @override
  State<LicenceStep> createState() => _LicenceStepState();
}

class _LicenceStepState extends State<LicenceStep> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _licence = TextEditingController(
    text: widget.context.rider.profile?.kyc.drivingLicenceNo ?? '',
  );
  final TextEditingController _insurance = TextEditingController();

  late DateTime? _licenceExpiry =
      widget.context.rider.profile?.kyc.drivingLicenceExpiry;
  late DateTime? _insuranceExpiry =
      widget.context.rider.profile?.kyc.insuranceExpiry;

  String? _licenceExpiryError;
  String? _insuranceExpiryError;

  @override
  void dispose() {
    _licence.dispose();
    _insurance.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();

    final String? licenceError =
        KycValidators.futureDate(_licenceExpiry, l10n);
    final String? insuranceError =
        KycValidators.futureDate(_insuranceExpiry, l10n);

    setState(() {
      _licenceExpiryError = licenceError;
      _insuranceExpiryError = insuranceError;
    });

    final bool formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || licenceError != null || insuranceError != null) return;

    widget.context.onResult(
      await widget.context.rider.saveDetails(
        KycDetails(
          drivingLicenceNo: _licence.text.trim().toUpperCase(),
          drivingLicenceExpiry: _licenceExpiry,
          insuranceNumber: _insurance.text.trim(),
          insuranceExpiry: _insuranceExpiry,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OnboardingStepContext step = widget.context;
    final bool busy = step.rider.isSaving;

    final DateTime today = DateTime.now();
    // From tomorrow: a document expiring today is spent by the time the review
    // comes back. Twenty years covers the longest licence India issues.
    final DateTime earliest = today.add(const Duration(days: 1));
    final DateTime latest = DateTime(today.year + 20, today.month, today.day);

    return OnboardingScaffold(
      stepIndex: step.index,
      stepCount: step.total,
      title: l10n.stepLicenceTitle,
      subtitle: l10n.stepLicenceSubtitle,
      onBack: step.onBack,
      isBusy: busy,
      banner: step.banner,
      primaryLabel: l10n.saveAndContinue,
      onPrimary: _submit,
      formKey: _formKey,
      children: <Widget>[
        RiderTextField(
          label: l10n.drivingLicenceNoLabel,
          controller: _licence,
          prefixIcon: Icons.credit_card_outlined,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: <TextInputFormatter>[UpperCaseTextFormatter()],
          maxLength: 20,
          enabled: !busy,
          serverError: step.rider.fieldError('driving_licence_no'),
          validator: (String? value) => KycValidators.required(value, l10n),
          onChanged: (_) => step.onEdited(),
        ),
        RiderDateField(
          label: l10n.drivingLicenceExpiryLabel,
          value: _licenceExpiry,
          firstDate: earliest,
          lastDate: latest,
          enabled: !busy,
          serverError: step.rider.fieldError('driving_licence_expiry'),
          errorText: _licenceExpiryError,
          onChanged: (DateTime value) {
            step.onEdited();
            setState(() {
              _licenceExpiry = value;
              _licenceExpiryError = null;
            });
          },
        ),
        RiderTextField(
          label: l10n.insuranceNumberLabel,
          controller: _insurance,
          prefixIcon: Icons.shield_outlined,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: <TextInputFormatter>[UpperCaseTextFormatter()],
          maxLength: 40,
          enabled: !busy,
          serverError: step.rider.fieldError('insurance_number'),
          validator: (String? value) => KycValidators.required(value, l10n),
          onChanged: (_) => step.onEdited(),
        ),
        RiderDateField(
          label: l10n.insuranceExpiryLabel,
          value: _insuranceExpiry,
          firstDate: earliest,
          lastDate: latest,
          enabled: !busy,
          serverError: step.rider.fieldError('insurance_expiry'),
          errorText: _insuranceExpiryError,
          onChanged: (DateTime value) {
            step.onEdited();
            setState(() {
              _insuranceExpiry = value;
              _insuranceExpiryError = null;
            });
          },
        ),
      ],
    );
  }
}
