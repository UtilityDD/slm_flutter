import 'package:flutter/material.dart';

/// Geometry of the floating notched dock (must match [_BottomNav] in main_shell).
abstract final class ShellDockMetrics {
  static const barH = 62.0;
  static const rise = 22.0;
  static const bottomGap = 8.0;
  static const radioApproxH = 64.0;

  static double compute(BuildContext context, {bool radioVisible = false}) {
    return barH +
        rise +
        bottomGap +
        MediaQuery.viewPaddingOf(context).bottom +
        (radioVisible ? radioApproxH : 0);
  }
}

/// Provides the dock clearance without inflating [SafeArea] / Scaffold chrome
/// (so page content still shows through the transparent notch).
class ShellDockScope extends InheritedWidget {
  final double bottomInset;

  const ShellDockScope({
    super.key,
    required this.bottomInset,
    required super.child,
  });

  static double of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShellDockScope>();
    return scope?.bottomInset ?? MediaQuery.viewPaddingOf(context).bottom;
  }

  @override
  bool updateShouldNotify(ShellDockScope oldWidget) =>
      bottomInset != oldWidget.bottomInset;
}

/// Bottom clearance for the floating dock. Prefer padding content with this
/// instead of [SafeArea] `bottom: true` (which leaves a solid band under the nav).
double shellDockBottomInset(BuildContext context) => ShellDockScope.of(context);

/// Gap above the dock for floating chips / FABs / bottom CTAs.
double shellDockBottomOffset(BuildContext context, [double gap = 12]) {
  return shellDockBottomInset(context) + gap;
}

/// Scroll/list padding that clears the floating dock.
EdgeInsets shellScrollPadding(
  BuildContext context, {
  double left = 0,
  double top = 0,
  double right = 0,
  double extraBottom = 12,
}) {
  return EdgeInsets.fromLTRB(
    left,
    top,
    right,
    shellDockBottomInset(context) + extraBottom,
  );
}

/// Top (and optional side) safe area — bottom stays open so the page paints
/// under the transparent dock. Clear the dock with [shellDockBottomInset].
class ShellSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const ShellSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = false,
    this.left = true,
    this.right = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}
