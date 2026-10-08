import 'package:flutter/material.dart';

class Breakpoints {
  static const double compact = 600;
  static const double tablet = 720;
  static const double medium = 1024;
  static const double desktop = 1100;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isCompact => screenWidth < Breakpoints.compact;
  bool get isWide => screenWidth >= Breakpoints.tablet;
  bool get isDesktop => screenWidth >= Breakpoints.desktop;

  double get pagePadding => isDesktop ? 32 : (isWide ? 24 : 16);
}

/// Centers content and limits its width on tablets / desktop / web.
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentWidth({super.key, required this.child, this.maxWidth = 1100});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Columns are added automatically: ~2 on phones, 3-4 on tablets, 5+ on desktop.
const foodGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 220,
  mainAxisExtent: 280,
  mainAxisSpacing: 14,
  crossAxisSpacing: 14,
);

/// Use in MaterialApp(builder: responsiveTextScale) so big system fonts
/// do not break the layout.
Widget responsiveTextScale(BuildContext context, Widget? child) {
  final mq = MediaQuery.of(context);
  return MediaQuery(
    data: mq.copyWith(
      textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.2),
    ),
    child: child ?? const SizedBox.shrink(),
  );
}
