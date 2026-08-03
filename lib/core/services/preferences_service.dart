import 'package:shared_preferences/shared_preferences.dart';

/// Thin typed wrapper over [SharedPreferences].
class PreferencesService {
  PreferencesService(this._prefs);

  static const String _languageCodeKey = 'nexmile.language_code';
  static const String _languageChosenKey = 'nexmile.language_chosen';
  static const String _sessionKey = 'nexmile.session';

  final SharedPreferences _prefs;

  static Future<PreferencesService> create() async =>
      PreferencesService(await SharedPreferences.getInstance());

  /// The stored language code, or `null` on a fresh install.
  String? get languageCode => _prefs.getString(_languageCodeKey);

  /// Whether the user has been through the language screen at least once.
  /// Drives whether the splash lands on the language screen or straight home.
  bool get hasChosenLanguage => _prefs.getBool(_languageChosenKey) ?? false;

  Future<void> saveLanguage(String code) async {
    await _prefs.setString(_languageCodeKey, code);
    await _prefs.setBool(_languageChosenKey, true);
  }

  /// Test / "reset onboarding" helper.
  Future<void> clearLanguage() async {
    await _prefs.remove(_languageCodeKey);
    await _prefs.remove(_languageChosenKey);
  }

  /// The encoded [AuthUser] of the signed-in customer, or null when signed out.
  ///
  /// Note for the API integration: this holds profile data only. Once real
  /// access/refresh tokens exist they belong in the keychain / keystore via
  /// `flutter_secure_storage`, not in SharedPreferences, which is readable on
  /// a rooted or jailbroken device.
  String? get session => _prefs.getString(_sessionKey);

  Future<void> saveSession(String encodedUser) =>
      _prefs.setString(_sessionKey, encodedUser);

  Future<void> clearSession() => _prefs.remove(_sessionKey);
}
