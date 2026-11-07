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

// Lesson 1.4, কাজ 2: "ফিটিং আর অ্যাঙ্কর". Three climbs. First the fit: a
// lineman in his harness, front and back — tap what is wrong (twisted strap,
// chest strap at the neck, loose leg strap, back D-ring low — seen from the
// back only), then check. Then the anchor: tap where the lanyard goes on the
// pole — only the sling around the pole body is a strong point. Once, a
// senior says "২০ বছর কাজ করছি, হারনেস লাগে না".
//
// Deadly (owner-approved list: weak anchor): a cracked cross-arm, an
// insulator pin or a cable clamp as the anchor; climbing without tying off.
// Slips: a fit fault missed; a strap marked that was fine.
//
// Voice: device TTS only. Art: assets/game/art/harness/ (hand-made SVG, no
// text inside); the lineman, harness and pole top are drawn in code.

// ============================================================================
// Content
// ============================================================================

enum FitFault { twisted, chestHigh, loose, dRingLow }

enum FitZone { shoulder, chest, leg, dRing }

extension FitFaultZone on FitFault {
  FitZone get zone => switch (this) {
        FitFault.twisted => FitZone.shoulder,
        FitFault.chestHigh => FitZone.chest,
        FitFault.loose => FitZone.leg,
        FitFault.dRingLow => FitZone.dRing,
      };
}

enum AnchorPoint { sling, crackedArm, insulatorPin, cableClamp }

@immutable
class ClimbRound {
  const ClimbRound({required this.faults, required this.anchors});
  final Set<FitFault> faults;

  /// Anchor points offered (the sling always; 2–3 weak ones).
  final List<AnchorPoint> anchors;
}

@immutable
class ClimbDeal {
  const ClimbDeal({required this.rounds, required this.pushRound});
  final List<ClimbRound> rounds;
  final int pushRound;
}

