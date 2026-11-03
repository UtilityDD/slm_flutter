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

class _AiLinemanGuideState extends ConsumerState<AiLinemanGuide> with TickerProviderStateMixin {
  late final AnimationController _eyes;
  late final AnimationController _face;
  late final AnimationController _gesture;
  late final AnimationController _settle;

  String _faceA = 'coach_ready';
  String _faceB = 'coach_ready';
  var _showingA = true;
  var _eyeLap = 0;
  var _eyeArmed = true;
  GuideGesture _gestureTarget = GuideGesture.none;
  var _lastToken = 0;

  @override
  void initState() {
    super.initState();
    _eyes = AnimationController(vsync: this, duration: const Duration(milliseconds: 4800))..repeat();
    _face = AnimationController(vsync: this, duration: const Duration(milliseconds: 280))..value = 1;
    _gesture = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _settle = AnimationController(vsync: this, duration: const Duration(milliseconds: 640))..value = 1;
    _eyes.addListener(_countLaps);
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
    _eyes.removeListener(_countLaps);
    _eyes.dispose();
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

  String? _blinkOverlay(GuideMood mood, double t, {required bool reduce}) {
    if (reduce) return null;
    final blink = t > 0.05 && t < 0.11;
    final glance = _eyeLap.isOdd && t > 0.45 && t < 0.62;
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

    return AnimatedBuilder(
      animation: Listenable.merge([_eyes, _face, _gesture, _settle]),
      builder: (_, _) {
        final t = reduce ? 0.0 : _eyes.value;
        final overlay = _blinkOverlay(guide.mood, t, reduce: reduce);
        final faceT = Curves.easeInOutCubic.transform(_face.value.clamp(0.0, 1.0));
        final topFace = _showingA ? _faceA : _faceB;
        final botFace = _showingA ? _faceB : _faceA;
        final settle = Curves.easeOutCubic.transform(_settle.value.clamp(0.0, 1.0));
        final g = _gesture.value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, (1 - settle) * (widget.large ? 28 : 14)),
          child: Transform.scale(
            scale: 0.92 + 0.08 * settle,
            alignment: Alignment.bottomCenter,
            child: SizedBox(
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
                  _gestureWrap(
                    g,
                    _gestureTarget == GuideGesture.none ? guide.gesture : _gestureTarget,
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
                          if (joy && !reduce)
                            for (var i = 0; i < 3; i++)
                              Positioned(
                                left: widget.sprite * 0.68 + 10 * math.cos(t * math.pi * 2 + i),
                                top: 2 + 8 * math.sin(t * math.pi * 2 + i * 0.9),
                                child: Icon(Icons.auto_awesome, size: 11, color: SlmColors.gold300.withValues(alpha: 0.85)),
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
