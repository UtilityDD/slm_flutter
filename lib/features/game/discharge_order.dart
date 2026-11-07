import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'beat_fx.dart';
import 'do_parts.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'learn_feedback_lines.dart';
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'order_steps.dart';
import 'spoken_once.dart';

// Lesson 1.5, কাজ 2: "আগে মাটি, পরে লাইন". The permit is in hand and the
// 11 kV line is off — but a dead line can still hold charge. Round 1: clamp
// the rod's earth end to a sound earth point, touch R, Y, B with the hook
// (a spark = charge gone), then throw the shorting chain. Round 2, work done:
// take it off in reverse — the earth comes off last. Somewhere in round 1 a
// pressure call says "the line is off, skip the discharge".
//
// Deadly (owner-approved list): hook on the line before the earth; chain in
// place of the rod; skipping the discharge. Slips: a rusty earth point; the
// chain before all three phases; the earth off first.
//
// Voice: NO recorded clips (owner's decision, 2026-11-06): every line is read
// by the phone's TTS through MascotSpeechLibrary. Art: hand-made SVGs under
// assets/game/art/discharge/ (no text inside them).


// ============================================================================
// Content
// ============================================================================

abstract final class DischargeLines {
  static const title = 'আগে মাটি, পরে লাইন';
  static const intro = 'পারমিট হাতে, লাইন বন্ধ। কিন্তু ঘুমন্ত বাঘও বাঘ — রড দিয়ে লাইনটা সত্যিই নিরাপদ করুন।';
  static const scene = '11 কেভি লাইন · পারমিট হাতে';
  static const sceneOff = 'কাজ শেষ · এবার খোলার পালা';
  static const rounds = ['লাগানো', 'খোলা'];
  static const askOn = 'ডিসচার্জ রড হাতে। কোনটা আগে?';
  static const askOff = 'কাজ শেষ। এবার খুলুন — ঠিক ক্রমে।';
  static const earthOn = [FeedbackLine('ক্ল্যাম্প আঁটল।'), FeedbackLine('আর্থ পাকা।'), FeedbackLine('মাটি ধরা হলো।')];
  static const spark = [
    FeedbackLine('চট্! চার্জ নামল।'),
    FeedbackLine('স্পার্ক — ভালো লক্ষণ।'),
    FeedbackLine('নামল!'),
    FeedbackLine('চট্!'),
  ];
  static const chainOn = 'চেইন উঠল — ফেজ শর্ট।';
  static const onDone = 'লাইন এবার সত্যিই নিরাপদ। কাজ চলুক।';
  static const offStep = [FeedbackLine('নামল।'), FeedbackLine('ঠিক আছে।'), FeedbackLine('বেশ।')];
  static const callHeld = 'ঠিক! চার্জ চোখে দেখা যায় না।';
  static const rush = 'ঠিক আছে, সরাসরি উঠি';
  static const hold = 'না, আগে ডিসচার্জ';
  static const allSet = 'আগে মাটি, পরে লাইন — খোলার সময় উল্টো। দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট! মাঠে এভাবেই।';
  static const fail = 'আরেকবার — এবার ক্রমটা মনে রেখে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtEarth = 'আর্থ আগে';
  static const caughtPhases = 'R · Y · B ডিসচার্জ';
  static const caughtChain = 'চেইন রডের পরে';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static const caughtOff = 'আর্থ সবার শেষে খোলা';
}

