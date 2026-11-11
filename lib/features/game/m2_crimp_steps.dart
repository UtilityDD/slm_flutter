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
import 'choice_deck.dart';
import 'coworker_moment.dart';
import 'do_parts.dart';
import 'full_scene_frame.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm2_crimp_steps_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 2.3 "ল্যাগস ক্রিম্পিং: সঠিক চাপ, নিরাপদ কানেকশন", কাজ 2 "ক্রিম্প করো
// ঠিকঠাক" (pack do_2_3_b, engineType m2_crimp_steps). Pure rules: the deal,
// the play state, the lines and the mistakes. The page is m2_crimp_steps.dart.
//
// The lesson's rules, and only those:
//   • golden rules (point 2): strip to the right length (the conductor goes
//     fully into the barrel, the insulation stays outside), clean the conductor
//     with a clean brush; insert it fully (no strand outside); the right-size
//     die, the tool on the barrel, full pressure until the tool releases by
//     itself (pro tip 2: a half press is weak); then pull-test by hand and look
//     at the shape;
//   • the match (point 1): wire, lug and die the same size; a wrong die makes
//     the crimp too loose or too tight;
//   • why (point 0 + the briefing): a right crimp is airtight and keeps the
//     resistance low, so the joint does not heat; a loose one overheats —
//     fire or a blackout;
//   • good vs bad (point 3): smooth symmetric (hexagonal) shape, clear die
//     marks, no crack, every strand inside; bad = under-crimped, over-crimped
//     (cracked), wrong shape, strands outside;
//   • myths: ordinary pliers can't give the right pressure or shape; solder
//     after a crimp makes it worse;
//   • pro tip 3: anti-oxidant paste on aluminium is "a good habit" — so it
//     earns the +5 but leaving it out is not a slip.
// Not in the lesson (left out, flagged in REGISTER.md): how many crimps a
// barrel takes and where along it to start; a hammer; any rating or size
// threshold for a hand vs a hydraulic tool (both jobs here are small lugs on
// the hand crimper).
// No deadly move: the lesson's harm from a bad crimp is heat at the joint
// later (shown as the joint glowing under load), not a hazard to the worker.

/// What the conductor is.
enum CrimpMetal { al, cu }

/// The steps of a crimp (the tray, dealt in a fresh order every round).
enum CrimpStep { strip, clean, paste, insert, die, crimp, pull, fit }

/// A crimped lug on the inspection tray.
enum LugKind { good, cracked, strands, under, pliers }

/// One job: a cable and its lug on the bench.
@immutable
class CrimpJob {
  const CrimpJob({required this.size, required this.metal, required this.marks, required this.dies});

  /// sq. mm of the cable, the lug and the right die.
  final int size;
  final CrimpMetal metal;

  /// Where the strip marks sit on the insulation, as × the barrel's depth
  /// (1.0 = the right length); one is 1.0.
  final List<double> marks;

  /// The dies on the rack (sq. mm), one of them [size].
  final List<int> dies;

  bool get al => metal == CrimpMetal.al;
}

/// One round: a crimp to make ([job]) or a tray to inspect ([lugs]).
@immutable
class CrimpRound {
  const CrimpRound.make(CrimpJob this.job) : lugs = const [];
  const CrimpRound.inspect(this.lugs) : job = null;
  final CrimpJob? job;
  final List<LugKind> lugs;
  bool get inspect => job == null;
}

@immutable
class CrimpDeal {
  const CrimpDeal({required this.rounds, required this.callAt});
  final List<CrimpRound> rounds;

  /// The make-round where the careless coworker comes (at the crimp).
  final int callAt;
}

/// Three rounds: two crimps to make (a small lug each, different sizes; Al or
/// Cu), and one tray of four crimped lugs to inspect (the 2nd or the 3rd
/// round): one or two good, the rest bad of different kinds. The strip marks
/// are three of five places (the right one always there); the die rack holds
/// three sizes (the right one always there). The coworker comes on one of the
/// two make-rounds.
CrimpDeal dealCrimp(math.Random rng) {
  final sizes = [...kCrimpSizes]..shuffle(rng);
  CrimpJob job(int size) {
    final others = [...kStripMarks.where((m) => m != 1.0)]..shuffle(rng);
    final marks = [1.0, others[0], others[1]]..sort();
    final near = [...kDieSizes.where((d) => d != size)]..shuffle(rng);
    final dies = [size, near[0], near[1]]..sort();
    return CrimpJob(size: size, metal: rng.nextBool() ? CrimpMetal.al : CrimpMetal.cu, marks: marks, dies: dies);
  }

  final good = 1 + rng.nextInt(2);
  final bad = [LugKind.cracked, LugKind.strands, LugKind.under, LugKind.pliers]..shuffle(rng);
  final lugs = [for (var i = 0; i < good; i++) LugKind.good, ...bad.take(4 - good)]..shuffle(rng);
  final at = 1 + rng.nextInt(2);
  final rounds = <CrimpRound>[CrimpRound.make(job(sizes[0])), CrimpRound.make(job(sizes[1]))];
  rounds.insert(at, CrimpRound.inspect(lugs));
  final makes = [
    for (final (i, r) in rounds.indexed)
      if (!r.inspect) i,
  ];
  return CrimpDeal(rounds: rounds, callAt: makes[rng.nextInt(2)]);
}

/// Small lugs (the hand crimper): sq. mm, the lesson's own 16 among them.
const kCrimpSizes = [10, 16, 25];

/// The dies a hand-crimper set carries (sq. mm).
const kDieSizes = [6, 10, 16, 25, 35];

/// Strip-mark places, × the barrel's depth.
const kStripMarks = [0.5, 0.75, 1.0, 1.3, 1.6];

/// What pulling does.
enum PullResult { nothing, slidOut, held }

/// The play state (pure logic).
class CrimpRun {
  CrimpRun(this.deal);
  final CrimpDeal deal;
  int index = 0;
  int slips = 0;
  final List<String> caught = [];

  // A make-round.
  var stripped = false;
  var cleaned = false;
  var pasted = false;

  /// How far the conductor is in the barrel (0–1).
  double inserted = 0;
  int? die;
  var onBarrel = false;
  var crimped = false;
  var pulled = false;

  // The inspection.
  final Set<int> rejected = {};

  /// The round is over (the reason or the card is up).
  var shown = false;

