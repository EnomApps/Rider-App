import 'package:flutter/material.dart';

import '../../../../../generated/l10n/app_localizations.dart';
import '../../../data/kyc_validators.dart';
import '../../widgets/rider_form_field.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_screen.dart';

/// Step 1 — name and date of birth. `PATCH /v1/rider/profile`.
class IdentityStep extends StatefulWidget {
  const IdentityStep({super.key, required this.context});

  final OnboardingStepContext context;

  @override
  State<IdentityStep> createState() => _IdentityStepState();
}

class _IdentityStepState extends State<IdentityStep> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.context.rider.profile?.fullName ?? '',
  );

  late DateTime? _dob = widget.context.rider.profile?.dateOfBirth;
  String? _dobError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();

    final String? dobError = KycValidators.adultBirthDate(_dob, l10n);
    setState(() => _dobError = dobError);

    final bool formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || dobError != null) return;

    widget.context.onResult(
      await widget.context.rider.saveIdentity(
        fullName: _name.text.trim(),
        dateOfBirth: _dob,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OnboardingStepContext step = widget.context;
    final DateTime now = DateTime.now();

    return OnboardingScaffold(
      stepIndex: step.index,
      stepCount: step.total,
      title: l10n.stepIdentityTitle,
      subtitle: l10n.stepIdentitySubtitle,
      onBack: step.onBack,
      isBusy: step.rider.isSaving,
      banner: step.banner,
      primaryLabel: l10n.saveAndContinue,
      onPrimary: _submit,
      formKey: _formKey,
      children: <Widget>[
        RiderTextField(
          label: l10n.fullNameLabel,
          hint: l10n.fullNameHint,
          controller: _name,
          prefixIcon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
          keyboardType: TextInputType.name,
          maxLength: 255,
          enabled: !step.rider.isSaving,
          serverError: step.rider.fieldError('full_name'),
          validator: (String? value) => KycValidators.required(value, l10n),
          onChanged: (_) => step.onEdited(),
        ),
        RiderDateField(
          label: l10n.dateOfBirthLabel,
          value: _dob,
          // 18 is the legal floor for a commercial licence; 80 is a generous
          // ceiling that keeps the picker from opening a century back.
          firstDate: DateTime(now.year - 80),
          lastDate: DateTime(now.year - 18, now.month, now.day),
          enabled: !step.rider.isSaving,
          serverError: step.rider.fieldError('date_of_birth'),
          errorText: _dobError,
          onChanged: (DateTime value) {
            step.onEdited();
            setState(() {
              _dob = value;
              _dobError = null;
            });
          },
        ),
      ],
    );
  }
}
