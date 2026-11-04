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

class _AiLinemanGuideState extends ConsumerState<AiLinemanGuide> with TickerProviderStateMixin {
  late final AnimationController _eyes;
  late final AnimationController _face;
  late final AnimationController _gesture;
  late final AnimationController _settle;
  late final AnimationController _mouth;

  String _faceA = 'coach_ready';
  String _faceB = 'coach_ready';
  var _showingA = true;
  var _eyeLap = 0;
  var _eyeArmed = true;
  GuideGesture _gestureTarget = GuideGesture.none;
  var _lastToken = 0;
  GuideMood? _lastOverrideMood;
  String? _lastOverrideLine;

  @override
  void initState() {
    super.initState();
    _eyes = AnimationController(vsync: this, duration: const Duration(milliseconds: 4600))..repeat();
    _face = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))..value = 1;
    _gesture = AnimationController(vsync: this, duration: const Duration(milliseconds: 680));
    _settle = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..value = 1;
    _mouth = AnimationController(vsync: this, duration: const Duration(milliseconds: 1320));
    _eyes.addListener(_countLaps);
    MascotTalk.active.addListener(_onTalkChanged);
    _syncMouth();
  }

  void _onTalkChanged() {
    _syncMouth();
    if (mounted) setState(() {});
  }

  bool get _isSpeaking => MascotTalk.active.value;

  void _syncMouth({bool restart = false}) {
    if (_isSpeaking) {
      if (restart || !_mouth.isAnimating) {
        _mouth.repeat(period: const Duration(milliseconds: 1320));
      }
    } else if (_mouth.isAnimating || _mouth.value != 0) {
      _mouth
        ..stop()
        ..value = 0;
    }
  }

  void _countLaps() {
    if (_eyes.value < 0.03 && _eyeArmed) {
      _eyeArmed = false;
      _eyeLap++;
    } else if (_eyes.value > 0.2) {
      _eyeArmed = true;
    }
  }

  @override
  void dispose() {
    MascotTalk.active.removeListener(_onTalkChanged);
    _eyes.removeListener(_countLaps);
    _eyes.dispose();
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

  String? _blinkOverlay(GuideMood mood, double t, {required bool reduce, required bool speaking}) {
    if (reduce) return null;
    final blink = t > 0.05 && t < 0.11;
    final glance = _eyeLap.isOdd && t > 0.45 && t < 0.62;
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
    String line,
    GuideGesture gesture,
    int token,
    bool hasEntrance, {
    required bool reduce,
  }) {
    final targetFace = _baseFace(mood, speaking: _isSpeaking);
    _crossTo(targetFace);

    final overrideChanged = widget.overrideMood != null &&
        (widget.overrideMood != _lastOverrideMood || widget.overrideLine != _lastOverrideLine);
    if (token == _lastToken && !overrideChanged) return;
    _lastToken = token;
    _lastOverrideMood = widget.overrideMood;
    _lastOverrideLine = widget.overrideLine;

    if (hasEntrance || overrideChanged) {
      _settle.forward(from: 0);
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

  Widget _talkMouth(GuideMood mood) {
    if (mood == GuideMood.glad ||
        mood == GuideMood.celebrate ||
        mood == GuideMood.warn ||
        mood == GuideMood.fright ||
        mood == GuideMood.fallen) {
      return const SizedBox.shrink();
    }
    final close = _lipClose(_mouth.value);
    if (close < 0.08) return const SizedBox.shrink();
    final s = widget.sprite;
    const imageAspect = 597 / 888;
    final imageW = s * imageAspect;
    final left = (s - imageW) / 2;
    return Positioned(
      left: left + imageW * 0.455,
      top: s * 0.442,
      width: imageW * 0.16,
      height: s * 0.076,
      child: CustomPaint(painter: MascotLipPainter(close)),
    );
  }

  Widget _gestureWrap(double g, GuideGesture kind, Widget child) {
    if (g < 0.001 || kind == GuideGesture.none) return child;
    switch (kind) {
      case GuideGesture.handstand:
        return Transform.translate(
          offset: Offset(0, widget.sprite * 0.08 * g),
          child: Transform.rotate(angle: math.pi * g, child: child),
        );
      case GuideGesture.leanLeft:
        return Transform.translate(
          offset: Offset(-6 * g, 0),
          child: Transform.rotate(angle: -0.28 * g, child: child),
        );
      case GuideGesture.leanRight:
        return Transform.translate(
          offset: Offset(6 * g, 0),
          child: Transform.rotate(angle: 0.28 * g, child: child),
        );
      case GuideGesture.peek:
        return Transform.translate(
          offset: Offset(10 * g, -4 * g),
          child: Transform.rotate(angle: 0.12 * g, child: child),
        );
      case GuideGesture.spinHop:
        return Transform.translate(
          offset: Offset(0, -12 * math.sin(g * math.pi)),
          child: Transform.rotate(angle: math.pi * 2 * g, child: child),
        );
      case GuideGesture.none:
        return child;
    }
  }

  @override
  Widget build(BuildContext context) {
    final guide = ref.watch(guideDirectorProvider);
    final reduce = slmReduceMotion(context);
    final activeMood = widget.overrideMood ?? guide.mood;
    final activeLine = widget.overrideLine ?? guide.line;
    final activeGesture = widget.overrideMood != null ? GuideGesture.none : guide.gesture;

    _syncFromState(
      activeMood,
      activeLine,
      activeGesture,
      guide.token,
      guide.entrance != null,
      reduce: reduce,
    );

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
    final stars = widget.sprite > 120 ? 5 : 3;

    return AnimatedBuilder(
      animation: Listenable.merge([_eyes, _face, _gesture, _settle, _mouth]),
      builder: (_, _) {
        final t = reduce ? 0.0 : _eyes.value;
        final overlay = _blinkOverlay(activeMood, t, reduce: reduce, speaking: _isSpeaking);
        final faceT = Curves.easeInOutCubic.transform(_face.value.clamp(0.0, 1.0));
        final topFace = _showingA ? _faceA : _faceB;
        final botFace = _showingA ? _faceB : _faceA;
        final settle = Curves.easeOutCubic.transform(_settle.value.clamp(0.0, 1.0));
        final g = _gesture.value.clamp(0.0, 1.0);
        final nod = (_isSpeaking && !reduce) ? 1.4 * math.sin(_mouth.value * math.pi * 2) : 0.0;
        final warnShake = (warn && !reduce && _settle.value < 0.95)
            ? math.sin(_settle.value * math.pi * 5) * 4 * (1 - _settle.value)
            : 0.0;

        return Transform.translate(
          offset: Offset(warnShake, (1 - settle) * (widget.large ? 24 : 12) + nod),
          child: Transform.scale(
            scale: 0.92 + 0.08 * settle,
            alignment: widget.centered ? Alignment.bottomCenter : Alignment.bottomLeft,
            child: SizedBox(
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
                  _gestureWrap(
                    g,
                    _gestureTarget == GuideGesture.none ? activeGesture : _gestureTarget,
                    SizedBox(
                      width: widget.sprite,
                      height: widget.sprite,
                      child: Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          Opacity(
                            opacity: 1 - faceT,
                            child: _Face(asset: botFace, size: widget.sprite),
                          ),
                          Opacity(
                            opacity: faceT,
                            child: _Face(asset: topFace, size: widget.sprite),
                          ),
                          if (overlay != null)
                            Opacity(
                              opacity: 0.92,
                              child: _Face(asset: overlay, size: widget.sprite),
                            ),
                          if (_isSpeaking) _talkMouth(activeMood),
                          if (joy && !reduce)
                            for (var i = 0; i < stars; i++)
                              Positioned(
                                left: widget.sprite * 0.68 + 12 * math.cos(t * math.pi * 2 + i * 1.05),
                                top: 2 + 10 * math.sin(t * math.pi * 2 + i * 0.9),
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: widget.sprite > 120 ? 15 : 11,
                                  color: SlmColors.gold300.withValues(alpha: 0.9),
                                ),
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Face extends StatelessWidget {
  final String asset;
  final double size;

  const _Face({required this.asset, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/duty_slip/dress/$asset.webp',
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
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
