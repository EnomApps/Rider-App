import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../generated/l10n/app_localizations.dart';

/// "Exit {app}?" — asked when back is pressed on a screen with nowhere left
/// to go back to, so a stray back swipe never closes the app.
///
/// Returns true once the app is closing.
Future<bool> confirmExit(BuildContext context) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final bool exit = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(l10n.exitTitle),
          content: Text(l10n.exitBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.exitConfirm),
            ),
          ],
        ),
      ) ??
      false;
  if (exit) await SystemNavigator.pop();
  return exit;
}
