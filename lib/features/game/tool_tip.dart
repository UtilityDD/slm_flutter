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
import 'distance_spot.dart' show StreetGeo, distanceFor, paintWireAndRuler;
import 'do_parts.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'rod_pick.dart' show RodRating, RodRatingText;
import 'spoken_once.dart';

// Lesson 1.2, কাজ 2: "লম্বা টুলের ডগা". A kite is caught in a tree near a live
// line. First pick the tool: only the tested fibreglass hot stick (dry
// bamboo and the PVC pipe with a metal hook are not insulators you can
// trust). Then judge: if the kite is outside the লক্ষ্মণ রেখা, reach it — the
// tip stays outside; if it is inside, the tip would be inside too, so the only
// right answer is "শাটডাউন চাই". Once, a helper pushes "শুকনো বাঁশ তো, চলবে".
//
// Deadly (owner-approved list): bamboo / PVC near a live line; the tool tip
// inside the distance. Slip: asking for a shutdown that was not needed.
//
// Voice: device TTS only. The street art is shared with কাজ 1; tools, tree
// and kite are drawn in code to scale.

// ============================================================================
// Content
// ============================================================================

enum LongTool { hotStick, bamboo, pvc }

@immutable
class KiteRound {
  const KiteRound({required this.line, required this.gapM, required this.tools});
  final RodRating line;

  /// How far below the wire the kite hangs, in metres.
  final double gapM;

  /// Tray order for this round.
  final List<LongTool> tools;
  double get distanceM => distanceFor(line);
  bool get inside => gapM < distanceM;
}

@immutable
class KiteDeal {
  const KiteDeal({required this.rounds, required this.callRound});
  final List<KiteRound> rounds;

  /// The round whose tool choice the helper interrupts.
  final int callRound;
}

abstract final class ToolTipLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askTool, askReach];

  static const title = 'লম্বা টুলের ডগা';
  static const intro = 'লাইভ লাইনের পাশে গাছে ঘুড়ি আটকেছে। হাতে লম্বা টুল নিলে তার ডগাও আপনার হাত।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];
  static const askTool = 'কোন টুল নেবেন?';
  static const askReach = 'ডগা কি রেখার বাইরে থাকবে? সরাবেন, না শাটডাউন?';
  static const reach = 'ডগা দিয়ে সরাই';
  static const shutdown = 'শাটডাউন চাই';
  static const next = 'পরের কাজ';
  static const finish = 'ফলাফল';
  static const ruler = 'মাপকাঠি: একজন মানুষ প্রায় 5.5 ফুট';
  static String scene(KiteRound r) => '${r.line.lineBn} লাইন · গাছে আটকানো ঘুড়ি';
  static String band(KiteRound r) => switch (r.line) {
        RodRating.lt => 'এলটি: কমপক্ষে 1.2 মিটার (প্রায় 4 ফুট)',
        RodRating.kv11 => '11 কেভি: কমপক্ষে 2.5 মিটার (প্রায় 8 ফুট)',
        RodRating.kv33 => '33 কেভি: কমপক্ষে 3.0 মিটার (প্রায় 10 ফুট)',
      };
  static const helperWho = 'সাথী হেল্পার';
  static const helperLine = 'শুকনো বাঁশ তো, চলবে! হট স্টিক আনতে গাড়ি পর্যন্ত কে যাবে?';
  static const giveIn = 'ঠিক, বাঁশই নিই';
  static const holdOut = 'না, হট স্টিক আনি';
  static const callHeld = 'ঠিক! শুকনো বাঁশও বিদ্যুৎ টানে।';
  static const toolOk = [FeedbackLine('ফাইবারগ্লাস — ঠিক টুল।'), FeedbackLine('পরীক্ষিত হট স্টিক!'), FeedbackLine('এটাই।')];
  static const reachOk = 'ডগা রেখার বাইরে — ঘুড়ি নামল।';
  static const shutOk = 'ঠিক! রেখার ভেতরে কাজ মানেই লাইন বন্ধ চাই।';
  static const allSet = 'টুল আর ডগা — দুটোই রেখার নিয়মে!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ডগাও আপনার হাত।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtTool = 'বাঁশ / পিভিসি নয়, হট স্টিক';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static const caughtShut = 'রেখার ভেতরে কাজে শাটডাউন';
  static const caughtReach = 'ডগা রেখার বাইরে রেখেছেন';
}

