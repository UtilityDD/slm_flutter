import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Gesture hints (GAME_LEVEL_PLAYBOOK.md §1, beats 3–5): when a player seems
// stuck — no touch for a while although the level waits for input, or a few
// taps on nothing — an animated hand shows HOW to interact (tap, hold, drag,
// swipe, or a sweep over the choices), never WHAT the answer is.
//
// * A sweep glides over every option and never presses one.
// * A drag nudges the source object a short way in a generic direction; it
//   never travels to the right target.
// * It plays its animation twice, then the screen is idle again (zero frames);
//   it may come back after a longer gap, at most [GestureHints.maxShows] times
//   per waiting state. Any touch hides it at once and restarts the wait.
// * Reduced motion: a still hand with a soft fade only.
// * Widget tests: off (FLUTTER_TEST) unless a test sets
//   [GestureHints.debugEnableInTests] — as main.dart turns off the intro.

/// How the hand shows the interaction.
enum HintKind { tap, drag, hold, swipe, sweep }

/// The coordinate space of a [HintSpec]'s anchors.
enum HintSpace {
  /// Global (screen) logical pixels — e.g. from [HintSpec.globalRectOf].
  global,

  /// The [IdleHint]'s own box (its top-left is 0,0).
  local,

  /// A full-screen scene's design pixels (360 wide); [FullSceneFrame] maps them.
  scene,
}

/// What the hand should show now. Build it in the level's hint callback.
@immutable
class HintSpec {
  const HintSpec._(this.kind, {this.at = Offset.zero, this.toward = Offset.zero, this.travel = 0, this.options = const [], this.space = HintSpace.global});

  /// Tap here (a ripple at the fingertip).
  const HintSpec.tap(Offset at, {HintSpace space = HintSpace.global}) : this._(HintKind.tap, at: at, space: space);

  /// Press and hold here (a ring fills round the fingertip).
  const HintSpec.hold(Offset at, {HintSpace space = HintSpace.global}) : this._(HintKind.hold, at: at, space: space);

  /// Drag the thing under [from] a short way ([travel], at most
  /// [maxDragTravel]) in a generic direction [toward] (e.g. up, right). Never
  /// point it at the correct target — this shows that the object can be moved.
  const HintSpec.drag(Offset from, {Offset toward = const Offset(0, -1), double travel = 64, HintSpace space = HintSpace.global})
      : this._(HintKind.drag, at: from, toward: toward, travel: travel, space: space);

  /// A quick swipe from [from] toward [toward] (e.g. a card, a lever).
  const HintSpec.swipe(Offset from, {Offset toward = const Offset(1, 0), double travel = 110, HintSpace space = HintSpace.global})
      : this._(HintKind.swipe, at: from, toward: toward, travel: travel, space: space);

  /// Glide over every one of [options] (in order) without pressing any:
  /// "one of these is yours to pick".
  const HintSpec.sweep(List<Rect> options, {HintSpace space = HintSpace.global}) : this._(HintKind.sweep, options: options, space: space);

  final HintKind kind;

  /// Tap / hold point, or the start of a drag or swipe.
  final Offset at;

  /// Drag / swipe direction (any length; normalised).
  final Offset toward;

  /// Drag / swipe length in the spec's space.
  final double travel;

  /// Sweep: the choices the hand passes over.
  final List<Rect> options;

  final HintSpace space;

  /// The longest drag nudge (so it can never reach a target across the scene).
  static const maxDragTravel = 96.0;

  /// The global rect of the widget under [key], or null before layout.
  static Rect? globalRectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// A single big button: tap it.
  static HintSpec? tapOn(GlobalKey key) {
    final r = globalRectOf(key);
    return r == null ? null : HintSpec.tap(r.center);
  }

  /// A single big button that must be held (squeeze, spray …).
  static HintSpec? holdOn(GlobalKey key) {
    final r = globalRectOf(key);
    return r == null ? null : HintSpec.hold(r.center);
  }

