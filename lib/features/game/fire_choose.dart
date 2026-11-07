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
import 'spoken_once.dart';

// Lesson 1.8, কাজ 1: "কোন আগুনে কী". Three fires in the substation yard, in
// random order: burning transformer oil (Class B), a sparking panel (Class
// C), dry grass under a pole (Class A). On the panel, first switch the power
// off (when safe). Then pick the tool — water bucket, DCP, CO2, sand bucket:
// oil → DCP / CO2 / sand; electrical → CO2 / DCP; grass → DCP / water. Pick
// up an extinguisher and read its gauge: one per play is empty (needle in
// the red). Once, someone says "ছোট আগুন, নিজেই নিভে যাবে".
//
// Deadly (owner-approved list): water on an oil or electrical fire. Slips:
// the wrong tool otherwise; skipping power-off on the panel; using an empty
// extinguisher; letting a small fire be.
//
// Voice: device TTS only. Art: assets/game/art/fire/ (hand-made SVG, no text
// inside); fires, transformer, panel and tools are drawn in code (static).

// ============================================================================
// Content
// ============================================================================

enum FireKind { oil, electrical, grass }

enum FireTool { water, dcp, co2, sand }

extension FireToolFacts on FireTool {
  bool get extinguisher => this == FireTool.dcp || this == FireTool.co2;
  bool fits(FireKind k) => switch (k) {
        FireKind.oil => this != FireTool.water,
        FireKind.electrical => this == FireTool.co2 || this == FireTool.dcp,
        FireKind.grass => this == FireTool.dcp || this == FireTool.water,
      };
}

@immutable
class FireDeal {
  const FireDeal({required this.fires, required this.empty, required this.pushRound, required this.tools});
  final List<FireKind> fires;

  /// The extinguisher whose gauge is in the red this play.
  final FireTool empty;
  final int pushRound;

  /// Tray order.
  final List<FireTool> tools;
}

FireDeal dealFires(math.Random rng) => FireDeal(
      fires: [...FireKind.values]..shuffle(rng),
      empty: rng.nextBool() ? FireTool.dcp : FireTool.co2,
      pushRound: rng.nextInt(3),
      tools: [...FireTool.values]..shuffle(rng),
    );

abstract final class FireLines {
  static const title = 'কোন আগুনে কী';
  static const intro = 'আগুন চিনুন, তারপর অস্ত্র — ভুল অস্ত্রে আগুন বাড়ে।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];
  static String scene(FireKind k) => switch (k) {
        FireKind.oil => 'ট্রান্সফরমারের তেলে আগুন',
        FireKind.electrical => 'প্যানেলে স্পার্ক, আগুন',
        FireKind.grass => 'পোলের নিচে শুকনো ঘাসে আগুন',
      };
  static const askPower = 'প্যানেলে আগুন — প্রথমে কী?';
  static const powerOff = 'নিরাপদ হলে আগে পাওয়ার বন্ধ';
  static const rushIn = 'সোজা নেভাতে যাই';
  static const askTool = 'কী দিয়ে নেভাবেন?';
  static String tool(FireTool t) => switch (t) {
        FireTool.water => 'জলের বালতি',
        FireTool.dcp => 'DCP',
        FireTool.co2 => 'CO2',
        FireTool.sand => 'বালির বালতি',
      };
  static const gaugeTitle = 'প্রেশার গেজ দেখুন';
  static const use = 'ব্যবহার করি';
  static const other = 'অন্যটা নিই';
  static const out = 'আগুন নিভল!';
  static const next = 'পরেরটা';
  static const finish = 'ফলাফল';
  static const pushWho = 'পাশের দোকানদার';
  static const pushLine = 'ছোট্ট আগুন — ছেড়ে দাও, একটু পরে নিজেই নিভে যাবে!';
  static const giveIn = 'ঠিক, অপেক্ষা করি';
  static const holdOut = 'না, এখনই নেভাই';
  static const callHeld = 'ঠিক! ছোট থাকতেই নেভান — কয়েক মিনিটে বড় হয়।';
  static const poweredOff = 'পাওয়ার বন্ধ — এবার নেভানো নিরাপদ।';
  static const ok = [FeedbackLine('ঠিক অস্ত্র!'), FeedbackLine('আগুন চিনেছেন।'), FeedbackLine('নিখুঁত!')];
  static const allSet = 'আগুন চেনা আর অস্ত্র বাছা — দুটোই পাকা!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — তেল আর বিদ্যুতে জল নয়।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtClass = 'আগুনের ধরন বুঝে অস্ত্র';
  static const caughtPower = 'প্যানেলে আগে পাওয়ার বন্ধ';
  static const caughtGauge = 'গেজ দেখে খালি সিলিন্ডার ধরেছেন';
  static const caughtCall = 'ছোট আগুনে দেরি নয়';
}

