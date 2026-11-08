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
import 'spoken_once.dart';

// Lesson 1.5, কাজ 1: "সঠিক রড". At the store before the job: read the docket's
// line voltage, pick the discharge rod whose label matches, hold it up and
// check it (cracked stick, cut cable, rusty clamp), and never take the PVC
// jugaad. Three dockets, easy to hard; on the last one no rod on the rack is
// right and the store-keeper says "নিয়ে যাও, চলবে" — the right move is to
// hold the job and tell the supervisor (lesson: মিল না থাকলে কাজ শুরু নয়).
//
// Deadly (owner-approved list): a rod rated below the line; the jugaad.
// Slips: a damaged rod; holding the job when the right rod was there.
//
// Voice: device TTS only (no recorded clips, owner's decision 2026-11-06).
// Art: assets/game/art/rod/ (hand-made SVG, no text inside); the rods are
// drawn in code so their rating, build and flaw can vary each play.

// ============================================================================
// Content
// ============================================================================

/// Line / rod voltage, weakest first.
enum RodRating { lt, kv11, kv33 }

extension RodRatingText on RodRating {
  /// The label printed on a rod.
  String get tag => switch (this) {
        RodRating.lt => 'LT 440V',
        RodRating.kv11 => '11 kV',
        RodRating.kv33 => '33 kV',
      };

  /// The line as the docket names it.
  String get lineBn => switch (this) {
        RodRating.lt => 'এলটি 440 ভি',
        RodRating.kv11 => '11 কেভি',
        RodRating.kv33 => '33 কেভি',
      };
}

enum RodFlaw { none, crack, cable, clamp }

@immutable
class RodItem {
  const RodItem({required this.id, this.rating, this.flaw = RodFlaw.none});
  final String id;

  /// Null: the PVC jugaad (no rating at all).
  final RodRating? rating;
  final RodFlaw flaw;
  bool get jugaad => rating == null;
}

@immutable
class RodDocket {
  const RodDocket({required this.line, required this.feederBn, required this.timeBn});
  final RodRating line;
  final String feederBn;
  final String timeBn;
}

@immutable
class RodRoundDeal {
  const RodRoundDeal({required this.docket, required this.rods});
  final RodDocket docket;
  final List<RodItem> rods;

  /// No rod on the rack is right: the job must be held.
  bool get noneFits => !rods.any((r) => r.rating == docket.line && r.flaw == RodFlaw.none);
}

@immutable
class RodDeal {
  const RodDeal({required this.rounds, required this.keeperLineBn});
  final List<RodRoundDeal> rounds;

  /// The store-keeper's push on the last docket.
  final String keeperLineBn;
}

abstract final class RodLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask];

  static const title = 'সঠিক রড';
  static const intro = 'কাজের আগে স্টোর। ডকেটের ভোল্টেজ দেখে ঠিক রড বেছে নিন — হাতে নিয়ে যাচাই করে।';
  static const scene = 'সাবস্টেশনের স্টোর · রড র‍্যাক';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];
  static const ask = 'ডকেট দেখুন। কোন রডটা?';
  static const docket = 'ডকেট';
  static String line(RodDocket d) => 'লাইন: ${d.line.lineBn} · ${d.feederBn}';
  static String shutdown(RodDocket d) => 'শাটডাউন ${d.timeBn}';
  static const take = 'এটাই নিন';
  static const putBack = 'ফেরত রাখুন';
  static const hold = 'কোনোটাই ঠিক নয় — কাজ স্থগিত';
  static const rejected = 'বাতিল';
  static const right = [FeedbackLine('লেবেল মিলল, রড ঠিকঠাক।'), FeedbackLine('ঠিক রড!'), FeedbackLine('এটাই কাজের রড।')];
  static const heldRight = 'ঠিক! মিল না থাকলে কাজ শুরু নয় — সুপারভাইজারকে জানান।';
  static const allSet = 'রড বাছাইয়ে পাকা হাত! লেবেল আর অবস্থা — দুটোই দেখেছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — লেবেল আর অবস্থা দুটোই দেখুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtRating = 'ডকেটের সঙ্গে রেটিং মিলিয়েছেন';
  static const caughtHold = 'ঠিক রড না পেয়ে কাজ স্থগিত';
  static const caughtFlaw = 'ভাঙা রড বাতিল';
  static const feeders = ['রামপুর ফিডার', 'হাটখোলা ফিডার', 'নদীপাড় ফিডার', 'স্টেশন রোড ফিডার', 'কলেজপাড়া ফিডার'];
  static const times = ['10:00–14:00', '09:30–13:00', '11:00–15:30', '08:00–12:00'];
  static String keeper(RodRating lower) => 'এটাই আছে ভাই, ${lower.tag}-টা নিয়ে যাও, চলবে!';
}

