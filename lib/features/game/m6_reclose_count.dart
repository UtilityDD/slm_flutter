import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
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
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm6_reclose_count_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_reclose_count_world.dart' show M6RcBranch, M6RcGeo, M6RcOutcome;

// Lesson 6.8 "অটো-রিক্লোজার ও সেকশনালাইজার: লাইনের স্মার্ট ব্রেন", কাজ 1
// "চেষ্টা গুনুন" (pack do_6_8_a, engineType m6_reclose_count). Storm dusk;
// the crew's van at a junction pole with sectionalizer S-A; the recloser R
// is out of sight. Three storm rounds. Each round the docket slides up
// (রিক্লোজার R · চেষ্টা: 3 or 4, the same all play); a tap tucks it away and
// the fault comes. The lights of both villages go out (the trip); after a
// dead pause they flick on (a try) — a lasting fault trips them at once.
// The player counts the tries on a tally clicker (only his own taps show;
// tally accuracy scores nothing) and calls the line's state by dragging one
// of three magnets onto the crew's sketch on the van door:
//
//   লাইন চালু  — a passing fault: a try held, both villages lit (point 1).
//   লক-আউট    — a lasting fault on the main line: every try tripped, the
//                setting's tries are over, dark (point 1: '৩-৪ বার চেষ্টা
//                করার পর ... লক-আউট').
//   শাখা বন্ধ  — on a branch line of the sketch: the sectionalizer of that
//                branch opened in the dead pause before the last try (point
//                2); the last try lit the other branch. S-A hangs open on our
//                pole (seen); S-B is far away (known from the last try).
//
// The board is live from the first trip: a call made too early or wrong is a
// slip (spec slips: লক-আউট while tries < setting; লক-আউট when one branch was
// isolated and the rest came back; চালু while a branch stays dark; শাখা বন্ধ on
// the wrong branch; শাখা বন্ধ or লক-আউট after a passing fault held — needless
// patrol) and the cycle plays on. A right call → ◆ on the table → "কেন?" →
// এগিয়ে যান; the radio reads back R's counter ('+N', after the call, framing,
// non-scoring).
//
// Deadly (module 6 table R3; ruling X2/B1): the careless coworker comes once a
// play in a lasting-fault round's dead pause after try 1 or 2 (tries always
// left) with lesson 6.8's myth word for word; the next try and the board
// wait for him. Listening = going up mid-cycle = deadly (the line comes back
// while the trainee is on the pole). Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_reclose_count_world.dart), corner guide, ReasonTable,
// CoworkerMoment, gesture hands: a tap ripple on the docket (the one way on);
// during the cycle and after it, an idle tap ripple on the clicker (on an
// idle timer, never in step with a try) and a sweep over the three magnets
// and both branch lines alike — never the answer.

// ============================================================================
// Content
// ============================================================================

/// The three magnets (fixed, alike, unlit).
enum M6RcCall { on, lockout, branch }

/// What a round's reason asks about.
enum M6RcWhy { lockout, on, branch, refused }

/// The lesson point (0-based) that teaches an outcome.
int m6RcLessonPoint(M6RcOutcome o) => switch (o) {
      M6RcOutcome.transient || M6RcOutcome.main => 0,
      M6RcOutcome.branchA || M6RcOutcome.branchB => 1,
    };

abstract final class M6RecloseCountLines {
  static const title = 'চেষ্টা গুনুন';
  // DRAFT wording — owner (M6-12). The intro and the count line are the
  // spec's.
  static const intro = 'ঝড়ে লাইন ট্রিপ করছে! রিক্লোজার কতবার চেষ্টা করে — গুনে বলুন।';

