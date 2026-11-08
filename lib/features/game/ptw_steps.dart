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
import 'beat_fx.dart';
import 'do_parts.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'order_steps.dart';
import 'spoken_once.dart';

// Lesson 1.6, কাজ 2: "সোনালি ধাপ ও লাইন ক্লিয়ার" — the "order" move with step
// cards. Round 1, the permit's golden steps: request → isolation + LOTO →
// permit number → receive → discharge & test → start work. Round 2, line
// clear: count the team (everyone down) → tools off the line → call the
// control room "line clear" → permit cancelled → LOTO off.
//
// Deadly (owner-approved list: skipping the test after the permit; working
// on a verbal permit): "কাজ শুরু" before the discharge & test, or before the
// permit is even issued. Slips: any other step out of order (e.g. line clear
// before counting the team).
//
// Voice: device TTS only. Art: assets/game/art/ptw/ (+ the 1.5 clock picture).

// ============================================================================
// Content
// ============================================================================

@immutable
class StepCard {
  const StepCard(this.id, this.titleBn, this.subBn, this.icon);
  final String id;
  final String titleBn;
  final String subBn;
  final IconData icon;
}

abstract final class StepIds {
  static const request = 'request';
  static const isolate = 'isolate';
  static const issue = 'issue';
  static const receive = 'receive';
  static const test = 'test';
  static const start = 'start';
  static const count = 'count';
  static const tools = 'tools';
  static const clear = 'clear';
  static const cancel = 'cancel';
  static const unlock = 'unlock';
}

const permitCards = [
  StepCard(StepIds.request, 'অনুরোধ', 'সুপারভাইজার কন্ট্রোল রুমে লাইন, জায়গা, কাজ জানিয়ে PTW চান', Icons.phone_in_talk_rounded),
  StepCard(StepIds.isolate, 'আইসোলেশন', 'অপারেটর ব্রেকার OFF করেন, LOTO — তালা আর ট্যাগ', Icons.lock_rounded),
  StepCard(StepIds.issue, 'অনুমোদন', 'ইউনিক পারমিট নম্বরসহ PTW ইস্যু', Icons.assignment_turned_in_rounded),
  StepCard(StepIds.receive, 'গ্রহণ', 'ফিল্ড টিম পারমিট হাতে পায়, মিলিয়ে নেয়', Icons.back_hand_rounded),
  StepCard(StepIds.test, 'যাচাই', 'ডিসচার্জ আর টেস্ট — লাইন সত্যিই ডেড', Icons.bolt_rounded),
  StepCard(StepIds.start, 'কাজ শুরু', 'এবার লাইনে হাত', Icons.construction_rounded),
];

const clearCards = [
  StepCard(StepIds.count, 'দল গোনা', 'সবাই পোল থেকে নেমেছে — মাথা গুনে নিশ্চিত', Icons.groups_rounded),
  StepCard(StepIds.tools, 'যন্ত্র সরানো', 'লাইন থেকে সব যন্ত্রপাতি, আর্থ, চেইন সরানো', Icons.handyman_rounded),
  StepCard(StepIds.clear, 'লাইন ক্লিয়ার', 'কন্ট্রোল রুমে ফোন — কাজ শেষ, পারমিট ফেরত', Icons.call_rounded),
  StepCard(StepIds.cancel, 'পারমিট বাতিল', 'অপারেটর পারমিট বাতিল করেন', Icons.assignment_return_rounded),
  StepCard(StepIds.unlock, 'LOTO খোলা', 'তালা-ট্যাগ খুলে লাইন চালুর প্রস্তুতি', Icons.lock_open_rounded),
];

