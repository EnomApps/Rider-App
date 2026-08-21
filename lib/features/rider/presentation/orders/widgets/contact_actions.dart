import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_theme.dart';

/// Dials a number.
///
/// Silent when there is no dialler — a tablet, or a locked-down device. The
/// alternative is an error about a missing app, which tells a rider standing
/// at a gate nothing they can act on.
Future<void> dial(String phone) async {
  final Uri uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Opens an address in whatever maps app the device has.
///
/// Coordinates when the API sent them, the written address otherwise. A
/// `geo:` URI with a `q` parameter is understood by Google Maps, and iOS
/// resolves the same intent through its own Maps — so one call covers both
/// without either platform needing a special case.
Future<void> openDirections({
  double? latitude,
  double? longitude,
  String? address,
}) async {
  final Uri uri;
  if (latitude != null && longitude != null) {
    uri = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude'
      '${address == null ? '' : '(${Uri.encodeComponent(address)})'}',
    );
  } else if (address != null && address.isNotEmpty) {
    uri = Uri.parse('geo:0,0?q=${Uri.encodeComponent(address)}');
  } else {
    return;
  }

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }

  // No handler for `geo:`. Every device with a browser can open a maps URL,
  // so that is the fallback rather than giving up.
  final String query = latitude != null && longitude != null
      ? '$latitude,$longitude'
      : Uri.encodeComponent(address ?? '');
  await launchUrl(
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
    mode: LaunchMode.externalApplication,
  );
}

/// The two things a rider does with an address: ring ahead, or get there.
///
/// Laid out as equal halves so both are hittable with a thumb, which is how
/// they are used — one-handed, often without taking the phone off the mount.
class ContactActions extends StatelessWidget {
  const ContactActions({
    super.key,
    required this.callLabel,
    required this.directionsLabel,
    this.phone,
    this.latitude,
    this.longitude,
    this.address,
  });

  final String callLabel;
  final String directionsLabel;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final String? address;

  @override
  Widget build(BuildContext context) {
    final bool canCall = phone != null && phone!.isNotEmpty;
    final bool canNavigate = (latitude != null && longitude != null) ||
        (address != null && address!.isNotEmpty);

    if (!canCall && !canNavigate) return const SizedBox.shrink();

    return Row(
      children: <Widget>[
        if (canCall)
          Expanded(
            child: _Action(
              icon: Icons.call_outlined,
              label: callLabel,
              onPressed: () => dial(phone!),
            ),
          ),
        if (canCall && canNavigate) const SizedBox(width: 12),
        if (canNavigate)
          Expanded(
            child: _Action(
              icon: Icons.directions_outlined,
              label: directionsLabel,
              onPressed: () => openDirections(
                latitude: latitude,
                longitude: longitude,
                address: address,
              ),
            ),
          ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
      ),
    );
  }
}
