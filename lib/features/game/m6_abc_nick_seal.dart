import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
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
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm6_abc_nick_seal_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm6_abc_nick_seal_world.dart' show M6NickDecoy, M6NickGeo, M6NickMat, M6NickSpan, M6NickView;

// Lesson 6.6 "এবি কেবিল (AB Cable): ঝঞ্ঝাটমুক্ত আধুনিক লাইন", কাজ 2 "কাটা
// আবরণ সিল করো" (pack do_6_6_b, rung 6.6/do/1, engineType m6_abc_nick_seal).
// The patrol found a nick in the AB cable's cover on a residential road; it
// names the span only (two pole numbers). The trainee is up the pole in a
// harness, gloves on; the PTW is given and the crew has isolated, proved dead
// and earthed (X1: drawn, not scored). The lesson's safety tip still says:
// treat the AB cable as live while working (PTW, PPE).
//
// Three jobs, each on a different place on the road (3 of 6 dealt), the nick
// smaller and the decoys more each time:
//
//  Find: the whole span at 1× shows no nick. Double-tap (or pinch) to zoom to
//    3×, drag to pan along the bundle. Up close every small mark shows alike
//    (printing, dust, a bird dropping, a ridge, a twig) and the nick (a notch
//    with the bright conductor in it). Double-tap on the bundle at 3× puts the
//    chalk mark there (again = move it). '1×' zooms out.
//  Start: a touch of the job's material (জলরোধী টেপ or হিট-স্রিঙ্ক টিউব, dealt
//    per job) starts the repair at the chalk mark. Not on the nick = a slip
//    (the mark is wiped; find again).
//  Seal (the core): tape — draw circles round the bundle (every pass across it
//    is a turn where the finger is; drift to move along); tube — drag it to sit
//    over the mark, then hold 'তাপ দিন' until it shrinks. Shrunk off-centre (a
//    part of the nick outside its sealing length) = a slip; the tube is cut off
//    and a new one goes on. Then 'শেষ'.
//  'শেষ': the drizzle comes. The whole nick covered → beads roll off → ◆ on the
//    table → "কেন?" → the next job. A part open → water creeps in → a slip;
//    add turns / shrink a tube, then 'শেষ' again.
//  After 3 jobs: the pass panel.
//
// Deadly (R23, R39 by B1/X2; lesson myth 1 and the safety tip): listening to
// the coworker ('গ্লাভস খুলে খালি হাতে পেঁচাও') — bare hands on the AB cable.
// He comes once a play, on a dealt job, at the first touch of the material
// (the material waits for him: holdForCoworker). Slips: a repair started on a
// spot that is not the nick; 'শেষ' with part of the nick open; a tube shrunk
// off-centre. Three slips strike out.
//
// Giveaways avoided: the span is named, never the spot; the nick cannot be
// seen at 1×; no glow, no ring, no coverage bar; decoys at 3×; the hands show
// on the player's own mark, never the nick; 'শেষ' has no hand.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_abc_nick_seal_world.dart), corner guide, ReasonTable (the
// "কেন?" cards at once), CoworkerMoment, gesture hands for every waiting state
// (how, never what — M6-11 fallbacks: a double-tap ripple for the zoom, an arc
// for the tape), MistakeCard, FreezeFrame + DoDeathGuard, DoStrikeOut, the pass
// panel with stars. Idle = zero frames (the zoom and the drizzle are one-shots).

// ============================================================================
// Content
// ============================================================================

/// What a job's reason asks about.
enum M6NickWhy { cover, material, live, patrol }

/// Where a job is.
enum M6NickStage { find, seal, done }

abstract final class M6NickSealLines {
  static const title = 'কাটা আবরণ সিল করো';

  // DRAFT wording — owner (M6-12): every guide line below is new text.
  static const intro = 'টহলে এবি কেবিলের আবরণে কাটা পাওয়া গেছে — খুঁজে সিল করুন।';
  static const askFind = 'স্প্যানে দুবার ছুঁয়ে কাছ থেকে দেখুন — কাটা পেলে ওখানে দুবার ছুঁয়ে দাগ দিন।';
  static const askSeal = 'দাগের জায়গায় কাটাটা পুরো সিল করুন।';
  static const tasks = [askFind, askSeal];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  static String ask(M6NickStage s) => s == M6NickStage.seal ? askSeal : askFind;

  // On screen (a worker's own words; not spoken).
  static const docket = 'PTW · শাটডাউন · আর্থ';
  static String patrol(int a, int b) => 'টহল: পোল $a–$b-এর মাঝে';
  static const sceneSpan = 'এবি কেবিলের স্প্যান';
  static const zoomOut = '1×';
  static const zoomOutLabel = 'পুরো স্প্যান';
  static const heat = 'তাপ দিন';
  static const done = 'শেষ';
  static const stages = ['প্রথম স্প্যান', 'দ্বিতীয় স্প্যান', 'তৃতীয় স্প্যান'];

  static String mat(M6NickMat m) => switch (m) {
        M6NickMat.tape => 'জলরোধী টেপ',
        M6NickMat.tube => 'হিট-স্রিঙ্ক টিউব',
      };