abstract final class RodMistakes {
  static const wrongRating = DoMistake(
    key: '1.5/rod/wrong-rating',
    textBn: 'রডের রেটিং লাইনের চেয়ে কম — ইনসুলেশন ভেঙে কারেন্ট হাতে আসে। ডকেটের ভোল্টেজ আর রডের লেবেল মিলিয়ে নিন।',
    art: 'assets/game/art/rod/rating_match.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const jugaad = DoMistake(
    key: '1.5/rod/jugaad',
    textBn: 'পিভিসি পাইপের জুগাড় রড নয় — ফাটে, ভিজে লিক করে। স্টোরের স্ট্যান্ডার্ড রড ছাড়া কাজ নয়।',
    art: 'assets/game/art/rod/jugaad_vs_standard.svg',
    deadly: true,
    lessonPoint: 4,
  );
  static const crack = DoMistake(
    key: '1.5/rod/cracked-stick',
    textBn: 'স্টিকে ফাটল — ফাটা জায়গা দিয়ে লিক হয়। ফাটা রড বাতিল।',
    art: 'assets/game/art/rod/rod_flaws.svg',
    lessonPoint: 2,
  );
  static const cable = DoMistake(
    key: '1.5/rod/cut-cable',
    textBn: 'কপার কেবিলের ইনসুলেশন কাটা — চার্জ ঠিক পথে নামবে না। এমন রড বাতিল।',
    art: 'assets/game/art/rod/rod_flaws.svg',
    lessonPoint: 2,
  );
  static const clamp = DoMistake(
    key: '1.5/rod/rusty-clamp',
    textBn: 'ক্ল্যাম্পে মরিচা — আর্থের গ্রিপ আলগা হয়। পরিষ্কার, মজবুত ক্ল্যাম্প চাই।',
    art: 'assets/game/art/rod/rod_flaws.svg',
    lessonPoint: 2,
  );
  static const heldWhenRight = DoMistake(
    key: '1.5/rod/held-when-right',
    textBn: 'সঠিক রডটা র‍্যাকেই ছিল — লেবেল আর অবস্থা ভালো করে দেখুন।',
    art: 'assets/game/art/rod/rating_match.svg',
    lessonPoint: 3,
  );
  static const all = [wrongRating, jugaad, crack, cable, clamp, heldWhenRight];
}

RodFlaw _anyFlaw(math.Random rng) => const [RodFlaw.crack, RodFlaw.cable, RodFlaw.clamp][rng.nextInt(3)];

RodRating _below(RodRating r) => r == RodRating.kv33 ? RodRating.kv11 : RodRating.lt;

