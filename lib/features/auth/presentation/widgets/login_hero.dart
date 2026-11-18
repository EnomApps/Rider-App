import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

/// One dish on the hero, placed by fractions of the hero's width and height
/// so the composition holds at any screen size.
@immutable
class HeroDish {
  const HeroDish(this.emoji, this.x, this.y, this.size, {this.turn = 0});

  final String emoji;

  /// Centre of the plate, as a fraction of the hero's width and height. Values
  /// near 0 or 1 let a plate run off the edge, which is what makes the
  /// picture feel bigger than the screen.
  final double x;
  final double y;

  /// Plate diameter in logical pixels before scaling to the screen.
  final double size;

  /// A slight tilt, in turns.
  final double turn;
}

/// The dishes around the customer login, biggest at the corners and the
/// centre left clear for the name.
const List<HeroDish> kCustomerHeroDishes = <HeroDish>[
  HeroDish('🍛', 0.13, 0.10, 128, turn: -0.03),
  HeroDish('🥗', 0.90, 0.11, 118, turn: 0.04),
  HeroDish('🍔', 0.12, 0.84, 132, turn: 0.02),
  HeroDish('🍕', 0.88, 0.85, 156, turn: -0.04),
  HeroDish('🥤', 0.05, 0.47, 56),
  HeroDish('🍜', 0.96, 0.49, 62),
  HeroDish('🍟', 0.58, 0.04, 54, turn: 0.05),
];

/// The rider login: the ride, the parcel, the pin, the pay.
const List<HeroDish> kRiderHeroDishes = <HeroDish>[
  HeroDish('📦', 0.13, 0.10, 124, turn: -0.03),
  HeroDish('📍', 0.90, 0.11, 112, turn: 0.04),
  HeroDish('🛵', 0.12, 0.85, 140, turn: 0.02),
  HeroDish('🍔', 0.88, 0.85, 150, turn: -0.04),
  HeroDish('💰', 0.05, 0.47, 58),
  HeroDish('⏱️', 0.96, 0.49, 60),
  HeroDish('🍕', 0.58, 0.04, 54, turn: 0.05),
];

/// The illustrated top of the login screen: the brand's dark ground with a
/// green and an orange glow, plates of food round the edges, and the wordmark
/// in the middle.
///
/// Drawn from widgets rather than shipped as a picture, so it is sharp at any
/// density, fits any screen shape, and costs nothing in the download.
class LoginHero extends StatelessWidget {
  const LoginHero({
    super.key,
    required this.height,
    required this.tagline,
    this.dishes = kCustomerHeroDishes,
    this.badge,
    this.topInset = 0,
  });

  final double height;

  /// The status bar's height. The picture runs up behind it, but the name is
  /// centred in the part below it, where it can be seen.
  final double topInset;
  final String tagline;
  final List<HeroDish> dishes;

  /// A pill under the tagline, for the rider app's "delivery partner".
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final double w = box.maxWidth;
          final double h = box.maxHeight;
          // Plates are sized for a 390-wide phone and scale with the screen,
          // within limits, so a tablet does not get dinner plates.
          final double scale = (w / 390).clamp(0.8, 1.25);

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.linear,
            builder: (BuildContext context, double t, _) {
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: <Widget>[
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            AppColors.slate,
                            AppColors.charcoal,
                            AppColors.nearBlack,
                          ],
                        ),
                      ),
                    ),
                  ),
                  _glow(left: -w * 0.25, top: -h * 0.2, size: w * 0.95,
                      colour: AppColors.green, alpha: 0.30),
                  _glow(right: -w * 0.3, bottom: -h * 0.25, size: w * 1.05,
                      colour: AppColors.orange, alpha: 0.26),
                  ..._confetti(w, h),
                  for (int i = 0; i < dishes.length; i++)
                    _placed(dishes[i], w, h, scale, _stagger(t, i)),
                  Positioned.fill(
                    top: topInset,
                    child: Center(
                      child: _Centre(
                        progress: _stagger(t, 2),
                        width: math.min(w * 0.56, 260),
                        tagline: tagline,
                        badge: badge,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Each plate arrives a little after the one before.
  static double _stagger(double t, int index) {
    final double start = (index * 0.07).clamp(0.0, 0.5);
    return Curves.easeOutBack
        .transform(((t - start) / 0.5).clamp(0.0, 1.0));
  }

  Widget _placed(HeroDish dish, double w, double h, double scale, double p) {
    final double size = dish.size * scale;
    return Positioned(
      left: dish.x * w - size / 2,
      top: dish.y * h - size / 2,
      child: Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: (dish.turn + (1 - p) * 0.08) * 2 * math.pi,
          child: Transform.scale(
            scale: 0.7 + 0.3 * p,
            child: _Plate(emoji: dish.emoji, size: size),
          ),
        ),
      ),
    );
  }

  static Widget _glow({
    double? left,
    double? top,
    double? right,
    double? bottom,
    required double size,
    required Color colour,
    required double alpha,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                colour.withValues(alpha: alpha),
                colour.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Specks of green, orange and white: a fixed pattern, so the screen looks
  /// the same on every visit.
  static List<Widget> _confetti(double w, double h) {
    const List<(double, double, int, double)> specks =
        <(double, double, int, double)>[
      (0.30, 0.20, 0, 0.2),
      (0.70, 0.24, 1, -0.3),
      (0.24, 0.40, 2, 0.5),
      (0.78, 0.36, 0, 0.1),
      (0.33, 0.66, 1, 0.7),
      (0.69, 0.70, 2, -0.2),
      (0.42, 0.12, 2, 0.9),
      (0.62, 0.86, 0, 0.4),
      (0.20, 0.58, 1, -0.6),
      (0.84, 0.60, 2, 0.3),
      (0.45, 0.80, 1, 0.0),
      (0.55, 0.22, 0, -0.5),
    ];
    const List<Color> colours = <Color>[
      AppColors.green,
      AppColors.orange,
      Colors.white,
    ];
    return <Widget>[
      for (int i = 0; i < specks.length; i++)
        Positioned(
          left: specks[i].$1 * w,
          top: specks[i].$2 * h,
          child: Transform.rotate(
            angle: specks[i].$4 * math.pi,
            child: Container(
              // Alternate dots and dashes.
              width: i.isEven ? 5 : 11,
              height: 5,
              decoration: BoxDecoration(
                color: colours[specks[i].$3].withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
    ];
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.07),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFFF6EA),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: size * 0.16,
              offset: Offset(0, size * 0.06),
            ),
          ],
        ),
        // The rim: a second, slightly darker ring inside the plate.
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFBEBD5),
            border: Border.all(
              color: const Color(0xFFF1DABA),
              width: math.max(1, size * 0.012),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            emoji,
            textScaler: TextScaler.noScaling,
            style: TextStyle(fontSize: size * 0.46, height: 1),
          ),
        ),
      ),
    );
  }
}

class _Centre extends StatelessWidget {
  const _Centre({
    required this.progress,
    required this.width,
    required this.tagline,
    this.badge,
  });

  final double progress;
  final double width;
  final String tagline;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - progress) * 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              label: 'Nexmile',
              image: true,
              child: Image.asset(
                AppAssets.wordmark,
                width: width,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tagline,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
            if (badge != null) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  badge!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
