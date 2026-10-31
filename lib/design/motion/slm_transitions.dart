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

/// Wraps a page in one of the [SlmTransition] styles. [secondary] animates
/// the page underneath when another page is pushed on top.
Widget slmTransition(
  SlmTransition style,
  Animation<double> primary,
  Animation<double> secondary,
  Widget child,
) {
  final inn = CurvedAnimation(parent: primary, curve: SlmMotion.emphasized, reverseCurve: SlmMotion.exit);
  final under = CurvedAnimation(parent: secondary, curve: SlmMotion.emphasized, reverseCurve: SlmMotion.exit);
  switch (style) {
    case SlmTransition.sharedAxisX:
      return SlideTransition(
        position: Tween(begin: const Offset(0.18, 0), end: Offset.zero).animate(inn),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: primary, curve: const Interval(0.2, 1, curve: Curves.easeOut)),
          child: SlideTransition(
            position: Tween(begin: Offset.zero, end: const Offset(-0.18, 0)).animate(under),
            child: FadeTransition(
              opacity: Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: secondary, curve: const Interval(0, 0.6))),
              child: child,
            ),
          ),
        ),
      );
    case SlmTransition.fadeRise:
      return FadeTransition(
        opacity: inn,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(inn),
          child: child,
        ),
      );
    case SlmTransition.fadeThrough:
      return FadeTransition(
        opacity: CurvedAnimation(parent: primary, curve: const Interval(0.35, 1, curve: Curves.easeOut)),
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(CurvedAnimation(parent: primary, curve: const Interval(0.35, 1, curve: SlmMotion.emphasized))),
          child: FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: secondary, curve: const Interval(0, 0.35))),
            child: child,
          ),
        ),
      );
    case SlmTransition.scaleFade:
      return FadeTransition(
        opacity: inn,
        child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(inn), child: child),
      );
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
          transitionsBuilder: (context, a, b, child) =>
              slmReduceMotion(context) ? child : slmTransition(style, a, b, child),
        );
}

/// For `ThemeData.pageTransitionsTheme`, so plain `MaterialPageRoute`s share
/// the same motion once a screen adopts the premium theme.
class SlmPageTransitionsBuilder extends PageTransitionsBuilder {
  final SlmTransition style;

  const SlmPageTransitionsBuilder([this.style = SlmTransition.fadeRise]);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (slmReduceMotion(context)) return child;
    return slmTransition(style, animation, secondaryAnimation, child);
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