abstract final class ToolTipMistakes {
  static const bamboo = DoMistake(
    key: '1.2/tool/bamboo',
    textBn: 'শুকনো বাঁশ বা কাঠেও ভেতরের আর্দ্রতা আর বাইরের ময়লা বিদ্যুৎ টানে। লাইভ লাইনের কাছে শুধু পরীক্ষিত ফাইবারগ্লাস হট স্টিক।',
    art: 'assets/game/art/distance/bamboo_vs_hot_stick.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const pvc = DoMistake(
    key: '1.2/tool/pvc-jugaad',
    textBn: 'পিভিসি পাইপে মেটাল হুক — জুগাড়, হট স্টিক নয়। ফাটে, ভিজে লিক করে; প্লাস্টিক দেখে নিরাপদ ভাববেন না।',
    art: 'assets/game/art/rod/jugaad_vs_standard.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const tipInside = DoMistake(
    key: '1.2/tool/tip-inside',
    textBn: 'ঘুড়িটা লক্ষ্মণ রেখার ভেতরে — সরাতে গেলে টুলের ডগাও ভেতরে। এমন কাজে শাটডাউন চাই।',
    art: 'assets/game/art/distance/tool_tip.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const needlessShutdown = DoMistake(
    key: '1.2/tool/needless-shutdown',
    textBn: 'ঘুড়িটা রেখার বাইরেই ছিল — ডগাও বাইরে থাকত। মাপকাঠি দিয়ে মেপে তবে শাটডাউন চান।',
    art: 'assets/game/art/distance/man_ruler.svg',
    lessonPoint: 1,
  );
  static const all = [bamboo, pvc, tipInside, needlessShutdown];
}

/// Three kites: each voltage once, at least one inside and one outside.
KiteDeal dealKites(math.Random rng) {
  final lines = [...RodRating.values]..shuffle(rng);
  final insides = <bool>[true, false, rng.nextBool()]..shuffle(rng);
  double u(double a, double b) => a + rng.nextDouble() * (b - a);
  return KiteDeal(
    rounds: [
      for (var i = 0; i < 3; i++)
        KiteRound(
          line: lines[i],
          gapM: insides[i]
              ? distanceFor(lines[i]) * u(0.35, 0.72)
              : math.min(distanceFor(lines[i]) + u(0.8, 1.5), StreetGeo.lineM - 3.2),
          tools: [...LongTool.values]..shuffle(rng),
        ),
    ],
    callRound: rng.nextInt(3),
  );
}

enum KitePhase { tool, decide, shown }

/// The play state (pure logic).
class KiteRun {
  KiteRun(this.deal);
  final KiteDeal deal;
  int round = 0;
  KitePhase phase = KitePhase.tool;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The last decision: true = reached, false = asked for a shutdown.
  bool? reached;

