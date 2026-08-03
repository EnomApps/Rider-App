import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../data/auth_failure.dart';
import '../data/login_identifier.dart';
import '../state/auth_controller.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';

/// Customer sign-in.
///
/// One field, accepting an email address **or** a ten-digit mobile number.
/// The API has no password, no registration and no password recovery for
/// customers: `POST /v1/auth/otp/request` creates the account on first
/// successful verification, so this screen serves new and returning customers
/// identically.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _input = TextEditingController();

  AuthFailure? _failure;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _failure = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final LoginIdentifier? identifier = LoginIdentifier.tryParse(_input.text);
    if (identifier == null) return; // The validator already flagged it.

    final NavigatorState navigator = Navigator.of(context);
    final AuthFailure? failure =
        await context.read<AuthController>().requestCode(identifier);

    if (!mounted) return;
    if (failure != null) {
      setState(() => _failure = failure);
      return;
    }
    navigator.pushNamed(
      AppRoutes.otpVerification,
      arguments: OtpArgs(identifier: identifier),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isBusy = context.watch<AuthController>().isBusy;

    return AuthScaffold(
      // Entry point of the flow — there is nothing behind it to go back to.
      showBack: false,
      title: l10n.loginTitle,
      subtitle: l10n.loginSubtitle,
      children: <Widget>[
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: AuthTextField(
              label: l10n.emailOrPhoneLabel,
              controller: _input,
              hint: l10n.emailOrPhoneHint,
              prefixIcon: Icons.person_outline_rounded,
              // Plain text, not emailAddress: the field also takes a phone
              // number, and an email keyboard hides the digits.
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[
                AutofillHints.email,
                AutofillHints.telephoneNumber,
              ],
              enabled: !isBusy,
              autofocus: true,
              validator: (String? value) =>
                  LoginIdentifier.tryParse(value) == null
                      ? l10n.invalidEmailOrPhone
                      : null,
              onSubmitted: (_) => isBusy ? null : _submit(),
              onChanged: (_) {
                if (_failure != null) setState(() => _failure = null);
              },
            ),
          ),
        ),
        if (_failure != null) ...<Widget>[
          const SizedBox(height: 18),
          AuthErrorBanner(message: _failure!.message(l10n)),
        ],
        const SizedBox(height: 26),
        AuthSubmitButton(
          label: l10n.sendCode,
          isBusy: isBusy,
          onPressed: _submit,
        ),
        const SizedBox(height: 18),
        // The OTP flow is shared byte-for-byte with the customer app; only
        // `intended_role` differs. Saying which app this is here stops a
        // customer creating a rider account by downloading the wrong one.
        _LegalNote(text: l10n.loginRiderNote),
        const SizedBox(height: 10),
        _LegalNote(text: l10n.agreeToTermsOnContinue),
      ],
    );
  }
}

/// Implicit consent line. The API creates the account on first verification,
/// so this is the only point at which terms can reasonably be surfaced.
class _LegalNote extends StatelessWidget {
  const _LegalNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
