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
import 'level_frame.dart';
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'rod_pick.dart' show RodRating, RodRatingText;
import 'spoken_once.dart';

// Lesson 1.2, কাজ 1: "কতটা দূরে?". A street seen from the side under a live
// line: people on a ladder, on a roof, with a long pole, a truck's boom. Tap
// everyone inside the line's লক্ষ্মণ রেখা (judge it with the man-height
// ruler hanging from the wire), then check: the danger band lights up and
// shows who was really inside. Three streets: LT dry; 11/33 kV dry with a
// long tool whose tip is inside; 11 kV in rain, where the distance grows.
//
// Deadly (owner-approved list): someone left inside the distance. Slip: a
// person stopped who was outside.
//
// Voice: device TTS only. Art: assets/game/art/distance/ (hand-made SVG, no
// text inside); the line, people and machines are drawn in code to scale.

// ============================================================================
// Content
// ============================================================================

enum ReachKind { ladder, roof, pole, boom }

/// One figure in the street: what it is and how far its highest point
/// (hand or tool tip) is below the wire, in metres.
@immutable
class StreetFigure {
  const StreetFigure({required this.id, required this.kind, required this.gapM});
  final String id;
  final ReachKind kind;
  final double gapM;
  bool get tool => kind == ReachKind.pole || kind == ReachKind.boom;
}

@immutable
class StreetRound {
  const StreetRound({required this.line, required this.rain, required this.placeBn, required this.figures});
  final RodRating line;
  final bool rain;
  final String placeBn;
  final List<StreetFigure> figures;

  /// The লক্ষ্মণ রেখা in metres (lesson 1.2: LT 1.2 · 11 kV 2.5 · 33 kV 3.0;
  /// in rain 11 kV keeps 10–12 ft, taken as 3.5 m).
  double get distanceM => distanceFor(line, rain: rain);
  bool inside(StreetFigure f) => f.gapM < distanceM;
}

double distanceFor(RodRating line, {bool rain = false}) => switch (line) {
      RodRating.lt => rain ? 1.8 : 1.2,
      RodRating.kv11 => rain ? 3.5 : 2.5,
      RodRating.kv33 => rain ? 4.0 : 3.0,
    };

abstract final class DistanceLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask];

  static const title = 'কতটা দূরে?';
  static const intro = 'ছুঁতে হয় না — কাছে গেলেই বিদ্যুৎ লাফায়। লক্ষ্মণ রেখার ভেতরে কে কে আছে, থামান।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];
  static const ask = 'লক্ষ্মণ রেখার ভেতরে কে কে? ট্যাপ করে থামান।';
  static const ruler = 'মাপকাঠি: একজন মানুষ প্রায় 5.5 ফুট';
  static const check = 'যাচাই করুন';
  static const next = 'পরের রাস্তা';
  static const finish = 'ফলাফল';
  static const stop = 'থামুন';
  static const rain = 'বৃষ্টি';
  static const places = ['বাজারের রাস্তা', 'স্কুলের সামনে', 'নতুন বাড়ির গলি', 'হাটের মোড়', 'মন্দিরের পাশের রাস্তা'];
  static String scene(StreetRound r) => '${r.placeBn} · ${r.line.lineBn} লাইন${r.rain ? ' · $rain' : ''}';
  static String band(StreetRound r) => switch ((r.line, r.rain)) {
        (RodRating.lt, false) => 'এলটি: কমপক্ষে 1.2 মিটার (প্রায় 4 ফুট)',
        (RodRating.kv11, false) => '11 কেভি: কমপক্ষে 2.5 মিটার (প্রায় 8 ফুট)',
        (RodRating.kv33, false) => '33 কেভি: কমপক্ষে 3.0 মিটার (প্রায় 10 ফুট)',
        (RodRating.kv11, true) => 'বৃষ্টিতে 11 কেভি: 3.5 মিটার (প্রায় 11 ফুট)',
        (_, true) => 'বৃষ্টিতে দূরত্ব আরও বাড়ান',
      };
  static const clean = [FeedbackLine('ঠিক চোখ!'), FeedbackLine('নিখুঁত মাপ!'), FeedbackLine('সবাই নিরাপদ।')];
  static const allSet = 'চোখের মাপ পাকা! ভোল্টেজ আর আবহাওয়া — দুটোই দেখেছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — মাপকাঠি দিয়ে মেপে দেখুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtBody = 'রেখার ভেতরের মানুষ থামিয়েছেন';
  static const caughtTool = 'টুলের ডগাও ধরেছেন';
  static const caughtRain = 'বৃষ্টিতে দূরত্ব বাড়িয়েছেন';
}

