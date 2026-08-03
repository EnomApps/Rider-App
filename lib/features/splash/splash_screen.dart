import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../auth/state/auth_controller.dart';
import 'widgets/glow_burst.dart';
import 'widgets/shine_sweep.dart';

/// Brand splash.
///
/// Choreography, driven by a single 3.0s controller so every layer shares one
/// clock and the whole sequence stays on one vsync:
///
/// | time        | beat                                                    |
/// |-------------|---------------------------------------------------------|
/// | 0.00-0.20s  | pure black                                              |
/// | 0.20-0.35s  | the orange dot pops in at the exact centre              |
/// | 0.35-1.26s  | it expands, ease-out, until it covers the screen        |
/// | 0.90-1.50s  | the fill dissolves to a soft glow; symbol + wordmark in  |
/// | 1.56-2.25s  | light sweeps across the "N" and the pin                 |
/// | 1.68-2.16s  | the tagline arrives                                     |
/// | 2.04-2.88s  | the four feature icons stagger in                       |
/// | 3.00s       | hand off to the next screen                             |
///
/// The fill dissolves rather than staying orange: the artwork is green, orange
/// and white, and none of it reads against a full-bleed orange field. What is
/// left is a centred orange glow behind the mark, which keeps the burst's
/// colour without fighting the logo.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Total time on screen before the hand-off.
  static const Duration totalDuration = Duration(milliseconds: 3000);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: SplashScreen.totalDuration,
  );

  // --- Beat 2: the dot ------------------------------------------------------
  late final Animation<double> _dotPop = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.067, 0.117, curve: Curves.easeOutBack),
  );

  // --- Beat 3/4: the expansion ----------------------------------------------
  late final Animation<double> _expansion = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.117, 0.42, curve: Curves.easeOutCubic),
  );

  /// Full strength while the circle travels, then down to a residual glow.
  late final Animation<double> _burstIntensity = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1.0),
        weight: 30,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 0.16)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.16, end: 0.11),
        weight: 50,
      ),
    ],
  ).animate(_c);

  // --- Beat 5: the logo -----------------------------------------------------
  late final Animation<double> _logoIn = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.30, 0.50, curve: Curves.easeOut),
  );

  late final Animation<double> _logoScale = Tween<double>(
    begin: 0.82,
    end: 1.0,
  ).animate(
    CurvedAnimation(
      parent: _c,
      curve: const Interval(0.30, 0.56, curve: Curves.easeOutCubic),
    ),
  );

  late final Animation<double> _wordmarkIn = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.38, 0.58, curve: Curves.easeOut),
  );

  // --- Beat 6: the shine ----------------------------------------------------
  late final Animation<double> _shine = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.52, 0.75, curve: Curves.easeInOut),
  );

  // --- Beat 7: the tagline --------------------------------------------------
  late final Animation<double> _taglineIn = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.56, 0.72, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _c.addStatusListener(_onStatus);
    _c.forward();
  }

  @override
  void dispose() {
    _c
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;

    // Three-stage hand-off:
    //   fresh install   -> language screen
    //   language chosen -> login
    //   session restored-> the rider gate, which decides between the
    //                      onboarding wizard, the waiting room and the home
    //                      screen once it has asked the API
    final bool chosenLanguage =
        context.read<LocaleController>().hasChosenLanguage;
    final bool signedIn = context.read<AuthController>().isSignedIn;

    final String next;
    if (!chosenLanguage) {
      next = AppRoutes.language;
    } else if (!signedIn) {
      next = AppRoutes.login;
    } else {
      next = AppRoutes.home;
    }

    Navigator.of(context).pushReplacementNamed(next);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;

            // Sized off the shorter axis so the lockup keeps its proportions
            // on both a small phone and a tablet.
            final double symbolWidth = (w * 0.50).clamp(150.0, 280.0);
            final double wordmarkWidth = (w * 0.60).clamp(180.0, 340.0);
            final bool roomForIcons = h > 560;

            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // Beats 2-4.
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (BuildContext context, _) {
                      return CustomPaint(
                        painter: GlowBurstPainter(
                          expansion: _expansion.value,
                          intensity: _burstIntensity.value * _dotPop.value,
                        ),
                      );
                    },
                  ),
                ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: <Widget>[
                        const Spacer(flex: 5),

                        // Beats 5 + 6.
                        FadeTransition(
                          opacity: _logoIn,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: ShineSweep(
                              progress: _shine,
                              // Default filter quality, not medium: on a large
                              // downscale medium takes Impeller's mipmap path,
                              // which renders black on some Android devices.
                              // See BrandMark for where that actually bit.
                              child: Image.asset(
                                AppAssets.symbol,
                                width: symbolWidth,
                                fit: BoxFit.contain,
                                semanticLabel: 'Nexmile',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        _RiseIn(
                          animation: _wordmarkIn,
                          offset: 14,
                          child: Image.asset(
                            AppAssets.wordmark,
                            width: wordmarkWidth,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Beat 7.
                        _RiseIn(
                          animation: _taglineIn,
                          offset: 10,
                          child: const _Tagline(),
                        ),

                        const Spacer(flex: 4),

                        // Beat 8.
                        if (roomForIcons) _FeatureRow(controller: _c),
                        SizedBox(height: roomForIcons ? 34 : 12),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Fade plus a short upward slide — the splash's one entrance gesture, reused
/// so the beats feel like a single sequence rather than separate effects.
class _RiseIn extends StatelessWidget {
  const _RiseIn({
    required this.animation,
    required this.child,
    this.offset = 12,
  });

  final Animation<double> animation;
  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? built) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, offset * (1 - animation.value)),
            child: built,
          ),
        );
      },
    );
  }
}

