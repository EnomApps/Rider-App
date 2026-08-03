import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The orange dot that opens the splash and the glow it expands into.
///
/// [expansion] drives the radius: 0 is the centred dot, 1 is a circle that has
/// swallowed the whole screen. [intensity] drives opacity, and is faded down
/// once the circle has filled the display so the black backdrop returns and the
/// logo reads against it, leaving a soft residual glow behind the mark.
class GlowBurstPainter extends CustomPainter {
  const GlowBurstPainter({
    required this.expansion,
    required this.intensity,
  });

  final double expansion;
  final double intensity;

  /// Radius of the initial dot, in logical pixels.
  static const double _dotRadius = 5;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.001) return;

    final Offset centre = size.center(Offset.zero);
    final double maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final double radius =
        _dotRadius + (maxRadius * 1.08 - _dotRadius) * expansion;

    // Soft halo that reaches past the hard edge of the disc.
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color = AppColors.orangePulse.withValues(alpha: 0.45 * intensity)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          8 + 46 * expansion,
        ),
    );

    // The disc itself: hot in the middle, falling away at the rim.
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            AppColors.orangePulse.withValues(alpha: intensity),
            AppColors.orangeDeep.withValues(alpha: 0.72 * intensity),
            AppColors.orangeDeep.withValues(alpha: 0.0),
          ],
          stops: const <double>[0.0, 0.62, 1.0],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );

    // A brighter leading rim while the circle is still travelling — this is
    // what reads as speed rather than as a plain fade-in.
    final double rim = (1 - expansion).clamp(0.0, 1.0);
    if (rim > 0.02 && expansion > 0.02) {
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + 10 * rim
          ..color = AppColors.orangeLight
              .withValues(alpha: 0.55 * rim * intensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  @override
  bool shouldRepaint(GlowBurstPainter old) =>
      old.expansion != expansion || old.intensity != intensity;
}
