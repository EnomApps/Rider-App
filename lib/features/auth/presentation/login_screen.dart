import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../data/auth_failure.dart';
import '../data/login_identifier.dart';
import '../state/auth_controller.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/login_hero.dart';

/// Rider sign-in, and the first screen a new install sees after the
/// permission pages.
///
/// An illustrated header, one line about the work, then a single field and
/// Continue. The field asks for an email address, which is what riders sign
/// in with today; a ten-digit mobile number typed into it is still accepted,
/// as before. The OTP flow is the customer app's, with `intended_role: rider`:
/// the account is created on first successful verification, so new and
/// returning riders see the same screen.
///
/// The language starts as English. "Change language" sits under the field for
/// anyone who wants another, instead of a language screen every new install
/// has to get past first.
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

  void _changeLanguage() {
    FocusScope.of(context).unfocus();
    // `false`: not first-run setup, so the picker has a back arrow and comes
    // back here once a language is chosen.
    Navigator.of(context).pushNamed(AppRoutes.language, arguments: false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isBusy = context.watch<AuthController>().isBusy;
    final AppLanguage language = context.watch<LocaleController>().language;
    final MediaQueryData media = MediaQuery.of(context);

    // The picture takes a little under half the screen, behind the status
    // bar too, and gives way on a short phone so the field stays in reach.
    final double heroHeight =
        (media.size.height * 0.45).clamp(220.0, 400.0) + media.padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status bar icons over the dark picture.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          // Tapping the background dismisses the keyboard.
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: <Widget>[
                LoginHero(
                  height: heroHeight,
                  tagline: l10n.tagline,
                  topInset: media.padding.top,
                  dishes: kRiderHeroDishes,
                  badge: l10n.loginHeroBadge,
                ),
                // The form sheet rides up over the bottom of the picture.
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        26,
                        24,
                        24 + media.padding.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            l10n.loginHeadline,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _LabelledRule(text: l10n.loginOrSignUp),
                          const SizedBox(height: 18),
                          Form(
                            key: _formKey,
                            child: AutofillGroup(
                              child: AuthTextField(
                                label: l10n.emailLabel,
                                controller: _input,
                                hint: l10n.loginEmailHint,
                                prefixIcon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                autofillHints: const <String>[
                                  AutofillHints.email,
                                ],
                                enabled: !isBusy,
                                validator: (String? value) =>
                                    LoginIdentifier.tryParse(value) == null
                                        ? l10n.invalidEmail
                                        : null,
                                onSubmitted: (_) => isBusy ? null : _submit(),
                                onChanged: (_) {
                                  if (_failure != null) {
                                    setState(() => _failure = null);
                                  }
                                },
                              ),
                            ),
                          ),
                          if (_failure != null) ...<Widget>[
                            const SizedBox(height: 14),
                            AuthErrorBanner(message: _failure!.message(l10n)),
                          ],
                          const SizedBox(height: 8),
                          _LanguageRow(
                            language: language,
                            action: l10n.changeLanguage,
                            onTap: isBusy ? null : _changeLanguage,
                          ),
                          const SizedBox(height: 14),
                          AuthSubmitButton(
                            label: l10n.continueLabel,
                            isBusy: isBusy,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 20),
                          // The OTP flow is shared byte-for-byte with the
                          // customer app; only `intended_role` differs. Saying
                          // which app this is stops a customer creating a
                          // rider account by downloading the wrong one.
                          _LegalNote(text: l10n.loginRiderNote),
                          const SizedBox(height: 8),
                          _LegalNote(text: l10n.agreeToTermsOnContinue),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "—— Log in or sign up ——"
class _LabelledRule extends StatelessWidget {
  const _LabelledRule({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Equal rules either side, with the words capped so a long translation
    // wraps instead of pushing the rules away.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) => Row(
        children: <Widget>[
          const Expanded(child: Divider()),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: box.maxWidth * 0.7),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

/// The current language, and the way to change it.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.action,
    required this.onTap,
  });

  final AppLanguage language;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = theme.brightness == Brightness.dark
        ? AppColors.greenLight
        : AppColors.greenDeep;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: <Widget>[
            Icon(Icons.translate_rounded, size: 20, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                language.nativeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: language.textDirection,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                action,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: accent),
          ],
        ),
      ),
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
