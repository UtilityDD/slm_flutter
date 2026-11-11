import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'beat_fx.dart';
import 'choice_deck.dart';
import 'coworker_moment.dart';
import 'do_parts.dart';
import 'full_scene_frame.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'helmet_check.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart';
import 'van_yard.dart';
import 'level_shell.dart';
import 'spoken_once.dart';

// Lesson 1.1, কাজ 2: "গ্লাভস যাচাই". Before the van leaves, pick three sound
// pairs of rubber gloves (own, partner's, spare). Rubber gloves must be
// air-tested before they are packed: a pinhole shows only that way. Then the
// helmet station (helmet_check.dart): your own helmet from the shelf, looked
// over with the torch, inside and at the chin strap.
//
// Voice: NO recorded clips for this level (owner's decision, 2026-11-06). Every
// line is read by the phone's TTS through MascotSpeechLibrary; all fixed lines
// are in [GloveLines] and the pack data, ready to be recorded later.

// ============================================================================
// Data
// ============================================================================

enum GloveKind { good, flawed, wrong }

/// pinhole: hidden, only the air test finds it. crack / wet: visible on a close look.
enum GloveFlawKind { pinhole, crack, wet }

@immutable
class GloveFlaw {
  const GloveFlaw({required this.id, required this.kind, required this.marks, required this.labelBn, required this.lineBn});
  final String id;
  final GloveFlawKind kind;

  /// Positions inside the picture box (0–1); the pinhole is where air escapes.
  final List<Offset> marks;
  final String labelBn;
  final String lineBn;
}

@immutable
class GloveItem {
  const GloveItem({
    required this.id,
    required this.kind,
    required this.asset,
    required this.aspect,
    required this.labelBn,
    this.rubber = true,
    this.lineBn = '',
    this.flaws = const [],
    this.flaw,
  });

  final String id;
  final GloveKind kind;
  final String asset;
  final double aspect;
  final String labelBn;

  /// Insulating rubber: can (and must) be air-tested.
  final bool rubber;
  final String lineBn;

  /// Good items only: ways this pair can turn up damaged.
  final List<GloveFlaw> flaws;

  /// Flawed copies (and the wet pair) only.
  final GloveFlaw? flaw;

  bool get leaks => flaw?.kind == GloveFlawKind.pinhole;

  GloveItem withFlaw(GloveFlaw f) =>
      GloveItem(id: '$id#${f.id}', kind: GloveKind.flawed, asset: asset, aspect: aspect, labelBn: f.labelBn, lineBn: f.lineBn, flaw: f);

  String get lessonKey => flaw != null ? 'flaw/${flaw!.kind.name}' : 'item/$id';
}

/// Fixed lines (read by device TTS until recorded).
abstract final class GloveLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askOwn, askMate, askSpare];

  static const intro = 'গাড়ি ছাড়ার আগে তিন জোড়া রাবার গ্লাভস বাছুন—নিজের, সাথীর আর একটা বাড়তি—প্রতিটায় হাওয়া দিয়ে। শেষে নিজের হেলমেট।';
  static const scene = 'সকাল 7:20 · ভ্যানের পাশে';
  static const askOwn = 'আগে নিজের জোড়াটা বাছুন।';
  static const askMate = 'এবার সাথীর জোড়া।';
  static const askSpare = 'শেষে একটা বাড়তি জোড়া।';
  static const testFirst = 'আগে হাওয়া দিয়ে দেখুন!';
  static const guessed = 'ঠিক, কিন্তু আন্দাজে নয়—আগে হাওয়া দিয়ে দেখুন।';
  static const holds = 'হাওয়া ধরে রাখছে—ঠিক আছে।';
  static const leaks = 'হাওয়া বেরিয়ে যাচ্ছে—ফুটো আছে!';
  static const pressMore = 'আরও একটু চেপে ধরে রাখুন।';
  static const caught = 'ঠিক ধরেছেন!';
  static const rejectedGood = 'এটা তো ঠিক ছিল!';
  static const callHeld = 'ঠিক। দশ সেকেন্ডের পরীক্ষাই জীবন বাঁচায়।';
  static const callRushed = 'না! পরীক্ষা ছাড়া গ্লাভস মানে খালি হাত।';
  static const allSet = 'তিন জোড়া গ্লাভস পরীক্ষিত, হেলমেটও দেখা হলো। এবার বেরোনো যায়।';
  static const fail = 'এবার হলো না। ভালো করে দেখে আবার চেষ্টা করুন।';
  static const quick = 'ঝটপট আর নির্ভুল! বোনাস পেলেন।';
  static const testButton = 'চেপে ধরে হাওয়া দিন';


  // The reason after each pair packed (lesson 1.1): one right, two wrong.
  static const whyAsk = 'কেন এই জোড়াটা নিলেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const whyRight = [
    'হাওয়া দিলে চোখে-না-দেখা ফুটো ধরা পড়ে',
    'ফুটো বা ফাটা রাবারে কারেন্ট হাতে ঢোকে',
    'পরীক্ষা করা অক্ষত রাবারই হাত বাঁচায়',
  ];
  static const whyWrong = [
    'নতুন গ্লাভস হলে পরীক্ষা লাগে না',
    'সুতির গ্লাভসও কারেন্ট আটকে দেয়',
    'ভেজা গ্লাভস পরেও দিব্যি কাজ চলে',
    'একটু ফাটা থাকলে টেপ দিলেই কাজ চলে',
    'চোখে দেখলেই সব ফুটো ধরা পড়ে যায়',
  ];

  /// The careless coworker (his recorded voice) pushes to skip the air test.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const choiceRight = [
    'না — হাওয়া দিয়ে দেখে তবেই নেব',
    'দশ সেকেন্ডের পরীক্ষা বাদ দেব না',
    'নতুন হোক, আগে হাওয়া দিয়ে দেখি',
    'আগে পরীক্ষা, তারপর গাড়িতে উঠব',
  ];
  static const choiceWrong = [
    'নতুন গ্লাভস, দেখার দরকার নেই',
    'এমনিই পরে নিই, সময় তো নেই',
    'পরে গাড়িতে বসে দেখে নেব একবার',
    'চোখে একবার দেখে নিলেই হয়ে যাবে',
    'সবাই তো না দেখেই এমনি পরে নেয়',
  ];
  static const choiceAsks = [
    'ও বলছে পরীক্ষার সময় নেই। আপনি কী করবেন?',
    'হাওয়া দিয়ে দেখবেন, না এমনিই পরবেন?',
    'কার কথা শুনবেন — ওর, না নিয়মের?',
  ];
  static const coworkerNew = CoworkerScript(
    line: 'সময় নেই! গ্লাভস তো নতুনই, এমনিই পরে নাও!',
    exitLine: coworkerExit,
    right: choiceRight,
    wrong: choiceWrong,
    asks: choiceAsks,
  );
  static const coworkerTrip = CoworkerScript(
    line: 'লাইন ট্রিপ করেছে, এখনই বেরোও!',
    exitLine: coworkerExit,
    right: choiceRight,
    wrong: choiceWrong,
    asks: choiceAsks,
  );

  static const rounds = ['নিজের', 'সাথীর', 'বাড়তি'];
  static String ask(int round) => [askOwn, askMate, askSpare][round.clamp(0, 2)];
}