/// A fresh store each play: dockets, decoys, flaws and rack order vary.
RodDeal dealRods(math.Random rng) {
  var n = 0;
  RodItem rod(RodRating? r, [RodFlaw f = RodFlaw.none]) => RodItem(id: 'rod${n++}', rating: r, flaw: f);
  RodDocket docket(RodRating line) => RodDocket(
        line: line,
        feederBn: RodLines.feeders[rng.nextInt(RodLines.feeders.length)],
        timeBn: RodLines.times[rng.nextInt(RodLines.times.length)],
      );

  // 1: easy — one right rod, the jugaad and one plain decoy.
  final first = rng.nextBool() ? RodRating.kv11 : RodRating.lt;
  final r1 = [
    rod(first),
    rod(null),
    first == RodRating.kv11 ? rod(RodRating.lt) : rod(RodRating.lt, _anyFlaw(rng)),
  ]..shuffle(rng);
  // 2: 33 kV — the right rod, a damaged twin, a lower rating and the jugaad.
  final r2 = [rod(RodRating.kv33), rod(RodRating.kv33, _anyFlaw(rng)), rod(RodRating.kv11), rod(null)]..shuffle(rng);
  // 3: nothing fits — damaged right rating, a lower rating, the jugaad.
  final last = rng.nextBool() ? RodRating.kv11 : RodRating.kv33;
  final r3 = [rod(last, _anyFlaw(rng)), rod(_below(last)), rod(null)]..shuffle(rng);
  return RodDeal(
    rounds: [
      RodRoundDeal(docket: docket(first), rods: r1),
      RodRoundDeal(docket: docket(RodRating.kv33), rods: r2),
      RodRoundDeal(docket: docket(last), rods: r3),
    ],
    keeperLineBn: RodLines.keeper(_below(last)),
  );
}

enum RodVerdict { right, slip, deadly }

@immutable
class RodOutcome {
  const RodOutcome(this.verdict, {this.mistake});
  final RodVerdict verdict;
  final DoMistake? mistake;
}

/// The play state (pure logic).
class RodRun {
  RodRun(this.deal);
  final RodDeal deal;
  int round = 0;
  int slips = 0;
  DoMistake? deadly;
  final Set<String> rejected = {};
  final List<String> caught = [];

