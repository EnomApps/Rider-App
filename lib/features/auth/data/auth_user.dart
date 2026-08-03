import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Mirrors `UserStatus` in the API schema.
enum UserStatus { pending, active, suspended, unknown }

/// Mirrors `UserRole` in the API schema.
enum UserRole { customer, rider, merchant, admin, unknown }

/// The signed-in customer, decoded from `UserResource`.
@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    this.email,
    this.phone,
    this.preferredLocale,
    this.phoneVerified = false,
  });

  final int id;
  final String name;
  final String? email;
  final String? phone;
  final UserRole role;
  final UserStatus status;
  final String? preferredLocale;
  final bool phoneVerified;

  /// Customers are `active` the moment they verify a code — there is no
  /// approval step, unlike riders. Anything else means the account cannot be
  /// used yet.
  bool get isActive => status == UserStatus.active;

  bool get isCustomer => role == UserRole.customer;

  /// First word of the name, for greetings. Falls back to the whole name, then
  /// to whichever identifier we have.
  String get firstName {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return email ?? phone ?? '';
    final int space = trimmed.indexOf(' ');
    return space == -1 ? trimmed : trimmed.substring(0, space);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'status': status.name,
        'preferred_locale': preferredLocale,
        'phone_verified': phoneVerified,
      };

  static AuthUser fromJson(Map<String, dynamic> json) => AuthUser(
        // Laravel returns an int, but be tolerant of a stringified id.
        id: json['id'] is int
            ? json['id'] as int
            : int.tryParse('${json['id']}') ?? 0,
        name: json['name'] as String? ?? '',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        role: _enumFrom(UserRole.values, json['role'], UserRole.unknown),
        status:
            _enumFrom(UserStatus.values, json['status'], UserStatus.unknown),
        preferredLocale: json['preferred_locale'] as String?,
        phoneVerified: json['phone_verified'] as bool? ?? false,
      );

  static T _enumFrom<T extends Enum>(List<T> values, Object? raw, T fallback) {
    if (raw is! String) return fallback;
    for (final T value in values) {
      if (value.name == raw) return value;
    }
    // An unrecognised value means the API grew a case this build predates.
    // Degrading to `unknown` beats throwing on a field the UI barely uses.
    return fallback;
  }

  String encode() => jsonEncode(toJson());

  /// Returns null rather than throwing when the stored blob is from an older
  /// build or is otherwise unreadable — a corrupt session should sign the user
  /// out, not crash the app on launch.
  static AuthUser? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['id'] == null) return null;
      return AuthUser.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) => other is AuthUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