abstract final class FireMistakes {
  static const waterOil = DoMistake(
    key: '1.8/fire/water-oil',
    textBn: 'তেলের আগুনে জল — তেল জলে ভাসে, আগুন আরও ছড়ায়। DCP, CO2 বা বালি।',
    art: 'assets/game/art/fire/water_no.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const waterElectric = DoMistake(
    key: '1.8/fire/water-electric',
    textBn: 'বৈদ্যুতিক আগুনে জল — জল বিদ্যুৎ টানে, শক লাগবে। আগে পাওয়ার বন্ধ, তারপর CO2 বা DCP।',
    art: 'assets/game/art/fire/water_no.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const wrongTool = DoMistake(
    key: '1.8/fire/wrong-tool',
    textBn: 'এই আগুনে এটা ঠিক অস্ত্র নয় — তেল: DCP/CO2/বালি · বিদ্যুৎ: CO2/DCP · ঘাস-কাঠ: DCP বা জল।',
    art: 'assets/game/art/fire/fire_class.svg',
    lessonPoint: 2,
  );
  static const noPowerOff = DoMistake(
    key: '1.8/fire/no-power-off',
    textBn: 'বৈদ্যুতিক আগুনে প্রথম কাজ — নিরাপদ হলে পাওয়ার বন্ধ। তখন আগুন সাধারণ আগুনের মতো হয়ে যায়।',
    art: 'assets/game/art/fire/water_no.svg',
    lessonPoint: 1,
  );
  static const empty = DoMistake(
    key: '1.8/fire/empty',
    textBn: 'গেজের কাঁটা লাল দাগে — চাপ নেই, কাজ করবে না। ব্যবহারের আগে দেখুন কাঁটা সবুজে আছে কিনা।',
    art: 'assets/game/art/fire/gauge.svg',
    lessonPoint: 2,
  );
  static const waited = DoMistake(
    key: '1.8/fire/waited',
    textBn: 'ছোট আগুন নিজে থেকে নেভে না — কয়েক মিনিটে বড় আগুন। ছোট থাকতেই নেভান।',
    art: 'assets/game/art/fire/fire_class.svg',
    lessonPoint: 0,
  );
  static const all = [waterOil, waterElectric, wrongTool, noPowerOff, empty, waited];
}

enum FirePhase { power, tool, gauge, out }

