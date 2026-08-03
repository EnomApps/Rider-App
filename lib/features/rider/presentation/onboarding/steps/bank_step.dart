import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../generated/l10n/app_localizations.dart';
import '../../../data/kyc_validators.dart';
import '../../../data/rider_profile.dart';
import '../../widgets/rider_form_field.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_screen.dart';
import 'vehicle_step.dart' show UpperCaseTextFormatter;

/// Step 5 — settlement account. Detail fields 9 to 11 of 11.
///
/// Nothing here is ever prefilled. The API hides bank details on the model and
/// never returns them, which is correct for an account number and means a
/// rider revisiting this step retypes it — the one place in the wizard where
/// that is a feature, since a typo here costs them their earnings.
class BankStep extends StatefulWidget {
  const BankStep({super.key, required this.context});

  final OnboardingStepContext context;

  @override
  State<BankStep> createState() => _BankStepState();
}

class _BankStepState extends State<BankStep> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _holder = TextEditingController();
  final TextEditingController _account = TextEditingController();
  final TextEditingController _ifsc = TextEditingController();

  @override
  void dispose() {
    _holder.dispose();
    _account.dispose();
    _ifsc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.context.onResult(
      await widget.context.rider.saveDetails(
        KycDetails(
          bankAccountName: _holder.text.trim(),
          bankAccountNumber: _account.text.replaceAll(RegExp(r'\s'), ''),
          bankIfsc: _ifsc.text.trim().toUpperCase(),
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
      title: l10n.stepBankTitle,
      subtitle: l10n.stepBankSubtitle,
      onBack: step.onBack,
      isBusy: busy,
      banner: step.banner,
      primaryLabel: l10n.saveAndContinue,
      onPrimary: _submit,
      formKey: _formKey,
      children: <Widget>[
        RiderTextField(
          label: l10n.bankAccountNameLabel,
          controller: _holder,
          prefixIcon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
          keyboardType: TextInputType.name,
          maxLength: 255,
          enabled: !busy,
          serverError: step.rider.fieldError('bank_account_name'),
          validator: (String? value) => KycValidators.required(value, l10n),
          onChanged: (_) => step.onEdited(),
        ),
        RiderTextField(
          label: l10n.bankAccountNumberLabel,
          controller: _account,
          prefixIcon: Icons.account_balance_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          maxLength: 30,
          enabled: !busy,
          serverError: step.rider.fieldError('bank_account_number'),
          validator: (String? value) =>
              KycValidators.accountNumber(value, l10n),
          onChanged: (_) => step.onEdited(),
        ),
        RiderTextField(
          label: l10n.bankIfscLabel,
          hint: l10n.bankIfscHint,
          controller: _ifsc,
          prefixIcon: Icons.pin_outlined,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: <TextInputFormatter>[UpperCaseTextFormatter()],
          maxLength: 11,
          enabled: !busy,
          serverError: step.rider.fieldError('bank_ifsc'),
          validator: (String? value) => KycValidators.ifsc(value, l10n),
          onChanged: (_) => step.onEdited(),
        ),
      ],
    );
  }
}
