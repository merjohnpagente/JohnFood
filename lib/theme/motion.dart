import 'package:flutter/widgets.dart';

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
