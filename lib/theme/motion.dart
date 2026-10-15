import 'package:flutter/material.dart';

/// Central motion tokens. Respect reduced motion via disableAnimationsOf.
class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration page = Duration(milliseconds: 400);

  static const Curve ease = Curves.easeOutCubic;
  static const Curve emphasized = Curves.fastOutSlowIn;

  static Duration scaled(BuildContext context, Duration d) {
    if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
    return d;
  }
}

/// Fade + slide entrance used for staggered list/grid items.
/// Pass [delay] as `index * 40ms` (capped by caller) for stagger effect.
class Entrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double slideY;
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.slideY = 24,
  });

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: AppMotion.slow);
    _opacity = CurvedAnimation(parent: _c, curve: AppMotion.ease);
    _offset = Tween<Offset>(begin: Offset(0, widget.slideY / 100), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: AppMotion.ease));
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void didUpdateWidget(Entrance old) {
    super.didUpdateWidget(old);
    if (old.delay != widget.delay) {
      _c.reset();
      if (widget.delay == Duration.zero) {
        _c.forward();
      } else {
        Future.delayed(widget.delay, () {
          if (mounted) _c.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// Shared slide-up page route for pushed screens.
Route<T> slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: AppMotion.page,
    reverseTransitionDuration: AppMotion.normal,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) {
      final offset = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: AppMotion.emphasized));
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: AppMotion.ease),
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}
