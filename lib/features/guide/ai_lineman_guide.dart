import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../design/slm_design.dart';
import 'guide_director.dart';
import 'mascot_speech_library.dart';

/// Unified expressive Game Mascot ("ওস্তাদ লাইনম্যান") — engineered with a
/// 60fps Rive / Lottie-style procedural skeletal & viseme rig:
/// - Continuous multi-harmonic breathing, torso squash-and-stretch, and head tilt
/// - Syllabic body bounce, eyebrow articulation, and specular eye catchlights
/// - Multi-viseme smooth morphing lip-sync (AA, OH, EE, MBP, FV, Smile) with
///   oral cavity, upper teeth, tongue contour, and lip shading
/// - Dynamic acoustic aura rings & live equalizer speech bubble
class AiLinemanGuide extends ConsumerStatefulWidget {
  final double sprite;
  final double bubbleWidth;
  final bool showBubble;
  final double bubbleOpacity;
  final bool large;

  /// Optional explicit overrides so [DsCoach] and custom call-sites render
  /// the exact same unified rigged mascot without duplicating state.
  final GuideMood? overrideMood;
  final String? overrideLine;
  final bool centered;
  final VoidCallback? onTap;

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
    this.onTap,
  });

  @override
  ConsumerState<AiLinemanGuide> createState() => _AiLinemanGuideState();
}

/// Keyframed speech viseme target for smooth Rive-like mouth interpolation.
class _VisemePose {
  final double open; // 0 = closed, 1 = wide open (AA)
  final double width; // 0.55 = narrow (OO), 1.05 = wide (EE/Smile)
  final double round; // 0 = flat, 1 = rounded O-shape
  final double smile; // -0.3 = frown/warn, +0.4 = warm smile
  final double teeth; // 0..1 upper teeth visibility
  final double tongue; // 0..1 tongue bounce

  const _VisemePose({
    required this.open,
    required this.width,
    required this.round,
    required this.smile,
    required this.teeth,
    required this.tongue,
  });

  static const rest = _VisemePose(
    open: 0.0,
    width: 0.90,
    round: 0.10,
    smile: 0.28,
    teeth: 0.0,
    tongue: 0.0,
  );

  static _VisemePose lerp(_VisemePose a, _VisemePose b, double t) {
    final s = Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
    return _VisemePose(
      open: a.open + (b.open - a.open) * s,
      width: a.width + (b.width - a.width) * s,
      round: a.round + (b.round - a.round) * s,
      smile: a.smile + (b.smile - a.smile) * s,
      teeth: a.teeth + (b.teeth - a.teeth) * s,
      tongue: a.tongue + (b.tongue - a.tongue) * s,
    );
  }
}

