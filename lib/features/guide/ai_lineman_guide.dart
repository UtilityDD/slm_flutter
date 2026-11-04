import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../design/slm_design.dart';
import 'guide_director.dart';
import 'mascot_speech_library.dart';

/// Unified expressive Game Mascot ("ওস্তাদ লাইনম্যান") — used across the
/// Ladder, Touchable Side Items, Learn Field Cards, and Do Field Drills.
/// Includes smooth face crossfades, eye blinks/glances, body gestures,
/// gold celebration sparkles, and real-time lip-sync mouth animation.
///
/// Performance: an idle guide draws no frames. Blink and glance run on a
/// Timer and only swap the overlay image; faces fade through the image's own
/// opacity; the mouth and nod animate only while [MascotTalk.active] is true;
/// sparkles loop only in a joyful mood. All loops respect the OS
/// "remove animations" setting and stop while the route is hidden.
class AiLinemanGuide extends ConsumerStatefulWidget {
  final double sprite;
  final double bubbleWidth;
  final bool showBubble;
  final double bubbleOpacity;
  final bool large;

  /// Optional explicit overrides so legacy [DsCoach] call-sites can render
  /// the exact same unified mascot widget without duplicating state.
  final GuideMood? overrideMood;
  final String? overrideLine;
  final bool centered;

  const AiLinemanGuide({
    super.key,
    this.sprite = 96,
    this.bubbleWidth = 176,
    this.showBubble = true,
    this.bubbleOpacity = 1,
    this.large = false,
    this.overrideMood,
    this.overrideLine,
    this.centered = true,
  });

  @override
  ConsumerState<AiLinemanGuide> createState() => _AiLinemanGuideState();
}

enum _Eye { open, blink, glance, lapEnd }

class _AiLinemanGuideState extends ConsumerState<AiLinemanGuide> with TickerProviderStateMixin {
  /// One eye lap, as millisecond offsets into a 4.6 s loop: blink at 5–11 %,
  /// and on odd laps a glance at 45–62 %. Driven by a Timer, so an idle guide
  /// only rebuilds when the face overlay actually changes.
  static const _oddLap = [(230, _Eye.blink), (506, _Eye.open), (2070, _Eye.glance), (2852, _Eye.open), (4600, _Eye.lapEnd)];
  static const _evenLap = [(230, _Eye.blink), (506, _Eye.open), (4600, _Eye.lapEnd)];

  late final AnimationController _spark;
  late final AnimationController _face;
  late final AnimationController _gesture;
  late final AnimationController _settle;
  late final AnimationController _mouth;
  late final CurvedAnimation _faceIn;
  late final Animation<double> _faceOut;

  String _faceA = 'coach_ready';
  String _faceB = 'coach_ready';
  var _showingA = true;
  var _eyeLap = 0;
  var _eye = _Eye.open;
  Timer? _eyeTimer;
  var _loopsOn = true;
  GuideGesture _gestureTarget = GuideGesture.none;
  var _lastToken = 0;
  GuideMood? _lastOverrideMood;
  String? _lastOverrideLine;