  // The reasons (lesson 6.6 point 1 daily check, point 3 the nick and the
  // safety tip, pro tip 4, myth 1). DRAFT wording — owner. 41–48 letters.
  static const whyQ = <M6NickWhy, String>{
    M6NickWhy.cover: 'কাটা জায়গাটা কেন পুরো ঢাকতে হবে?',
    M6NickWhy.material: 'কেন জলরোধী টেপ বা হিট-স্রিঙ্ক দিয়ে মেরামত?',
    M6NickWhy.live: 'ইনসুলেটেড কেবিলেও কেন লাইভ ধরে কাজ করলেন?',
    M6NickWhy.patrol: 'টহলে আবরণের কাটা কেন খুঁজতে হয়?',
  };
  static const whyRight = <M6NickWhy, List<String>>{
    M6NickWhy.cover: ['কাটা খোলা থাকলে সেখানে জল ঢুকে ফল্ট হতে পারে', 'পুরো ঢাকা না হলে ফাঁক দিয়ে জল ঢুকে ফল্ট হয়'],
    M6NickWhy.material: ['জলরোধী টেপ বা হিট-স্রিঙ্ক টিউবেই আবরণ মেরামত হয়', 'জলরোধী ইনসুলেটিং টেপ বা টিউব কাটায় জল আটকায়'],
    M6NickWhy.live: ['ইনসুলেশনে অদৃশ্য পিন-হোল থেকেও মারাত্মক শক লাগে', 'কাজের সময় এবি কেবিলকে সবসময় লাইভ ধরতে হয়'],
    M6NickWhy.patrol: ['টহলে আবরণের গভীর কাটা খোঁজা রোজকার দেখার কাজ', 'কাটা আগে ধরা পড়লে জল ঢুকে ফল্ট হওয়ার আগেই সারে'],
  };
  static const myths = [
    'ইনসুলেটেড কেবিলে খালি হাতে কাজ করলেও কিছু হয় না',
    'ছোট্ট কাটা দিয়ে কখনো জল ঢোকে না, কোনো ভয় নেই',
    'কাটার আধখানা ঢাকলেই কাজ চলে যায়, পুরোটা লাগে না',
    'এবি কেবিলে কোনোদিন ফল্ট হয় না, দেখার দরকার নেই',
    'আবরণের কাটা শুধু দেখতে খারাপ, আর কোনো ক্ষতি নেই',
    'টহলে শুধু পোলগুলো দেখলেই চলে, কেবিল দেখতে হয় না',
    'বৃষ্টি থামলে কাটা নিজে থেকেই আবার ঠিক হয়ে যায়',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (once a play). DRAFT wording — owner; his push
  // needs recording (tool/rival_clip.py). His exit line is recorded already.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerLine = 'এবি কেবিল তো ইনসুলেটেড — গ্লাভস খুলে খালি হাতে পেঁচাও, তাড়াতাড়ি হবে।';
  static const coworker = CoworkerScript(
    line: coworkerLine,
    exitLine: coworkerExit,
    right: ['না, গ্লাভস পরেই পেঁচাব আমি', 'না, এবি কেবিলও লাইভ ধরেই চলব', 'না, পিন-হোলেও মারাত্মক শক লাগে'],
    wrong: [
      'ঠিক, ইনসুলেটেড তো, খুলেই ফেলি',
      'আচ্ছা, খালি হাতে তাড়াতাড়ি হবে',
      'হ্যাঁ, এটুকু কাজে গ্লাভস লাগে না',
      'ঠিক আছে, গ্লাভস খুলে পেঁচাই',
      'হ্যাঁ, আবরণ থাকলে শক লাগে না',
    ],
    asks: ['কী করবেন?', 'ও বলছে গ্লাভস খুলে খালি হাতে পেঁচাতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const callHeld = 'ঠিক! এবি কেবিলও লাইভ ধরেই কাজ — গ্লাভস পরেই।';

  static const allSet = 'তিনটে কাটাই খুঁজে পুরো সিল করেছেন — দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — কাছ থেকে খুঁজে, পুরো কাটা ঢেকে, তবে শেষ।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন" (on screen).
  static const caughtFind = 'ছোট কাটাও জুম করে খুঁজে পেয়েছেন';
  static const caughtSeal = 'প্রতিটা কাটা পুরো ঢেকে সিল করেছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন — গ্লাভস পরেই';

  /// Every spoken guide line of this level (DRAFT wording — owner; to be
  /// recorded), including the spoken why-questions and the mistake texts.
  static const newGuideLines = [
    intro,
    askFind,
    askSeal,
    'কারণটা বেছে নিন।',
    'ঠিক কারণটা কোনটা?',
    'কাটা জায়গাটা কেন পুরো ঢাকতে হবে?',
    'কেন জলরোধী টেপ বা হিট-স্রিঙ্ক দিয়ে মেরামত?',
    'ইনসুলেটেড কেবিলেও কেন লাইভ ধরে কাজ করলেন?',
    'টহলে আবরণের কাটা কেন খুঁজতে হয়?',
    'কী করবেন?',
    'ও বলছে গ্লাভস খুলে খালি হাতে পেঁচাতে। কী করবেন?',
    'ওর কথা শুনবেন, না নিয়ম?',
    callHeld,
    allSet,
    quick,
    fail,
    deadlyWord,
    nearMissWord,
    M6NickSealMistakes.wrongSpotBn,
    M6NickSealMistakes.uncoveredBn,
    M6NickSealMistakes.tubeOffBn,
    M6NickSealMistakes.bareHandsBn,
  ];

  /// The coworker's new push (DRAFT wording — owner; to be recorded in his
  /// voice). His exit line is recorded already.
  static const newRivalLines = [coworkerLine];
}

abstract final class M6NickSealMistakes {
  static const _dir = 'assets/game/art/m6_abc_nick_seal';

  // Lesson 6.6 points (0-based): 0 what AB cable is (+ the patrol's daily
  // check for deep cuts in the cover), 1 the hardware, 2 installation and
  // troubles (the insulation nick lets water in → fault; the safety tip:
  // treat it as live, PTW, PPE).
  // DRAFT wording — owner (every text below is read aloud the first time).
  static const wrongSpotBn = 'এটা কাটা নয় — মেরামত শুরুর আগে কাছ থেকে দেখে আসল কাটাটা খুঁজে দাগ দিন।';
  static const uncoveredBn = 'কাটার কিছু অংশ এখনও খোলা — ওখান দিয়ে জল ঢুকে ফল্ট হতে পারে। পুরো কাটা ঢেকে তবে শেষ করুন।';
  static const tubeOffBn = 'টিউবটা কাটার ঠিক মাঝখানে বসেনি — কাটার এক পাশ খোলা থেকে গেল। নতুন টিউব মাঝখানে বসিয়ে তাপ দিন।';
  // Lesson myth 1's reality, nearly word for word.
  static const bareHandsBn = 'মারাত্মক ভুল এবং বিপজ্জনক! ইনসুলেশনটি লাইভ লাইন কাজের জন্য ডিজাইন করা হয়নি। যেকোনো ইনসুলেশনে একটি অদৃশ্য পিন-হোল বা ফাটল থাকতে পারে, যা মারাত্মক শক দেওয়ার জন্য যথেষ্ট। গ্লাভস কখনো খুলবেন না।';

  static const wrongSpot = DoMistake(key: '6.6/m6_abc_nick_seal/wrong-spot', textBn: wrongSpotBn, art: '$_dir/wrong_spot.svg', lessonPoint: 0);
  static const uncovered = DoMistake(key: '6.6/m6_abc_nick_seal/uncovered', textBn: uncoveredBn, art: '$_dir/uncovered.svg', lessonPoint: 2);
  static const tubeOff = DoMistake(key: '6.6/m6_abc_nick_seal/tube-off-centre', textBn: tubeOffBn, art: '$_dir/tube_off.svg', lessonPoint: 2);
  static const bareHands = DoMistake(key: '6.6/m6_abc_nick_seal/bare-hands', textBn: bareHandsBn, art: '$_dir/bare_hands.svg', deadly: true, lessonPoint: 2);

  static const List<DoMistake> all = [wrongSpot, uncovered, tubeOff, bareHands];
}

/// One job: a span, its nick, its decoys and its material.
@immutable
class M6NickJob {
  const M6NickJob({
    required this.span,
    required this.poles,
    required this.nickT,
    required this.nickLen,
    required this.nickCore,
    required this.decoys,
    required this.mat,
    required this.tubeOffset,
  });

  final M6NickSpan span;
  final (int, int) poles;

  /// The nick's middle (t along the span) and its length (t units).
  final double nickT;
  final double nickLen;
  final int nickCore;
  final List<M6NickMark> decoys;
  final M6NickMat mat;

  /// Where a new tube goes on, from the chalk mark (t units, ±).
  final double tubeOffset;
}

/// One play's deal.
@immutable
class M6NickDeal {
  const M6NickDeal({required this.jobs, required this.coworkerJob, required this.whys});
  final List<M6NickJob> jobs;

  /// The job on which the coworker comes.
  final int coworkerJob;

  /// The reason topic of each job (all different).
  final List<M6NickWhy> whys;
}

/// How far past the nick's ends a chalk mark still counts as on it (t units).
/// Kept so a tube centred on any accepted mark still holds the whole nick:
/// nickLen / 2 + slack <= tube sealing half − nickLen / 2 on every job.
const double m6NickMarkSlack = 0.010;

/// The nick's length per job (it gets smaller).
const List<double> m6NickLens = [0.030, 0.023, 0.017];

/// The decoys per job (more each time).
const List<int> m6NickDecoyCounts = [2, 3, 4];

/// Places on the span the scenery already uses (the IPC on the drop span,
/// the branch on the tree span): no nick or decoy there.
bool _sceneryAt(M6NickSpan s, double t) => switch (s) {
      M6NickSpan.drop => (t - 0.3).abs() < 0.05,
      M6NickSpan.branch => (t - 0.72).abs() < 0.05,
      _ => false,
    };

M6NickDeal m6NickDeal(math.Random rng) {
  final spans = [...M6NickSpan.values]..shuffle(rng);
  final mats = [M6NickMat.tape, M6NickMat.tube, rng.nextBool() ? M6NickMat.tape : M6NickMat.tube]..shuffle(rng);
  var pole = 4 + rng.nextInt(30);
  final jobs = <M6NickJob>[];
  for (var j = 0; j < 3; j++) {
    final span = spans[j];
    double nick;
    do {
      nick = 0.12 + rng.nextDouble() * 0.76;
    } while (_sceneryAt(span, nick));
    final taken = <double>[nick];
    final kinds = [...M6NickDecoy.values]..shuffle(rng);
    final decoys = <M6NickMark>[];
    for (var k = 0; k < m6NickDecoyCounts[j]; k++) {
      double t;
      var tries = 0;
      do {
        t = 0.08 + rng.nextDouble() * 0.84;
        tries++;
      } while (tries < 200 && (_sceneryAt(span, t) || taken.any((x) => (x - t).abs() < 0.07)));
      taken.add(t);
      decoys.add(M6NickMark(kinds[k % kinds.length], t, rng.nextInt(3)));
    }
    final off = (0.052 + rng.nextDouble() * 0.014) * (rng.nextBool() ? 1 : -1);
    jobs.add(M6NickJob(
      span: span,
      poles: (pole, pole + 1),
      nickT: nick,
      nickLen: m6NickLens[j],
      nickCore: rng.nextInt(3),
      decoys: decoys,
      mat: mats[j],
      tubeOffset: off,
    ));
    pole += 2 + rng.nextInt(6);
  }
  final whys = [...M6NickWhy.values]..shuffle(rng);
  // His push is about wrapping: he comes on a tape job only (every deal has one).
  final tapeJobs = [for (var j = 0; j < 3; j++) if (jobs[j].mat == M6NickMat.tape) j];
  return M6NickDeal(jobs: jobs, coworkerJob: tapeJobs[rng.nextInt(tapeJobs.length)], whys: whys.take(3).toList());
}

/// The play state (pure logic).
class M6NickRun {
  M6NickRun(this.deal);

  final M6NickDeal deal;

  int job = 0;
  M6NickStage stage = M6NickStage.find;

  /// The player's chalk mark (t), if any.
  double? mark;

  /// Tape turns (t of each).
  final List<double> turns = [];
  double? tubeT;
  var shrunk = false;
  int tubesUsed = 0;
  var complete = false;

  int slips = 0;
  int jobSlips = 0;
  var _findSlip = false;
  var _sealSlip = false;
  DoMistake? deadly;
  final List<String> caught = [];

  M6NickJob get now => deal.jobs[math.min(job, 2)];
  bool get ended => complete || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => complete && deadly == null && percent >= 55;
  bool get _open => deadly == null && !complete;

  /// The mark is on the nick (within a little of its ends).
  bool get markOnNick {
    final m = mark;
    if (m == null) return false;
    return (m - now.nickT).abs() <= now.nickLen / 2 + m6NickMarkSlack;
  }

  /// The tube's sealing length holds the whole nick.
  bool get tubeHoldsNick {
    final t = tubeT;
    if (t == null) return false;
    return (now.nickT - t).abs() + now.nickLen / 2 <= m6NickTubeLen / 2 - m6NickTubeEdge + 1e-9;
  }

  /// The whole nick is sealed.
  bool get covered {
    final j = now;
    if (j.mat == M6NickMat.tube) return shrunk && tubeHoldsNick;
    if (turns.isEmpty) return false;
    const steps = 12;
    for (var i = 0; i <= steps; i++) {
      final p = j.nickT - j.nickLen / 2 + j.nickLen * i / steps;
      if (!turns.any((t) => (t - p).abs() <= m6NickTapeW / 2)) return false;
    }
    return true;
  }

  /// The repair has begun (the material is on).
  bool get started => stage == M6NickStage.seal;

  DoMistake _slip(DoMistake m) {
    slips++;
    jobSlips++;
    return m;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Chalk at [t] (find only; again = move it). True if it was put.
  bool chalk(double t) {
    if (!_open || stage != M6NickStage.find) return false;
    mark = t.clamp(0.0, 1.0);
    return true;
  }

  /// The first touch of the material: the repair starts at the mark. Not on
  /// the nick: a slip, the mark is wiped. No mark: nothing (null, no slip).
  DoMistake? startRepair() {
    if (!_open || stage != M6NickStage.find || mark == null) return null;
    if (!markOnNick) {
      mark = null;
      _findSlip = true;
      return _slip(M6NickSealMistakes.wrongSpot);
    }
    stage = M6NickStage.seal;
    if (now.mat == M6NickMat.tube) _newTube();
    return null;
  }

  void _newTube() {
    tubeT = (mark! + (tubesUsed.isEven ? now.tubeOffset : -now.tubeOffset)).clamp(m6NickTubeLen / 2, 1 - m6NickTubeLen / 2);
    shrunk = false;
    tubesUsed++;
  }

  /// A tape turn at [t]; true if it was laid.
  bool wrap(double t) {
    if (!_open || stage != M6NickStage.seal || now.mat != M6NickMat.tape) return false;
    turns.add(t.clamp(0.0, 1.0));
    return true;
  }

  /// Slide the unshrunk tube by [dt].
  void moveTube(double dt) {
    if (!_open || stage != M6NickStage.seal || tubeT == null || shrunk) return;
    tubeT = (tubeT! + dt).clamp(m6NickTubeLen / 2, 1 - m6NickTubeLen / 2);
  }

  /// The heat held to the end: the tube shrinks. Off-centre: a slip, the
  /// tube is cut off and a new one goes on.
  DoMistake? shrink() {
    if (!_open || stage != M6NickStage.seal || tubeT == null || shrunk) return null;
    if (!tubeHoldsNick) {
      _sealSlip = true;
      _newTube();
      return _slip(M6NickSealMistakes.tubeOff);
    }
    shrunk = true;
    return null;
  }

  /// 'শেষ': the whole nick sealed → the job is done; a part open → a slip.
  DoMistake? finish() {
    if (!_open || stage != M6NickStage.seal) return null;
    if (!covered) {
      _sealSlip = true;
      return _slip(M6NickSealMistakes.uncovered);
    }
    stage = M6NickStage.done;
    return null;
  }

  /// The table was paid: on to the next job (or the end).
  void nextJob() {
    if (stage != M6NickStage.done) return;
    if (job == 2) {
      complete = true;
      if (!_findSlip) _tag(M6NickSealLines.caughtFind);
      if (!_sealSlip) _tag(M6NickSealLines.caughtSeal);
      return;
    }
    job++;
    stage = M6NickStage.find;
    mark = null;
    turns.clear();
    tubeT = null;
    shrunk = false;
    tubesUsed = 0;
    jobSlips = 0;
  }

  /// Listened to the coworker: gloves off on the AB cable (deadly, B1).
  DoMistake listen() => deadly = M6NickSealMistakes.bareHands;

  /// The coworker's moment: his job, before the repair has begun.
  bool get coworkerFits => _open && job == deal.coworkerJob && stage == M6NickStage.find;
}

/// The gesture hand while the job waits (how, never what). [layerOf] maps a
/// span place (t) to the layer under the current view.
///  * Find at 1×–2.4×: a sweep along the whole span (five places alike) and a
///    tap on the span's middle.
///  * Find zoomed in: a swipe left, a swipe right (pan), then a tap on the
///    bundle at the view's middle — wherever the player looks.
///  KIT GAP: both find taps are double-taps in play (zoom at 1×, chalk at
///  3×), but the kit's [HintKind] has no double-tap, so the hand shows a
///  single press. The guide's ask line names the double-tap meanwhile; swap
///  these two for a kit double-tap hint once the director adds one.
///  * A mark, nothing in hand: a sweep over the tray.
///  * Tape: an arc across the bundle on the player's own mark, down then up.
///  * Tube: a nudge of the tube left or right, then a hold on the heat.
///  * Shrunk: none ('শেষ' has no hand).
HintSpec? m6NickHint({
  required int n,
  required M6NickRun run,
  required M6NickView view,
  required M6NickGeo geo,
  required Offset Function(double t) layerOf,
  HintSpec? Function()? tray,
  HintSpec? Function()? heat,
}) {
  final j = run.now;
  switch (run.stage) {
    case M6NickStage.find:
      if (!view.detail) {
        if (n.isEven) {
          return HintSpec.sweep([for (var i = 0; i < 5; i++) Rect.fromCenter(center: layerOf(0.1 + 0.2 * i), width: 36, height: 36)], space: HintSpace.scene);
        }
        return HintSpec.tap(layerOf(0.5), space: HintSpace.scene);
      }
      if (run.mark != null && n % 4 == 3) return tray?.call();
      final mid = view.toWorld(geo.centre, geo);
      final onBundle = layerOf(geo.tAt(mid.dx));
      switch (n % 3) {
        case 0:
          return HintSpec.swipe(onBundle.translate(40, 0), toward: const Offset(-1, 0), travel: 80, space: HintSpace.scene);
        case 1:
          return HintSpec.swipe(onBundle.translate(-40, 0), toward: const Offset(1, 0), travel: 80, space: HintSpace.scene);
        default:
          return HintSpec.tap(onBundle, space: HintSpace.scene);
      }
    case M6NickStage.seal:
      final m = run.mark;
      if (m == null) return null;
      if (j.mat == M6NickMat.tape) {
        final p = layerOf(m);
        return n.isEven
            ? HintSpec.swipe(p.translate(0, -30), toward: const Offset(0, 1), travel: 60, space: HintSpace.scene)
            : HintSpec.swipe(p.translate(0, 30), toward: const Offset(0, -1), travel: 60, space: HintSpace.scene);
      }
      if (run.shrunk) return null;
      final t = run.tubeT;
      if (t == null) return null;
      return switch (n % 3) {
        0 => HintSpec.drag(layerOf(t), toward: const Offset(1, 0), travel: 40, space: HintSpace.scene),
        1 => HintSpec.drag(layerOf(t), toward: const Offset(-1, 0), travel: 40, space: HintSpace.scene),
        _ => heat?.call(),
      };
    case M6NickStage.done:
      return null;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   per job: double-tap zoom 1500, pan along the span ~6000, chalk 1500,
///     the material 1500, the seal ~5000 (turns / slide + 1400 heat),
///     'শেষ' 1500, the drizzle 1300, the reason ~8200        ≈ 26500
///   3 jobs ≈ 79500, the coworker once ≈ 9600                ≈ 89100
/// 85 % ≈ 75700 → 80 s.
const m6NickSealQuickMs = 80000;

/// How long the heat is held before the tube shrinks.
const m6NickHeatMs = 1400;

/// Test hook: the play state of the page now on screen (tests only).
abstract final class M6NickSealProbe {
  @visibleForTesting
  static M6NickRun? run;

  /// The layer (design px) of a span place under the current view.
  @visibleForTesting
  static Offset Function(double t)? layerOf;

  /// The current view.
  @visibleForTesting
  static M6NickView? view;
}

@immutable
class M6NickSealPack {
  const M6NickSealPack({required this.id, required this.titleBn, this.quickMs = m6NickSealQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6NickSealPack> m6NickSealPacks = {
  'do_6_6_b': M6NickSealPack(id: 'do_6_6_b', titleBn: M6NickSealLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M6NickSealPage extends StatefulWidget {
  const M6NickSealPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6NickSealPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6NickSealPage> createState() => _M6NickSealPageState();
}

class _M6NickSealPageState extends State<M6NickSealPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _NickRunPage(
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

class _NickRunPage extends ConsumerStatefulWidget {
  const _NickRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6NickSealPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_NickRunPage> createState() => _NickRunPageState();
}

/// What a drag on the scene is doing.
enum _Drag { none, view, pinch, wrap, tube }

class _NickRunPageState extends ConsumerState<_NickRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6NickRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  late final AnimationController _zoom = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  late final AnimationController _rain = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  M6NickView? _viewFrom;
  M6NickView? _viewTo;
  M6NickView? _viewNow;
  var _rainSealed = false;
  var _raining = false;

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
  int _steps = 0;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // The heat control.
  Timer? _heatTimer;
  var _heating = false;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _matKey = GlobalKey();
  final _zoomKey = GlobalKey();
  final _heatKey = GlobalKey();
  final _touchKey = GlobalKey();
  int _hintN = 0;
  M6NickGeo? _geoNow;

  // A drag on the scene.
  _Drag _drag = _Drag.none;
  Offset _dragLast = Offset.zero;
  double _pinchZ0 = 1;
  double _pinchS0 = 1;
  Offset _pinchWorld = Offset.zero;
  Offset _doubleAt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _run = M6NickRun(m6NickDeal(widget.rng));
    M6NickSealProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _heatTimer?.cancel();
    _zoom.dispose();
    _rain.dispose();
    _chain++;
    if (M6NickSealProbe.run == _run) {
      M6NickSealProbe.layerOf = null;
      M6NickSealProbe.view = null;
    }
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
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_freeze && !_raining && !_run.ended && _run.stage != M6NickStage.done;

  String get _task => M6NickSealLines.ask(_run.stage);

  void _stepDone() {
    _steps++;
    setState(() {});
  }

  Future<void> _start() async {
    _clock.start();
    unawaited(_sayChain([_task]));
  }

  // --- the view -----------------------------------------------------------------
  M6NickView _view(M6NickGeo g) {
    final from = _viewFrom, to = _viewTo;
    if (from == null || to == null) return _viewNow ?? M6NickView.whole(g);
    return M6NickView.lerp(from, to, Curves.easeInOut.transform(_zoom.value));
  }

  void _setView(M6NickView v, {bool animate = false}) {
    final g = _geoNow;
    if (g == null) return;
    final cur = _view(g);
    final next = v.clamped(g);
    _viewNow = next;
    if (animate && !_quiet) {
      _viewFrom = cur;
      _viewTo = next;
      unawaited(_zoom.forward(from: 0).whenComplete(() {
        if (!mounted || _viewTo != next) return;
        setState(() {
          _viewFrom = null;
          _viewTo = null;
        });
      }));
    } else {
      _zoom.stop();
      _viewFrom = null;
      _viewTo = null;
    }
    setState(() {});
  }

  /// The layer (design px) of a span place under the current view.
  Offset _layerOf(double t) {
    final g = _geoNow!;
    return _view(g).toLayer(g.cable(t), g);
  }

  /// The span place under a layer point, and whether it is on the bundle
  /// (within [slack] layer px of it).
  (double, bool) _spanAt(Offset layer, {double slack = 30}) {
    final g = _geoNow!;
    final v = _view(g);
    final w = v.toWorld(layer, g);
    final t = g.tAt(w.dx);
    final near = (w.dy - g.cable(t).dy).abs() * v.z <= slack && w.dx >= M6NickGeo.spanL && w.dx <= M6NickGeo.spanR;
    return (t, near);
  }

  void _zoomOut() {
    if (!_canPlay) return;
    _tick('sounds/intro/click.ogg', 0.45);
    final g = _geoNow;
    if (g == null) return;
    _setView(M6NickView.whole(g), animate: true);
    _steps++;
  }

  // --- the scene's touches --------------------------------------------------------
  void _doubleTap() {
    if (!_canPlay) return;
    final g = _geoNow;
    if (g == null) return;
    final v = _view(g);
    final p = _doubleAt;
    if (!v.detail) {
      // Zoom to 3× where the finger is, the bundle in the middle.
      final w = v.toWorld(p, g);
      final t = g.tAt(w.dx);
      _tick('sounds/intro/click.ogg', 0.4);
      _setView(M6NickView(m6NickMaxZoom, Offset(w.dx, g.cable(t).dy)), animate: true);
      _steps++;
      return;
    }
    if (_run.stage != M6NickStage.find) {
      _hints.missTap();
      return;
    }
    final (t, near) = _spanAt(p);
    if (!near) {
      _hints.missTap();
      return;
    }
    if (_run.chalk(t)) {
      HapticFeedback.lightImpact();
      _cue('sounds/intro/tick.ogg', volume: 0.55);
      _stepDone();
    }
  }

  void _scaleStart(ScaleStartDetails d) {
    _drag = _Drag.none;
    if (!_canPlay) return;
    final g = _geoNow;
    if (g == null) return;
    _dragLast = d.localFocalPoint;
    if (d.pointerCount >= 2) {
      _beginPinch(d.localFocalPoint, 1);
      return;
    }
    if (_run.stage == M6NickStage.seal) {
      final j = _run.now;
      if (j.mat == M6NickMat.tape) {
        final (_, near) = _spanAt(d.localFocalPoint, slack: 70);
        if (near) {
          _drag = _Drag.wrap;
          return;
        }
      } else if (!_run.shrunk && _run.tubeT != null) {
        final c = _layerOf(_run.tubeT!);
        final half = m6NickTubeLen * M6NickGeo.spanW * _view(g).z / 2;
        if ((d.localFocalPoint.dx - c.dx).abs() <= half + 14 && (d.localFocalPoint.dy - c.dy).abs() <= 34) {
          _drag = _Drag.tube;
          return;
        }
      }
    }
    _drag = _Drag.view;
  }

  void _beginPinch(Offset focal, double scale) {
    final g = _geoNow!;
    final v = _view(g);
    _drag = _Drag.pinch;
    _pinchZ0 = v.z;
    _pinchS0 = scale <= 0 ? 1 : scale;
    _pinchWorld = v.toWorld(focal, g);
  }

  void _scaleUpdate(ScaleUpdateDetails d) {
    final g = _geoNow;
    if (g == null || _drag == _Drag.none) return;
    if (!_canPlay) {
      _drag = _Drag.none;
      return;
    }
    final p = d.localFocalPoint;
    final last = _dragLast;
    _dragLast = p;
    if (d.pointerCount >= 2 && _drag != _Drag.pinch) {
      _beginPinch(p, d.scale);
      return;
    }
    switch (_drag) {
      case _Drag.pinch:
        final z = (_pinchZ0 * d.scale / _pinchS0).clamp(1.0, m6NickMaxZoom);
        final f = _pinchWorld - (p - g.centre) / z;
        _setView(M6NickView(z, f));
      case _Drag.view:
        final v = _view(g);
        _setView(M6NickView(v.z, v.f - (p - last) / v.z));
      case _Drag.wrap:
        // A pass across the bundle lays a turn where the finger crosses it.
        final v = _view(g);
        final w0 = v.toWorld(last, g);
        final w1 = v.toWorld(p, g);
        final t = g.tAt(w1.dx);
        final y = g.cable(t).dy;
        final crossed = (w0.dy - y) * (w1.dy - y) < 0 || (w1.dy - y).abs() < 0.01;
        if (crossed && (w1.dy - y).abs() * v.z < 80) {
          if (_run.wrap(t)) {
            HapticFeedback.selectionClick();
            if (_run.turns.length % 3 == 1) _cue('sounds/intro/tick.ogg', volume: 0.3);
            setState(() {});
          }
        }
      case _Drag.tube:
        final v = _view(g);
        _run.moveTube((p.dx - last.dx) / v.z / M6NickGeo.spanW);
        setState(() {});
      case _Drag.none:
        break;
    }
  }

  void _scaleEnd(ScaleEndDetails d) {
    final kind = _drag;
    _drag = _Drag.none;
    if (kind == _Drag.wrap || kind == _Drag.tube || kind == _Drag.view || kind == _Drag.pinch) {
      if (_canPlay) _stepDone();
    }
  }

  // --- the tray -------------------------------------------------------------------
  /// The first touch of the material starts the repair at the mark (the
  /// coworker's moment on his job waits for this touch).
  void _touchMaterial(Offset origin) {
    if (!_canPlay || _run.stage != M6NickStage.find) return;
    if (_run.coworkerFits && !coworkerDone && !coworkerDue) scheduleCoworker();
    if (holdForCoworker()) return;
    if (_run.mark == null) {
      _hints.missTap();
      return;
    }
    _tick('sounds/intro/click.ogg', 0.5);
    final m = _run.startRepair();
    if (m != null) {
      setState(() {});
      unawaited(_mistake(m, origin));
      return;
    }
    unawaited(_levelDelta(5, origin, mood: GuideMood.glad));
    _stepDone();
    unawaited(_sayChain([_task]));
  }

  void _heatDown() {
    if (!_canPlay || _run.stage != M6NickStage.seal || _run.shrunk || _run.tubeT == null) return;
    _heatTimer?.cancel();
    setState(() => _heating = true);
    _heatTimer = Timer(const Duration(milliseconds: m6NickHeatMs), _heatDone);
  }

  void _heatUp() {
    if (!_heating) return;
    _heatTimer?.cancel();
    setState(() => _heating = false);
    _hints.missTap();
  }

  void _heatDone() {
    if (!mounted) return;
    setState(() => _heating = false);
    if (!_canPlay) return;
    final m = _run.shrink();
    if (m != null) {
      setState(() {});
      unawaited(_mistake(m, _globalOfHeat()));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/ring_steel.ogg', volume: 0.45);
    _stepDone();
  }

  Offset _globalOfHeat() {
    final r = HintSpec.globalRectOf(_heatKey);
    return r?.center ?? Offset.zero;
  }

  void _finishJob(Offset origin) {
    if (!_canPlay || _run.stage != M6NickStage.seal) return;
    _tick('sounds/intro/click.ogg', 0.5);
    final m = _run.finish();
    _rainSealed = m == null;
    setState(() => _raining = true);
    _cue('sounds/learn/rush_in.ogg', volume: 0.25);
    final wait = _quiet ? 500 : 1500;
    if (_quiet) {
      _rain.value = 1;
    } else {
      unawaited(_rain.forward(from: 0));
    }
    unawaited(Future<void>.delayed(Duration(milliseconds: wait), () {
      if (!mounted || _ended) return;
      setState(() => _raining = false);
      if (m != null) {
        _rain.value = 0;
        unawaited(_mistake(m, origin));
        return;
      }
      _sealed();
    }));
  }

  /// The whole nick sealed: ◆ on the table, then this job's reason.
  void _sealed() {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/confirm.ogg', volume: 0.7);
    _rain.value = 0;
    putOnTable(15 + (_run.jobSlips == 0 ? 5 : 0));
    final topic = _run.deal.whys[_run.job];
    unawaited(askReason(
      deal: () => dealChoices(M6NickSealLines.whyRight[topic]!, M6NickSealLines.myths, widget.rng),
      question: M6NickSealLines.whyQ[topic]!,
      stillValid: () => !_ended,
    ));
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
    _run.nextJob();
    _rain.value = 0;
    if (_run.complete) {
      unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
        if (mounted && !_ended) unawaited(_finish());
      }));
      return;
    }
    final g = _geoNow;
    if (g != null) _setView(M6NickView.whole(g));
    setState(() => _steps++);
    unawaited(_sayChain([_task]));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M6NickSealLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || !_run.coworkerFits) return null;
    if (_intro || _card != null || tableBusy || _freeze || _raining) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() {
    _hush();
    _heatTimer?.cancel();
    if (_heating && mounted) setState(() => _heating = false);
  }

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.listen();
      final g = _geoNow;
      if (g != null) _flashAt = _view(g).toLayer(g.cable(0.06).translate(0, 4), g);
      await _deadly(m);
      return;
    }
    _run.caught.add(M6NickSealLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6NickSealLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6NickSealLines.tapWhy[_nudgeN++ % M6NickSealLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    _heatTimer?.cancel();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6nickseal/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Gloves off on the AB cable: the scene freezes grey and the shock flashes
  /// at the bare hand in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _heatTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _heating = false;
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
    final speak = await SpokenOnce.first('m6nickseal/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6NickSealLines.deadlyWord : M6NickSealLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _steps++;
        });
        unawaited(_sayChain([_task]));
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
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _clock.elapsedMilliseconds < widget.pack.quickMs);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? M6NickSealLines.fail : (_quickBonus ? M6NickSealLines.quick : M6NickSealLines.allSet),
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
  M6NickRig _rig(double rain) {
    final j = _run.now;
    return M6NickRig(
      span: j.span,
      poles: j.poles,
      nickT: j.nickT,
      nickLen: j.nickLen,
      nickCore: j.nickCore,
      decoys: j.decoys,
      mark: _run.mark,
      turns: [..._run.turns],
      tubeT: _run.tubeT,
      shrunk: _run.shrunk,
      rain: rain,
      sealed: _rainSealed,
      bare: _freeze,
    );
  }

  HintSpec? _hint() {
    final g = _geoNow;
    if (g == null) return null;
    return m6NickHint(
      n: _hintN++,
      run: _run,
      view: _view(g),
      geo: g,
      layerOf: _layerOf,
      tray: () => HintSpec.sweepOver([_matKey, if (_view(g).z > 1.01) _zoomKey]),
      heat: () => HintSpec.holdOn(_heatKey),
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6NickGeo.forScene(m.height, m.inset);
    M6NickSealProbe.layerOf = _layerOf;
    M6NickSealProbe.view = _view(geo);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([_zoom, _rain]),
              builder: (_, _) => CustomPaint(painter: M6NickWorldPainter(geo: geo, rig: _rig(_rain.value), view: _view(geo))),
            ),
          ),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M6NickSealLines.sceneSpan,
          child: GestureDetector(
            key: _touchKey,
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (_) => _hints.missTap(),
            onDoubleTapDown: (d) => _doubleAt = d.localPosition,
            onDoubleTap: _doubleTap,
            onScaleStart: _scaleStart,
            onScaleUpdate: _scaleUpdate,
            onScaleEnd: _scaleEnd,
          ),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M6NickFlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
      // A new job: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('place-${_run.job}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.job == 0 ? 0 : 0.7, end: 0),
              duration: const Duration(milliseconds: 560),
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
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_raining && !_run.ended && _run.stage != M6NickStage.done;
    final g = _geoNow;
    final zoomed = g != null && _view(g).z > 1.01;
    final j = _run.now;
    final seal = _run.stage == M6NickStage.seal;
    final tube = seal && j.mat == M6NickMat.tube;
    final waiting = handsOn && !tableBusy && _drag == _Drag.none && !_heating && !(tube && _run.shrunk);
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
              labels: M6NickSealLines.stages,
              done: {for (var i = 0; i < 3; i++) if (i < _run.job || (i == _run.job && (_run.stage == M6NickStage.done || _run.complete))) i},
              current: _run.complete ? null : _run.job,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: waiting,
            hintKey: '${_run.job}/${_run.stage.name}/$_steps/${_run.mark != null}/$zoomed/${_run.shrunk}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing)
                Positioned(
                  key: const ValueKey('dockets'),
                  top: pad.top + 92,
                  left: 10,
                  child: IgnorePointer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _DocketChip(text: M6NickSealLines.docket, icon: Icons.lock_rounded, tone: Color(0xFFB03A2E)),
                        const SizedBox(height: 5),
                        _DocketChip(
                          key: ValueKey('patrol-${_run.job}'),
                          text: M6NickSealLines.patrol(j.poles.$1, j.poles.$2),
                          icon: Icons.assignment_rounded,
                          tone: const Color(0xFF2E5E8C),
                        ),
                      ],
                    ),
                  ),
                ),
              if (handsOn)
                Positioned(
                  key: ValueKey('tray-${_run.job}-${_run.stage.name}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (zoomed)
                        _TrayButton(
                          key: _zoomKey,
                          icon: Icons.zoom_out_map_rounded,
                          label: M6NickSealLines.zoomOut,
                          semantics: M6NickSealLines.zoomOutLabel,
                          onTap: (_) => _zoomOut(),
                        ),
                      _TrayButton(
                        key: _matKey,
                        icon: j.mat == M6NickMat.tape ? Icons.donut_large_rounded : Icons.straighten_rounded,
                        label: M6NickSealLines.mat(j.mat),
                        on: seal,
                        onTap: _touchMaterial,
                      ),
                      if (tube && !_run.shrunk)
                        _HoldButton(
                          key: _heatKey,
                          label: M6NickSealLines.heat,
                          holding: _heating,
                          quiet: quiet,
                          onDown: _heatDown,
                          onUp: _heatUp,
                        ),
                      if (seal)
                        _TrayButton(
                          key: const ValueKey('nick-done'),
                          icon: Icons.check_rounded,
                          label: M6NickSealLines.done,
                          onTap: _finishJob,
                        ),
                    ],
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 96), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$strikes'),
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
                  line: M6NickSealLines.intro,
                  alarm: 'sounds/learn/rush_in.ogg',
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

/// A docket on the job (a worker reads it).
class _DocketChip extends StatelessWidget {
  const _DocketChip({super.key, required this.text, required this.icon, required this.tone});
  final String text;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xE6F7F1DE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tone, width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tone),
          const SizedBox(width: 5),
          Text(text, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018))),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.on, this.child});
  final IconData icon;
  final String label;
  final bool on;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return SizedBox(
      width: 88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
              ),
              border: Border.all(color: ring.withValues(alpha: 0.9), width: on ? 2.4 : 1.7),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Stack(alignment: Alignment.center, children: [?child, Icon(icon, size: 24, color: ring)]),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, softWrap: false, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tray button: a round icon with its name under it.
class _TrayButton extends StatelessWidget {
  const _TrayButton({super.key, required this.icon, required this.label, required this.onTap, this.semantics, this.on = false});
  final IconData icon;
  final String label;
  final String? semantics;
  final bool on;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantics ?? label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: _Chip(icon: icon, label: label, on: on),
      ),
    );
  }
}

/// The heat: press and hold (a ring fills); let go early = nothing.
class _HoldButton extends StatelessWidget {
  const _HoldButton({super.key, required this.label, required this.holding, required this.quiet, required this.onDown, required this.onUp});
  final String label;
  final bool holding;
  final bool quiet;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: _Chip(
          icon: Icons.local_fire_department_rounded,
          label: label,
          on: holding,
          child: holding
              ? TweenAnimationBuilder<double>(
                  key: const ValueKey('heat-ring'),
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: quiet ? 1 : m6NickHeatMs),
                  builder: (_, v, _) => SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(value: quiet ? 1 : v, strokeWidth: 3, color: const Color(0xFFE67E22)),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
