import 'package:flutter/foundation.dart';

/// Mirrors `KycStatus` in the API schema.
enum KycStatus {
  /// Nothing submitted yet — the rider is still filling the wizard in.
  pending,

  /// Sent for review. Read-only until an admin decides.
  submitted,

  /// Approved. The only status from which a rider can go on duty.
  verified,

  /// Turned down; `rejectionReason` says why and the wizard reopens.
  rejected,

  /// A value this build predates. Treated as [pending] everywhere a decision
  /// has to be made, which is the safe direction: it shows the wizard rather
  /// than a live order screen.
  unknown,
}

extension KycStatusX on KycStatus {
  bool get isVerified => this == KycStatus.verified;

  bool get isUnderReview => this == KycStatus.submitted;

  bool get isRejected => this == KycStatus.rejected;

  /// True while the rider may still edit details and swap documents. The API
  /// locks the reference numbers once verified, so the wizard must not offer
  /// an edit it knows will be refused.
  bool get isEditable =>
      this == KycStatus.pending ||
      this == KycStatus.rejected ||
      this == KycStatus.unknown;
}

/// Mirrors `DocumentStatus` — the per-document review outcome.
enum DocumentStatus { pending, approved, rejected, unknown }

/// Mirrors `RiderStatus` — what the rider is doing right now.
enum DutyStatus {
  /// Not working. The default, and where a rider lands after signing in.
  offline,

  /// Working and ready to be dispatched.
  available,

  /// Working but not dispatchable — the API's own third state, so the app
  /// exposes it rather than collapsing duty into a two-way switch.
  onBreak,

  unknown;

  /// Wire value. `on_break` is snake_case on the API and camelCase in Dart, so
  /// the enum name cannot be used directly.
  String get wireValue {
    switch (this) {
      case DutyStatus.offline:
        return 'offline';
      case DutyStatus.available:
        return 'available';
      case DutyStatus.onBreak:
        return 'on_break';
      case DutyStatus.unknown:
        return 'offline';
    }
  }

  static DutyStatus fromWire(Object? raw) {
    switch (raw) {
      case 'offline':
        return DutyStatus.offline;
      case 'available':
        return DutyStatus.available;
      case 'on_break':
        return DutyStatus.onBreak;
      default:
        return DutyStatus.unknown;
    }
  }
}

/// Normalises the API's stringly-typed nulls.
///
/// `GET /v1/rider/profile` returns `"pan":"null"` and
/// `"driving_licence_no":"null"` — the four-character string, not JSON null —
/// and `otp/request` does the same with `debug_code`. Taken at face value that
/// makes "no PAN on file" indistinguishable from a PAN, which is exactly what
/// the onboarding wizard's resume logic keys on: it would skip the identity
/// step for a rider who had never filled it in.
///
/// Worth reporting upstream, but the app cannot wait for that.
String? nullableString(Object? raw) {
  if (raw == null) return null;
  final String value = '$raw'.trim();
  if (value.isEmpty || value == 'null') return null;
  return value;
}

/// One entry in `allowed_documents` — a type the rider may upload.
///
/// The API sends `{"type": "...", "label": "..."}` objects, so the label is
/// server-supplied and a document added on the backend reads correctly without
/// an app release.
@immutable
class KycDocumentType {
  const KycDocumentType({required this.type, required this.label});

  final String type;
  final String label;

  static KycDocumentType fromJson(Map<String, dynamic> json) =>
      KycDocumentType(
        type: json['type'] as String? ?? '',
        label: json['label'] as String? ?? json['type'] as String? ?? '',
      );
}

/// One uploaded file, decoded from `KycDocumentResource`.
@immutable
class KycDocument {
  const KycDocument({
    required this.id,
    required this.type,
    required this.label,
    required this.status,
    required this.originalName,
    required this.sizeBytes,
    this.mimeType = '',
    this.rejectionReason,
    this.uploadedAt,
  });

  final int id;

  /// The slug the API keys uploads on — `aadhaar_front`, `driving_licence`
  /// and so on. Sent back as the `type` field when replacing the file.
  final String type;

  /// Human-readable name, supplied by the server. Preferred over any local
  /// mapping so a document type added after this build still reads correctly.
  final String label;

  final DocumentStatus status;
  final String originalName;
  final int sizeBytes;
  final String mimeType;
  final String? rejectionReason;
  final DateTime? uploadedAt;

  bool get isRejected => status == DocumentStatus.rejected;

  bool get isApproved => status == DocumentStatus.approved;

  static KycDocument fromJson(Map<String, dynamic> json) => KycDocument(
        id: _int(json['id']),
        type: json['type'] as String? ?? '',
        label: json['label'] as String? ?? json['type'] as String? ?? '',
        status: _status(json['status']),
        originalName: json['original_name'] as String? ?? '',
        sizeBytes: _int(json['size_bytes']),
        mimeType: json['mime_type'] as String? ?? '',
        rejectionReason: json['rejection_reason'] as String?,
        uploadedAt: DateTime.tryParse('${json['uploaded_at']}'),
      );