  // The guide's task now (tap him: the same task, a different way).
  static const askDocket = 'ডকেটটা দেখে সরিয়ে রাখুন।';
  // One task from the docket tuck to the call: it never changes when the
  // cycle ends (the count, not the guide, tells the player R has locked out).
  static const askCount = 'চেষ্টা গুনুন, বুঝলে ম্যাগনেটটা বোর্ডে লাগান।';
  static const docketFirst = 'আগে ডকেটটা সরিয়ে রাখুন।';
  static const pickBranch = 'কোন শাখা? ম্যাগনেটটা সেই শাখার লাইনের ওপর রাখুন।';
  static List<String> get tasks => [askDocket, askCount];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The scene (a worker's own words).
  static const docket = 'ডকেট';
  static const recloser = 'রিক্লোজার R';
  static String setting(int n) => enDigits('চেষ্টা: $n');
  static String round(int n) => enDigits('ঝড় $n');
  static const sceneLabel = 'ঝড়ের মাঠ, জংশন পোল আর গাড়ির ম্যাগনেট বোর্ড';
  static const clickerLabel = 'ট্যালি কাউন্টার';
  static String tally(int n) => enDigits(n.toString().padLeft(2, '0'));
  static String radio(int n) => enDigits('রেডিও: R কাউন্টার +$n');

  /// The three magnets: about the same length (option group, 1.3×).
  static String magnet(M6RcCall c) => switch (c) {
        M6RcCall.on => 'লাইন চালু',
        M6RcCall.lockout => 'R লক-আউট',
        M6RcCall.branch => 'শাখা বন্ধ',
      };

  // The reasons (spoken questions are the spec's).
  static const whyQ = <M6RcWhy, String>{
    M6RcWhy.lockout: 'লক-আউট বললেন — কেন নিশ্চিত?',
    M6RcWhy.on: 'লাইন চালু বললেন — কেন?',
    M6RcWhy.branch: 'এই শাখা বন্ধ বললেন — কেন?',
    M6RcWhy.refused: 'ওর কথায় উঠলেন না কেন?',
  };
  // DRAFT wording — owner (M6-12).
  static const whyRight = <M6RcWhy, List<String>>{
    M6RcWhy.lockout: ['সব চেষ্টা শেষ, তারপরও দুই দিকেই অন্ধকার', 'সেটিং পর্যন্ত চেষ্টা গুনেছি, আর চালু হয়নি'],
    M6RcWhy.on: ['চেষ্টার পর দুই গ্রামেই আলো টিকে গেছে', 'ফল্ট অস্থায়ী ছিল, চালু হয়ে লাইন টিকেছে'],
    M6RcWhy.branch: ['শুধু ওই শাখা অন্ধকার, বাকিটা আলো পেয়েছে', 'সেকশনালাইজার ফল্টি শাখাটা আলাদা করেছে'],
    M6RcWhy.refused: ['রিক্লোজার মাঝপথে আবার চালু করতে পারে', 'Non-Reclose আর PTW ছাড়া লাইন নিরাপদ নয়'],
  };
  static const myths = [
    'লাইন ট্রিপ করে থাকলেই লক-আউট হয়ে গেছে',
    'সেকশনালাইজার ফিউজের মতোই গলে লাইন কাটে',
    'একবার আলো জ্বললেই লাইন পুরো ঠিক হয়ে যায়',
    'অন্ধকার থাকলেই লাইনে আর কোনো ভয় নেই',
    'গোনার দরকার নেই, আন্দাজে বললেই চলে',
    'ঝড় থামলে সব শাখা নিজে থেকেই ঠিক হয়',
    'যা-ই হোক, পুরো লাইন পেট্রোলিং করতেই হবে',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker: lesson 6.8 myth 1, word for word (spec).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'লাইনটা তো ট্রিপ করে আছে, রিক্লোজার নিশ্চয়ই লক-আউট হয়ে গেছে। কাজ করতে কোনো ভয় নেই।',
    exitLine: coworkerExit,
    // DRAFT wording — owner (M6-12).
    right: ['না, রিক্লোজার এখনও চেষ্টা চালাতে পারে', 'না, Non-Reclose আর PTW ছাড়া উঠব না', 'না, লাইনটা হঠাৎ আবার চালু হতে পারে'],
    wrong: [
      'ঠিক, ট্রিপ মানেই লক-আউট হয়ে গেছে',
      'আচ্ছা, অন্ধকার তো, এখনই উঠে পড়ি',
      'হ্যাঁ, এখনই উঠে কাজটা সেরে ফেলি',
      'ঠিক আছে, ভয়ের কিছু নেই, উঠছি',
      'হ্যাঁ, PTW পরে নিলেও কোনো ক্ষতি নেই',
    ],
    asks: ['কী করবেন?', 'ও বলছে লক-আউট হয়ে গেছে, উঠে পড়তে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const callHeld = 'ঠিক! রিক্লোজার মাঝপথে আবার লাইন চালু করতে পারে।';

  static const allSet = 'তিন ঝড়েই লাইনের অবস্থা ঠিক বলেছেন — দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — চেষ্টা গুনুন, শেষ চেষ্টা পর্যন্ত দেখুন, তারপর বলুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtOn = 'অস্থায়ী ফল্ট — লাইন চালু';
  static const caughtLock = 'সব চেষ্টা গুনে তবে লক-আউট';
  static const caughtBranch = 'ফল্টি শাখা চিনে শাখা বন্ধ';
  static const caughtCount = 'চেষ্টা ঠিক গুনেছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new line (lesson myth word for word; record in his voice).
  static List<String> get newRivalLines => [coworker.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        askDocket,
        askCount,
        docketFirst,
        pickBranch,
        ...tapWhy.where((l) => !_oldLines.contains(l)),
        ...whyQ.values,
        ...coworker.asks.where((a) => !_oldLines.contains(a)),
        callHeld,
        allSet,
        fail,
        for (final m in M6RecloseCountMistakes.all) m.textBn,
      ];
  static const _oldLines = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'};
}

abstract final class M6RecloseCountMistakes {
  static const _dir = 'assets/game/art/m6_reclose_count';

  // DRAFT wording — owner (M6-12).
  static const lockEarly = DoMistake(
    key: '6.8/m6_reclose_count/lock-early',
    textBn: 'রিক্লোজার এখনও চেষ্টা শেষ করেনি — চেষ্টা বাকি থাকতে লক-আউট নয়। সাধারণত 3-4 বার চেষ্টার পর তবে লক-আউট; ডকেটের সংখ্যা পর্যন্ত গুনুন।',
    art: '$_dir/lock_early.svg',
    lessonPoint: 0,
  );
  static const lockBranch = DoMistake(
    key: '6.8/m6_reclose_count/lock-branch',
    textBn: 'লক-আউট নয় — সেকশনালাইজার ফল্টি শাখাটা আলাদা করেছে, শেষ চেষ্টায় বাকি শাখা বিদ্যুৎ পেয়েছে। বন্ধ শুধু ওই শাখা।',
    art: '$_dir/lock_branch.svg',
    lessonPoint: 1,
  );
  static const onDark = DoMistake(
    key: '6.8/m6_reclose_count/on-dark',
    textBn: 'আলো টেকেনি — চেষ্টায় আলো জ্বলে আবার নিভে যায়, বা একটা শাখা অন্ধকার। দুই গ্রামেই আলো টিকে থাকলে তবেই লাইন চালু।',
    art: '$_dir/on_dark.svg',
    lessonPoint: 0,
  );
  static const branchWrong = DoMistake(
    key: '6.8/m6_reclose_count/branch-wrong',
    textBn: 'ভুল শাখা! যে শাখা শেষ চেষ্টায় আলো পায়নি, সেটাই ফল্টি — সেকশনালাইজার সেটাকেই আলাদা করেছে।',
    art: '$_dir/branch_wrong.svg',
    lessonPoint: 1,
  );
  static const noBranch = DoMistake(
    key: '6.8/m6_reclose_count/no-branch',
    textBn: 'কোনো শাখা আলাদা হয়েছে, এমন দেখা যায়নি। শেষ চেষ্টায় কোন শাখা আলো পায়, কোনটা পায় না — দেখে তবে শাখা বন্ধ বলুন।',
    art: '$_dir/no_branch.svg',
    lessonPoint: 1,
  );
  static const needless = DoMistake(
    key: '6.8/m6_reclose_count/needless',
    textBn: 'ফল্ট অস্থায়ী ছিল — চালু হয়ে লাইন টিকে গেছে। এখন লক-আউট বা শাখা বন্ধ বললে অকারণ পেট্রোলিং হবে; রিক্লোজার তো এমন অপ্রয়োজনীয় পেট্রোলিং থেকেই মুক্তি দেয়।',
    art: '$_dir/needless.svg',
    lessonPoint: 0,
  );
  // Lesson 6.8 myth 1's reality, word for word (the safety section's rule).
  static const climbMidCycle = DoMistake(
    key: '6.8/m6_reclose_count/climb-mid-cycle',
    textBn:
        "মারাত্মক ভুল! রিক্লোজার হয়তো তার চেষ্টার সাইকেলের মাঝখানে আছে এবং কয়েক সেকেন্ড পরেই আবার লাইন চালু করার চেষ্টা করবে। 'Non-Reclose' মোড নিশ্চিত না করে এবং PTW না নিয়ে কোনো রিক্লোজারযুক্ত লাইনকে নিরাপদ ভাবা যাবে না।",
    art: '$_dir/climb_mid_cycle.svg',
    deadly: true,
    lessonPoint: 2,
  );

  static const List<DoMistake> all = [lockEarly, lockBranch, onDark, branchWrong, noBranch, needless, climbMidCycle];
}

/// One beat of the cycle.
enum M6RcStepKind {
  /// The fault: the bolt, both villages go dark (the trip).
  fault,

  /// A try: the recloser closes, both villages light.
  tryOn,

  /// The lasting fault trips it again at once.
  trip,

  /// The faulted branch's sectionalizer opens (dead line, before the last try).
  open,

  /// The last try: the healthy branch lights, the faulted one stays dark.
  restore,

  /// A passing fault: the lights have stayed on well past a lasting fault's
  /// flick — only now can the player read "held" (nothing changes on screen).
  held,
}

@immutable
class M6RcStep {
  const M6RcStep(this.kind, this.ms);
  final M6RcStepKind kind;

  /// The wait before this beat.
  final int ms;
}

/// The wait from the tucked docket to the fault, and a lasting fault's flick.
const kM6RcFaultMs = 900;
const kM6RcFlickMs = 320;

/// How long a passing fault's lights must stay on before "লাইন চালু" counts
/// (well past [kM6RcFlickMs]: a drop as the lights come on is a guess).
const kM6RcHeldMs = 1000;

/// One storm round.
@immutable
class M6RcRound {
  const M6RcRound({required this.outcome, required this.pauses, this.hold = 0, this.bolt = 0.5, this.thunder = 0});

  final M6RcOutcome outcome;

  /// The dead pause before each try (ms; one per try of the setting).
  final List<int> pauses;

  /// A passing fault: the try that holds (1-based).
  final int hold;

  /// Where the bolt strikes (0–1 across) and which thunder rolls (the same
  /// cue for every kind of fault).
  final double bolt;
  final int thunder;

  bool get lasting => outcome != M6RcOutcome.transient;
  M6RcBranch? get faulted => switch (outcome) {
        M6RcOutcome.branchA => M6RcBranch.a,
        M6RcOutcome.branchB => M6RcBranch.b,
        _ => null,
      };
}

/// The beats of [r]'s cycle for a recloser set to [setting] tries.
List<M6RcStep> m6RcSteps(M6RcRound r, int setting) {
  final out = <M6RcStep>[const M6RcStep(M6RcStepKind.fault, kM6RcFaultMs)];
  for (var i = 1; i <= setting; i++) {
    final p = r.pauses[i - 1];
    if (r.faulted != null && i == setting) {
      out
        ..add(M6RcStep(M6RcStepKind.open, p ~/ 2))
        ..add(M6RcStep(M6RcStepKind.restore, p - p ~/ 2));
      break;
    }
    out.add(M6RcStep(M6RcStepKind.tryOn, p));
    if (r.outcome == M6RcOutcome.transient && i == r.hold) {
      out.add(const M6RcStep(M6RcStepKind.held, kM6RcHeldMs));
      break;
    }
    out.add(const M6RcStep(M6RcStepKind.trip, kM6RcFlickMs));
  }
  return out;
}

@immutable
class M6RcDeal {
  const M6RcDeal({
    required this.setting,
    required this.rounds,
    required this.coworkerRound,
    required this.coworkerAfter,
    required this.why,
    this.mirror = false,
    this.dusk = 0,
  });

  /// The recloser's tries (the docket; lesson: 3–4).
  final int setting;
  final List<M6RcRound> rounds;

  /// The round the coworker comes in (a lasting fault) and the try after
  /// which he comes (1 or 2: tries always left).
  final int coworkerRound;
  final int coworkerAfter;

  /// What each round's reason asks about.
  final List<M6RcWhy> why;
  final bool mirror;
  final int dusk;
}

M6RcWhy m6RcWhyFor(M6RcOutcome o) => switch (o) {
      M6RcOutcome.transient => M6RcWhy.on,
      M6RcOutcome.main => M6RcWhy.lockout,
      M6RcOutcome.branchA || M6RcOutcome.branchB => M6RcWhy.branch,
    };

M6RcDeal m6RcDeal(math.Random rng) {
  final setting = 3 + rng.nextInt(2);
  // Three different faults of the four (so at least two are lasting: one
  // locks out or isolates a branch every play).
  final outs = [...M6RcOutcome.values]..shuffle(rng);
  final rounds = <M6RcRound>[
    for (final o in outs.take(3))
      M6RcRound(
        outcome: o,
        pauses: [for (var i = 0; i < setting; i++) 1600 + rng.nextInt(1600)],
        hold: o == M6RcOutcome.transient ? 1 + rng.nextInt(2) : 0,
        bolt: rng.nextDouble(),
        thunder: rng.nextInt(3),
      ),
  ];
  final lasting = [for (final (i, r) in rounds.indexed) if (r.lasting) i];
  final cw = lasting[rng.nextInt(lasting.length)];
  final why = [
    for (final (i, r) in rounds.indexed) i == cw && rng.nextBool() ? M6RcWhy.refused : m6RcWhyFor(r.outcome),
  ];
  return M6RcDeal(
    setting: setting,
    rounds: rounds,
    coworkerRound: cw,
    coworkerAfter: 1 + rng.nextInt(2),
    why: why,
    mirror: rng.nextBool(),
    dusk: rng.nextInt(3),
  );
}

/// The play state (pure logic).
class M6RcRun {
  M6RcRun(this.deal) {
    _startRound();
  }
  final M6RcDeal deal;

  int index = 0;
  int slips = 0;
  int roundSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The round's right call is in (its reason comes next).
  var roundDone = false;

  /// The docket has been tucked away (the cycle runs).
  var tucked = false;

  /// The cycle so far.
  int step = 0;
  int tries = 0;
  var lightsA = true;
  var lightsB = true;
  var saOpen = false;
  var sbOpen = false;

  /// The cycle has come to its end (held / locked out / branch isolated).
  var settled = false;

  /// The player's own taps on the tally (shown; never scored).
  int taps = 0;

  /// Bolts so far (the flash layer keys on it).
  int bolts = 0;

  M6RcRound get round => deal.rounds[index.clamp(0, 2)];
  late List<M6RcStep> steps;
  bool get done => index >= 3;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => roundSlips == 0;
  bool get _open => !ended && !roundDone;

  /// The board is live from the fault on (before it nothing has tripped).
  bool get live => tucked && _open && step > 0;

  /// The next beat of the cycle (null before the docket, at the end, after
  /// the call).
  M6RcStep? get nextStep => tucked && _open && step < steps.length ? steps[step] : null;

  /// The coworker's dead pause: his round, after his try, the lines dark,
  /// tries left.
  bool get coworkerPause =>
      index == deal.coworkerRound && tucked && _open && tries == deal.coworkerAfter && !lightsA && !lightsB && !settled && step < steps.length;

  void _startRound() {
    steps = m6RcSteps(round, deal.setting);
    tucked = false;
    roundDone = false;
    roundSlips = 0;
    step = 0;
    tries = 0;
    lightsA = true;
    lightsB = true;
    saOpen = false;
    sbOpen = false;
    settled = false;
    taps = 0;
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlips++;
    return m;
  }

  void tuck() {
    if (_open) tucked = true;
  }

  /// A tap on the tally clicker (only once the cycle runs).
  bool tap() {
    if (!_open || !tucked) return false;
    taps++;
    return true;
  }

  /// Plays the next beat; returns it (null if none).
  M6RcStep? applyStep() {
    final s = nextStep;
    if (s == null) return null;
    step++;
    final r = round;
    switch (s.kind) {
      case M6RcStepKind.fault:
        lightsA = lightsB = false;
        bolts++;
      case M6RcStepKind.tryOn:
        tries++;
        lightsA = lightsB = true;
      case M6RcStepKind.held:
        settled = true;
      case M6RcStepKind.trip:
        lightsA = lightsB = false;
        if (step >= steps.length) settled = true;
      case M6RcStepKind.open:
        if (r.faulted == M6RcBranch.a) saOpen = true;
        if (r.faulted == M6RcBranch.b) sbOpen = true;
      case M6RcStepKind.restore:
        tries++;
        lightsA = r.faulted != M6RcBranch.a;
        lightsB = r.faulted != M6RcBranch.b;
        settled = true;
    }
    return s;
  }

  /// The rest of the cycle at once (after a right call).
  void finishCycle() {
    // Played as if live (the guard on [_open] would stop it after a call).
    final keep = roundDone;
    roundDone = false;
    while (applyStep() != null) {}
    roundDone = keep;
  }

  /// The branch is cut off as far as the player could know: S-A seen hanging
  /// open on our pole, or the last try that lit only the other branch.
  bool isolated(M6RcBranch b) => round.faulted == b && (b == M6RcBranch.a ? saOpen : settled);

  /// A magnet on the board: null = the right call (the round is done), else
  /// the slip (the cycle plays on).
  DoMistake? call(M6RcCall c, [M6RcBranch? b]) {
    if (!live) return null;
    final r = round;
    final heldOn = r.outcome == M6RcOutcome.transient && settled;
    switch (c) {
      case M6RcCall.on:
        if (heldOn) return _done(M6RecloseCountLines.caughtOn);
        return _slip(M6RecloseCountMistakes.onDark);
      case M6RcCall.lockout:
        if (r.outcome == M6RcOutcome.main && settled) return _done(M6RecloseCountLines.caughtLock);
        if (heldOn) return _slip(M6RecloseCountMistakes.needless);
        if (r.faulted != null && settled) return _slip(M6RecloseCountMistakes.lockBranch);
        return _slip(M6RecloseCountMistakes.lockEarly);
      case M6RcCall.branch:
        if (b == null) return null;
        if (isolated(b)) return _done(M6RecloseCountLines.caughtBranch);
        if (heldOn) return _slip(M6RecloseCountMistakes.needless);
        final other = b == M6RcBranch.a ? M6RcBranch.b : M6RcBranch.a;
        if (isolated(other)) return _slip(M6RecloseCountMistakes.branchWrong);
        return _slip(M6RecloseCountMistakes.noBranch);
    }
  }

  DoMistake? _done(String tag) {
    roundDone = true;
    _tag(tag);
    finishCycle();
    if (taps == tries && tries > 0) _tag(M6RecloseCountLines.caughtCount);
    return null;
  }

  /// Fails the play (listening to his deadly push).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    if (!done) _startRound();
  }
}

/// The quick bonus is worked out from the deal, so every deal can earn it:
///
///   quick = the dealt cycle waits (every beat of [m6RcSteps], all 3 rounds:
///           the fault, the dead pauses, the flicks, the held beat — no
///           player can shorten them; ≈ 15–38 s)
///         + this allowance for the player's own part.
///
/// The allowance (ms): per round the docket ~1500, the call (a drag) ~2000,
/// a reason ~8200 → 11700 × 3 = 35100; the coworker (arrival, his line, the
/// pick) ≈ 9600 → 44700; 85 % ≈ 38000 (a builder's estimate; owner may tune).
/// A brisk clean play needs about 32 s of its own, so even the slowest deal
/// leaves room.
const m6RecloseCountQuickAllowanceMs = 38000;

/// The dealt cycle waits of every round (ms).
int m6RcDealtWaitMs(M6RcDeal deal) => [
      for (final r in deal.rounds)
        for (final s in m6RcSteps(r, deal.setting)) s.ms,
    ].fold(0, (a, b) => a + b);

/// The quick time of this deal (ms).
int m6RcQuickMs(M6RcDeal deal, [int allowanceMs = m6RecloseCountQuickAllowanceMs]) =>
    m6RcDealtWaitMs(deal) + allowanceMs;

@immutable
class M6RecloseCountPack {
  const M6RecloseCountPack({required this.id, required this.titleBn, this.quickAllowanceMs = m6RecloseCountQuickAllowanceMs});
  final String id;
  final String titleBn;

  /// The player's own part of the quick time (see [m6RcQuickMs]).
  final int quickAllowanceMs;
}

const Map<String, M6RecloseCountPack> m6RecloseCountPacks = {
  'do_6_8_a': M6RecloseCountPack(id: 'do_6_8_a', titleBn: M6RecloseCountLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M6RecloseCountProbe {
  static M6RcRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M6RecloseCountPage extends StatefulWidget {
  const M6RecloseCountPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6RecloseCountPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6RecloseCountPage> createState() => _M6RecloseCountPageState();
}

class _M6RecloseCountPageState extends State<M6RecloseCountPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _RcRunPage(
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

class _RcRunPage extends ConsumerStatefulWidget {
  const _RcRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6RecloseCountPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_RcRunPage> createState() => _RcRunPageState();
}

class _RcRunPageState extends ConsumerState<_RcRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6RcRun _run;

  /// This deal's quick time (the dealt waits + the player's allowance).
  late final int _quickMs;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;

  /// The cycle's next beat.
  Timer? _stepTimer;

  /// A magnet in hand (which, where its centre is now) and where it was
  /// picked up from.
  M6RcCall? _drag;
  Offset _dragAt = Offset.zero;
  Offset _grab = Offset.zero;

  /// The magnet placed by the right call (until the next round).
  M6RcCall? _placed;
  Offset _placedAt = Offset.zero;

  /// The radio read-back (after the right call).
  int? _radioN;

  var _freeze = false;
  var _climbed = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _hintN = 0;
  int _steps = 0;
  M6RcGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M6RcRun(m6RcDeal(widget.rng));
    _quickMs = m6RcQuickMs(_run.deal, widget.pack.quickAllowanceMs);
    M6RecloseCountProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _stepTimer?.cancel();
    _chain++;
    if (identical(M6RecloseCountProbe.run, _run)) M6RecloseCountProbe.run = null;
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

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze;

  // The same task from the tuck to the call: never a cue that the cycle ended.
  String get _task => !_run.tucked ? M6RecloseCountLines.askDocket : M6RecloseCountLines.askCount;

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  void _startRound() {
    setState(() {
      _wake++;
      _drag = null;
      _placed = null;
      _radioN = null;
    });
    _cue('sounds/learn/wind_gust.ogg', volume: 0.4);
    unawaited(_sayChain([_task]));
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  // --- the cycle ------------------------------------------------------------------
  /// Waits for the next beat — unless a card is up, or it is the coworker's
  /// dead pause and he has not been yet (the next try waits for him).
  void _scheduleStep() {
    _stepTimer?.cancel();
    _stepTimer = null;
    final s = _run.nextStep;
    if (s == null || _ended || _freeze || _card != null || !mounted) return;
    if (_run.coworkerPause && !coworkerDone) {
      if (!coworkerDue && !coworkerOpen) scheduleCoworker();
      return;
    }
    _stepTimer = Timer(Duration(milliseconds: s.ms), _playStep);
  }

  void _playStep() {
    _stepTimer = null;
    if (!mounted || _ended || _freeze || _card != null || coworkerOpen) return;
    final s = _run.applyStep();
    if (s == null) return;
    setState(() {});
    switch (s.kind) {
      case M6RcStepKind.fault:
        _cue(switch (_run.round.thunder) {
          0 => 'sounds/learn/thunder_clap.ogg',
          1 => 'sounds/learn/thunder_near.ogg',
          _ => 'sounds/learn/thunder_far.ogg',
        }, volume: 0.8);
        HapticFeedback.mediumImpact();
      case M6RcStepKind.open:
        // S-A is on our pole: its blade drops with a clack (S-B is far away).
        if (_run.round.faulted == M6RcBranch.a) _cue('sounds/intro/drop.ogg', volume: 0.6);
      case M6RcStepKind.tryOn || M6RcStepKind.trip || M6RcStepKind.restore || M6RcStepKind.held:
        break;
    }
    // No word, no hint change when the cycle ends: only the count tells.
    _scheduleStep();
  }

  // --- hands on -----------------------------------------------------------------
  void _tuck() {
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    setState(_run.tuck);
    _stepDone();
    unawaited(_sayChain([M6RecloseCountLines.askCount]));
    _scheduleStep();
  }

  void _needDocket() {
    _tick();
    unawaited(_sayChain([M6RecloseCountLines.docketFirst]));
  }

  void _tapScene(Offset p, M6RcGeo geo) {
    if (!_canPlay) return;
    if (!_run.tucked) {
      if (geo.docket.contains(p)) {
        _tuck();
        return;
      }
      if (geo.clicker.contains(p) || geo.board.contains(p)) {
        _needDocket();
        return;
      }
      _hints.missTap();
      return;
    }
    if (geo.clicker.contains(p)) {
      if (_run.tap()) {
        HapticFeedback.lightImpact();
        _cue('sounds/intro/click.ogg', volume: 0.55);
        setState(() {});
      }
      return;
    }
    _hints.missTap();
  }

  int? _magnetAt(Offset p, M6RcGeo geo) {
    for (var i = 0; i < 3; i++) {
      if (geo.magnet(i).inflate(4).contains(p)) return i;
    }
    return null;
  }

  void _panStart(Offset p, M6RcGeo geo) {
    _drag = null;
    if (!_canPlay) return;
    final i = _magnetAt(p, geo);
    if (i == null) return;
    if (!_run.tucked) {
      _needDocket();
      return;
    }
    // Nothing has tripped yet: the board is live from the fault on.
    if (!_run.live) return;
    final c = M6RcCall.values[i];
    _tick('sounds/intro/click.ogg', 0.4);
    setState(() {
      _drag = c;
      _grab = p - geo.magnet(i).center;
      _dragAt = geo.magnet(i).center;
    });
  }

  void _panUpdate(Offset p) {
    if (_drag == null) return;
    if (!_canPlay) {
      setState(() => _drag = null);
      return;
    }
    setState(() => _dragAt = p - _grab);
  }

  void _panEnd(M6RcGeo geo) {
    final c = _drag;
    if (c == null) return;
    final at = _dragAt;
    setState(() => _drag = null);
    if (!_canPlay || !geo.sketch.contains(at)) {
      _hints.missTap();
      return;
    }
    M6RcBranch? b;
    if (c == M6RcCall.branch) {
      b = M6RcBranch.values.where((x) => geo.branchZone(x).contains(at)).firstOrNull;
      if (b == null) {
        _tick();
        unawaited(_sayChain([M6RecloseCountLines.pickBranch]));
        return;
      }
    }
    // The decisive control: in his dead pause it waits for him.
    if (holdForCoworker()) return;
    _tick('sounds/learn/tag_slap.ogg', 0.6);
    final m = _run.call(c, b);
    final origin = _toGlobal(at);
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, origin));
      return;
    }
    if (!_run.roundDone) return;
    _stepTimer?.cancel();
    _stepTimer = null;
    setState(() {
      _placed = c;
      _placedAt = at;
      _radioN = _run.tries;
    });
    _stepDone();
    unawaited(_roundDone());
  }

  Offset _toGlobal(Offset design) {
    final size = MediaQuery.sizeOf(context);
    return design * (size.width / 360);
  }

  Future<void> _roundDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    var topic = _run.deal.why[_run.index];
    if (topic == M6RcWhy.refused && !coworkerDone) topic = m6RcWhyFor(_run.round.outcome);
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M6RecloseCountLines.whyRight[topic]!, M6RecloseCountLines.myths, widget.rng),
      question: M6RecloseCountLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M6RecloseCountLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerRound || _run.roundDone) return null;
    if (_intro || _card != null || tableBusy || _freeze || !_run.coworkerPause) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      const m = M6RecloseCountMistakes.climbMidCycle;
      _run.failDeadly(m);
      setState(() => _climbed = true);
      await _deadly(m);
      return;
    }
    _run.caught.add(M6RecloseCountLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6RecloseCountLines.callHeld, _task], mood: GuideMood.glad));
    _scheduleStep();
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6RecloseCountLines.tapWhy[_nudgeN++ % M6RecloseCountLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _stepTimer?.cancel();
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
    // The cycle waits while the card is read; it plays on after.
    _stepTimer?.cancel();
    _stepTimer = null;
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _drag = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6rc/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Up the pole mid-cycle: the scene freezes grey, the line comes back on
  /// him in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _stepTimer?.cancel();
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _drag = null;
    });
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.ogg', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('m6rc/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6RecloseCountLines.deadlyWord : M6RecloseCountLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same round goes on: the cycle plays on from where it was.
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        unawaited(_sayChain([_task]));
        _scheduleStep();
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
    _stepTimer?.cancel();
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
      if (mark == 100 && _clock.elapsedMilliseconds < _quickMs) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _clock.elapsedMilliseconds < _quickMs);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? M6RecloseCountLines.fail : (_quickBonus ? M6RecloseCountLines.quick : M6RecloseCountLines.allSet),
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

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_drag != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M6RcRig get _rig => M6RcRig(
        mirror: _run.deal.mirror,
        dusk: _run.deal.dusk,
        lightsA: _climbed || _run.lightsA,
        lightsB: _climbed || _run.lightsB,
        saOpen: _run.saOpen,
        climbed: _climbed,
      );

  /// The gesture hand: how to touch, never what. Before the docket, a tap on
  /// it (the one way on); after it, in turn, a tap ripple on the clicker (on
  /// the idle timer only, never in step with a try) and a sweep over the
  /// three magnets and both branch lines alike.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    if (!_run.tucked) return HintSpec.tap(geo.docket.center, space: HintSpace.scene);
    if (n.isEven) return HintSpec.tap(geo.clicker.center, space: HintSpace.scene);
    return HintSpec.sweep([for (var i = 0; i < 3; i++) geo.magnet(i), for (final b in M6RcBranch.values) geo.branchZone(b)], space: HintSpace.scene);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6RcGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final r = _run;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('land'),
                child: RepaintBoundary(child: CustomPaint(painter: M6RcWorldPainter(geo: geo, rig: _rig))),
              ),
              Positioned.fill(
                key: const ValueKey('board'),
                child: RepaintBoundary(child: CustomPaint(painter: M6RcBoardPainter(geo: geo))),
              ),
              // The bolt (the same cue for every fault): a short fade.
              if (r.bolts > 0)
                Positioned.fill(
                  key: ValueKey('bolt-${r.index}-${r.bolts}'),
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: quiet ? 1 : 0, end: 1),
                      duration: const Duration(milliseconds: 520),
                      builder: (_, v, _) => v >= 0.999 ? const SizedBox.shrink() : CustomPaint(painter: M6RcFlashPainter(geo: geo, at: r.round.bolt, v: v)),
                    ),
                  ),
                ),
              for (var i = 0; i < 3; i++)
                Positioned.fromRect(
                  key: ValueKey('magnet-$i'),
                  rect: geo.magnet(i),
                  child: Opacity(
                    opacity: _drag == M6RcCall.values[i] || _placed == M6RcCall.values[i] ? 0.25 : 1,
                    child: _Magnet(label: M6RecloseCountLines.magnet(M6RcCall.values[i])),
                  ),
                ),
              if (_placed != null)
                Positioned.fromRect(
                  key: ValueKey('placed-${r.index}'),
                  rect: Rect.fromCenter(center: _placedAt, width: 66, height: 34),
                  child: IgnorePointer(child: _Magnet(label: M6RecloseCountLines.magnet(_placed!), placed: true)),
                ),
              if (r.tucked)
                Positioned.fromRect(
                  key: ValueKey('docket-tag-${r.index}'),
                  rect: geo.docketTag,
                  child: IgnorePointer(child: _DocketTag(setting: r.deal.setting)),
                ),
              if (_radioN != null)
                Positioned.fromRect(
                  key: ValueKey('radio-${r.index}'),
                  rect: geo.radio,
                  child: IgnorePointer(child: _RadioChip(text: M6RecloseCountLines.radio(_radioN!))),
                ),
              Positioned.fromRect(
                key: const ValueKey('clicker'),
                rect: geo.clicker,
                child: _Clicker(count: r.taps, label: M6RecloseCountLines.clickerLabel),
              ),
              Positioned.fromRect(
                key: ValueKey('trainee-$_climbed'),
                rect: _climbed ? geo.traineeUp : geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _climbed ? LinemanMode.hold : _mode, wake: _wake, quiet: quiet),
              ),
              if (!r.tucked && !r.ended)
                Positioned.fromRect(
                  key: ValueKey('docket-${r.index}'),
                  rect: geo.docket,
                  child: _Docket(setting: r.deal.setting, round: r.index + 1, quiet: quiet),
                ),
            ],
          ),
        ),
      ),
      if (_drag != null)
        Positioned.fromRect(
          key: const ValueKey('magnet-hand'),
          rect: Rect.fromCenter(center: _dragAt, width: 70, height: 36),
          child: IgnorePointer(child: _Magnet(label: M6RecloseCountLines.magnet(_drag!), lifted: true)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M6RecloseCountLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (_) => _panEnd(geo),
            onPanCancel: () {
              if (_drag != null) setState(() => _drag = null);
            },
          ),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M6RcZapPainter(at: geo.zapAt, v: v)),
            ),
          ),
        ),
      // The next storm: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('round-${r.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || r.index == 0 ? 0 : 0.6, end: 0),
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
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
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
              labels: [for (var i = 0; i < 3; i++) M6RecloseCountLines.round(i + 1)],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _drag == null,
            hintKey: '${_run.index}/$_steps/${_run.tucked}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
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
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 12), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}-$strikes'),
                  mistake: _card!,
                  tone: _cardTone,
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
              if (_freeze && _card == null)
                FreezeFrame(
                  key: const ValueKey('freeze'),
                  muted: _muted,
                  ms: MediaQuery.disableAnimationsOf(context) ? 300 : 2400,
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M6RecloseCountLines.intro,
                  alarm: 'sounds/learn/thunder_far.ogg',
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: m6RcLessonPoint(_run.round.outcome), muted: _muted)),
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