  bool get done => index >= deal.rounds.length;
  bool get ended => done;
  CrimpRound get current => deal.rounds[index.clamp(0, deal.rounds.length - 1)];
  CrimpJob get job => current.job!;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get fullyIn => inserted >= 1;

  /// The +5: the aluminium got its anti-oxidant paste (a copper job: always).
  bool get thorough => current.inspect ? needless == 0 : (!job.al || pasted);

  /// Good lugs marked to reject on this tray (put back, not scored).
  int needless = 0;

  bool get _open => !ended && !shown;

  DoMistake _slip(DoMistake m) {
    slips++;
    if (CrimpMistakes.ruins.contains(m)) shown = true;
    return m;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Cuts the insulation at mark [factor] (× the barrel's depth).
  DoMistake? strip(double factor) {
    if (!_open || current.inspect || stripped) return null;
    if ((factor - 1.0).abs() > 0.01) return _slip(CrimpMistakes.stripLength);
    stripped = true;
    return null;
  }

  DoMistake? clean() {
    if (!_open || current.inspect || cleaned) return null;
    if (!stripped) return _slip(CrimpMistakes.prep);
    cleaned = true;
    return null;
  }

  /// Aluminium only (a copper job has no paste).
  DoMistake? paste() {
    if (!_open || current.inspect || pasted || !job.al) return null;
    if (!cleaned) return _slip(CrimpMistakes.prep);
    pasted = true;
    return null;
  }

  /// May the conductor go in now? null = yes.
  DoMistake? startInsert() {
    if (!_open || current.inspect) return null;
    if (!stripped || !cleaned) return _slip(CrimpMistakes.prep);
    return null;
  }

  void setInserted(double v) {
    if (_open && stripped && cleaned && !crimped) inserted = v.clamp(0.0, 1.0);
  }

  void pickDie(int size) {
    if (_open && !current.inspect && !crimped) die = size;
  }

  /// May the tool go on now? null = yes (then [place], then [press]).
  DoMistake? startCrimp() {
    if (!_open || current.inspect || crimped) return null;
    if (!fullyIn) return _slip(CrimpMistakes.notIn);
    if (die == null) return _slip(CrimpMistakes.noDie);
    return null;
  }

  /// The tool goes on the barrel ([barrel]) or on the palm.
  DoMistake? place({required bool barrel}) {
    if (!_open || current.inspect || crimped) return null;
    if (!barrel) return _slip(CrimpMistakes.onPalm);
    onBarrel = true;
    return null;
  }

  /// The press ends at [reached] of the tool's cycle (1 = it released itself).
  DoMistake? press(double reached) {
    if (!_open || current.inspect || crimped || !onBarrel) return null;
    if (reached < 1) return _slip(CrimpMistakes.halfPress);
    if (die != job.size) return _slip(CrimpMistakes.wrongDie);
    crimped = true;
    return null;
  }

  /// Squeezed with pliers (listened to the coworker).
  DoMistake pliers() => _slip(CrimpMistakes.pliers);

  /// Pull by hand: a crimp holds; an uncrimped conductor slides out.
  PullResult pull() {
    if (!_open || current.inspect) return PullResult.nothing;
    if (crimped) {
      pulled = true;
      return PullResult.held;
    }
    if (inserted > 0) {
      inserted = 0;
      return PullResult.slidOut;
    }
    return PullResult.nothing;
  }

  /// Fit the lug to its terminal: only after the pull test. null = the round
  /// is right (then [shown]).
  DoMistake? fit() {
    if (!_open || current.inspect) return null;
    if (!pulled) return _slip(CrimpMistakes.noPull);
    shown = true;
    _tag(CrimpLines.caughtSteps);
    if (job.al && pasted) _tag(CrimpLines.caughtPaste);
    _tag(CrimpLines.caughtPull);
    return null;
  }

  /// A bad crimp was made: cut the lug off and start this job again.
  void redo() {
    stripped = cleaned = pasted = crimped = pulled = onBarrel = false;
    inserted = 0;
    die = null;
    shown = false;
  }

  // --- the inspection ---------------------------------------------------------
  void toggle(int i) {
    if (!_open || !current.inspect) return;
    if (!rejected.remove(i)) rejected.add(i);
  }

  /// Good lugs marked to reject: not scored (redoing is never wrong), the
  /// guide says why they are good and they are put back ([unreject]).
  List<int> get falseRejects => [
        for (final i in rejected)
          if (current.lugs[i] == LugKind.good) i,
      ]..sort();

  void unreject(Iterable<int> ids) {
    if (ids.isEmpty) return;
    needless++;
    rejected.removeAll(ids);
  }

  /// Bad lugs not marked.
  List<int> get missed => [
        for (final (i, k) in current.lugs.indexed)
          if (k != LugKind.good && !rejected.contains(i)) i,
      ];

  /// The tray is checked. Returns the mistake for the first bad lug let
  /// through (one slip however many), or null when every bad one was caught.
  /// Call only with no [falseRejects] (the page handles them first).
  DoMistake? passTray() {
    if (!_open || !current.inspect) return null;
    shown = true;
    final m = missed;
    if (m.isNotEmpty) {
      slips++;
      return CrimpMistakes.passed(current.lugs[m.first]);
    }
    for (final k in current.lugs) {
      if (k != LugKind.good) _tag(CrimpLines.caughtKind(k));
    }
    return null;
  }

  void next() {
    index++;
    redo();
    rejected.clear();
    needless = 0;
  }
}

abstract final class CrimpLines {
  static const title = 'ক্রিম্প করো ঠিকঠাক';
  static const intro = 'ল্যাগ লাগানোর কাজ! দুর্বল ক্রিম্প পরে গরম হয়ে পোড়ে — ধাপে ধাপে, ঠিকঠাক ক্রিম্প করুন।';
  static const rounds = ['ক', 'খ', 'গ'];
  static const askMake = 'তার আর ল্যাগ তৈরি। ধাপে ধাপে ক্রিম্প করুন।';
  static const askInspect = 'এই ল্যাগগুলো দেখুন। খারাপগুলো বাতিল করুন।';
  static const askStrip = 'কোন দাগে ছিলবেন?';
  static const askDie = 'কোন ডাই বসাবেন?';
  static const askPlace = 'টুল কোথায় বসাবেন? ল্যাগে ছুঁয়ে দেখান।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askMake, askInspect];

  // Labels a worker reads (the tray, the hold pad, the bench).
  static const sceneLabel = 'বেঞ্চ, তার আর ল্যাগ';
  static String stepBn(CrimpStep s) => switch (s) {
        CrimpStep.strip => 'ছিলুন',
        CrimpStep.clean => 'ব্রাশ',
        CrimpStep.paste => 'পেস্ট',
        CrimpStep.insert => 'ঢোকান',
        CrimpStep.die => 'ডাই',
        CrimpStep.crimp => 'ক্রিম্প',
        CrimpStep.pull => 'টেনে দেখুন',
        CrimpStep.fit => 'লাগান',
      };
  static const holdInsert = 'চেপে ঠেলুন';
  static const holdCrimp = 'চেপে ধরুন';
  static const trayDone = 'পরীক্ষা শেষ';
  static const reject = 'বাতিল';
  static String mm(int v) => enDigits('$v');
  static String cablePrint(CrimpJob j) => enDigits('${j.size} sq.mm ${j.al ? 'AL' : 'CU'}');
  static String dieBn(int v) => enDigits('$v mm²');

  static const stampDone = 'লাগানো হলো';
  static const stampTray = 'বাছাই হলো';
  static const slidOut = 'টানতেই তার বেরিয়ে এল — আগে ক্রিম্প।';

  // The reasons (lesson 2.3): every card 30–38 letters, so none stands out.
  static const whyMake = 'ঠিকঠাক ক্রিম্প কেন এত জরুরি?';
  static const whyTray = 'কেন এগুলো বাতিল করলেন?';
  static const makeWhy = [
    'ঠিক ক্রিম্প বাতাসরোধী, তাই মরিচা ধরে না',
    'রেজিস্ট্যান্স কম থাকে, তাই জোড়া গরম হয় না',
    'লুজ ক্রিম্পই লাইনে বহু ফল্টের মূল কারণ',
  ];
  static const pasteWhy = 'অ্যালুমিনিয়ামে পেস্ট দিলে অক্সিডেশন কমে';
  static const trayWhy = [
    'ভালো ক্রিম্প মসৃণ ষড়ভুজ, কোনো ফাটল নেই',
    'খারাপ ক্রিম্প আবার করা লজ্জা নয়, দক্ষতা',
    'খারাপ জোড়া লোডে গরম হয়, আগুনও ধরে',
  ];

  /// Wrong reasons: the lesson's myths and field excuses (never a true rule).
  static const myths = [
    'পরে সোল্ডার করে দিলে আরও মজবুত হবে',
    'যেকোনো প্লায়ার্সেও একই কাজ হয়ে যায়',
    'ক্রিম্প একটু আলগা হলেও কারেন্ট চলবে',
    'তাড়াতাড়ি শেষ হলে সুপারভাইজার খুশি',
    'ল্যাগের সাইজ নিয়ে এত ভাবার কিছু নেই',
    'অর্ধেক চাপই যথেষ্ট, পুরো চাপে ফাটে',
  ];

  static List<String> whyRight(CrimpRound r, {bool pasted = false}) =>
      r.inspect ? trayWhy : [...makeWhy, if (pasted && r.job!.al) pasteWhy];

  /// Good lugs marked to reject (not scored): the guide says why they are good.
  static const goodLug = 'এটা ভালো ক্রিম্প — মসৃণ ষড়ভুজ, ফাটল নেই, সব স্ট্র্যান্ড ভেতরে। আবার দেখুন।';

  /// The careless coworker: squeeze it with pliers (the lesson's myth). His
  /// push is new (device TTS until recorded); his snarl is recorded.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'এত ঝামেলা কেন? ছোট ল্যাগ তো — প্লায়ার্স দিয়ে চেপে দাও!',
    exitLine: coworkerExit,
    right: ['না, ক্রিম্পিং টুল আর ঠিক ডাই দিয়েই করব', 'না, প্লায়ার্সে ঠিক চাপ বা আকার আসে না', 'না, দুর্বল জোড়া পরে গরম হয়ে পুড়বে'],
    wrong: ['ঠিক, প্লায়ার্সেই চেপে দিই, তাড়াতাড়ি', 'আচ্ছা, এত ছোট ল্যাগে টুল লাগে না', 'প্লায়ার্সে জোরে চাপলেই হয়ে যাবে', 'সবাই তো প্লায়ার্স দিয়েই চেপে দেয়', 'ঠিক আছে, চেপে দিয়ে পরে সোল্ডার করব'],
    asks: ['ও বলছে প্লায়ার্সে চেপে দিতে। আপনি কী করবেন?', 'টুল দিয়ে করবেন, না প্লায়ার্সে?', 'ওর কথা শুনবেন, না পাঠের?'],
  );

  static const callHeld = 'ঠিক! ঠিক টুল, ঠিক ডাই — তবেই ঠিক ক্রিম্প।';
  static const redo = 'এই ল্যাগ কেটে ফেলুন। নতুন করে, ধাপে ধাপে।';
  static const allSet = 'ক্রিম্প শিখে গেছেন — মাপ, পরিষ্কার, পুরো চাপ, টেনে দেখা।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ধাপগুলো পাঠে দেখে নিন, তারপর ঠিকঠাক ক্রিম্প।';

  // "আজ যা ধরলেন".
  static const caughtSteps = 'মাপ, পরিষ্কার, পুরো ঢোকানো, পুরো চাপ';
  static const caughtPaste = 'অ্যালুমিনিয়ামে অ্যান্টি-অক্সিডেন্ট পেস্ট';
  static const caughtPull = 'লাগানোর আগে পুল টেস্ট';
  static const caughtCall = 'প্লায়ার্সকে “না” বলেছেন';
  static String caughtKind(LugKind k) => switch (k) {
        LugKind.cracked => 'ফাটা ল্যাগ ধরেছেন',
        LugKind.strands => 'বাইরে স্ট্র্যান্ড ধরেছেন',
        LugKind.under => 'আন্ডার-ক্রিম্প ধরেছেন',
        LugKind.pliers => 'প্লায়ার্সে চাপা ল্যাগ ধরেছেন',
        LugKind.good => '',
      };

  /// Every fixed guide line (for recording).
  static List<String> get guideLines => [
        intro,
        askMake,
        askInspect,
        askStrip,
        askDie,
        askPlace,
        ...tapWhy,
        whyMake,
        whyTray,
        slidOut,
        goodLug,
        ...coworker.asks,
        callHeld,
        redo,
        allSet,
        quick,
        fail,
        for (final m in CrimpMistakes.all) m.textBn,
      ];
}

abstract final class CrimpMistakes {
  static const _dir = 'assets/game/art/m2_crimp_steps';
  static const prep = DoMistake(
    key: '2.3/crimp/no-prep',
    textBn: 'আগে প্রস্তুতি: মাপমতো ইনসুলেশন ছিলুন, তারপর পরিষ্কার ব্রাশে কন্ডাক্টর পরিষ্কার — তেল বা ময়লা থাকলে রেজিস্ট্যান্স বাড়ে।',
    art: '$_dir/crimp_prep.svg',
    lessonPoint: 2,
  );
  static const stripLength = DoMistake(
    key: '2.3/crimp/strip-length',
    textBn: 'ছিলতে হয় ঠিক মাপে — কন্ডাক্টর পুরোটা ব্যারেলে ঢুকবে, আর ইনসুলেশন থাকবে ব্যারেলের বাইরে। ল্যাগ পাশে রেখে মেপে নিন।',
    art: '$_dir/crimp_strip.svg',
    lessonPoint: 2,
  );
  static const notIn = DoMistake(
    key: '2.3/crimp/not-fully-in',
    textBn: 'কন্ডাক্টর পুরো ঢোকেনি — এমন ক্রিম্প আলগা থাকে, লোডে গরম হয়। আগে কন্ডাক্টর পুরোটা ঢোকান, কোনো স্ট্র্যান্ড বাইরে নয়।',
    art: '$_dir/crimp_not_in.svg',
    lessonPoint: 2,
  );
  static const noDie = DoMistake(
    key: '2.3/crimp/no-die',
    textBn: 'ডাই না মিলিয়েই টুল চালালেন। দুইবার মাপুন, একবার ক্রিম্প — তার, ল্যাগ আর ডাই, তিনটের সাইজ এক হতে হবে।',
    art: '$_dir/crimp_die.svg',
    lessonPoint: 1,
  );
  static const wrongDie = DoMistake(
    key: '2.3/crimp/wrong-die',
    textBn: 'ভুল সাইজের ডাই — ক্রিম্প হয় ঢিলা, নয়তো বেশি টাইট হয়ে কন্ডাক্টর ভেতরে জখম হয়। ডাই মিলবে তার আর ল্যাগের সাইজে।',
    art: '$_dir/crimp_die.svg',
    lessonPoint: 1,
  );
  static const onPalm = DoMistake(
    key: '2.3/crimp/on-palm',
    textBn: 'টুল বসাতে হয় ল্যাগের ব্যারেলের ওপর, যেখানে কন্ডাক্টর আছে — চ্যাপ্টা পামের ওপর চাপলে তার ধরেই না।',
    art: '$_dir/crimp_place.svg',
    lessonPoint: 2,
  );
  static const halfPress = DoMistake(
    key: '2.3/crimp/half-press',
    textBn: 'অর্ধেক চাপে ক্রিম্প দুর্বল (আন্ডার-ক্রিম্প) — পুরো চাপ দিন, যতক্ষণ না টুল নিজে থেকে রিলিজ হয়।',
    art: '$_dir/crimp_half.svg',
    lessonPoint: 2,
  );
  static const noPull = DoMistake(
    key: '2.3/crimp/no-pull-test',
    textBn: 'পুল টেস্ট না করেই লাগালেন। ক্রিম্পের পর হাতে জোরে টেনে দেখুন — আলগা হলে চলবে না; আকারটাও মসৃণ, ঠিক হতে হবে।',
    art: '$_dir/crimp_pull.svg',
    lessonPoint: 2,
  );