abstract final class FitLines {
  static const title = 'ফিটিং আর অ্যাঙ্কর';
  static const intro = 'হারনেস ঠিক, এবার ঠিকমতো পরা আর ঠিক জায়গায় অ্যাঙ্কর — দুটো ছাড়া হারনেস কাজ করে না।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];
  static const askFit = 'ফিটিং দেখুন — যা ঠিক নেই ট্যাপ করুন, তারপর যাচাই।';
  static const askAnchor = 'ল্যানিয়ার্ড কোথায় লাগাবেন? মজবুত জায়গা বেছে নিন।';
  static const front = 'সামনে';
  static const back = 'পেছনে';
  static const turn = 'ঘুরিয়ে দেখুন';
  static const check = 'যাচাই করুন';
  static const toAnchor = 'অ্যাঙ্কর করুন';
  static const next = 'পরের ওঠা';
  static const finish = 'ফলাফল';
  static const notOk = 'ঠিক নেই';
  static const fitScene = 'পোলের নিচে · হারনেস পরা';
  static const anchorScene = 'পোলের মাথায় · অ্যাঙ্কর';
  static String faultBn(FitFault f) => switch (f) {
        FitFault.twisted => 'ফিতে পেঁচানো',
        FitFault.chestHigh => 'বুকের ফিতে গলার কাছে',
        FitFault.loose => 'পায়ের ফিতে ঢিলে',
        FitFault.dRingLow => 'ডি-রিং নিচে',
      };
  static const pushWho = 'সিনিয়র লাইনম্যান';
  static const pushLine = '২০ বছর কাজ করছি, হারনেস-অ্যাঙ্কর কিছু লাগে না — সোজা উঠে যাও!';
  static const giveIn = 'ঠিক, এমনিই উঠি';
  static const holdOut = 'না, আগে অ্যাঙ্কর';
  static const callHeld = 'ঠিক! মাধ্যাকর্ষণ অভিজ্ঞতা মানে না।';
  static const fitOk = [FeedbackLine('ফিটিং ঠিক ধরেছেন!'), FeedbackLine('চোখ খোলা!'), FeedbackLine('নিখুঁত!')];
  static const anchorOk = 'মজবুত অ্যাঙ্কর — ল্যানিয়ার্ড লাগল।';
  static const allSet = 'ঠিক ফিটিং, মজবুত অ্যাঙ্কর — হারনেস এবার সত্যিই প্যারাশুট।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — চার আঙুল, বুকের মাঝ, কাঁধের মাঝ।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtFit = 'ফিটিংয়ের ভুল ধরেছেন';
  static const caughtBack = 'পেছন ঘুরে ডি-রিং দেখেছেন';
  static const caughtAnchor = 'মজবুত জায়গায় অ্যাঙ্কর';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class FitMistakes {
  static DoMistake missed(FitFault f) => switch (f) {
        FitFault.twisted => const DoMistake(
            key: '1.4/fit/twisted',
            textBn: 'কাঁধের ফিতে পেঁচানো — পড়লে চাপ ভুল জায়গায় পড়ে। ফিতে সোজা করে পরুন।',
            art: 'assets/game/art/harness/fit_check.svg',
            lessonPoint: 2),
        FitFault.chestHigh => const DoMistake(
            key: '1.4/fit/chest-high',
            textBn: 'বুকের ফিতে গলার কাছে — পড়লে গলায় চাপ। বুকের ফিতে থাকবে বুকের মাঝ বরাবর।',
            art: 'assets/game/art/harness/fit_check.svg',
            lessonPoint: 2),
        FitFault.loose => const DoMistake(
            key: '1.4/fit/loose',
            textBn: 'পায়ের ফিতে ঢিলে — চার আঙুলের বেশি ঢুকছে। পড়ার ঝাঁকুনিতে শরীর পিছলে বেরোতে পারে।',
            art: 'assets/game/art/harness/fit_check.svg',
            lessonPoint: 2),
        FitFault.dRingLow => const DoMistake(
            key: '1.4/fit/d-ring-low',
            textBn: 'পিঠের ডি-রিং নিচে নেমে গেছে — থাকবে দুই কাঁধের মাঝখানে। পেছনটাও দেখুন।',
            art: 'assets/game/art/harness/fit_check.svg',
            lessonPoint: 2),
      };
  static const falseMark = DoMistake(
    key: '1.4/fit/false-mark',
    textBn: 'এটা ঠিকই ছিল — বুকের মাঝ, চার আঙুল, কাঁধের মাঝে ডি-রিং মিলিয়ে দেখুন।',
    art: 'assets/game/art/harness/fit_check.svg',
    lessonPoint: 2,
  );
  static DoMistake anchor(AnchorPoint a) => switch (a) {
        AnchorPoint.crackedArm => const DoMistake(
            key: '1.4/anchor/cracked-arm',
            textBn: 'ফাটা ক্রস-আর্ম কখনো অ্যাঙ্কর নয় — পতনের ঝাঁকুনিতে ভেঙে আপনার সঙ্গেই নামবে।',
            art: 'assets/game/art/harness/anchor_strong.svg',
            deadly: true,
            lessonPoint: 3),
        AnchorPoint.insulatorPin => const DoMistake(
            key: '1.4/anchor/insulator-pin',
            textBn: 'ইনসুলেটর পিন অ্যাঙ্কর নয় — আপনার ওজনের বহু গুণ ভার নিতে পারে না।',
            art: 'assets/game/art/harness/anchor_strong.svg',
            deadly: true,
            lessonPoint: 3),
        AnchorPoint.cableClamp => const DoMistake(
            key: '1.4/anchor/cable-clamp',
            textBn: 'কেবলের ক্ল্যাম্প অ্যাঙ্কর নয় — পতনের ধাক্কায় খুলে যাবে।',
            art: 'assets/game/art/harness/anchor_strong.svg',
            deadly: true,
            lessonPoint: 3),
        AnchorPoint.sling => noTieOff,
      };
  static const noTieOff = DoMistake(
    key: '1.4/anchor/no-tie-off',
    textBn: 'অ্যাঙ্কর ছাড়া উঠলেন — একটা পিছলে যাওয়াই যথেষ্ট। অভিজ্ঞতা নয়, হারনেসই দ্বিতীয় সুযোগ।',
    art: 'assets/game/art/harness/no_tie_off.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static List<DoMistake> get all => [
        for (final f in FitFault.values) missed(f),
        falseMark,
        for (final a in AnchorPoint.values.skip(1)) anchor(a),
        noTieOff,
      ];
}

/// Three climbs: fit faults vary (one round may be clean; the D-ring fault
/// shows up at least once), the weak anchors vary; the push comes once.
ClimbDeal dealClimbs(math.Random rng) {
  final clean = rng.nextInt(3);
  final dRing = (clean + 1 + rng.nextInt(2)) % 3;
  final rounds = <ClimbRound>[];
  for (var i = 0; i < 3; i++) {
    final faults = <FitFault>{};
    if (i != clean) {
      if (i == dRing) faults.add(FitFault.dRingLow);
      final others = [FitFault.twisted, FitFault.chestHigh, FitFault.loose]..shuffle(rng);
      faults.add(others.first);
      if (faults.length < 2 && rng.nextBool()) faults.add(others[1]);
    }
    final weak = [AnchorPoint.crackedArm, AnchorPoint.insulatorPin, AnchorPoint.cableClamp]..shuffle(rng);
    rounds.add(ClimbRound(faults: faults, anchors: [AnchorPoint.sling, ...weak.take(2 + rng.nextInt(2))]));
  }
  return ClimbDeal(rounds: rounds, pushRound: rng.nextInt(3));
}

enum ClimbPhase { fit, fitShown, anchor, anchored }

@immutable
class FitCheck {
  const FitCheck({required this.missed, required this.falseMarks});
  final List<FitFault> missed;
  final List<FitZone> falseMarks;
}

/// The play state (pure logic).
class ClimbRun {
  ClimbRun(this.deal);
  final ClimbDeal deal;
  int round = 0;
  ClimbPhase phase = ClimbPhase.fit;
  int slips = 0;
  DoMistake? deadly;
  bool sawBack = false;
  final List<String> caught = [];

