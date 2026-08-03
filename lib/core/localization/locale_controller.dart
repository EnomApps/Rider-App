import 'package:flutter/widgets.dart';

import '../services/preferences_service.dart';
import 'app_language.dart';

/// Owns the active language and persists it.
///
/// Seeded from storage on first build; if nothing is stored the device locale
/// is offered as a suggestion but English stays the active default until the
/// user confirms a choice on the language screen.
class LocaleController extends ChangeNotifier {
  LocaleController(this._preferences)
      : _language = AppLanguages.byCode(_preferences.languageCode),
        _hasChosen = _preferences.hasChosenLanguage;

  final PreferencesService _preferences;

  AppLanguage _language;
  bool _hasChosen;

  AppLanguage get language => _language;

  Locale get locale => _language.locale;

  TextDirection get textDirection => _language.textDirection;

  /// False until the user confirms a language at least once.
  bool get hasChosenLanguage => _hasChosen;

  /// Best guess for a fresh install: the device language if Nexmile supports
  /// it, otherwise English. Used to pre-select a tile, never to skip the
  /// language screen.
  AppLanguage suggestionFor(Locale deviceLocale) =>
      AppLanguages.fromLocale(deviceLocale);

  /// Previews a language without marking onboarding complete, so the language
  /// screen can re-render live as the user taps through the list.
  void preview(AppLanguage language) {
    if (_language == language) return;
    _language = language;
    notifyListeners();
  }

  /// Commits the selection and records that onboarding is done.
  Future<void> confirm(AppLanguage language) async {
    _language = language;
    _hasChosen = true;
    await _preferences.saveLanguage(language.code);
    notifyListeners();
  }

  /// Restores the pre-preview language — used when the user backs out of the
  /// language screen without pressing Continue.
  void restorePersisted() {
    final AppLanguage stored = AppLanguages.byCode(_preferences.languageCode);
    if (stored == _language) return;
    _language = stored;
    notifyListeners();
  }
}