  /// The myth (no lesson point: "পাঠে দেখুন" opens the lesson from its start).
  static const pliers = DoMistake(
    key: '2.3/crimp/pliers',
    textBn: 'সাধারণ প্লায়ার্সে ঠিক চাপ বা ঠিক আকার আসে না — জোড়া দুর্বল, লোডে গরম হয়। সবসময় সঠিক ক্রিম্পিং টুল।',
    art: '$_dir/crimp_pliers.svg',
  );

  static const passCracked = DoMistake(
    key: '2.3/crimp/passed-cracked',
    textBn: 'ফাটা ল্যাগ পাস করলেন — অতিরিক্ত চাপে (ওভার-ক্রিম্প) ল্যাগ ফেটেছে। এটা কেটে আবার করতে হয়।',
    art: '$_dir/crimp_cracked.svg',
    lessonPoint: 3,
  );
  static const passStrands = DoMistake(
    key: '2.3/crimp/passed-strands',
    textBn: 'স্ট্র্যান্ড বাইরে বেরিয়ে আছে — খারাপ ক্রিম্প। কন্ডাক্টরের সব স্ট্র্যান্ড ব্যারেলের ভেতরে থাকতে হবে।',
    art: '$_dir/crimp_strands.svg',
    lessonPoint: 3,
  );
  static const passUnder = DoMistake(
    key: '2.3/crimp/passed-under',
    textBn: 'চাপ অসম্পূর্ণ (আন্ডার-ক্রিম্প) — ডাই-এর চিহ্ন অস্পষ্ট, আকার অসম। ভালো ক্রিম্প মসৃণ, প্রতিসম, ষড়ভুজ।',
    art: '$_dir/crimp_half.svg',
    lessonPoint: 3,
  );
  static const passPliers = DoMistake(
    key: '2.3/crimp/passed-pliers',
    textBn: 'প্লায়ার্সে চ্যাপ্টা করা ল্যাগ — ভুল আকার, ঠিক চাপ নেই, ডাই-এর চিহ্নও নেই। এটা বাতিল।',
    art: '$_dir/crimp_pliers.svg',
    lessonPoint: 3,
  );