abstract final class DistanceMistakes {
  static const insideMissed = DoMistake(
    key: '1.2/distance/inside-missed',
    textBn: 'লক্ষ্মণ রেখার ভেতরে ঢুকেছে — না ছুঁয়েও আর্ক ফ্ল্যাশ লাফিয়ে আসে। ভোল্টেজ দেখে দূরত্ব মাপুন।',
    art: 'assets/game/art/distance/arc_jump.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const toolTipMissed = DoMistake(
    key: '1.2/distance/tool-tip-missed',
    textBn: 'শরীর দূরে, কিন্তু লম্বা টুলের ডগা রেখার ভেতরে — টুলের ডগাও আপনার হাত।',
    art: 'assets/game/art/distance/tool_tip.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const rainMissed = DoMistake(
    key: '1.2/distance/rain-missed',
    textBn: 'বৃষ্টিতে বাতাস ভেজা — দূরত্ব বাড়াতে হয়। 11 কেভিতে 8 ফুট নয়, 10–12 ফুট।',
    art: 'assets/game/art/distance/rain_distance.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const falseStop = DoMistake(
    key: '1.2/distance/false-stop',
    textBn: 'এ তো নিরাপদ দূরত্বেই ছিল — মানুষের উচ্চতার মাপকাঠি দিয়ে দূরত্ব মেপে নিন।',
    art: 'assets/game/art/distance/man_ruler.svg',
    lessonPoint: 1,
  );
  static const all = [insideMissed, toolTipMissed, rainMissed, falseStop];
}

/// Scene scale: 40 px per metre, the wire 8.25 m up.
abstract final class StreetGeo {
  static const size = Size(360, 480);
  static const ppm = 40.0;
  static const groundY = 440.0;
  static const lineY = 110.0;
  static const lineM = (groundY - lineY) / ppm;
  static const slots = [118.0, 205.0, 292.0];
  static double y(double gapM) => lineY + gapM * ppm;
}

/// Largest gap below the wire each kind can show (so a roof stays a roof).
double _maxGap(ReachKind k) => switch (k) {
      ReachKind.ladder => StreetGeo.lineM - 3.0,
      ReachKind.roof => StreetGeo.lineM - 4.6,
      ReachKind.pole => StreetGeo.lineM - 3.5,
      ReachKind.boom => StreetGeo.lineM - 2.5,
    };

/// A fresh street each play: places, kinds, gaps and slots vary.
List<StreetRound> dealStreets(math.Random rng) {
  var n = 0;
  double u(double a, double b) => a + rng.nextDouble() * (b - a);
  StreetFigure fig(ReachKind k, double gap) => StreetFigure(id: 'f${n++}', kind: k, gapM: gap.clamp(0.3, _maxGap(k)));
  ReachKind pick(List<ReachKind> from, double needGap) {
    final ok = [for (final k in from) if (_maxGap(k) >= needGap) k];
    return ok[rng.nextInt(ok.length)];
  }

  final places = [...DistanceLines.places]..shuffle(rng);
  List<StreetFigure> spread(List<StreetFigure> f) => f..shuffle(rng);

  // 1: LT, dry — one in, one out, one either.
  const d1 = 1.2;
  final k1 = [...ReachKind.values]..shuffle(rng);
  final g1out = d1 + u(0.8, 1.6);
  final g1in = d1 * u(0.3, 0.7);
  final r1 = [
    fig(k1[0], g1in),
    fig(pick(k1.sublist(1), g1out), g1out),
    rng.nextBool() ? fig(k1[2], d1 * u(0.3, 0.7)) : fig(pick([ReachKind.ladder, ReachKind.boom, ReachKind.pole], d1 + 1.0), d1 + u(0.9, 1.6)),
  ];

  // 2: 11 or 33 kV, dry — a long tool's tip inside while its holder is far below.
  final line2 = rng.nextBool() ? RodRating.kv11 : RodRating.kv33;
  final d2 = distanceFor(line2);
  final tool = rng.nextBool() ? ReachKind.pole : ReachKind.boom;
  final g2out = d2 + u(0.8, 1.3);
  final r2 = [
    fig(tool, d2 * u(0.35, 0.7)),
    fig(pick([ReachKind.ladder, ReachKind.roof], g2out), g2out),
    rng.nextBool() ? fig(ReachKind.ladder, d2 * u(0.3, 0.6)) : fig(pick([ReachKind.ladder, ReachKind.boom], d2 + 1.0), d2 + u(0.9, 1.4)),
  ];

  // 3: 11 kV in rain — one figure safe on a dry day is inside now.
  final r3 = [
    fig(rng.nextBool() ? ReachKind.ladder : ReachKind.roof, u(2.8, 3.2)),
    fig(pick([ReachKind.ladder, ReachKind.pole, ReachKind.boom], 4.2), u(4.2, 4.7)),
    fig(rng.nextBool() ? ReachKind.boom : ReachKind.pole, u(1.0, 2.0)),
  ];

  return [
    StreetRound(line: RodRating.lt, rain: false, placeBn: places[0], figures: spread(r1)),
    StreetRound(line: line2, rain: false, placeBn: places[1], figures: spread(r2)),
    StreetRound(line: RodRating.kv11, rain: true, placeBn: places[2], figures: spread(r3)),
  ];
}