  bool get done => round >= deal.rounds.length;
  bool get ended => done || deadly != null;
  ClimbRound get current => deal.rounds[round.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  FitCheck checkFit(Set<FitZone> marked) {
    if (phase != ClimbPhase.fit || ended) return const FitCheck(missed: [], falseMarks: []);
    phase = ClimbPhase.fitShown;
    final faults = current.faults;
    final missed = [for (final f in faults) if (!marked.contains(f.zone)) f];
    final faultZones = {for (final f in faults) f.zone};
    final falseMarks = [for (final z in marked) if (!faultZones.contains(z)) z];
    slips += missed.length + falseMarks.length;
    if (faults.isNotEmpty && missed.isEmpty) _tag(FitLines.caughtFit);
    if (faults.contains(FitFault.dRingLow) && !missed.contains(FitFault.dRingLow)) _tag(FitLines.caughtBack);
    return FitCheck(missed: missed, falseMarks: falseMarks);
  }

  void toAnchor() {
    if (phase == ClimbPhase.fitShown) phase = ClimbPhase.anchor;
  }

  /// Ties off at [a]; null = strong point, else the deadly mistake.
  DoMistake? tieOff(AnchorPoint a) {
    if (phase != ClimbPhase.anchor || ended) return null;
    if (a != AnchorPoint.sling) return deadly = FitMistakes.anchor(a);
    phase = ClimbPhase.anchored;
    _tag(FitLines.caughtAnchor);
    return null;
  }

  /// Gave in to "হারনেস লাগে না".
  DoMistake noTieOff() => deadly = FitMistakes.noTieOff;

  void next() {
    round++;
    phase = ClimbPhase.fit;
    sawBack = false;
  }
}

@immutable
class FitPack {
  const FitPack({required this.id, required this.titleBn, this.quickMs = 90000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const fitPack14 = FitPack(id: 'do_1_4_b', titleBn: FitLines.title);
const fitPacks = {'do_1_4_b': fitPack14};

// ============================================================================
// Page
// ============================================================================

class HarnessFitPage extends StatefulWidget {
  const HarnessFitPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final FitPack pack;
  final bool muted;
  final int? seed;

  @override
  State<HarnessFitPage> createState() => _HarnessFitPageState();
}

class _HarnessFitPageState extends State<HarnessFitPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _FitRunPage(
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

class _FitRunPage extends ConsumerStatefulWidget {
  const _FitRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final FitPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_FitRunPage> createState() => _FitRunPageState();
}

class _FitRunPageState extends ConsumerState<_FitRunPage> with DoDeathGuard {
  final _scoreKey = GlobalKey();
  late final ClimbRun _run = ClimbRun(dealClimbs(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _fitBag = LineBag(FitLines.fitOk);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  int _chain = 0;
  var _back = false;
  final Set<FitZone> _marked = {};
  FitCheck? _fitShown;
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
    await _sayChain([FitLines.intro, FitLines.askFit]);
  }

  bool get _idle => !_busy && !_ended && !_callOpen && _card == null;

  void _turn() {
    if (!_idle || _run.phase != ClimbPhase.fit) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_in.wav', volume: 0.35, muted: false));
    setState(() {
      _back = !_back;
      if (_back) _run.sawBack = true;
    });
  }

  void _toggle(FitZone z) {
    if (!_idle || _run.phase != ClimbPhase.fit) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.45, muted: false));
    setState(() => _marked.contains(z) ? _marked.remove(z) : _marked.add(z));
  }

  Future<void> _checkFit(Offset origin) async {
    if (!_idle || _run.phase != ClimbPhase.fit) return;
    _hush();
    final c = _run.checkFit(_marked);
    setState(() => _fitShown = c);
    final caught = _run.current.faults.length - c.missed.length;
    final gain = 10 * caught + (c.missed.isEmpty && c.falseMarks.isEmpty ? 10 : 0) - 10 * (c.missed.length + c.falseMarks.length);
    if (gain != 0) unawaited(_levelDelta(gain, origin, mood: gain > 0 ? GuideMood.glad : GuideMood.warn));
    if (c.missed.isNotEmpty || c.falseMarks.isNotEmpty) {
      await Future<void>.delayed(MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 900));
      if (!mounted) return;
      await _slip(c.missed.isNotEmpty ? FitMistakes.missed(c.missed.first) : FitMistakes.falseMark);
    } else {
      HapticFeedback.lightImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      unawaited(_sayChain([_fitBag.next().shownBn], mood: GuideMood.glad));
    }
  }

  void _goAnchor() {
    if (!_idle || _run.phase != ClimbPhase.fitShown) return;
    _run.toAnchor();
    setState(() {
      _back = false;
      _fitShown = null;
    });
    if (!_callDone && _run.round == _run.deal.pushRound) {
      _hush();
      HapticFeedback.heavyImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/complaint.wav', volume: 0.8, muted: false));
      setState(() => _callOpen = true);
      unawaited(_say(FitLines.pushLine, other: true));
      return;
    }
    unawaited(_sayChain([FitLines.askAnchor]));
  }

  Future<void> _answerCall(bool held, Offset origin) async {
    if (!_callOpen) return;
    _hush();
    setState(() {
      _callOpen = false;
      _callDone = true;
    });
    if (!held) {
      await _deadly(_run.noTieOff());
      return;
    }
    _run.caught.add(FitLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(_sayChain([FitLines.callHeld, FitLines.askAnchor], mood: GuideMood.glad));
  }

  Future<void> _tieOff(AnchorPoint a, Offset origin) async {
    if (!_idle || _run.phase != ClimbPhase.anchor) return;
    _hush();
    final m = _run.tieOff(a);
    if (m != null) {
      await _deadly(m);
      return;
    }
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.6, muted: false));
    setState(() {});
    unawaited(_levelDelta(15, origin, mood: GuideMood.glad));
    unawaited(_sayChain([FitLines.anchorOk], mood: GuideMood.glad));
  }

  void _next() {
    if (!_idle || _run.phase != ClimbPhase.anchored) return;
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _marked.clear();
      _back = false;
      _fitShown = null;
    });
    unawaited(_sayChain([FitLines.askFit]));
  }