  static DoMistake passed(LugKind k) => switch (k) {
        LugKind.cracked => passCracked,
        LugKind.strands => passStrands,
        LugKind.under => passUnder,
        LugKind.pliers || LugKind.good => passPliers,
      };

  /// A bad crimp was made: the joint glows under load, then this job starts again.
  static const ruins = {notIn, wrongDie, onPalm, halfPress, pliers};

  static const all = [prep, stripLength, notIn, noDie, wrongDie, onPalm, halfPress, noPull, pliers, passCracked, passStrands, passUnder, passPliers];
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// A make-round (ms; ~1500 human reaction per action): strip 1500 + mark
/// 2000, brush 1500 + 700, paste (Al, 1 in 2) 750, insert 1500 + hold 1200,
/// die 1500 + pick 2000, crimp 1500 + place 2000 + hold 1600, pull 1500 +
/// 700, fit 1500 = 22450; the reason (praise ~1500 + 650 + deck 910 + read
/// 2000 + pick 1500 + "এই তো আসল কথা" ~1200 + 450) 8210 → 30660 × 2 = 61320.
/// The tray: look 3000 + four taps 4 × 1500 + done 1500 + reason 8210 = 18710.
/// The coworker once: his line ~3500 + deck 910 + read and pick 3500 + 420 =
/// 8330. ≈ 88360 ms; 85 % ≈ 75100 → 80 s.
const kCrimpQuickMs = 80000;

@immutable
class M2CrimpStepsPack {
  const M2CrimpStepsPack({required this.id, required this.titleBn, this.quickMs = kCrimpQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M2CrimpStepsPack> m2CrimpStepsPacks = {
  'do_2_3_b': M2CrimpStepsPack(id: 'do_2_3_b', titleBn: CrimpLines.title),
};

/// The tray's buttons for a round, in a fresh order (the paste only on aluminium).
List<CrimpStep> dealTray(CrimpJob job, math.Random rng) => [
      for (final s in CrimpStep.values)
        if (s != CrimpStep.paste || job.al) s,
    ]..shuffle(rng);

// ============================================================================
// Page
// ============================================================================

class M2CrimpStepsPage extends StatefulWidget {
  const M2CrimpStepsPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M2CrimpStepsPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2CrimpStepsPage> createState() => _M2CrimpStepsPageState();
}

class _M2CrimpStepsPageState extends State<M2CrimpStepsPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CrimpRunPage(
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

class _CrimpRunPage extends ConsumerStatefulWidget {
  const _CrimpRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2CrimpStepsPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_CrimpRunPage> createState() => _CrimpRunPageState();
}

/// What the hands are on now.
enum _Mode { idle, strip, die, place, insert, press }

class _CrimpRunPageState extends ConsumerState<_CrimpRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final CrimpRun _run = CrimpRun(dealCrimp(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// The brush's sweep, or the pull test's tug (one-shots).
  late final AnimationController _act = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  /// Pushing the conductor in (runs only while held).
  late final AnimationController _ins = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _insertDone();
    });

  /// The crimper's cycle (runs only while held; it releases itself at 1).
  late final AnimationController _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600), reverseDuration: const Duration(milliseconds: 350))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _pressEnd();
    });