  @override
  void initState() {
    super.initState();
    _spark = AnimationController(vsync: this, duration: const Duration(milliseconds: 4600));
    _face = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))..value = 1;
    _gesture = AnimationController(vsync: this, duration: const Duration(milliseconds: 680));
    _settle = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..value = 1;
    _mouth = AnimationController(vsync: this, duration: const Duration(milliseconds: 1320));
    _faceIn = CurvedAnimation(parent: _face, curve: Curves.easeInOutCubic);
    _faceOut = ReverseAnimation(_faceIn);
    MascotTalk.active.addListener(_onTalkChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loopsOn = slmLoopsOn(context) && TickerMode.valuesOf(context).enabled;
    _syncEyes();
    _syncMouth();
  }

  void _onTalkChanged() {
    _syncMouth();
    if (mounted) setState(() {});
  }

  bool get _isSpeaking => MascotTalk.active.value;

  /// The mouth cycles only while speaking and loops are allowed; otherwise it
  /// rests closed (no frames).
  void _syncMouth({bool restart = false}) {
    if (_isSpeaking && _loopsOn) {
      if (restart || !_mouth.isAnimating) {
        _mouth.repeat(period: const Duration(milliseconds: 1320));
      }
    } else if (_mouth.isAnimating || _mouth.value != 0) {
      _mouth
        ..stop()
        ..value = 0;
    }
  }

  /// Eyes run only while loops are allowed and this route is on screen.
  void _syncEyes() {
    if (_loopsOn) {
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
    MascotTalk.active.removeListener(_onTalkChanged);
    _eyeTimer?.cancel();
    _faceIn.dispose();
    _spark.dispose();
    _face.dispose();
    _gesture.dispose();
    _settle.dispose();
    _mouth.dispose();
    super.dispose();
  }

  /// Stable family face — blink/glance as soft overlay + lip-sync mouth when speaking.
  String _baseFace(GuideMood mood, {required bool speaking}) {
    return switch (mood) {
      GuideMood.glad || GuideMood.celebrate => 'coach_happy',
      GuideMood.warn || GuideMood.fright || GuideMood.fallen => 'coach_oops',
      GuideMood.talk || GuideMood.inspire || GuideMood.wake => speaking ? 'coach_talk' : 'coach_ready',
      GuideMood.sleep => 'coach_ready',
      GuideMood.listen || GuideMood.think || GuideMood.idle => speaking ? 'coach_talk' : 'coach_ready',
    };
  }

  String? _blinkOverlay(GuideMood mood, {required bool reduce, required bool speaking}) {
    if (reduce) return null;
    final blink = _eye == _Eye.blink;
    final glance = _eye == _Eye.glance;
    if (!blink && !glance) return null;
    return switch (mood) {
      GuideMood.warn || GuideMood.fright || GuideMood.fallen => blink ? 'coach_oops_blink' : 'coach_oops_glance',
      GuideMood.glad || GuideMood.celebrate => null,
      _ => speaking
          ? (blink ? 'coach_talk_blink' : 'coach_talk_glance')
          : (blink ? 'coach_blink' : 'coach_glance'),
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

  void _syncFromState(
    GuideMood mood,
    GuideGesture gesture,
    int token,
    bool hasEntrance, {
    required bool reduce,
  }) {
    _crossTo(_baseFace(mood, speaking: _isSpeaking));

    final overrideChanged = widget.overrideMood != null &&
        (widget.overrideMood != _lastOverrideMood || widget.overrideLine != _lastOverrideLine);
    if (token == _lastToken && !overrideChanged) return;
    _lastToken = token;
    _lastOverrideMood = widget.overrideMood;
    _lastOverrideLine = widget.overrideLine;

    // Only settle-pop on entrance / a new override beat — not every glad/oops.
    if (hasEntrance || overrideChanged) {
      if (reduce) {
        _settle.value = 1;
      } else {
        _settle.forward(from: 0);
      }
    }

    if (gesture != _gestureTarget) {
      _gestureTarget = gesture;
      if (reduce) {
        _gesture.value = gesture == GuideGesture.none ? 0 : 1;
      } else if (gesture == GuideGesture.none) {
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

  /// Lip overlay — positioned once; only its painter repaints with [_mouth].
  Widget? _talkMouth(GuideMood mood) {
    if (mood == GuideMood.glad ||
        mood == GuideMood.celebrate ||
        mood == GuideMood.warn ||
        mood == GuideMood.fright ||
        mood == GuideMood.fallen) {
      return null;
    }
    final s = widget.sprite;
    const imageAspect = 597 / 888;
    final imageW = s * imageAspect;
    final left = (s - imageW) / 2;
    return Positioned(
      left: left + imageW * 0.455,
      top: s * 0.442,
      width: imageW * 0.16,
      height: s * 0.076,
      child: CustomPaint(painter: _LiveLipPainter(_mouth)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guide = ref.watch(guideDirectorProvider);
    final reduce = slmReduceMotion(context);
    final activeMood = widget.overrideMood ?? guide.mood;
    final activeLine = widget.overrideLine ?? guide.line;
    final activeGesture = widget.overrideMood != null ? GuideGesture.none : guide.gesture;

    _syncFromState(activeMood, activeGesture, guide.token, guide.entrance != null, reduce: reduce);

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

    final warn = activeMood == GuideMood.warn || activeMood == GuideMood.fright || activeMood == GuideMood.fallen;
    final joy = activeMood == GuideMood.glad || activeMood == GuideMood.celebrate;
    final sleep = activeMood == GuideMood.sleep;
    final speaking = _isSpeaking;
    // Sparkles are the only continuous idle motion, and only in a joyful mood.
    slmSyncLoop(context, _spark, enabled: joy);

    final overlay = _blinkOverlay(activeMood, reduce: reduce, speaking: speaking);
    final topFace = _showingA ? _faceA : _faceB;
    final botFace = _showingA ? _faceB : _faceA;
    final kind = _gestureTarget == GuideGesture.none ? activeGesture : _gestureTarget;
    final s = widget.sprite;
    final stars = s > 120 ? 5 : 3;
    final mouth = speaking ? _talkMouth(activeMood) : null;

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
            ?mouth,
            if (joy && !reduce)
              for (var i = 0; i < stars; i++)
                AnimatedBuilder(
                  animation: _spark,
                  child: Icon(
                    Icons.auto_awesome,
                    size: s > 120 ? 15 : 11,
                    color: SlmColors.gold300.withValues(alpha: 0.9),
                  ),
                  builder: (_, icon) {
                    final t = _spark.value;
                    return Positioned(
                      left: s * 0.68 + 12 * math.cos(t * math.pi * 2 + i * 1.05),
                      top: 2 + 10 * math.sin(t * math.pi * 2 + i * 0.9),
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
        crossAxisAlignment: widget.centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          if (widget.showBubble && activeLine.isNotEmpty && widget.bubbleOpacity > 0.02) ...[
            Opacity(
              opacity: widget.bubbleOpacity.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - widget.bubbleOpacity.clamp(0.0, 1.0)) * 8),
                child: _GuideBubble(
                  key: ValueKey(activeLine),
                  line: enDigits(activeLine),
                  warn: warn,
                  joy: joy,
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

    // Settle pop, warn shake and the speaking nod move the whole body; the
    // subtree is built once and only the transform changes per frame.
    final nodOn = speaking && !reduce;
    return AnimatedBuilder(
      animation: nodOn ? Listenable.merge([_settle, _mouth]) : _settle,
      child: body,
      builder: (_, child) {
        final settle = Curves.easeOutCubic.transform(_settle.value.clamp(0.0, 1.0));
        final nod = nodOn ? 1.4 * math.sin(_mouth.value * math.pi * 2) : 0.0;
        final warnShake = (warn && !reduce && _settle.value < 0.95)
            ? math.sin(_settle.value * math.pi * 5) * 4 * (1 - _settle.value)
            : 0.0;
        return Transform.translate(
          offset: Offset(warnShake, (1 - settle) * (widget.large ? 24 : 12) + nod),
          child: Transform.scale(
            scale: 0.92 + 0.08 * settle,
            alignment: widget.centered ? Alignment.bottomCenter : Alignment.bottomLeft,
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
  final bool joy;
  final double maxWidth;

  const _GuideBubble({
    super.key,
    required this.line,
    required this.warn,
    required this.joy,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = warn
        ? SlmColors.danger.withValues(alpha: 0.75)
        : joy
            ? SlmColors.emerald400.withValues(alpha: 0.75)
            : SlmColors.gold400.withValues(alpha: 0.55);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: warn
                ? [
                    const Color(0xF22D1216),
                    SlmColors.navy900.withValues(alpha: 0.96),
                  ]
                : [
                    SlmColors.navy850.withValues(alpha: 0.96),
                    SlmColors.navy950.withValues(alpha: 0.96),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
          child: Text(
            line,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: warn ? const Color(0xFFFFE4E1) : SlmColors.ivory,
              fontSize: 13.5,
              height: 1.32,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mouth closure over one 1.32 s talk cycle (0 = open, 1 = closed).
double _lipClose(double t) {
  const keys = <(double, double)>[
    (0.00, 0.16),
    (0.05, 0.00),
    (0.16, 0.00),
    (0.19, 1.00),
    (0.23, 0.00),
    (0.35, 0.00),
    (0.39, 0.58),
    (0.45, 0.00),
    (0.56, 0.00),
    (0.59, 1.00),
    (0.64, 0.00),
    (0.76, 0.00),
    (0.82, 0.34),
    (0.88, 0.00),
    (0.95, 0.86),
    (1.00, 0.16),
  ];
  for (var i = 0; i < keys.length - 1; i++) {
    final a = keys[i];
    final b = keys[i + 1];
    if (t < a.$1 || t > b.$1) continue;
    final u = ((t - a.$1) / (b.$1 - a.$1)).clamp(0.0, 1.0);
    final snap = (b.$2 - a.$2).abs() > 0.7;
    final s = snap ? Curves.easeInOutQuart.transform(u) : Curves.easeInOutCubic.transform(u);
    return a.$2 + (b.$2 - a.$2) * s;
  }
  return keys.last.$2;
}

/// Repaints with the mouth controller without rebuilding any widget.
class _LiveLipPainter extends CustomPainter {
  _LiveLipPainter(this.mouth) : super(repaint: mouth);

  final Animation<double> mouth;

  @override
  void paint(Canvas canvas, Size size) => MascotLipPainter(_lipClose(mouth.value)).paint(canvas, size);

  @override
  bool shouldRepaint(_LiveLipPainter old) => old.mouth != mouth;
}

/// Lip-sync mouth overlay painter shared across all Mascot appearances.
class MascotLipPainter extends CustomPainter {
  const MascotLipPainter(this.close);

  final double close;

  @override
  void paint(Canvas canvas, Size size) {
    final c = close.clamp(0.0, 1.0);
    if (c < 0.06 || size.width < 2 || size.height < 2) return;
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromLTWH(0, size.height * 0.04, size.width, size.height * 0.92)),
    );
    final skin = Paint()..color = const Color(0xFFC67C4C);
    final meet = size.height * 0.40;
    final upperH = (meet + size.height * 0.08) * c;
    final lowerH = (size.height - meet + size.height * 0.08) * c;
    final upper = Path()
      ..moveTo(-2, -2)
      ..lineTo(size.width + 2, -2)
      ..lineTo(size.width + 2, upperH * 0.62)
      ..quadraticBezierTo(size.width * 0.5, upperH * 1.18, -2, upperH * 0.62)
      ..close();
    canvas.drawPath(upper, skin);
    final ly = size.height - lowerH;
    final lower = Path()
      ..moveTo(-2, size.height + 2)
      ..lineTo(size.width + 2, size.height + 2)
      ..lineTo(size.width + 2, ly + lowerH * 0.42)
      ..quadraticBezierTo(size.width * 0.5, ly - lowerH * 0.16, -2, ly + lowerH * 0.42)
      ..close();
    canvas.drawPath(lower, skin);
    if (c > 0.82) {
      final lip = Paint()
        ..color = const Color(0xFF2C1A12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.15, size.width * 0.048)
        ..strokeCap = StrokeCap.round;
      final smile = Path()
        ..moveTo(size.width * 0.20, meet)
        ..quadraticBezierTo(size.width * 0.5, meet + size.height * 0.14, size.width * 0.80, meet);
      canvas.drawPath(smile, lip);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MascotLipPainter old) => old.close != close;
}
