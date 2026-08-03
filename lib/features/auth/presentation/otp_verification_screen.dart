import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../data/auth_failure.dart';
import '../data/auth_session.dart';
import '../state/auth_controller.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/otp_input.dart';

/// Verifies the six-digit code and signs the customer in.
///
/// This is the whole of account creation as well: the API creates the account
/// on the first successful verification, so a new customer and a returning one
/// see exactly this screen.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.args});

  final OtpArgs args;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _codeLength = 6;

  final TextEditingController _code = TextEditingController();

  Timer? _ticker;
  int _secondsLeft = 0;
  AuthFailure? _failure;
  bool _incomplete = false;

  @override
  void initState() {
    super.initState();
    // Cooldown comes from the server's `resend_after` rather than a hard-coded
    // number, so client and API cannot drift apart.
    _startCooldown(context.read<AuthController>().challenge?.resendAfter ?? 60);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _ticker?.cancel();
    setState(() => _secondsLeft = seconds);
    if (seconds <= 0) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();

    if (_code.text.length < _codeLength) {
      setState(() {
        _incomplete = true;
        _failure = null;
      });
      return;
    }

    setState(() {
      _incomplete = false;
      _failure = null;
    });

    final NavigatorState navigator = Navigator.of(context);
    final AuthController auth = context.read<AuthController>();

    final AuthFailure? failure = await auth.verifyCode(
      identifier: widget.args.identifier,
      code: _code.text,
    );

    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _failure = failure;
        // A rejected code is spent after five attempts; clearing the boxes
        // makes that obvious rather than leaving stale digits on screen.
        _code.clear();
      });
      return;
    }

    navigator.pushNamedAndRemoveUntil(
      AppRoutes.home,
      (Route<void> route) => false,
    );
  }

  Future<void> _resend() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AuthController auth = context.read<AuthController>();

    final AuthFailure? failure = await auth.requestCode(widget.args.identifier);

    if (!mounted) return;
    if (failure != null) {
      setState(() => _failure = failure);
      return;
    }
    _code.clear();
    setState(() {
      _failure = null;
      _incomplete = false;
    });
    _startCooldown(auth.challenge?.resendAfter ?? 60);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.codeResent)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AuthController auth = context.watch<AuthController>();
    final bool isBusy = auth.isBusy;
    final bool canResend = _secondsLeft == 0 && !isBusy;
    final OtpChallenge? challenge = auth.challenge;

    return AuthScaffold(
      title: l10n.otpTitle,
      subtitle: l10n.otpSubtitle(widget.args.identifier.display),
      children: <Widget>[
        OtpInput(
          controller: _code,
          length: _codeLength,
          enabled: !isBusy,
          hasError: _failure != null || _incomplete,
          onCompleted: (_) => _verify(),
        ),
        if (_incomplete) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            l10n.enterFullCode,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        if (_failure != null) ...<Widget>[
          const SizedBox(height: 18),
          AuthErrorBanner(message: _failure!.message(l10n)),
        ],
        const SizedBox(height: 26),
        AuthSubmitButton(
          label: l10n.verifyCode,
          isBusy: isBusy,
          onPressed: _verify,
        ),
        const SizedBox(height: 14),
        Center(
          child: canResend
              ? TextButton(
                  onPressed: _resend,
                  child: Text(l10n.resendCode),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.resendCodeIn(_secondsLeft),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
        ),
        if (challenge?.debugCode != null) ...<Widget>[
          const SizedBox(height: 8),
          _DevelopmentCodeCard(
            code: challenge!.debugCode!,
            onUse: () => _code.text = challenge.debugCode!,
          ),
        ],
      ],
    );
  }
}

/// Shows the code the API hands back in `debug_code`.
///
/// The backend only populates that field outside production — while there is no
/// SMS gateway, codes go to `laravel.log` instead of being delivered. The card
/// is additionally gated on [kReleaseMode] so a misconfigured production
/// response can never surface a live code in a shipped build.
class _DevelopmentCodeCard extends StatelessWidget {
  const _DevelopmentCodeCard({required this.code, required this.onUse});

  final String code;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.science_outlined,
            size: 19,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.developmentCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  code,
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUse,
            style: TextButton.styleFrom(
              foregroundColor:
                  isDark ? AppColors.greenLight : AppColors.greenDeep,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 40),
            ),
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
  }
}
