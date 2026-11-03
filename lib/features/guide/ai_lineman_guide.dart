import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/slm_design.dart';
import 'guide_director.dart';

/// Persistent expressive Line Man face — smooth face crossfades, soft gesture motion.
class AiLinemanGuide extends ConsumerStatefulWidget {
  final double sprite;
  final double bubbleWidth;
  final bool showBubble;
  final double bubbleOpacity;
  final bool large;

  const AiLinemanGuide({
    super.key,
    this.sprite = 96,
    this.bubbleWidth = 176,
    this.showBubble = true,
    this.bubbleOpacity = 1,
    this.large = false,
  });

  @override
  ConsumerState<AiLinemanGuide> createState() => _AiLinemanGuideState();
}

enum _Eye { open, blink, glance, lapEnd }

class _AiLinemanGuideState extends ConsumerState<AiLinemanGuide> with TickerProviderStateMixin {
  /// One eye lap, as offsets into a 4.8 s loop: blink at 5–11 %, and on odd
  /// laps a glance at 45–62 %. Driven by a Timer, so an idle guide only
  /// rebuilds when the face overlay actually changes.
  static const _oddLap = [(240, _Eye.blink), (528, _Eye.open), (2160, _Eye.glance), (2976, _Eye.open), (4800, _Eye.lapEnd)];
  static const _evenLap = [(240, _Eye.blink), (528, _Eye.open), (4800, _Eye.lapEnd)];

  late final AnimationController _spark;
  late final AnimationController _face;
  late final AnimationController _gesture;
  late final AnimationController _settle;
  late final CurvedAnimation _faceIn;
  late final Animation<double> _faceOut;

  String _faceA = 'coach_ready';
  String _faceB = 'coach_ready';
  var _showingA = true;
  var _eyeLap = 0;
  var _eye = _Eye.open;
  Timer? _eyeTimer;
  GuideGesture _gestureTarget = GuideGesture.none;
  var _lastToken = 0;

  @override
  void initState() {
    super.initState();
    _spark = AnimationController(vsync: this, duration: const Duration(milliseconds: 4800));
    _face = AnimationController(vsync: this, duration: const Duration(milliseconds: 280))..value = 1;
    _gesture = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _settle = AnimationController(vsync: this, duration: const Duration(milliseconds: 640))..value = 1;
    _faceIn = CurvedAnimation(parent: _face, curve: Curves.easeInOutCubic);
    _faceOut = ReverseAnimation(_faceIn);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncEyes();
  }

  /// Eyes run only while loops are allowed and this route is on screen.
  void _syncEyes() {
    final on = slmLoopsOn(context) && TickerMode.valuesOf(context).enabled;
    if (on) {
      if (_eyeTimer == null) {
        _eyeLap++;
        _armEye(0);
      }
    } else {
      _eyeTimer?.cancel();
      _eyeTimer = null;
      _eye = _Eye.open;
    }
  }

  void _armEye(int i) {
    final lap = _eyeLap.isOdd ? _oddLap : _evenLap;
    final wait = lap[i].$1 - (i == 0 ? 0 : lap[i - 1].$1);
    _eyeTimer = Timer(Duration(milliseconds: wait), () {
      if (!mounted) return;
      final next = lap[i].$2;
      if (next == _Eye.lapEnd) {
        _eyeLap++;
        _armEye(0);
        return;
      }
      if (next != _eye) setState(() => _eye = next);
      _armEye(i + 1);
    });
  }

  @override
  void dispose() {
    _eyeTimer?.cancel();
    _faceIn.dispose();
    _spark.dispose();
    _face.dispose();
    _gesture.dispose();
    _settle.dispose();
    super.dispose();
  }

  /// Stable family face — blink/glance only as soft overlay, not hard asset thrash.
  String _baseFace(GuideMood mood) {
    return switch (mood) {
      GuideMood.glad || GuideMood.celebrate => 'coach_happy',
      GuideMood.warn || GuideMood.fright || GuideMood.fallen => 'coach_oops',
      GuideMood.talk || GuideMood.inspire || GuideMood.wake => 'coach_talk',
      GuideMood.sleep => 'coach_ready',
      GuideMood.listen || GuideMood.think || GuideMood.idle => 'coach_ready',
    };
  }