  /// A draggable thing: a short nudge from its centre in a generic direction.
  static HintSpec? dragFrom(GlobalKey key, {Offset toward = const Offset(0, -1), double travel = 64}) {
    final r = globalRectOf(key);
    return r == null ? null : HintSpec.drag(r.center, toward: toward, travel: travel);
  }

  /// Choices on screen (cards, tiles): sweep over all of them.
  static HintSpec? sweepOver(Iterable<GlobalKey> keys) {
    final rects = [for (final k in keys) ?globalRectOf(k)];
    return rects.isEmpty ? null : HintSpec.sweep(rects);
  }

  /// The cells of a grid of [count] choices laid out in [size] (local space):
  /// [columns] across, [spacing] apart, cells [aspect] (width / height).
  static List<Rect> gridCells({required Size size, required int count, int columns = 2, double spacing = 14, double aspect = 1, EdgeInsets padding = EdgeInsets.zero}) {
    final inner = padding.deflateSize(size);
    final w = (inner.width - spacing * (columns - 1)) / columns;
    final h = w / aspect;
    return [
      for (var i = 0; i < count; i++)
        Rect.fromLTWH(padding.left + (i % columns) * (w + spacing), padding.top + (i ~/ columns) * (h + spacing), w, h),
    ];
  }
}

/// Global switches and timings.
abstract final class GestureHints {
  /// Tests that check hints set this (and reset it in tearDown).
  static bool debugEnableInTests = false;

  static final bool _inWidgetTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  /// Hints run in the app; in widget tests only when a test opts in.
  static bool get enabled => !_inWidgetTest || debugEnableInTests;

  /// No touch for this long while the level waits → the hand shows.
  static const idle = Duration(seconds: 8);

  /// After a hint played to its end untouched, the next one waits longer.
  static const rearm = Duration(seconds: 25);

  /// At most this many hints per waiting state.
  static const maxShows = 3;

  /// This many taps on nothing within [missWindow] → the hand shows now.
  static const missTaps = 3;
  static const missWindow = Duration(seconds: 4);

  /// The animation plays this many times per hint.
  static const laps = 2;

  /// One hand on screen at a time.
  static IdleHintState? _showing;
}

/// Lets a level talk to its [IdleHint]: report a tap that hit nothing useful
/// (the level's "plain tap" handler), or hide the hand.
class IdleHintController {
  IdleHintState? _state;

  /// A tap on nothing interactive (e.g. empty sky). Three within 4 s show the
  /// hand at once.
  void missTap() => _state?._miss();

  /// Hide the hand now and restart the wait.
  void hide() => _state?._touched();

  bool get showing => _state?.showing ?? false;
}

/// One frame of the hand (exposed for tests).
@immutable
class HintFrame {
  const HintFrame({required this.tip, required this.opacity, required this.press, this.ripple, this.ring, this.trailFrom, this.hover = 0});

  /// Where the fingertip is (local pixels).
  final Offset tip;
  final double opacity;

  /// 0 = not touching, 1 = pressed down.
  final double press;

  /// Tap ripple progress 0..1 (null = none).
  final double? ripple;

  /// Hold ring fill 0..1 (null = none).
  final double? ring;

  /// Drag / swipe: where the trail starts (null = no trail).
  final Offset? trailFrom;

  /// Sweep: lifted above the screen (bigger shadow).
  final double hover;
}

/// Wraps a waiting part of a level (the whole scene, a deck, a board) and
/// shows the hand over it after idle or confusion.
class IdleHint extends StatefulWidget {
  const IdleHint({
    super.key,
    required this.waiting,
    required this.spec,
    required this.child,
    this.waitKey,
    this.controller,
    this.sceneToLocal,
    this.autoMiss = true,
    this.idle = GestureHints.idle,
    this.rearm = GestureHints.rearm,
    this.maxShows = GestureHints.maxShows,
  });

