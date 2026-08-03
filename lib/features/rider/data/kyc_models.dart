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
    required this.missingDocuments,
    required this.canSubmit,
    this.rejectionReason,
    this.requiredDocuments = '',
    this.verifiedAt,
  });

  final KycStatus status;
  final List<KycDocument> documents;

  /// Every document type the rider may upload, in the order the API lists it.
  final List<String> allowedDocuments;

  /// The subset still outstanding. Empty does not by itself mean ready —
  /// [canSubmit] is the API's own verdict and is what the button follows.
  final List<String> missingDocuments;

  final bool canSubmit;
  final String? rejectionReason;

  /// Free-text summary of the requirement, e.g. "6 documents".
  final String requiredDocuments;

  final DateTime? verifiedAt;

  /// An empty shell, used before the first fetch lands.
  static const KycOverview empty = KycOverview(
    status: KycStatus.pending,
    documents: <KycDocument>[],
    allowedDocuments: <String>[],
    missingDocuments: <String>[],
    canSubmit: false,
  );

  /// The uploaded file for [type], or null when nothing is on file yet.
  KycDocument? documentOf(String type) {
    for (final KycDocument document in documents) {
      if (document.type == type) return document;
    }
    return null;
  }

  /// How many of the allowed types have a file against them. Drives the
  /// "3 of 6 uploaded" progress line.
  int get uploadedCount =>
      allowedDocuments.where((String type) => documentOf(type) != null).length;

  bool get hasRejectedDocuments =>
      documents.any((KycDocument document) => document.isRejected);

  static KycOverview fromJson(Map<String, dynamic> data) {
    return KycOverview(
      status: _status(data['status']),
      rejectionReason: data['rejection_reason'] as String?,
      verifiedAt: DateTime.tryParse('${data['verified_at']}'),
      requiredDocuments: data['required_documents'] as String? ?? '',
      allowedDocuments: _strings(data['allowed_documents']),
      missingDocuments: _strings(data['missing_documents']),
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

  /// The schema types these arrays as untyped, and a Laravel resource that
  /// keys them by slug would arrive as a map. Both shapes are accepted.
  static List<String> _strings(Object? raw) {
    if (raw is List) return raw.whereType<String>().toList(growable: false);
    if (raw is Map) return raw.keys.whereType<String>().toList(growable: false);
    return const <String>[];
  }
}
