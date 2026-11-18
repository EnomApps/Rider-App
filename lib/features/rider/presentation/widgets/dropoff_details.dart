import 'package:flutter/material.dart';

import '../../../../generated/l10n/app_localizations.dart';
import '../../data/order_models.dart';

/// What a rider needs at the customer's gate, under the drop address: the
/// flat and floor, the street, the landmark, and the door photo when the
/// customer added one.
///
/// Every part is optional and shown only when the order carries it. These
/// arrive only on an accepted order, never on an offer, because an offer
/// reaches riders who decline it.
class DropoffDetails extends StatelessWidget {
  const DropoffDetails({super.key, required this.dropoff});

  final OrderDropoff dropoff;

  /// True when there is nothing beyond the address line to show.
  static bool isEmpty(OrderDropoff dropoff) =>
      dropoff.line1 == null &&
      dropoff.line2 == null &&
      dropoff.landmark == null &&
      dropoff.photoUrl == null;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? photo = dropoff.photoUrl;

    final Widget lines = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (dropoff.line1 != null)
          _Line(
            icon: Icons.door_front_door_outlined,
            label: l10n.dropoffDoorLabel,
            text: dropoff.line1!,
            strong: true,
          ),
        if (dropoff.line2 != null)
          _Line(
            icon: Icons.signpost_outlined,
            label: l10n.dropoffStreetLabel,
            text: dropoff.line2!,
          ),
        if (dropoff.landmark != null)
          _Line(
            icon: Icons.place_outlined,
            label: l10n.dropoffLandmarkLabel,
            text: dropoff.landmark!,
          ),
      ],
    );
    if (photo == null) return lines;

    // A square beside the lines rather than a banner under them: it costs
    // no extra height, and a tap opens it full screen anyway.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: lines),
        const SizedBox(width: 12),
        _DoorPhoto(url: photo),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.label,
    required this.text,
    this.strong = false,
  });

  final IconData icon;
  final String label;
  final String text;

  /// The flat and floor, which is what the rider reads at the door.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      label: '$label: $text',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                icon,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style:
                    strong
                        ? theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        )
                        : theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The door photo as a wide thumbnail; a tap opens it full screen, where it
/// can be zoomed.
class _DoorPhoto extends StatelessWidget {
  const _DoorPhoto({required this.url});

  final String url;

  void _open(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder:
          (BuildContext context) => Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: InteractiveViewer(
                    maxScale: 5,
                    child: Center(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (BuildContext context, _, __) =>
                                const _Unavailable(dark: true),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconButton(
                        tooltip:
                            MaterialLocalizations.of(
                              context,
                            ).closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: '${l10n.doorPhotoLabel}. ${l10n.doorPhotoHint}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (BuildContext context, _, __) =>
                          const _Unavailable(compact: true),
                ),
                // A caption strip along the bottom of the square.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    color: Colors.black.withValues(alpha: 0.6),
                    child: Text(
                      l10n.doorPhotoLabel,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The link lasts three hours. Past that, or offline, say so plainly: the
/// next refresh of the order brings a working one.
class _Unavailable extends StatelessWidget {
  const _Unavailable({this.dark = false, this.compact = false});

  final bool dark;

  /// In the small thumbnail there is room for the icon only; the sentence is
  /// for the full-screen view.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fg = dark ? Colors.white70 : theme.colorScheme.onSurfaceVariant;
    return ColoredBox(
      color: dark ? Colors.black : theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child:
            compact
                ? Icon(Icons.image_not_supported_outlined, color: fg)
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.image_not_supported_outlined, color: fg),
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.of(context).doorPhotoUnavailable,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: fg),
                    ),
                  ],
                ),
      ),
    );
  }
}