abstract final class DischargeMistakes {
  static const lineBeforeEarth = DoMistake(
    key: '1.5/discharge/line-before-earth',
    textBn: 'আগে লাইনে হুক, পরে আর্থ — জমা চার্জ আপনার শরীর দিয়ে মাটিতে নামে। সবসময় আগে মাটি, পরে লাইন।',
    art: 'assets/game/art/discharge/wrong_right.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const chainInsteadOfRod = DoMistake(
    key: '1.5/discharge/chain-instead-of-rod',
    textBn: 'চেইন রডের বদলি নয় — চেইন শুধু ফেজ শর্ট করে, চার্জ মাটিতে নামায় না। আগে রড, পরে চেইন।',
    art: 'assets/game/art/discharge/chain_after_rod.svg',
    deadly: true,
    lessonPoint: 5,
  );
  static const skipDischarge = DoMistake(
    key: '1.5/discharge/skip-discharge',
    textBn: 'বন্ধ লাইনেও চার্জ জমে থাকে — ৫ মিনিট হোক বা ৫ ঘণ্টা, ডিসচার্জ না করে লাইনে হাত নয়।',
    art: 'assets/game/art/discharge/five_min.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const rustyEarth = DoMistake(
    key: '1.5/discharge/rusty-earth',
    textBn: 'মরিচা ধরা, ভাঙা আর্থে চার্জ ঠিকমতো নামে না। পরিষ্কার, মজবুত আর্থ পয়েন্টে ক্ল্যাম্প দিন।',
    art: 'assets/game/art/discharge/rusty_vs_clean.svg',
    lessonPoint: 1,
  );
  static const chainEarly = DoMistake(
    key: '1.5/discharge/chain-early',
    textBn: 'তিনটে ফেজ — R, Y, B — ডিসচার্জ শেষ করে তবেই চেইন ছুড়ুন।',
    art: 'assets/game/art/discharge/chain_after_rod.svg',
    lessonPoint: 5,
  );
  static const earthOffFirst = DoMistake(
    key: '1.5/discharge/earth-off-first',
    textBn: 'খোলার সময় আর্থ সবার শেষে — আগে চেইন আর হুক নামান, তারপর ক্ল্যাম্প।',
    art: 'assets/game/art/discharge/earth_last.svg',
    lessonPoint: 1,
  );
}

const dischargeCallers = [
  DoCaller(
    id: 'jeo',
    whoBn: 'জেই, ফোনে',
    lineBn: 'লাইন তো ৫ মিনিট আগে বন্ধ হয়েছে! ডিসচার্জ-টিসচার্জ ছাড়ো, তাড়াতাড়ি ওঠো।',
    icon: Icons.phone_in_talk_rounded,
  ),
  DoCaller(
    id: 'helper',
    whoBn: 'সাথী হেল্পার',
    lineBn: 'দাদা, পারমিট তো হাতে, লাইন ডেড। রড লাগিয়ে সময় নষ্ট কেন?',
    icon: Icons.engineering_rounded,
  ),
  DoCaller(
    id: 'consumer',
    whoBn: 'পাড়ার লোক',
    lineBn: 'দু’ঘণ্টা ধরে কারেন্ট নেই! এত দেরি করছেন কেন? তাড়াতাড়ি করুন!',
    icon: Icons.record_voice_over_rounded,
  ),
];

/// Ids of the things in the scene.
abstract final class DischargeIds {
  static const earth = 'earth';
  static const rusty = 'rusty';
  static const r = 'R';
  static const y = 'Y';
  static const b = 'B';
  static const chain = 'chain';
  static const chainOff = 'chain-off';
  static const hookOff = 'hook-off';
  static const clampOff = 'clamp-off';
  static const phases = [r, y, b];
}

/// One play's variation: where the sound earth is, when the pressure call
/// comes and who makes it.
@immutable
class DischargeDeal {
  const DischargeDeal({required this.goodLeft, required this.callAfter, required this.caller});

  /// The sound earth point is on the left (the rusty one on the right), or the other way.
  final bool goodLeft;

  /// Steps of round 1 done when the call comes (0 = right at the start).
  final int callAfter;
  final DoCaller caller;
}

DischargeDeal dealDischarge(math.Random rng) => DischargeDeal(
      goodLeft: rng.nextBool(),
      callAfter: rng.nextInt(3),
      caller: dischargeCallers[rng.nextInt(dischargeCallers.length)],
    );

