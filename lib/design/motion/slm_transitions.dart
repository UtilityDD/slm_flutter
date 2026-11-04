import 'package:flutter/material.dart';

import '../components/slm_text.dart';
import '../tokens/slm_motion.dart';
import 'slm_motion_scope.dart';
import 'slm_motion_widgets.dart';

/// The app's navigation motion vocabulary.
enum SlmTransition {
  /// Horizontal shared axis: onboarding steps, sibling pages.
  sharedAxisX,

  /// Fade with a short rise: opening detail pages.
  fadeRise,

  /// Old page fades out before the new one fades and scales in: switching
  /// context, e.g. lesson → quiz.
  fadeThrough,

  /// Grow from slightly smaller: dialogs-as-pages, celebrations.
  scaleFade,
}

/// The curved views of one route's animations for one [SlmTransition].
///
/// A CurvedAnimation adds a status listener to its parent and keeps it until
/// disposed, so these are built once per route (not in every
/// buildTransitions call) and disposed with the route.
class _SlmRouteCurves {
  final SlmTransition style;
  final Animation<double> primary;
  final Animation<double> secondary;
  final List<CurvedAnimation> _owned = [];

  _SlmRouteCurves(this.style, this.primary, this.secondary);

  CurvedAnimation _curve(Animation<double> parent, Curve curve, {Curve? reverse}) {
    final c = CurvedAnimation(parent: parent, curve: curve, reverseCurve: reverse);
    _owned.add(c);
    return c;
  }

  late final Animation<double> _inn = _curve(primary, SlmMotion.emphasized, reverse: SlmMotion.exit);
  late final Animation<double> _under = _curve(secondary, SlmMotion.emphasized, reverse: SlmMotion.exit);

  late final Widget Function(Widget child) build = switch (style) {
    SlmTransition.sharedAxisX => _sharedAxisX(),
    SlmTransition.fadeRise => _fadeRise(),
    SlmTransition.fadeThrough => _fadeThrough(),
    SlmTransition.scaleFade => _scaleFade(),
  };

  Widget Function(Widget) _sharedAxisX() {
    final slideIn = Tween(begin: const Offset(0.18, 0), end: Offset.zero).animate(_inn);
    final fadeIn = _curve(primary, const Interval(0.2, 1, curve: Curves.easeOut));
    final slideOut = Tween(begin: Offset.zero, end: const Offset(-0.18, 0)).animate(_under);
    final fadeOut = Tween(begin: 1.0, end: 0.0).animate(_curve(secondary, const Interval(0, 0.6)));
    return (child) => SlideTransition(
          position: slideIn,
          child: FadeTransition(
            opacity: fadeIn,
            child: SlideTransition(
              position: slideOut,
              child: FadeTransition(opacity: fadeOut, child: child),
            ),
          ),
        );
  }

  Widget Function(Widget) _fadeRise() {
    final rise = Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(_inn);
    return (child) => FadeTransition(
          opacity: _inn,
          child: SlideTransition(position: rise, child: child),
        );
  }

  Widget Function(Widget) _fadeThrough() {
    final fadeIn = _curve(primary, const Interval(0.35, 1, curve: Curves.easeOut));
    final scaleIn = Tween(begin: 0.94, end: 1.0).animate(_curve(primary, const Interval(0.35, 1, curve: SlmMotion.emphasized)));
    final fadeOut = Tween(begin: 1.0, end: 0.0).animate(_curve(secondary, const Interval(0, 0.35)));
    return (child) => FadeTransition(
          opacity: fadeIn,
          child: ScaleTransition(
            scale: scaleIn,
            child: FadeTransition(opacity: fadeOut, child: child),
          ),
        );
  }

  Widget Function(Widget) _scaleFade() {
    final scale = Tween(begin: 0.9, end: 1.0).animate(_inn);
    return (child) => FadeTransition(
          opacity: _inn,
          child: ScaleTransition(scale: scale, child: child),
        );
  }

  void dispose() {
    for (final c in _owned) {
      c.dispose();
    }
    _owned.clear();
  }
}

/// A route that uses an [SlmTransition]. Drop-in for [MaterialPageRoute].
class SlmPageRoute<T> extends PageRouteBuilder<T> {
  final SlmTransition style;

  SlmPageRoute({
    required WidgetBuilder builder,
    this.style = SlmTransition.fadeRise,
    super.settings,
    super.fullscreenDialog,
  }) : super(
          transitionDuration: SlmMotion.page,
          reverseTransitionDuration: SlmMotion.slow,
          pageBuilder: (context, _, _) => builder(context),
        );

  _SlmRouteCurves? _curves;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (slmReduceMotion(context)) return child;
    var curves = _curves;
    if (curves == null || curves.primary != animation || curves.secondary != secondaryAnimation) {
      curves?.dispose();
      curves = _curves = _SlmRouteCurves(style, animation, secondaryAnimation);
    }
    return curves.build(child);
  }

  @override
  void dispose() {
    _curves?.dispose();
    _curves = null;
    super.dispose();
  }
}

/// Swaps between steps with a direction-aware horizontal slide
/// (onboarding, multi-step forms). Change [index] to move.
class SlmStepSwitcher extends StatefulWidget {
  final int index;
  final IndexedWidgetBuilder builder;

  const SlmStepSwitcher({super.key, required this.index, required this.builder});

  @override
  State<SlmStepSwitcher> createState() => _SlmStepSwitcherState();
}

class _SlmStepSwitcherState extends State<SlmStepSwitcher> {
  int _dir = 1;

  @override
  void didUpdateWidget(covariant SlmStepSwitcher old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _dir = widget.index > old.index ? 1 : -1;
  }

  @override
  Widget build(BuildContext context) {
    final dir = _dir.toDouble();
    return AnimatedSwitcher(
      duration: slmReduceMotion(context) ? Duration.zero : SlmMotion.page,
      switchInCurve: SlmMotion.emphasized,
      switchOutCurve: SlmMotion.exit,
      layoutBuilder: (current, previous) => Stack(children: [...previous, ?current]),
      transitionBuilder: (child, a) {
        final incoming = child.key == ValueKey(widget.index);
        final from = Offset(incoming ? 0.25 * dir : -0.25 * dir, 0);
        return FadeTransition(
          opacity: a,
          child: SlideTransition(position: Tween(begin: from, end: Offset.zero).animate(a), child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey(widget.index), child: widget.builder(context, widget.index)),
    );
  }
}

/// Text that arrives word by word. Works for Bangla and English.
class SlmStaggeredText extends StatelessWidget {
  final String text;
  final SlmTextRole role;
  final Color? color;
  final TextAlign align;
  final Duration delay;

  const SlmStaggeredText(
    this.text, {
    super.key,
    this.role = SlmTextRole.headline,
    this.color,
    this.align = TextAlign.start,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final alignment = switch (align) {
      TextAlign.center => WrapAlignment.center,
      TextAlign.end || TextAlign.right => WrapAlignment.end,
      _ => WrapAlignment.start,
    };
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Wrap(
        alignment: alignment,
        spacing: 6,
        children: [
          for (var i = 0; i < words.length; i++)
            SlmReveal(
              index: i,
              delay: delay,
              rise: 10,
              child: SlmText(words[i], role: role, color: color),
            ),
        ],
      ),
    );
  }
}

/// Column whose children appear one after another.
class SlmStagger extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final Duration delay;
  final double gap;

  const SlmStagger({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.delay = Duration.zero,
    this.gap = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0 && gap > 0) SizedBox(height: gap),
          SlmReveal(index: i, delay: delay, child: children[i]),
        ],
      ],
    );
  }
}
