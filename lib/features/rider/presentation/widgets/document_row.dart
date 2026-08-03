import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/info_tile.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../data/document_catalogue.dart';
import '../../data/kyc_models.dart';
import '../../data/picked_document.dart';

/// One line of the KYC checklist: what is wanted, what is on file, and the
/// action that changes it.
class DocumentRow extends StatelessWidget {
  const DocumentRow({
    super.key,
    required this.type,
    required this.document,
    required this.isUploading,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  /// The API's type slug — what the checklist is keyed on.
  final String type;

  /// The file on record, or null when this slot is still empty.
  final KycDocument? document;

  final bool isUploading;

  /// False once KYC is submitted or verified: the file is locked and the row
  /// becomes a read-only receipt.
  final bool enabled;

  final ValueChanged<PickedDocument> onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    final DocumentPresentation presentation =
        DocumentCatalogue.presentationOf(type);

    // The catalogue's translated name where the type is known; otherwise the
    // server's own label, which is at least readable English, and only then
    // the raw slug.
    final String label = DocumentCatalogue.labelOf(type, l10n) ??
        (document?.label.isNotEmpty ?? false ? document!.label : type);

    final BorderRadius radius = BorderRadius.circular(AppTheme.radiusLarge);
    final bool hasFile = document != null;
    final bool rejected = document?.isRejected ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: rejected
                  ? theme.colorScheme.error.withValues(alpha: 0.5)
                  : theme.colorScheme.outline,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      presentation.icon,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _StatusLine(document: document),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Trailing(
                      isUploading: isUploading,
                      hasFile: hasFile,
                      document: document,
                    ),
                  ],
                ),
                if (rejected && document!.rejectionReason != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    document!.rejectionReason!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                if (enabled && !isUploading) ...<Widget>[
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      TextButton.icon(
                        onPressed: () => _openSheet(context, presentation),
                        icon: Icon(
                          hasFile
                              ? Icons.refresh_rounded
                              : Icons.add_rounded,
                          size: 19,
                        ),
                        label: Text(
                          hasFile
                              ? l10n.replaceDocument
                              : l10n.uploadDocument,
                        ),
                      ),
                      if (hasFile)
                        TextButton(
                          onPressed: onRemove,
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                          child: Text(l10n.removeDocument),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom sheet with the three ways in.
  ///
  /// The camera is listed first for anything the rider is physically holding,
  /// and the file browser first for the papers that usually arrive as an
  /// emailed PDF — insurance, most often.
  Future<void> _openSheet(
    BuildContext context,
    DocumentPresentation presentation,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final DocumentPicker picker = PlatformDocumentPicker();

    final _PickSource? source = await showModalBottomSheet<_PickSource>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        final List<Widget> options = <Widget>[
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.takePhoto),
            onTap: () => Navigator.of(sheetContext).pop(_PickSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.chooseFromGallery),
            onTap: () => Navigator.of(sheetContext).pop(_PickSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(l10n.chooseFile),
            onTap: () => Navigator.of(sheetContext).pop(_PickSource.file),
          ),
        ];

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: presentation.prefersCamera
                ? options
                : options.reversed.toList(),
          ),
        );
      },
    );

    if (source == null) return;

    final PickResult result = switch (source) {
      _PickSource.camera => await picker.pickImage(ImageSource.camera),
      _PickSource.gallery => await picker.pickImage(ImageSource.gallery),
      _PickSource.file => await picker.pickFile(),
    };

    final PickedDocument? document = result.document;
    if (document != null) {
      onPick(document);
      return;
    }

    // Backing out of the camera is not an error and gets no message.
    final String? message = switch (result.failure) {
      PickFailure.tooLarge => l10n.fileTooLarge,
      PickFailure.unsupportedType => l10n.unsupportedFileType,
      PickFailure.denied => l10n.pickerUnavailable,
      PickFailure.cancelled || null => null,
    };
    if (message == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _PickSource { camera, gallery, file }

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.document});

  final KycDocument? document;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final KycDocument? file = document;

    if (file == null) {
      return Text(
        l10n.documentRequired,
        style: theme.textTheme.bodySmall,
      );
    }

    return Text(
      file.originalName.isEmpty ? l10n.documentUploaded : file.originalName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: TextDirection.ltr,
      style: theme.textTheme.bodySmall,
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({
    required this.isUploading,
    required this.hasFile,
    required this.document,
  });

  final bool isUploading;
  final bool hasFile;
  final KycDocument? document;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    if (isUploading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      );
    }

    final KycDocument? file = document;
    if (file == null) {
      return StatusChip(
        label: l10n.documentRequired,
        tone: StatusTone.warning,
      );
    }
    if (file.isRejected) {
      return StatusChip(
        label: l10n.documentRejected,
        tone: StatusTone.negative,
      );
    }
    if (file.isApproved) {
      return StatusChip(
        label: l10n.documentApproved,
        tone: StatusTone.positive,
      );
    }
    return StatusChip(
      label: l10n.documentUploaded,
      tone: StatusTone.positive,
    );
  }
}