class _AiLinemanGuideState extends ConsumerState<AiLinemanGuide>
    with TickerProviderStateMixin {
  /// Master rig clock (drives breathing, head drift, eye glints, aura). It
  /// loops while speaking, then finishes its lap and rests (see [_syncRig]).
  late final AnimationController _rig;

  /// Smooth crossfade between base facial expressions.
  late final AnimationController _face;

  /// Special gag/body gesture controller (lean, peek, spinHop, handstand).
  late final AnimationController _gesture;

  /// Spring entrance / cue reaction controller.
  late final AnimationController _settle;

  /// High-resolution multi-viseme lip-sync cycle controller.
  late final AnimationController _mouth;

  /// Smooth transition weight between silent rest pose (0) and active speech rig (1).
  late final AnimationController _talkBlend;
  late final AnimationController _touchPop;

  String _faceA = 'coach_ready';
  String _faceB = 'coach_ready';
  var _showingA = true;
  var _eyeLap = 0;
  var _eyeArmed = true;

  /// Eye phase while the rig rests; stepped by [_eyeTimer], not a ticker.
  var _eyeT = 0.0;
  Timer? _eyeTimer;
  var _rigLooping = false;

  /// Loops allowed: animations on and this route visible.
  var _loopsOn = true;
  GuideGesture _gestureTarget = GuideGesture.none;
  var _lastToken = 0;
  GuideMood? _lastOverrideMood;
  String? _lastOverrideLine;

  /// Natural Bangla speech cadence sequence of visemes over a 1.65s phrase loop.
  static const _visemeTrack = <(double, _VisemePose)>[
    // 0.00: Bilabial start (ম / ব / প)
    (
      0.00,
      _VisemePose(
        open: 0.04,
        width: 0.88,
        round: 0.15,
        smile: 0.22,
        teeth: 0.0,
        tongue: 0.0,
      ),
    ),
    // 0.08: Wide open vowel (আ - "ভাই" / "কাজ")
    (
      0.08,
      _VisemePose(
        open: 0.88,
        width: 1.02,
        round: 0.18,
        smile: 0.30,
        teeth: 0.85,
        tongue: 0.45,
      ),
    ),
    // 0.16: Dental / palatal (ই / এ)
    (
      0.16,
      _VisemePose(
        open: 0.42,
        width: 1.05,
        round: 0.08,
        smile: 0.36,
        teeth: 0.90,
        tongue: 0.70,
      ),
    ),
    // 0.22: Brief consonant closure (ত / দ / ন)
    (
      0.22,
      _VisemePose(
        open: 0.12,
        width: 0.92,
        round: 0.12,
        smile: 0.24,
        teeth: 0.35,
        tongue: 0.80,
      ),
    ),
    // 0.31: Rounded vowel (ও / উ - "ওস্তাদ" / "হলো")
    (
      0.31,
      _VisemePose(
        open: 0.74,
        width: 0.64,
        round: 0.92,
        smile: 0.10,
        teeth: 0.30,
        tongue: 0.35,
      ),
    ),
    // 0.40: Soft consonant dip
    (
      0.40,
      _VisemePose(
        open: 0.18,
        width: 0.86,
        round: 0.30,
        smile: 0.22,
        teeth: 0.20,
        tongue: 0.25,
      ),
    ),
    // 0.49: Energetic mid-open syllable (অ / আ)
    (
      0.49,
      _VisemePose(
        open: 0.94,
        width: 0.98,
        round: 0.24,
        smile: 0.32,
        teeth: 0.82,
        tongue: 0.62,
      ),
    ),
    // 0.58: Bilabial snap (প / ম)
    (
      0.58,
      _VisemePose(
        open: 0.03,
        width: 0.90,
        round: 0.10,
        smile: 0.25,
        teeth: 0.0,
        tongue: 0.0,
      ),
    ),
    // 0.67: Wide E/I syllable
    (
      0.67,
      _VisemePose(
        open: 0.58,
        width: 1.04,
        round: 0.10,
        smile: 0.38,
        teeth: 0.88,
        tongue: 0.55,
      ),
    ),
    // 0.76: Rounded O syllable
    (
      0.76,
      _VisemePose(
        open: 0.66,
        width: 0.68,
        round: 0.84,
        smile: 0.14,
        teeth: 0.25,
        tongue: 0.30,
      ),
    ),
    // 0.84: Consonant flutter
    (
      0.84,
      _VisemePose(
        open: 0.22,
        width: 0.92,
        round: 0.18,
        smile: 0.26,
        teeth: 0.50,
        tongue: 0.65,
      ),
    ),
    // 0.92: Final open emphasis vowel
    (
      0.92,
      _VisemePose(
        open: 0.78,
        width: 0.96,
        round: 0.22,
        smile: 0.30,
        teeth: 0.75,
        tongue: 0.50,
      ),
    ),
    // 1.00: Loop back to bilabial start
    (
      1.00,
      _VisemePose(
        open: 0.04,
        width: 0.88,
        round: 0.15,
        smile: 0.22,
        teeth: 0.0,
        tongue: 0.0,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _rig = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );
    _face = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..value = 1;
    _gesture = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 640),
    )..value = 1;
    _mouth = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    );
    _talkBlend = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: MascotTalk.active.value ? 1.0 : 0.0,
    );
    _touchPop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _rig.addListener(_countLaps);
    _rig.addStatusListener(_onRigStatus);
    MascotTalk.active.addListener(_onTalkChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loopsOn = slmLoopsOn(context) && TickerMode.valuesOf(context).enabled;
    _syncMouth();
    _syncRig();
  }

  void _onTalkChanged() {
    _syncMouth();
    _syncRig();
    if (mounted) setState(() {});
  }

  /// The rig loops only while speaking. After speech, a cue or a tap it
  /// finishes the current lap (at most one 6 s breath cycle) and rests at
  /// the neutral pose, where blinks run on a Timer, so an idle guide draws
  /// no frames. Nothing runs with remove-animations or a hidden route.
  void _syncRig({bool kick = false}) {
    if (!_loopsOn) {
      _rigLooping = false;
      _rig.stop();
      if (_rig.value != 0) _rig.value = 0;
      _stopEyes();
    } else if (_isSpeaking) {
      if (_rigLooping) return;
      _rigLooping = true;
      _stopEyes();
      _rig.repeat();
    } else if (_rigLooping || kick) {
      _rigLooping = false;
      _stopEyes();
      _rig.forward();
    } else if (!_rig.isAnimating) {
      _startEyes();
    }
  }

  void _onRigStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _rigLooping) return;
    _rig.value = 0;
    _startEyes();
  }

  void _startEyes() {
    if (_eyeTimer == null && _loopsOn) _armEye(0);
  }

  void _stopEyes() {
    _eyeTimer?.cancel();
    _eyeTimer = null;
    _eyeT = 0;
  }

  /// Steps [_eyeT] through the same blink / double-blink / glance beats as
  /// one rig lap (ms into 6 s), with one setState per beat.
  void _armEye(int ms) {
    final beats = [
      360, 630,
      if (_eyeLap % 3 == 0) ...[810, 1050],
      if (_eyeLap.isOdd) ...[2880, 3840],
      6000,
    ];
    final next = beats.firstWhere((b) => b > ms);
    _eyeTimer = Timer(Duration(milliseconds: next - ms), () {
      if (!mounted) return;
      if (next >= 6000) {
        _eyeLap++;
        _eyeT = 0;
        _armEye(0);
        return;
      }
      setState(() => _eyeT = (next + 1) / 6000);
      _armEye(next);
    });
  }

  bool get _isSpeaking => MascotTalk.active.value;

  void _syncMouth({bool restart = false}) {
    if (_isSpeaking && _loopsOn) {
      _talkBlend.forward();
      if (restart || !_mouth.isAnimating) {
        _mouth.repeat(period: const Duration(milliseconds: 1650));
      }
    } else {
      _talkBlend.reverse();
      if (_mouth.isAnimating) {
        _mouth.stop();
      }
    }
  }

  void _countLaps() {
    if (_rig.value < 0.03 && _eyeArmed) {
      _eyeArmed = false;
      _eyeLap++;
    } else if (_rig.value > 0.2) {
      _eyeArmed = true;
    }
  }

  void _onSpriteTap() {
    HapticFeedback.selectionClick();
    _touchPop.forward(from: 0);
    _syncRig(kick: true);
    widget.onTap?.call();
  }

  @override
  void dispose() {
    MascotTalk.active.removeListener(_onTalkChanged);
    _eyeTimer?.cancel();
    _rig.removeListener(_countLaps);
    _rig.removeStatusListener(_onRigStatus);
    _rig.dispose();
    _face.dispose();
    _gesture.dispose();
    _settle.dispose();
    _mouth.dispose();
    _talkBlend.dispose();
    _touchPop.dispose();
    super.dispose();
  }

  /// Base sprite selection — when speaking, we use `coach_talk` so our
  /// 60fps Rive-style mouth rig (`MascotRiveMouthPainter`) has a clean canvas.
  String _baseFace(GuideMood mood, {required bool speaking}) {
    if (speaking &&
        mood != GuideMood.warn &&
        mood != GuideMood.fright &&
        mood != GuideMood.fallen) {
      return 'coach_talk';
    }
    return switch (mood) {
      GuideMood.glad || GuideMood.celebrate => 'coach_happy',
      GuideMood.warn || GuideMood.fright || GuideMood.fallen => 'coach_oops',
      GuideMood.talk || GuideMood.inspire || GuideMood.wake =>
        speaking ? 'coach_talk' : 'coach_ready',
      GuideMood.sleep => 'coach_blink',
      GuideMood.listen || GuideMood.think || GuideMood.idle =>
        speaking ? 'coach_talk' : 'coach_ready',
    };
  }

  /// Natural blink & eye saccade overlay with occasional double-blinks.
  String? _blinkOverlay(
    GuideMood mood,
    double t, {
    required bool reduce,
    required bool speaking,
  }) {
    if (reduce || mood == GuideMood.sleep) return null;
    final primaryBlink = t > 0.06 && t < 0.105;
    final doubleBlink = _eyeLap % 3 == 0 && t > 0.135 && t < 0.175;
    final blink = primaryBlink || doubleBlink;
    final glance = _eyeLap.isOdd && t > 0.48 && t < 0.64;
    if (!blink && !glance) return null;
    return switch (mood) {
      GuideMood.warn || GuideMood.fright || GuideMood.fallen =>
        blink ? 'coach_oops_blink' : 'coach_oops_glance',
      GuideMood.glad || GuideMood.celebrate =>
        speaking ? (blink ? 'coach_talk_blink' : null) : null,
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
        (widget.overrideMood != _lastOverrideMood ||
            widget.overrideLine != _lastOverrideLine);
    if (token == _lastToken && !overrideChanged) return;
    _lastToken = token;
    _lastOverrideMood = widget.overrideMood;
    _lastOverrideLine = widget.overrideLine;
    _syncRig(kick: true);

    if (hasEntrance || overrideChanged) {
      _settle.forward(from: 0);
    }

    if (gesture != _gestureTarget) {
      _gestureTarget = gesture;
      if (reduce) {
        _gesture.value = gesture == GuideGesture.none ? 0 : 1;
      } else if (gesture == GuideGesture.none) {
        _gesture.animateTo(
          0,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _gesture.animateTo(
          1,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  /// Evaluates the interpolated viseme pose at phase `t` (`0.0..1.0`),
  /// blended smoothly with `_talkBlend` so mouth opening/closing never snaps.
  _VisemePose _currentViseme(GuideMood mood) {
    final blend = Curves.easeOutCubic.transform(_talkBlend.value.clamp(0.0, 1.0));
    if (blend < 0.01) return _VisemePose.rest;
    final t = _mouth.value.clamp(0.0, 1.0);
    _VisemePose raw = _visemeTrack.last.$2;
    for (var i = 0; i < _visemeTrack.length - 1; i++) {
      final a = _visemeTrack[i];
      final b = _visemeTrack[i + 1];
      if (t >= a.$1 && t <= b.$1) {
        final local = ((t - a.$1) / (b.$1 - a.$1)).clamp(0.0, 1.0);
        raw = _VisemePose.lerp(a.$2, b.$2, local);
        break;
      }
    }
    final moodSmileBoost = (mood == GuideMood.glad || mood == GuideMood.celebrate)
        ? 0.14
        : (mood == GuideMood.warn || mood == GuideMood.fright)
            ? -0.22
            : 0.0;
    final adjusted = _VisemePose(
      open: raw.open,
      width: raw.width,
      round: raw.round,
      smile: (raw.smile + moodSmileBoost).clamp(-0.35, 0.55),
      teeth: raw.teeth,
      tongue: raw.tongue,
    );
    return _VisemePose.lerp(_VisemePose.rest, adjusted, blend);
  }

  Widget _buildRiveMouth(GuideMood mood, _VisemePose pose) {
    if (_talkBlend.value < 0.02) return const SizedBox.shrink();
    if (mood == GuideMood.warn ||
        mood == GuideMood.fright ||
        mood == GuideMood.fallen) {
      return const SizedBox.shrink();
    }
    final s = widget.sprite;
    const imageAspect = 597 / 888;
    final imageW = s * imageAspect;
    final left = (s - imageW) / 2;
    return Positioned(
      left: left + imageW * 0.442,
      top: s * 0.436,
      width: imageW * 0.185,
      height: s * 0.086,
      child: CustomPaint(
        painter: _MascotRiveMouthPainter(
          pose: pose,
          talkBlend: _talkBlend.value,
        ),
      ),
    );
  }

  Widget _buildRiveExpressions(
    GuideMood mood,
    _VisemePose pose,
    double rigPhase,
  ) {
    final s = widget.sprite;
    const imageAspect = 597 / 888;
    final imageW = s * imageAspect;
    final left = (s - imageW) / 2;
    return Positioned(
      left: left,
      top: 0,
      width: imageW,
      height: s,
      child: IgnorePointer(
        child: CustomPaint(
          painter: _MascotRigOverlayPainter(
            mood: mood,
            syllableOpen: pose.open * _talkBlend.value,
            rigPhase: rigPhase,
          ),
        ),
      ),
    );
  }

  Widget _gestureWrap(double g, GuideGesture kind, Widget child) {
    // Same Transform pair at rest keeps the sprite subtree mounted.
    if (g < 0.001 || kind == GuideGesture.none) {
      return Transform.translate(
        offset: Offset.zero,
        child: Transform.rotate(angle: 0, child: child),
      );
    }
    switch (kind) {
      case GuideGesture.handstand:
        return Transform.translate(
          offset: Offset(0, widget.sprite * 0.08 * g),
          child: Transform.rotate(angle: math.pi * g, child: child),
        );
      case GuideGesture.leanLeft:
        return Transform.translate(
          offset: Offset(-6 * g, 0),
          child: Transform.rotate(angle: -0.22 * g, child: child),
        );
      case GuideGesture.leanRight:
        return Transform.translate(
          offset: Offset(6 * g, 0),
          child: Transform.rotate(angle: 0.22 * g, child: child),
        );
      case GuideGesture.peek:
        return Transform.translate(
          offset: Offset(8 * g, -4 * g),
          child: Transform.rotate(angle: 0.11 * g, child: child),
        );
      case GuideGesture.spinHop:
        return Transform.translate(
          offset: Offset(0, -12 * math.sin(g * math.pi)),
          child: Transform.rotate(angle: math.pi * 2 * g, child: child),
        );
      case GuideGesture.none:
        return Transform.translate(
          offset: Offset.zero,
          child: Transform.rotate(angle: 0, child: child),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final guide = ref.watch(guideDirectorProvider);
    final reduce = slmReduceMotion(context);
    final activeMood = widget.overrideMood ?? guide.mood;
    final activeLine = widget.overrideLine ?? guide.line;
    final activeGesture =
        widget.overrideMood != null ? GuideGesture.none : guide.gesture;

    _syncFromState(
      activeMood,
      activeLine,
      activeGesture,
      guide.token,
      guide.entrance != null,
      reduce: reduce,
    );

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

    final warn = activeMood == GuideMood.warn ||
        activeMood == GuideMood.fright ||
        activeMood == GuideMood.fallen;
    final joy =
        activeMood == GuideMood.glad || activeMood == GuideMood.celebrate;
    final sleep = activeMood == GuideMood.sleep;
    final stars = widget.sprite > 110 ? 5 : 3;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _rig,
        _face,
        _gesture,
        _settle,
        _mouth,
        _talkBlend,
        _touchPop,
      ]),
      builder: (_, _) {
        final rigT = reduce ? 0.0 : _rig.value;
        final tau = rigT * math.pi * 2;
        final overlay = _blinkOverlay(
          activeMood,
          _rig.isAnimating ? rigT : _eyeT,
          reduce: reduce,
          speaking: _isSpeaking,
        );
        final faceT = Curves.easeInOutCubic.transform(_face.value.clamp(0.0, 1.0));
        final topFace = _showingA ? _faceA : _faceB;
        final botFace = _showingA ? _faceB : _faceA;

        // Spring-like settle curve for entrance/reaction pops
        final settleRaw = _settle.value.clamp(0.0, 1.0);
        final settle = Curves.easeOutBack.transform(settleRaw);
        final g = _gesture.value.clamp(0.0, 1.0);

        // Viseme & syllable energy
        final viseme = _currentViseme(activeMood);
        final talkW = _talkBlend.value.clamp(0.0, 1.0);
        final syllableEnergy = viseme.open * talkW;

        // Continuous 60fps Rive-like body physics:
        // 1. Multi-harmonic breathing (slow deep breath + secondary chest harmonic)
        final breathWave = reduce
            ? 0.0
            : (math.sin(tau * 2.0) * 0.7 + math.sin(tau * 4.0 + 0.6) * 0.3);
        // 2. Idle figure-8 sway + talking syllabic bounce
        final swayX = reduce
            ? 0.0
            : math.sin(tau * 1.0) * 1.4 +
                math.cos(_mouth.value * math.pi * 4) * 1.2 * talkW;
        final floatY = reduce
            ? 0.0
            : -breathWave.abs() * 1.8 - syllableEnergy * 3.4;
        // 3. Articulated head/torso tilt (rotates smoothly with breath & speech emphasis)
        final tiltAngle = reduce
            ? 0.0
            : math.sin(tau * 1.0 + 0.4) * 0.026 +
                math.sin(_mouth.value * math.pi * 2) * 0.048 * talkW +
                (joy ? math.sin(tau * 3) * 0.032 : 0.0);
        // 4. Squash-and-stretch (preserved volume: when stretching Y, slightly compress X)
        final stretchY = reduce
            ? 1.0
            : 1.0 +
                0.016 * breathWave +
                0.034 * syllableEnergy +
                (1.0 - settleRaw) * 0.06;
        final squashX = reduce
            ? 1.0
            : 1.0 -
                0.010 * breathWave -
                0.018 * syllableEnergy -
                (1.0 - settleRaw) * 0.04;

        final warnShake = (warn && !reduce && settleRaw < 0.95)
            ? math.sin(settleRaw * math.pi * 6) * 4.5 * (1 - settleRaw)
            : 0.0;

        return Transform.translate(
          offset: Offset(
            warnShake + swayX * 0.4,
            (1 - settle.clamp(0.0, 1.2)) * (widget.large ? 22 : 10),
          ),
          child: SizedBox(
            width: widget.bubbleWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: widget.centered
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.end,
              children: [
                if (widget.showBubble &&
                    activeLine.isNotEmpty &&
                    widget.bubbleOpacity > 0.02) ...[
                  Opacity(
                    opacity: widget.bubbleOpacity.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        (1 - widget.bubbleOpacity.clamp(0.0, 1.0)) * 8,
                      ),
                      child: _GuideBubble(
                        key: ValueKey(activeLine),
                        line: enDigits(activeLine),
                        warn: warn,
                        joy: joy,
                        speaking: _isSpeaking,
                        syllableEnergy: syllableEnergy,
                        rigPhase: rigT,
                        maxWidth: widget.bubbleWidth,
                        tailRight: !widget.centered,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Transform.scale(
                  scale: 1.0 + 0.22 * math.sin(_touchPop.value * math.pi),
                  alignment: widget.centered ? Alignment.bottomCenter : Alignment.bottomRight,
                  child: InkResponse(
                    onTap: widget.onTap != null ? _onSpriteTap : null,
                    customBorder: const CircleBorder(),
                    splashColor: SlmColors.gold300.withValues(alpha: 0.35),
                    highlightColor: SlmColors.gold300.withValues(alpha: 0.15),
                    radius: widget.sprite * 0.52,
                    child: _gestureWrap(
                      g,
                      _gestureTarget == GuideGesture.none
                          ? activeGesture
                          : _gestureTarget,
                      RepaintBoundary(
                      child: SizedBox(
                        width: widget.sprite,
                        height: widget.sprite,
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        // 1. Rive-style glowing aura & acoustic voice ripples behind character
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MascotAuraPainter(
                              mood: activeMood,
                              rigPhase: rigT,
                              talkEnergy: syllableEnergy,
                              talkBlend: talkW,
                            ),
                          ),
                        ),
                        // 2. Articulated character body with squash-stretch, tilt & float
                        Transform.translate(
                          offset: Offset(swayX, floatY),
                          child: Transform.rotate(
                            angle: tiltAngle,
                            alignment: const Alignment(0, 0.72),
                            child: Transform(
                              alignment: Alignment.bottomCenter,
                              transform: Matrix4.diagonal3Values(
                                squashX * (0.92 + 0.08 * settle.clamp(0.0, 1.08)),
                                stretchY * (0.92 + 0.08 * settle.clamp(0.0, 1.08)),
                                1.0,
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                clipBehavior: Clip.none,
                                children: [
                                  Opacity(
                                    opacity: (1 - faceT).clamp(0.0, 1.0),
                                    child: _Face(
                                      asset: botFace,
                                      size: widget.sprite,
                                    ),
                                  ),
                                  Opacity(
                                    opacity: faceT.clamp(0.0, 1.0),
                                    child: _Face(
                                      asset: topFace,
                                      size: widget.sprite,
                                    ),
                                  ),
                                  if (overlay != null)
                                    Opacity(
                                      opacity: 0.94,
                                      child: _Face(
                                        asset: overlay,
                                        size: widget.sprite,
                                      ),
                                    ),
                                  // 3. Multi-viseme fluid lip-sync mouth rig
                                  _buildRiveMouth(activeMood, viseme),
                                  // 4. Expressive eyebrows, eye glints & helmet sheen
                                  if (!reduce)
                                    _buildRiveExpressions(
                                      activeMood,
                                      viseme,
                                      rigT,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // 5. Orbiting celebration sparkles
                        if (joy && !reduce)
                          for (var i = 0; i < stars; i++)
                            Positioned(
                              left: widget.sprite * 0.5 +
                                  (widget.sprite * 0.44) *
                                      math.cos(tau * 1.5 + i * (math.pi * 2 / stars)) -
                                  7,
                              top: widget.sprite * 0.28 +
                                  (widget.sprite * 0.22) *
                                      math.sin(tau * 1.5 + i * (math.pi * 2 / stars)),
                              child: Transform.scale(
                                scale: 0.75 +
                                    0.35 *
                                        math.sin(tau * 3 + i * 1.3).abs(),
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: widget.sprite > 110 ? 15 : 11,
                                  color: SlmColors.gold300.withValues(alpha: 0.92),
                                ),
                              ),
                            ),
                        // 6. Floating Zzz sleep particles
                        if (sleep && !reduce)
                          for (var i = 0; i < 2; i++)
                            Positioned(
                              right: 4 + i * 8.0,
                              top: 8 - ((rigT * 2 + i * 0.5) % 1.0) * 16,
                              child: Opacity(
                                opacity: (1.0 - ((rigT * 2 + i * 0.5) % 1.0))
                                    .clamp(0.0, 0.85),
                                child: Text(
                                  i == 0 ? 'z' : 'Z',
                                  style: TextStyle(
                                    color: SlmColors.gold200,
                                    fontWeight: FontWeight.w900,
                                    fontSize: i == 0 ? 11 : 14,
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  ),
                ),
              ),
            ),
          ],
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

  /// Tallest face export; never decode above the source.
  static const _maxPx = 900;

  @override
  Widget build(BuildContext context) {
    // Faces are taller than wide, so BoxFit.contain shows them [size] tall:
    // decode at that height x DPR instead of the full ~900 px source.
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round().clamp(1, _maxPx);
    return Image.asset(
      'assets/duty_slip/dress/$asset.webp',
      width: size,
      height: size,
      cacheHeight: px,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => Icon(
        Icons.engineering_rounded,
        size: size * 0.7,
        color: SlmColors.gold300,
      ),
    );
  }
}

/// Rive-style circular rim-light pedestal and acoustic voice wave rings behind the Mascot.
class _MascotAuraPainter extends CustomPainter {
  final GuideMood mood;
  final double rigPhase;
  final double talkEnergy;
  final double talkBlend;

  const _MascotAuraPainter({
    required this.mood,
    required this.rigPhase,
    required this.talkEnergy,
    required this.talkBlend,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.54);
    final baseR = size.shortestSide * 0.40;
    final warn = mood == GuideMood.warn ||
        mood == GuideMood.fright ||
        mood == GuideMood.fallen;
    final joy = mood == GuideMood.glad || mood == GuideMood.celebrate;

    final primaryColor = warn
        ? SlmColors.danger
        : joy
            ? SlmColors.emerald400
            : SlmColors.gold400;

    // Soft ambient radial glow behind head & shoulders
    final pulse = 0.5 + 0.5 * math.sin(rigPhase * math.pi * 4);
    final glowRadius = baseR * (1.05 + 0.08 * pulse + 0.14 * talkEnergy);
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            primaryColor.withValues(alpha: 0.28 + 0.18 * talkEnergy),
            primaryColor.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: glowRadius)),
    );

    // Acoustic voice ripple rings when speaking
    if (talkBlend > 0.05) {
      for (var i = 0; i < 2; i++) {
        final waveP = ((rigPhase * 3.0) + i * 0.5) % 1.0;
        final r = baseR * (0.88 + 0.42 * waveP);
        final alpha = (1.0 - waveP) * 0.38 * talkBlend * (0.5 + 0.5 * talkEnergy);
        canvas.drawCircle(
          center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = primaryColor.withValues(alpha: alpha.clamp(0.0, 1.0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MascotAuraPainter old) =>
      old.mood != mood ||
      old.rigPhase != rigPhase ||
      old.talkEnergy != talkEnergy ||
      old.talkBlend != talkBlend;
}

/// Rive-style procedural overlay for expressive eyebrows, eye catchlights,
/// and safety-helmet rim sheen.
class _MascotRigOverlayPainter extends CustomPainter {
  final GuideMood mood;
  final double syllableOpen;
  final double rigPhase;

  const _MascotRigOverlayPainter({
    required this.mood,
    required this.syllableOpen,
    required this.rigPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w < 16 || h < 16) return;

    // 1. Safety Helmet Specular Rim Sheen (sweeps smoothly across the yellow helmet dome)
    final sheenPhase = (rigPhase * 1.5) % 1.0;
    final sheenX = w * (0.28 + 0.44 * math.sin(sheenPhase * math.pi));
    final sheenRect = Rect.fromCenter(
      center: Offset(sheenX, h * 0.20),
      width: w * 0.22,
      height: h * 0.055,
    );
    canvas.save();
    canvas.translate(sheenRect.center.dx, sheenRect.center.dy);
    canvas.rotate(-0.18);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: sheenRect.width,
        height: sheenRect.height,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.restore();

    if (mood == GuideMood.sleep) return;

    // 2. Animated Eye Specular Catchlights (gives living Rive/Lottie sparkle to the eyes)
    final driftX = math.sin(rigPhase * math.pi * 2) * (w * 0.006);
    final driftY = -syllableOpen * (h * 0.004);
    final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.88);
    final rGlint = math.max(1.0, w * 0.016);
    // Left & right eye highlight positions in normalized sprite space
    final leftEye = Offset(w * 0.435 + driftX, h * 0.356 + driftY);
    final rightEye = Offset(w * 0.625 + driftX, h * 0.356 + driftY);
    canvas.drawCircle(leftEye, rGlint, glintPaint);
    canvas.drawCircle(rightEye, rGlint, glintPaint);

    // 3. Expressive Eyebrow Articulation (lifts with speech syllables & mood)
    final browLift = (mood == GuideMood.glad || mood == GuideMood.celebrate)
        ? -h * 0.012
        : (mood == GuideMood.warn || mood == GuideMood.fright)
            ? h * 0.005
            : -syllableOpen * (h * 0.011);
    final browPaint = Paint()
      ..color = const Color(0xFF1F140E).withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.3, w * 0.026)
      ..strokeCap = StrokeCap.round;

    final browY = h * 0.318 + browLift;
    final tilt = (mood == GuideMood.warn || mood == GuideMood.fright)
        ? h * 0.008
        : 0.0;

    final leftBrow = Path()
      ..moveTo(w * 0.37, browY + h * 0.006 - tilt)
      ..quadraticBezierTo(
        w * 0.43,
        browY - h * 0.010,
        w * 0.48,
        browY + h * 0.004 + tilt,
      );
    final rightBrow = Path()
      ..moveTo(w * 0.57, browY + h * 0.004 + tilt)
      ..quadraticBezierTo(
        w * 0.63,
        browY - h * 0.010,
        w * 0.69,
        browY + h * 0.006 - tilt,
      );
    canvas.drawPath(leftBrow, browPaint);
    canvas.drawPath(rightBrow, browPaint);

    // 4. Grounded Contact Shadow (gives grounded weight and removes rigid floating)
    final shadowPulse = 0.5 + 0.5 * math.sin(rigPhase * math.pi * 2);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.94),
        width: w * (0.62 + 0.08 * shadowPulse),
        height: h * 0.08,
      ),
      Paint()
        ..color = const Color(0x66050A16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
  }

  @override
  bool shouldRepaint(covariant _MascotRigOverlayPainter old) =>
      old.mood != mood ||
      old.syllableOpen != syllableOpen ||
      old.rigPhase != rigPhase;
}

/// Multi-viseme 60fps mouth rig painter that morphs between closed smile,
/// bilabial press, dental grin, rounded 'O', and wide 'AA' with oral cavity,
/// upper teeth, animated tongue, and natural lip contours.
class _MascotRiveMouthPainter extends CustomPainter {
  final _VisemePose pose;
  final double talkBlend;

  const _MascotRiveMouthPainter({
    required this.pose,
    required this.talkBlend,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w < 2 || h < 2 || talkBlend < 0.02) return;

    canvas.save();
    // 1. Clean skin-tone base plate over the underlying static sprite mouth
    // so we can draw any viseme shape (narrow 'O', closed 'M', wide 'AA') cleanly.
    final baseRect = Rect.fromLTWH(0, h * 0.02, w, h * 0.96);
    final skinBase = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFC97F4F),
          Color(0xFFC27646),
          Color(0xFFB86C3D),
        ],
      ).createShader(baseRect);
    canvas.drawOval(baseRect, skinBase);

    final cx = w * 0.50;
    final cy = h * 0.46;
    final open = pose.open.clamp(0.0, 1.0);
    final widthFactor = pose.width.clamp(0.55, 1.08);
    final round = pose.round.clamp(0.0, 1.0);
    final smile = pose.smile.clamp(-0.35, 0.55);

    final halfW = (w * 0.42) * widthFactor * (1.0 - 0.22 * round);
    final halfH = (h * 0.06) + (h * 0.36) * open * (1.0 + 0.12 * round);
    final cornerLift = -smile * h * 0.16;

    // 2. If mouth is nearly closed (Bilabial M/B/P or brief pause), draw a warm curved lip line
    if (open < 0.09) {
      final lipLine = Path()
        ..moveTo(cx - halfW, cy + cornerLift)
        ..quadraticBezierTo(cx, cy + h * 0.12, cx + halfW, cy + cornerLift);
      canvas.drawPath(
        lipLine,
        Paint()
          ..color = const Color(0xFF3A1F16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.4, w * 0.065)
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
      return;
    }

    // 3. Build smooth upper & lower lip bezier contour for the active viseme
    final leftCorner = Offset(cx - halfW, cy + cornerLift);
    final rightCorner = Offset(cx + halfW, cy + cornerLift);
    final topCtrlY = cy - halfH * (0.85 + 0.25 * round);
    final botCtrlY = cy + halfH * (1.15 + 0.25 * round);

    final mouthPath = Path()
      ..moveTo(leftCorner.dx, leftCorner.dy)
      ..cubicTo(
        cx - halfW * 0.55,
        topCtrlY,
        cx + halfW * 0.55,
        topCtrlY,
        rightCorner.dx,
        rightCorner.dy,
      )
      ..cubicTo(
        cx + halfW * 0.60,
        botCtrlY,
        cx - halfW * 0.60,
        botCtrlY,
        leftCorner.dx,
        leftCorner.dy,
      )
      ..close();

    // 4. Oral cavity interior
    canvas.save();
    canvas.clipPath(mouthPath);
    canvas.drawPath(
      mouthPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFF2B0E0E),
            Color(0xFF4A151B),
          ],
        ).createShader(mouthPath.getBounds()),
    );

    // 5. Animated tongue contour at bottom of oral cavity
    if (open > 0.22) {
      final tongueTop = cy + halfH * (0.28 - 0.22 * pose.tongue);
      final tongueRect = Rect.fromCenter(
        center: Offset(cx, tongueTop + halfH * 0.55),
        width: halfW * 1.35,
        height: halfH * 1.1,
      );
      canvas.drawOval(
        tongueRect,
        Paint()..color = const Color(0xFFD95B66),
      );
    }

    // 6. Crisp white upper teeth bar
    if (pose.teeth > 0.12 && open > 0.16) {
      final teethH = halfH * 0.42 * pose.teeth;
      final teethRect = RRect.fromRectAndCorners(
        Rect.fromLTRB(
          cx - halfW * 0.78,
          cy - halfH * 0.85,
          cx + halfW * 0.78,
          cy - halfH * 0.85 + teethH,
        ),
        bottomLeft: const Radius.circular(2.5),
        bottomRight: const Radius.circular(2.5),
      );
      canvas.drawRRect(
        teethRect,
        Paint()..color = const Color(0xFFFDF8EE),
      );
    }
    canvas.restore();

    // 7. Outer lip border definition
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = const Color(0xFF3E1F16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.1, w * 0.048)
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MascotRiveMouthPainter old) =>
      old.pose.open != pose.open ||
      old.pose.width != pose.width ||
      old.pose.round != pose.round ||
      old.pose.smile != pose.smile ||
      old.talkBlend != talkBlend;
}

/// Legacy compatibility alias so any external caller referencing [MascotLipPainter]
/// gets the smooth Rive-style mouth rendering automatically.
class MascotLipPainter extends CustomPainter {
  const MascotLipPainter(this.close);

  final double close;

  @override
  void paint(Canvas canvas, Size size) {
    final open = (1.0 - close.clamp(0.0, 1.0)).clamp(0.0, 1.0);
    _MascotRiveMouthPainter(
      pose: _VisemePose(
        open: open,
        width: 0.92,
        round: 0.25,
        smile: 0.26,
        teeth: open * 0.8,
        tongue: open * 0.5,
      ),
      talkBlend: 1.0,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(MascotLipPainter old) => old.close != close;
}

class _GuideBubble extends StatelessWidget {
  final String line;
  final bool warn;
  final bool joy;
  final bool speaking;
  final double syllableEnergy;
  final double rigPhase;
  final double maxWidth;
  final bool tailRight;

  const _GuideBubble({
    super.key,
    required this.line,
    required this.warn,
    required this.joy,
    required this.speaking,
    required this.syllableEnergy,
    required this.rigPhase,
    required this.maxWidth,
    this.tailRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = warn
        ? SlmColors.danger.withValues(alpha: 0.82)
        : joy
            ? SlmColors.emerald400.withValues(alpha: 0.82)
            : SlmColors.gold400.withValues(alpha: 0.68);
    final accentColor = warn
        ? SlmColors.danger
        : joy
            ? SlmColors.emerald300
            : SlmColors.gold300;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            tailRight ? CrossAxisAlignment.end : CrossAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: warn
                    ? [
                        const Color(0xF5321217),
                        SlmColors.navy900.withValues(alpha: 0.97),
                      ]
                    : [
                        SlmColors.navy850.withValues(alpha: 0.97),
                        SlmColors.navy950.withValues(alpha: 0.97),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: speaking ? 1.55 : 1.25,
              ),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x77000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
                if (speaking)
                  BoxShadow(
                    color: accentColor.withValues(
                      alpha: 0.16 + 0.18 * syllableEnergy,
                    ),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (speaking) ...[
                    _VoiceEqualizerBars(
                      energy: syllableEnergy,
                      phase: rigPhase,
                      color: accentColor,
                    ),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
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
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: tailRight ? 28 : 0),
            child: CustomPaint(
              size: const Size(14, 6),
              painter: _BubbleTailPainter(color: borderColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceEqualizerBars extends StatelessWidget {
  final double energy;
  final double phase;
  final Color color;

  const _VoiceEqualizerBars({
    required this.energy,
    required this.phase,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(3, (i) {
          final wave =
              0.35 + 0.65 * math.sin(phase * math.pi * 8 + i * 1.4).abs();
          final h = (4.0 + 10.0 * wave * (0.45 + 0.55 * energy)).clamp(3.5, 14.0);
          return Container(
            width: 2.6,
            height: h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;

  const _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) => old.color != color;
}