  /// The bad joint heating under load (one-shot).
  late final AnimationController _heat = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  late final Listenable _sceneMotion = Listenable.merge([_act, _ins, _press, _heat]);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  _Mode _mode = _Mode.idle;
  List<CrimpStep> _tray = const [];
  String? _stamp;
  var _brushing = false;
  var _tugging = false;
  var _holding = false;
  var _pliered = false;
  LugKind? _bad;
  Offset? _heatAt;
  var _heatOn = false;
  int? _pressCue;

  /// Crimp was pressed on his round before he came: he comes now.
  Offset? _heldCrimp;
  var _coworkerArmed = false;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  CrimpRound get _round => _run.current;
  String get _ask => _round.inspect ? CrimpLines.askInspect : CrimpLines.askMake;

  @override
  void dispose() {
    disposeCoworker();
    _act.dispose();
    _ins.dispose();
    _press.dispose();
    _heat.dispose();
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

  void _cue(String file, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(file, volume: volume, muted: false));
  }

  void _tick() {
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.45);
  }

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  bool get _canPlay => !_intro && !_busy && !_ended && _card == null && !reasonOpen && !coworkerOpen && !_run.shown && !_heatOn;

  void _startRound() {
    setState(() {
      _mode = _Mode.idle;
      _stamp = null;
      _bad = null;
      _pliered = false;
      _heatOn = false;
      _heatAt = null;
      _tray = _round.inspect ? const [] : dealTray(_round.job!, widget.rng);
      _wake++;
    });
    _ins.value = 0;
    _press.value = 0;
    _heat.value = 0;
    _act.value = 0;
    unawaited(_sayChain([_ask]));
  }

  // --- the tray ---------------------------------------------------------------
  void _step(CrimpStep s, Offset origin) {
    if (!_canPlay || _holding) return;
    setState(() => _mode = _Mode.idle);
    switch (s) {
      case CrimpStep.strip:
        if (_run.stripped) return _tick();
        _tick();
        setState(() => _mode = _Mode.strip);
        unawaited(_sayChain([CrimpLines.askStrip]));
      case CrimpStep.clean:
        final was = _run.cleaned;
        final m = _run.clean();
        if (m != null) return unawaited(_slip(m, origin));
        if (was) return _tick();
        _cue('sounds/learn/tag_slap.wav', volume: 0.35);
        setState(() => _brushing = true);
        if (_quiet) {
          setState(() => _brushing = false);
        } else {
          unawaited(_act.forward(from: 0).then((_) {
            if (mounted) setState(() => _brushing = false);
          }));
        }
      case CrimpStep.paste:
        final m = _run.paste();
        if (m != null) return unawaited(_slip(m, origin));
        _cue('sounds/quiz_select.wav', volume: 0.45);
        HapticFeedback.selectionClick();
        setState(() => _wake++);
      case CrimpStep.insert:
        if (_run.fullyIn || _run.crimped) return _tick();
        final m = _run.startInsert();
        if (m != null) return unawaited(_slip(m, origin));
        _tick();
        _ins.value = _run.inserted;
        setState(() => _mode = _Mode.insert);
      case CrimpStep.die:
        if (_run.crimped) return _tick();
        _tick();
        setState(() => _mode = _Mode.die);
        unawaited(_sayChain([CrimpLines.askDie]));
      case CrimpStep.crimp:
        if (_run.crimped) return _tick();
        final m = _run.startCrimp();
        if (m != null) return unawaited(_slip(m, origin));
        _tick();
        if (_run.index == _run.deal.callAt && !coworkerDone) {
          // On his round he cuts in the moment the tool comes off the hook.
          _hush();
          setState(() {
            _heldCrimp = origin;
            _busy = true;
          });
          if (!_coworkerArmed) {
            _coworkerArmed = true;
            scheduleCoworker();
          }
          return;
        }
        _toPlace();
      case CrimpStep.pull:
        final r = _run.pull();
        if (r == PullResult.nothing) return _tick();
        HapticFeedback.mediumImpact();
        _cue(r == PullResult.held ? 'sounds/learn/knock_solid.wav' : 'sounds/intro/drop.ogg', volume: 0.6);
        _ins.value = _run.inserted;
        setState(() => _tugging = true);
        if (_quiet) {
          setState(() => _tugging = false);
        } else {
          unawaited(_act.forward(from: 0).then((_) {
            if (mounted) setState(() => _tugging = false);
          }));
        }
        if (r == PullResult.slidOut) unawaited(_sayChain([CrimpLines.slidOut]));
      case CrimpStep.fit:
        final m = _run.fit();
        if (m != null) return unawaited(_slip(m, origin));
        _roundRight(CrimpLines.stampDone, CrimpLines.whyMake);
    }
  }