@immutable
class StreetCheck {
  const StreetCheck({required this.caught, required this.falseStops, this.deadly});
  final List<StreetFigure> caught;
  final List<StreetFigure> falseStops;
  final DoMistake? deadly;
}

/// The play state (pure logic).
class DistanceRun {
  DistanceRun(this.rounds);
  final List<StreetRound> rounds;
  int round = 0;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => round >= rounds.length;
  bool get ended => done || deadly != null;
  StreetRound get current => rounds[round.clamp(0, rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// Checks the marks on the current street (does not move on).
  StreetCheck check(Set<String> marked) {
    final r = current;
    final caughtNow = <StreetFigure>[];
    final wrong = <StreetFigure>[];
    DoMistake? fatal;
    for (final f in r.figures) {
      final inside = r.inside(f);
      final on = marked.contains(f.id);
      if (inside && on) caughtNow.add(f);
      if (!inside && on) wrong.add(f);
      if (inside && !on && fatal == null) {
        fatal = r.rain && f.gapM >= distanceFor(r.line)
            ? DistanceMistakes.rainMissed
            : (f.tool ? DistanceMistakes.toolTipMissed : DistanceMistakes.insideMissed);
      }
    }
    if (fatal != null) {
      deadly = fatal;
    } else {
      slips += wrong.length;
      for (final f in caughtNow) {
        final tag = r.rain && f.gapM >= distanceFor(r.line)
            ? DistanceLines.caughtRain
            : (f.tool ? DistanceLines.caughtTool : DistanceLines.caughtBody);
        if (!caught.contains(tag)) caught.add(tag);
      }
    }
    return StreetCheck(caught: caughtNow, falseStops: wrong, deadly: fatal);
  }

  void next() => round++;
}

@immutable
class DistancePack {
  const DistancePack({required this.id, required this.titleBn, this.quickMs = 60000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const distancePack12 = DistancePack(id: 'do_1_2_a', titleBn: DistanceLines.title);
const distancePacks = {'do_1_2_a': distancePack12};

// ============================================================================
// Page
// ============================================================================

class DistanceSpotPage extends StatefulWidget {
  const DistanceSpotPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final DistancePack pack;
  final bool muted;
  final int? seed;

  @override
  State<DistanceSpotPage> createState() => _DistanceSpotPageState();
}

class _DistanceSpotPageState extends State<DistanceSpotPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DistanceRunPage(
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

class _DistanceRunPage extends ConsumerStatefulWidget {
  const _DistanceRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final DistancePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DistanceRunPage> createState() => _DistanceRunPageState();
}

class _DistanceRunPageState extends ConsumerState<_DistanceRunPage> with DoDeathGuard, DoStrikeOut {
  final _scoreKey = GlobalKey();
  late final DistanceRun _run = DistanceRun(dealStreets(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _cleanBag = LineBag(DistanceLines.clean);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;
  final Set<String> _marked = {};
  StreetCheck? _shown;
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

  void _toggle(StreetFigure f) {
    if (_busy || _ended || _shown != null || _card != null) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.45, muted: false));
    setState(() => _marked.contains(f.id) ? _marked.remove(f.id) : _marked.add(f.id));
  }

  Future<void> _check(Offset origin) async {
    if (_busy || _ended || _shown != null || _card != null) return;
    _busy = true;
    _hush();
    final c = _run.check(_marked);
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/stomp.wav', volume: 0.5, muted: false));
    setState(() => _shown = c);
    final quiet = MediaQuery.disableAnimationsOf(context);
    if (c.deadly != null) {
      await Future<void>.delayed(quiet ? Duration.zero : const Duration(milliseconds: 1300));
      if (!mounted) return;
      await _deadly(c.deadly!);
      return;
    }
    final gain = 10 * c.caught.length + (c.falseStops.isEmpty ? 10 : 0) - 10 * c.falseStops.length;
    if (gain != 0) unawaited(_levelDelta(gain, origin, mood: gain > 0 ? GuideMood.glad : GuideMood.warn));
    _busy = false;
    if (c.falseStops.isNotEmpty) {
      HapticFeedback.heavyImpact();
      await Future<void>.delayed(quiet ? Duration.zero : const Duration(milliseconds: 900));
      if (!mounted) return;
      await _slip(DistanceMistakes.falseStop);
    } else {
      HapticFeedback.lightImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      unawaited(_sayChain([_cleanBag.next().shownBn], mood: GuideMood.glad));
    }
  }

  void _next() {
    if (_busy || _card != null || _shown == null) return;
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _shown = null;
      _marked.clear();
    });
    unawaited(_sayChain([DistanceLines.ask]));
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
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('distance/${m.key}');
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
    final speak = await SpokenOnce.first('distance/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? DistanceLines.deadlyWord : DistanceLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
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
    await _say(!_run.passed ? DistanceLines.fail : (_quickBonus ? DistanceLines.quick : DistanceLines.allSet),
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
    final shown = _shown;
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
                      labels: DistanceLines.rounds,
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
                              child: _StreetScene(
                                key: ValueKey('street-${_run.round}'),
                                round: r,
                                marked: _marked,
                                shown: shown,
                                quiet: quiet,
                                onTap: _toggle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: shown == null
                            ? DoBigButton(label: DistanceLines.check, filled: true, onTapUp: (d) => unawaited(_check(d.globalPosition)))
                            : DoBigButton(
                                label: _run.round >= _run.rounds.length - 1 ? DistanceLines.finish : DistanceLines.next,
                                filled: true,
                                onTapUp: (_) => _next(),
                              ),
                      ),
                    ),
                    Opacity(opacity: _card == null ? 1 : 0, child: DoCoachStrip(tasks: DistanceLines.tasks, muted: _muted)),
                    const SizedBox(height: 6),
                  ],
                ),
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
                  lines: [DistanceLines.intro, DistanceLines.ask],
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

/// The street: background art, the live wire, the man-height ruler, the
/// figures (drawn to scale), rain, and after "যাচাই" the danger band.
class _StreetScene extends StatelessWidget {
  const _StreetScene({super.key, required this.round, required this.marked, required this.shown, required this.quiet, required this.onTap});
  final StreetRound round;
  final Set<String> marked;
  final StreetCheck? shown;
  final bool quiet;
  final ValueChanged<StreetFigure> onTap;

  @override
  Widget build(BuildContext context) {
    final reveal = shown != null;
    final d = round.distanceM * StreetGeo.ppm;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(child: SvgPicture.asset('assets/game/art/distance/street_side.svg', fit: BoxFit.fill)),
        if (round.rain) const Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Color(0x40324A66)))),
        // The danger band, revealed after the check.
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
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _StreetPainter(round)))),
        Positioned(
          left: 18,
          top: 168,
          child: _Plate(text: round.line.tag),
        ),
        for (var i = 0; i < round.figures.length; i++) _figureTap(round.figures[i], StreetGeo.slots[i]),
        if (reveal)
          Positioned(
            left: 60,
            right: 8,
            // At the band's top edge, clear of the people below.
            top: math.max(4, StreetGeo.lineY - d + 4),
            child: Center(child: _BandLabel(text: DistanceLines.band(round))),
          ),
      ],
    );
  }

  Widget _figureTap(StreetFigure f, double x) {
    final top = StreetGeo.y(f.gapM) - 18;
    final on = marked.contains(f.id);
    final s = shown;
    final inside = round.inside(f);
    final verdict = s == null ? null : (inside == on);
    return Positioned(
      left: x - 40,
      top: top,
      width: 80,
      height: StreetGeo.groundY - top,
      child: Semantics(
        button: true,
        label: 'মানুষ',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(f),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              if (on)
                Positioned(
                  top: 6,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: SlmColors.danger, width: 3),
                      color: const Color(0x33C0392B),
                    ),
                  ),
                ),
              if (on)
                Positioned(
                  top: -14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pan_tool_rounded, size: 10, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(DistanceLines.stop, style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              if (verdict != null)
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: verdict ? const Color(0xFF2E8B45) : SlmColors.danger),
                    child: Icon(verdict ? Icons.check_rounded : Icons.close_rounded, size: 18, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
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

class _BandLabel extends StatelessWidget {
  const _BandLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
      );
}

/// The live wire and the man-height ruler hanging from it (two 1.7 m men,
/// head to toe) — shared by every street scene of lesson 1.2.
void paintWireAndRuler(Canvas canvas, Size size) {
  canvas.drawLine(
    const Offset(48, StreetGeo.lineY),
    Offset(size.width, StreetGeo.lineY + 2),
    Paint()
      ..color = const Color(0xFF2A2F35)
      ..strokeWidth = 3,
  );
  final ruler = Paint()..color = const Color(0x8C2E8B45);
  for (var i = 0; i < 2; i++) {
    final top = StreetGeo.lineY + 4 + i * 1.7 * StreetGeo.ppm;
    paintMan(canvas, Offset(66, top), 1.7 * StreetGeo.ppm - 4, ruler);
  }
  canvas.drawLine(const Offset(66, StreetGeo.lineY), const Offset(66, StreetGeo.lineY + 4), ruler..strokeWidth = 1.5);
}

/// A plain standing man, [h] px tall, top at [top] (silhouette).
void paintMan(Canvas c, Offset top, double h, Paint p) {
  final r = h * 0.09;
  c.drawCircle(top.translate(0, r), r, p);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(top.dx - r * 0.95, top.dy + r * 2.1, r * 1.9, h * 0.38), Radius.circular(r * 0.6)), p);
  c.drawRect(Rect.fromLTWH(top.dx - r * 0.9, top.dy + r * 2.1 + h * 0.36, r * 0.8, h * 0.42), p);
  c.drawRect(Rect.fromLTWH(top.dx + r * 0.1, top.dy + r * 2.1 + h * 0.36, r * 0.8, h * 0.42), p);
}

