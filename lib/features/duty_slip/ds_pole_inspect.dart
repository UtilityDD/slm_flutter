import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/en_digits.dart';
import '../zero_loss/zero_loss_fx.dart';
import '../zero_loss/zero_loss_ui.dart';
import 'ds_dress_up.dart';
import 'duty_slip_engine.dart';

const _pole11Done =
    'এই তো আসল লাইনম্যানের অভ্যাস! চারপাশ, গোড়া, স্টে-তার আর শব্দ দেখে তবেই মই লাগিয়েছেন।';

const _missGrass = 'গোড়ার ঘাস সরিয়ে মাটি আর মাফিংটা একবারও দেখলেন না?';
const _missStay = 'স্টে-তার আর ইনসুলেটরটা টানটান আছে কি না ছুঁয়ে দেখলেন না?';
const _missBack = 'পোলের পেছনের দিকটা ঘুরে না দেখেই মই লাগাচ্ছেন? চারপাশ ও আর্থিং তারটা দেখুন।';
const _missHammer = 'বাইরে থেকে দেখেই ভরসা করলেন? হাতুড়ি দিয়ে ঠুকে পোলের শব্দটা শুনুন।';
const _okGrass = 'গোড়ার ঘাস সরানো হয়েছে। মাফিং ঠিক আছে।';
const _okStay = 'স্টে-তার আর ইনসুলেটর টানটান। ঠিক আছে।';
const _okBack = 'পেছনের দিক দেখা হয়েছে। আর্থিং তার ঠিক আছে।';
const _okHammer = 'হাতুড়ি ঠুকে শব্দ নিরেট। ঠিক আছে।';

const _poleFront = 'assets/zero_loss/scene/pole11_front.jpg';
const _poleFrontClear = 'assets/zero_loss/scene/pole11_front_clear.jpg';
const _poleBack = 'assets/zero_loss/scene/pole11_back.jpg';
const _poleBackClear = 'assets/zero_loss/scene/pole11_back_clear.jpg';
const _poleHammer = 'assets/zero_loss/scene/pole11_hammer.jpg';
const _poleLadder = 'assets/zero_loss/scene/gear_frp_ladder.webp';

const _preDoneItems = <String>[
  'পিপিই',
  'যন্ত্রপাতি',
  'শাটডাউন',
  'ডিসচার্জ',
  'দুদিক আর্থ',
];

const _endHabitItems = <String>[
  'গোড়ার ঘাস সরিয়ে মাফিং পরীক্ষা',
  'স্টে-তার ও ইনসুলেটর যাচাই',
  'চারপাশ ঘুরে আর্থিং তার দেখা',
  'হাতুড়ি ঠুকে ‘ঠক্ ঠক্’ শব্দ পরীক্ষা',
];

enum _ShelfTool { hammer, ladder }

class DsPolePreChecklist extends StatefulWidget {
  const DsPolePreChecklist({super.key});

  @override
  State<DsPolePreChecklist> createState() => _DsPolePreChecklistState();
}

class _DsPolePreChecklistState extends State<DsPolePreChecklist> with SingleTickerProviderStateMixin {
  late final AnimationController _ticks;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _ticks = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    Future<void>.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() => _started = true);
      _ticks.forward();
    });
  }

  @override
  void dispose() {
    _ticks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ticks,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _preDoneItems.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: _TickLine(
                  label: _preDoneItems[i],
                  t: _started ? ((_ticks.value * _preDoneItems.length) - i).clamp(0.0, 1.0) : 0,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TickLine extends StatelessWidget {
  const _TickLine({required this.label, required this.t});

  final String label;
  final double t;

  @override
  Widget build(BuildContext context) {
    final ink = Color.lerp(const Color(0xFF6E5A32), const Color(0xFF1B4332), t)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CustomPaint(painter: _TickPainter(t)),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: zlText(12, weight: FontWeight.w800, color: ink).copyWith(
            shadows: const [Shadow(color: Color(0xCCFFF8E8), blurRadius: 4)],
          ),
        ),
      ],
    );
  }
}