List<OrderRoundSpec> dischargeRounds() => const [
      OrderRoundSpec(
        groups: [
          OrderGroup(
            [DischargeIds.earth],
            skipMistake: DischargeMistakes.lineBeforeEarth,
            earlyBy: {DischargeIds.chain: DischargeMistakes.chainInsteadOfRod},
          ),
          OrderGroup(DischargeIds.phases, skipMistake: DischargeMistakes.chainEarly),
          OrderGroup([DischargeIds.chain], skipMistake: DischargeMistakes.chainEarly),
        ],
        traps: {DischargeIds.rusty: DischargeMistakes.rustyEarth},
      ),
      OrderRoundSpec(
        groups: [
          OrderGroup([DischargeIds.chainOff, DischargeIds.hookOff], skipMistake: DischargeMistakes.earthOffFirst),
          OrderGroup([DischargeIds.clampOff], skipMistake: DischargeMistakes.earthOffFirst),
        ],
      ),
    ];

@immutable
class DischargePack {
  const DischargePack({required this.id, required this.titleBn, this.quickMs = 45000});
  final String id;
  final String titleBn;

  /// A clean play under this time earns the quick bonus.
  final int quickMs;
}

const dischargePack15 = DischargePack(id: 'do_1_5_b', titleBn: DischargeLines.title);
const dischargePacks = {'do_1_5_b': dischargePack15};

// ============================================================================
// Scene geometry (scene units: 360 x 480, same as scene.svg)
// ============================================================================

abstract final class _Geo {
  static const size = Size(360, 480);
  static const wires = {
    DischargeIds.r: (74.0, 66.0, 72.0),
    DischargeIds.y: (144.0, 136.0, 142.0),
    DischargeIds.b: (214.0, 206.0, 212.0),
  };
  static const touchX = 100.0;
  static const leftEarth = Offset(52, 446);
  static const rightEarth = Offset(306, 446);
  static const coil = Offset(246, 452);
  static const chainOn = Offset(300, 142);
  static const hookRest = Offset(132, 330);
  static const hand = Offset(150, 486);
  static const clampLoose = Offset(176, 458);

  static double wireY((double, double, double) w, double x) {
    final t = x / size.width;
    return (1 - t) * (1 - t) * w.$1 + 2 * t * (1 - t) * w.$2 + t * t * w.$3;
  }

  static Offset touch(String phase) => Offset(touchX, wireY(wires[phase]!, touchX));
}

// ============================================================================
// Page
// ============================================================================

class DischargeOrderPage extends StatefulWidget {
  const DischargeOrderPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final DischargePack pack;
  final bool muted;
  final int? seed;

  @override
  State<DischargeOrderPage> createState() => _DischargeOrderPageState();
}

class _DischargeOrderPageState extends State<DischargeOrderPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DischargeRun(
        key: ValueKey(_round),
        ctx: widget.ctx,
        pack: widget.pack,
        muted: _muted,
        rng: widget.seed == null ? math.Random() : math.Random(widget.seed! + _round),
        onRetry: (m) => setState(() {
          _muted = m;
          _round++;
        }),
      );
}