/// The play state (pure logic).
class FireRun {
  FireRun(this.deal);
  final FireDeal deal;
  int round = 0;
  late FirePhase phase = _startPhase;
  FireTool? held;
  final Set<FireTool> spent = {};
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => round >= deal.fires.length;
  bool get ended => done || deadly != null;
  FireKind get current => deal.fires[round.clamp(0, deal.fires.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  FirePhase get _startPhase => current == FireKind.electrical ? FirePhase.power : FirePhase.tool;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Power off first (true) or rush in.
  DoMistake? power({required bool off}) {
    if (ended || phase != FirePhase.power) return null;
    phase = FirePhase.tool;
    if (!off) {
      slips++;
      return FireMistakes.noPowerOff;
    }
    _tag(FireLines.caughtPower);
    return null;
  }

  DoMistake? pick(FireTool t) {
    if (ended || phase != FirePhase.tool || spent.contains(t)) return null;
    final k = current;
    if (t == FireTool.water && k != FireKind.grass) {
      return deadly = k == FireKind.oil ? FireMistakes.waterOil : FireMistakes.waterElectric;
    }
    if (!t.fits(k)) {
      slips++;
      return FireMistakes.wrongTool;
    }
    if (t.extinguisher) {
      held = t;
      phase = FirePhase.gauge;
      return null;
    }
    phase = FirePhase.out;
    _tag(FireLines.caughtClass);
    return null;
  }

  /// After reading the gauge: use it (true) or put it back.
  DoMistake? useHeld({required bool use}) {
    final t = held;
    if (ended || phase != FirePhase.gauge || t == null) return null;
    held = null;
    final empty = t == deal.empty;
    if (!use) {
      phase = FirePhase.tool;
      if (empty) {
        spent.add(t);
        _tag(FireLines.caughtGauge);
      }
      return null;
    }
    if (empty) {
      spent.add(t);
      phase = FirePhase.tool;
      slips++;
      return FireMistakes.empty;
    }
    phase = FirePhase.out;
    _tag(FireLines.caughtClass);
    return null;
  }

  void next() {
    round++;
    held = null;
    if (!done) phase = _startPhase;
  }
}

@immutable
class FirePack {
  const FirePack({required this.id, required this.titleBn, this.quickMs = 50000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const firePack18 = FirePack(id: 'do_1_8_a', titleBn: FireLines.title);
const firePacks = {'do_1_8_a': firePack18};

// ============================================================================
// Page
// ============================================================================

class FireChoosePage extends StatefulWidget {
  const FireChoosePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final FirePack pack;
  final bool muted;
  final int? seed;

  @override
  State<FireChoosePage> createState() => _FireChoosePageState();
}

class _FireChoosePageState extends State<FireChoosePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _FireRunPage(
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

class _FireRunPage extends ConsumerStatefulWidget {
  const _FireRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final FirePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_FireRunPage> createState() => _FireRunPageState();
}

class _FireRunPageState extends ConsumerState<_FireRunPage> with DoDeathGuard {
  final _scoreKey = GlobalKey();
  late final FireRun _run = FireRun(dealFires(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _okBag = LineBag(FireLines.ok);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
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

  Future<void> _start() async {
    _clock.start();
    if (_maybeCall()) return;
    await _sayChain([FireLines.intro, _ask]);
  }

  String get _ask => _run.phase == FirePhase.power ? FireLines.askPower : FireLines.askTool;

  bool _maybeCall() {
    if (_callDone || _run.round != _run.deal.pushRound || _run.ended) return false;
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/customer.wav', volume: 0.6, muted: false));
    setState(() => _callOpen = true);
    unawaited(_say(FireLines.pushLine, other: true));
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
      _run.slips++;
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(FireMistakes.waited);
      return;
    }
    _run.caught.add(FireLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(_sayChain([FireLines.callHeld, _ask], mood: GuideMood.glad));
  }

  bool get _idle => !_busy && !_ended && !_callOpen && _card == null;

  Future<void> _power(bool off, Offset origin) async {
    if (!_idle) return;
    _hush();
    final m = _run.power(off: off);
    setState(() {});
    if (m != null) {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    HapticFeedback.lightImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.6, muted: false));
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(_sayChain([FireLines.poweredOff, FireLines.askTool], mood: GuideMood.glad));
  }

  Future<void> _pick(FireTool t, Offset origin) async {
    if (!_idle) return;
    _hush();
    final m = _run.pick(t);
    setState(() {});
    await _after(m, origin);
  }

  Future<void> _useHeld(bool use, Offset origin) async {
    if (!_idle) return;
    _hush();
    final m = _run.useHeld(use: use);
    setState(() {});
    if (!use && m == null) return;
    await _after(m, origin);
  }

  Future<void> _after(DoMistake? m, Offset origin) async {
    if (m == null) {
      if (_run.phase == FirePhase.out) {
        HapticFeedback.mediumImpact();
        if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
        unawaited(_levelDelta(15, origin, mood: GuideMood.glad));
        unawaited(_sayChain([FireLines.out, _okBag.next().shownBn], mood: GuideMood.glad));
      }
      return;
    }
    if (m.deadly) {
      await _deadly(m);
    } else {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
    }
  }

  void _next() {
    if (!_idle || _run.phase != FirePhase.out) return;
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {});
    if (!_maybeCall()) unawaited(_sayChain([_ask]));
  }

  Future<void> _slip(DoMistake m) async {
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('fire/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/accident.wav', volume: 0.9, muted: false));
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('fire/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? FireLines.deadlyWord : FireLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        unawaited(_sayChain([_ask]));
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
    await _say(!_run.passed ? FireLines.fail : (_quickBonus ? FireLines.quick : FireLines.allSet),
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
    final k = _run.current;
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
                      labels: FireLines.rounds,
                      done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
                      current: _run.done ? null : _run.round,
                      quiet: quiet,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: Text(FireLines.scene(k), style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.gold200)),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: 360,
                              height: 420,
                              child: Stack(
                                children: [
                                  Positioned.fill(child: SvgPicture.asset('assets/game/art/fire/yard.svg', fit: BoxFit.fill)),
                                  Positioned.fill(
                                    child: AnimatedSwitcher(
                                      duration: quiet ? Duration.zero : const Duration(milliseconds: 500),
                                      child: CustomPaint(
                                        key: ValueKey('fire-${_run.round}-${phase == FirePhase.out}-${phase == FirePhase.power}'),
                                        painter: FireScenePainter(kind: k, out: phase == FirePhase.out, powerOff: phase != FirePhase.power),
                                        size: const Size(360, 420),
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
                    if (_mark == null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                        child: switch (phase) {
                          FirePhase.power => Row(
                              children: [
                                Expanded(child: DoBigButton(label: FireLines.rushIn, filled: false, onDark: true, onTapUp: (d) => unawaited(_power(false, d.globalPosition)))),
                                const SizedBox(width: 10),
                                Expanded(child: DoBigButton(label: FireLines.powerOff, filled: true, onTapUp: (d) => unawaited(_power(true, d.globalPosition)))),
                              ],
                            ),
                          FirePhase.tool || FirePhase.gauge => SizedBox(
                              height: 104,
                              child: Row(
                                children: [
                                  for (final t in _run.deal.tools)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: _ToolCard(
                                          tool: t,
                                          spent: _run.spent.contains(t),
                                          onTap: (o) => unawaited(_pick(t, o)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          FirePhase.out => SizedBox(
                              width: double.infinity,
                              child: DoBigButton(
                                label: _run.round >= 2 ? FireLines.finish : FireLines.next,
                                filled: true,
                                onTapUp: (_) => _next(),
                              ),
                            ),
                        },
                      ),
                    Opacity(opacity: _card == null && !_callOpen && phase != FirePhase.gauge ? 1 : 0, child: const DoCoachStrip()),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              if (phase == FirePhase.gauge && _run.held != null)
                _GaugeCard(
                  key: ValueKey('gauge-${_run.held}'),
                  tool: _run.held!,
                  empty: _run.held == _run.deal.empty,
                  quiet: quiet,
                  onUse: (use, o) => unawaited(_useHeld(use, o)),
                ),
              if (_callOpen)
                DoCallCard(
                  caller: const DoCaller(id: 'shop', whoBn: FireLines.pushWho, lineBn: FireLines.pushLine, icon: Icons.storefront_rounded),
                  quiet: quiet,
                  rushBn: FireLines.giveIn,
                  holdBn: FireLines.holdOut,
                  onAnswer: (held, o) => unawaited(_answerCall(held, o)),
                ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.round}-${_run.slips}'),
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

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, required this.spent, required this.onTap});
  final FireTool tool;
  final bool spent;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: FireLines.tool(tool),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: spent ? null : (d) => onTap(d.globalPosition),
        child: Opacity(
          opacity: spent ? 0.35 : 1,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
            decoration: BoxDecoration(
              color: SlmColors.ivory,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Column(
              children: [
                Expanded(child: CustomPaint(painter: ToolIconPainter(tool), size: Size.infinite)),
                const SizedBox(height: 2),
                Text(FireLines.tool(tool),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: SlmColors.ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The picked-up extinguisher's pressure gauge: green = ready, red = empty.
class _GaugeCard extends StatelessWidget {
  const _GaugeCard({super.key, required this.tool, required this.empty, required this.quiet, required this.onUse});
  final FireTool tool;
  final bool empty;
  final bool quiet;
  final void Function(bool use, Offset origin) onUse;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xC0050A16),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder: (_, t, child) => Transform.scale(scale: 0.9 + 0.1 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(color: SlmColors.ivory, borderRadius: BorderRadius.circular(22)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${FireLines.tool(tool)} · ${FireLines.gaugeTitle}',
                      style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ink)),
                  const SizedBox(height: 10),
                  SizedBox(width: 170, height: 120, child: CustomPaint(painter: _GaugePainter(empty: empty))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: DoBigButton(label: FireLines.other, filled: false, onTapUp: (d) => onUse(false, d.globalPosition))),
                      const SizedBox(width: 10),
                      Expanded(child: DoBigButton(label: FireLines.use, filled: true, onTapUp: (d) => onUse(true, d.globalPosition))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.empty});
  final bool empty;

  @override
  void paint(Canvas c, Size s) {
    // A half dial that fits its box.
    final r = math.min(s.width * 0.42, s.height * 0.78);
    final centre = Offset(s.width / 2, s.height * 0.92);
    final face = Rect.fromCircle(center: centre, radius: r + 8);
    c.drawArc(face, math.pi, math.pi, true, Paint()..color = Colors.white);
    c.drawArc(
      face,
      math.pi,
      math.pi,
      true,
      Paint()
        ..color = const Color(0xFF31363C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    final rect = Rect.fromCircle(center: centre, radius: r);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    c.drawArc(rect, math.pi, math.pi * 0.38, false, arc..color = const Color(0xFFC0392B));
    c.drawArc(rect, math.pi * 1.38, math.pi * 0.24, false, arc..color = const Color(0xFF2E8B45));
    c.drawArc(rect, math.pi * 1.62, math.pi * 0.38, false, arc..color = const Color(0xFFC0392B));
    final a = empty ? math.pi * 1.12 : math.pi * 1.5;
    c.drawLine(centre, centre + Offset(math.cos(a), math.sin(a)) * (r - 8), Paint()..color = const Color(0xFF31363C)..strokeWidth = 4..strokeCap = StrokeCap.round);
    c.drawCircle(centre, 6, Paint()..color = const Color(0xFF31363C));
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.empty != empty;
}

/// A tool picture: water bucket, DCP / CO2 extinguisher, sand bucket.
class ToolIconPainter extends CustomPainter {
  ToolIconPainter(this.tool);
  final FireTool tool;

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final h = s.height;
    switch (tool) {
      case FireTool.water:
      case FireTool.sand:
        final body = Path()
          ..moveTo(cx - h * 0.32, h * 0.25)
          ..lineTo(cx + h * 0.32, h * 0.25)
          ..lineTo(cx + h * 0.24, h * 0.95)
          ..lineTo(cx - h * 0.24, h * 0.95)
          ..close();
        c.drawPath(body, Paint()..color = tool == FireTool.water ? const Color(0xFF8D949B) : const Color(0xFFC0392B));
        c.drawOval(Rect.fromCenter(center: Offset(cx, h * 0.25), width: h * 0.64, height: h * 0.14),
            Paint()..color = tool == FireTool.water ? const Color(0xFF5AA0D8) : const Color(0xFFD8B26A));
        c.drawArc(Rect.fromCenter(center: Offset(cx, h * 0.25), width: h * 0.7, height: h * 0.4), math.pi, math.pi, false,
            Paint()..color = const Color(0xFF3B3F45)..style = PaintingStyle.stroke..strokeWidth = 2);
      case FireTool.dcp:
      case FireTool.co2:
        final w = h * 0.3;
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - w / 2, h * 0.22, w, h * 0.74), Radius.circular(w * 0.4)), Paint()..color = const Color(0xFFC0392B));
        c.drawRect(Rect.fromLTWH(cx - w / 2, h * 0.45, w, h * 0.16), Paint()..color = tool == FireTool.dcp ? const Color(0xFF2F6FD0) : const Color(0xFF31363C));
        c.drawRect(Rect.fromLTWH(cx - w * 0.2, h * 0.08, w * 0.4, h * 0.16), Paint()..color = const Color(0xFF3B3F45));
        if (tool == FireTool.co2) {
          // CO2: a wide horn.
          c.drawPath(
            Path()
              ..moveTo(cx + w * 0.2, h * 0.14)
              ..lineTo(cx + w * 1.2, h * 0.24)
              ..lineTo(cx + w * 1.5, h * 0.12)
              ..lineTo(cx + w * 1.4, h * 0.36)
              ..close(),
            Paint()..color = const Color(0xFF2B2F35),
          );
        } else {
          c.drawPath(
            Path()
              ..moveTo(cx + w * 0.2, h * 0.14)
              ..quadraticBezierTo(cx + w * 1.3, h * 0.12, cx + w * 1.2, h * 0.5),
            Paint()
              ..color = const Color(0xFF2B2F35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
        }
    }
  }

  @override
  bool shouldRepaint(ToolIconPainter old) => old.tool != tool;
}

/// The fire scene in the yard (360 x 420): transformer with burning oil,
/// a sparking panel, or dry grass under a pole; flames are still shapes (no
/// loop); after it is out, grey smoke.
class FireScenePainter extends CustomPainter {
  FireScenePainter({required this.kind, required this.out, this.powerOff = true});
  final FireKind kind;
  final bool out;

  /// The panel's power is off (no spark).
  final bool powerOff;

  static void flame(Canvas c, Offset base, double s) {
    final outer = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(base.dx - 22 * s, base.dy - 10 * s, base.dx - 18 * s, base.dy - 40 * s, base.dx - 4 * s, base.dy - 56 * s)
      ..cubicTo(base.dx - 6 * s, base.dy - 38 * s, base.dx + 8 * s, base.dy - 36 * s, base.dx + 6 * s, base.dy - 52 * s)
      ..cubicTo(base.dx + 22 * s, base.dy - 36 * s, base.dx + 24 * s, base.dy - 10 * s, base.dx, base.dy)
      ..close();
    c.drawPath(outer, Paint()..color = const Color(0xFFF05A28));
    final inner = Path()
      ..moveTo(base.dx, base.dy - 2 * s)
      ..cubicTo(base.dx - 12 * s, base.dy - 8 * s, base.dx - 10 * s, base.dy - 26 * s, base.dx - 2 * s, base.dy - 36 * s)
      ..cubicTo(base.dx, base.dy - 26 * s, base.dx + 8 * s, base.dy - 26 * s, base.dx + 6 * s, base.dy - 34 * s)
      ..cubicTo(base.dx + 14 * s, base.dy - 22 * s, base.dx + 12 * s, base.dy - 8 * s, base.dx, base.dy - 2 * s)
      ..close();
    c.drawPath(inner, Paint()..color = const Color(0xFFFFD21F));
  }

  static void smoke(Canvas c, Offset base) {
    final p = Paint()..color = const Color(0x998D949B);
    c.drawCircle(base.translate(-10, -20), 14, p);
    c.drawCircle(base.translate(8, -38), 18, p);
    c.drawCircle(base.translate(-4, -62), 22, p);
  }

  /// Where the fire's base is (for aiming).
  static Offset baseOf(FireKind k) => switch (k) {
        FireKind.oil => const Offset(200, 298),
        FireKind.electrical => const Offset(180, 250),
        FireKind.grass => const Offset(170, 300),
      };

  @override
  void paint(Canvas c, Size s) {
    switch (kind) {
      case FireKind.oil:
        // Transformer: tank, radiator fins, bushings, plinth, oil pool.
        c.drawRect(const Rect.fromLTRB(140, 286, 270, 300), Paint()..color = const Color(0xFF9D9A90));
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(160, 180, 250, 286), const Radius.circular(6)), Paint()..color = const Color(0xFF7F8A84));
        final fin = Paint()..color = const Color(0xFF6B756F);
        for (var x = 254.0; x < 270; x += 5) {
          c.drawRect(Rect.fromLTWH(x, 196, 3, 80), fin);
        }
        final bush = Paint()..color = const Color(0xFFB98B54);
        for (final x in const [176.0, 205.0, 234.0]) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 5, 150, 10, 32), const Radius.circular(4)), bush);
        }
        c.drawOval(const Rect.fromLTRB(120, 292, 290, 310), Paint()..color = const Color(0xFF2B1D0E));
        if (out) {
          smoke(c, const Offset(200, 296));
        } else {
          for (final (x, sc) in const [(140.0, 0.8), (170.0, 1.1), (205.0, 1.3), (240.0, 1.0), (272.0, 0.7)]) {
            flame(c, Offset(x, 302), sc);
          }
        }
      case FireKind.electrical:
        // Feeder pillar / panel with its door open.
        c.drawRect(const Rect.fromLTRB(120, 290, 240, 300), Paint()..color = const Color(0xFF9D9A90));
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(130, 170, 230, 292), const Radius.circular(4)), Paint()..color = const Color(0xFF8E979F));
        c.drawRect(const Rect.fromLTRB(140, 182, 220, 282), Paint()..color = const Color(0xFF2B2F35));
        c.drawPath(
          Path()
            ..moveTo(230, 172)
            ..lineTo(270, 186)
            ..lineTo(270, 296)
            ..lineTo(230, 290)
            ..close(),
          Paint()..color = const Color(0xFF9AA3AB),
        );
        final bus = Paint()
          ..color = const Color(0xFFB98B54)
          ..strokeWidth = 4;
        for (final y in const [200.0, 220.0, 240.0]) {
          c.drawLine(Offset(148, y), Offset(212, y), bus);
        }
        if (!out && !powerOff) {
          // Spark (power still on).
          final ray = Paint()
            ..color = const Color(0xFFFFD21F)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round;
          const sp = Offset(186, 222);
          for (var i = 0; i < 8; i++) {
            final a = i * math.pi / 4;
            c.drawLine(sp + Offset(math.cos(a), math.sin(a)) * 6, sp + Offset(math.cos(a), math.sin(a)) * 18, ray);
          }
        }
        if (out) {
          smoke(c, const Offset(180, 250));
        } else {
          flame(c, const Offset(166, 262), 0.9);
          flame(c, const Offset(192, 270), 1.2);
        }
      case FireKind.grass:
        // Pole with dry grass at its foot.
        c.drawRect(const Rect.fromLTRB(244, 60, 258, 300), Paint()..color = const Color(0xFFB9B6AD));
        c.drawRect(const Rect.fromLTRB(228, 74, 274, 80), Paint()..color = const Color(0xFF5F676F));
        final grass = Paint()
          ..color = const Color(0xFFC9A55A)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;
        final rnd = math.Random(5);
        for (var i = 0; i < 70; i++) {
          final x = 90 + rnd.nextDouble() * 200;
          c.drawLine(Offset(x, 300), Offset(x + (rnd.nextDouble() - 0.5) * 10, 300 - 10 - rnd.nextDouble() * 16), grass);
        }
        if (out) {
          c.drawOval(const Rect.fromLTRB(110, 292, 240, 306), Paint()..color = const Color(0xFF3B3326));
          smoke(c, const Offset(170, 296));
        } else {
          for (final (x, sc) in const [(120.0, 0.7), (150.0, 1.0), (180.0, 1.2), (212.0, 0.9)]) {
            flame(c, Offset(x, 302), sc);
          }
        }
    }
  }

  @override
  bool shouldRepaint(FireScenePainter old) => old.kind != kind || old.out != out || old.powerOff != powerOff;
}