  Future<void> _slip(DoMistake m) async {
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('fit/${m.key}');
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
    final speak = await SpokenOnce.first('fit/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? FitLines.deadlyWord : FitLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
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
    await _say(!_run.passed ? FitLines.fail : (_quickBonus ? FitLines.quick : FitLines.allSet),
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
    final fitting = phase == ClimbPhase.fit || phase == ClimbPhase.fitShown;
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
                      labels: FitLines.rounds,
                      done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
                      current: _run.done ? null : _run.round,
                      quiet: quiet,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: Text(fitting ? FitLines.fitScene : FitLines.anchorScene,
                          style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.gold200)),
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
                              height: 480,
                              child: AnimatedSwitcher(
                                duration: quiet ? Duration.zero : const Duration(milliseconds: 360),
                                child: fitting
                                    ? _FitScene(
                                        key: ValueKey('fit-${_run.round}-$_back'),
                                        faults: r.faults,
                                        back: _back,
                                        marked: _marked,
                                        shown: _fitShown,
                                        onZone: _toggle,
                                        onTurn: _turn,
                                      )
                                    : _AnchorScene(
                                        key: ValueKey('anchor-${_run.round}'),
                                        anchors: r.anchors,
                                        tied: phase == ClimbPhase.anchored,
                                        quiet: quiet,
                                        onTap: (a, o) => unawaited(_tieOff(a, o)),
                                      ),
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
                        child: switch (phase) {
                          ClimbPhase.fit => DoBigButton(label: FitLines.check, filled: true, onTapUp: (d) => unawaited(_checkFit(d.globalPosition))),
                          ClimbPhase.fitShown => DoBigButton(label: FitLines.toAnchor, filled: true, onTapUp: (_) => _goAnchor()),
                          ClimbPhase.anchor => const SizedBox(height: 52),
                          ClimbPhase.anchored => DoBigButton(
                              label: _run.round >= _run.deal.rounds.length - 1 ? FitLines.finish : FitLines.next,
                              filled: true,
                              onTapUp: (_) => _next(),
                            ),
                        },
                      ),
                    ),
                    Opacity(opacity: _card == null && !_callOpen ? 1 : 0, child: const DoCoachStrip()),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              if (_callOpen)
                DoCallCard(
                  caller: const DoCaller(id: 'senior', whoBn: FitLines.pushWho, lineBn: FitLines.pushLine, icon: Icons.record_voice_over_rounded),
                  quiet: quiet,
                  rushBn: FitLines.giveIn,
                  holdBn: FitLines.holdOut,
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
// Scenes
// ============================================================================

/// The lineman in his harness, front or back; tap a strap to mark it.
class _FitScene extends StatelessWidget {
  const _FitScene({
    super.key,
    required this.faults,
    required this.back,
    required this.marked,
    required this.shown,
    required this.onZone,
    required this.onTurn,
  });
  final Set<FitFault> faults;
  final bool back;
  final Set<FitZone> marked;
  final FitCheck? shown;
  final ValueChanged<FitZone> onZone;
  final VoidCallback onTurn;

  static const zones = {
    FitZone.shoulder: Rect.fromLTRB(120, 116, 240, 170),
    FitZone.chest: Rect.fromLTRB(130, 172, 230, 226),
    FitZone.leg: Rect.fromLTRB(120, 290, 240, 360),
    FitZone.dRing: Rect.fromLTRB(140, 120, 220, 250),
  };

  @override
  Widget build(BuildContext context) {
    final visible = back ? const [FitZone.dRing] : const [FitZone.shoulder, FitZone.chest, FitZone.leg];
    return Stack(
      children: [
        Positioned.fill(child: SvgPicture.asset('assets/game/art/pole/village_road.svg', fit: BoxFit.fill)),
        Positioned.fill(child: CustomPaint(painter: _LinemanPainter(faults: faults, back: back))),
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(10)),
            child: Text(back ? FitLines.back : FitLines.front, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
          ),
        ),
        for (final z in visible) _zone(z),
        if (shown == null)
          Positioned(
            right: 10,
            bottom: 10,
            child: Semantics(
              button: true,
              label: FitLines.turn,
              child: GestureDetector(
                onTap: onTurn,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xE6122036),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.threesixty_rounded, size: 16, color: SlmColors.gold300),
                      const SizedBox(width: 5),
                      Text(FitLines.turn, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _zone(FitZone z) {
    final on = marked.contains(z);
    final s = shown;
    final fault = faults.where((f) => f.zone == z).firstOrNull;
    final verdict = s == null ? null : (fault != null) == on;
    return Positioned.fromRect(
      rect: zones[z]!,
      child: Semantics(
        button: true,
        label: 'ফিতে',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onZone(z),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (on)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SlmColors.danger, width: 3),
                      color: const Color(0x22C0392B),
                    ),
                  ),
                ),
              if (on && s == null)
                Positioned(
                  right: -6,
                  top: -10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(8)),
                    child: Text(FitLines.notOk, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              if (verdict != null && (fault != null || on))
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -12,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: verdict ? const Color(0xFF2E8B45) : SlmColors.danger,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        fault != null ? FitLines.faultBn(fault) : '✓',
                        style: bangla(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
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

/// A lineman (front or back) in a full body harness, with the fit faults.
class _LinemanPainter extends CustomPainter {
  _LinemanPainter({required this.faults, required this.back});
  final Set<FitFault> faults;
  final bool back;

  static const _web = Color(0xFFE67E22);
  static const _webDark = Color(0xFFB85C12);

  @override
  void paint(Canvas c, Size s) {
    const cx = 180.0;
    final body = Paint()..color = const Color(0xFF3F5E8C);
    final skin = Paint()..color = const Color(0xFFF0C9A0);
    // Legs, torso, arms, head.
    final leg = Paint()
      ..color = const Color(0xFF2F3B52)
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(cx - 22, 280), const Offset(cx - 26, 430), leg);
    c.drawLine(const Offset(cx + 22, 280), const Offset(cx + 26, 430), leg);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(cx - 48, 120, cx + 48, 290), const Radius.circular(24)), body);
    final arm = Paint()
      ..color = const Color(0xFF3F5E8C)
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(cx - 46, 134), const Offset(cx - 70, 260), arm);
    c.drawLine(const Offset(cx + 46, 134), const Offset(cx + 70, 260), arm);
    c.drawCircle(const Offset(cx - 70, 268), 10, skin);
    c.drawCircle(const Offset(cx + 70, 268), 10, skin);
    c.drawCircle(const Offset(cx, 92), 26, back ? (Paint()..color = const Color(0xFF3A2E24)) : skin);
    c.drawArc(Rect.fromCircle(center: const Offset(cx, 84), radius: 28), math.pi, math.pi, true, Paint()..color = const Color(0xFFF2B632));

    final strap = Paint()
      ..color = _web
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final edge = Paint()
      ..color = _webDark
      ..strokeWidth = 1.2;
    // Shoulder straps (one may be twisted).
    final twisted = faults.contains(FitFault.twisted) && !back;
    c.drawLine(const Offset(cx - 28, 118), const Offset(cx - 22, 290), strap);
    c.drawLine(const Offset(cx + 28, 118), const Offset(cx + 22, 290), strap);
    if (twisted) {
      // A half turn: the strap narrows and shows its darker back face.
      c.drawPath(
        Path()
          ..moveTo(cx + 21, 136)
          ..lineTo(cx + 34, 150)
          ..lineTo(cx + 22, 164)
          ..lineTo(cx + 33, 178)
          ..lineTo(cx + 21, 178)
          ..lineTo(cx + 30, 164)
          ..lineTo(cx + 20, 150)
          ..close(),
        Paint()..color = _webDark,
      );
    }
    if (!back) {
      // Chest strap: mid-chest, or up at the neck.
      final chestY = faults.contains(FitFault.chestHigh) ? 130.0 : 200.0;
      c.drawLine(Offset(cx - 30, chestY), Offset(cx + 30, chestY), strap);
      c.drawRect(Rect.fromCenter(center: Offset(cx, chestY), width: 18, height: 14), Paint()..color = const Color(0xFF2B2F35));
    }
    // Waist and leg loops.
    c.drawLine(const Offset(cx - 44, 286), const Offset(cx + 44, 286), strap);
    final loose = faults.contains(FitFault.loose) && !back;
    for (final side in const [-1.0, 1.0]) {
      final x = cx + 24 * side;
      final sag = loose && side > 0 ? 26.0 : 0.0;
      final loop = Path()
        ..moveTo(x - 16 * side, 290)
        ..quadraticBezierTo(x - 4 * side, 336 + sag, x + 18 * side + sag * side, 316 + sag * 0.4);
      c.drawPath(loop, Paint()
        ..color = _web
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round);
    }
    if (loose) {
      // A hand: far more than four fingers fit under the loose strap.
      final hand = Paint()..color = const Color(0xFFE8B98C);
      for (var i = 0; i < 5; i++) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 26 + i * 6.5, 318, 6, 22), const Radius.circular(3)), hand);
      }
    }
    if (back) {
      // Back D-ring: between the shoulder blades, or low near the waist.
      final y = faults.contains(FitFault.dRingLow) ? 236.0 : 142.0;
      c.drawLine(Offset(cx - 28, y + 8), Offset(cx + 28, y + 8), strap);
      c.drawPath(
        Path()
          ..moveTo(cx - 12, y + 12)
          ..quadraticBezierTo(cx - 12, y - 14, cx, y - 14)
          ..quadraticBezierTo(cx + 12, y - 14, cx + 12, y + 12),
        Paint()
          ..color = const Color(0xFF8D949B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
    }
    c.drawLine(const Offset(cx - 22, 118), const Offset(cx - 16, 290), edge);
  }

  @override
  bool shouldRepaint(_LinemanPainter old) => old.back != back || old.faults != faults;
}

/// The pole top from the climber's eye: sling around the pole (strong), and
/// the weak points dealt this round. After a strong tie-off the lanyard runs
/// to the sling ring.
class _AnchorScene extends StatelessWidget {
  const _AnchorScene({super.key, required this.anchors, required this.tied, required this.quiet, required this.onTap});
  final List<AnchorPoint> anchors;
  final bool tied;
  final bool quiet;
  final void Function(AnchorPoint a, Offset origin) onTap;

  static const spots = {
    AnchorPoint.sling: Rect.fromLTRB(140, 216, 236, 270),
    AnchorPoint.crackedArm: Rect.fromLTRB(250, 126, 330, 186),
    AnchorPoint.insulatorPin: Rect.fromLTRB(46, 96, 112, 160),
    AnchorPoint.cableClamp: Rect.fromLTRB(150, 300, 230, 350),
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: tied ? 1.0 : 0.0),
            duration: quiet ? Duration.zero : const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (_, t, _) => CustomPaint(painter: _PoleTopPainter(anchors: anchors, tie: t)),
          ),
        ),
        if (!tied)
          for (final a in anchors)
            Positioned.fromRect(
              rect: spots[a]!,
              child: Semantics(
                button: true,
                label: 'অ্যাঙ্কর',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => onTap(a, d.globalPosition),
                ),
              ),
            ),
      ],
    );
  }
}

