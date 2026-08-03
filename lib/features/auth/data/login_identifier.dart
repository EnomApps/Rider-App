import 'package:flutter/foundation.dart';

enum IdentifierKind { email, phone }

/// What the customer typed into the single sign-in field, resolved to either an
/// email address or an Indian mobile number.
///
/// The API takes `email` **or** `phone`, never both, so the app has to decide
/// which one it is before calling. Rules mirror the OpenAPI schema exactly:
/// `^[6-9]\d{9}$` for phone, RFC-ish for email.
@immutable
class LoginIdentifier {
  const LoginIdentifier._(this.kind, this.value);

  final IdentifierKind kind;

  /// Normalised: a phone is ten bare digits, an email is trimmed lowercase.
  final String value;

  bool get isEmail => kind == IdentifierKind.email;

  bool get isPhone => kind == IdentifierKind.phone;

  /// Request body fragment, with only the relevant key present.
  Map<String, dynamic> toJson() => <String, dynamic>{
        if (isEmail) 'email': value else 'phone': value,
      };

  /// How the identifier is shown back to the customer on the OTP screen.
  /// Always left-to-right — both forms read that way in every language.
  String get display => value;

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s.]+(\.[^@\s.]+)+$');
  static final RegExp _phone = RegExp(r'^[6-9]\d{9}$');

  /// Returns null when the input is neither a valid email nor a valid mobile
  /// number.
  ///
  /// Phone input is forgiving about how Indian numbers are commonly typed —
  /// `+91 98765 43210`, `098765-43210` and `9876543210` all normalise to the
  /// same ten digits — because rejecting those would look like a bug to a user
  /// who pasted a number from their contacts.
  static LoginIdentifier? tryParse(String? raw) {
    final String input = (raw ?? '').trim();
    if (input.isEmpty) return null;

    if (input.contains('@')) {
      final String email = input.toLowerCase();
      return _email.hasMatch(email)
          ? LoginIdentifier._(IdentifierKind.email, email)
          : null;
    }

    String digits = input.replaceAll(RegExp(r'[\s()\-.]'), '');
    if (digits.startsWith('+91')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('91') && digits.length == 12) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }

    return _phone.hasMatch(digits)
        ? LoginIdentifier._(IdentifierKind.phone, digits)
        : null;
  }

  @override
  bool operator ==(Object other) =>
      other is LoginIdentifier && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);

  @override
  String toString() => '${kind.name}:$value';
}