const _d = 'assets/duty_slip/dress';
const _ppe = 'assets/safety/library/ppe';

const _pinholeLine = 'চোখে না-দেখা ফুটো দিয়েই কারেন্ট হাতে ঢুকবে।';
const _crackLine = 'রাবারে ফাটল। ওখানেই ইনসুলেশন শেষ।';

List<GloveFlaw> _rubberFlaws(String id, Offset hole, Offset crack) => [
      GloveFlaw(id: '$id-pin', kind: GloveFlawKind.pinhole, marks: [hole], labelBn: 'ফুটো রাবার গ্লাভস', lineBn: _pinholeLine),
      GloveFlaw(id: '$id-crack', kind: GloveFlawKind.crack, marks: [crack], labelBn: 'ফাটা রাবার গ্লাভস', lineBn: _crackLine),
    ];

@immutable
class GloveCheckPack {
  const GloveCheckPack({required this.id, required this.titleBn, required this.pool, required this.callers, required this.quickMs});
  final String id;
  final String titleBn;
  final List<GloveItem> pool;
  final List<DoCaller> callers;
  final int quickMs;
}

final gloveCheckPack11 = GloveCheckPack(
  id: 'glove_check_1_1',
  titleBn: 'গ্লাভস যাচাই',
  // A little under a thorough play: gloves ~90 s + the helmet's three looks.
  quickMs: 135000,
  callers: const [
    DoCaller(id: 'mate', whoBn: 'সহকর্মী', lineBn: 'সময় নেই! গ্লাভস তো নতুনই, এমনিই পরে নাও!', icon: Icons.directions_run_rounded),
    DoCaller(id: 'je', whoBn: 'JE সাহেব (ফোনে)', lineBn: 'লাইন ট্রিপ করেছে, এখনই বেরোও!', icon: Icons.phone_in_talk_rounded),
  ],
  pool: [
    GloveItem(
      id: 'rubber_orange',
      kind: GloveKind.good,
      asset: '$_d/tray_rubber_gloves.webp',
      aspect: 605 / 738,
      labelBn: 'রাবার গ্লাভস',
      flaws: _rubberFlaws('rubber_orange', const Offset(0.27, 0.58), const Offset(0.70, 0.36)),
    ),
    GloveItem(
      id: 'rubber_cream',
      kind: GloveKind.good,
      asset: '$_ppe/Electrical_Gloves.webp',
      aspect: 1,
      labelBn: 'ইলেকট্রিক্যাল গ্লাভস',
      flaws: _rubberFlaws('rubber_cream', const Offset(0.27, 0.42), const Offset(0.72, 0.30)),
    ),
    GloveItem(
      id: 'rubber_red',
      kind: GloveKind.good,
      asset: '$_ppe/Electrical_Gloves_2.webp',
      aspect: 867 / 960,
      labelBn: 'ইলেকট্রিক্যাল গ্লাভস',
      flaws: _rubberFlaws('rubber_red', const Offset(0.24, 0.42), const Offset(0.70, 0.28)),
    ),
    const GloveItem(
      id: 'wet',
      kind: GloveKind.flawed,
      asset: '$_d/tray_wet_gloves.webp',
      aspect: 440 / 512,
      labelBn: 'ভেজা রাবার গ্লাভস',
      lineBn: 'ভেজা গ্লাভসে কারেন্ট সহজে চলে। শুকিয়ে তবেই পরুন।',
      flaw: GloveFlaw(
        id: 'wet',
        kind: GloveFlawKind.wet,
        marks: [Offset(0.35, 0.35), Offset(0.62, 0.52)],
        labelBn: 'ভেজা রাবার গ্লাভস',
        lineBn: 'ভেজা গ্লাভসে কারেন্ট সহজে চলে। শুকিয়ে তবেই পরুন।',
      ),
    ),
    const GloveItem(id: 'cotton', kind: GloveKind.wrong, rubber: false, asset: '$_d/tray_cotton_gloves.webp', aspect: 488 / 512, labelBn: 'সুতির গ্লাভস', lineBn: 'সুতির গ্লাভস কারেন্ট আটকায় না।'),
    const GloveItem(id: 'bike', kind: GloveKind.wrong, rubber: false, asset: '$_d/tray_bike_gloves.webp', aspect: 512 / 497, labelBn: 'বাইকের গ্লাভস', lineBn: 'বাইকের গ্লাভস ইনসুলেটেড নয়।'),
    const GloveItem(id: 'leather', kind: GloveKind.wrong, rubber: false, asset: '$_d/tray_hole_gloves.webp', aspect: 378 / 512, labelBn: 'চামড়ার গ্লাভস', lineBn: 'চামড়ার গ্লাভস ঘষা থেকে বাঁচায়, কারেন্ট থেকে নয়।'),
    const GloveItem(id: 'cut', kind: GloveKind.wrong, rubber: false, asset: '$_ppe/Cut_Resistant_Gloves.webp', aspect: 1, labelBn: 'কাট-রেজিস্ট্যান্ট গ্লাভস', lineBn: 'কাট-রেজিস্ট্যান্ট গ্লাভস ধার থেকে বাঁচায়, কারেন্ট থেকে নয়।'),
  ],
);

final gloveCheckPacks = <String, GloveCheckPack>{'do_1_1_b': gloveCheckPack11};

// ============================================================================
// Deal + rules (pure, tested)
// ============================================================================

@immutable
class GloveDeal {
  const GloveDeal({required this.rounds, required this.callBefore, required this.caller});

  /// Tray for each of the three rounds.
  final List<List<GloveItem>> rounds;