/// The docket: slides up over the board; tapped away before the cycle.
class _Docket extends StatelessWidget {
  const _Docket({required this.setting, required this.round, required this.quiet});
  final int setting;
  final int round;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final ink = bangla(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF2A2018));
    final paper = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1DE),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF8A6A3C), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(M6RecloseCountLines.docket, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A16)))),
            FittedBox(fit: BoxFit.scaleDown, child: Text(M6RecloseCountLines.round(round), style: ink)),
            const Divider(height: 6, thickness: 1, color: Color(0x668A6A3C)),
            FittedBox(fit: BoxFit.scaleDown, child: Text(M6RecloseCountLines.recloser, style: ink)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(M6RecloseCountLines.setting(setting), style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF8A2A16))),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      label: M6RecloseCountLines.docket,
      child: quiet
          ? paper
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              builder: (_, v, child) => Transform.translate(offset: Offset(0, 90 * v), child: Opacity(opacity: 1 - v * 0.6, child: child)),
              child: paper,
            ),
    );
  }
}

/// The docket tucked on the board's edge: the setting stays readable.
class _DocketTag extends StatelessWidget {
  const _DocketTag({required this.setting});
  final int setting;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F1DE),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF8A6A3C), width: 1.4),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('R · ${M6RecloseCountLines.setting(setting)}', style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF8A2A16))),
          ),
        ),
      );
}

