import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';

/// Presentation metadata for a KYC document type.
///
/// The *list* of documents is always the server's — [KycOverview.allowedDocuments]
/// decides what the rider is asked for. This catalogue only decides how a known
/// type is dressed: which icon it gets, whether the camera or a file browser
/// opens first, and a translated label.
///
/// A type the catalogue has never heard of still renders correctly: it falls
/// back to a generic icon and to the label the API supplied, so a document
/// added on the backend needs no app release.
@immutable
class DocumentPresentation {
  const DocumentPresentation({
    required this.icon,
    required this.prefersCamera,
    this.hint,
  });

  final IconData icon;

  /// True for anything the rider is holding in their hand. Photographing a
  /// licence is one tap; digging a PDF out of the file manager is five.
  final bool prefersCamera;

  final String? hint;
}

class DocumentCatalogue {
  const DocumentCatalogue._();

  /// The six a rider is normally asked for, plus the two the API lists as
  /// allowed. Keys are the API's own type slugs.
  ///
  /// Slugs are matched loosely by [_normalise] so `aadhaar_front`,
  /// `aadhaarFront` and `aadhaar-front` all land on the same entry.
  static const Map<String, DocumentPresentation> _known =
      <String, DocumentPresentation>{
    'aadhaar_front': DocumentPresentation(
      icon: Icons.badge_outlined,
      prefersCamera: true,
    ),
    'aadhaar_back': DocumentPresentation(
      icon: Icons.badge_outlined,
      prefersCamera: true,
    ),
    'driving_licence': DocumentPresentation(
      icon: Icons.credit_card_outlined,
      prefersCamera: true,
    ),
    'driving_license': DocumentPresentation(
      icon: Icons.credit_card_outlined,
      prefersCamera: true,
    ),
    'rc': DocumentPresentation(
      icon: Icons.two_wheeler_outlined,
      prefersCamera: true,
    ),
    'rc_book': DocumentPresentation(
      icon: Icons.two_wheeler_outlined,
      prefersCamera: true,
    ),
    'vehicle_rc': DocumentPresentation(
      icon: Icons.two_wheeler_outlined,
      prefersCamera: true,
    ),
    'insurance': DocumentPresentation(
      icon: Icons.shield_outlined,
      prefersCamera: false,
    ),
    'vehicle_insurance': DocumentPresentation(
      icon: Icons.shield_outlined,
      prefersCamera: false,
    ),
    'profile_photo': DocumentPresentation(
      icon: Icons.account_circle_outlined,
      prefersCamera: true,
    ),
    'pan': DocumentPresentation(
      icon: Icons.article_outlined,
      prefersCamera: true,
    ),
    'pan_card': DocumentPresentation(
      icon: Icons.article_outlined,
      prefersCamera: true,
    ),
    'bank_proof': DocumentPresentation(
      icon: Icons.account_balance_outlined,
      prefersCamera: false,
    ),
    'cancelled_cheque': DocumentPresentation(
      icon: Icons.account_balance_outlined,
      prefersCamera: false,
    ),
  };

  static const DocumentPresentation _fallback = DocumentPresentation(
    icon: Icons.upload_file_outlined,
    prefersCamera: false,
  );

  static DocumentPresentation presentationOf(String type) =>
      _known[_normalise(type)] ?? _fallback;

  /// Translated label for a known type.
  ///
  /// Returns null for anything unrecognised, and the caller then shows the
  /// server's own `label`. Better an English label from the API than a slug.
  static String? labelOf(String type, AppLocalizations l10n) {
    switch (_normalise(type)) {
      case 'aadhaar_front':
        return l10n.docAadhaarFront;
      case 'aadhaar_back':
        return l10n.docAadhaarBack;
      case 'driving_licence':
      case 'driving_license':
        return l10n.docDrivingLicence;
      case 'rc':
      case 'rc_book':
      case 'vehicle_rc':
        return l10n.docVehicleRc;
      case 'insurance':
      case 'vehicle_insurance':
        return l10n.docInsurance;
      case 'profile_photo':
        return l10n.docProfilePhoto;
      case 'pan':
      case 'pan_card':
        return l10n.docPan;
      case 'bank_proof':
      case 'cancelled_cheque':
        return l10n.docBankProof;
      default:
        return null;
    }
  }

  /// Lowercases and folds `-` and camelCase humps to `_`, so a slug the backend
  /// spells slightly differently still matches.
  static String _normalise(String type) {
    final String spaced = type.replaceAllMapped(
      RegExp('([a-z0-9])([A-Z])'),
      (Match m) => '${m[1]}_${m[2]}',
    );
    return spaced.toLowerCase().replaceAll('-', '_').trim();
  }
}