  void _toPlace() {
    setState(() => _mode = _Mode.place);
    unawaited(_sayChain([CrimpLines.askPlace]));
  }

  void _pickMark(double factor, Offset origin) {
    if (!_canPlay || _mode != _Mode.strip) return;
    final m = _run.strip(factor);
    setState(() => _mode = _Mode.idle);
    if (m != null) return unawaited(_slip(m, origin));
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.5);
    setState(() => _wake++);
  }

  void _pickDie(int d) {
    if (!_canPlay || _mode != _Mode.die) return;
    _run.pickDie(d);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.55);
    setState(() => _mode = _Mode.idle);
  }

  void _place(bool barrel, Offset origin) {
    if (!_canPlay || _mode != _Mode.place) return;
    final m = _run.place(barrel: barrel);
    if (m != null) {
      setState(() => _mode = _Mode.idle);
      return unawaited(_ruin(m, origin, at: CrimpGeo.forScene(_sceneH).palmSpot));
    }
    _cue('sounds/intro/impact_metal.ogg', volume: 0.5);
    HapticFeedback.selectionClick();
    _press.value = 0;
    setState(() => _mode = _Mode.press);
  }

  // --- holds ------------------------------------------------------------------
  void _holdDown() {
    if (!_canPlay || _holding) return;
    if (_mode == _Mode.insert) {
      setState(() => _holding = true);
      unawaited(_ins.forward());
    } else if (_mode == _Mode.press) {
      setState(() => _holding = true);
      _pressCue = 0;
      _press.addListener(_ratchet);
      unawaited(_press.forward());
    }
  }

  /// Ratchet clicks as the handles close.
  void _ratchet() {
    final n = (_press.value * 5).floor();
    if (n > (_pressCue ?? 0)) {
      _pressCue = n;
      HapticFeedback.selectionClick();
      _cue('sounds/learn/tick.wav', volume: 0.5);
    }
  }

  void _holdUp(Offset origin) {
    if (!_holding) return;
    setState(() => _holding = false);
    if (_mode == _Mode.insert) {
      _ins.stop();
      _run.setInserted(_ins.value);
    } else if (_mode == _Mode.press && _press.isAnimating) {
      _press.stop();
      _pressEnd(origin: origin);
    }
  }

  void _insertDone() {
    if (!mounted || _mode != _Mode.insert) return;
    _run.setInserted(1);
    _cue('sounds/intro/click.ogg', volume: 0.6);
    HapticFeedback.mediumImpact();
    setState(() {
      _holding = false;
      _mode = _Mode.idle;
      _wake++;
    });
  }

  void _pressEnd({Offset? origin}) {
    if (!mounted || _mode != _Mode.press) return;
    _press.removeListener(_ratchet);
    final reached = _press.value;
    final m = _run.press(reached >= 0.999 ? 1 : reached);
    final o = origin ?? Offset(MediaQuery.sizeOf(context).width / 2, MediaQuery.sizeOf(context).height * 0.5);
    setState(() {
      _holding = false;
      _mode = _Mode.idle;
    });
    if (m != null) {
      final job = _run.job;
      setState(() => _bad = m == CrimpMistakes.wrongDie && (_run.die ?? 0) < job.size ? LugKind.cracked : LugKind.under);
      _press.value = 0;
      unawaited(_ruin(m, o));
      return;
    }
    // The tool releases by itself.
    _cue('sounds/intro/confirm.ogg', volume: 0.6);
    HapticFeedback.heavyImpact();
    if (_quiet) {
      _press.value = 0;
    } else {
      unawaited(_press.reverse());
    }
    setState(() => _wake++);
  }

  // --- the tray round ---------------------------------------------------------
  void _toggleLug(int i) {
    if (!_canPlay || !_round.inspect) return;
    _run.toggle(i);
    HapticFeedback.selectionClick();
    _cue(_run.rejected.contains(i) ? 'sounds/learn/tag_slap.wav' : 'sounds/intro/click.ogg', volume: 0.45);
    setState(() {});
  }

  void _trayDone(Offset origin) {
    if (!_canPlay || !_round.inspect) return;
    final f = _run.falseRejects;
    if (f.isNotEmpty) {
      // A good lug set aside: not scored; the guide says why it is good.
      _run.unreject(f);
      _tick();
      setState(() {});
      unawaited(_sayChain([CrimpLines.goodLug]));
      return;
    }
    final miss = _run.missed;
    final m = _run.passTray();
    if (m != null) {
      final geo = CrimpGeo.forScene(_sceneH);
      final at = geo.trayAt(miss.first);
      unawaited(_ruin(m, origin, at: at + const Offset(10, 0), counted: true));
      return;
    }
    _roundRight(CrimpLines.stampTray, CrimpLines.whyTray);
  }

  void _roundRight(String stamp, String question) {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_right.wav', volume: 0.6);
    setState(() {
      _stamp = stamp;
      _wake++;
    });
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final r = _round;
    final pasted = _run.pasted;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(CrimpLines.whyRight(r, pasted: pasted), CrimpLines.myths, widget.rng),
      question: question,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
  }

  // --- the shared success beat (ReasonTable) ---------------------------------
  @override
  bool get reasonMuted => _muted;
  @override
  bool get reasonEnded => _ended;
  @override
  Future<void> reasonSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void reasonHush() => _hush();
  @override
  Future<void> reasonScore(int delta, Offset origin, {GuideMood? mood}) => _levelDelta(delta, origin, mood: mood);
  @override
  void onReasonPaid() {
    final idx = _run.index;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => CrimpLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callAt || _run.shown || _run.crimped) return null;
    if (_heldCrimp != null) return true;
    if (_intro || _busy || _holding || _card != null || reasonOpen || _heatOn) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final waiting = _heldCrimp != null;
    setState(() {
      _heldCrimp = null;
      _busy = false;
    });
    if (!held) {
      // Listened to him: the lug squeezed flat with pliers.
      setState(() => _pliered = true);
      _cue('sounds/learn/dull_steel.wav', volume: 0.7);
      await _ruin(_run.pliers(), origin);
      return;
    }
    _run.caught.add(CrimpLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    if (waiting) {
      _toPlace();
    } else {
      unawaited(_sayChain([CrimpLines.callHeld]));
    }
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? CrimpLines.tapWhy[_nudgeN++ % CrimpLines.tapWhy.length]
            : _nudge.next(switch (_mode) {
                _Mode.strip => CrimpLines.askStrip,
                _Mode.die => CrimpLines.askDie,
                _Mode.place => CrimpLines.askPlace,
                _ => _ask,
              });
    _tick();
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  /// A bad crimp was made (or let through): the joint heats under load, the
  /// glow and the smoke; then the card. [counted]: the slip is already in
  /// the run (the tray).
  Future<void> _ruin(DoMistake m, Offset origin, {Offset? at, bool counted = false}) async {
    _hush();
    final geo = CrimpGeo.forScene(_sceneH);
    setState(() {
      _heatOn = true;
      _heatAt = at ?? (_round.inspect ? null : Offset(geo.mouthAt(_run.inserted) + CrimpGeo.barrel / 2, geo.cableY));
      _wake++;
    });
    _cue('sounds/learn/spark.wav', volume: 0.6);
    if (_quiet) {
      _heat.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 600));
    } else {
      await _heat.forward(from: 0);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;
    await _slip(m, origin);
  }

  Future<void> _slip(DoMistake m, Offset origin) async {
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _mode = _Mode.idle;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('crimp/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    final m = _card;
    setState(() => _card = null);
    if (_round.inspect && _run.shown) {
      _next();
      return;
    }
    if (m != null && CrimpMistakes.ruins.contains(m)) {
      // Cut the bad lug off: the job again, from the start.
      _run.redo();
      _startRound();
      unawaited(_sayChain([CrimpLines.redo]));
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
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _clock.elapsedMilliseconds < widget.pack.quickMs);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? CrimpLines.fail : (_quickBonus ? CrimpLines.quick : CrimpLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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

  // --- the scene ---------------------------------------------------------------
  double _sceneH = 780;

  LinemanMode get _figure {
    if (_card != null || _heatOn || coworkerOpen || _heldCrimp != null) return LinemanMode.worried;
    if (_stamp != null) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  CrimpView _view() {
    final r = _round;
    if (r.inspect) return CrimpView(lugs: r.lugs, heat: _heatOn ? _heat.value : 0, heatAt: _heatAt);
    final toolOut = _mode == _Mode.place || _mode == _Mode.press || _press.value > 0;
    return CrimpView(
      job: r.job,
      stripped: _run.stripped,
      cleaned: _run.cleaned && !_brushing,
      pasted: _run.pasted,
      inserted: _mode == _Mode.insert || _ins.isAnimating ? _ins.value : _run.inserted,
      die: _run.die,
      crimped: _run.crimped,
      onBarrel: _run.onBarrel || _mode == _Mode.press,
      press: _press.value,
      pull: _tugging ? _act.value : 0,
      brush: _brushing ? _act.value : 0,
      showMarks: _mode == _Mode.strip,
      showDies: _mode == _Mode.die,
      toolOut: toolOut,
      heat: _heatOn ? _heat.value : 0,
      heatAt: _heatAt,
      pliers: _pliered,
      bad: _bad,
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    _sceneH = m.height;
    final geo = CrimpGeo.forScene(m.height);
    final quiet = _quiet;
    final view = _view();
    final job = _round.job;
    final open = _canPlay;
    return [
      Positioned.fill(
        key: const ValueKey('wall'),
        child: RepaintBoundary(child: CustomPaint(painter: CrimpWallPainter(geo: geo, toolOut: view.toolOut, brushOut: _brushing))),
      ),
      Positioned(
        key: const ValueKey('trainee'),
        left: 2,
        top: geo.wallBottom - 76,
        width: 76,
        height: 152,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _figure, wake: _wake, quiet: quiet),
      ),
      Positioned.fill(
        key: const ValueKey('bench'),
        child: CustomPaint(painter: CrimpBenchPainter(geo: geo, view: view)),
      ),
      // The strip marks.
      if (open && _mode == _Mode.strip && job != null)
        for (final (i, f) in job.marks.indexed)
          Positioned(
            key: ValueKey('mark-$i'),
            left: geo.markX(f) - 16,
            top: geo.cableY - 28,
            width: 32,
            height: 56,
            child: Semantics(
              button: true,
              label: 'mark-$i',
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _pickMark(f, d.globalPosition)),
            ),
          ),
      // The dies.
      if (open && _mode == _Mode.die && job != null)
        for (final (i, d) in job.dies.indexed)
          Positioned(
            key: ValueKey('die-$d'),
            left: geo.dieAt(i).dx - 28,
            top: geo.dieAt(i).dy - 24,
            width: 56,
            height: 48,
            child: Semantics(
              button: true,
              label: CrimpLines.dieBn(d),
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _pickDie(d)),
            ),
          ),
      // Where the tool goes on the lug.
      if (open && _mode == _Mode.place)
        for (final barrel in [true, false])
          Positioned(
            key: ValueKey('spot-$barrel'),
            left: (barrel ? geo.barrelSpot : geo.palmSpot).dx - (barrel ? CrimpGeo.barrel : CrimpGeo.palm) / 2,
            top: geo.cableY - 26,
            width: barrel ? CrimpGeo.barrel : CrimpGeo.palm,
            height: 52,
            child: Semantics(
              button: true,
              label: barrel ? 'spot-barrel' : 'spot-palm',
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _place(barrel, d.globalPosition)),
            ),
          ),
      // The tray: tap a lug to set it aside.
      if (_round.inspect)
        for (var i = 0; i < _round.lugs.length; i++)
          Positioned(
            key: ValueKey('lug-$i'),
            left: geo.trayAt(i).dx - CrimpGeo.traySize.width / 2,
            top: geo.trayAt(i).dy - CrimpGeo.traySize.height / 2,
            width: CrimpGeo.traySize.width,
            height: CrimpGeo.traySize.height,
            child: Semantics(
              button: true,
              label: 'lug-$i',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _toggleLug(i),
                child: _run.rejected.contains(i) ? _RejectTag(quiet: quiet) : const SizedBox.expand(),
              ),
            ),
          ),
      if (_stamp != null && !_heatOn)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: 150,
          width: 180,
          top: geo.wallBottom - 4,
          child: IgnorePointer(child: _StampPop(text: _stamp!, quiet: quiet)),
        ),
      if (!_intro)
        Positioned.fill(
          key: ValueKey('day-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.shown && !deckUp && !coworkerOpen && _card == null && _heldCrimp == null && !_heatOn;
    final hold = handsOn && (_mode == _Mode.insert || _mode == _Mode.press);
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
              labels: CrimpLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            animation: _sceneMotion,
            layers: (context, m) => _scene(m),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && !_round.inspect)
                Positioned(
                  key: const ValueKey('hud-tray'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 10,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in _tray)
                        _StepButton(
                          key: ValueKey('step-${s.name}'),
                          label: CrimpLines.stepBn(s),
                          lit: _mode == _Mode.strip && s == CrimpStep.strip || _mode == _Mode.die && s == CrimpStep.die || (_mode == _Mode.insert && s == CrimpStep.insert) || ((_mode == _Mode.place || _mode == _Mode.press) && s == CrimpStep.crimp),
                          onTapUp: (d) => _step(s, d.globalPosition),
                        ),
                    ],
                  ),
                ),
              if (handsOn && _round.inspect)
                Positioned(
                  key: const ValueKey('hud-done'),
                  left: 12,
                  right: 130,
                  bottom: pad.bottom + 12,
                  child: DoBigButton(label: CrimpLines.trayDone, filled: true, onTapUp: (d) => _trayDone(d.globalPosition)),
                ),
              if (hold)
                Positioned(
                  key: ValueKey('hud-hold-${_mode.name}'),
                  left: 0,
                  right: 0,
                  bottom: pad.bottom + 132,
                  child: Center(
                    child: _HoldPad(
                      label: _mode == _Mode.insert ? CrimpLines.holdInsert : CrimpLines.holdCrimp,
                      progress: _mode == _Mode.insert ? _ins : _press,
                      holding: _holding,
                      onDown: _holdDown,
                      onUp: _holdUp,
                    ),
                  ),
                ),
              if (deckUp)
                Positioned(
                  key: const ValueKey('hud-deck'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (_round.inspect ? 72 : 128)), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
                  mistake: _card!,
                  tone: MistakeTone.slip,
                  quiet: quiet,
                  onRead: () {
                    _hush();
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
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: CrimpLines.intro,
                  alarm: 'sounds/intro/impact_metal.ogg',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    unawaited(_start());
                  },
                ),
              if (_mark != null)
                Positioned.fill(
                  key: const ValueKey('result'),
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
                                stars: _stars,
                                onNext: () => _popOnce(true),
                                onRetry: () => widget.onRetry(_muted),
                              )
                            : LevelFailPanel(
                                percent: _mark!,
                                muted: _muted,
                                onRetry: () => widget.onRetry(_muted),
                                onLeave: () => _popOnce(false),
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 2, muted: _muted)),
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