  /// The level waits for the player's input now (false during intros, voice
  /// lines that lock input, animations, cards, results …).
  final bool waiting;

  /// The current hint (null = none now). [size] is this widget's box.
  final HintSpec? Function(Size size) spec;

  final Widget child;

  /// Identifies the waiting state (e.g. the round, the dealt options): a new
  /// value resets the count of hints shown.
  final Object? waitKey;

  final IdleHintController? controller;

  /// Maps [HintSpace.scene] points into this box (given by [FullSceneFrame]).
  final Offset Function(Offset scene)? sceneToLocal;

  /// Count taps inside this box that hit no small interactive widget as
  /// misses (true for decks and boards). A scene with one big tap detector
  /// should pass false and call [IdleHintController.missTap] from its own
  /// "tapped nothing" branch instead.
  final bool autoMiss;

  final Duration idle;
  final Duration rearm;
  final int maxShows;

  @override
  State<IdleHint> createState() => IdleHintState();
}

class IdleHintState extends State<IdleHint> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _wait;
  Timer? _missTimer;
  int _missN = 0;
  int _shows = 0;
  int _lap = 0;
  bool _visible = false;
  bool _routed = false;
  _Resolved? _geo;
  bool _still = false;

  /// The hand is on screen.
  bool get showing => _visible;

  /// Hints shown in this waiting state.
  int get shows => _shows;

  /// The frame the hand is drawn at now (tests).
  @visibleForTesting
  HintFrame? get debugFrame => _visible && _geo != null ? _geo!.frame(_c.value, still: _still) : null;

  /// The resolved hint geometry (tests): the option rects of a sweep, local.
  @visibleForTesting
  List<Rect> get debugOptions => _geo?.options ?? const [];

  bool get _enabled => GestureHints.enabled;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _c.addStatusListener(_onStatus);
    if (_enabled) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
      _routed = true;
      _arm(widget.idle);
    }
  }

  @override
  void didUpdateWidget(IdleHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget;
    if (old.controller != widget.controller) {
      if (old.controller?._state == this) old.controller!._state = null;
      widget.controller?._state = this;
    }
    if (!_enabled) return;
    if (old.waitKey != widget.waitKey) {
      _shows = 0;
      _hide();
      _arm(widget.idle);
    } else if (old.waiting != widget.waiting) {
      if (!widget.waiting) {
        _hide();
        _wait?.cancel();
      } else {
        _arm(widget.idle);
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller!._state = null;
    if (_routed) GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    _wait?.cancel();
    _missTimer?.cancel();
    if (identical(GestureHints._showing, this)) GestureHints._showing = null;
    _c.dispose();
    super.dispose();
  }

  bool get _canShow => mounted && _enabled && widget.waiting && _shows < widget.maxShows;

  void _arm(Duration d) {
    _wait?.cancel();
    _wait = null;
    if (!_canShow) return;
    _wait = Timer(d, _show);
  }

  void _onPointer(PointerEvent e) {
    if (e is! PointerDownEvent) return;
    final wasShowing = _visible;
    _touched();
    if (!wasShowing && widget.autoMiss && _isMiss(e)) _miss();
  }

  /// A touch anywhere: hide, and wait again from now.
  void _touched() {
    _hide();
    _arm(widget.idle);
  }

  void _miss() {
    if (!_canShow || _visible) return;
    _missN++;
    _missTimer ??= Timer(GestureHints.missWindow, () {
      _missTimer = null;
      _missN = 0;
    });
    if (_missN >= GestureHints.missTaps) {
      _missN = 0;
      _missTimer?.cancel();
      _missTimer = null;
      _show();
    }
  }

  /// A tap inside this box that hit no small interactive widget.
  bool _isMiss(PointerDownEvent e) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    final local = box.globalToLocal(e.position);
    if (!(Offset.zero & box.size).contains(local)) return false;
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, e.position, e.viewId);
    final area = box.size.width * box.size.height;
    for (final entry in result.path) {
      final t = entry.target;
      if (identical(t, box)) return true;
      if (t is RenderPointerListener && (t.onPointerDown != null || t.onPointerUp != null)) {
        // A detector covering (nearly) the whole box is the scene's or a
        // scroll view's, not a thing to press.
        if (t.hasSize && t.size.width * t.size.height < area * 0.85) return false;
      }
    }
    return false; // the touch landed on something above this box
  }

  void _show() {
    _wait?.cancel();
    _wait = null;
    if (!_canShow || _visible) return;
    // Covered by another route (e.g. the lesson page) or with tickers muted:
    // the hand would show offstage, never finish, and block every other hint.
    if (!TickerMode.valuesOf(context).enabled || ModalRoute.of(context)?.isCurrent == false) {
      _arm(widget.idle);
      return;
    }
    final other = GestureHints._showing;
    if (other != null && other.mounted && other._visible) {
      _arm(widget.idle);
      return;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) {
      _arm(widget.idle);
      return;
    }
    final spec = widget.spec(box.size);
    final geo = spec == null ? null : _Resolved.of(spec, box, widget.sceneToLocal);
    if (geo == null) {
      _arm(widget.idle);
      return;
    }
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    GestureHints._showing = this;
    setState(() {
      _geo = geo;
      _visible = true;
      _shows++;
      _lap = 0;
    });
    _c.duration = _still ? const Duration(milliseconds: 1800) : geo.lap;
    unawaited(_c.forward(from: 0));
  }

  void _onStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !_visible) return;
    _lap++;
    if (_lap < GestureHints.laps) {
      unawaited(_c.forward(from: 0));
      return;
    }
    _hide();
    _arm(widget.rearm);
  }

  void _hide() {
    if (identical(GestureHints._showing, this)) GestureHints._showing = null;
    if (!_visible) return;
    _c.stop();
    if (mounted) {
      setState(() {
        _visible = false;
        _geo = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final geo = _geo;
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_visible && geo != null)
          Positioned.fill(
            key: const ValueKey('gesture-hint'),
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: CustomPaint(painter: _HintPainter(repaint: _c, geo: geo, still: _still)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A hint resolved into this box's pixels, with its timeline.
class _Resolved {
  _Resolved(this.kind, {required this.at, this.dir = Offset.zero, this.travel = 0, this.options = const []});

  final HintKind kind;
  final Offset at;
  final Offset dir;
  final double travel;
  final List<Rect> options;

  static _Resolved? of(HintSpec s, RenderBox box, Offset Function(Offset)? scene) {
    Offset map(Offset p) => switch (s.space) {
          HintSpace.local => p,
          HintSpace.global => box.globalToLocal(p),
          HintSpace.scene => scene == null ? p : scene(p),
        };
    Rect mapRect(Rect r) => Rect.fromPoints(map(r.topLeft), map(r.bottomRight));
    if (s.kind == HintKind.sweep) {
      // Only the choices that sit in this box (a list's off-screen cache
      // items are left out).
      final inBox = Offset.zero & box.size;
      final opts = [for (final r in s.options) mapRect(r)].where((r) => r.width > 4 && r.height > 4 && inBox.contains(r.center)).toList();
      if (opts.isEmpty) return null;
      return _Resolved(HintKind.sweep, at: opts.first.center, options: opts);
    }
    final at = map(s.at);
    if (s.kind == HintKind.drag || s.kind == HintKind.swipe) {
      final end = map(s.at + s.toward);
      var d = end - at;
      if (d.distance < 0.001) d = const Offset(0, -1);
      d = d / d.distance;
      // Travel in local pixels (scale it like the anchors).
      final scale = (map(s.at + const Offset(100, 0)) - at).distance / 100;
      var travel = s.travel * (scale > 0 ? scale : 1);
      if (s.kind == HintKind.drag) travel = math.min(travel, HintSpec.maxDragTravel * (scale > 0 ? scale : 1));
      return _Resolved(s.kind, at: at, dir: d, travel: travel);
    }
    return _Resolved(s.kind, at: at);
  }

  Duration get lap => switch (kind) {
        HintKind.tap => const Duration(milliseconds: 1600),
        HintKind.hold => const Duration(milliseconds: 2400),
        HintKind.drag => const Duration(milliseconds: 2200),
        HintKind.swipe => const Duration(milliseconds: 1500),
        HintKind.sweep => Duration(milliseconds: 900 + 620 * options.length),
      };

  /// Where the fingertip rests for a still (reduced-motion) hand.
  Offset get stillTip {
    if (kind != HintKind.sweep) return at;
    if (options.length == 1) return options.first.center;
    // Between the first two choices at their right end: it points at the
    // group, not at one card (the deal is shuffled anyway).
    final sorted = [...options]..sort((a, b) => a.top == b.top ? a.left.compareTo(b.left) : a.top.compareTo(b.top));
    final a = sorted[0], b = sorted[1];
    if ((a.top - b.top).abs() < 2) return Offset((a.right + b.left) / 2, a.center.dy);
    return Offset(math.min(a.right, b.right) - 22, (a.bottom + b.top) / 2);
  }

  static double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  HintFrame frame(double t, {required bool still}) {
    if (still) {
      final fade = t < 0.25 ? t / 0.25 : (t > 0.75 ? (1 - t) / 0.25 : 1.0);
      return HintFrame(tip: stillTip, opacity: fade.clamp(0.0, 1.0) * 0.92, press: 0);
    }
    const enter = Offset(30, 38);
    switch (kind) {
      case HintKind.tap:
        final inT = Curves.easeOutCubic.transform(_seg(t, 0, 0.25));
        final down = Curves.easeOut.transform(_seg(t, 0.25, 0.36));
        final up = Curves.easeIn.transform(_seg(t, 0.38, 0.5));
        final out = _seg(t, 0.78, 1);
        final ripple = t >= 0.33 && t <= 0.85 ? _seg(t, 0.33, 0.85) : null;
        return HintFrame(
          tip: at + enter * (1 - inT) + Offset(6, 8) * out,
          opacity: (inT * (1 - out)).clamp(0.0, 1.0),
          press: (down - up).clamp(0.0, 1.0),
          ripple: ripple,
        );
      case HintKind.hold:
        final inT = Curves.easeOutCubic.transform(_seg(t, 0, 0.2));
        final down = Curves.easeOut.transform(_seg(t, 0.2, 0.28));
        final up = Curves.easeIn.transform(_seg(t, 0.8, 0.88));
        final out = _seg(t, 0.86, 1);
        final ring = t >= 0.28 && t <= 0.9 ? Curves.easeInOut.transform(_seg(t, 0.28, 0.8)) : null;
        return HintFrame(
          tip: at + enter * (1 - inT) + Offset(6, 8) * out,
          opacity: (inT * (1 - out)).clamp(0.0, 1.0),
          press: (down - up).clamp(0.0, 1.0),
          ring: ring,
        );
      case HintKind.drag:
      case HintKind.swipe:
        final swipe = kind == HintKind.swipe;
        final inT = Curves.easeOutCubic.transform(_seg(t, 0, swipe ? 0.2 : 0.18));
        final down = Curves.easeOut.transform(_seg(t, swipe ? 0.2 : 0.18, swipe ? 0.26 : 0.26));
        final move = swipe ? Curves.easeInCubic.transform(_seg(t, 0.26, 0.5)) : Curves.easeInOutCubic.transform(_seg(t, 0.26, 0.72));
        final up = Curves.easeIn.transform(_seg(t, swipe ? 0.5 : 0.72, swipe ? 0.56 : 0.8));
        final out = _seg(t, swipe ? 0.6 : 0.8, 1);
        final tip = at + dir * travel * move;
        return HintFrame(
          tip: tip + enter * (1 - inT),
          opacity: (inT * (1 - out)).clamp(0.0, 1.0),
          press: (down - up).clamp(0.0, 1.0),
          ripple: !swipe && t >= 0.2 && t <= 0.5 ? _seg(t, 0.2, 0.5) : null,
          trailFrom: move > 0.01 ? at : null,
        );
      case HintKind.sweep:
        // Over each choice's right half in turn, lifted — never pressing.
        final pts = [for (final r in options) Offset(r.left + r.width * 0.72, r.center.dy)];
        final inT = Curves.easeOutCubic.transform(_seg(t, 0, 0.14));
        final out = _seg(t, 0.86, 1);
        final glide = _seg(t, 0.14, 0.86);
        final f = glide * (pts.length - 1);
        final i = f.floor().clamp(0, math.max(0, pts.length - 2)).toInt();
        final local = pts.length == 1 ? 0.0 : Curves.easeInOutSine.transform((f - i).clamp(0.0, 1.0));
        final tip = pts.length == 1 ? pts.first : Offset.lerp(pts[i], pts[i + 1], local)!;
        final bob = math.sin(t * math.pi * 2 * pts.length) * 2.5;
        return HintFrame(
          tip: tip + const Offset(18, 26) * (1 - inT) + Offset(0, bob),
          opacity: (inT * (1 - out)).clamp(0.0, 1.0),
          press: 0,
          hover: 1,
        );
    }
  }
}

class _HintPainter extends CustomPainter {
  _HintPainter({required this.repaint, required this.geo, required this.still}) : super(repaint: repaint);
  final Animation<double> repaint;
  final _Resolved geo;
  final bool still;

  static const _gold = Color(0xFFFFC94A);

  /// The hand is drawn in a ~37 × 60 unit box; this makes it ~52 × 84 dp.
  static const _size = 1.4;
  static const _ink = Color(0xFF0B1630);

  @override
  void paint(Canvas canvas, Size size) {
    final f = geo.frame(repaint.value, still: still);
    if (f.opacity <= 0.01) return;
    final o = f.opacity;

    // Sweep: a soft dotted path through the choices (no stop marks).
    if (geo.kind == HintKind.sweep && !still && geo.options.length > 1) {
      final pts = [for (final r in geo.options) Offset(r.left + r.width * 0.72, r.center.dy)];
      final dot = Paint()..color = Colors.white.withValues(alpha: 0.22 * o);
      for (var i = 0; i < pts.length - 1; i++) {
        final a = pts[i], b = pts[i + 1];
        final n = math.max(2, ((b - a).distance / 12).round());
        for (var k = 1; k < n; k++) {
          canvas.drawCircle(Offset.lerp(a, b, k / n)!, 1.8, dot);
        }
      }
    }

    // Drag / swipe trail.
    final from = f.trailFrom;
    if (from != null && (f.tip - from).distance > 2) {
      final shader = LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.55 * o)]).createShader(Rect.fromPoints(from, f.tip));
      canvas.drawLine(
        from,
        f.tip,
        Paint()
          ..shader = shader
          ..strokeWidth = geo.kind == HintKind.swipe ? 8 : 12
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(from, 7, Paint()..color = Colors.white.withValues(alpha: 0.3 * o));
    }

    // Tap ripple: two rings from the fingertip.
    final rp = f.ripple;
    if (rp != null) {
      for (final lag in const [0.0, 0.28]) {
        final p = ((rp - lag) / (1 - lag)).clamp(0.0, 1.0);
        if (p <= 0) continue;
        final r = 10 + 34 * Curves.easeOut.transform(p);
        final a = (1 - p) * 0.7 * o;
        canvas.drawCircle(f.tip, r, Paint()..color = Colors.white.withValues(alpha: a * 0.16));
        canvas.drawCircle(
          f.tip,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = Colors.white.withValues(alpha: a),
        );
      }
    }

    // Hold ring: fills round the fingertip.
    final ring = f.ring;
    if (ring != null) {
      final rect = Rect.fromCircle(center: f.tip, radius: 30);
      canvas.drawCircle(
        f.tip,
        30,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = Colors.white.withValues(alpha: 0.28 * o),
      );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * ring,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = _gold.withValues(alpha: o),
      );
      if (f.press > 0.5) canvas.drawCircle(f.tip, 10, Paint()..color = Colors.white.withValues(alpha: 0.22 * o));
    }

    _paintHand(canvas, f);
  }

  void _paintHand(Canvas canvas, HintFrame f) {
    final o = f.opacity;
    final scale = _size * (1 - 0.08 * f.press) * (1 + 0.05 * f.hover);
    canvas.save();
    canvas.translate(f.tip.dx, f.tip.dy + 2.5 * f.press);
    canvas.rotate(-0.22);
    canvas.scale(scale);
    final hand = handPath();
    // Shadow: deeper when lifted (sweep), tight when pressed.
    final lift = 3 + 5 * f.hover - 2 * f.press;
    canvas.save();
    canvas.translate(lift * 0.6, lift);
    canvas.drawPath(
      hand,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.32 * o)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + 2 * f.hover),
    );
    canvas.restore();
    // A faint light rim so the hand reads on dark sheets as well as on sky.
    canvas.drawPath(
      hand,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.22 * o),
    );
    final bounds = hand.getBounds();
    canvas.drawPath(
      hand,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: o), const Color(0xFFDDE5F2).withValues(alpha: o)],
        ).createShader(bounds),
    );
    // Finger creases.
    final crease = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = _ink.withValues(alpha: 0.28 * o);
    canvas.drawLine(const Offset(10, 22), const Offset(10, 30), crease);
    canvas.drawLine(const Offset(18, 25), const Offset(18, 32), crease);
    canvas.drawLine(const Offset(-3, 9), const Offset(3, 9), crease);
    canvas.drawPath(
      hand,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = _ink.withValues(alpha: 0.9 * o),
    );
    // Gold cuff.
    final cuff = RRect.fromLTRBR(-8.5, 49, 27.5, 59, const Radius.circular(4));
    canvas.drawRRect(cuff, Paint()..color = _gold.withValues(alpha: o));
    canvas.drawRRect(
      cuff,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _ink.withValues(alpha: 0.9 * o),
    );
    // Nail glint on the fingertip.
    canvas.drawRRect(RRect.fromLTRBR(-3, 2.5, 3, 8, const Radius.circular(3)), Paint()..color = const Color(0xFFF4D9C6).withValues(alpha: 0.55 * o));
    canvas.restore();
  }

  /// A pointing hand, fingertip at (0, 0), body down and to the right.
  static Path handPath() => _hand ??= _buildHand();
  static Path? _hand;

  static Path _buildHand() {
    Path rr(double l, double t, double r, double b, double rad) => Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(rad)));
    var p = rr(-6, 0, 6, 32, 6); // index finger
    p = Path.combine(
      PathOperation.union,
      p,
      Path()
        ..addRRect(RRect.fromLTRBAndCorners(-8, 22, 27, 52,
            topLeft: const Radius.circular(6), topRight: const Radius.circular(10), bottomLeft: const Radius.circular(14), bottomRight: const Radius.circular(12))),
    );
    p = Path.combine(PathOperation.union, p, rr(5, 17, 15, 35, 5)); // middle
    p = Path.combine(PathOperation.union, p, rr(13, 20, 23, 37, 5)); // ring
    p = Path.combine(PathOperation.union, p, rr(20, 25, 28.5, 40, 4.2)); // little
    final thumb = rr(-5, -11, 5, 11, 5).transform((Matrix4.translationValues(-10, 35, 0)..rotateZ(0.62)).storage);
    p = Path.combine(PathOperation.union, p, thumb);
    return p;
  }

  @override
  bool shouldRepaint(_HintPainter old) => old.geo != geo || old.still != still;
}
