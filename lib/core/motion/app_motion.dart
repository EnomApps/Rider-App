import 'package:flutter/material.dart';

/// The app's motion vocabulary.
///
/// Three rules hold everything here together:
///
/// 1. **Motion explains, it does not decorate.** Something moves because it
///    arrived, changed, or responded to a finger — never because a screen
///    looked static.
/// 2. **Entrances finish.** Every animation in this file settles except the
///    ones that report a live state ([BreathingDot], [Shimmer]), and those run
///    only while that state is true. A screen that never stops moving is a
///    screen a rider's eye never stops tracking, and it makes the widget tests
///    impossible to settle.
/// 3. **The system's accessibility setting wins.** Everything checks
///    [MediaQuery.disableAnimationsOf] and renders its finished state
///    immediately when animations are switched off at the OS level.
class AppMotion {
  const AppMotion._();

  /// A tap responding under the finger. Anything slower feels unhooked from
  /// the touch.
  static const Duration instant = Duration(milliseconds: 120);

  /// The default for a thing appearing or changing in place.
  static const Duration quick = Duration(milliseconds: 260);

  /// Entrances, expansions, and anything crossing a meaningful distance.
  static const Duration medium = Duration(milliseconds: 420);

  /// Reserved for a moment worth waiting for — an order accepted, a delivery
  /// confirmed.
  static const Duration slow = Duration(milliseconds: 620);

  /// Gap between neighbours in a staggered entrance.
  ///
  /// Deliberately short. Long stagger looks impressive on a design mock and
  /// wastes a rider's time on every single scroll of a list they are reading
  /// for the fourth time that hour.
  static const Duration stagger = Duration(milliseconds: 55);

  /// How far a staggered child rises into place. Small on purpose — the eye
  /// reads it as "settled", not as "flew in".
  static const double rise = 14;

  /// Deceleration for things entering: fast at first, easing to rest.
  static const Curve enter = Curves.easeOutCubic;

  /// Symmetric easing for a value changing in place.
  static const Curve change = Curves.easeInOutCubic;

  /// A little overshoot, for the one or two moments that deserve emphasis.
  static const Curve emphasise = Curves.easeOutBack;

  /// Pressed-state scale for a tappable surface.
  static const double pressScale = 0.972;

  /// True when the OS has asked for animations to be reduced or removed.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}

/// Fades and lifts its child into place once, on first build.
///
/// [index] staggers neighbours in a list or a column so the group reads as one
/// movement settling rather than a dozen unrelated ones. Finite by design: it
/// runs once and is then inert, which is what lets a test settle the tree.
class EntranceFade extends StatefulWidget {
  const EntranceFade({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = AppMotion.medium,
    this.rise = AppMotion.rise,
  });

  final Widget child;

  /// Position within its group. Each step adds [AppMotion.stagger] of delay.
  final int index;

  final Duration duration;

  /// Distance travelled upward into place. Zero fades without moving.
  final double rise;

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: AppMotion.enter,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (AppMotion.reduced(context)) {
      // Straight to the finished state. Not `forward()` at speed — a rider who
      // has asked for no animation should see none at all.
      _c.value = 1;
      return;
    }

    final Duration delay = AppMotion.stagger * widget.index;
    if (delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: _t.value,
          child: Transform.translate(
            offset: Offset(0, widget.rise * (1 - _t.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Wraps a group of children in staggered [EntranceFade]s.
///
/// Saves threading an index through by hand, and keeps the stagger consistent
/// wherever a column of cards appears.
List<Widget> entranceGroup(
  List<Widget> children, {
  int startIndex = 0,
  double rise = AppMotion.rise,
}) {
  return <Widget>[
    for (int i = 0; i < children.length; i++)
      EntranceFade(index: startIndex + i, rise: rise, child: children[i]),
  ];
}

/// A surface that presses in under a finger.
///
/// The scale is small and the timing short: this is tactile feedback, not an
/// effect. Used on cards that do something when tapped, so a rider wearing
/// gloves on a bike mount gets a physical answer to "did that register?".
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.scale = AppMotion.pressScale,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (_down == value || widget.onTap == null) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool still = AppMotion.reduced(context) || widget.onTap == null;

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _down && !still ? widget.scale : 1,
        duration: AppMotion.instant,
        curve: AppMotion.change,
        child: widget.child,
      ),
    );
  }
}

/// A number that counts to its new value rather than jumping.
///
/// Used for the delivery count, where the change is the point: a rider who has
/// just confirmed a delivery watches the figure they are paid against move.
/// Finite, so it settles.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.duration = AppMotion.slow,
  });

  final int value;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) {
      return Text('$value', style: style, textDirection: TextDirection.ltr);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: AppMotion.change,
      builder: (BuildContext context, double v, _) => Text(
        '${v.round()}',
        style: style,
        // Digits stay left-to-right inside a right-to-left layout.
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

/// A dot that breathes while something is live.
///
/// Runs forever *while mounted*, which is why every caller renders it only
/// when the state it reports is actually true. Replaces the older beacon on
/// the duty card with a softer, slower pulse and a second trailing ring, so
/// "am I receiving orders?" is answerable from a bike mount at a glance.
class BreathingDot extends StatefulWidget {
  const BreathingDot({
    super.key,
    required this.colour,
    this.size = 12,
    this.spread = 18,
  });

  final Color colour;

  /// Diameter of the solid centre.
  final double size;

  /// How far the outer ring travels beyond the centre.
  final double spread;

  @override
  State<BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<BreathingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double extent = widget.size + widget.spread;

    if (AppMotion.reduced(context)) {
      return SizedBox(
        width: extent,
        height: extent,
        child: Center(child: _core()),
      );
    }

    return SizedBox(
      width: extent,
      height: extent,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, _) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // Two rings, half a cycle apart, so the pulse never fully
              // empties — a single ring reads as a stutter at this speed.
              _ring(_c.value),
              _ring((_c.value + 0.5) % 1),
              _core(),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(double t) {
    final double size = widget.size + widget.spread * t;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.colour.withValues(alpha: 0.26 * (1 - t)),
      ),
    );
  }

  Widget _core() => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.colour,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: widget.colour.withValues(alpha: 0.55),
              blurRadius: 10,
            ),
          ],
        ),
      );
}

/// A placeholder block that shimmers while real content is on its way.
///
/// Better than a spinner for a list, because it says what is coming as well as
/// that something is: a rider glancing at the board sees the shape of two
/// order cards, not an abstract circle. Runs forever while mounted, so it is
/// only ever built inside a loading branch.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color base = theme.colorScheme.surfaceContainerHighest;
    final Color highlight = Color.alphaBlend(
      theme.colorScheme.onSurface.withValues(alpha: 0.05),
      base,
    );

    final BorderRadius radius = BorderRadius.circular(widget.radius);

    if (AppMotion.reduced(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: base, borderRadius: radius),
      );
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, _) {
        // A band travelling left to right, well outside the box at both ends
        // so the sweep enters and leaves rather than fading in place.
        final double t = _c.value * 2 - 0.5;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment(t - 1, 0),
              end: Alignment(t + 1, 0),
              colors: <Color>[base, highlight, base],
              stops: const <double>[0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}