  /// The pressure call comes before this round: 1 or 2 (a glove pair), or 3
  /// (the helmet station). One coworker per play.
  final int callBefore;
  final DoCaller caller;
}

/// Three rounds, each: one sound rubber pair, a pinholed copy of the SAME
/// picture (only the air test tells them apart), sometimes a cracked or wet
/// pair, and one wrong glove. At most 4 per round.
GloveDeal dealGloves(GloveCheckPack pack, math.Random rng) {
  T pick<T>(List<T> l) => l[rng.nextInt(l.length)];
  final goods = [for (final g in pack.pool) if (g.kind == GloveKind.good) g];
  final wrongs = [for (final g in pack.pool) if (g.kind == GloveKind.wrong) g]..shuffle(rng);
  final wet = pack.pool.where((g) => g.kind == GloveKind.flawed).toList();
  final rounds = <List<GloveItem>>[];
  for (var r = 0; r < 3; r++) {
    final good = pick(goods);
    final hand = <GloveItem>[good, good.withFlaw(good.flaws.firstWhere((f) => f.kind == GloveFlawKind.pinhole))];
    if (rng.nextBool()) {
      if (wet.isNotEmpty && rng.nextBool()) {
        hand.add(wet.first);
      } else {
        final other = pick(goods);
        hand.add(other.withFlaw(other.flaws.firstWhere((f) => f.kind == GloveFlawKind.crack)));
      }
    }
    hand.add(wrongs[r % wrongs.length]);
    // Ids stay unique in a round (two copies of one picture differ by flaw).
    final seen = <String>{};
    rounds.add([for (final g in hand) if (seen.add(g.id)) g]);
  }
  return GloveDeal(rounds: rounds, callBefore: 1 + rng.nextInt(3), caller: pick(pack.callers));
}

enum GloveChoice { wear, reject }

const gloveStampRight = 'ঠিক';
const gloveStampReject = 'বাতিল';
const gloveStampWrong = 'ভুল';

@immutable
class GloveOutcome {
  const GloveOutcome({
    required this.right,
    required this.clean,
    required this.delta,
    required this.packs,
    required this.leavesTray,
    required this.stampBn,
    this.wordBn = '',
    this.reasonBn = '',
  });

  /// The item went the right way (worn if sound, sent back if not).
  final bool right;

  /// Right AND done the right way (rubber air-tested first) — the mark counts this.
  final bool clean;
  final int delta;
  final bool packs;
  final bool leavesTray;
  final String stampBn;

  /// Fixed reaction to say instead of a random short word ('' = pick one).
  final String wordBn;
  final String reasonBn;
}

/// Rubber gloves must be air-tested before a decision: packing an untested
/// sound pair is refused ("আগে হাওয়া দিয়ে দেখুন!"), and sending back an
/// untested pinholed pair is a lucky guess, not a clean answer.
GloveOutcome judgeGlove(GloveItem g, GloveChoice c, {required bool tested}) {
  final needsTest = g.rubber && !tested;
  switch ((g.kind, c)) {
    case (GloveKind.good, GloveChoice.wear):
      if (needsTest) {
        return const GloveOutcome(right: false, clean: false, delta: -5, packs: false, leavesTray: false, stampBn: gloveStampWrong, wordBn: GloveLines.testFirst);
      }
      return const GloveOutcome(right: true, clean: true, delta: 10, packs: true, leavesTray: true, stampBn: gloveStampRight);
    case (GloveKind.good, GloveChoice.reject):
      return const GloveOutcome(right: false, clean: false, delta: -5, packs: false, leavesTray: false, stampBn: gloveStampWrong, wordBn: GloveLines.rejectedGood);
    case (_, GloveChoice.wear):
      return GloveOutcome(right: false, clean: false, delta: -5, packs: false, leavesTray: true, stampBn: gloveStampWrong, reasonBn: g.lineBn);
    case (_, GloveChoice.reject):
      if (g.leaks && needsTest) {
        return GloveOutcome(right: true, clean: false, delta: 0, packs: false, leavesTray: true, stampBn: gloveStampReject, wordBn: GloveLines.guessed, reasonBn: g.lineBn);
      }
      return GloveOutcome(right: true, clean: true, delta: 5, packs: false, leavesTray: true, stampBn: gloveStampReject, wordBn: GloveLines.caught, reasonBn: g.lineBn);
  }
}

class GloveRound {
  GloveRound(this.deal);

  final GloveDeal deal;
  int round = 0;
  final packed = <GloveItem>[];
  final caught = <GloveItem>[];
  final _gone = <String>{};
  final _tried = <String>{};
  final tested = <String>{};
  int asked = 0;
  int clean = 0;
  bool callDone = false;

  bool get done => round >= deal.rounds.length;
  bool get callDue => !callDone && round == deal.callBefore;

  List<GloveItem> get tray => done ? const [] : [for (final g in deal.rounds[round]) if (!_gone.contains('$round/${g.id}')) g];

  void markTested(GloveItem g) => tested.add('$round/${g.id}');
  bool isTested(GloveItem g) => tested.contains('$round/${g.id}');

  GloveOutcome decide(GloveItem g, GloveChoice c) {
    final o = judgeGlove(g, c, tested: isTested(g));
    final key = '$round/${g.id}';
    if (_tried.add(key)) {
      asked++;
      if (o.clean) clean++;
    }
    if (o.right && c == GloveChoice.reject) caught.add(g);
    if (o.leavesTray) _gone.add(key);
    if (o.packs) {
      packed.add(g);
      round++;
    }
    return o;
  }

  void answerCall({required bool heldCheck}) {
    callDone = true;
    asked++;
    if (heldCheck) clean++;
  }

  int get percent => asked == 0 ? 0 : (clean * 100 / asked).round();
  bool get passed => percent >= kLessonPassMark;
}

/// Every fixed line of [p] (for the record-later list and tests).
Iterable<String> gloveCheckLines(GloveCheckPack p) sync* {
  yield* [
    GloveLines.intro, GloveLines.askOwn, GloveLines.askMate, GloveLines.askSpare, GloveLines.testFirst, GloveLines.guessed,
    GloveLines.holds, GloveLines.leaks, GloveLines.pressMore, GloveLines.caught, GloveLines.rejectedGood, GloveLines.callHeld,
    GloveLines.callRushed, GloveLines.allSet, GloveLines.fail, GloveLines.quick,
  ];
  for (final g in p.pool) {
    if (g.lineBn.isNotEmpty) yield g.lineBn;
    for (final f in g.flaws) {
      yield f.lineBn;
    }
  }
  for (final c in p.callers) {
    yield c.lineBn;
  }
  yield* helmetCheckLines();
}

