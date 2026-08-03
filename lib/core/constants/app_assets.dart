/// Asset paths, kept in one place so a rebrand touches a single file.
class AppAssets {
  const AppAssets._();

  /// Full logo lockup: mark + wordmark + tagline + feature row.
  static const String logo = 'assets/images/nexmile_logo.png';

  /// The "N + pin" mark alone, centred on the brand black.
  static const String mark = 'assets/images/nexmile_mark.png';

  /// The "N + pin" symbol on a transparent background, trimmed to its content.
  /// Separated out so the splash can animate and light-sweep it on its own.
  static const String symbol = 'assets/images/nexmile_symbol.png';

  /// The "Nexmile" wordmark on a transparent background, trimmed to content.
  static const String wordmark = 'assets/images/nexmile_wordmark.png';

  /// Square store/launcher icon.
  static const String icon = 'assets/icon/nexmile_icon.png';
}