  bool get done => round >= deal.rounds.length;
  bool get ended => done || deadly != null;
  KiteRound get current => deal.rounds[round.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// Picks a tool; null = right, else the deadly mistake.
  DoMistake? pickTool(LongTool t) {
    if (ended || phase != KitePhase.tool) return null;
    switch (t) {
      case LongTool.hotStick:
        phase = KitePhase.decide;
        if (!caught.contains(ToolTipLines.caughtTool)) caught.add(ToolTipLines.caughtTool);
        return null;
      case LongTool.bamboo:
        return deadly = ToolTipMistakes.bamboo;
      case LongTool.pvc:
        return deadly = ToolTipMistakes.pvc;
    }
  }

  /// Reach (true) or ask for a shutdown (false). Returns the mistake, if any.
  DoMistake? decide({required bool reach}) {
    if (ended || phase != KitePhase.decide) return null;
    reached = reach;
    phase = KitePhase.shown;
    final r = current;
    if (reach && r.inside) return deadly = ToolTipMistakes.tipInside;
    if (!reach && !r.inside) {
      slips++;
      return ToolTipMistakes.needlessShutdown;
    }
    final tag = reach ? ToolTipLines.caughtReach : ToolTipLines.caughtShut;
    if (!caught.contains(tag)) caught.add(tag);
    return null;
  }

  void next() {
    round++;
    phase = KitePhase.tool;
    reached = null;
  }
}

@immutable
class ToolTipPack {
  const ToolTipPack({required this.id, required this.titleBn, this.quickMs = 55000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const toolTipPack12 = ToolTipPack(id: 'do_1_2_b', titleBn: ToolTipLines.title);
const toolTipPacks = {'do_1_2_b': toolTipPack12};

// ============================================================================
// Page
// ============================================================================

class ToolTipPage extends StatefulWidget {
  const ToolTipPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final ToolTipPack pack;
  final bool muted;
  final int? seed;

  @override
  State<ToolTipPage> createState() => _ToolTipPageState();
}

class _ToolTipPageState extends State<ToolTipPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _ToolTipRun(
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

class _ToolTipRun extends ConsumerStatefulWidget {
  const _ToolTipRun({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final ToolTipPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_ToolTipRun> createState() => _ToolTipRunState();
}

class _ToolTipRunState extends ConsumerState<_ToolTipRun> with DoDeathGuard, DoStrikeOut {
  final _scoreKey = GlobalKey();
  late final KiteRun _run = KiteRun(dealKites(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _toolBag = LineBag(ToolTipLines.toolOk);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;
  var _callOpen = false;
  var _callDone = false;
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

  /// After the guide's intro: the clock runs and play begins.
  Future<void> _start() async {
    _clock.start();
    _maybeCall();
  }

  bool _maybeCall() {
    if (_callDone || _run.ended || _run.round != _run.deal.callRound || _run.phase != KitePhase.tool) return false;
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/complaint.wav', volume: 0.8, muted: false));
    setState(() => _callOpen = true);
    unawaited(_say(ToolTipLines.helperLine, other: true));
    return true;
  }

  Future<void> _answerCall(bool held, Offset origin) async {
    if (!_callOpen) return;
    _hush();
    setState(() {
      _callOpen = false;
      _callDone = true;
    });
    if (!held) {
      _run.deadly = ToolTipMistakes.bamboo;
      await _deadly(ToolTipMistakes.bamboo);
      return;
    }
    _run.caught.add(ToolTipLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await _sayChain([ToolTipLines.callHeld, ToolTipLines.askTool], mood: GuideMood.glad);
  }

  void _pickTool(LongTool t, Offset origin) {
    if (_busy || _ended || _callOpen || _card != null || _run.phase != KitePhase.tool) return;
    HapticFeedback.selectionClick();
    final m = _run.pickTool(t);
    if (m != null) {
      unawaited(_deadly(m));
      return;
    }
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.55, muted: false));
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    setState(() {});
    unawaited(_sayChain([_toolBag.next().shownBn, ToolTipLines.askReach], mood: GuideMood.glad));
  }

  Future<void> _decide(bool reach, Offset origin) async {
    if (_busy || _ended || _card != null || _run.phase != KitePhase.decide) return;
    _hush();
    final m = _run.decide(reach: reach);
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/stomp.wav', volume: 0.5, muted: false));
    setState(() {});
    final quiet = MediaQuery.disableAnimationsOf(context);
    if (m == null) {
      unawaited(_levelDelta(15, origin, mood: GuideMood.glad));
      unawaited(_sayChain([reach ? ToolTipLines.reachOk : ToolTipLines.shutOk], mood: GuideMood.glad));
      return;
    }
    _busy = true;
    await Future<void>.delayed(quiet ? Duration.zero : const Duration(milliseconds: 1100));
    _busy = false;
    if (!mounted) return;
    if (m.deadly) {
      await _deadly(m);
    } else {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
    }
  }

  void _next() {
    if (_busy || _card != null || _run.phase != KitePhase.shown) return;
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {});
    if (!_maybeCall()) unawaited(_sayChain([ToolTipLines.askTool]));
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
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('tooltip/${m.key}');
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
    final speak = await SpokenOnce.first('tooltip/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? ToolTipLines.deadlyWord : ToolTipLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
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
    await _say(!_run.passed ? ToolTipLines.fail : (_quickBonus ? ToolTipLines.quick : ToolTipLines.allSet),
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
    final r = _run.current;
    final phase = _run.phase;
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
                      labels: ToolTipLines.rounds,
                      done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
                      current: _run.done ? null : _run.round,
                      quiet: quiet,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox.fromSize(
                              size: StreetGeo.size,
                              child: _KiteScene(
                                key: ValueKey('kite-${_run.round}'),
                                round: r,
                                holding: phase != KitePhase.tool,
                                reached: _run.reached,
                                reveal: phase == KitePhase.shown,
                                quiet: quiet,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_mark == null)
                      SizedBox(
                        height: 92,
                        child: switch (phase) {
                          KitePhase.tool => _ToolTray(
                              key: ValueKey('tray-${_run.round}'),
                              tools: r.tools,
                              quiet: quiet,
                              onPick: _pickTool,
                            ),
                          KitePhase.decide => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                              child: Row(
                                children: [
                                  Expanded(child: DoBigButton(label: ToolTipLines.shutdown, filled: false, onDark: true, onTapUp: (d) => unawaited(_decide(false, d.globalPosition)))),
                                  const SizedBox(width: 12),
                                  Expanded(child: DoBigButton(label: ToolTipLines.reach, filled: true, onTapUp: (d) => unawaited(_decide(true, d.globalPosition)))),
                                ],
                              ),
                            ),
                          KitePhase.shown => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                              child: DoBigButton(
                                label: _run.round >= _run.deal.rounds.length - 1 ? ToolTipLines.finish : ToolTipLines.next,
                                filled: true,
                                onTapUp: (_) => _next(),
                              ),
                            ),
                        },
                      ),
                    Opacity(opacity: _card == null && !_callOpen ? 1 : 0, child: DoCoachStrip(tasks: ToolTipLines.tasks, muted: _muted)),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              if (_callOpen)
                DoCallCard(
                  caller: const DoCaller(id: 'helper', whoBn: ToolTipLines.helperWho, lineBn: ToolTipLines.helperLine, icon: Icons.engineering_rounded),
                  quiet: quiet,
                  rushBn: ToolTipLines.giveIn,
                  holdBn: ToolTipLines.holdOut,
                  onAnswer: (held, o) => unawaited(_answerCall(held, o)),
                ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.round}'),
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
                  sound: FailSound.electric,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_intro)
                LevelIntro(
                  lines: [ToolTipLines.intro, ToolTipLines.askTool],
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
                                caughtBn: _run.caught,
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
                                    lessonId: widget.ctx.lessonId, point: 2, muted: _muted)),
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

/// The three long tools as picture cards (no names: look at them).
class _ToolTray extends StatelessWidget {
  const _ToolTray({super.key, required this.tools, required this.quiet, required this.onPick});
  final List<LongTool> tools;
  final bool quiet;
  final void Function(LongTool t, Offset origin) onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var i = 0; i < tools.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: DoDealIn(
                  index: i,
                  quiet: quiet,
                  muted: true,
                  child: Semantics(
                    button: true,
                    label: 'টুল',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) => onPick(tools[i], d.globalPosition),
                      child: Container(
                        decoration: BoxDecoration(
                          color: SlmColors.ivory,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: CustomPaint(painter: _ToolPainter(tools[i]), size: Size.infinite),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A long tool lying diagonally on its card.
class _ToolPainter extends CustomPainter {
  _ToolPainter(this.tool);
  final LongTool tool;

  @override
  void paint(Canvas c, Size s) {
    final a = Offset(s.width * 0.1, s.height * 0.88);
    final b = Offset(s.width * 0.9, s.height * 0.14);
    Offset at(double t) => Offset.lerp(a, b, t)!;
    final t = math.max(5.0, s.height * 0.1);
    switch (tool) {
      case LongTool.hotStick:
        c.drawLine(a, b, Paint()..color = const Color(0xFFE9B949)..strokeWidth = t..strokeCap = StrokeCap.round);
        c.drawLine(a, at(0.18), Paint()..color = const Color(0xFF3B3F45)..strokeWidth = t * 1.25..strokeCap = StrokeCap.round);
        c.drawLine(at(0.3), at(0.34), Paint()..color = const Color(0xFFC0392B)..strokeWidth = t * 1.2);
        for (final u in const [0.5, 0.72]) {
          c.drawLine(at(u), at(u + 0.015), Paint()..color = const Color(0xFFB88A2A)..strokeWidth = t * 1.1);
        }
        // Test label.
        final mid = at(0.6);
        c.save();
        c.translate(mid.dx, mid.dy);
        c.rotate(math.atan2(b.dy - a.dy, b.dx - a.dx));
        c.drawRect(Rect.fromCenter(center: Offset.zero, width: t * 2.4, height: t * 0.9), Paint()..color = Colors.white);
        c.drawRect(
          Rect.fromCenter(center: Offset.zero, width: t * 2.4, height: t * 0.9),
          Paint()
            ..color = const Color(0xFF2E8B45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        c.restore();
        // Fitting at the head.
        c.drawCircle(b, t * 0.55, Paint()..color = const Color(0xFF9AA3AB));
      case LongTool.bamboo:
        c.drawLine(a, b, Paint()..color = const Color(0xFFC2A766)..strokeWidth = t * 1.1..strokeCap = StrokeCap.round);
        for (var u = 0.12; u < 0.95; u += 0.17) {
          final p = at(u);
          c.drawCircle(p, t * 0.62, Paint()..color = const Color(0xFF8A7536));
        }
        c.drawLine(at(0.4), at(0.4).translate(t, -t * 0.3), Paint()..color = const Color(0xFF7C8B3A)..strokeWidth = 2);
      case LongTool.pvc:
        // White pipe with a thin grey outline.
        c.drawLine(a, b, Paint()..color = const Color(0xFFA9A9A2)..strokeWidth = t + 2..strokeCap = StrokeCap.round);
        c.drawLine(a, b, Paint()..color = const Color(0xFFFAFAF6)..strokeWidth = t..strokeCap = StrokeCap.round);
        for (final u in const [0.35, 0.62]) {
          c.drawLine(at(u), at(u + 0.05), Paint()..color = const Color(0xFF222222)..strokeWidth = t * 1.15);
        }
        // Metal hook at the head.
        final hook = Path()
          ..moveTo(b.dx, b.dy)
          ..lineTo(b.dx + t * 0.6, b.dy - t * 0.8)
          ..quadraticBezierTo(b.dx + t * 1.6, b.dy - t * 1.4, b.dx + t * 1.4, b.dy - t * 0.2);
        c.drawPath(
          hook,
          Paint()
            ..color = const Color(0xFF7A7F85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = t * 0.45
            ..strokeCap = StrokeCap.round,
        );
    }
  }

  @override
  bool shouldRepaint(_ToolPainter old) => old.tool != tool;
}

/// The street with a tree and a kite caught near the wire; the lineman with
/// the hot stick; after the decision the danger band shows.
class _KiteScene extends StatelessWidget {
  const _KiteScene({super.key, required this.round, required this.holding, required this.reached, required this.reveal, required this.quiet});
  final KiteRound round;
  final bool holding;
  final bool? reached;
  final bool reveal;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final d = round.distanceM * StreetGeo.ppm;
    final kite = Offset(250, StreetGeo.y(round.gapM));
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(child: SvgPicture.asset('assets/game/art/distance/street_side.svg', fit: BoxFit.fill)),
        Positioned(
          left: 0,
          right: 0,
          top: StreetGeo.lineY - d,
          height: 2 * d,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: reveal ? 1 : 0,
              duration: quiet ? Duration.zero : const Duration(milliseconds: 500),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x33C0392B),
                  border: Border.symmetric(horizontal: BorderSide(color: SlmColors.danger.withValues(alpha: 0.9), width: 2)),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: reached == true ? 1.0 : 0.0),
            duration: quiet ? Duration.zero : const Duration(milliseconds: 650),
            curve: Curves.easeInOutCubic,
            builder: (_, t, _) => CustomPaint(
              painter: _KitePainter(round: round, kite: kite, holding: holding, reach: t, down: reached == true && !round.inside),
            ),
          ),
        ),
        Positioned(left: 18, top: 168, child: _Plate(text: round.line.tag)),
        if (reveal)
          Positioned(
            left: 60,
            right: 8,
            top: math.max(4, StreetGeo.lineY - d + 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(8)),
                child: Text(ToolTipLines.band(round), style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ),
        if (reveal && reached == false)
          Positioned(
            left: 96,
            top: 300,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: SlmColors.navy800, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_in_talk_rounded, size: 14, color: SlmColors.gold300),
                  const SizedBox(width: 4),
                  Text(ToolTipLines.shutdown, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(color: const Color(0xFFFFF6D6), border: Border.all(color: const Color(0xFFC0392B), width: 1)),
        child: Text(text, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF1E2228))),
      );
}

class _KitePainter extends CustomPainter {
  _KitePainter({required this.round, required this.kite, required this.holding, required this.reach, required this.down});
  final KiteRound round;
  final Offset kite;
  final bool holding;

  /// 0 = stick held ready, 1 = tip at the kite.
  final double reach;

  /// The kite came down (a safe reach).
  final bool down;

  @override
  void paint(Canvas c, Size size) {
    paintWireAndRuler(c, size);
    const g = StreetGeo.groundY;
    // The tree: trunk, crown, one branch reaching toward the wire.
    c.drawRect(const Rect.fromLTRB(296, 250, 312, g), Paint()..color = const Color(0xFF6E4724));
    c.drawCircle(const Offset(304, 250), 46, Paint()..color = const Color(0xFF4F7A3A));
    c.drawCircle(const Offset(280, 280), 30, Paint()..color = const Color(0xFF5E8A44));
    c.drawLine(const Offset(300, 230), kite.translate(8, 10), Paint()..color = const Color(0xFF6E4724)..strokeWidth = 5..strokeCap = StrokeCap.round);
    // The kite (falls to the ground after a safe reach).
    final k = down ? Offset.lerp(kite, const Offset(250, g - 14), reach)! : kite;
    final kp = Path()
      ..moveTo(k.dx, k.dy - 14)
      ..lineTo(k.dx + 10, k.dy)
      ..lineTo(k.dx, k.dy + 14)
      ..lineTo(k.dx - 10, k.dy)
      ..close();
    c.drawPath(kp, Paint()..color = const Color(0xFFE2463A));
    c.drawLine(Offset(k.dx, k.dy - 14), Offset(k.dx, k.dy + 14), Paint()..color = const Color(0xFF7A1F18)..strokeWidth = 1.2);
    c.drawLine(Offset(k.dx - 10, k.dy), Offset(k.dx + 10, k.dy), Paint()..color = const Color(0xFF7A1F18)..strokeWidth = 1.2);
    c.drawLine(Offset(k.dx, k.dy + 14), Offset(k.dx - 6, k.dy + 34), Paint()..color = const Color(0xFFE2463A)..strokeWidth = 1);

    // The lineman on the footpath.
    const x = 150.0;
    const h = 1.7 * StreetGeo.ppm;
    final limb = Paint()
      ..color = const Color(0xFF3A2E24)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(x - 4, g - 28), const Offset(x - 6, g), limb);
    c.drawLine(const Offset(x + 4, g - 28), const Offset(x + 6, g), limb);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(x - 8, g - h + 15, 16, 30), const Radius.circular(5)), Paint()..color = const Color(0xFF2F5F9E));
    final head = const Offset(x, g - h + 7);
    c.drawCircle(head, 7, Paint()..color = const Color(0xFFF0C9A0));
    c.drawArc(Rect.fromCircle(center: head.translate(0, -2), radius: 8), math.pi, math.pi, true, Paint()..color = const Color(0xFFF2B632));
    const hand = Offset(x + 10, g - 50);
    c.drawLine(const Offset(x + 6, g - h + 20), hand, limb..color = const Color(0xFFF0C9A0));
    if (!holding) return;
    // The hot stick: held ready (pointing up toward the tree), or reaching.
    final ready = hand + Offset.fromDirection(-1.1, 3.4 * StreetGeo.ppm);
    final tip = Offset.lerp(ready, kite, reach)!;
    c.drawLine(hand, tip, Paint()..color = const Color(0xFFE9B949)..strokeWidth = 5..strokeCap = StrokeCap.round);
    c.drawLine(hand, Offset.lerp(hand, tip, 0.14)!, Paint()..color = const Color(0xFF3B3F45)..strokeWidth = 6..strokeCap = StrokeCap.round);
    final g0 = Offset.lerp(hand, tip, 0.24)!;
    c.drawLine(g0, Offset.lerp(hand, tip, 0.27)!, Paint()..color = const Color(0xFFC0392B)..strokeWidth = 6);
    c.drawCircle(tip, 4, Paint()..color = const Color(0xFF9AA3AB));
  }

  @override
  bool shouldRepaint(_KitePainter old) =>
      old.reach != reach || old.holding != holding || old.round != round || old.down != down;
}
