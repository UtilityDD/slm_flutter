import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../zero_loss/zero_loss_fx.dart';
import 'ds_dress_up.dart';
import 'ds_pole_inspect.dart';
import 'duty_slip_engine.dart';

const _okCrowd = 'ভিড় সরিয়ে কোন ও ফিতে দিয়ে সেফ জোন ঘেরা হয়েছে। ঠিক আছে।';
const _okGround = 'পোলের গোড়া থেকে ভেজা জঞ্জাল ও লোহার পাইপ সরানো হয়েছে। ঠিক আছে।';
const _okClearance = 'বারান্দা ও পাশের লাইভ লাইন থেকে নিরাপদ দূরত্ব দেখে নেওয়া হয়েছে। ঠিক আছে।';
const _missPipe =
    'লম্বা লোহার পাইপ হাতে নিচ্ছেন কেন? ওভারহেড লাইনের লক্ষ্মণ রেখায় ঢুকে গেলে ছোঁয়ার আগেই আর্ক ফ্ল্যাশ হবে!';
const _missCrowd = 'চারপাশে লোকজন দাঁড়িয়ে আছে! আগে কোন-ফিতে দিয়ে কাজের জায়গা ঘিরে দিন।';
const _missGround = 'পোলের নিচে লোহার পাইপ আর ভেজা জঞ্জাল পড়ে আছে। আগে জায়গাটা পরিষ্কার করুন।';
const _missClearance = 'পাশের লাইন থেকে নিরাপদ দূরত্বটা একবারও মেপে দেখলেন না?';
const _doneLine = 'এই তো নিয়ম! ভিড় সরিয়ে, নিচের জায়গা পরিষ্কার করে আর লক্ষ্মণ রেখা মেনে কাজ শুরু করেছেন।';

const _endItems = <String>[
  'ভিড় সরিয়ে কোন-ফিতে',
  'গোড়া থেকে পাইপ ও ভেজা জায়গা',
  'বারান্দার লক্ষ্মণ রেখা',
];

const _open = 'assets/zero_loss/scene/pole14_open.jpg';
const _crowd = 'assets/zero_loss/scene/pole14_crowd.jpg';
const _ground = 'assets/zero_loss/scene/pole14_ground.jpg';
const _ready = 'assets/zero_loss/scene/pole14_ready.jpg';
const _cones = 'assets/zero_loss/scene/pole14_cones.jpg';
const _mat = 'assets/zero_loss/scene/pole14_mat.jpg';
const _pipe = 'assets/zero_loss/scene/pole14_pipe.jpg';
const _ladder = 'assets/zero_loss/scene/gear_frp_ladder.webp';

/// Level 14. The player already knows the lesson. The scene shows the crowd,
/// the wet patch, and the steel pipe. Nothing is labeled.
class DsClearance extends StatefulWidget {
  const DsClearance({
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
  State<DsClearance> createState() => _DsClearanceState();
}

class _DsClearanceState extends State<DsClearance> with TickerProviderStateMixin {
  final _done = <String>{};
  var _ladderPlaced = false;
  var _finishing = false;
  var _showChecklist = false;
  var _checkedCount = 0;
  var _checklistReady = false;
  var _showThanks = false;
  Completer<void>? _nextGate;
  var _coachVisible = false;
  var _coachSay = '';
  var _coachMood = DsCoachMood.talk;
  var _speechToken = 0;

  late final AnimationController _shake;

  String get _shot {
    final crowd = _done.contains('crowd');
    final ground = _done.contains('ground');
    if (crowd && ground) return _ready;
    if (crowd) return _crowd;
    if (ground) return _ground;
    return _open;
  }

  @override
  void initState() {
    super.initState();
    widget.engine.beginDress();
    ZlFx.holdClock();
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.35, muted: widget.muted));
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  }

