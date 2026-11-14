import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'full_scene_frame.dart';

// Making a level feel like play (owner's brief, 2026-11-07):
// - GuidedTour: the guide walks the real scene — a spotlight and a pulsing
//   ring on each thing; the player taps to discover ("কী জ্বলছে? ট্যাপ
//   করুন"); options are pointed at one by one ("এটা? এটা? না এটা?") without
//   ever showing the answer;
// - RescueBurst: the white cloud that swallows a fire, then cheering;
// - FreezeFrame: a deadly move freezes the scene in grey with a heartbeat
//   while the consequence plays, before the mistake card;
// - Combo: clean moves in a row multiply the points (×2, ×3);
// - stars: 1 = passed, 2 = no strikes, 3 = no strikes and quick.

// ============================================================================
// Guided tour
// ============================================================================

/// One beat of the tour: a line, and where to look.
@immutable
class TourBeat {
  const TourBeat(this.line, {this.target, this.targets = const [], this.tapToReveal = false, this.revealBn});

  final String line;

  /// The thing to light up (its widget's key).
  final GlobalKey? target;

  /// Options to point at one by one while the line is said ("এটা? এটা?").
  final List<GlobalKey> targets;

  /// Wait for the player to tap [target]; then [revealBn] pops up there.
  final bool tapToReveal;
  final String? revealBn;
}

/// The tour over the whole page (global coordinates, measured from keys).
class GuidedTour extends ConsumerStatefulWidget {
  const GuidedTour({super.key, required this.beats, required this.muted, required this.onDone});

  final List<TourBeat> beats;
  final bool muted;
  final VoidCallback onDone;

  @override
  ConsumerState<GuidedTour> createState() => _GuidedTourState();
}

class _GuidedTourState extends ConsumerState<GuidedTour> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  int _beat = -1;
  int _option = 0;
  Rect? _hole;
  String? _reveal;
  int _reveals = 0;
  var _done = false;
  Completer<void>? _next;
  Timer? _cycle;
  final _box = GlobalKey();

  TourBeat? get _cur => _beat >= 0 && _beat < widget.beats.length ? widget.beats[_beat] : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  @override
  void dispose() {
    _done = true;
    _cycle?.cancel();
    _pulse.dispose();
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  /// [key]'s rect in this overlay's coordinates.
  Rect? _rectOf(GlobalKey? key) {
    final target = key?.currentContext?.findRenderObject() as RenderBox?;
    final me = _box.currentContext?.findRenderObject() as RenderBox?;
    if (target == null || me == null || !target.hasSize || !me.hasSize) return null;
    final tl = me.globalToLocal(target.localToGlobal(Offset.zero));
    final br = me.globalToLocal(target.localToGlobal(target.size.bottomRight(Offset.zero)));
    return Rect.fromPoints(tl, br).inflate(8);
  }

  Future<void> _run() async {
    final quiet = MediaQuery.disableAnimationsOf(context);
    if (!quiet) _pulse.repeat();
    for (var i = 0; i < widget.beats.length; i++) {
      if (!mounted || _done) return;
      final b = widget.beats[i];
      setState(() {
        _beat = i;
        _option = 0;
        _reveal = null;
        _hole = _rectOf(b.target) ?? (b.targets.isEmpty ? null : _rectOf(b.targets.first));
      });
      ref.read(guideDirectorProvider.notifier).say(mood: i == 0 ? GuideMood.inspire : GuideMood.talk, line: b.line);
      final next = _next = Completer<void>();
      _cycle?.cancel();
      if (b.targets.length > 1) {
        // Point at each option in turn, and keep circling while he speaks.
        _cycle = Timer.periodic(const Duration(milliseconds: 900), (_) {
          if (!mounted) return;
          HapticFeedback.selectionClick();
          setState(() {
            _option = (_option + 1) % b.targets.length;
            _hole = _rectOf(b.targets[_option]);
          });
        });
      }
      final speech = MascotSpeechLibrary.speak(b.line, muted: widget.muted);
      if (b.tapToReveal) {
        // Interactive: the tour waits for the player's tap on the thing.
        await next.future;
      } else {
        final read = Duration(milliseconds: math.max(b.line.length * 85, b.targets.length * 900 + 600).clamp(2400, 9000));
        await Future.any([Future.wait([speech, Future<void>.delayed(read)]), next.future]);
      }
      _cycle?.cancel();
      if (!mounted || _done) return;
      if (b.tapToReveal && b.revealBn != null) {
        await Future<void>.delayed(const Duration(milliseconds: 1100));
      }
    }
    _finish();
  }

  void _tapAnywhere() {
    // No skipping (as level 1): a tap beside the thing only nudges.
    if (_cur != null) HapticFeedback.selectionClick();
  }

  void _tapTarget() {
    final b = _cur;
    if (b == null || !b.tapToReveal) return _tapAnywhere();
    HapticFeedback.mediumImpact();
    if (!widget.muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.ogg', volume: 0.6, muted: false));
    unawaited(MascotSpeechLibrary.stop());
    setState(() {
      _reveal = b.revealBn;
      _reveals++;
    });
    if (b.revealBn != null) ref.read(guideDirectorProvider.notifier).say(mood: GuideMood.glad, line: b.revealBn!);
    final n = _next;
    if (n != null && !n.isCompleted) n.complete();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _cycle?.cancel();
    _pulse.stop();
    unawaited(MascotSpeechLibrary.stop());
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final hole = _hole;
    final b = _cur;
    return Positioned.fill(
      child: Stack(
        key: _box,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _tapAnywhere,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, _) => CustomPaint(painter: _SpotPainter(hole: hole, pulse: _pulse.value)),
                ),
              ),
            ),
          ),
          if (hole != null && b != null && b.tapToReveal)
            Positioned.fromRect(
              rect: hole,
              child: Semantics(
                button: true,
                label: 'দেখুন',
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _tapTarget),
              ),
            ),
          if (hole != null && _reveal != null)
            Positioned(
              left: hole.center.dx - 110,
              width: 220,
              top: math.max(4, hole.top - 46),
              child: TweenAnimationBuilder<double>(
                key: ValueKey('reveal-$_reveals'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.elasticOut,
                builder: (_, t, child) => Transform.scale(scale: t.clamp(0.0, 1.3), child: child),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SlmColors.gold300,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 10)],
                    ),
                    child: Text(_reveal!, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.navy950)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The dim layer with a hole on the lit thing, and a pulsing gold ring.