abstract final class StepLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askPermit, askClear];

  static const title = 'সোনালি ধাপ';
  static const intro = 'পারমিটের প্রতিটা ধাপ জীবন বাঁচায় — একটা বাদ গেলেই পুরো সুরক্ষা ভেঙে পড়ে।';
  static const rounds = ['পারমিট', 'লাইন ক্লিয়ার'];
  static const askPermit = 'পারমিটের ধাপগুলো ক্রমে সাজান — পরের ধাপটা ট্যাপ করুন।';
  static const askClear = 'কাজ শেষ। এবার লাইন ক্লিয়ারের ধাপ সাজান।';
  static String scene(String feeder) => '$feeder · শাটডাউনের দিন';
  static const permitDone = 'পারমিটের সোনালি ধাপ সম্পূর্ণ!';
  static const next = 'লাইন ক্লিয়ারে চলুন';
  static const finish = 'ফলাফল';
  static String headcount(int n) => 'দল গোনা: ${enDigits('$n/$n')} ✓';
  static const ok = [FeedbackLine('ঠিক!'), FeedbackLine('এটাই পরের ধাপ।'), FeedbackLine('বেশ!')];
  static const allSet = 'নেওয়া থেকে ফেরত — পুরো পারমিট চক্র পাকা!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — কোন ধাপের পরে কোনটা, মনে রেখে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtTest = 'পারমিটের পরেও ডিসচার্জ-টেস্ট';
  static const caughtCount = 'লাইন ক্লিয়ারের আগে দল গোনা';
  static const feeders = ['রামপুর 11 কেভি', 'হাটখোলা 11 কেভি', 'নদীপাড় 11 কেভি', 'স্টেশন রোড 11 কেভি'];
}

abstract final class StepMistakes {
  static const noPermit = DoMistake(
    key: '1.6/steps/no-permit',
    textBn: 'পারমিট ইস্যু হওয়ার আগেই কাজ শুরু — এটা মুখের কথায় কাজ। লিখিত PTW হাতে, তবে কাজ।',
    art: 'assets/game/art/ptw/verbal_vs_written.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const skipTest = DoMistake(
    key: '1.6/steps/skip-test',
    textBn: 'পারমিট মানেই ১০০% নিরাপদ নয় — ভুল ফিডার বা ইন্ডুসড ভোল্টেজ থাকতে পারে। ডিসচার্জ আর টেস্ট করে তবে কাজ।',
    art: 'assets/game/art/discharge/five_min.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const permitOrder = DoMistake(
    key: '1.6/steps/permit-order',
    textBn: 'ধাপ উল্টে গেল — অনুরোধ, আইসোলেশন আর LOTO, পারমিট নম্বর, গ্রহণ, যাচাই, তারপর কাজ।',
    art: 'assets/game/art/ptw/golden_steps.svg',
    lessonPoint: 1,
  );
  static const clearEarly = DoMistake(
    key: '1.6/steps/clear-early',
    textBn: 'দল না গুনে লাইন ক্লিয়ার — কেউ পোলে থাকলে লাইন চালু হবে তার ওপরেই। আগে সবাই নিচে, মাথা গুনে।',
    art: 'assets/game/art/ptw/line_clear.svg',
    lessonPoint: 2,
  );
  static const clearOrder = DoMistake(
    key: '1.6/steps/clear-order',
    textBn: 'লাইন ক্লিয়ারের ধাপ উল্টে গেল — দল গোনা, যন্ত্র সরানো, লাইন ক্লিয়ার, পারমিট বাতিল, LOTO খোলা।',
    art: 'assets/game/art/ptw/line_clear.svg',
    lessonPoint: 2,
  );
  static const all = [noPermit, skipTest, permitOrder, clearEarly, clearOrder];
}

/// The two rounds as order specs: every step its own group, in sequence.
List<OrderRoundSpec> permitStepRounds() {
  OrderGroup g(String id, DoMistake skip, [Map<String, DoMistake> early = const {}]) =>
      OrderGroup([id], skipMistake: skip, earlyBy: early);
  const noPermit = {StepIds.start: StepMistakes.noPermit};
  return [
    OrderRoundSpec(groups: [
      g(StepIds.request, StepMistakes.permitOrder, noPermit),
      g(StepIds.isolate, StepMistakes.permitOrder, noPermit),
      g(StepIds.issue, StepMistakes.permitOrder, noPermit),
      g(StepIds.receive, StepMistakes.permitOrder, const {StepIds.start: StepMistakes.skipTest}),
      g(StepIds.test, StepMistakes.permitOrder, const {StepIds.start: StepMistakes.skipTest}),
      g(StepIds.start, StepMistakes.permitOrder),
    ]),
    OrderRoundSpec(groups: [
      g(StepIds.count, StepMistakes.clearOrder, const {StepIds.clear: StepMistakes.clearEarly}),
      g(StepIds.tools, StepMistakes.clearOrder),
      g(StepIds.clear, StepMistakes.clearOrder),
      g(StepIds.cancel, StepMistakes.clearOrder),
      g(StepIds.unlock, StepMistakes.clearOrder),
    ]),
  ];
}

