import 'package:flutter/material.dart';

/// Runs a diagonal band of light across [child].
///
/// Uses [BlendMode.srcATop] so the highlight is clipped to the child's own
/// alpha — the sweep lights up the "N" and the pin without painting a grey
/// rectangle across the black backdrop around them. This is why the splash
/// uses the transparent-background `nexmile_symbol.png` rather than the flat
/// lockup, which carries its own opaque black.
class ShineSweep extends StatelessWidget {
  const ShineSweep({
    super.key,
    required this.progress,
    required this.child,
    this.bandWidth = 0.30,
    this.strength = 0.62,
  });

  /// 0 -> band off the leading edge, 1 -> band off the trailing edge.
  final Animation<double> progress;
  final Widget child;

  /// Half-width of the highlight as a fraction of the sweep axis.
  final double bandWidth;

  /// Peak opacity of the highlight.
  final double strength;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (BuildContext context, Widget? built) {
        final double t = progress.value;
        if (t <= 0 || t >= 1) return built!;

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            // Travel from just off one edge to just off the other.
            final double pos = -bandWidth + t * (1 + 2 * bandWidth);

            // Gradient stops must strictly ascend, so each one is clamped
            // above its predecessor.
            const double e = 1e-4;
            final double s1 = (pos - bandWidth).clamp(e, 1 - 4 * e);
            final double s2 = pos.clamp(s1 + e, 1 - 3 * e);
            final double s3 = (pos + bandWidth).clamp(s2 + e, 1 - 2 * e);

            return LinearGradient(
              begin: const Alignment(-1.0, -0.7),
              end: const Alignment(1.0, 0.7),
              colors: <Color>[
                const Color(0x00FFFFFF),
                const Color(0x00FFFFFF),
                Colors.white.withValues(alpha: strength),
                const Color(0x00FFFFFF),
                const Color(0x00FFFFFF),
              ],
              stops: <double>[0.0, s1, s2, s3, 1.0],
            ).createShader(bounds);
          },
          child: built,
        );
      },
    );
  }
}