  bool get done => round >= deal.rounds.length;
  bool get ended => done || deadly != null;
  RodRoundDeal get current => deal.rounds[round.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  RodOutcome take(RodItem rod) {
    if (ended || rejected.contains(rod.id)) return const RodOutcome(RodVerdict.slip);
    final line = current.docket.line;
    if (rod.jugaad) return _deadly(RodMistakes.jugaad);
    if (rod.rating!.index < line.index) return _deadly(RodMistakes.wrongRating);
    if (rod.flaw != RodFlaw.none) {
      slips++;
      rejected.add(rod.id);
      if (!caught.contains(RodLines.caughtFlaw)) caught.add(RodLines.caughtFlaw);
      return RodOutcome(RodVerdict.slip, mistake: switch (rod.flaw) {
        RodFlaw.crack => RodMistakes.crack,
        RodFlaw.cable => RodMistakes.cable,
        _ => RodMistakes.clamp,
      });
    }
    if (!caught.contains(RodLines.caughtRating)) caught.add(RodLines.caughtRating);
    _next();
    return const RodOutcome(RodVerdict.right);
  }

  /// "কোনোটাই ঠিক নয় — কাজ স্থগিত".
  RodOutcome holdJob() {
    if (ended) return const RodOutcome(RodVerdict.slip);
    if (!current.noneFits) {
      slips++;
      return const RodOutcome(RodVerdict.slip, mistake: RodMistakes.heldWhenRight);
    }
    caught.add(RodLines.caughtHold);
    _next();
    return const RodOutcome(RodVerdict.right);
  }

  void _next() {
    round++;
    rejected.clear();
  }

  RodOutcome _deadly(DoMistake m) {
    deadly = m;
    return RodOutcome(RodVerdict.deadly, mistake: m);
  }
}

@immutable
class RodPickPack {
  const RodPickPack({required this.id, required this.titleBn, this.quickMs = 50000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const rodPickPack15 = RodPickPack(id: 'do_1_5_a', titleBn: RodLines.title);
const rodPickPacks = {'do_1_5_a': rodPickPack15};

// ============================================================================
// Page
// ============================================================================

class RodPickPage extends StatefulWidget {
  const RodPickPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final RodPickPack pack;
  final bool muted;
  final int? seed;

  @override
  State<RodPickPage> createState() => _RodPickPageState();
}

class _RodPickPageState extends State<RodPickPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _RodRunPage(
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

class _RodRunPage extends ConsumerStatefulWidget {
  const _RodRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final RodPickPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_RodRunPage> createState() => _RodRunPageState();
}

class _RodRunPageState extends ConsumerState<_RodRunPage> with DoDeathGuard, DoStrikeOut {
  final _scoreKey = GlobalKey();
  late final RodRun _run = RodRun(dealRods(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _rightBag = LineBag(RodLines.right);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;
  RodItem? _held;
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

  /// After the guide's intro: the clock runs and play begins.
  Future<void> _start() async {
    _clock.start();
  }

  /// The last docket: the store-keeper pushes the wrong rod.
  void _roundStarted() {
    if (_run.done) return;
    if (_run.round == _run.deal.rounds.length - 1) {
      _hush();
      if (!_muted) unawaited(ZlFx.cue('sounds/customer.wav', volume: 0.6, muted: false));
      ref.read(guideDirectorProvider.notifier).say(mood: GuideMood.warn, line: '“${_run.deal.keeperLineBn}”');
      unawaited(_say(_run.deal.keeperLineBn, other: true));
    } else {
      unawaited(_sayChain([RodLines.ask]));
    }
  }

  void _pick(RodItem r) {
    if (_busy || _ended || _card != null || _held != null || _run.rejected.contains(r.id)) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.5, muted: false));
    _hush();
    ref.read(guideDirectorProvider.notifier).clearLine();
    setState(() => _held = r);
  }

  void _putBack() {
    if (_busy) return;
    HapticFeedback.selectionClick();
    setState(() => _held = null);
  }

  void _take(Offset origin) {
    final r = _held;
    if (r == null || _busy) return;
    setState(() => _held = null);
    _settle(_run.take(r), origin, points: 15);
  }

  void _holdJob(Offset origin) {
    if (_busy || _ended || _card != null || _held != null) return;
    _settle(_run.holdJob(), origin, points: 20);
  }

  void _settle(RodOutcome o, Offset origin, {required int points}) {
    switch (o.verdict) {
      case RodVerdict.right:
        HapticFeedback.lightImpact();
        if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
        unawaited(_levelDelta(points, origin, mood: GuideMood.glad));
        if (_run.done) {
          unawaited(_finish());
        } else {
          final held = points == 20;
          setState(() {});
          unawaited(_sayChain([held ? RodLines.heldRight : _rightBag.next().shownBn], mood: GuideMood.glad));
          // The next docket arrives at once; the voice never holds the player.
          Future<void>.delayed(const Duration(milliseconds: 700), () {
            if (mounted && !_ended) _roundStarted();
          });
        }
      case RodVerdict.slip:
        final m = o.mistake;
        if (m != null) unawaited(_slip(m, origin));
      case RodVerdict.deadly:
        unawaited(_deadly(o.mistake!));
    }
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

  Future<void> _slip(DoMistake m, Offset origin) async {
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
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('rod/${m.key}');
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
    final speak = await SpokenOnce.first('rod/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? RodLines.deadlyWord : RodLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
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
    await _say(!_run.passed ? RodLines.fail : (_quickBonus ? RodLines.quick : RodLines.allSet),
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

  // ---- build ------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final round = _run.current;
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
                      labels: RodLines.rounds,
                      done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
                      current: _run.done ? null : _run.round,
                      quiet: quiet,
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: quiet ? Duration.zero : const Duration(milliseconds: 380),
                      transitionBuilder: (child, a) => SlideTransition(
                        position: Tween(begin: const Offset(0, -0.4), end: Offset.zero).animate(a),
                        child: FadeTransition(opacity: a, child: child),
                      ),
                      child: _DocketCard(key: ValueKey('docket-${_run.round}'), docket: round.docket),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: 360,
                              height: 420,
                              child: _Rack(
                                key: ValueKey('rack-${_run.round}'),
                                rods: round.rods,
                                rejected: _run.rejected,
                                held: _held?.id,
                                quiet: quiet,
                                onPick: _pick,
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
                        child: _HoldButton(onTapUp: (d) => _holdJob(d.globalPosition)),
                      ),
                    ),
                    Opacity(opacity: _card == null && _held == null ? 1 : 0, child: DoCoachStrip(tasks: RodLines.tasks, muted: _muted)),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              if (_held != null)
                _Inspect(
                  key: ValueKey('inspect-${_held!.id}'),
                  rod: _held!,
                  quiet: quiet,
                  onTake: _take,
                  onPutBack: _putBack,
                ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.slips}'),
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
                  lines: [RodLines.intro, RodLines.ask],
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
                                    lessonId: widget.ctx.lessonId, point: 3, muted: _muted)),
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

/// The docket slip: line voltage, feeder and shutdown window.
class _DocketCard extends StatelessWidget {
  const _DocketCard({super.key, required this.docket});
  final RodDocket docket;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB59B62), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: Color(0xFF8C6A2A), size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(RodLines.docket, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF8C6A2A))),
                Text(RodLines.line(docket), style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.ink)),
                Text(RodLines.shutdown(docket), style: bangla(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The store rack: rods hang from the pegs, each with its label.
class _Rack extends StatelessWidget {
  const _Rack({super.key, required this.rods, required this.rejected, required this.held, required this.quiet, required this.onPick});
  final List<RodItem> rods;
  final Set<String> rejected;
  final String? held;
  final bool quiet;
  final ValueChanged<RodItem> onPick;

  static const _pegs = [48.0, 108.0, 168.0, 228.0];

  @override
  Widget build(BuildContext context) {
    final xs = rods.length == 3 ? const [78.0, 143.0, 208.0] : _pegs;
    return Stack(
      children: [
        Positioned.fill(child: SvgPicture.asset('assets/game/art/rod/store_rack.svg', fit: BoxFit.fill)),
        for (var i = 0; i < rods.length; i++)
          Positioned(
            left: xs[i] - 26,
            top: 50,
            width: 52,
            height: 310,
            child: DoDealIn(
              index: i,
              quiet: quiet,
              muted: true,
              child: _RackRod(
                rod: rods[i],
                gone: rejected.contains(rods[i].id),
                lifted: held == rods[i].id,
                quiet: quiet,
                onTap: () => onPick(rods[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _RackRod extends StatelessWidget {
  const _RackRod({required this.rod, required this.gone, required this.lifted, required this.quiet, required this.onTap});
  final RodItem rod;
  final bool gone;
  final bool lifted;
  final bool quiet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = quiet ? Duration.zero : const Duration(milliseconds: 260);
    return Semantics(
      button: true,
      label: 'রড',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: gone ? null : onTap,
        child: AnimatedOpacity(
          opacity: gone ? 0.25 : (lifted ? 0.0 : 1),
          duration: d,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: RotatedBox(quarterTurns: 1, child: CustomPaint(painter: RodPainter(rod))),
              ),
              if (rod.rating != null)
                Positioned(top: 86, child: _Tag(text: rod.rating!.tag, small: true)),
              if (gone)
                Center(
                  child: Transform.rotate(
                    angle: -0.5,
                    child: const DoStamp(text: RodLines.rejected, good: false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "কোনোটাই ঠিক নয় — কাজ স্থগিত", readable on the dark page.
class _HoldButton extends StatelessWidget {
  const _HoldButton({required this.onTapUp});
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x1AFFFFFF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: () {},
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.warning.withValues(alpha: 0.8), width: 1.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pan_tool_rounded, size: 18, color: SlmColors.warning),
              const SizedBox(width: 8),
              Flexible(
                child: Text(RodLines.hold,
                    textAlign: TextAlign.center,
                    style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.small = false});
  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 3 : 8, vertical: small ? 1 : 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF31363C), width: small ? 0.8 : 1.4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: small ? 7.5 : 15, fontWeight: FontWeight.w900, color: const Color(0xFF1E2228), height: 1.1),
      ),
    );
  }
}

/// Close look: the rod held up big, label and all; take it or put it back.
class _Inspect extends StatelessWidget {
  const _Inspect({super.key, required this.rod, required this.quiet, required this.onTake, required this.onPutBack});
  final RodItem rod;
  final bool quiet;
  final ValueChanged<Offset> onTake;
  final VoidCallback onPutBack;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPutBack,
        child: ColoredBox(
          color: const Color(0xC0050A16),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: quiet ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutBack,
                builder: (_, t, child) => Transform.scale(scale: 0.9 + 0.1 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
                  decoration: BoxDecoration(color: SlmColors.ivory, borderRadius: BorderRadius.circular(22)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AspectRatio(
                        aspectRatio: 3.4,
                        child: Stack(
                          children: [
                            Positioned.fill(child: CustomPaint(painter: RodPainter(rod))),
                            if (rod.rating != null)
                              Align(alignment: const Alignment(-0.42, -0.6), child: _Tag(text: rod.rating!.tag)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: DoBigButton(label: RodLines.putBack, filled: false, onTapUp: (_) => onPutBack())),
                          const SizedBox(width: 12),
                          Expanded(child: DoBigButton(label: RodLines.take, filled: true, onTapUp: (d) => onTake(d.globalPosition))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A discharge rod drawn lengthwise (hook at the left): fibreglass stick with
/// telescopic joints, a red guard band and a black grip, copper cable to the
/// earth clamp — or the jugaad (white PVC, tape, thin wire, crocodile clip).
/// Flaws: a crack in the stick, a cut in the cable, rust on the clamp.
class RodPainter extends CustomPainter {
  RodPainter(this.rod);
  final RodItem rod;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final cy = h * 0.36;
    final t = math.max(3.0, h * 0.13);
    final x0 = w * 0.1;
    final x1 = w * 0.9;
    final jug = rod.jugaad;

    // Cable first (it hangs behind the stick).
    final from = Offset(x0 + t * 0.4, cy + t * 0.4);
    final clampAt = Offset(w * 0.93, h * 0.8);
    final ctrl = Offset(w * 0.5, h * 1.05);
    Offset at(double u) {
      final a = Offset.lerp(from, ctrl, u)!;
      final b = Offset.lerp(ctrl, clampAt, u)!;
      return Offset.lerp(a, b, u)!;
    }

    final cablePaint = Paint()
      ..color = jug ? const Color(0xFF7A7F85) : const Color(0xFF8A5A1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = jug ? math.max(1.0, t * 0.18) : math.max(1.6, t * 0.42)
      ..strokeCap = StrokeCap.round;
    final cut = rod.flaw == RodFlaw.cable;
    Path cablePath(double a, double b) {
      final p = Path()..moveTo(at(a).dx, at(a).dy);
      for (var i = 1; i <= 24; i++) {
        final q = at(a + (b - a) * i / 24);
        p.lineTo(q.dx, q.dy);
      }
      return p;
    }

    if (cut) {
      canvas.drawPath(cablePath(0, 0.5), cablePaint);
      canvas.drawPath(cablePath(0.56, 1), cablePaint);
      final strand = Paint()
        ..color = const Color(0xFFF0A040)
        ..strokeWidth = math.max(0.8, t * 0.1)
        ..strokeCap = StrokeCap.round;
      final a = at(0.5);
      final b = at(0.56);
      for (var i = -1; i <= 1; i++) {
        canvas.drawLine(a, Offset.lerp(a, b, 0.7)!.translate(0, i * t * 0.25), strand);
        canvas.drawLine(b, Offset.lerp(b, a, 0.6)!.translate(0, i * t * 0.22), strand);
      }
    } else {
      canvas.drawPath(cablePath(0, 1), cablePaint);
      if (!jug) {
        canvas.drawPath(
          cablePath(0, 1),
          Paint()
            ..color = const Color(0xFFD9954A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.6, t * 0.12),
        );
      }
    }

    // Clamp (or crocodile clip).
    if (jug) {
      final jaw = Paint()..color = const Color(0xFF8D949B);
      final p = Path()
        ..moveTo(clampAt.dx - t * 0.9, clampAt.dy - t * 0.3)
        ..lineTo(clampAt.dx + t * 0.9, clampAt.dy - t * 0.6)
        ..lineTo(clampAt.dx + t * 0.9, clampAt.dy + t * 0.1)
        ..lineTo(clampAt.dx - t * 0.9, clampAt.dy + t * 0.3)
        ..close();
      canvas.drawPath(p, jaw);
    } else {
      final rusty = rod.flaw == RodFlaw.clamp;
      final r = Rect.fromCenter(center: clampAt, width: t * 2.4, height: t * 1.7);
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(t * 0.4)),
          Paint()..color = rusty ? const Color(0xFF9A5A2C) : const Color(0xFFD9A441));
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(t * 0.4)),
        Paint()
          ..color = rusty ? const Color(0xFF4F2A12) : const Color(0xFF7A5A1C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.8, t * 0.14),
      );
      canvas.drawCircle(clampAt, t * 0.32, Paint()..color = rusty ? const Color(0xFF4F2A12) : const Color(0xFF7A5A1C));
      if (rusty) {
        final spot = Paint()..color = const Color(0xFFC9783A);
        for (final o in const [Offset(-0.7, -0.4), Offset(0.6, 0.35), Offset(0.75, -0.45), Offset(-0.4, 0.5)]) {
          canvas.drawCircle(clampAt + Offset(o.dx * t, o.dy * t), t * 0.2, spot);
        }
      }
    }

    // Hook.
    final hook = Path()
      ..moveTo(x0, cy)
      ..lineTo(x0 - w * 0.03, cy)
      ..quadraticBezierTo(x0 - w * 0.08, cy, x0 - w * 0.08, cy - t * 1.6)
      ..quadraticBezierTo(x0 - w * 0.08, cy - t * 3, x0 - w * 0.04, cy - t * 3)
      ..quadraticBezierTo(x0 - w * 0.01, cy - t * 3, x0 - w * 0.01, cy - t * 2.1);
    canvas.drawPath(
      hook,
      Paint()
        ..color = const Color(0xFF9AA3AB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, t * 0.5)
        ..strokeCap = StrokeCap.round,
    );

    // Stick.
    final stick = RRect.fromRectAndRadius(Rect.fromLTRB(x0, cy - t / 2, x1, cy + t / 2), Radius.circular(t / 2));
    canvas.drawRRect(stick, Paint()..color = jug ? const Color(0xFFF4F4F0) : const Color(0xFFE9B949));
    canvas.drawRRect(
      stick,
      Paint()
        ..color = jug ? const Color(0xFFA9A9A2) : const Color(0xFF9C7420)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, t * 0.1),
    );
    if (jug) {
      final tape = Paint()..color = const Color(0xFF222222);
      for (final u in const [0.36, 0.62]) {
        canvas.drawRect(Rect.fromCenter(center: Offset(x0 + (x1 - x0) * u, cy), width: t * 0.9, height: t * 1.15), tape);
      }
    } else {
      final joint = Paint()..color = const Color(0xFFB88A2A);
      for (final u in const [0.33, 0.55]) {
        canvas.drawRect(Rect.fromCenter(center: Offset(x0 + (x1 - x0) * u, cy), width: t * 0.35, height: t * 1.08), joint);
      }
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x0 + (x1 - x0) * 0.7, cy), width: t * 0.7, height: t * 1.15),
        Paint()..color = const Color(0xFFC0392B),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(x0 + (x1 - x0) * 0.8, cy - t * 0.6, x1, cy + t * 0.6), Radius.circular(t * 0.4)),
        Paint()..color = const Color(0xFF3B3F45),
      );
    }
    if (rod.flaw == RodFlaw.crack) {
      final cx = x0 + (x1 - x0) * 0.62;
      final crack = Path()
        ..moveTo(cx - t * 1.2, cy - t * 0.45)
        ..lineTo(cx - t * 0.4, cy + t * 0.1)
        ..lineTo(cx + t * 0.2, cy - t * 0.25)
        ..lineTo(cx + t * 1.0, cy + t * 0.42);
      canvas.drawPath(
        crack,
        Paint()
          ..color = const Color(0xFF3B2A12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.8, t * 0.16),
      );
      final stress = Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = math.max(0.5, t * 0.08);
      canvas.drawLine(Offset(cx - t * 0.5, cy - t * 0.45), Offset(cx - t * 0.2, cy - t * 0.1), stress);
      canvas.drawLine(Offset(cx + t * 0.6, cy + t * 0.45), Offset(cx + t * 0.4, cy + t * 0.12), stress);
    }
  }

  @override
  bool shouldRepaint(RodPainter old) => old.rod != rod;
}