  @override
  void dispose() {
    _speechToken++;
    ZlFx.releaseClock();
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

  void _fault(String line, Offset global) {
    HapticFeedback.heavyImpact();
    unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.8, muted: widget.muted));
    widget.engine.dressWrong();
    widget.onDelta(-5, global);
    _shake.forward(from: 0);
    _showFaultCoach(line);
  }

  void _grant(String id, String line, Offset global) {
    if (_finishing) return;
    HapticFeedback.lightImpact();
    if (!_done.add(id)) return;
    setState(() {});
    unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.65, muted: widget.muted));
    widget.engine.dressRight();
    widget.onDelta(5, global);
    _praise(line);
  }

  Offset _land(Offset raw) {
    if (raw.dx > 8 || raw.dy > 8) return raw;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return const Offset(180, 360);
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  String? _firstMiss() {
    if (!_done.contains('crowd')) return _missCrowd;
    if (!_done.contains('ground')) return _missGround;
    if (!_done.contains('clearance')) return _missClearance;
    return null;
  }

  Future<void> _tryLadder(Offset global) async {
    if (_finishing) return;
    final missed = _firstMiss();
    if (missed != null) {
      _fault(missed, global);
      return;
    }
    _speechToken++;
    setState(() {
      _finishing = true;
      _ladderPlaced = true;
      _coachVisible = false;
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
    for (var i = 0; i < _endItems.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 520));
      if (!mounted) return;
      unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.45, muted: widget.muted));
      setState(() => _checkedCount = i + 1);
    }
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    final gate = Completer<void>();
    _nextGate = gate;
    unawaited(ZlFx.cue('sounds/quiz_complete.wav', volume: 0.55, muted: widget.muted));
    setState(() => _checklistReady = true);
    await gate.future;
    if (!mounted) return;
    setState(() {
      _showChecklist = false;
      _checklistReady = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!mounted) return;
    setState(() {
      _showThanks = true;
    });
    await widget.onSpeak(_doneLine).timeout(const Duration(seconds: 12), onTimeout: () {});
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = (t <= 0 || t >= 1) ? 0.0 : (8 * (0.5 - (t * 4 % 1))).clamp(-6.0, 6.0);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Expanded(
                child: _showChecklist
                    ? Padding(
                        padding: EdgeInsets.only(top: dsBadgeInset(context)),
                        child: DsHabitChecklist(
                        items: _endItems,
                        shown: _checkedCount,
                        showNext: _checklistReady,
                        onNext: () {
                          final gate = _nextGate;
                          if (gate != null && !gate.isCompleted) gate.complete();
                        },
                      ),
                      )
                    : LayoutBuilder(
                        builder: (context, box) {
                          final w = box.maxWidth;
                          final h = box.maxHeight;
                          return DragTarget<String>(
                            onWillAcceptWithDetails: (d) => d.data == 'ladder' || d.data == 'pipe',
                            onAcceptWithDetails: (d) {
                              if (d.data == 'pipe') {
                                _fault(_missPipe, _land(d.offset));
                              } else {
                                _tryLadder(_land(d.offset));
                              }
                            },
                            builder: (context, _, _) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 420),
                                    child: Image.asset(
                                      _shot,
                                      key: ValueKey(_shot),
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      width: w,
                                      height: h,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: h * 0.08,
                                    width: w * 0.46,
                                    height: h * 0.34,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTapDown: (d) => _grant('clearance', _okClearance, d.globalPosition),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    bottom: h * 0.16,
                                    width: w * 0.50,
                                    height: h * 0.30,
                                    child: DragTarget<String>(
                                      onWillAcceptWithDetails: (d) => d.data == 'cones',
                                      onAcceptWithDetails: (d) => _grant('crowd', _okCrowd, _land(d.offset)),
                                      builder: (_, _, _) => const SizedBox.expand(),
                                    ),
                                  ),
                                  Positioned(
                                    left: w * 0.28,
                                    bottom: h * 0.04,
                                    width: w * 0.42,
                                    height: h * 0.24,
                                    child: DragTarget<String>(
                                      onWillAcceptWithDetails: (d) => d.data == 'mat',
                                      onAcceptWithDetails: (d) => _grant('ground', _okGround, _land(d.offset)),
                                      builder: (_, _, _) => const SizedBox.expand(),
                                    ),
                                  ),
                                  if (_ladderPlaced)
                                    Positioned(
                                      left: w * 0.28,
                                      bottom: 0,
                                      height: h * 0.72,
                                      child: IgnorePointer(
                                        child: Transform.rotate(
                                          angle: -0.12,
                                          alignment: Alignment.bottomCenter,
                                          child: Image.asset(_ladder, fit: BoxFit.contain),
                                        ),
                                      ),
                                    ),
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 700),
                                    curve: Curves.easeOutCubic,
                                    left: _ladderPlaced ? w * 0.18 : w * 0.02,
                                    bottom: _ladderPlaced ? h * 0.28 : h * 0.02,
                                    height: _ladderPlaced ? h * 0.46 : h * 0.40,
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
                                ],
                              );
                            },
                          );
                        },
                      ),
              ),
              if (!_finishing)
                DsFlatShelf(
                  children: [
                    if (!_done.contains('crowd')) DsShelfToken<String>(data: 'cones', asset: _cones),
                    if (!_done.contains('ground')) DsShelfToken<String>(data: 'mat', asset: _mat),
                    if (!_ladderPlaced) DsShelfToken<String>(data: 'ladder', asset: _ladder),
                    DsShelfToken<String>(data: 'pipe', asset: _pipe),
                  ],
                ),
            ],
          ),
          if (!_showChecklist && !_showThanks)
            Positioned(
              left: 14,
              top: dsBadgeInset(context),
              child: const IgnorePointer(child: DsPolePreChecklist()),
            ),
          if (_coachVisible && !_showChecklist && !_showThanks)
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: const Alignment(0, -0.08),
                  child: DsCoach(
                    mood: _coachMood,
                    line: _coachSay,
                    bubbleWidth: 280,
                    sprite: 156,
                    centered: true,
                  ),
                ),
              ),
            ),
          if (_showThanks)
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, -0.42),
                child: DsCoach(
                  mood: DsCoachMood.thanks,
                  line: _doneLine,
                  bubbleWidth: 280,
                  sprite: 188,
                  centered: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
