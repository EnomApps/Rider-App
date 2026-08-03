import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// `flutter_localizations` ships Material/Cupertino strings for most, but not
/// all, of the Eighth Schedule languages. As of Flutter 3.29 there is no
/// bundled translation for Bodo, Dogri, Kashmiri, Konkani, Maithili, Manipuri,
/// Sanskrit, Santali or Sindhi.
///
/// Without a delegate that accepts those locales, `Localizations.of` throws the
/// "No MaterialLocalizations found" assertion the moment a `Scaffold`,
/// `TextField` or `SnackBar` is built — i.e. the app would crash for nine of
/// the twenty-three languages.
///
/// These delegates are registered *after* the global ones, so Flutter's own
/// translations win wherever they exist and only the remaining locales fall
/// through to the English widget chrome. App copy itself is unaffected: that
/// comes from `AppLocalizations`, which does cover all twenty-three.
class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}