class _TickPainter extends CustomPainter {
  const _TickPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = const Color(0xFF2F6B3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final check = Path()
      ..moveTo(size.width * 0.12, size.height * 0.52)
      ..lineTo(size.width * 0.40, size.height * 0.78)
      ..lineTo(size.width * 0.90, size.height * 0.22);
    final metric = check.computeMetrics().first;
    canvas.drawPath(metric.extractPath(0, metric.length * t), pen);
  }

  @override
  bool shouldRepaint(covariant _TickPainter old) => old.t != t;
}

class DsPoleInspect extends StatefulWidget {
  const DsPoleInspect({
    super.key,
    required this.engine,
    required this.onDone,
    required this.muted,
    required this.onSpeak,
    required this.onDelta,
  });

  final DutySlipEngine engine;
  final VoidCallback onDone;
  final bool muted;
  final Future<void> Function(String text) onSpeak;
  final void Function(int delta, Offset global) onDelta;

  @override
  State<DsPoleInspect> createState() => _DsPoleInspectState();
}

class _DsPoleInspectState extends State<DsPoleInspect> with TickerProviderStateMixin {
  late final AnimationController _flip;
  late final AnimationController _tapAnim;
  late final AnimationController _stayTwang;
  late final AnimationController _shake;

  var _backSide = false;
  var _grassCleared = false;
  final _done = <String>{}; // 'grass', 'stay', 'back', 'hammer'
  var _ladderPlaced = false;

  var _coachVisible = false;
  var _coachSay = '';
  var _coachMood = DsCoachMood.talk;
  var _speechToken = 0;

  var _finishing = false;
  var _showChecklist = false;
  var _checkedCount = 0;
  var _showThanks = false;

