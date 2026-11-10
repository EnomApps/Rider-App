import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../../core/theme/app_colors.dart';
import '../../data/navigation_models.dart';
import 'map_styles.dart';
import 'route_geometry.dart';

gm.LatLng _g(LatLng p) => gm.LatLng(p.latitude, p.longitude);

const Color _routeCasing = Color(0xFF1F6A08);
const Color _routeCore = Color(0xFF3FA514);

/// The map half of navigation.
///
/// In follow mode the camera sits behind and above the rider, turned to their
/// direction of travel, so "up" on the screen is always "ahead" on the road —
/// the way every sat-nav works and the only way a glance at a mounted phone
/// can be read at speed. Each new fix is glided to over most of the gap
/// before the next one, so the chevron moves continuously instead of jumping.
class NavMap extends StatefulWidget {
  const NavMap({
    super.key,
    required this.here,
    required this.destination,
    required this.target,
    this.heading,
    this.path,
    this.along = 0,
    this.follow = true,
    this.padding = EdgeInsets.zero,
    this.glide = const Duration(milliseconds: 1800),
  });

  final LatLng? here;
  final LatLng destination;
  final NavTarget target;
  final double? heading;
  final RoutePath? path;

  /// Metres along [path] the rider has reached. The line behind is dropped.
  final double along;

  final bool follow;
  final EdgeInsets padding;

  /// Just under the position poll, so the chevron arrives as the next fix
  /// lands.
  final Duration glide;

  @override
  State<NavMap> createState() => _NavMapState();
}

class _NavMapState extends State<NavMap> with SingleTickerProviderStateMixin {
  final Completer<gm.GoogleMapController> _controller =
      Completer<gm.GoogleMapController>();

  late final AnimationController _motion =
      AnimationController(vsync: this, duration: widget.glide)
        ..addListener(_onFrame);

  LatLng? _from;
  LatLng? _to;
  LatLng? _shown;
  double _bearing = 0;
  bool _hasBearing = false;

  gm.BitmapDescriptor? _chevron;
  gm.BitmapDescriptor? _pin;
  bool _iconsRequested = false;

  /// Caps rebuilds and camera moves near 30 a second. Each one crosses the
  /// platform channel, and 60 would double the traffic for no visible gain.
  final Stopwatch _sinceFrame = Stopwatch()..start();

  static const double _followZoom = 17.6;
  static const double _followTilt = 55;

  @override
  void initState() {
    super.initState();
    _shown = widget.here;
    if (widget.heading != null) {
      _bearing = widget.heading!;
      _hasBearing = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iconsRequested) return;
    _iconsRequested = true;
    final double ratio = MediaQuery.devicePixelRatioOf(context);
    Future.wait(<Future<gm.BitmapDescriptor>>[
      _paintChevron(ratio),
      _paintPin(
        widget.target == NavTarget.pickup
            ? Icons.storefront_rounded
            : Icons.home_rounded,
        widget.target == NavTarget.pickup
            ? AppColors.orangeDeep
            : AppColors.greenDeep,
        ratio,
      ),
    ]).then((List<gm.BitmapDescriptor> icons) {
      if (!mounted) return;
      setState(() {
        _chevron = icons[0];
        _pin = icons[1];
      });
    });
  }