/// A step on the tray (lit while its hands-on part is open).
class _StepButton extends StatelessWidget {
  const _StepButton({super.key, required this.label, required this.lit, required this.onTapUp});
  final String label;
  final bool lit;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTapUp,
        child: Container(
          width: 78,
          height: 50,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: lit ? const [Color(0xFF6B5310), Color(0xFF3A2C06)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
            ),
            border: Border.all(color: (lit ? SlmColors.gold300 : SlmColors.gold300.withValues(alpha: 0.55)), width: lit ? 2 : 1.4),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Text(label, textAlign: TextAlign.center, maxLines: 2, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, height: 1.1, color: SlmColors.ivory)),
        ),
      ),
    );
  }
}

/// Press and hold: a ring fills while held (the conductor going in, or the
/// crimper's cycle).
class _HoldPad extends StatelessWidget {
  const _HoldPad({required this.label, required this.progress, required this.holding, required this.onDown, required this.onUp});
  final String label;
  final Animation<double> progress;
  final bool holding;
  final VoidCallback onDown;
  final ValueChanged<Offset> onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onDown(),
        onPointerUp: (e) => onUp(e.position),
        onPointerCancel: (e) => onUp(e.position),
        child: SizedBox(
          width: 150,
          height: 76,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: progress,
              builder: (_, child) => CustomPaint(painter: _HoldRing(progress.value, holding), child: child),
              child: Center(
                child: Text(label, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoldRing extends CustomPainter {
  const _HoldRing(this.v, this.holding);
  final double v;
  final bool holding;

  @override
  void paint(Canvas c, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(38));
    c.drawRRect(r, Paint()..color = holding ? const Color(0xF0263D5E) : const Color(0xE60B1324));
    final fill = Rect.fromLTWH(0, 0, size.width * v.clamp(0.0, 1.0), size.height);
    c.save();
    c.clipRRect(r);
    c.drawRect(fill, Paint()..color = const Color(0x8854C27A));
    c.restore();
    c.drawRRect(r, Paint()..color = SlmColors.gold300..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_HoldRing old) => old.v != v || old.holding != holding;
}

/// A lug set aside on the tray.
class _RejectTag extends StatelessWidget {
  const _RejectTag({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: 0.7 + 0.3 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SlmColors.danger, width: 2.6),
          color: const Color(0x33C0392B),
        ),
        alignment: Alignment.topRight,
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(6)),
          child: Text(CrimpLines.reject, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ),
    );
  }
}

class _StampPop extends StatelessWidget {
  const _StampPop({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.rotate(angle: -0.12, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.success, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
