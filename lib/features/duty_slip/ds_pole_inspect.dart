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

const _okGrass12 = 'গোড়ার ঘাস সরানো হয়েছে। ফাউন্ডেশনে চুলের মতো ফাটল দেখা যাচ্ছে। ঠিক আছে।';
const _okStay12 = 'স্টে-তার দেখা হয়েছে। ঠিক আছে।';
const _okBack12 = 'পেছনের দিক দেখা হয়েছে। কংক্রিট খসে ভেতরের রড বেরিয়ে আছে! ঠিক আছে।';
const _okHammer12 = 'হাতুড়ি ঠুকে ফাঁপা দপ্ দপ্ শব্দ মিলেছে। ভেতরটা দুর্বল, ধরা পড়েছে। ঠিক আছে।';
const _repGrass = 'গোড়ার ঘাস সরিয়ে ফাটলটা না দেখে রিপোর্ট করবেন না।';
const _repStay = 'স্টে-তার দেখে নিন, তারপর রিপোর্ট করুন।';
const _repBack = 'পেছনে রড বেরিয়েছে কি না না দেখে রিপোর্ট করবেন না।';
const _repHammer = 'হাতুড়ি ঠুকে শব্দ না শুনে রিপোর্ট করবেন না।';
const _noClimb = 'হাতুড়িতে দপ্ দপ্ শব্দ আর পেছনে রড বেরিয়ে আছে! এই পোল আপনার ভারে ভেঙে পড়বে। মই লাগাবেন না।';
const _pole12Done = 'সাবাশ! ফাঁপা শব্দ আর বেরিয়ে থাকা রড দেখে মই না লাগিয়ে বিপদ রিপোর্ট করেছেন। হিরো না হয়ে প্রাণ বাঁচিয়েছেন।';

const _endHabit12 = <String>[
  'গোড়ার ঘাস সরিয়ে ফাটল দেখা',
  'স্টে-তার যাচাই',
  'পেছনে খসে যাওয়া কংক্রিট ও রড',
  'হাতুড়িতে ফাঁপা দপ্ দপ্ শব্দ',
];

const _pole12Front = 'assets/zero_loss/scene/pole12_front.jpg';
const _pole12FrontClear = 'assets/zero_loss/scene/pole12_front_clear.jpg';
const _pole12Back = 'assets/zero_loss/scene/pole12_back.jpg';
const _pole12BackClear = 'assets/zero_loss/scene/pole12_back_clear.jpg';
const _pole12Tag = 'assets/zero_loss/scene/pole12_tag.jpg';

const _okBase13 = 'গোড়ার মাটি সরিয়ে জয়েন্ট দেখা হয়েছে। মরিচা নেই। ঠিক আছে।';
const _okHammer13 = 'হাতুড়ি ঠুকে পরিষ্কার টন টন শব্দ মিলেছে। ভেতরে জং নেই, ঠিক আছে।';
const _okBack13 = 'চারপাশ ঘুরে ওয়েল্ডিং জয়েন্ট ও আর্থিং দেখা হয়েছে। ঠিক আছে।';
const _okTop13 = 'নিচ থেকে মাথা পর্যন্ত ক্রস-আর্ম ও ইনসুলেটর দেখে নেওয়া হয়েছে। ঠিক আছে।';
const _missBase13 = 'স্টিল পোলের আসল শত্রু মাটির সংযোগস্থলের মরিচা। গোড়াটা পরিষ্কার করে দেখলেন না?';
const _missHammer13 = 'স্টিলের পোলে হাতুড়ি ঠুকে টন টন শব্দটা যাচাই করলেন না?';
const _missBack13 = 'চারপাশ ঘুরে ওয়েল্ডিং জয়েন্ট আর ক্ল্যাম্পগুলো দেখলেন না?';
const _missTop13 = 'গোড়া থেকে ওপর পর্যন্ত চোখ বুলিয়ে ক্রস-আর্ম আর ইনসুলেটর দেখলেন না?';
const _pole13Done = 'দারুণ অভ্যাস! গোড়ার জয়েন্ট, টন টন শব্দ আর মাথার ক্রস-আর্ম দেখে তবেই মই লাগিয়েছেন।';

const _endHabit13 = <String>[
  'গোড়ার জয়েন্টে মরিচা নেই',
  'হাতুড়িতে টন টন শব্দ',
  'চারপাশের ওয়েল্ড ও আর্থিং',
  'মাথার ক্রস-আর্ম ও ইনসুলেটর',
];