/// "FAST DELIVERY. FRESH SMILES." in the logo's own two-colour treatment.
class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    const TextStyle base = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 2.2,
      height: 1.4,
      leadingDistribution: TextLeadingDistribution.even,
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _TaglineDash(color: AppColors.greenLight, flip: false),
          const SizedBox(width: 10),
          Text.rich(
            const TextSpan(
              children: <TextSpan>[
                TextSpan(
                  text: 'FAST DELIVERY.',
                  style: TextStyle(color: AppColors.greenLight),
                ),
                TextSpan(text: '   '),
                TextSpan(
                  text: 'FRESH SMILES.',
                  style: TextStyle(color: AppColors.orangePulse),
                ),
              ],
            ),
            style: base,
            maxLines: 1,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(width: 10),
          const _TaglineDash(color: AppColors.orangePulse, flip: true),
        ],
      ),
    );
  }
}

class _TaglineDash extends StatelessWidget {
  const _TaglineDash({required this.color, required this.flip});

  final Color color;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: flip ? Alignment.centerLeft : Alignment.centerRight,
          end: flip ? Alignment.centerRight : Alignment.centerLeft,
          colors: <Color>[color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// The logo's four pillars, staggered in one after another.
///
/// Labels stay in English here because the splash runs before the user has
/// chosen a language, and because they are part of the logo lockup itself.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.controller});

  final AnimationController controller;

  static const List<(IconData, String)> _features = <(IconData, String)>[
    (Icons.place_outlined, 'NEARBY'),
    (Icons.bolt_outlined, 'FAST'),
    (Icons.shopping_bag_outlined, 'EVERYTHING'),
    (Icons.verified_user_outlined, 'TRUSTED'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < _features.length; i++) ...<Widget>[
          if (i > 0)
            Container(
              width: 1,
              height: 30,
              color: AppColors.white.withValues(alpha: 0.14),
            ),
          Expanded(
            child: _RiseIn(
              // 0.68 -> 0.83 for the first, each next one 0.05 later.
              animation: CurvedAnimation(
                parent: controller,
                curve: Interval(
                  0.68 + i * 0.05,
                  0.81 + i * 0.05,
                  curve: Curves.easeOut,
                ),
              ),
              offset: 12,
              child: _Feature(
                icon: _features[i].$1,
                label: _features[i].$2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 22, color: AppColors.white.withValues(alpha: 0.92)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              height: 1.3,
              leadingDistribution: TextLeadingDistribution.even,
              color: AppColors.white.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }
}
