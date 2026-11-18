import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/motion/app_motion.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../generated/l10n/app_localizations.dart';
import '../../../data/document_catalogue.dart';
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

    final List<KycDocumentType> types = kyc.allowedDocuments;
    final bool everythingUploaded =
        types.isNotEmpty && kyc.missingDocuments.isEmpty;

    return OnboardingScaffold(
      stepIndex: step.index,
      stepCount: step.total,
      icon: Icons.folder_copy_rounded,
      bodyInCard: false,
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
        _Summary(
          done: kyc.uploadedCount,
          total: kyc.requiredCount,
          allDone: everythingUploaded,
        ),
        for (final DocumentGroup group in DocumentGroup.values)
          if (types.any(
            (KycDocumentType t) => DocumentCatalogue.groupOf(t.type) == group,
          )) ...<Widget>[
            _GroupHeading(group: group),
            for (final KycDocumentType type in types)
              if (DocumentCatalogue.groupOf(type.type) == group)
                DocumentRow(
                  type: type.type,
                  serverLabel: type.label,
                  // The API allows more types than it requires — a bank proof
                  // and a profile photo are optional extras. Both are offered,
                  // but only the required ones are allowed to block the step.
                  isRequired: kyc.isRequired(type.type),
                  document: kyc.documentOf(type.type),
                  preview: rider.previewOf(type.type),
                  isUploading: rider.isUploading(type.type),
                  enabled: rider.canEditDocuments,
                  onPick: (PickedDocument file) =>
                      _upload(buildContext, rider, type.type, file),
                  onRemove: () => _remove(buildContext, rider, type.type),
                ),
          ],
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

/// The top of the checklist: a ring that fills as documents go up, the
/// count, and a tip — or, once nothing required is missing, the way on.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.done,
    required this.total,
    required this.allDone,
  });

  final int done;
  final int total;
  final bool allDone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double fraction = total == 0 ? 0 : (done / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allDone
            ? AppColors.greenDeep.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: allDone
              ? AppColors.greenDeep.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox.square(
            dimension: 62,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: fraction),
              duration: AppMotion.medium,
              curve: AppMotion.change,
              builder: (BuildContext context, double value, _) => CustomPaint(
                painter: _RingPainter(
                  fraction: value,
                  track: theme.colorScheme.outlineVariant,
                ),
                child: Center(
                  child: allDone
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.greenDeep,
                          size: 28,
                        )
                      : Text(
                          '$done/$total',
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.documentsProgress(done, total),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  allDone ? l10n.docsAllDone : l10n.docsTip,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.fraction, required this.track});

  final double fraction;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 6;
    final Rect rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (fraction <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      Paint()
        ..color = AppColors.greenDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.track != track;
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading({required this.group});

  final DocumentGroup group;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String title = switch (group) {
      DocumentGroup.identity => l10n.docGroupIdentity,
      DocumentGroup.vehicle => l10n.docGroupVehicle,
      DocumentGroup.more => l10n.docGroupMore,
    };
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, top: 22, bottom: 10),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