  static DocumentStatus _status(Object? raw) {
    for (final DocumentStatus value in DocumentStatus.values) {
      if (value.name == raw) return value;
    }
    return DocumentStatus.unknown;
  }

  static int _int(Object? raw) =>
      raw is int ? raw : int.tryParse('$raw') ?? 0;
}

/// The whole of `GET /v1/rider/kyc` — status plus what is still outstanding.
///
/// The document checklist is deliberately server-driven. [allowedDocuments]
/// and [missingDocuments] come straight from the API, so adding or retiring a
/// required document is a backend change and not an app release.
@immutable
class KycOverview {
  const KycOverview({
    required this.status,
    required this.documents,
    required this.allowedDocuments,
    required this.requiredDocuments,
    required this.missingDocuments,
    required this.canSubmit,
    this.rejectionReason,
    this.verifiedAt,
  });

  final KycStatus status;
  final List<KycDocument> documents;

  /// Every document type the rider may upload, in the order the API lists it.
  ///
  /// Wider than [requiredDocuments]: the live API allows eight and requires
  /// six, the extra two being a bank proof and a profile photo.
  final List<KycDocumentType> allowedDocuments;

  /// The types that must be on file before KYC can be submitted.
  final List<String> requiredDocuments;

  /// The subset still outstanding. Empty does not by itself mean ready —
  /// [canSubmit] is the API's own verdict and is what the button follows.
  final List<String> missingDocuments;

  final bool canSubmit;
  final String? rejectionReason;

  final DateTime? verifiedAt;

  /// An empty shell, used before the first fetch lands.
  static const KycOverview empty = KycOverview(
    status: KycStatus.pending,
    documents: <KycDocument>[],
    allowedDocuments: <KycDocumentType>[],
    requiredDocuments: <String>[],
    missingDocuments: <String>[],
    canSubmit: false,
  );

  bool isRequired(String type) => requiredDocuments.contains(type);

  /// The uploaded file for [type], or null when nothing is on file yet.
  KycDocument? documentOf(String type) {
    for (final KycDocument document in documents) {
      if (document.type == type) return document;
    }
    return null;
  }

  /// How many of the *required* types have a file against them. Drives the
  /// "3 of 6 uploaded" progress line.
  ///
  /// Counted against [requiredDocuments] rather than [allowedDocuments]: the
  /// API allows eight and requires six, so counting the allowed set would show
  /// "6 of 8" to a rider who has in fact finished.
  int get uploadedCount =>
      requiredDocuments.where((String type) => documentOf(type) != null).length;

  int get requiredCount => requiredDocuments.length;

  bool get hasRejectedDocuments =>
      documents.any((KycDocument document) => document.isRejected);

  static KycOverview fromJson(Map<String, dynamic> data) {
    return KycOverview(
      status: _status(data['status']),
      rejectionReason: nullableString(data['rejection_reason']),
      verifiedAt: DateTime.tryParse('${data['verified_at']}'),
      requiredDocuments: _types(data['required_documents']),
      allowedDocuments: _allowed(data['allowed_documents']),
      missingDocuments: _types(data['missing_documents']),
      canSubmit: data['can_submit'] as bool? ?? false,
      documents: <KycDocument>[
        for (final Object? raw in data['documents'] as List<Object?>? ??
            const <Object?>[])
          if (raw is Map<String, dynamic>) KycDocument.fromJson(raw),
      ],
    );
  }

  static KycStatus _status(Object? raw) {
    for (final KycStatus value in KycStatus.values) {
      if (value.name == raw) return value;
    }
    return KycStatus.unknown;
  }

  /// Decodes `allowed_documents`.
  ///
  /// The live API sends `[{"type": "...", "label": "..."}]`, which is what the
  /// first branch handles. The OpenAPI schema types the array as untyped, so
  /// the two simpler shapes it could equally have been — a bare list of slugs,
  /// or a slug-keyed map — are accepted too rather than silently decoding to
  /// an empty checklist.
  static List<KycDocumentType> _allowed(Object? raw) {
    if (raw is List) {
      return <KycDocumentType>[
        for (final Object? item in raw)
          if (item is Map<String, dynamic>)
            KycDocumentType.fromJson(item)
          else if (item is String)
            KycDocumentType(type: item, label: item),
      ];
    }
    if (raw is Map) {
      return <KycDocumentType>[
        for (final MapEntry<Object?, Object?> e in raw.entries)
          KycDocumentType(type: '${e.key}', label: '${e.value}'),
      ];
    }
    return const <KycDocumentType>[];
  }

  /// Decodes the plain slug arrays, tolerating the object form as well so the
  /// two endpoints cannot drift apart on shape without this noticing.
  static List<String> _types(Object? raw) {
    if (raw is List) {
      return <String>[
        for (final Object? item in raw)
          if (item is String)
            item
          else if (item is Map && item['type'] is String)
            item['type'] as String,
      ];
    }
    if (raw is Map) return raw.keys.map((Object? k) => '$k').toList();
    return const <String>[];
  }
}