/// The radio read-back of R's operation counter (after the call; framing).
class _RadioChip extends StatelessWidget {
  const _RadioChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: const Color(0xE60B1324), borderRadius: BorderRadius.circular(11), border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.8))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings_input_antenna_rounded, size: 13, color: SlmColors.gold300),
            const SizedBox(width: 3),
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.ivory)))),
          ],
        ),
      );
}

/// One magnet: all three alike (no colour, no light, no mark of the answer).
class _Magnet extends StatelessWidget {
  const _Magnet({required this.label, this.lifted = false, this.placed = false});
  final String label;
  final bool lifted;
  final bool placed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3C4A5E), Color(0xFF243042)]),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF8C98A8), width: 1.4),
          boxShadow: [BoxShadow(color: const Color(0x66000000), blurRadius: lifted ? 10 : 3, offset: Offset(0, lifted ? 6 : 2))],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFFF2F4F6))),
            ),
          ),
        ),
      ),
    );
  }
}

/// The hand tally counter: a two-digit window and its thumb button. It shows
/// the player's own taps only.
class _Clicker extends StatelessWidget {
  const _Clicker({required this.count, required this.label});
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: M6RecloseCountLines.tally(count),
      child: Stack(
        children: [
          Positioned.fill(
            top: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFFE6EAEE), Color(0xFF8E969E)]),
                border: Border.all(color: const Color(0xFF4A5058), width: 2),
                boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF14181C), borderRadius: BorderRadius.circular(3)),
                  child: Text(M6RecloseCountLines.tally(count), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFF2F4F6), fontFeatures: [FontFeature.tabularFigures()])),
                ),
              ),
            ),
          ),
          // The thumb button on top.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 22,
                height: 16,
                decoration: BoxDecoration(color: const Color(0xFF6E767E), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF3A3F45))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