@immutable
class StepsPack {
  const StepsPack({required this.id, required this.titleBn, this.quickMs = 70000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const stepsPack16 = StepsPack(id: 'do_1_6_b', titleBn: StepLines.title);
const stepsPacks = {'do_1_6_b': stepsPack16};

// ============================================================================
// Page
// ============================================================================

class PtwStepsPage extends StatefulWidget {
  const PtwStepsPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final StepsPack pack;
  final bool muted;
  final int? seed;

  @override
  State<PtwStepsPage> createState() => _PtwStepsPageState();
}

class _PtwStepsPageState extends State<PtwStepsPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _StepsRunPage(
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

class _StepsRunPage extends ConsumerStatefulWidget {
  const _StepsRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final StepsPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_StepsRunPage> createState() => _StepsRunPageState();
}

class _StepsRunPageState extends ConsumerState<_StepsRunPage> with DoDeathGuard, DoStrikeOut {
  final _scoreKey = GlobalKey();
  final OrderRun _run = OrderRun(permitStepRounds());
  late final List<List<StepCard>> _trays = [
    [...permitCards]..shuffle(widget.rng),
    [...clearCards]..shuffle(widget.rng),
  ];
  late final int _crew = 4 + widget.rng.nextInt(3);
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _okBag = LineBag(StepLines.ok);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  final List<String> _caught = [];

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;
  int _shakes = 0;
  String? _shook;
  var _between = false;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int? _mark;
  int _totalDelta = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  int get _shownRound => _between ? 0 : math.min(_run.round, 1);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  Future<void> _say(String line, {GuideMood mood = GuideMood.talk}) async {
    if (line.trim().isEmpty || !mounted) return;
    ref.read(guideDirectorProvider.notifier).say(mood: mood, line: line);
    await MascotSpeechLibrary.speak(line, muted: _muted);
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

  /// After the guide's intro: the clock runs and play begins.
  Future<void> _start() async {
    _clock.start();
  }

  void _tap(StepCard card, Offset origin) {
    if (_busy || _ended || _card != null || _between) return;
    final roundBefore = _run.round;
    final t = _run.tap(card.id);
    switch (t.kind) {
      case OrderTapKind.ignored:
        return;
      case OrderTapKind.mistake:
        final m = t.mistake!;
        setState(() {
          _shakes++;
          _shook = card.id;
        });
        if (m.deadly) {
          unawaited(_deadly(m));
        } else {
          unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
          unawaited(_slip(m));
        }
      case OrderTapKind.ok:
        HapticFeedback.lightImpact();
        if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.5, muted: false));
        if (card.id == StepIds.test && !_caught.contains(StepLines.caughtTest)) _caught.add(StepLines.caughtTest);
        if (card.id == StepIds.count && !_caught.contains(StepLines.caughtCount)) _caught.add(StepLines.caughtCount);
        unawaited(_levelDelta(t.roundDone ? 15 : 5, origin, mood: GuideMood.glad));
        if (t.allDone) {
          setState(() {});
          unawaited(_finish());
          return;
        }
        if (t.roundDone && roundBefore == 0) {
          setState(() => _between = true);
          unawaited(_sayChain([StepLines.permitDone], mood: GuideMood.glad));
          return;
        }
        setState(() {});
        unawaited(_sayChain([_okBag.next().shownBn], mood: GuideMood.glad));
    }
  }

  void _toClear() {
    if (!_between) return;
    setState(() => _between = false);
    unawaited(_sayChain([StepLines.askClear]));
  }

  /// The third small mistake: the level fails and the lesson card insists.
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    _hush();
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('steps/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/accident.wav', volume: 0.9, muted: false));
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('steps/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? StepLines.deadlyWord : StepLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
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
    await _say(!_run.passed ? StepLines.fail : (_quickBonus ? StepLines.quick : StepLines.allSet),
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

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final round = _shownRound;
    final cards = round == 0 ? permitCards : clearCards;
    final placed = _between ? [for (final c in permitCards) c.id] : [for (final c in cards) if (_run.isDone(c.id)) c.id];
    final order = round == 0 ? [for (final c in permitCards) c.id] : [for (final c in clearCards) c.id];
    final tray = [for (final c in _trays[round]) if (!placed.contains(c.id)) c];
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
                      labels: StepLines.rounds,
                      done: {if (_run.round >= 1) 0, if (_run.done) 1},
                      current: _run.done ? null : (_between ? null : _run.round),
                      quiet: quiet,
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                        children: [
                          for (var i = 0; i < order.length; i++)
                            StepSlot(
                              index: i,
                              card: placed.contains(order[i]) ? cards.firstWhere((c) => c.id == order[i]) : null,
                              note: order[i] == StepIds.count && placed.contains(StepIds.count) ? StepLines.headcount(_crew) : null,
                              quiet: quiet,
                            ),
                          const SizedBox(height: 10),
                          if (_mark == null && !_between)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (var i = 0; i < tray.length; i++)
                                  StepTrayCard(
                                    key: ValueKey('tray-${tray[i].id}-${_shook == tray[i].id ? _shakes : 0}'),
                                    card: tray[i],
                                    shake: _shook == tray[i].id,
                                    quiet: quiet,
                                    onTap: (o) => _tap(tray[i], o),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (_between)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: DoBigButton(label: StepLines.next, filled: true, onTapUp: (_) => _toClear()),
                        ),
                      ),
                    Opacity(opacity: _card == null ? 1 : 0, child: DoCoachStrip(tasks: StepLines.tasks, muted: _muted)),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$_shakes'),
                  mistake: _card!,
                  tone: _cardTone,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null
                      ? null
                      : () {
                          _hush();
                          unawaited(openLessonPoint(context, ref,
                              lessonId: widget.ctx.lessonId, point: _card!.lessonPoint, muted: _muted));
                        },
                  onGo: _cardGo,
                ),
              if (struckOut)
                StruckOutCard(
                  mistake: strikeOutBy!,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.paper,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_intro)
                LevelIntro(
                  lines: [StepLines.intro, StepLines.askPermit],
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    unawaited(_start());
                  },
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
// Pieces
// ============================================================================

/// A numbered place in the sequence: empty, or the step that belongs there.
class StepSlot extends StatelessWidget {
  const StepSlot({super.key, required this.index, required this.card, required this.note, required this.quiet});
  final int index;
  final StepCard? card;
  final String? note;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final c = card;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c != null ? const Color(0xFF2E8B45) : const Color(0x22FFFFFF),
            ),
            child: Text(enDigits('${index + 1}'), style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: quiet ? Duration.zero : const Duration(milliseconds: 260),
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c != null ? const Color(0xFFE9F6EC) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c != null ? const Color(0xFF2E8B45) : const Color(0x44FFFFFF), width: 1.4),
              ),
              child: c == null
                  ? const SizedBox()
                  : Row(
                      children: [
                        Icon(c.icon, size: 18, color: const Color(0xFF2E8B45)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.titleBn, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: SlmColors.ink)),
                              Text(note ?? c.subBn, style: bangla(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF3A4660))),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A step card waiting in the tray; shakes once when tapped out of turn.
class StepTrayCard extends StatelessWidget {
  const StepTrayCard({super.key, required this.card, required this.shake, required this.quiet, required this.onTap});
  final StepCard card;
  final bool shake;
  final bool quiet;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.sizeOf(context).width - 28 - 8) / 2;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: shake && !quiet ? 0 : 1, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (_, t, child) => Transform.translate(offset: Offset(math.sin(t * math.pi * 6) * 8 * (1 - t), 0), child: child),
      child: Semantics(
        button: true,
        label: card.titleBn,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => onTap(d.globalPosition),
          child: Container(
            width: w,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SlmColors.ivory,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Row(
              children: [
                Icon(card.icon, size: 22, color: const Color(0xFF8C6A2A)),
                const SizedBox(width: 8),
                Expanded(child: Text(card.titleBn, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ink))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