// ============================================================================
// Page
// ============================================================================

class GloveCheckPage extends StatefulWidget {
  const GloveCheckPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final GloveCheckPack pack;
  final bool muted;
  final int? seed;

  @override
  State<GloveCheckPage> createState() => _GloveCheckPageState();
}

class _GloveCheckPageState extends State<GloveCheckPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _GloveRun(
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

class _GloveRun extends ConsumerStatefulWidget {
  const _GloveRun({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final GloveCheckPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_GloveRun> createState() => _GloveRunState();
}

enum _Overlay { none, inspect }

class _GloveRunState extends ConsumerState<_GloveRun> with DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final GloveDeal _deal = dealGloves(widget.pack, widget.rng);
  late final GloveRound _r = GloveRound(_deal);
  late final List<List<GloveItem>> _order;
  late final HelmetRound _h;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _rightBag = LineBag(LearnFeedbackLines.right);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;

  /// The guide's full-screen intro is up; play starts when it is done.
  var _introCard = true;
  int _chain = 0;
  int _wave = 0;
  int _dealtRound = 0;

  _Overlay _overlay = _Overlay.none;
  GloveItem? _held;
  HelmetItem? _heldHelmet;

  /// The slip card on screen (helmet station).
  DoMistake? _card;
  GloveOutcome? _verdict;
  var _leaving = false;
  Completer<void>? _gone;
  Completer<void>? _skip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int? _mark;
  int _stars = 0;
  int _totalDelta = 0;

  String get _rungId => widget.ctx.rungId;

  @override
  void initState() {
    super.initState();
    // Deal in a fixed order: the gloves, their tray order, then the helmets.
    _order = [for (final r in _deal.rounds) [...r]..shuffle(widget.rng)];
    _h = HelmetRound(dealHelmets(widget.rng));
  }

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  List<GloveItem> get _tray {
    if (_r.done) return const [];
    final left = _r.tray.map((g) => g.id).toSet();
    return [for (final g in _order[_r.round]) if (left.contains(g.id)) g];
  }

  /// 0–2 the glove pairs, 3 the helmet, 4 all done.
  int get _station => !_r.done ? _r.round : (_h.done ? 4 : 3);
  bool get _allDone => _r.done && _h.done;
  String? get _taskLine => !_r.done ? GloveLines.ask(_r.round) : (_h.done ? null : HelmetLines.ask);
  int get _percent {
    final asked = _r.asked + _h.asked;
    return asked == 0 ? 0 : ((_r.clean + _h.clean) * 100 / asked).round();
  }

  bool get _passMark => _percent >= kLessonPassMark;

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

  Future<void> _dwell(Duration d) async {
    final skip = _skip = Completer<void>();
    await Future.any([skip.future, Future<void>.delayed(d)]);
    if (identical(_skip, skip)) _skip = null;
  }

  void _skipDwell() {
    final s = _skip;
    if (s != null && !s.isCompleted) s.complete();
  }

  // ---- flow -----------------------------------------------------------------------

  Future<void> _start() async {
    _clock.start();
    await _askRound();
  }

  Future<void> _askRound() async {
    if (_allDone || !mounted) return;
    if (_r.callDue) scheduleCoworker();
    if (_station != _dealtRound) {
      setState(() {
        _dealtRound = _station;
        _wave++;
      });
    }
    final line = _taskLine;
    if (_overlay == _Overlay.none && _card == null && line != null) await _sayChain([line]);
  }

  void _pickUp(GloveItem g) {
    if (coworkerOpen && !coworkerChoiceUp) unawaited(answerCoworker(true, _screenCentre, direct: true));
    if (_busy || _ended || _overlay != _Overlay.none || coworkerOpen || reasonOpen) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.55, muted: false));
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    ref.read(guideDirectorProvider.notifier).clearLine();
    setState(() {
      _held = g;
      _verdict = null;
      _leaving = false;
      _overlay = _Overlay.inspect;
    });
  }

  void _pickHelmet(HelmetItem h) {
    if (coworkerOpen && !coworkerChoiceUp) unawaited(answerCoworker(true, _screenCentre, direct: true));
    if (_busy || _ended || _overlay != _Overlay.none || coworkerOpen || reasonOpen || _card != null) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.55, muted: false));
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    ref.read(guideDirectorProvider.notifier).clearLine();
    setState(() {
      _heldHelmet = h;
      _verdict = null;
      _leaving = false;
      _overlay = _Overlay.inspect;
    });
  }

  void _putBack() {
    if (_busy || _verdict != null || _overlay != _Overlay.inspect) return;
    HapticFeedback.selectionClick();
    setState(() {
      _overlay = _Overlay.none;
      _held = null;
      _heldHelmet = null;
    });
  }

  /// Pack or send back the helmet in the close look. A wrong call is a slip:
  /// its card (picture + the lesson's line + পাঠে দেখুন) follows.
  Future<void> _decideHelmet(GloveChoice c, Offset origin) async {
    final h = _heldHelmet;
    if (h == null || _busy || _verdict != null) return;
    _busy = true;
    final o = _h.decide(h, c);
    DoMistake? slip;
    if (!o.right) {
      slip = helmetMistake(h, o);
      unawaited(bookMistake(ref, widget.ctx, slip));
      if (strike(slip)) {
        await _struckOut();
        return;
      }
    }
    if (o.right) {
      HapticFeedback.lightImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/stomp.wav', volume: 0.45, muted: false));
    } else {
      HapticFeedback.heavyImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
      // The last task line (e.g. "ক্লিক—লক হলো।") must not sit under the stamp.
      _chain++;
      unawaited(MascotSpeechLibrary.stop());
      ref.read(guideDirectorProvider.notifier).say(mood: GuideMood.warn, line: o.wordBn.isNotEmpty ? o.wordBn : h.labelBn);
    }
    if (o.packs) {
      putOnTable(o.delta);
    } else {
      unawaited(_levelDelta(o.delta, origin, mood: o.right ? GuideMood.glad : GuideMood.warn));
      if (o.right) unawaited(_reactHelmet(h, o));
    }
    setState(() => _verdict = o);
    await _dwell(Duration(milliseconds: !o.right ? 800 : (o.packs ? 900 : 1400)));
    if (!mounted) return;
    final gone = _gone = Completer<void>();
    setState(() => _leaving = true);
    await gone.future.timeout(const Duration(seconds: 1), onTimeout: () {});
    if (!mounted) return;
    setState(() {
      _overlay = _Overlay.none;
      _heldHelmet = null;
      _verdict = null;
      _leaving = false;
      _card = slip;
    });
    _busy = false;
    if (slip != null) {
      final speak = await SpokenOnce.first('helmet/${slip.key}');
      if (!mounted || _card != slip) return;
      await _sayChain([speak ? slip.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
    } else if (o.packs) {
      unawaited(askReason(
        deal: () => dealChoices(HelmetLines.whyRight, HelmetLines.whyWrong, widget.rng),
        question: HelmetLines.whyAsk,
      ));
    }
  }

  void _cardGo() {
    HapticFeedback.selectionClick();
    setState(() => _card = null);
    unawaited(_askRound());
  }

  Future<void> _reactHelmet(HelmetItem h, GloveOutcome o) async {
    final chain = ++_chain;
    final speakReason = o.reasonBn.isNotEmpty && await SpokenOnce.first('helmet/${widget.pack.id}/${h.flaw?.kind.name ?? h.id}');
    if (!mounted || chain != _chain) return;
    await _say(o.wordBn.isNotEmpty ? o.wordBn : _rightBag.next().shownBn, mood: GuideMood.glad);
    if (!mounted || chain != _chain || o.reasonBn.isEmpty) return;
    if (speakReason) {
      await _say(o.reasonBn, mood: GuideMood.glad);
    } else {
      ref.read(guideDirectorProvider.notifier).say(mood: GuideMood.glad, line: o.reasonBn);
    }
  }

  /// The air test finished on the held pair.
  void _onTested(GloveItem g, {required bool leaked}) {
    _r.markTested(g);
    if (leaked) {
      HapticFeedback.heavyImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_out.wav', volume: 0.75, muted: false));
    } else {
      HapticFeedback.lightImpact();
    }
    unawaited(_sayChain([leaked ? GloveLines.leaks : GloveLines.holds], mood: leaked ? GuideMood.warn : GuideMood.glad));
    setState(() {});
  }

  Future<void> _decide(GloveChoice c, Offset origin) async {
    final g = _held;
    if (g == null || _busy || _verdict != null) return;
    _busy = true;
    final roundBefore = _r.round;
    final o = _r.decide(g, c);
    if (!o.right && strike(DoMistake(key: 'glove/${g.id}', textBn: o.reasonBn, art: g.asset))) {
      await _struckOut();
      return;
    }
    if (o.right) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/stomp.wav', volume: o.right ? 0.45 : 0.7, muted: false));
    if (o.packs) {
      putOnTable(o.delta);
    } else {
      unawaited(_levelDelta(o.delta, origin, mood: o.right ? GuideMood.glad : GuideMood.warn));
      unawaited(_react(g, o));
    }

    setState(() => _verdict = o);
    await _dwell(Duration(milliseconds: o.reasonBn.isEmpty && o.wordBn.isEmpty ? 900 : 1400));
    if (!mounted) return;
    final gone = _gone = Completer<void>();
    setState(() => _leaving = true);
    await gone.future.timeout(const Duration(seconds: 1), onTimeout: () {});
    if (!mounted) return;
    setState(() {
      _overlay = _Overlay.none;
      _held = null;
      _verdict = null;
      _leaving = false;
    });
    _busy = false;
    if (_r.round != roundBefore) {
      // "কেন এই জোড়াটা নিলেন?" — the right reason pays the table, then the next pair.
      unawaited(askReason(
        deal: () => dealChoices(GloveLines.whyRight, GloveLines.whyWrong, widget.rng),
        question: GloveLines.whyAsk,
      ));
    }
  }

  Offset get _screenCentre {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * 0.45);
  }

  // --- the shared success beat (ReasonTable) ---------------------------------
  @override
  bool get reasonMuted => _muted;
  @override
  bool get reasonEnded => _ended;
  @override
  Future<void> reasonSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void reasonHush() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
  }

  @override
  Future<void> reasonScore(int delta, Offset origin, {GuideMood? mood}) => _levelDelta(delta, origin, mood: mood);
  @override
  void onReasonPaid() {
    if (_allDone) {
      unawaited(_finish());
    } else {
      unawaited(_askRound());
    }
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => _helmetPush ? HelmetLines.coworker : (_deal.caller.id == 'je' ? GloveLines.coworkerTrip : GloveLines.coworkerNew);

  /// The coworker's one push of this play falls on the helmet station.
  bool get _helmetPush => _deal.callBefore == 3;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _r.callDone || _r.round != _deal.callBefore) return null;
    if (_overlay != _Overlay.none || _busy || reasonOpen || _introCard || _card != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
  }

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    _r.answerCall(heldCheck: held);
    unawaited(_levelDelta(held ? 5 : -10, origin, mood: held ? GuideMood.glad : GuideMood.warn));
    if (direct) return;
    final next = [?_taskLine];
    if (held) {
      final chain = _chain;
      unawaited(() async {
        await coworkerSnarl();
        if (!mounted || chain != _chain) return;
        await _sayChain([_helmetPush ? HelmetLines.callHeld : GloveLines.callHeld, ...next], mood: GuideMood.glad);
      }());
    } else {
      unawaited(_sayChain([_helmetPush ? HelmetLines.callRushed : GloveLines.callRushed, ...next], mood: GuideMood.warn));
    }
  }

  /// Tap the guide: the task on screen again, a different way each time.
  final _nudge = TaskNudge();
  int _nudgeN = 0;
  void _tapGuide() {
    if (_introCard || _ended) return;
    final String? line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? GloveLines.tapWhy[_nudgeN++ % GloveLines.tapWhy.length]
            : (_taskLine == null ? null : _nudge.next(_taskLine!));
    if (line == null) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  /// A short word (or the fixed line, e.g. "আগে হাওয়া দিয়ে দেখুন!"); the
  /// reason is spoken the first time only, then shown as text.
  Future<void> _react(GloveItem g, GloveOutcome o) async {
    final chain = ++_chain;
    final mood = o.right ? GuideMood.glad : GuideMood.warn;
    final word = o.wordBn.isNotEmpty ? o.wordBn : (o.right ? _rightBag.next().shownBn : _wrongBag.next().shownBn);
    final speakReason = o.reasonBn.isNotEmpty && await SpokenOnce.first('glove/${widget.pack.id}/${g.lessonKey}');
    if (!mounted || chain != _chain) return;
    await _say(word, mood: mood);
    if (!mounted || chain != _chain || o.reasonBn.isEmpty) return;
    if (speakReason) {
      await _say(o.reasonBn, mood: mood);
    } else {
      ref.read(guideDirectorProvider.notifier).say(mood: mood, line: o.reasonBn);
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
    final mark = _percent;
    await save.recordLevelResult(_rungId, mark);
    if (!mounted) return;
    if (_passMark) {
      await save.markRungCleared(_rungId);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && _clock.elapsedMilliseconds < widget.pack.quickMs) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_passMark) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _passMark, strikes: strikes, quick: _clock.elapsedMilliseconds < widget.pack.quickMs);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_passMark ? GloveLines.fail : (_quickBonus ? GloveLines.quick : GloveLines.allSet),
        mood: _passMark ? GuideMood.celebrate : GuideMood.warn);
  }

  /// The third wrong decision: the level fails and the lesson card insists.
  Future<void> _struckOut() async {
    if (_ended) return;
    _ended = true;
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    _clock.stop();
    await recordStrikeOut(widget.ctx, percent: _percent, runScore: _runScore);
    if (!mounted) return;
    setState(() {
      _overlay = _Overlay.none;
      _held = null;
      _heldHelmet = null;
      _card = null;
      _busy = false;
    });
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leave() async {
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
    final tray = _tray;
    final shelf = _r.done ? _h.shelf : const <HelmetItem>[];
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final deckUp = reasonOpen || coworkerChoiceUp;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: SlmColors.navy950,
        body: ScoreFlyHost(
          scoreKey: _scoreKey,
          child: FullSceneFrame(
            ctx: widget.ctx,
            titleBn: widget.pack.titleBn,
            scoreKey: _scoreKey,
            levelScore: _runScore,
            muted: _muted,
            onClose: () => unawaited(_leave()),
            onToggleMute: () {
              unawaited(MascotSpeechLibrary.stop());
              setState(() => _muted = !_muted);
            },
            progress: DoProgress(
              labels: const [...GloveLines.rounds, HelmetLines.station],
              done: {for (var i = 0; i < _r.packed.length; i++) i, if (_h.done) 3},
              current: _station < 4 ? _station : null,
              quiet: quiet,
            ),
            layers: (context, m) => const [
              Positioned.fill(key: ValueKey('yard'), child: CustomPaint(painter: VanYardPainter())),
            ],
            overlays: [
              // The bag (three places) and the tray of gloves.
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      Expanded(
                        child: _Bag(
                          packed: [for (final g in _r.packed) g.asset, ?_h.packed?.asset],
                          quiet: quiet,
                          // With a deck up the corner guide stands higher: lift the
                          // bag to just under the ◆ so its last place stays in view.
                          liftTo: deckUp ? size.height * 0.22 + 30 - pad.top - 80 : null,
                        ),
                      ),
                      if (_mark == null)
                        Padding(
                          padding: EdgeInsets.only(bottom: pad.bottom),
                          child: _r.done
                              ? DoTray(
                                  key: ValueKey('tray-$_wave'),
                                  entries: [for (final h in shelf) DoTrayEntry(id: h.id, asset: h.asset)],
                                  quiet: quiet,
                                  muted: _muted,
                                  onPick: (n) => _pickHelmet(shelf[n]),
                                )
                              : DoTray(
                                  key: ValueKey('tray-$_wave'),
                                  entries: [for (final g in tray) DoTrayEntry(id: g.id, asset: g.asset)],
                                  quiet: quiet,
                                  muted: _muted,
                                  onPick: (n) => _pickUp(tray[n]),
                                ),
                        ),
                    ],
                  ),
                ),
              ),
              // The pair's ◆ waiting on the table.
              ...tableLayers(at: Offset(size.width / 2, size.height * 0.22), quiet: quiet),
              // The answers: level 1's cards — the reason, or the coworker choice.
              if (deckUp)
                Positioned(
                  key: const ValueKey('deck'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (!_introCard && _overlay == _Overlay.none && _mark == null && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 124), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_overlay == _Overlay.inspect && _held != null)
                _GloveInspect(
                  key: ValueKey('inspect-${_r.round}-${_held!.id}'),
                  item: _held!,
                  tested: _r.isTested(_held!),
                  verdict: _verdict,
                  leaving: _leaving,
                  quiet: quiet,
                  onTested: (leaked) => _onTested(_held!, leaked: leaked),
                  onPressMore: () => unawaited(_sayChain([GloveLines.pressMore])),
                  onDecide: (c, o) => unawaited(_decide(c, o)),
                  onTapCard: _skipDwell,
                  onTapShade: _putBack,
                  onGone: () {
                    final g = _gone;
                    if (g != null && !g.isCompleted) g.complete();
                  },
                ),
              if (_overlay == _Overlay.inspect && _heldHelmet != null)
                HelmetInspect(
                  key: ValueKey('helmet-${_heldHelmet!.id}'),
                  item: _heldHelmet!,
                  stampDate: helmetStampDate(_heldHelmet!, _h.deal, DateTime.now()),
                  checks: _h.checksOf(_heldHelmet!),
                  verdict: _verdict,
                  leaving: _leaving,
                  quiet: quiet,
                  muted: _muted,
                  onCheck: (c) => setState(() => _h.markChecked(_heldHelmet!, c)),
                  onSay: (l) => unawaited(_sayChain([l])),
                  onDecide: (c, o) => unawaited(_decideHelmet(c, o)),
                  onTapCard: _skipDwell,
                  onTapShade: _putBack,
                  onGone: () {
                    final g = _gone;
                    if (g != null && !g.isCompleted) g.complete();
                  },
                ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}'),
                  mistake: _card!,
                  tone: MistakeTone.slip,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null
                      ? null
                      : () {
                          _chain++;
                          unawaited(MascotSpeechLibrary.stop());
                          unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: _card!.lessonPoint, muted: _muted));
                        },
                  onGo: _cardGo,
                ),
              if (struckOut)
                StruckOutCard(
                  key: const ValueKey('struck'),
                  mistake: strikeOutBy!,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.thud,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_introCard)
                GuideIntro(
                  line: GloveLines.intro,
                  alarm: 'sounds/learn/rush_in.wav',
                  muted: _muted,
                  onDone: () {
                    setState(() => _introCard = false);
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
                        child: _passMark
                            ? LevelPassPanel(
                                mark: _mark!,
                                levelScore: _runScore,
                                totalDelta: _totalDelta,
                                ms: _clock.elapsedMilliseconds,
                                caughtBn: [for (final c in _r.caught) c.labelBn, for (final c in _h.caught) c.labelBn],
                                quickBonus: _quickBonus,
                                stars: _stars,
                                onNext: () => _popOnce(true),
                                onRetry: () => widget.onRetry(_muted),
                              )
                            : LevelFailPanel(
                                percent: _mark!,
                                muted: _muted,
                                onRetry: () => widget.onRetry(_muted),
                                onLeave: () => _popOnce(false),
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

/// The bag by the van: four places (নিজের / সাথীর / বাড়তি গ্লাভস, then the
/// helmet) that fill with each checked item, popping in once.
class _Bag extends StatelessWidget {
  const _Bag({required this.packed, required this.quiet, this.liftTo});

  /// Pictures of what is packed, in order (three pairs, then the helmet).
  final List<String> packed;
  final bool quiet;

  /// When set, the bag's top sits this far below its area's top (a deck is
  /// up and the corner guide stands over the middle); else it is centred.
  final double? liftTo;

  static const _labels = [...GloveLines.rounds, HelmetLines.station];

  @override
  Widget build(BuildContext context) {
    final px = (100 * MediaQuery.devicePixelRatioOf(context)).round();
    return LayoutBuilder(
      builder: (context, box) {
        final slot = math.min(88.0, (box.maxWidth - 24 - 4 * 10) / 4);
        // The bag's height: the slot, the gap and the label line.
        final tall = slot * 1.16 + 6 + 22;
        final free = box.maxHeight - tall;
        final top = liftTo;
        final y = top == null || free <= 0 ? 0.0 : (2 * top.clamp(0.0, free) / free - 1).clamp(-1.0, 0.0);
        return AnimatedAlign(
          alignment: Alignment(0, y),
          duration: quiet ? Duration.zero : const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _labels.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: slot,
                        height: slot * 1.16,
                        decoration: BoxDecoration(
                          color: const Color(0xAA0B1324),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: SlmColors.gold400.withValues(alpha: i < packed.length ? 0.9 : 0.3), width: i < packed.length ? 2 : 1),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: i < packed.length
                            ? TweenAnimationBuilder<double>(
                                tween: Tween(begin: quiet ? 1 : 0, end: 1),
                                duration: const Duration(milliseconds: 520),
                                curve: Curves.easeOutBack,
                                builder: (_, t, child) => Transform.scale(scale: 0.4 + 0.6 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
                                child: Image(image: ResizeImage(AssetImage(packed[i]), height: px, policy: ResizeImagePolicy.fit), fit: BoxFit.contain),
                              )
                            : Icon(i < 3 ? Icons.back_hand_outlined : Icons.engineering_outlined, color: SlmColors.gold400.withValues(alpha: 0.35), size: 30),
                      ),
                      const SizedBox(height: 6),
                      Text(_labels[i], style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Close look at a pair. Rubber pairs get the air test: press and hold, the
/// cuff rolls and the glove puffs up; let go — a sound pair stays puffed, a
/// pinholed one hisses flat with air puffing out of the hole. Then decide.
class _GloveInspect extends StatefulWidget {
  const _GloveInspect({
    super.key,
    required this.item,
    required this.tested,
    required this.verdict,
    required this.leaving,
    required this.quiet,
    required this.onTested,
    required this.onPressMore,
    required this.onDecide,
    required this.onTapCard,
    required this.onTapShade,
    required this.onGone,
  });

  final GloveItem item;
  final bool tested;
  final GloveOutcome? verdict;
  final bool leaving;
  final bool quiet;
  final ValueChanged<bool> onTested;
  final VoidCallback onPressMore;
  final void Function(GloveChoice c, Offset origin) onDecide;
  final VoidCallback onTapCard;
  final VoidCallback onTapShade;
  final VoidCallback onGone;

  @override
  State<_GloveInspect> createState() => _GloveInspectState();
}

class _GloveInspectState extends State<_GloveInspect> with TickerProviderStateMixin {
  late final AnimationController _lift = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  late final AnimationController _air = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _leak = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final AnimationController _stamp = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final AnimationController _exit = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  var _holding = false;
  bool? _leaked;

  @override
  void initState() {
    super.initState();
    if (widget.quiet) {
      _lift.value = 1;
    } else {
      _lift.forward();
    }
    _exit.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onGone();
    });
  }

  @override
  void didUpdateWidget(_GloveInspect old) {
    super.didUpdateWidget(old);
    if (widget.verdict != null && old.verdict == null) {
      if (widget.quiet) {
        _stamp.value = 1;
      } else {
        _stamp.forward(from: 0);
      }
    }
    if (widget.leaving && !old.leaving) {
      if (widget.quiet) {
        _exit.value = 1;
        widget.onGone();
      } else {
        _exit.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _lift.dispose();
    _air.dispose();
    _leak.dispose();
    _stamp.dispose();
    _exit.dispose();
    super.dispose();
  }

  void _pressStart() {
    if (widget.verdict != null || _leaked != null) return;
    HapticFeedback.selectionClick();
    setState(() => _holding = true);
    if (widget.quiet) {
      _air.value = 1;
    } else {
      _air.forward();
    }
  }

  void _pressEnd() {
    if (!_holding) return;
    setState(() => _holding = false);
    if (_air.value < 0.85) {
      _air.reverse();
      widget.onPressMore();
      return;
    }
    final leaked = widget.item.leaks;
    setState(() => _leaked = leaked);
    if (leaked) {
      // Slowly flat, with air puffing out of the hole.
      if (widget.quiet) {
        _leak.value = 1;
      } else {
        _leak.forward(from: 0);
      }
    }
    widget.onTested(leaked);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.item;
    final v = widget.verdict;
    final px = (300 * MediaQuery.devicePixelRatioOf(context)).round();
    final canTest = g.rubber && v == null && _leaked == null && !widget.tested;
    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 26),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: SlmColors.ivory,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            g.rubber ? 'ভালো করে দেখুন · হাওয়া দিয়ে দেখুন' : 'ভালো করে দেখুন',
            style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.gold700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 230,
            child: Center(
              child: AspectRatio(
                aspectRatio: g.aspect,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_air, _leak]),
                  builder: (_, child) {
                    // Puffed by the held breath; a leak lets it down again.
                    final puff = Curves.easeOut.transform(_air.value) * (1 - Curves.easeIn.transform(_leak.value));
                    return Transform.scale(scale: 1 + 0.12 * puff, child: Stack(fit: StackFit.expand, clipBehavior: Clip.none, children: [
                      child!,
                      if (_leak.value > 0 && _leak.value < 1 && g.flaw != null) CustomPaint(painter: _AirPuffPainter(g.flaw!.marks.first, _leak.value)),
                    ]));
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image(image: ResizeImage(AssetImage(g.asset), height: px, policy: ResizeImagePolicy.fit), fit: BoxFit.fill),
                      if (g.flaw?.kind == GloveFlawKind.crack) CustomPaint(painter: _CrackPainter(g.flaw!.marks)),
                      if (v != null && g.flaw != null) CustomPaint(painter: DoPulsePainter(g.flaw!.marks, _stamp)),
                      if (v != null)
                        AnimatedBuilder(
                          animation: _stamp,
                          builder: (_, _) {
                            final t = Curves.easeOutBack.transform((_stamp.value / 0.3).clamp(0.0, 1.0));
                            return Center(
                              child: Opacity(
                                opacity: t.clamp(0.0, 1.0),
                                child: Transform.rotate(
                                  angle: -0.22,
                                  child: Transform.scale(scale: 2.2 - 1.2 * t, child: DoStamp(text: v.stampBn, good: v.stampBn == gloveStampRight)),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_leaked != null && v == null) ...[
            const SizedBox(height: 8),
            Text(
              _leaked! ? GloveLines.leaks : GloveLines.holds,
              style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: _leaked! ? SlmColors.danger : SlmColors.emerald500),
            ),
          ],
          const SizedBox(height: 12),
          if (canTest) ...[
            // Raw pointer events: a long hold must not be cancelled as a "tap".
            Listener(
              onPointerDown: (_) => _pressStart(),
              onPointerUp: (_) => _pressEnd(),
              onPointerCancel: (_) => _pressEnd(),
              child: AnimatedBuilder(
                animation: _air,
                builder: (_, _) => Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [SlmColors.emerald500, SlmColors.emerald500, SlmColors.emerald500.withValues(alpha: 0.25)],
                      stops: [0, _air.value, _air.value],
                    ),
                    border: Border.all(color: SlmColors.emerald500),
                  ),
                  child: Text(
                    GloveLines.testButton,
                    style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: _holding ? Colors.white : SlmColors.ink),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (v == null)
            Row(
              children: [
                Expanded(child: DoBigButton(label: 'বাদ দিন', filled: false, onTapUp: (d) => widget.onDecide(GloveChoice.reject, d.globalPosition))),
                const SizedBox(width: 12),
                Expanded(child: DoBigButton(label: 'নিয়ে নিন', filled: true, onTapUp: (d) => widget.onDecide(GloveChoice.wear, d.globalPosition))),
              ],
            )
          else
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (v.right ? SlmColors.emerald500 : SlmColors.danger).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                v.reasonBn.isNotEmpty ? v.reasonBn : (v.wordBn.isNotEmpty ? v.wordBn : (v.packs ? 'ব্যাগে তোলা হলো।' : '')),
                textAlign: TextAlign.center,
                style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.35),
              ),
            ),
        ],
      ),
    );

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: v == null ? widget.onTapShade : widget.onTapCard,
              child: AnimatedBuilder(
                animation: Listenable.merge([_lift, _exit]),
                child: GestureDetector(onTap: v == null ? () {} : widget.onTapCard, child: card),
                builder: (_, child) {
                  final lift = Curves.easeOutBack.transform(_lift.value);
                  final e = Curves.easeInCubic.transform(_exit.value);
                  var dx = 0.0, dy = 0.0, rot = 0.0, scale = 0.7 + 0.3 * lift;
                  var fade = 1.0;
                  if (v != null && _exit.value > 0) {
                    if (v.packs) {
                      dy = -200 * e; // into the bag
                      scale *= 1 - 0.8 * e;
                    } else if (v.leavesTray) {
                      dx = 420 * e; // back to the store
                      rot = 0.6 * e;
                    } else {
                      dx = math.sin(_exit.value * math.pi * 6) * 14 * (1 - _exit.value); // shake back to the tray
                      scale *= 1 - 0.3 * e;
                    }
                    fade = 1 - e;
                  }
                  return ColoredBox(
                    color: Color.fromRGBO(5, 10, 22, 0.8 * (1 - e)),
                    child: Align(
                      alignment: const Alignment(0, -0.4),
                      child: Opacity(
                        opacity: (fade * _lift.value).clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(dx, dy + 40 * (1 - lift)),
                          child: Transform.rotate(angle: rot, child: Transform.scale(scale: scale, child: child)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (!widget.leaving) const Positioned(left: 0, right: 0, bottom: 8, child: DoCoachStrip()),
        ],
      ),
    );
  }
}

/// Little puffs of air escaping from the pinhole.
class _AirPuffPainter extends CustomPainter {
  _AirPuffPainter(this.hole, this.t);
  final Offset hole;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(hole.dx * size.width, hole.dy * size.height);
    for (var i = 0; i < 5; i++) {
      final p = ((t * 2.5) + i / 5) % 1;
      final a = -0.9 + i * 0.35;
      final o = c + Offset(math.cos(a), math.sin(a)) * (8 + 36 * p);
      canvas.drawCircle(o, 3 + 5 * p, Paint()..color = Colors.white.withValues(alpha: 0.75 * (1 - p)));
    }
  }

  @override
  bool shouldRepaint(_AirPuffPainter old) => old.t != t;
}

/// Hairline cracks in the rubber (placeholder until photos exist).
class _CrackPainter extends CustomPainter {
  _CrackPainter(this.marks);
  final List<Offset> marks;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xCC1A1208);
    for (final m in marks) {
      final c = Offset(m.dx * size.width, m.dy * size.height);
      final s = size.width * 0.09;
      final path = Path()
        ..moveTo(c.dx - s * 0.6, c.dy - s * 0.2)
        ..lineTo(c.dx - s * 0.2, c.dy + s * 0.1)
        ..lineTo(c.dx + s * 0.1, c.dy - s * 0.15)
        ..lineTo(c.dx + s * 0.5, c.dy + s * 0.2)
        ..moveTo(c.dx + s * 0.1, c.dy - s * 0.15)
        ..lineTo(c.dx + s * 0.2, c.dy - s * 0.5);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_CrackPainter old) => old.marks != marks;
}