  @override
  void didUpdateWidget(NavMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final LatLng? next = widget.here;
    if (next != null && next != oldWidget.here) _driveTo(next);
    if (widget.follow && !oldWidget.follow) unawaited(_moveCamera(animate: true));
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _driveTo(LatLng target) {
    final LatLng? start = _shown;
    if (start == null || distanceMetres(start, target) > 300) {
      // First fix, or a jump no rider makes in two seconds: place it.
      _motion.stop();
      _shown = target;
      _from = _to = null;
      unawaited(_moveCamera(animate: start != null));
      setState(() {});
      return;
    }
    _from = start;
    _to = target;
    _motion.forward(from: 0);
  }

  void _onFrame() {
    final LatLng? from = _from;
    final LatLng? to = _to;
    if (from == null || to == null) return;

    _shown = lerpLatLng(from, to, _motion.value);

    // The phone's compass heading when it has one; otherwise the road's
    // direction at this point; otherwise the direction of movement.
    double? target = widget.heading;
    final RoutePath? path = widget.path;
    if (target == null && path != null) {
      target = path.bearingAt(path.project(_shown!).along);
    }
    if (target == null && distanceMetres(from, to) > 2) {
      target = bearingDegrees(from, to);
    }
    if (target != null) {
      _bearing = _hasBearing ? lerpBearing(_bearing, target, 0.15) : target;
      _hasBearing = true;
    }

    if (_sinceFrame.elapsedMilliseconds < 33 && _motion.value < 1) return;
    _sinceFrame.reset();
    unawaited(_moveCamera());
    if (mounted) setState(() {});
  }

  Future<void> _moveCamera({bool animate = false}) async {
    final LatLng? at = _shown;
    if (!widget.follow || at == null || !_controller.isCompleted) return;
    final gm.GoogleMapController map = await _controller.future;
    final gm.CameraUpdate update = gm.CameraUpdate.newCameraPosition(
      gm.CameraPosition(
        target: _g(at),
        zoom: _followZoom,
        tilt: _followTilt,
        bearing: _hasBearing ? _bearing : 0,
      ),
    );
    try {
      animate ? await map.animateCamera(update) : await map.moveCamera(update);
    } catch (_) {
      // Disposed mid-move.
    }
  }

  List<LatLng> _line(LatLng at) {
    final RoutePath? path = widget.path;
    if (path == null) return <LatLng>[at, widget.destination];
    // From the chevron, along whatever of the road is still ahead of it.
    final double from = widget.along.clamp(0, path.length);
    return <LatLng>[at, ...path.slice(from, path.length).skip(1)];
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final LatLng? at = _shown;
    final List<gm.LatLng> line =
        at == null ? const <gm.LatLng>[] : _line(at).map(_g).toList();
    final bool hasRoad = widget.path != null;

    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: _g(at ?? widget.destination),
        zoom: at == null ? 15 : _followZoom,
        tilt: at == null ? 0 : _followTilt,
        bearing: _bearing,
      ),
      style: dark ? kNavMapStyleDark : kNavMapStyleLight,
      padding: widget.padding,
      onMapCreated: (gm.GoogleMapController controller) {
        _controller.complete(controller);
        unawaited(_moveCamera());
      },
      compassEnabled: false,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      buildingsEnabled: true,
      polylines: <gm.Polyline>{
        if (line.length >= 2 && hasRoad) ...<gm.Polyline>{
          gm.Polyline(
            polylineId: const gm.PolylineId('casing'),
            points: line,
            width: 12,
            color: _routeCasing,
            jointType: gm.JointType.round,
            startCap: gm.Cap.roundCap,
            endCap: gm.Cap.roundCap,
            zIndex: 1,
          ),
          gm.Polyline(
            polylineId: const gm.PolylineId('core'),
            points: line,
            width: 7,
            color: _routeCore,
            jointType: gm.JointType.round,
            startCap: gm.Cap.roundCap,
            endCap: gm.Cap.roundCap,
            zIndex: 2,
          ),
        },
        if (line.length >= 2 && !hasRoad)
          gm.Polyline(
            polylineId: const gm.PolylineId('direct'),
            points: line,
            width: 4,
            color: _routeCasing.withValues(alpha: 0.7),
            // Dotted: a straight line is a direction, not a road to follow.
            patterns: <gm.PatternItem>[
              gm.PatternItem.dot,
              gm.PatternItem.gap(10),
            ],
            zIndex: 1,
          ),
      },
      markers: <gm.Marker>{
        if (_pin != null)
          gm.Marker(
            markerId: const gm.MarkerId('destination'),
            position: _g(widget.destination),
            icon: _pin!,
            anchor: const Offset(0.5, 1),
            zIndexInt: 2,
          ),
        if (_chevron != null && at != null)
          gm.Marker(
            markerId: const gm.MarkerId('rider'),
            position: _g(at),
            icon: _chevron!,
            anchor: const Offset(0.5, 0.5),
            // Flat and rotated with the road, so in follow mode — where the
            // camera turns too — it always points up the screen.
            flat: true,
            rotation: _hasBearing ? _bearing : 0,
            zIndexInt: 3,
          ),
      },
    );
  }
}

/// A navigation chevron: an orange arrowhead on a white disc, pointing north
/// before rotation.
Future<gm.BitmapDescriptor> _paintChevron(double ratio) {
  const double logical = 54;
  return _draw(logical, logical, ratio, (Canvas canvas, double s) {
    final Offset c = Offset(logical * s / 2, logical * s / 2);

    canvas.drawCircle(
      c.translate(0, 2 * s),
      20 * s,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 4 * s),
    );
    canvas.drawCircle(c, 20 * s, Paint()..color = Colors.white);

    final Path arrow = Path()
      ..moveTo(c.dx, c.dy - 14 * s)
      ..lineTo(c.dx + 11 * s, c.dy + 12 * s)
      ..lineTo(c.dx, c.dy + 6 * s)
      ..lineTo(c.dx - 11 * s, c.dy + 12 * s)
      ..close();
    canvas.drawPath(
      arrow,
      Paint()
        ..shader = ui.Gradient.linear(
          c.translate(0, -14 * s),
          c.translate(0, 12 * s),
          const <Color>[AppColors.orangeLight, AppColors.orangeDeep],
        ),
    );
  });
}

/// A teardrop pin, tip on the stop.
Future<gm.BitmapDescriptor> _paintPin(
  IconData icon,
  Color colour,
  double ratio,
) {
  const double width = 46;
  const double height = width * 1.25;
  return _draw(width, height, ratio, (Canvas canvas, double s) {
    const double w = width;
    final double r = (w / 2 - 3) * s;
    final Offset head = Offset(w * s / 2, r + 3 * s);
    final double tip = (height - 1) * s;

    final Path drop = Path()
      ..addOval(Rect.fromCircle(center: head, radius: r))
      ..moveTo(head.dx - r * 0.62, head.dy + r * 0.78)
      ..lineTo(head.dx, tip)
      ..lineTo(head.dx + r * 0.62, head.dy + r * 0.78)
      ..close();

    canvas.drawPath(
      drop.shift(Offset(0, 1.5 * s)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5 * s),
    );
    canvas.drawPath(drop, Paint()..color = colour);
    canvas.drawCircle(head, r * 0.68, Paint()..color = Colors.white);

    final TextPainter glyph = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: r * 0.95,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: colour,
        ),
      ),
    )..layout();
    glyph.paint(canvas, head - Offset(glyph.width / 2, glyph.height / 2));
  });
}

Future<gm.BitmapDescriptor> _draw(
  double width,
  double height,
  double ratio,
  void Function(Canvas canvas, double scale) paint,
) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  paint(Canvas(recorder), ratio);
  final ui.Image image = await recorder
      .endRecording()
      .toImage((width * ratio).round(), (height * ratio).round());
  final ByteData? bytes =
      await image.toByteData(format: ui.ImageByteFormat.png);
  return gm.BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    imagePixelRatio: ratio,
  );
}