class _PoleTopPainter extends CustomPainter {
  _PoleTopPainter({required this.anchors, required this.tie});
  final List<AnchorPoint> anchors;
  final double tie;

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFBCD6EA));
    const cx = 180.0;
    // Pole body.
    c.drawRect(const Rect.fromLTRB(cx - 20, 40, cx + 20, 480), Paint()..color = const Color(0xFFBDBAB1));
    c.drawRect(
      const Rect.fromLTRB(cx - 20, 40, cx + 20, 480),
      Paint()
        ..color = const Color(0xFF6E6B63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // Cross-arm (cracked and sagging on the right if dealt).
    final cracked = anchors.contains(AnchorPoint.crackedArm);
    final arm = Paint()
      ..color = const Color(0xFF5F676F)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(40, 150), const Offset(cx, 150), arm);
    if (cracked) {
      c.drawLine(const Offset(cx, 150), const Offset(268, 152), arm);
      c.drawLine(const Offset(268, 152), const Offset(320, 172), arm);
      c.drawPath(
        Path()
          ..moveTo(262, 144)
          ..lineTo(270, 152)
          ..lineTo(264, 158),
        Paint()
          ..color = const Color(0xFF2B2F35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    } else {
      c.drawLine(const Offset(cx, 150), const Offset(320, 150), arm);
    }
    // Insulators on pins.
    final ins = Paint()..color = const Color(0xFFE9E6DF);
    final pin = Paint()
      ..color = const Color(0xFF8D949B)
      ..strokeWidth = 4;
    for (final x in const [70.0, 300.0]) {
      // On a cracked arm the right end sags: the insulator sits on the sag.
      final base = x > 200 && cracked ? 164.0 : 144.0;
      c.drawLine(Offset(x, base), Offset(x, base - 14), pin);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, base - 26), width: 22, height: 22), const Radius.circular(5)), ins);
    }
    // Wires.
    final wire = Paint()
      ..color = const Color(0xFF2A2F35)
      ..strokeWidth = 2;
    c.drawLine(const Offset(0, 112), const Offset(360, 114), wire);
    // The sling around the pole with its D-ring.
    c.drawRect(const Rect.fromLTRB(cx - 22, 232, cx + 22, 244), Paint()..color = const Color(0xFFE67E22));
    c.drawPath(
      Path()
        ..moveTo(cx + 22, 236)
        ..quadraticBezierTo(cx + 44, 236, cx + 44, 252)
        ..quadraticBezierTo(cx + 44, 266, cx + 26, 262),
      Paint()
        ..color = const Color(0xFF8D949B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    // Cable clamp with black service cables.
    if (anchors.contains(AnchorPoint.cableClamp)) {
      c.drawRect(const Rect.fromLTRB(cx - 22, 318, cx + 22, 330), Paint()..color = const Color(0xFF6B747C));
      final cable = Paint()
        ..color = const Color(0xFF1E2228)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      c.drawPath(Path()..moveTo(cx + 22, 324)..quadraticBezierTo(280, 330, 360, 300), cable);
      c.drawPath(Path()..moveTo(cx + 22, 328)..quadraticBezierTo(290, 344, 360, 320), cable);
    }
    // The climber's hand with the lanyard; after the tie-off it runs to the ring.
    final hand = const Offset(cx - 60, 470);
    final ring = const Offset(cx + 40, 262);
    final end = Offset.lerp(const Offset(cx - 40, 420), ring, tie)!;
    c.drawPath(
      Path()
        ..moveTo(hand.dx, hand.dy)
        ..quadraticBezierTo(cx - 70, 380, end.dx, end.dy),
      Paint()
        ..color = const Color(0xFF3B6EA8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    c.drawCircle(end, 7, Paint()..color = const Color(0xFF8D949B));
    c.drawCircle(hand, 14, Paint()..color = const Color(0xFFF0C9A0));
  }

  @override
  bool shouldRepaint(_PoleTopPainter old) => old.tie != tie || old.anchors != anchors;
}