const _pole13Front = 'assets/zero_loss/scene/pole13_front.jpg';
const _pole13FrontClear = 'assets/zero_loss/scene/pole13_front_clear.jpg';
const _pole13Back = 'assets/zero_loss/scene/pole13_back.jpg';
const _pole13BackClear = 'assets/zero_loss/scene/pole13_back_clear.jpg';
const _pole13Top = 'assets/zero_loss/scene/pole13_top.jpg';
const _pole13Glass = 'assets/zero_loss/scene/pole13_glass.jpg';

const _poleFront = 'assets/zero_loss/scene/pole11_front.jpg';
const _poleFrontClear = 'assets/zero_loss/scene/pole11_front_clear.jpg';
const _poleBack = 'assets/zero_loss/scene/pole11_back.jpg';
const _poleBackClear = 'assets/zero_loss/scene/pole11_back_clear.jpg';
const _poleHammer = 'assets/zero_loss/scene/pole11_hammer.webp';
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

enum _ShelfTool { hammer, ladder, tag, glass }

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
  late final AnimationController _climb;

  var _backSide = false;
  var _grassCleared = false;
  final _done = <String>{}; // 'grass', 'stay', 'back', 'hammer'
  var _ladderPlaced = false;
  var _reported = false;
  var _lookingUp = false;

  bool get _unfit => widget.engine.level.number == 12;
  bool get _steel => widget.engine.level.number == 13;

  String _poleShot(bool showBack) {
    if (_lookingUp && _steel) return _pole13Top;
    if (_steel) {
      return showBack
          ? (_grassCleared ? _pole13BackClear : _pole13Back)
          : (_grassCleared ? _pole13FrontClear : _pole13Front);
    }
    if (_unfit) {
      return showBack
          ? (_grassCleared ? _pole12BackClear : _pole12Back)
          : (_grassCleared ? _pole12FrontClear : _pole12Front);
    }
    return showBack
        ? (_grassCleared ? _poleBackClear : _poleBack)
        : (_grassCleared ? _poleFrontClear : _poleFront);
  }

  List<String> get _endItems {
    if (_unfit) return _endHabit12;
    if (_steel) return _endHabit13;
    return _endHabitItems;
  }

  String get _thanks {
    if (_unfit) return _pole12Done;
    if (_steel) return _pole13Done;
    return _pole11Done;
  }

  var _coachVisible = false;
  var _coachSay = '';
  var _coachMood = DsCoachMood.talk;
  var _speechToken = 0;

  var _finishing = false;
  var _climbed = false;
  var _hammerBusy = false;
  var _showChecklist = false;
  var _checkedCount = 0;
  var _checklistReady = false;
  var _showThanks = false;
  Completer<void>? _nextGate;

  @override
  void initState() {
    super.initState();
    widget.engine.beginDress();
    ZlFx.holdClock();
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.35, muted: widget.muted));
    _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _tapAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 680));
    _stayTwang = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _climb = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  }

  @override
  void dispose() {
    _speechToken++;
    ZlFx.releaseClock();
    _flip.dispose();
    _tapAnim.dispose();
    _stayTwang.dispose();
    _shake.dispose();
    _climb.dispose();
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
      _praise(_steel ? _okBase13 : _unfit ? _okGrass12 : _okGrass);
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
      _praise(_unfit ? _okStay12 : _okStay);
    }
  }

  Future<void> _doFlip(Offset global) async {
    if (_finishing || _flip.isAnimating) return;
    final toBack = !_backSide;
    HapticFeedback.selectionClick();
    setState(() => _backSide = toBack);
    if (toBack) {
      await _flip.forward();
    } else {
      await _flip.reverse();
      return;
    }
    if (!mounted || !_backSide || _finishing) return;
    if (_done.add('back')) {
      unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.65, muted: widget.muted));
      widget.engine.dressRight();
      widget.onDelta(5, global);
      setState(() {});
      _praise(_steel ? _okBack13 : _unfit ? _okBack12 : _okBack);
    }
  }

  Future<void> _doHammer(Offset global) async {
    if (_finishing || _hammerBusy) return;
    _hammerBusy = true;
    _tapAnim.forward(from: 0);
    HapticFeedback.mediumImpact();
    unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.72, muted: widget.muted));
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.86, muted: widget.muted));
    await Future<void>.delayed(const Duration(milliseconds: 460));
    _hammerBusy = false;
    if (!mounted || _finishing) return;
    if (!_done.add('hammer')) return;
    setState(() {});
    unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.55, muted: widget.muted));
    widget.engine.dressRight();
    widget.onDelta(5, global);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted || _finishing) return;
    _praise(_steel ? _okHammer13 : _unfit ? _okHammer12 : _okHammer);
  }

  void _fault(String line, Offset global) {
    HapticFeedback.heavyImpact();
    unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.8, muted: widget.muted));
    widget.engine.dressWrong();
    widget.onDelta(-5, global);
    _shake.forward(from: 0);
    _showFaultCoach(line);
  }

  String? _firstMiss({required bool reporting}) {
    if (_steel) {
      if (!_done.contains('grass')) return _missBase13;
      if (!_done.contains('hammer')) return _missHammer13;
      if (!_done.contains('back')) return _missBack13;
      if (!_done.contains('top')) return _missTop13;
      return null;
    }
    if (!_done.contains('grass')) return reporting ? _repGrass : _missGrass;
    if (!_done.contains('stay')) return reporting ? _repStay : _missStay;
    if (!_done.contains('back')) return reporting ? _repBack : _missBack;
    if (!_done.contains('hammer')) return reporting ? _repHammer : _missHammer;
    return null;
  }

  void _doTop(Offset global) {
    if (_finishing || !_steel) return;
    final opening = !_lookingUp;
    setState(() => _lookingUp = opening);
    if (!opening) return;
    HapticFeedback.selectionClick();
    unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.55, muted: widget.muted));
    if (_done.add('top')) {
      unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.65, muted: widget.muted));
      widget.engine.dressRight();
      widget.onDelta(5, global);
      _praise(_okTop13);
    }
  }

  Future<void> _tryReport(Offset global) async {
    if (_finishing || !_unfit) return;
    final missed = _firstMiss(reporting: true);
    if (missed != null) {
      _fault(missed, global);
      return;
    }
    _clearCoachIfOpen();
    if (_backSide) {
      setState(() => _backSide = false);
      await _flip.reverse();
      if (!mounted) return;
    }
    setState(() {
      _finishing = true;
      _reported = true;
    });
    HapticFeedback.mediumImpact();
    unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.82, muted: widget.muted));
    widget.engine.dressRight();
    widget.onDelta(5, global);
    await _closeOut(_pole12Done);
  }

  Future<void> _tryLadder(Offset global) async {
    if (_finishing) return;
    final missed = _firstMiss(reporting: false);
    if (missed != null) {
      _fault(missed, global);
      return;
    }
    if (_unfit) {
      _fault(_noClimb, global);
      return;
    }
    _clearCoachIfOpen();
    if (_backSide) {
      setState(() => _backSide = false);
      await _flip.reverse();
      if (!mounted) return;
    }
    setState(() {
      _finishing = true;
      _ladderPlaced = true;
    });
    HapticFeedback.mediumImpact();
    unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.62, muted: widget.muted));
    widget.engine.dressRight();
    widget.onDelta(5, global);
    await Future<void>.delayed(const Duration(milliseconds: 780));
    if (!mounted) return;
    setState(() => _climbed = true);
    _climb.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    await _closeOut(_thanks);
  }

  void _proceedChecklist() {
    final gate = _nextGate;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  Future<void> _closeOut(String thanks) async {
    final gate = Completer<void>();
    _nextGate = gate;
    if (!mounted) return;
    setState(() {
      _showChecklist = true;
      _checkedCount = 0;
      _checklistReady = false;
    });
    final endItems = _endItems;
    for (var i = 0; i < endItems.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 520));
      if (!mounted) return;
      unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.45, muted: widget.muted));
      setState(() => _checkedCount = i + 1);
    }
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
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
    await widget.onSpeak(thanks).timeout(
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
                child: _showChecklist
                    ? Padding(
                        padding: EdgeInsets.only(top: dsBadgeInset(context)),
                        child: DsHabitChecklist(
                        items: _endItems,
                        shown: _checkedCount,
                        showNext: _checklistReady,
                        onNext: _proceedChecklist,
                      ),
                      )
                    : DragTarget<_ShelfTool>(
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
                    } else if (details.data == _ShelfTool.tag) {
                      _tryReport(center);
                    } else if (details.data == _ShelfTool.glass) {
                      _doTop(center);
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
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: Listenable.merge([_flip, _stayTwang]),
                                  builder: (context, _) {
                                    final nudge = math.sin(_stayTwang.value * math.pi * 6) * (1 - _stayTwang.value) * 5;
                                    final fade = _lookingUp ? 0.0 : _flip.value;
                                    return Transform.translate(
                                      offset: Offset(nudge, 0),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.asset(
                                            _poleShot(false),
                                            fit: BoxFit.cover,
                                            alignment: _lookingUp ? Alignment.topCenter : Alignment.bottomCenter,
                                            width: w,
                                            height: h,
                                          ),
                                          Opacity(
                                            opacity: fade,
                                            child: Image.asset(
                                              _poleShot(true),
                                              fit: BoxFit.cover,
                                              alignment: Alignment.bottomCenter,
                                              width: w,
                                              height: h,
                                            ),
                                          ),
                                        ],
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
                              if (!_backSide && !_steel)
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
                                        _praise(_steel ? _okBack13 : _unfit ? _okBack12 : _okBack);
                                      }
                                      setState(() {});
                                    },
                                    child: const SizedBox.expand(),
                                  ),
                                ),

                              // Standing in PPE until the ladder is up, then the climbing pose.
                              if (_reported)
                                Positioned(
                                  left: w * 0.47,
                                  top: h * 0.40,
                                  width: 42,
                                  height: 56,
                                  child: IgnorePointer(
                                    child: Image.asset(_pole12Tag, fit: BoxFit.contain),
                                  ),
                                ),
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: Listenable.merge([_flip, _climb]),
                                  builder: (context, _) {
                                    final walk = _flip.value;
                                    final rise = _climb.value;
                                    final standLeft = w * (0.02 + walk * 0.56);
                                    final standBottom = h * 0.04;
                                    final standH = h * 0.42;
                                    final left = _reported
                                        ? w * 0.0
                                        : standLeft + (w * 0.20 - standLeft) * rise;
                                    final bottom = _reported
                                        ? h * 0.02
                                        : standBottom + (h * 0.30 - standBottom) * rise;
                                    final manH = _reported
                                        ? h * 0.36
                                        : standH + (h * 0.48 - standH) * rise;
                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Positioned(
                                          left: left,
                                          bottom: bottom,
                                          height: manH,
                                          child: IgnorePointer(
                                            child: Transform.flip(
                                              flipX: rise < 0.45 && walk < 0.55,
                                              child: Image.asset(
                                                rise > 0.35
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

              if (!_finishing)
                DsFlatShelf(
                  children: [
                    if (!_done.contains('hammer'))
                      DsShelfToken<_ShelfTool>(data: _ShelfTool.hammer, asset: _poleHammer),
                    if (!_ladderPlaced && !_reported)
                      DsShelfToken<_ShelfTool>(data: _ShelfTool.ladder, asset: _poleLadder),
                    if (_steel && !_done.contains('top'))
                      DsShelfToken<_ShelfTool>(data: _ShelfTool.glass, asset: _pole13Glass),
                    if (_unfit && !_reported)
                      DsShelfToken<_ShelfTool>(data: _ShelfTool.tag, asset: _pole12Tag),
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

          // Final thank-you coach while the pole + FRP ladder stay visible behind
          if (_showThanks)
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, -0.42),
                child: DsCoach(
                  mood: DsCoachMood.thanks,
                  line: _thanks,
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

/// Closing list used by levels 8–10: dark card, rows appear one at a time.
class DsHabitChecklist extends StatelessWidget {
  const DsHabitChecklist({
    super.key,
    required this.items,
    required this.shown,
    this.showNext = false,
    this.onNext,
  });

  final List<String> items;
  final int shown;
  final bool showNext;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final n = shown.clamp(0, items.length);
    final progress = items.isEmpty ? 0.0 : n / items.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF012181F),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0x44F6E7B0)),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 16))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('চেকলিস্ট', style: zlText(13, weight: FontWeight.w800, color: const Color(0xFFC9A227))),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  builder: (_, t, _) => LinearProgressIndicator(
                    value: t,
                    minHeight: 4,
                    backgroundColor: const Color(0x33F6E7B0),
                    color: const Color(0xFF7DCEA0),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  children: [
                    for (var i = 0; i < n; i++)
                      TweenAnimationBuilder<double>(
                        key: ValueKey(items[i]),
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        builder: (_, t, _) {
                          final rise = t.clamp(0.0, 1.0);
                          final tick = ((t - 0.42) / 0.58).clamp(0.0, 1.0);
                          return Opacity(
                            opacity: rise,
                            child: Transform.translate(
                              offset: Offset(36 * (1 - rise), 0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        items[i],
                                        style: zlText(16, weight: FontWeight.w700, color: const Color(0xFFF6E7C8)),
                                      ),
                                    ),
                                    Transform.scale(
                                      scale: Curves.easeOutBack.transform(tick),
                                      child: const Icon(Icons.check_circle_rounded, color: Color(0xFF7DCEA0), size: 26),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              if (showNext && onNext != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Material(
                      color: const Color(0xFFC9A227),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onNext,
                        child: const SizedBox(
                          width: 52,
                          height: 52,
                          child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF1A140C), size: 26),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