/// Wire, man-height ruler, figures and rain — all to scale (40 px per metre).
class _StreetPainter extends CustomPainter {
  _StreetPainter(this.round);
  final StreetRound round;

  static const _skin = Color(0xFFF0C9A0);
  static const _cloth = Color(0xFF3F5E8C);
  static const _ink = Color(0xFF3A2E24);

  @override
  void paint(Canvas canvas, Size size) {
    paintWireAndRuler(canvas, size);

    for (var i = 0; i < round.figures.length; i++) {
      _figure(canvas, round.figures[i], StreetGeo.slots[i]);
    }

    if (round.rain) {
      final drop = Paint()
        ..color = const Color(0x99B8CCE0)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      final rnd = math.Random(7);
      for (var i = 0; i < 90; i++) {
        final x = rnd.nextDouble() * size.width;
        final y = rnd.nextDouble() * size.height;
        canvas.drawLine(Offset(x, y), Offset(x - 3, y + 11), drop);
      }
    }
  }

  /// A person whose raised hand reaches [reach]; feet at [feetY].
  void _person(Canvas c, double x, double feetY, {Offset? hand}) {
    const h = 1.7 * StreetGeo.ppm;
    final head = Offset(x, feetY - h + 7);
    final body = Paint()..color = _cloth;
    final limb = Paint()
      ..color = _ink
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(x - 4, feetY - 28), Offset(x - 6, feetY), limb);
    c.drawLine(Offset(x + 4, feetY - 28), Offset(x + 6, feetY), limb);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 8, feetY - h + 15, 16, 30), const Radius.circular(5)), body);
    final shoulder = Offset(x + 6, feetY - h + 20);
    c.drawLine(shoulder, hand ?? Offset(x + 10, feetY - h + 42), limb..color = _skin);
    c.drawLine(Offset(x - 6, feetY - h + 20), Offset(x - 10, feetY - h + 42), limb);
    c.drawCircle(head, 7, Paint()..color = _skin);
    c.drawArc(Rect.fromCircle(center: head.translate(0, -2), radius: 8), math.pi, math.pi, true, Paint()..color = const Color(0xFFF2B632));
  }

  void _figure(Canvas c, StreetFigure f, double x) {
    final reach = StreetGeo.y(f.gapM);
    const g = StreetGeo.groundY;
    switch (f.kind) {
      case ReachKind.ladder:
        final topY = reach + 30;
        final rail = Paint()
          ..color = const Color(0xFF9AA3AB)
          ..strokeWidth = 3;
        final a0 = Offset(x - 22, g);
        final a1 = Offset(x - 4, topY);
        final b0 = Offset(x - 8, g);
        final b1 = Offset(x + 10, topY);
        c.drawLine(a0, a1, rail);
        c.drawLine(b0, b1, rail);
        for (var t = 0.08; t < 1; t += 0.11) {
          c.drawLine(Offset.lerp(a0, a1, t)!, Offset.lerp(b0, b1, t)!, rail..strokeWidth = 2);
        }
        // Standing on a rung: hand raised to the reach point.
        final feet = topY + 1.4 * StreetGeo.ppm;
        _person(c, x + 6, math.min(feet, g), hand: Offset(x + 14, reach));
      case ReachKind.roof:
        final roofY = reach + 2.1 * StreetGeo.ppm;
        c.drawRect(Rect.fromLTRB(x - 36, roofY, x + 36, g), Paint()..color = const Color(0xFFD8C7A2));
        c.drawRect(Rect.fromLTRB(x - 40, roofY - 5, x + 40, roofY + 2), Paint()..color = const Color(0xFF8D949B));
        for (var wy = roofY + 18; wy < g - 30; wy += 34) {
          c.drawRect(Rect.fromLTWH(x - 24, wy, 14, 14), Paint()..color = const Color(0xFF6F7F8F));
          c.drawRect(Rect.fromLTWH(x + 10, wy, 14, 14), Paint()..color = const Color(0xFF6F7F8F));
        }
        c.drawRect(Rect.fromLTWH(x - 8, g - 30, 16, 30), Paint()..color = const Color(0xFF7A5532));
        _person(c, x, roofY - 5, hand: Offset(x + 12, reach));
      case ReachKind.pole:
        const handY = g - 1.4 * StreetGeo.ppm;
        final hand = Offset(x + 10, handY);
        c.drawLine(
          hand,
          Offset(x + 22, reach),
          Paint()
            ..color = const Color(0xFFA9773A)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
        c.drawCircle(Offset(x + 22, reach), 4, Paint()..color = const Color(0xFF7A7F85));
        _person(c, x, g, hand: hand);
      case ReachKind.boom:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x - 38, g - 30, x + 30, g - 8), const Radius.circular(4)), Paint()..color = const Color(0xFFE0A33A));
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x + 10, g - 48, x + 36, g - 8), const Radius.circular(5)), Paint()..color = const Color(0xFFC77F22));
        c.drawRect(Rect.fromLTRB(x + 16, g - 44, x + 32, g - 32), Paint()..color = const Color(0xFFBFD7EA));
        final wheel = Paint()..color = const Color(0xFF2A2F35);
        c.drawCircle(Offset(x - 24, g - 6), 7, wheel);
        c.drawCircle(Offset(x + 22, g - 6), 7, wheel);
        final base = Offset(x - 20, g - 32);
        final tip = Offset(x - 4, reach);
        c.drawLine(
          base,
          tip,
          Paint()
            ..color = const Color(0xFFD9A441)
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round,
        );
        c.drawLine(tip, tip.translate(0, 14), Paint()..color = const Color(0xFF3B3F45)..strokeWidth = 1.5);
        c.drawCircle(tip.translate(0, 16), 3, Paint()..color = const Color(0xFF3B3F45));
    }
  }

  @override
  bool shouldRepaint(_StreetPainter old) => old.round != round;
}
