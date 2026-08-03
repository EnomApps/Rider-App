import 'package:flutter/material.dart';

import '../../../../../generated/l10n/app_localizations.dart';
import '../../../data/kyc_models.dart';
import '../../../data/picked_document.dart';
import '../../../data/rider_failure.dart';
import '../../../state/rider_controller.dart';
import '../../widgets/document_row.dart';
import '../onboarding_scaffold.dart';
import '../onboarding_screen.dart';

/// Step 6 — the document checklist.
///
/// The list is entirely the server's: `allowed_documents` decides what is
/// asked for, in what order, and `missing_documents` decides what is still
/// outstanding. Nothing here hard-codes "six documents" — retiring the PAN
/// card or adding a police verification is a backend change, and this screen
/// picks it up on the next fetch.
class DocumentsStep extends StatelessWidget {
  const DocumentsStep({super.key, required this.context});

  final OnboardingStepContext context;

  @override
  Widget build(BuildContext buildContext) {
    final ThemeData theme = Theme.of(buildContext);
    final AppLocalizations l10n = AppLocalizations.of(buildContext);
    final OnboardingStepContext step = context;
    final RiderController rider = step.rider;
    final KycOverview kyc = rider.kyc;

    final List<String> types = kyc.allowedDocuments;
    final bool everythingUploaded =
        types.isNotEmpty && kyc.missingDocuments.isEmpty;

    return OnboardingScaffold(
      stepIndex: step.index,
      stepCount: step.total,
      title: l10n.stepDocumentsTitle,
      subtitle: l10n.stepDocumentsSubtitle,
      onBack: step.onBack,
      // Never busy: an upload spins on its own row, so the rest of the
      // checklist stays usable while one file is in flight.
      isBusy: false,
      banner: step.banner,
      primaryLabel: l10n.saveAndContinue,
      // Refuses to advance until every requested document is on file. The API
      // would refuse the submit anyway; blocking here means the rider finds out
      // on the screen that can fix it.
      onPrimary: everythingUploaded ? () => step.onResult(null) : null,
      children: <Widget>[
        _ProgressLine(
          done: kyc.uploadedCount,
          total: types.length,
        ),
        const SizedBox(height: 16),
        for (final String type in types)
          DocumentRow(
            type: type,
            document: kyc.documentOf(type),
            isUploading: rider.isUploading(type),
            enabled: rider.canEditDocuments,
            onPick: (PickedDocument file) =>
                _upload(buildContext, rider, type, file),
            onRemove: () => _remove(buildContext, rider, type),
          ),
        if (types.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                l10n.couldNotLoadAccount,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _upload(
    BuildContext buildContext,
    RiderController rider,
    String type,
    PickedDocument file,
  ) async {
    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(buildContext);
    final AppLocalizations l10n = AppLocalizations.of(buildContext);

    final RiderFailure? failure =
        await rider.uploadDocument(type: type, file: file);
    if (failure == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure.message(l10n))));
  }

  Future<void> _remove(
    BuildContext buildContext,
    RiderController rider,
    String type,
  ) async {
    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(buildContext);
    final AppLocalizations l10n = AppLocalizations.of(buildContext);

    final RiderFailure? failure = await rider.deleteDocument(type);
    if (failure == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure.message(l10n))));
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Row(
      children: <Widget>[
        Icon(
          done == total && total > 0
              ? Icons.check_circle_rounded
              : Icons.pending_outlined,
          size: 20,
          color: done == total && total > 0
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Text(
          l10n.documentsProgress(done, total),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