class _DischargeRun extends ConsumerStatefulWidget {
  const _DischargeRun({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final DischargePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DischargeRun> createState() => _DischargeRunState();
}

class _DischargeRunState extends ConsumerState<_DischargeRun> with DoDeathGuard {
  final _scoreKey = GlobalKey();
  late final DischargeDeal _deal = dealDischarge(widget.rng);
  final OrderRun _run = OrderRun(dischargeRounds());
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  late final _earthBag = LineBag(DischargeLines.earthOn);
  late final _sparkBag = LineBag(DischargeLines.spark);
  late final _offBag = LineBag(DischargeLines.offStep);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  int _chain = 0;
  var _callOpen = false;
  var _callDone = false;
  var _callHeld = false;

  /// Last phase the hook touched (the rod rests there in round 2).
  String _lastPhase = DischargeIds.b;
  int _sparks = 0;
  Offset? _sparkAt;
  int _pings = 0;
  Offset? _pingAt;
  var _zap = false;

  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int? _mark;
  int _totalDelta = 0;

  String get _rungId => widget.ctx.rungId;

  @override
  LevelContext get deathCtx => widget.ctx;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  @override
  void dispose() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  // ---- voice (never holds the player) -------------------------------------------

  Future<void> _say(String line, {GuideMood mood = GuideMood.talk, bool other = false}) async {
    if (line.trim().isEmpty || !mounted) return;
    if (!other) ref.read(guideDirectorProvider.notifier).say(mood: mood, line: line);
    await MascotSpeechLibrary.speak(line, muted: _muted, rival: other);
  }

  Future<void> _sayChain(List<String> lines, {GuideMood mood = GuideMood.talk}) async {
    final chain = ++_chain;
    for (final l in lines) {
      if (!mounted || chain != _chain) return;
      await _say(l, mood: mood);
    }
  }

  void _hush() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
  }

  // ---- flow -----------------------------------------------------------------------

  Future<void> _start() async {
    await _sayChain([DischargeLines.intro]);
    if (!mounted || _ended) return;
    _clock.start();
    if (!_maybeCall()) unawaited(_sayChain([DischargeLines.askOn]));
  }

  /// Opens the pressure call when its moment has come; true if it opened.
  bool _maybeCall() {
    if (_callDone || _callOpen || _run.ended || _run.round != 0) return false;
    if (_run.stepsDone < _deal.callAfter) return false;
    if (DischargeIds.phases.every(_run.isDone)) return false;
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/complaint.wav', volume: 0.8, muted: false));
    setState(() => _callOpen = true);
    unawaited(_say(_deal.caller.lineBn, other: true));
    return true;
  }

  Future<void> _answerCall(bool held, Offset origin) async {
    if (!_callOpen || _busy) return;
    _hush();
    setState(() {
      _callOpen = false;
      _callDone = true;
      _callHeld = held;
    });
    if (!held) {
      _run.failDeadly(DischargeMistakes.skipDischarge);
      await _deadly(DischargeMistakes.skipDischarge, origin);
      return;
    }
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await _sayChain([DischargeLines.callHeld, if (_run.stepsDone == 0) DischargeLines.askOn], mood: GuideMood.glad);
  }

  void _tap(String id, Offset origin, Offset scenePoint) {
    if (_busy || _ended || _callOpen || _card != null) return;
    final roundBefore = _run.round;
    final t = _run.tap(id);
    switch (t.kind) {
      case OrderTapKind.ignored:
        return;
      case OrderTapKind.mistake:
        final m = t.mistake!;
        if (m.deadly) {
          unawaited(_deadly(m, origin));
        } else {
          unawaited(_slip(m, origin, scenePoint));
        }
        return;
      case OrderTapKind.ok:
        unawaited(_stepDone(id, roundBefore, t, origin));
    }
  }

  Future<void> _stepDone(String id, int round, OrderTap t, Offset origin) async {
    final phase = DischargeIds.phases.contains(id);
    if (phase) {
      _lastPhase = id;
      HapticFeedback.mediumImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.9, muted: false));
    } else {
      HapticFeedback.lightImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.5, muted: false));
    }
    setState(() {
      if (phase) {
        _sparks++;
        _sparkAt = _Geo.touch(id);
      }
    });
    final points = switch (id) {
      DischargeIds.earth || DischargeIds.chain => 10,
      _ => 5,
    };
    unawaited(_levelDelta(points, origin, mood: GuideMood.glad));
    final word = switch (id) {
      DischargeIds.earth => _earthBag.next().shownBn,
      DischargeIds.chain => DischargeLines.chainOn,
      _ when phase => _sparkBag.next().shownBn,
      _ => _offBag.next().shownBn,
    };
    if (t.allDone) {
      await _finish();
      return;
    }
    if (t.roundDone) {
      // A short beat to see the safe line; the voice never holds the player.
      _busy = true;
      unawaited(_sayChain([DischargeLines.onDone, DischargeLines.askOff], mood: GuideMood.glad));
      await Future<void>.delayed(MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 900));
      if (!mounted) return;
      _busy = false;
      setState(() {});
      return;
    }
    if (round == 0 && _maybeCall()) return;
    unawaited(_sayChain([word], mood: GuideMood.glad));
  }

  Future<void> _slip(DoMistake m, Offset origin, Offset scenePoint) async {
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    _hush();
    setState(() {
      _pings++;
      _pingAt = scenePoint;
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('order/${m.key}');
    if (!mounted || _card != m) return;
    // The rule is read aloud the first time only; after that a short word
    // (the card shows the rule).
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  Future<void> _deadly(DoMistake m, Offset origin) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/accident.wav', volume: 0.9, muted: false));
    setState(() => _zap = true);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    await Future<void>.delayed(MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('order/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? DischargeLines.deadlyWord : DischargeLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  Future<void> _readLesson(DoMistake m) async {
    _hush();
    await openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: m.lessonPoint, muted: _muted);
  }

  void _cardGo() {
    final m = _card;
    if (m == null) return;
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
      case MistakeTone.nearMiss:
        _hush();
        widget.onRetry(_muted);
      case MistakeTone.deadly:
        _popped = true;
        unawaited(dieAndLeave());
    }
  }

  Future<void> _levelDelta(int delta, Offset origin, {GuideMood? mood}) async {
    final next = math.max(0, _runScore + delta);
    final real = next - _runScore;
    if (real == 0 || !mounted) return;
    setState(() => _runScore = next);
    await BeatFx.levelDelta(ref, real, mood: mood, originGlobal: origin, muted: _muted);
  }

  Future<void> _finish() async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    final save = ref.read(gameSaveProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final centre = Offset(size.width / 2, size.height * 0.45);
    final mark = _run.percent;
    await save.recordLevelResult(_rungId, mark);
    if (!mounted) return;
    if (_run.passed) {
      await save.markRungCleared(_rungId);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && _clock.elapsedMilliseconds < widget.pack.quickMs) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    if (!mounted) return;
    setState(() {
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? DischargeLines.fail : (_quickBonus ? DischargeLines.quick : DischargeLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leave() async {
    if (deathPending) {
      if (_popped) return;
      _popped = true;
      await dieAndLeave();
      return;
    }
    if (_passed) {
      _popOnce(true);
      return;
    }
    final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: true);
    if (leave == true) _popOnce(false);
  }

  List<String> get _caught => [
        DischargeLines.caughtEarth,
        DischargeLines.caughtPhases,
        DischargeLines.caughtChain,
        if (_callHeld) DischargeLines.caughtCall,
        DischargeLines.caughtOff,
      ];

  // ---- build ------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final round = _run.done ? 1 : _run.round;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: SlmColors.navy950,
        body: ScoreFlyHost(
          scoreKey: _scoreKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                child: Column(
                  children: [
                    LevelShellBar(
                      context_: widget.ctx,
                      titleBn: widget.pack.titleBn,
                      scoreKey: _scoreKey,
                      levelScore: _runScore,
                      muted: _muted,
                      onClose: () => unawaited(_leave()),
                      onToggleMute: () {
                        unawaited(MascotSpeechLibrary.stop());
                        setState(() => _muted = !_muted);
                      },
                    ),
                    DoProgress(
                      labels: DischargeLines.rounds,
                      done: {for (var i = 0; i < math.min(_run.round, 2); i++) i},
                      current: _run.done ? null : _run.round,
                      quiet: quiet,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 4),
                      child: Text(
                        round == 0 ? DischargeLines.scene : DischargeLines.sceneOff,
                        style: bangla(fontSize: 12.5, fontWeight: FontWeight.w700, color: SlmColors.gold200),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox.fromSize(
                              size: _Geo.size,
                              child: _Scene(
                                deal: _deal,
                                run: _run,
                                lastPhase: _lastPhase,
                                sparks: _sparks,
                                sparkAt: _sparkAt,
                                pings: _pings,
                                pingAt: _pingAt,
                                zap: _zap,
                                quiet: quiet,
                                enabled: _card == null && !_callOpen,
                                onTap: _tap,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Opacity(opacity: _card == null && !_callOpen ? 1 : 0, child: const DoCoachStrip()),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              if (_callOpen)
                DoCallCard(
                  caller: _deal.caller,
                  quiet: quiet,
                  rushBn: DischargeLines.rush,
                  holdBn: DischargeLines.hold,
                  onAnswer: (held, o) => unawaited(_answerCall(held, o)),
                ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$_pings'),
                  mistake: _card!,
                  tone: _cardTone,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null ? null : () => unawaited(_readLesson(_card!)),
                  onGo: _cardGo,
                ),
              if (_mark != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0xB3050A16),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _run.passed
                            ? LevelPassPanel(
                                mark: _mark!,
                                levelScore: _runScore,
                                totalDelta: _totalDelta,
                                ms: _clock.elapsedMilliseconds,
                                caughtBn: _caught,
                                quickBonus: _quickBonus,
                                onNext: () => _popOnce(true),
                                onRetry: () => widget.onRetry(_muted),
                              )
                            : LevelFailPanel(
                                percent: _mark!,
                                muted: _muted,
                                onRetry: () => widget.onRetry(_muted),
                                onLeave: () => _popOnce(false),
                                onRead: () => unawaited(openLessonPoint(context, ref,
                                    lessonId: widget.ctx.lessonId, point: 1, muted: _muted)),
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

// ============================================================================
// Scene
// ============================================================================

typedef _TapScene = void Function(String id, Offset global, Offset scenePoint);

/// The pole, the three charged wires, two earth points (one rusty), the chain
/// coil and the rod (hook on a fibreglass stick, copper cable to the earth
/// clamp). Every movement is a one-shot reply to a tap: nothing loops.
class _Scene extends StatelessWidget {
  const _Scene({
    required this.deal,
    required this.run,
    required this.lastPhase,
    required this.sparks,
    required this.sparkAt,
    required this.pings,
    required this.pingAt,
    required this.zap,
    required this.quiet,
    required this.enabled,
    required this.onTap,
  });

  final DischargeDeal deal;
  final OrderRun run;
  final String lastPhase;
  final int sparks;
  final Offset? sparkAt;
  final int pings;
  final Offset? pingAt;
  final bool zap;
  final bool quiet;
  final bool enabled;
  final _TapScene onTap;

  Offset get _good => deal.goodLeft ? _Geo.leftEarth : _Geo.rightEarth;
  Offset get _bad => deal.goodLeft ? _Geo.rightEarth : _Geo.leftEarth;

  @override
  Widget build(BuildContext context) {
    final r0 = run.round == 0 && !run.ended;
    final off = run.round >= 1;
    final earthOn = off ? !run.isDone(DischargeIds.clampOff) : run.isDone(DischargeIds.earth);
    final chainUp = off ? !run.isDone(DischargeIds.chainOff) && !run.done : run.isDone(DischargeIds.chain);
    final charged = {
      if (!off)
        for (final p in DischargeIds.phases)
          if (!run.isDone(p)) p,
    };
    final Offset hookAt;
    if (off) {
      hookAt = run.isDone(DischargeIds.hookOff) || run.done ? _Geo.hookRest : _Geo.touch(lastPhase);
    } else {
      final last = run.doneOrder.lastWhere((id) => DischargeIds.phases.contains(id), orElse: () => '');
      hookAt = last.isEmpty ? _Geo.hookRest : _Geo.touch(last);
    }
    final clampAt = earthOn ? _good.translate(0, -14) : _Geo.clampLoose;
    final move = quiet ? Duration.zero : const Duration(milliseconds: 380);

    final taps = <(String, Rect, String)>[
      if (r0) ...[
        (DischargeIds.earth, Rect.fromCenter(center: _good, width: 78, height: 70), 'আর্থ পয়েন্ট'),
        (DischargeIds.rusty, Rect.fromCenter(center: _bad, width: 78, height: 70), 'আর্থ পয়েন্ট'),
        for (final p in DischargeIds.phases)
          (p, Rect.fromCenter(center: _Geo.touch(p), width: 150, height: 46), '$p ফেজ'),
        (DischargeIds.chain, Rect.fromCenter(center: _Geo.coil, width: 86, height: 56), 'চেইন'),
      ],
      if (off && !run.done) ...[
        (DischargeIds.chainOff, Rect.fromCenter(center: _Geo.chainOn, width: 64, height: 176), 'চেইন'),
        (DischargeIds.hookOff, Rect.fromCenter(center: _Geo.touch(lastPhase).translate(-8, 12), width: 76, height: 64), 'রডের হুক'),
        (DischargeIds.clampOff, Rect.fromCenter(center: _good, width: 78, height: 70), 'আর্থ ক্ল্যাম্প'),
      ],
    ];

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(child: SvgPicture.asset('assets/game/art/discharge/scene.svg', fit: BoxFit.fill)),
        Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _ChargePainter(charged)))),
        // Earth points.
        _at(_good, const Size(64, 64), SvgPicture.asset('assets/game/art/discharge/earth_good.svg')),
        _at(_bad, const Size(64, 64), SvgPicture.asset('assets/game/art/discharge/earth_rusty.svg')),
        // Chain: coiled on the ground, or thrown over the three wires.
        _at(
          _Geo.coil,
          const Size(72, 40),
          AnimatedOpacity(opacity: chainUp ? 0 : 1, duration: move, child: SvgPicture.asset('assets/game/art/discharge/chain_coil.svg')),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: chainUp ? 1 : 0,
              duration: move,
              child: AnimatedSlide(
                offset: chainUp ? Offset.zero : const Offset(-0.08, 0.5),
                duration: move,
                curve: Curves.easeOutBack,
                child: SvgPicture.asset('assets/game/art/discharge/chain.svg', fit: BoxFit.fill),
              ),
            ),
          ),
        ),
        // The rod: stick, cable, clamp and hook move together.
        Positioned.fill(
          child: IgnorePointer(
            child: TweenAnimationBuilder<Offset>(
              tween: Tween<Offset>(end: hookAt),
              duration: move,
              curve: Curves.easeOutCubic,
              builder: (_, hook, _) => TweenAnimationBuilder<Offset>(
                tween: Tween<Offset>(end: clampAt),
                duration: move,
                curve: Curves.easeOutBack,
                builder: (_, clamp, _) => Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _RodPainter(hook: hook, clamp: clamp))),
                    Positioned(left: clamp.dx - 16, top: clamp.dy - 16, width: 32, height: 32, child: SvgPicture.asset('assets/game/art/discharge/clamp.svg')),
                    Positioned(left: hook.dx - 29, top: hook.dy - 10, width: 40, height: 40, child: SvgPicture.asset('assets/game/art/discharge/hook.svg')),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (sparkAt != null && sparks > 0 && !quiet)
          Positioned(
            left: sparkAt!.dx - 40,
            top: sparkAt!.dy - 40,
            width: 80,
            height: 80,
            child: IgnorePointer(child: _OneShot(key: ValueKey('spark-$sparks'), ms: 460, painter: _SparkPainter.new)),
          ),
        if (pingAt != null && pings > 0 && !quiet)
          Positioned(
            left: pingAt!.dx - 40,
            top: pingAt!.dy - 40,
            width: 80,
            height: 80,
            child: IgnorePointer(child: _OneShot(key: ValueKey('ping-$pings'), ms: 520, painter: _PingPainter.new)),
          ),
        if (zap)
          Positioned.fill(
            child: IgnorePointer(
              child: quiet
                  ? const ColoredBox(color: Color(0x66C0392B))
                  : _OneShot(key: const ValueKey('zap'), ms: 900, painter: (t) => _ZapPainter(t, from: hookAt, to: _Geo.hand)),
            ),
          ),
        // Tap areas on top (no names on screen; screen readers get a label).
        if (enabled)
          for (final (id, rect, label) in taps)
            Positioned.fromRect(
              rect: rect,
              child: Semantics(
                button: true,
                label: label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => onTap(id, d.globalPosition, rect.center),
                ),
              ),
            ),
      ],
    );
  }

  Widget _at(Offset c, Size s, Widget child) =>
      Positioned(left: c.dx - s.width / 2, top: c.dy - s.height / 2, width: s.width, height: s.height, child: IgnorePointer(child: child));
}

/// A warm glow along each wire that still holds charge.
class _ChargePainter extends CustomPainter {
  _ChargePainter(this.charged);
  final Set<String> charged;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = const Color(0x66FF8A1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final core = Paint()
      ..color = const Color(0xAAFFB347)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final id in charged) {
      final w = _Geo.wires[id]!;
      final path = Path()
        ..moveTo(0, w.$1)
        ..quadraticBezierTo(size.width / 2, w.$2, size.width, w.$3);
      canvas.drawPath(path, glow);
      canvas.drawPath(path, core);
    }
  }

  @override
  bool shouldRepaint(_ChargePainter old) => old.charged.length != charged.length || !old.charged.containsAll(charged);
}

/// Fibreglass stick from the hand to the hook; copper cable from the hook
/// down to the earth clamp.
class _RodPainter extends CustomPainter {
  _RodPainter({required this.hook, required this.clamp});
  final Offset hook;
  final Offset clamp;

  @override
  void paint(Canvas canvas, Size size) {
    final stem = hook.translate(-9, 28);
    final stick = Paint()
      ..color = const Color(0xFFE6C35C)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final band = Paint()
      ..color = const Color(0xFFC0392B)
      ..strokeWidth = 7;
    canvas.drawLine(stem, _Geo.hand, stick);
    // The red guard band a third of the way down the stick.
    final g0 = Offset.lerp(stem, _Geo.hand, 0.62)!;
    final g1 = Offset.lerp(stem, _Geo.hand, 0.66)!;
    canvas.drawLine(g0, g1, band);
    final top = hook.translate(-9, 20);
    final sag = Offset((top.dx + clamp.dx) / 2 - 24, math.max(top.dy, clamp.dy) - 10);
    final cable = Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo(sag.dx, sag.dy, clamp.dx, clamp.dy);
    canvas.drawPath(
      cable,
      Paint()
        ..color = const Color(0xFF8A5A1E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4,
    );
    canvas.drawPath(
      cable,
      Paint()
        ..color = const Color(0xFFD9954A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_RodPainter old) => old.hook != hook || old.clamp != clamp;
}

/// Runs its painter once from 0 to 1, then rests (draws nothing more).
class _OneShot extends StatefulWidget {
  const _OneShot({super.key, required this.ms, required this.painter});
  final int ms;
  final CustomPainter Function(Animation<double> t) painter;

  @override
  State<_OneShot> createState() => _OneShotState();
}

class _OneShotState extends State<_OneShot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.ms))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(painter: widget.painter(_c));
}

/// "চট্": a white-yellow flash with short rays.
class _SparkPainter extends CustomPainter {
  _SparkPainter(this.t) : super(repaint: t);
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v >= 1) return;
    final c = size.center(Offset.zero);
    final fade = 1 - v;
    canvas.drawCircle(
      c,
      6 + 16 * v,
      Paint()
        ..color = Color.fromRGBO(255, 244, 180, 0.85 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    final ray = Paint()
      ..color = Color.fromRGBO(255, 210, 31, fade)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.3;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * (8 + 10 * v), c + d * (16 + 20 * v), ray);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => false;
}

/// A red ring where a wrong tap landed.
class _PingPainter extends CustomPainter {
  _PingPainter(this.t) : super(repaint: t);
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v >= 1) return;
    canvas.drawCircle(
      size.center(Offset.zero),
      10 + 26 * v,
      Paint()
        ..color = Color.fromRGBO(192, 57, 43, 1 - v)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(_PingPainter old) => false;
}

/// The deadly moment: a flash and a jagged arc down the rod to the hand.
class _ZapPainter extends CustomPainter {
  _ZapPainter(this.t, {required this.from, required this.to}) : super(repaint: t);
  final Animation<double> t;
  final Offset from;
  final Offset to;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final flash = v < 0.25 ? v / 0.25 : (1 - (v - 0.25) / 0.75);
    canvas.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 240, 230, 0.55 * flash.clamp(0.0, 1.0)));
    canvas.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(150, 20, 20, 0.35 * v));
    if (v > 0.7) return;
    final rnd = math.Random((v * 12).floor());
    final path = Path()..moveTo(from.dx, from.dy);
    const n = 9;
    for (var i = 1; i <= n; i++) {
      final p = Offset.lerp(from, to, i / n)!;
      path.lineTo(p.dx + (rnd.nextDouble() - 0.5) * 22, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFF3B0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(_ZapPainter old) => false;
}