  String? _blinkOverlay(GuideMood mood, {required bool reduce}) {
    if (reduce) return null;
    final blink = _eye == _Eye.blink;
    final glance = _eye == _Eye.glance;
    if (!blink && !glance) return null;
    return switch (mood) {
      GuideMood.warn || GuideMood.fright || GuideMood.fallen => blink ? 'coach_oops_blink' : 'coach_oops_glance',
      GuideMood.talk || GuideMood.inspire || GuideMood.wake => blink ? 'coach_talk_blink' : 'coach_talk_glance',
      GuideMood.glad || GuideMood.celebrate => null,
      _ => blink ? 'coach_blink' : 'coach_glance',
    };
  }

  void _crossTo(String next) {
    final current = _showingA ? _faceA : _faceB;
    if (current == next) return;
    if (_showingA) {
      _faceB = next;
    } else {
      _faceA = next;
    }
    _showingA = !_showingA;
    _face
      ..value = 0
      ..forward();
  }

  void _syncFromState(GuideState guide, {required bool reduce}) {
    if (guide.token == _lastToken) return;
    _lastToken = guide.token;

    _crossTo(_baseFace(guide.mood));

    // Only settle-pop on entrance / first visible beat — not every glad/oops.
    if (guide.entrance != null) {
      _settle.forward(from: 0);
    }

    if (guide.gesture != _gestureTarget) {
      _gestureTarget = guide.gesture;
      if (reduce) {
        _gesture.value = guide.gesture == GuideGesture.none ? 0 : 1;
      } else if (guide.gesture == GuideGesture.none) {
        _gesture.animateTo(0, duration: const Duration(milliseconds: 520), curve: Curves.easeInOutCubic);
      } else {
        _gesture.animateTo(1, duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);
      }
    }
  }

