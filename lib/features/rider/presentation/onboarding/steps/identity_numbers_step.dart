import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../generated/l10n/app_localizations.dart';
import '../../../data/kyc_validators.dart';
import '../../../data/rider_profile.dart';
import '../../widgets/rider_form_field.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_screen.dart';
import 'vehicle_step.dart' show UpperCaseTextFormatter;

/// Step 3 — Aadhaar and PAN. Detail fields 3 and 4 of 11.
///
/// The Aadhaar box starts blank even on a return visit: the API hides the
/// number on the model and never returns it, which is the right call for a
/// national identity number and means there is nothing to prefill. PAN *is*
/// echoed back, so that one is restored.
class IdentityNumbersStep extends StatefulWidget {
  const IdentityNumbersStep({super.key, required this.context});

  final OnboardingStepContext context;

  @override
  State<IdentityNumbersStep> createState() => _IdentityNumbersStepState();
}

class _IdentityNumbersStepState extends State<IdentityNumbersStep> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _aadhaar = TextEditingController();
  late final TextEditingController _pan = TextEditingController(
    text: widget.context.rider.profile?.kyc.pan ?? '',
  );

  @override
  void dispose() {
    _aadhaar.dispose();
    _pan.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.context.onResult(
      await widget.context.rider.saveDetails(
        KycDetails(
          aadhaarNumber: _aadhaar.text.replaceAll(RegExp(r'\s'), ''),
          pan: _pan.text.trim().toUpperCase(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OnboardingStepContext step = widget.context;
    final bool busy = step.rider.isSaving;

    return OnboardingScaffold(
      stepIndex: step.index,
      stepCount: step.total,
      title: l10n.stepIdentityNumbersTitle,
      subtitle: l10n.stepIdentityNumbersSubtitle,
      onBack: step.onBack,
      isBusy: busy,
      banner: step.banner,
      primaryLabel: l10n.saveAndContinue,
      onPrimary: _submit,
      formKey: _formKey,
      children: <Widget>[
        RiderTextField(
          label: l10n.aadhaarLabel,
          hint: l10n.aadhaarHint,
          controller: _aadhaar,
          prefixIcon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          maxLength: 12,
          enabled: !busy,
          serverError: step.rider.fieldError('aadhaar_number'),
          validator: (String? value) => KycValidators.aadhaar(value, l10n),
          onChanged: (_) => step.onEdited(),
        ),
        RiderTextField(
          label: l10n.panLabel,
          hint: l10n.panHint,
          controller: _pan,
          prefixIcon: Icons.article_outlined,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: <TextInputFormatter>[UpperCaseTextFormatter()],
          maxLength: 10,
          enabled: !busy,
          serverError: step.rider.fieldError('pan'),
          validator: (String? value) => KycValidators.pan(value, l10n),
          onChanged: (_) => step.onEdited(),
        ),
      ],
    );
  }
}
