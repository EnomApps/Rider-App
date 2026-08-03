import 'package:flutter/widgets.dart';

/// A language offered on the language-selection screen.
@immutable
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
    this.isRtl = false,
    this.isDefault = false,
    this.isPriority = false,
  });

  /// ISO 639 code, matching the `app_<code>.arb` file.
  final String code;

  /// The language's own name in its own script — what users actually scan for.
  final String nativeName;

  /// English exonym, shown underneath as a fallback cue.
  final String englishName;

  /// True for Perso-Arabic scripts, which lay out right-to-left.
  final bool isRtl;

  /// True for English, the app default.
  final bool isDefault;

  /// Shown in the "suggested" block at the top of the list.
  final bool isPriority;

  Locale get locale => Locale(code);

  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// Case-insensitive match against either name or the language code, used by
  /// the search field.
  bool matches(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return nativeName.toLowerCase().contains(q) ||
        englishName.toLowerCase().contains(q) ||
        code.toLowerCase() == q;
  }

  @override
  bool operator ==(Object other) =>
      other is AppLanguage && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// The catalogue of languages Nexmile ships with: English plus all 22 languages
/// listed in the Eighth Schedule to the Constitution of India.
///
/// Ordering is deliberate — English (the default) and Tamil lead, then Hindi,
/// then the remainder alphabetically by English name.
class AppLanguages {
  const AppLanguages._();

  static const AppLanguage english = AppLanguage(
    code: 'en',
    nativeName: 'English',
    englishName: 'English',
    isDefault: true,
    isPriority: true,
  );

  static const AppLanguage tamil = AppLanguage(
    code: 'ta',
    nativeName: 'தமிழ்',
    englishName: 'Tamil',
    isPriority: true,
  );

  static const AppLanguage hindi = AppLanguage(
    code: 'hi',
    nativeName: 'हिन्दी',
    englishName: 'Hindi',
    isPriority: true,
  );

  /// Every supported language, in display order.
  static const List<AppLanguage> all = <AppLanguage>[
    english,
    tamil,
    hindi,
    AppLanguage(code: 'as', nativeName: 'অসমীয়া', englishName: 'Assamese'),
    AppLanguage(code: 'bn', nativeName: 'বাংলা', englishName: 'Bengali'),
    AppLanguage(code: 'brx', nativeName: 'बड़ो', englishName: 'Bodo'),
    AppLanguage(code: 'doi', nativeName: 'डोगरी', englishName: 'Dogri'),
    AppLanguage(code: 'gu', nativeName: 'ગુજરાતી', englishName: 'Gujarati'),
    AppLanguage(code: 'kn', nativeName: 'ಕನ್ನಡ', englishName: 'Kannada'),
    AppLanguage(
      code: 'ks',
      nativeName: 'کٲشُر',
      englishName: 'Kashmiri',
      isRtl: true,
    ),
    AppLanguage(code: 'kok', nativeName: 'कोंकणी', englishName: 'Konkani'),
    AppLanguage(code: 'mai', nativeName: 'मैथिली', englishName: 'Maithili'),
    AppLanguage(code: 'ml', nativeName: 'മലയാളം', englishName: 'Malayalam'),
    AppLanguage(code: 'mni', nativeName: 'মৈতৈলোন্', englishName: 'Manipuri'),
    AppLanguage(code: 'mr', nativeName: 'मराठी', englishName: 'Marathi'),
    AppLanguage(code: 'ne', nativeName: 'नेपाली', englishName: 'Nepali'),
    AppLanguage(code: 'or', nativeName: 'ଓଡ଼ିଆ', englishName: 'Odia'),
    AppLanguage(code: 'pa', nativeName: 'ਪੰਜਾਬੀ', englishName: 'Punjabi'),
    AppLanguage(code: 'sa', nativeName: 'संस्कृतम्', englishName: 'Sanskrit'),
    AppLanguage(code: 'sat', nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ', englishName: 'Santali'),
    AppLanguage(
      code: 'sd',
      nativeName: 'سنڌي',
      englishName: 'Sindhi',
      isRtl: true,
    ),
    AppLanguage(code: 'te', nativeName: 'తెలుగు', englishName: 'Telugu'),
    AppLanguage(
      code: 'ur',
      nativeName: 'اردو',
      englishName: 'Urdu',
      isRtl: true,
    ),
  ];

  /// English — used whenever nothing has been chosen or a stored code is stale.
  static const AppLanguage fallback = english;

  static AppLanguage byCode(String? code) {
    if (code == null) return fallback;
    for (final AppLanguage language in all) {
      if (language.code == code) return language;
    }
    return fallback;
  }

  /// Resolves the device locale to a supported language, falling back to
  /// English. Only the language subtag is considered; `ta_IN` and `ta_LK` both
  /// resolve to Tamil.
  static AppLanguage fromLocale(Locale? locale) =>
      locale == null ? fallback : byCode(locale.languageCode);

  static List<Locale> get supportedLocales =>
      all.map((AppLanguage l) => l.locale).toList(growable: false);
}