  // One structure for every gesture value, so the sprite never remounts
  // when a gag starts or ends (identity transforms paint without a layer).
  Widget _gestureWrap(double g, GuideGesture kind, Widget child) {
    if (g < 0.001) kind = GuideGesture.none;
    final (Offset offset, double angle) = switch (kind) {
      GuideGesture.handstand => (Offset(0, widget.sprite * 0.08 * g), math.pi * g),
      GuideGesture.leanLeft => (Offset(-6 * g, 0), -0.28 * g),
      GuideGesture.leanRight => (Offset(6 * g, 0), 0.28 * g),
      GuideGesture.peek => (Offset(10 * g, -4 * g), 0.12 * g),
      GuideGesture.spinHop => (Offset(0, -12 * math.sin(g * math.pi)), math.pi * 2 * g),
      GuideGesture.none => (Offset.zero, 0.0),
    };
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(angle: angle, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guide = ref.watch(guideDirectorProvider);
    final reduce = slmReduceMotion(context);
    _syncFromState(guide, reduce: reduce);

    // Auto-end gag after a hold so we don't stick upside-down.
    ref.listen<GuideState>(guideDirectorProvider, (prev, next) {
      if (next.gesture == GuideGesture.none) return;
      final hold = next.gesture == GuideGesture.handstand ? 2200 : 1600;
      Future<void>.delayed(Duration(milliseconds: hold), () {
        if (!mounted) return;
        final now = ref.read(guideDirectorProvider);
        if (now.token == next.token && now.gesture != GuideGesture.none) {
          ref.read(guideDirectorProvider.notifier).endGesture();
        }
      });
    });

    final warn = guide.mood == GuideMood.warn || guide.mood == GuideMood.fright || guide.mood == GuideMood.fallen;
    final joy = guide.mood == GuideMood.glad || guide.mood == GuideMood.celebrate;
    final sleep = guide.mood == GuideMood.sleep;
    // Sparkles are the only continuous motion, and only in a joyful mood.
    slmSyncLoop(context, _spark, enabled: joy);

    final overlay = _blinkOverlay(guide.mood, reduce: reduce);
    final topFace = _showingA ? _faceA : _faceB;
    final botFace = _showingA ? _faceB : _faceA;
    final kind = _gestureTarget == GuideGesture.none ? guide.gesture : _gestureTarget;
    final s = widget.sprite;

    // Faces fade via the image's own opacity: no rebuild, no saveLayer.
    final sprite = RepaintBoundary(
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            _Face(asset: botFace, size: s, opacity: _faceOut),
            _Face(asset: topFace, size: s, opacity: _faceIn),
            if (overlay != null) _Face(asset: overlay, size: s, opacity: const AlwaysStoppedAnimation(0.92)),
            if (joy && !reduce)
              for (var i = 0; i < 3; i++)
                AnimatedBuilder(
                  animation: _spark,
                  child: Icon(Icons.auto_awesome, size: 11, color: SlmColors.gold300.withValues(alpha: 0.85)),
                  builder: (_, icon) {
                    final t = _spark.value;
                    return Positioned(
                      left: s * 0.68 + 10 * math.cos(t * math.pi * 2 + i),
                      top: 2 + 8 * math.sin(t * math.pi * 2 + i * 0.9),
                      child: icon!,
                    );
                  },
                ),
            if (sleep && !reduce)
              Positioned(
                right: 2,
                top: 2,
                child: Text('z', style: TextStyle(color: SlmColors.mist.withValues(alpha: 0.7), fontSize: 13)),
              ),
          ],
        ),
      ),
    );

    final body = SizedBox(
      width: widget.bubbleWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.showBubble && guide.line.isNotEmpty && widget.bubbleOpacity > 0.02) ...[
            Opacity(
              opacity: widget.bubbleOpacity.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - widget.bubbleOpacity.clamp(0.0, 1.0)) * 8),
                child: _GuideBubble(
                  key: ValueKey(guide.line),
                  line: guide.line,
                  warn: warn,
                  maxWidth: widget.bubbleWidth,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          AnimatedBuilder(
            animation: _gesture,
            child: sprite,
            builder: (_, child) => _gestureWrap(_gesture.value.clamp(0.0, 1.0), kind, child!),
          ),
        ],
      ),
    );

    return AnimatedBuilder(
      animation: _settle,
      child: body,
      builder: (_, child) {
        final settle = Curves.easeOutCubic.transform(_settle.value.clamp(0.0, 1.0));
        return Transform.translate(
          offset: Offset(0, (1 - settle) * (widget.large ? 28 : 14)),
          child: Transform.scale(
            scale: 0.92 + 0.08 * settle,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
    );
  }
}

class _Face extends StatelessWidget {
  final String asset;
  final double size;
  final Animation<double> opacity;

  const _Face({required this.asset, required this.size, required this.opacity});

  /// Tallest face export; never decode above the source.
  static const _maxPx = 900;

  @override
  Widget build(BuildContext context) {
    // Faces are taller than wide, so BoxFit.contain shows them [size] tall:
    // decode at that height × DPR instead of the full ~900 px source.
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round().clamp(1, _maxPx);
    return Image.asset(
      'assets/duty_slip/dress/$asset.webp',
      width: size,
      height: size,
      cacheHeight: px,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      opacity: opacity,
      errorBuilder: (_, _, _) => Icon(Icons.face_retouching_natural, size: size * 0.7, color: SlmColors.gold300),
    );
  }
}

class _GuideBubble extends StatelessWidget {
  final String line;
  final bool warn;
  final double maxWidth;

  const _GuideBubble({super.key, required this.line, required this.warn, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SlmColors.navy850.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: warn ? SlmColors.danger.withValues(alpha: 0.55) : SlmColors.gold400.withValues(alpha: 0.35),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Text(
            line,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: warn ? SlmColors.gold100 : SlmColors.ivory,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