  @override
  void initState() {
    super.initState();
    widget.engine.beginDress();
    ZlFx.holdClock();
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.35, muted: widget.muted));
    _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _tapAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 680));
    _stayTwang = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  }

  @override
  void dispose() {
    _speechToken++;
    ZlFx.releaseClock();
    _flip.dispose();
    _tapAnim.dispose();
    _stayTwang.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _showFaultCoach(String line) {
    final token = ++_speechToken;
    setState(() {
      _coachSay = line;
      _coachMood = DsCoachMood.oops;
      _coachVisible = true;
    });
    unawaited(
      widget.onSpeak(line).whenComplete(() async {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted || token != _speechToken) return;
        setState(() => _coachVisible = false);
      }),
    );
  }

  void _clearCoachIfOpen() {
    if (!_coachVisible) return;
    _speechToken++;
    setState(() => _coachVisible = false);
  }

  void _praise(String line) {
    final token = ++_speechToken;
    setState(() {
      _coachSay = line;
      _coachMood = DsCoachMood.glad;
      _coachVisible = true;
    });
    unawaited(
      widget.onSpeak(line).whenComplete(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted || token != _speechToken) return;
        setState(() => _coachVisible = false);
      }),
    );
  }

  void _doGrass(Offset global) {
    if (_finishing) return;
    HapticFeedback.lightImpact();
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.55, muted: widget.muted));
    final first = _done.add('grass');
    setState(() => _grassCleared = true);
    if (first) {
      unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.65, muted: widget.muted));
      widget.engine.dressRight();
      widget.onDelta(5, global);
      _praise(_okGrass);
    }
  }

  void _doStay(Offset global) {
    if (_finishing) return;
    HapticFeedback.lightImpact();
    _stayTwang.forward(from: 0);
    unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.55, muted: widget.muted));
    final first = _done.add('stay');
    setState(() {});
    if (first) {
      unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.65, muted: widget.muted));
      widget.engine.dressRight();
      widget.onDelta(5, global);
      _praise(_okStay);
    }
  }

  void _doFlip(Offset global) {
    if (_finishing) return;
    HapticFeedback.selectionClick();
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.5, muted: widget.muted));
    final nextBack = !_backSide;
    setState(() => _backSide = nextBack);
    if (nextBack) {
      _flip.forward();
      if (_done.add('back')) {
        unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.65, muted: widget.muted));
        widget.engine.dressRight();
        widget.onDelta(5, global);
        _praise(_okBack);
      }
    } else {
      _flip.reverse();
    }
  }

  void _doHammer(Offset global) {
    if (_finishing) return;
    HapticFeedback.mediumImpact();
    _tapAnim.forward(from: 0);
    unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.75, muted: widget.muted));
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.85, muted: widget.muted));
    });
    final first = _done.add('hammer');
    setState(() {});
    if (first) {
      unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.7, muted: widget.muted));
      widget.engine.dressRight();
      widget.onDelta(5, global);
      _praise(_okHammer);
    }
  }

  Future<void> _tryLadder(Offset global) async {
    if (_finishing) return;

    String? missed;
    if (!_done.contains('grass')) {
      missed = _missGrass;
    } else if (!_done.contains('stay')) {
      missed = _missStay;
    } else if (!_done.contains('back')) {
      missed = _missBack;
    } else if (!_done.contains('hammer')) {
      missed = _missHammer;
    }

    if (missed != null) {
      HapticFeedback.heavyImpact();
      unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.8, muted: widget.muted));
      widget.engine.dressWrong();
      widget.onDelta(-5, global);
      _shake.forward(from: 0);
      _showFaultCoach(missed);
      return;
    }

    // All 4 habits completed! Place ladder on the pole.
    _clearCoachIfOpen();
    if (_backSide) {
      setState(() => _backSide = false);
      _flip.reverse();
    }
    setState(() {
      _finishing = true;
      _ladderPlaced = true;
    });
    HapticFeedback.mediumImpact();
    unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.82, muted: widget.muted));
    widget.engine.dressRight();
    widget.onDelta(5, global);

    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _showChecklist = true;
      _checkedCount = 0;
    });

    for (var i = 0; i < _endHabitItems.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 380));
      if (!mounted) return;
      unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.45, muted: widget.muted));
      setState(() => _checkedCount = i + 1);
    }

    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    unawaited(ZlFx.cue('sounds/quiz_complete.wav', volume: 0.85, muted: widget.muted));
    setState(() {
      _showChecklist = false;
      _showThanks = true;
    });

    await widget.onSpeak(_pole11Done).timeout(
      const Duration(seconds: 12),
      onTimeout: () {},
    );
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final dx = math.sin(_shake.value * math.pi * 6) * 8 * (1 - _shake.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Main interactive stage + clean bottom shelf
          Column(
            children: [
              Expanded(
                child: DragTarget<_ShelfTool>(
                  onWillAcceptWithDetails: (_) => !_finishing,
                  onAcceptWithDetails: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    final center = box != null
                        ? box.localToGlobal(box.size.center(Offset.zero))
                        : details.offset;
                    if (details.data == _ShelfTool.hammer) {
                      _doHammer(center);
                    } else if (details.data == _ShelfTool.ladder) {
                      _tryLadder(center);
                    }
                  },
                  builder: (context, candidates, _) {
                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragEnd: (d) {
                        final v = d.primaryVelocity ?? 0;
                        if (v.abs() > 180) {
                          final box = context.findRenderObject() as RenderBox?;
                          final pos = box != null
                              ? box.localToGlobal(box.size.center(Offset.zero))
                              : Offset.zero;
                          _doFlip(pos);
                        }
                      },
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              // Front and back photographs of the same pole.
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: Listenable.merge([_flip, _stayTwang]),
                                  builder: (context, _) {
                                    final angle = _flip.value * math.pi;
                                    final showBack = _flip.value >= 0.5;
                                    final asset = showBack
                                        ? (_grassCleared ? _poleBackClear : _poleBack)
                                        : (_grassCleared ? _poleFrontClear : _poleFront);
                                    final nudge = math.sin(_stayTwang.value * math.pi * 6) * (1 - _stayTwang.value) * 5;
                                    return Transform.translate(
                                      offset: Offset(nudge, 0),
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.001)
                                          ..rotateY(angle),
                                        child: Transform(
                                          alignment: Alignment.center,
                                          transform: showBack ? Matrix4.rotationY(math.pi) : Matrix4.identity(),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 380),
                                            child: Image.asset(
                                              asset,
                                              key: ValueKey(asset),
                                              fit: BoxFit.cover,
                                              alignment: Alignment.bottomCenter,
                                              width: w,
                                              height: h,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (_ladderPlaced)
                                Positioned(
                                  left: w * 0.30,
                                  bottom: 0,
                                  height: h * 0.76,
                                  child: IgnorePointer(
                                    child: Transform.rotate(
                                      angle: -0.14,
                                      alignment: Alignment.bottomCenter,
                                      child: Image.asset(_poleLadder, fit: BoxFit.contain),
                                    ),
                                  ),
                                ),
                              Positioned(
                                left: w * 0.54,
                                top: h * 0.48,
                                child: AnimatedBuilder(
                                  animation: _tapAnim,
                                  builder: (context, _) {
                                    final t = _tapAnim.value;
                                    if (t <= 0 || t >= 1) return const SizedBox.shrink();
                                    return IgnorePointer(
                                      child: Opacity(
                                        opacity: (1 - (t - 0.15).abs()).clamp(0.35, 1),
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xF2ECFDF5),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: const Color(0xFF22C55E)),
                                              ),
                                              child: Text(
                                                'ঠক্ ঠক্',
                                                style: zlText(13, weight: FontWeight.w900, color: const Color(0xFF14532D)),
                                              ),
                                            ),
                                            Transform.rotate(
                                              angle: -0.5 - math.sin(t * math.pi * 4) * 0.4,
                                              child: Image.asset(_poleHammer, width: 64, height: 64, fit: BoxFit.contain),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Touch zone: Base Grass (Front or Back foot of pole)
                              Positioned(
                                left: w * 0.36,
                                top: h * 0.72,
                                width: w * 0.28,
                                height: h * 0.22,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (d) => _doGrass(d.globalPosition),
                                  onPanStart: (d) => _doGrass(d.globalPosition),
                                  child: const SizedBox.expand(),
                                ),
                              ),

                              // Touch zone: Stay wire & porcelain insulator (Left side of pole)
                              if (!_backSide)
                                Positioned(
                                  left: w * 0.10,
                                  top: h * 0.26,
                                  width: w * 0.32,
                                  height: h * 0.56,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapDown: (d) => _doStay(d.globalPosition),
                                    onPanStart: (d) => _doStay(d.globalPosition),
                                    child: const SizedBox.expand(),
                                  ),
                                ),

                              // Touch zone: Back side GI earthing wire
                              if (_backSide)
                                Positioned(
                                  left: w * 0.44,
                                  top: h * 0.18,
                                  width: w * 0.22,
                                  height: h * 0.64,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapDown: (d) {
                                      HapticFeedback.selectionClick();
                                      unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.5, muted: widget.muted));
                                      if (_done.add('back')) {
                                        widget.engine.dressRight();
                                        widget.onDelta(5, d.globalPosition);
                                        unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.65, muted: widget.muted));
                                        _praise(_okBack);
                                      }
                                      setState(() {});
                                    },
                                    child: const SizedBox.expand(),
                                  ),
                                ),

                              // Standing in PPE until the ladder is up, then the climbing pose.
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                left: _ladderPlaced ? w * 0.20 : w * 0.02,
                                bottom: _ladderPlaced ? h * 0.30 : h * 0.04,
                                height: _ladderPlaced ? h * 0.48 : h * 0.42,
                                child: IgnorePointer(
                                  child: Transform.flip(
                                    flipX: !_ladderPlaced,
                                    child: Image.asset(
                                      _ladderPlaced
                                          ? 'assets/zero_loss/scene/spr_man_climb.webp'
                                          : 'assets/zero_loss/scene/spr_man_point.webp',
                                      fit: BoxFit.contain,
                                      alignment: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),

                              // Clean rotate-around icon button beside the pole (no text)
                              Positioned(
                                right: w * 0.16,
                                top: h * 0.46,
                                child: GestureDetector(
                                  onTapDown: (d) => _doFlip(d.globalPosition),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _done.contains('back')
                                          ? const Color(0xE6143824)
                                          : const Color(0xDDFFFBF0),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _done.contains('back')
                                            ? const Color(0xFF34D399)
                                            : const Color(0xFF8C6B3F),
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x33000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.threesixty_rounded,
                                      size: 26,
                                      color: _done.contains('back')
                                          ? const Color(0xFF6EE7B7)
                                          : const Color(0xFF3A2A16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // Clean bottom tool tray (pictures only, zero text labels)
              if (!_finishing)
                Container(
                  height: 108,
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xF2FDF4E3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD4B483), width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x29000000), blurRadius: 14, offset: Offset(0, 5)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 1. Hammer (Tap or Drag onto pole)
                      _TrayToolTile(
                        tool: _ShelfTool.hammer,
                        done: _done.contains('hammer'),
                        onTap: _doHammer,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(_poleHammer, fit: BoxFit.contain),
                        ),
                      ),

                      // 2. FRP Ladder (Tap or Drag onto pole when ready)
                      _TrayToolTile(
                        tool: _ShelfTool.ladder,
                        done: _ladderPlaced,
                        onTap: _tryLadder,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            _poleLadder,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 118),
            ],
          ),

          const Positioned(
            left: 14,
            top: 8,
            child: IgnorePointer(child: DsPolePreChecklist()),
          ),

          // One-by-one mistake coach (only appears when player makes a mistake)
          if (_coachVisible && !_showChecklist && !_showThanks)
            Positioned(
              left: 10,
              bottom: 122,
              child: IgnorePointer(
                child: DsCoach(
                  mood: _coachMood,
                  line: _coachSay,
                  bubbleWidth: 238,
                  sprite: 126,
                ),
              ),
            ),

          // End-of-level habit checklist (only after success)
          if (_showChecklist)
            Positioned.fill(
              child: Container(
                color: const Color(0x88101820),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF6E4),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFC9A227), width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x55000000), blurRadius: 20, offset: Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _endHabitItems.length; i++)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: i < _checkedCount ? 1.0 : 0.25,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Icon(
                                  i < _checkedCount
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 20,
                                  color: i < _checkedCount ? const Color(0xFF2F6B3A) : const Color(0xFF9C8867),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _endHabitItems[i],
                                    style: zlText(13.5, weight: FontWeight.w800, color: const Color(0xFF3A2A16)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Final thank-you coach while the pole + FRP ladder stay visible behind
          if (_showThanks)
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, -0.32),
                child: DsCoach(
                  mood: DsCoachMood.thanks,
                  line: _pole11Done,
                  bubbleWidth: 280,
                  sprite: 184,
                  centered: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrayToolTile extends StatelessWidget {
  const _TrayToolTile({
    required this.tool,
    required this.done,
    required this.onTap,
    required this.child,
  });

  final _ShelfTool tool;
  final bool done;
  final ValueChanged<Offset> onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: 96,
      height: 84,
      decoration: BoxDecoration(
        color: done ? const Color(0xFFE6F7ED) : const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: done ? const Color(0xFF34D399) : const Color(0xFFCBB282),
          width: 1.8,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x18000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          if (done)
            const Positioned(
              right: 6,
              top: 6,
              child: Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF2F6B3A)),
            ),
        ],
      ),
    );

    return GestureDetector(
      onTapDown: (d) => onTap(d.globalPosition),
      child: Draggable<_ShelfTool>(
        data: tool,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(width: 92, height: 92, child: child),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: box),
        child: box,
      ),
    );
  }
}