class _SpotPainter extends CustomPainter {
  _SpotPainter({required this.hole, required this.pulse});
  final Rect? hole;
  final double pulse;

  @override
  void paint(Canvas c, Size s) {
    final h = hole;
    final dim = Paint()..color = const Color(0xB3050A16);
    if (h == null) {
      c.drawRect(Offset.zero & s, dim);
      return;
    }
    final r = RRect.fromRectAndRadius(h, const Radius.circular(18));
    c.drawPath(Path()..fillType = PathFillType.evenOdd..addRect(Offset.zero & s)..addRRect(r), dim);
    final grow = 6 + 10 * pulse;
    c.drawRRect(
      RRect.fromRectAndRadius(h.inflate(grow), const Radius.circular(24)),
      Paint()
        ..color = Color.fromRGBO(242, 182, 50, 0.9 * (1 - pulse))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    c.drawRRect(
      r,
      Paint()
        ..color = const Color(0xFFF2B632)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_SpotPainter old) => old.hole != hole || old.pulse != pulse;
}

// ============================================================================
// Rescue moment, freeze-frame, combo, stars
// ============================================================================

/// The white cloud that swallows a fire (one shot), then rests.
class RescueBurst extends StatefulWidget {
  const RescueBurst({super.key, required this.muted, this.cloud = true});
  final bool muted;

  /// Draw the cloud (off where a Lottie bloom plays; the sounds stay).
  final bool cloud;

  @override
  State<RescueBurst> createState() => _RescueBurstState();
}

class _RescueBurstState extends State<RescueBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    if (!widget.muted) {
      unawaited(ZlFx.cue('sounds/learn/rush_out.ogg', volume: 0.6, muted: false));
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (!widget.muted) unawaited(ZlFx.cue('sounds/quiz_complete.ogg', volume: 0.7, muted: false));
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      IgnorePointer(child: widget.cloud ? CustomPaint(painter: _CloudPainter(_c)) : const SizedBox.expand());
}

class _CloudPainter extends CustomPainter {
  _CloudPainter(this.t) : super(repaint: t);
  final Animation<double> t;

  @override
  void paint(Canvas c, Size s) {
    final v = Curves.easeOutCubic.transform(t.value);
    if (t.value >= 1) return;
    final fade = t.value < 0.6 ? 1.0 : (1 - (t.value - 0.6) / 0.4);
    final p = Paint()..color = Color.fromRGBO(245, 247, 250, 0.92 * fade);
    final centre = s.center(Offset.zero);
    final rnd = math.Random(3);
    for (var i = 0; i < 14; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final d = (20 + rnd.nextDouble() * s.shortestSide * 0.32) * v;
      c.drawCircle(centre + Offset(math.cos(a), math.sin(a) * 0.6) * d, (16 + rnd.nextDouble() * 22) * (0.4 + v), p);
    }
  }

  @override
  bool shouldRepaint(_CloudPainter old) => false;
}

/// The deadly moment: the scene stays, frozen in grey under a red pulse with a
/// heartbeat, while [consequence] (the level's own "what would happen")
/// plays; [onDone] after [ms].
///
/// While it runs it swallows every touch under it (the scene must not play on
/// during a death) — except, inside a [FullSceneFrame], the header band, so
/// close and mute (the heartbeat) stay live ([HeaderSafeShield]). Layers
/// listed after it in the Stack (a card, a continue button) stay live. Once
/// done it lets touches through again. It fills its Stack whether or not it
/// is wrapped in a [Positioned].
class FreezeFrame extends StatefulWidget {
  const FreezeFrame({super.key, required this.muted, required this.onDone, this.consequence, this.ms = 2200});
  final bool muted;
  final VoidCallback onDone;
  final Widget? consequence;
  final int ms;

  @override
  State<FreezeFrame> createState() => _FreezeFrameState();
}

class _FreezeFrameState extends State<FreezeFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.ms));

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    if (!widget.muted) unawaited(ZlFx.cue('sounds/learn/heartbeat.ogg', volume: 1, muted: false));
    _c.forward().whenComplete(() {
      if (!mounted) return;
      setState(() {}); // stop absorbing touches
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// True while the freeze runs and swallows touches (tests).
  @visibleForTesting
  bool get absorbing => !_c.isCompleted;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: HeaderSafeShield(
        active: absorbing,
        child: IgnorePointer(
          child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.consequence != null) widget.consequence!,
            AnimatedBuilder(
              animation: _c,
              builder: (_, _) {
                final beat = (math.sin(_c.value * math.pi * 4)).abs();
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [const Color(0x00000000), Color.fromRGBO(150, 20, 20, 0.35 + 0.3 * beat)],
                      radius: 1.0,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Grey-out filter for a frozen scene.
const freezeFilter = ColorFilter.matrix(<double>[
  0.3, 0.59, 0.11, 0, 0, //
  0.3, 0.59, 0.11, 0, 0, //
  0.3, 0.59, 0.11, 0, 0, //
  0, 0, 0, 1, 0,
]);

/// Clean moves in a row multiply the points: ×2 after two, ×3 after four.
class Combo {
  int streak = 0;
  int get mult => 1 + math.min(streak ~/ 2, 2);

  /// A right move: returns the multiplier it scored with and whether it just went up.
  (int, bool) hit() {
    final before = mult;
    streak++;
    return (before, mult > before);
  }

  void miss() => streak = 0;
}

/// "×2!" popping in the scene (never in the header).
class ComboPop extends StatelessWidget {
  const ComboPop({super.key, required this.mult});
  final int mult;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1300),
        builder: (_, t, child) {
          final pop = t < 0.3 ? Curves.easeOutBack.transform(t / 0.3) : 1.0;
          final fade = t < 0.75 ? 1.0 : 1 - (t - 0.75) / 0.25;
          return Opacity(opacity: fade.clamp(0.0, 1.0), child: Transform.scale(scale: 0.6 + 0.6 * pop, child: child));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF2B632), Color(0xFFE8590C)]),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [BoxShadow(color: Color(0x99E8590C), blurRadius: 16)],
          ),
          child: Text(enDigits('×$mult কম্বো!'), style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ),
    );
  }
}

/// Stars of a finished play: 1 passed, 2 no strikes, 3 no strikes and quick.
int starsFor({required bool passed, required int strikes, required bool quick}) {
  if (!passed) return 0;
  if (strikes > 0) return 1;
  return quick ? 3 : 2;
}
