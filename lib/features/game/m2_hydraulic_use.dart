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
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm2_hydraulic_use_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm2_hydraulic_use_world.dart' show HydGeo, HydZone, hydZoneRect;

// Lesson 2.9 "হাইড্রোলিক ক্রিম্পার ও কাটার: দানবীয় শক্তি", কাজ 2 "কাটার আগে
// নিশ্চিত হও" (pack do_2_9_b). Three jobs a play at an open cable trench with
// three armoured cables, each with its feeder tag: cut a big cable, or crimp a
// lug on one. Hands on: tap the cable the docket names, prove it dead (the
// tester, the earth lead), then use the tool in the lesson's order —
//   • cutter (point 3): put the cable in the blades, close the safety lock,
//     pump; the blade cuts slowly;
//   • crimper (point 2): the right die from the chart (myth: a near size will
//     do), set it on the lug, pump until the pressure release valve opens by
//     itself with a click (pro tip 2) — then let go;
//   • fingers and body out from between the die and the lug (point 2's
//     safety tip): the free hand goes on the pump body.
// Sometimes the docket's cable still reads voltage on the tester after the
// shutdown: the job stops and is reported.
//
// Proving a cable dead (test + discharge/earth before touching it) is not in
// lesson 2.9's text: it is the project's line-work rule (BRIEF_M2 "work on
// lines only after shutdown, PTW, test and discharge/earth"; lesson 1.6 step 4
// "discharge and test"). No order is enforced between the test and the earth
// (1.6 names both, no order); no spiking (not in the lessons). Flagged.
//
// Deadly: putting the tool on (cutting / crimping) a cable not proved dead —
// also on the coworker's say-so ("এটাই তো মরা কেবল, কেটে দাও!"). Slips: the
// earth lead on a cable that reads voltage, the wrong die, pumping the cutter
// without the safety lock, the free hand in the jaws or on the cable at them,
// letting go of the crimper before the valve clicks, and a needless stop (the
// docket's cable not read LIVE on the tester: untested, or tested dead — a
// stop must cost something, audit 2026-11-11; the card says why only after
// the decision). Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m2_hydraulic_use_world.dart), corner guide, ◆ on the table → "কেন …?"
// → the next job by itself; the careless coworker once a play, on a cut job,
// before anything is tested — every tool step and the stop wait for him
// (`holdForCoworker`), so a fast play cannot skip him; his push fits only
// until a cable is tested or the tool is on. Listening stays deadly: the act
// he pushes (the cutter on a cable not proved dead) is this rung's deadly in
// MODULE2_LADDER.md. Gesture hints (how, never what): a sweep over the
// cables, the tool row, the close-up's zones or the die tray; a tap only on
// "ছাড়ুন" once the valve has clicked (the one way forward). Voice: the guide
// by device TTS; the coworker's two lines have no clip yet (silent, caption
// held — see HydLines.coworker).

// ============================================================================
// Content
// ============================================================================

enum HydKind { cut, crimp }

/// The steps on the tool row (dealt in a fresh order every job).
enum HydStep { test, earth, die, place, lock, pump }

/// How a job ended well.
enum HydEnd { cut, crimp, stop }

@immutable
class HydJob {
  const HydJob({
    required this.id,
    required this.kind,
    required this.tags,
    required this.target,
    required this.liveTarget,
    required this.size,
    required this.dies,
    required this.steps,
  });

  final String id;
  final HydKind kind;

  /// The three cables' tags, top to bottom.
  final List<String> tags;

  /// The docket's cable (its slot).
  final int target;

  /// The docket's cable still reads voltage after the shutdown (stop, report).
  final bool liveTarget;

  /// The cable's size (sq mm, on the docket).
  final int size;

  /// The dies in the tray (crimp jobs).
  final List<int> dies;

  /// The tool row, in this job's dealt order.
  final List<HydStep> steps;

  bool get cut => kind == HydKind.cut;

  /// The cables next to the docket's one are in service.
  bool live(int slot) => slot != target || liveTarget;
}

abstract final class HydLines {
  static const title = 'কাটার আগে নিশ্চিত হও';
  static const intro = 'মোটা কেবল কাটা আর ল্যাগ ক্রিম্প — হাইড্রোলিকের দানবীয় শক্তি! কাটার আগে নিশ্চিত হোন।';
  static const rounds = ['ক', 'খ', 'গ'];
  static const askCut = 'ডকেট পড়ুন — এই কেবলটা কাটতে হবে।';
  static const askCrimp = 'ডকেট পড়ুন — এই কেবলে ল্যাগ ক্রিম্প করতে হবে।';
  static String ask(HydJob j) => j.cut ? askCut : askCrimp;
  static const askHand = 'অন্য হাতটা কোথায় রাখবেন?';
  static const tasks = [askCut, askCrimp];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'ট্রেঞ্চের কেবল';
  static String cableLabel(String tag) => 'কেবল $tag';
  static const docket = 'ডকেট';
  static const jobCut = 'কেবল কাটা';
  static const jobCrimp = 'ল্যাগ ক্রিম্প';
  static String sqmm(int v) => enDigits('$v sq mm');
  static const tester = 'টেস্টার';
  static const earth = 'আর্থ';
  static const die = 'ডাই';
  static const placeCut = 'কাটার বসান';
  static const placeCrimp = 'ক্রিম্পার বসান';
  static const lock = 'সেফটি লক';
  static const pump = 'পাম্প';
  static const release = 'ছাড়ুন';
  static const stop = 'কাজ বন্ধ — রিপোর্ট';
  static const close = 'বন্ধ';
  static String dieOf(int v) => enDigits('ডাই $v');
  static const live = 'LIVE';
  static const dead = 'NO VOLTAGE';
  static const click = 'ক্লিক!';
  static const zoneHandle = 'পাম্পের বডি';
  static const zoneJaws = 'চোয়াল';
  static const zoneCable = 'চোয়ালের পাশে কেবল';
  static String zoneBn(HydZone z) => switch (z) {
        HydZone.handle => zoneHandle,
        HydZone.jaws => zoneJaws,
        HydZone.cable => zoneCable,
      };
  static String stepBn(HydStep s, HydKind k) => switch (s) {
        HydStep.test => tester,
        HydStep.earth => earth,
        HydStep.die => die,
        HydStep.place => k == HydKind.cut ? placeCut : placeCrimp,
        HydStep.lock => lock,
        HydStep.pump => pump,
      };

  static const stampCut = 'কাটা হলো';
  static const stampCrimp = 'ক্রিম্প পাকা';
  static const stampStop = 'রিপোর্ট হলো';

  // Not-scored lines (an action that cannot be done yet).
  static const pickFirst = 'কোন কেবলে? আগে কেবলটা বেছে নিন।';
  static const placeFirst = 'টুল এখনো কেবলে বসানো হয়নি।';
  static const handFirst = 'আগে অন্য হাতটা ঠিক জায়গায় রাখুন।';
  static const toolOn = 'টুল বসানো আছে — এখন কেবল বা ডাই বদলানো যায় না।';
  static const pumpFirst = 'এখনো পাম্পই করা হয়নি।';

  // The reasons (lesson 2.9 + the prove-dead rule): the right ones fit what
  // the player did; the wrong ones are the lesson's myths and field excuses.
  static const whyCut = 'কেন এভাবে কাটলেন?';
  static const whyCrimp = 'কেন এভাবে ক্রিম্প করলেন?';
  static const whyStop = 'কেন কাজ থামালেন?';
  static const cutRight = [
    'টেস্টারে মরা দেখে, আর্থ দিয়ে তবে কাটলাম',
    'ডকেটের কেবল চিনে, প্রমাণ করে তবে কাটা',
    'সেফটি লক বন্ধ করে পাম্প, তাই নিরাপদ কাটা',
  ];
  static const crimpRight = [
    'রিলিজ ভাল্ভ ক্লিক করা পর্যন্ত পুরো চাপ',
    'চার্ট মিলিয়ে ঠিক ডাই, তাই ক্রিম্প মজবুত',
    'মরা প্রমাণ করে, আঙুল ডাইয়ের বাইরে রেখে কাজ',
  ];
  static const stopRight = [
    'টেস্টারে ভোল্টেজ, তাই এই কেবলে হাত নয়',
    'শাটডাউনের পরেও লাইভ, কাজ বন্ধ করে রিপোর্ট',
  ];

  /// Wrong reasons for a job done (the myths and shortcuts).
  static const goMyths = [
    'ডকেটে বন্ধ লেখা, টেস্ট না করলেও চলত',
    'কাছাকাছি সাইজের ডাই হলেও কাজ চলে যায়',
    'অর্ধেক চাপেই ল্যাগ বসে যায়, পুরোটা লাগে না',
    'গ্লাভস আছে, আঙুল ডাইয়ে থাকলেও কিছু হয় না',
    'সবাই তো এভাবেই তাড়াতাড়ি কেটে ফেলে',
    'হাইড্রোলিক টুলে ভুল হয় না, তাই নিশ্চিন্ত',
  ];

  /// Wrong reasons to stop (bad motives, none a lesson rule).
  static const stopExcuses = [
    'পাম্প করতে খাটুনি, তাই কাজ বন্ধ করলাম',
    'চা খাওয়ার সময় হয়ে গেছে, তাই থামলাম',
    'টুলটা ভারী, তাই আজ আর কাটব না ভাবলাম',
    'সুপারভাইজার দেখছেন না, একটু জিরিয়ে নিই',
    'কাজটা কঠিন, পরে অন্য কেউ করে দেবে',
  ];

  static List<String> whyRight(HydEnd e) => switch (e) {
        HydEnd.cut => cutRight,
        HydEnd.crimp => crimpRight,
        HydEnd.stop => stopRight,
      };
  static List<String> whyWrong(HydEnd e) => e == HydEnd.stop ? stopExcuses : goMyths;
  static String whyAsk(HydEnd e) => switch (e) {
        HydEnd.cut => whyCut,
        HydEnd.crimp => whyCrimp,
        HydEnd.stop => whyStop,
      };

  /// The careless coworker. No clip of his yet: silent, caption held (never
  /// the device voice) until the director records them.
  static const coworker = CoworkerScript(
    line: 'এটাই তো মরা কেবল, কেটে দাও! টেস্ট-ফেস্ট লাগবে না।',
    exitLine: 'হুঁ! যত সব ঝামেলা।',
    right: ['না, আগে টেস্টারে মরা প্রমাণ করব', 'না, প্রমাণ না করে কেবল কাটব না', 'আগে টেস্ট আর আর্থ, তারপর কাটা'],
    wrong: ['ঠিক, ডকেটে বন্ধ লেখা, কেটে দিই', 'আচ্ছা, চটপট কেটেই ফেলি তাহলে', 'তুমি বলছ যখন, মরাই হবে নিশ্চয়', 'টেস্ট করতে সময় লাগে, কেটে দিই', 'সবাই তো টেস্ট ছাড়াই কেটে ফেলে'],
    asks: ['ও বলছে টেস্ট ছাড়াই কাটতে। আপনি কী করবেন?', 'ওর কথায় কাটবেন, না আগে নিশ্চিত হবেন?', 'কাটবেন এখনই, না আগে প্রমাণ?'],
  );

  static const callHeld = 'ঠিক! মরা প্রমাণ না হলে কেবল কাটা নয়।';
  static const allSet = 'হাইড্রোলিকের শক্তি এখন আপনার হাতে — কাটার আগে নিশ্চিত, ক্রিম্পে পুরো চাপ।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — কেবল চিনুন, মরা প্রমাণ করুন, টুল চালান পাঠের নিয়মে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtProve = 'টেস্ট আর আর্থ করে তবে টুল';
  static const caughtWrongCable = 'পাশের লাইভ কেবল টেস্টেই ধরা';
  static const caughtLive = 'লাইভ কেবলে কাজ থামিয়ে রিপোর্ট';
  static const caughtDie = 'চার্ট মিলিয়ে ঠিক ডাই';
  static const caughtClick = 'ক্লিক পর্যন্ত পুরো চাপ';
  static const caughtLock = 'সেফটি লক বন্ধ করে পাম্প';
  static const caughtHand = 'আঙুল চোয়ালের বাইরে';
  static const caughtCall = 'চাপে “না” বলেছেন';

  /// Every fixed line of the guide (for recording later).
  static const guideLines = [
    intro, askCut, askCrimp, askHand, ...tapWhy, pickFirst, placeFirst, handFirst, toolOn, pumpFirst,
    whyCut, whyCrimp, whyStop, callHeld, allSet, quick, fail, deadlyWord, nearMissWord,
  ];
}

abstract final class HydMistakes {
  static const _dir = 'assets/game/art/m2_hydraulic_use';

  /// Lesson points (0-based): 0 hydraulics, 1 the crimper, 2 the cutter, 3 care.
  static const cutUnproved = DoMistake(
    key: '2.9/hyd/cut-unproved',
    textBn: 'মরা প্রমাণ না করেই কেবলে কাটার! ডকেটের কেবলটা চিনুন, টেস্টারে ভোল্টেজ নেই দেখুন, আর্থ দিন — তারপর কাটা।',
    art: '$_dir/unproved.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const crimpUnproved = DoMistake(
    key: '2.9/hyd/crimp-unproved',
    textBn: 'মরা প্রমাণ না করেই কেবলে ক্রিম্পার! ডকেটের কেবলটা চিনুন, টেস্টারে ভোল্টেজ নেই দেখুন, আর্থ দিন — তারপর কাজ।',
    art: '$_dir/unproved.svg',
    deadly: true,
    lessonPoint: 1,
  );

  /// Not in lesson 2.9 (the prove-dead rule): no lesson point.
  static const earthLive = DoMistake(
    key: '2.9/hyd/earth-on-live',
    textBn: 'ভোল্টেজ আছে এমন কেবলে আর্থ লাগালেন — স্পার্ক! ডকেটের কেবলটাই চিনুন; টেস্টারে লাইভ পেলে কাজ বন্ধ, রিপোর্ট।',
    art: '$_dir/earth_live.svg',
  );
  static const wrongDie = DoMistake(
    key: '2.9/hyd/wrong-die',
    textBn: 'চার্ট মিলিয়ে কেবলের সাইজের ডাই নিন। কাছাকাছি সাইজের ডাই দুর্বল আর বিপজ্জনক ক্রিম্প দেয়।',
    art: '$_dir/wrong_die.svg',
    lessonPoint: 1,
  );
  static const noLock = DoMistake(
    key: '2.9/hyd/no-safety-lock',
    textBn: 'কেবল ব্লেডে বসিয়ে আগে সেফটি লক বন্ধ করুন, তারপর পাম্প।',
    art: '$_dir/no_lock.svg',
    lessonPoint: 2,
  );
  static const fingersCrimp = DoMistake(
    key: '2.9/hyd/fingers-crimp',
    textBn: 'আঙুল বা শরীরের কোনো অংশ ডাই আর ল্যাগের মাঝে নয় — মুহূর্তে মারাত্মক আঘাত হতে পারে। হাত রাখুন পাম্পের বডিতে।',
    art: '$_dir/fingers.svg',
    lessonPoint: 1,
  );
  static const fingersCut = DoMistake(
    key: '2.9/hyd/fingers-cut',
    textBn: 'ব্লেড অত্যন্ত ধারালো আর শক্ত — আঙুল ব্লেডের মাঝে বা তার পাশে কেবলে নয়। হাত রাখুন পাম্পের বডিতে।',
    art: '$_dir/fingers.svg',
    lessonPoint: 2,
  );
  static const halfCrimp = DoMistake(
    key: '2.9/hyd/half-crimp',
    textBn: 'পুরো চাপ দিন — প্রেসার রিলিজ ভাল্ভ নিজে থেকে ক্লিক করে খোলা পর্যন্ত। আধা চাপে ক্রিম্প দুর্বল, হটস্পট হয়।',
    art: '$_dir/half_crimp.svg',
    lessonPoint: 1,
  );

  /// A stop without a LIVE reading on the docket's cable (untested, or it
  /// tested dead): not in lesson 2.9 (the prove-dead rule) — no lesson point.
  /// Neutral: it names the rule, not which case it was.
  static const needlessStop = DoMistake(
    key: '2.9/hyd/needless-stop',
    textBn: 'ডকেটের কেবলে টেস্টার LIVE না দেখাতেই কাজ বন্ধ হলো। আগে ডকেটের কেবলটাই টেস্ট করুন — LIVE পেলে থামিয়ে রিপোর্ট, মরা প্রমাণ হলে আর্থ দিয়ে কাজ।',
    art: '$_dir/needless_stop.svg',
  );

  static const all = [cutUnproved, crimpUnproved, earthLive, wrongDie, noLock, fingersCrimp, fingersCut, halfCrimp, needlessStop];
}

/// Pump strokes to cut through, or to the valve's click.
const kHydStrokes = 6;

@immutable
class HydDeal {
  const HydDeal({required this.jobs, required this.callAt});
  final List<HydJob> jobs;

  /// The cut job where the careless coworker comes.
  final int callAt;
}

const _tagPool = ['F-03', 'F-05', 'F-07', 'F-09', 'F-11', 'F-12', 'F-14', 'F-15', 'F-18', 'F-21'];
const _crimpSizes = [120, 150, 185, 240, 300, 400];
const _cutSizes = [300, 400];

/// Three jobs: at least one cut and one crimp; in about half the plays one
/// job's docket cable still reads voltage (stop, report). The coworker comes
/// on a cut job.
HydDeal dealHyd(math.Random rng) {
  final kinds = [HydKind.cut, HydKind.crimp, rng.nextBool() ? HydKind.cut : HydKind.crimp]..shuffle(rng);
  final liveAt = rng.nextBool() ? rng.nextInt(3) : -1;
  final jobs = <HydJob>[];
  for (final (i, k) in kinds.indexed) {
    final tags = [..._tagPool]..shuffle(rng);
    final size = k == HydKind.cut ? _cutSizes[rng.nextInt(_cutSizes.length)] : _crimpSizes[rng.nextInt(_crimpSizes.length)];
    // The tray: the right die, its near sizes (the lesson's myth) and one more.
    final si = _crimpSizes.indexOf(size);
    final near = <int>{
      size,
      if (si > 0) _crimpSizes[si - 1],
      if (si >= 0 && si < _crimpSizes.length - 1) _crimpSizes[si + 1],
    };
    final rest = [..._crimpSizes.where((s) => !near.contains(s))]..shuffle(rng);
    final dies = [...near, ...rest].take(4).toList()..sort();
    final steps = [HydStep.test, HydStep.earth, HydStep.place, HydStep.pump, k == HydKind.cut ? HydStep.lock : HydStep.die]..shuffle(rng);
    jobs.add(HydJob(
      id: 'j$i',
      kind: k,
      tags: tags.take(3).toList(),
      target: rng.nextInt(3),
      liveTarget: i == liveAt,
      size: size,
      dies: dies,
      steps: steps,
    ));
  }
  final cuts = [
    for (final (i, j) in jobs.indexed)
      if (j.cut) i,
  ];
  return HydDeal(jobs: jobs, callAt: cuts[rng.nextInt(cuts.length)]);
}

/// What an action did: a mistake, a not-scored line, or the job done.
@immutable
class HydAct {
  const HydAct({this.mistake, this.note, this.end});
  static const ok = HydAct();
  final DoMistake? mistake;
  final String? note;
  final HydEnd? end;
}

/// The play state (pure logic).
class HydRun {
  HydRun(this.deal);
  final HydDeal deal;
  int index = 0;
  int? selected;
  final Set<int> tested = {};
  final Set<int> earthed = {};
  int? die;
  var placed = false;
  var locked = false;
  HydZone? hand;
  int strokes = 0;
  var clicked = false;

  /// Not-scored lines this job (a clean job has none: +5).
  int notes = 0;
  bool shown = false;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.jobs.length;
  bool get ended => done || deadly != null;
  HydJob get current => deal.jobs[index.clamp(0, deal.jobs.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => notes == 0;
  bool get _idle => ended || shown;

  /// Proved dead: the docket's cable, tested with no voltage, earthed.
  bool proved(int slot) => tested.contains(slot) && earthed.contains(slot) && !current.live(slot);

  /// The tester's reading on [slot] (null = not tested).
  bool? reading(int slot) => tested.contains(slot) ? current.live(slot) : null;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  HydAct _note(String line) {
    notes++;
    return HydAct(note: line);
  }

  HydAct _slip(DoMistake m) {
    shown = true;
    slips++;
    return HydAct(mistake: m);
  }

  HydAct _die(DoMistake m) {
    shown = true;
    deadly = m;
    return HydAct(mistake: m);
  }

  HydAct select(int slot) {
    if (_idle) return HydAct.ok;
    if (placed) return _note(HydLines.toolOn);
    selected = slot;
    return HydAct.ok;
  }

  HydAct test() {
    if (_idle) return HydAct.ok;
    final s = selected;
    if (s == null) return _note(HydLines.pickFirst);
    tested.add(s);
    if (s != current.target && current.live(s)) _tag(HydLines.caughtWrongCable);
    return HydAct.ok;
  }

  HydAct earth() {
    if (_idle) return HydAct.ok;
    final s = selected;
    if (s == null) return _note(HydLines.pickFirst);
    if (current.live(s)) return _slip(HydMistakes.earthLive);
    earthed.add(s);
    return HydAct.ok;
  }

  HydAct pickDie(int size) {
    if (_idle) return HydAct.ok;
    if (placed) return _note(HydLines.toolOn);
    if (size != current.size) return _slip(HydMistakes.wrongDie);
    die = size;
    return HydAct.ok;
  }

  HydAct place() {
    if (_idle) return HydAct.ok;
    if (placed) return HydAct.ok;
    final s = selected;
    if (s == null) return _note(HydLines.pickFirst);
    if (!proved(s)) return _die(current.cut ? HydMistakes.cutUnproved : HydMistakes.crimpUnproved);
    if (!current.cut && die == null) return _slip(HydMistakes.wrongDie);
    placed = true;
    _tag(HydLines.caughtProve);
    if (!current.cut) _tag(HydLines.caughtDie);
    return HydAct.ok;
  }

  HydAct lock() {
    if (_idle) return HydAct.ok;
    if (!placed) return _note(HydLines.placeFirst);
    locked = true;
    return HydAct.ok;
  }

  HydAct putHand(HydZone z) {
    if (_idle || !placed || hand != null) return HydAct.ok;
    if (z != HydZone.handle) return _slip(current.cut ? HydMistakes.fingersCut : HydMistakes.fingersCrimp);
    hand = z;
    _tag(HydLines.caughtHand);
    return HydAct.ok;
  }

  HydAct pump() {
    if (_idle) return HydAct.ok;
    if (!placed) return _note(HydLines.placeFirst);
    if (current.cut && !locked) return _slip(HydMistakes.noLock);
    if (hand == null) return _note(HydLines.handFirst);
    if (clicked) return HydAct.ok;
    strokes++;
    if (strokes < kHydStrokes) return HydAct.ok;
    if (current.cut) {
      shown = true;
      _tag(HydLines.caughtLock);
      return const HydAct(end: HydEnd.cut);
    }
    clicked = true;
    return HydAct.ok;
  }

  HydAct release() {
    if (_idle || current.cut || !placed) return HydAct.ok;
    if (strokes == 0) return _note(HydLines.pumpFirst);
    if (!clicked) return _slip(HydMistakes.halfCrimp);
    shown = true;
    _tag(HydLines.caughtClick);
    return const HydAct(end: HydEnd.crimp);
  }

  /// Stop and report: right only when the docket's cable tested live; any
  /// other stop (untested, or tested dead) is a needless stop: a slip.
  HydAct stop() {
    if (_idle) return HydAct.ok;
    final t = current.target;
    if (!tested.contains(t) || !current.live(t)) return _slip(HydMistakes.needlessStop);
    shown = true;
    _tag(HydLines.caughtLive);
    return const HydAct(end: HydEnd.stop);
  }

  /// Listened to the coworker: cut without proving.
  HydAct pushedCut() {
    if (_idle) return HydAct.ok;
    return _die(HydMistakes.cutUnproved);
  }

  void next() {
    index++;
    selected = null;
    tested.clear();
    earthed.clear();
    die = null;
    placed = false;
    locked = false;
    hand = null;
    strokes = 0;
    clicked = false;
    notes = 0;
    shown = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %). A thorough job
/// (ms, ~1500 per action): read the docket 2000, pick the cable 1500, test
/// 1500 + read 1000, earth 1500, (die: open 1500 + pick 1500 on a crimp),
/// place 1500, (lock 1500 on a cut), hand: the ask ~1800 + 1500, pump
/// 6 × 450, (let go 1500 on a crimp) ≈ 18000; reason ≈ 8200 → 26200 × 3 =
/// 78600, + the coworker ≈ 9600 → 88200; 85 % ≈ 75000.
const kHydQuickMs = 75000;

@immutable
class M2HydraulicUsePack {
  const M2HydraulicUsePack({required this.id, required this.titleBn, this.quickMs = kHydQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2HydraulicUsePacks = {
  'do_2_9_b': M2HydraulicUsePack(id: 'do_2_9_b', titleBn: HydLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M2HydraulicUsePage extends StatefulWidget {
  const M2HydraulicUsePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M2HydraulicUsePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2HydraulicUsePage> createState() => _M2HydraulicUsePageState();
}

class _M2HydraulicUsePageState extends State<M2HydraulicUsePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _HydRunPage(
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

class _HydRunPage extends ConsumerStatefulWidget {
  const _HydRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2HydraulicUsePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_HydRunPage> createState() => _HydRunPageState();
}

class _HydRunPageState extends ConsumerState<_HydRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final HydRun _run = HydRun(dealHyd(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  HydEnd? _verdict;

  /// The die tray is open.
  var _tray = false;

  // Gesture hints (how to touch, never what): the frame's hand and the keys
  // of what it may sweep over.
  final _hints = IdleHintController();
  final _stepKeys = {for (final s in HydStep.values) s: GlobalKey(debugLabel: 'hyd-step-${s.name}')};
  final _stopKey = GlobalKey(debugLabel: 'hyd-stop');
  final _releaseKey = GlobalKey(debugLabel: 'hyd-release');
  final _zoneKeys = {for (final z in HydZone.values) z: GlobalKey(debugLabel: 'hyd-zone-${z.name}')};
  final _dieKeys = <int, GlobalKey>{};
  HydGeo? _geo;

  /// A spark on the trench (the earth lead on a live cable): its cable.
  int? _spark;
  int _sparkN = 0;
  Timer? _sparkTimer;

  var _freeze = false;
  /// The cable the deadly flash is on.
  int? _hitAt;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _sparkTimer?.cancel();
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

  bool get _canPlay =>
      !_intro && !_busy && !_ended && _card == null && !tableBusy && !coworkerOpen && !_run.shown && !_tray;

  // --- a job --------------------------------------------------------------------
  void _startJob() {
    setState(() {
      _verdict = null;
      _tray = false;
      _wake++;
    });
    if (_run.index == _run.deal.callAt && !coworkerDone) scheduleCoworker();
    unawaited(_sayChain([HydLines.ask(_run.current)]));
  }

  void _tapScene(Offset p, HydGeo geo) {
    if (!_canPlay) return;
    for (var i = 0; i < 3; i++) {
      if (geo.cableRect(i).contains(p)) {
        HapticFeedback.selectionClick();
        _cue('sounds/intro/tick.ogg', volume: 0.45);
        _apply(_run.select(i), p);
        return;
      }
    }
    _hints.missTap();
  }

  /// Every tool step and the stop wait for him on his job (he comes now):
  /// a fast play cannot finish his item before his push.
  void _step(HydStep s, Offset origin) {
    if (!_canPlay) return;
    if (holdForCoworker()) return;
    switch (s) {
      case HydStep.test:
        final a = _run.test();
        if (a.note == null) {
          final live = _run.reading(_run.selected!) ?? false;
          _cue(live ? 'sounds/learn/spark.wav' : 'sounds/intro/click.ogg', volume: live ? 0.5 : 0.5);
          if (live) HapticFeedback.mediumImpact();
        }
        _apply(a, origin);
      case HydStep.earth:
        final a = _run.earth();
        if (a.mistake == null && a.note == null) _cue('sounds/intro/impact_metal.ogg', volume: 0.5);
        _apply(a, origin);
      case HydStep.die:
        if (_run.placed) {
          _apply(_run.pickDie(0), origin);
          return;
        }
        HapticFeedback.selectionClick();
        _cue('sounds/quiz_select.wav', volume: 0.45);
        setState(() => _tray = true);
      case HydStep.place:
        final a = _run.place();
        if (a.mistake == null && a.note == null) {
          _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
          _apply(a, origin);
          unawaited(_sayChain([HydLines.askHand]));
          return;
        }
        _apply(a, origin);
      case HydStep.lock:
        final a = _run.lock();
        if (a.note == null) _cue('sounds/intro/click.ogg', volume: 0.6);
        _apply(a, origin);
      case HydStep.pump:
        _pump(origin);
    }
  }

  void _pump(Offset origin) {
    if (!_canPlay) return;
    final before = _run.clicked;
    final a = _run.pump();
    if (a.mistake == null && a.note == null) {
      HapticFeedback.lightImpact();
      _cue('sounds/learn/tock.wav', volume: 0.5);
      if (_run.clicked && !before) {
        // The pressure release valve opens by itself: the click.
        _cue('sounds/intro/click.ogg', volume: 0.95);
        HapticFeedback.mediumImpact();
      }
      if (a.end == HydEnd.cut) _cue('sounds/intro/impact_metal.ogg', volume: 0.85);
    }
    _apply(a, origin);
  }

  void _pickDie(int size, Offset origin) {
    if (!_tray || _ended) return;
    _cue('sounds/intro/click.ogg', volume: 0.5);
    setState(() => _tray = false);
    _apply(_run.pickDie(size), origin);
  }

  void _closeTray() {
    if (!_tray) return;
    _cue('sounds/intro/click.ogg', volume: 0.4);
    setState(() => _tray = false);
  }

  void _putHand(HydZone z, Offset origin) {
    if (!_canPlay || _run.hand != null) return;
    HapticFeedback.selectionClick();
    _apply(_run.putHand(z), origin);
  }

  void _release(Offset origin) {
    if (!_canPlay) return;
    final a = _run.release();
    if (a.end != null) _cue('sounds/intro/confirm.ogg', volume: 0.6);
    _apply(a, origin);
  }

  void _stopJob(Offset origin) {
    if (!_canPlay) return;
    if (holdForCoworker()) return;
    _apply(_run.stop(), origin);
  }

  /// What an action did, on the screen.
  void _apply(HydAct a, Offset origin) {
    setState(() => _wake++);
    if (a.note != null) {
      _cue('sounds/intro/click.ogg', volume: 0.5);
      unawaited(_sayChain([a.note!]));
      return;
    }
    final m = a.mistake;
    if (m != null) {
      if (m.deadly) {
        unawaited(_deadly(m));
        return;
      }
      if (m == HydMistakes.earthLive) _sparkOn(_run.selected ?? _run.current.target);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      unawaited(_slip(m));
      return;
    }
    final end = a.end;
    if (end != null) _done(end);
  }

  void _sparkOn(int slot) {
    _cue('sounds/learn/spark.wav', volume: 0.9);
    _sparkTimer?.cancel();
    setState(() {
      _spark = slot;
      _sparkN++;
    });
    _sparkTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _spark = null);
    });
  }

  void _done(HydEnd end) {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.7);
    _cue('sounds/quiz_right.wav', volume: 0.6);
    setState(() {
      _verdict = end;
      _wake++;
    });
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(HydLines.whyRight(end), HydLines.whyWrong(end), widget.rng),
      question: HydLines.whyAsk(end),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startJob();
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
  CoworkerScript get coworkerScript => HydLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callAt || _run.shown) return null;
    // His push ("no test needed") fits only before anything is tested and
    // before the tool is on.
    if (_run.tested.isNotEmpty || _run.placed) return null;
    if (_intro || _busy || _card != null || tableBusy || _tray) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!mounted || _ended) return;
    if (!held) {
      // Listened to him: the cutter goes on a cable not proved dead — this
      // rung's deadly (MODULE2_LADDER.md step 27), so listening stays deadly.
      _apply(_run.pushedCut(), origin);
      return;
    }
    _run.caught.add(HydLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    unawaited(_sayChain([HydLines.callHeld], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? HydLines.tapWhy[_nudgeN++ % HydLines.tapWhy.length]
            : _nudge.next(_run.placed && _run.hand == null ? HydLines.askHand : HydLines.ask(_run.current));
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
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

  Future<void> _slip(DoMistake m) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _tray = false;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('hyd/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The tool on a cable not proved dead: the trench freezes grey, the flash
  /// at the tool comes in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.wav', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _tray = false;
      _hitAt = _run.selected ?? _run.current.target;
    });
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.wav', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('hyd/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? HydLines.deadlyWord : HydLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        _next();
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
    await _say(!_run.passed ? HydLines.fail : (_quickBonus ? HydLines.quick : HydLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
    if (coworkerHeld || coworkerOpen) return LinemanMode.worried;
    if (_verdict != null) return LinemanMode.cheer;
    if (_run.selected != null) return LinemanMode.point;
    return LinemanMode.idle;
  }

  List<HydCableLook> _looks() {
    final j = _run.current;
    final on = _run.placed || (_verdict == HydEnd.cut || _verdict == HydEnd.crimp);
    return [
      for (var i = 0; i < 3; i++)
        HydCableLook(
          tag: j.tags[i],
          picked: _run.selected == i && !_freeze,
          reading: _run.reading(i),
          earthed: _run.earthed.contains(i),
          // The head stays on until the cut / the crimp is shown.
          tool: on && _run.selected == i && _verdict != HydEnd.cut ? j.cut : null,
          cut: _verdict == HydEnd.cut && _run.selected == i,
          crimped: _verdict == HydEnd.crimp && _run.selected == i,
          closing: _run.selected == i ? (_verdict != null ? 1 : _run.strokes / kHydStrokes) : 0,
        ),
    ];
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = HydGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final j = _run.current;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('yard'),
                child: RepaintBoundary(child: CustomPaint(painter: HydYardPainter(geo: geo))),
              ),
              Positioned.fill(
                key: const ValueKey('cables'),
                child: RepaintBoundary(child: CustomPaint(painter: HydCablesPainter(geo: geo, cables: _looks()))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, point: 0.9, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      // The tester's readings, by each tested cable.
      if (!_freeze)
        for (var i = 0; i < 3; i++)
          if (_run.reading(i) != null)
            Positioned(
              key: ValueKey('reading-${_run.index}-$i'),
              left: HydGeo.testX - 50,
              top: geo.cableY(i) - 30,
              child: IgnorePointer(child: _Reading(live: _run.reading(i)!, quiet: quiet)),
            ),
      if (_spark != null && !_freeze)
        Positioned(
          key: ValueKey('spark-$_sparkN'),
          left: HydGeo.earthX - 40,
          top: geo.cableY(_spark!) - 40,
          width: 80,
          height: 80,
          child: IgnorePointer(child: _Flash(quiet: quiet)),
        ),
      if (_verdict != null && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: 150,
          width: 180,
          top: geo.wallY - 92,
          child: IgnorePointer(
            child: _StampPop(
              text: switch (_verdict!) {
                HydEnd.cut => HydLines.stampCut,
                HydEnd.crimp => HydLines.stampCrimp,
                HydEnd.stop => HydLines.stampStop,
              },
              quiet: quiet,
            ),
          ),
        ),
      // Tap a cable to pick it.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: HydLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo)),
        ),
      ),
      // The cables for a screen reader (and tests): their tags.
      for (var i = 0; i < 3; i++)
        Positioned.fromRect(
          key: ValueKey('cable-sem-$i'),
          rect: Rect.fromCenter(center: geo.tagAt(i), width: 44, height: 20),
          child: Semantics(
            label: HydLines.cableLabel(j.tags[i]),
            button: true,
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(geo.tagAt(i), geo)),
          ),
        ),
      if (_freeze && _hitAt != null)
        Positioned(
          key: const ValueKey('hit'),
          left: HydGeo.toolX - 70,
          top: geo.cableY(_hitAt!) - 70,
          width: 140,
          height: 140,
          child: IgnorePointer(child: _Flash(quiet: quiet, big: true)),
        ),
      if (!_intro && !_freeze)
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

  bool _stepOn(HydStep s) {
    final sel = _run.selected;
    return switch (s) {
      HydStep.test => sel != null && _run.tested.contains(sel),
      HydStep.earth => sel != null && _run.earthed.contains(sel),
      HydStep.die => _run.die != null,
      HydStep.place => _run.placed,
      HydStep.lock => _run.locked,
      HydStep.pump => _run.strokes > 0,
    };
  }

  GlobalKey _dieKey(int size) => _dieKeys.putIfAbsent(size, () => GlobalKey(debugLabel: 'hyd-die-$size'));

  /// The hand for now: how to touch, never what. A sweep passes over every
  /// option the same way (the cables, the tool row and the stop, the
  /// close-up's zones, the dies); a tap only on "ছাড়ুন" once the valve has
  /// clicked — then it is the one way forward.
  HintSpec? _hint() {
    if (_run.ended) return null;
    final j = _run.current;
    if (_tray) return HintSpec.sweepOver([for (final d in j.dies) _dieKey(d)]);
    final crimpOn = _run.placed && !j.cut;
    if (_run.placed && _run.hand == null) {
      return HintSpec.sweepOver([for (final z in const [HydZone.cable, HydZone.jaws, HydZone.handle]) _zoneKeys[z]!]);
    }
    if (crimpOn && _run.clicked) return HintSpec.tapOn(_releaseKey);
    if (_run.selected == null) {
      final g = _geo;
      if (g == null) return null;
      return HintSpec.sweep([for (var i = 0; i < 3; i++) Rect.fromCenter(center: g.tagAt(i), width: 52, height: 28)], space: HintSpace.scene);
    }
    return HintSpec.sweepOver([for (final s in j.steps) _stepKeys[s]!, _stopKey, if (crimpOn) _releaseKey]);
  }

  /// A new waiting state (resets the count of hints shown).
  String get _hintKey =>
      '${_run.index}|${_run.selected}|${_run.tested.length}|${_run.earthed.length}|${_run.die}|${_run.placed}|${_run.locked}|${_run.hand}|${_run.clicked}|$_tray';

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.shown && !deckUp && !coworkerOpen && _card == null;
    final waiting = handsOn && !_run.done && !_ended && !_busy && !coworkerOnScreen && !tableBusy;
    final j = _run.current;
    final closeup = playing && _run.placed && !_run.shown && _card == null && !deckUp;
    final cardW = math.min(300.0, size.width - 32);
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
              labels: HydLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: waiting,
            hintKey: _hintKey,
            hintController: _hints,
            overlays: [
              if (playing && !_run.done && !coworkerOpen && !closeup)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(job: j)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 132), quiet: quiet),
              if (closeup)
                Positioned(
                  key: ValueKey('closeup-${_run.index}'),
                  left: (size.width - cardW) / 2,
                  width: cardW,
                  top: pad.top + 150,
                  child: _Closeup(
                    cutter: j.cut,
                    strokes: _run.strokes,
                    clicked: _run.clicked,
                    hand: _run.hand,
                    locked: _run.locked,
                    quiet: quiet,
                    zoneKeys: _zoneKeys,
                    releaseKey: _releaseKey,
                    onZone: (z, at) => _putHand(z, at),
                    onRelease: j.cut ? null : (at) => _release(at),
                  ),
                ),
              if (handsOn) ...[
                Positioned(
                  key: const ValueKey('hud-stop'),
                  left: 12,
                  width: math.min(210.0, size.width - 150),
                  bottom: pad.bottom + 94,
                  child: _StopButton(key: _stopKey, onTapUp: (d) => _stopJob(d.globalPosition)),
                ),
                Positioned(
                  key: ValueKey('hud-steps-${_run.index}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final s in j.steps)
                        _ToolButton(
                          key: _stepKeys[s],
                          icon: _stepIcon(s),
                          label: HydLines.stepBn(s, j.kind),
                          on: _stepOn(s),
                          enabled: _canPlay,
                          onTapUp: (d) => _step(s, d.globalPosition),
                        ),
                    ],
                  ),
                ),
              ],
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
              if (_tray && playing) _DieTray(key: const ValueKey('tray'), dies: j.dies, quiet: quiet, keyOf: _dieKey, onPick: _pickDie, onClose: _closeTray),
              if (playing && _card == null && !_tray) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 86), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
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
                  line: HydLines.intro,
                  alarm: 'sounds/learn/ring_steel.wav',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    _clock.start();
                    _startJob();
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 1, muted: _muted)),
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

  static IconData _stepIcon(HydStep s) => switch (s) {
        HydStep.test => Icons.bolt_rounded,
        HydStep.earth => Icons.link_rounded,
        HydStep.die => Icons.hexagon_outlined,
        HydStep.place => Icons.handyman_rounded,
        HydStep.lock => Icons.lock_rounded,
        HydStep.pump => Icons.compress_rounded,
      };
}

// ============================================================================
// Pieces
// ============================================================================

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.job});
  final HydJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8A7A55), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(HydLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(job.cut ? HydLines.jobCut : HydLines.jobCrimp, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
          Text('${job.tags[job.target]} · ${HydLines.sqmm(job.size)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF2B2416))),
        ],
      ),
    );
  }
}

/// The tester's display by a cable: LIVE (red, lit) or NO VOLTAGE.
class _Reading extends StatelessWidget {
  const _Reading({required this.live, required this.quiet});
  final bool live;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final colour = live ? const Color(0xFFE53935) : const Color(0xFF2E9D4A);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: 0.6 + 0.4 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 3, 7, 3),
        decoration: BoxDecoration(
          color: const Color(0xFF14181E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colour, width: 1.6),
          boxShadow: [if (live) BoxShadow(color: colour.withValues(alpha: 0.6), blurRadius: 8)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: live ? colour : const Color(0xFF3A3F46))),
            const SizedBox(width: 4),
            Text(live ? HydLines.live : HydLines.dead, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: colour)),
          ],
        ),
      ),
    );
  }
}

/// A flash of sparks (the earth lead on a live cable; the deadly hit).
class _Flash extends StatelessWidget {
  const _Flash({required this.quiet, this.big = false});
  final bool quiet;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: Duration(milliseconds: big ? 1500 : 700),
      builder: (_, v, _) => CustomPaint(painter: _FlashPainter(v: v, big: big)),
    );
  }
}

class _FlashPainter extends CustomPainter {
  const _FlashPainter({required this.v, required this.big});
  final double v;
  final bool big;

  @override
  void paint(Canvas c, Size size) {
    final at = size.center(Offset.zero);
    final r = size.width * (0.2 + 0.3 * Curves.easeOut.transform(v));
    final glow = big ? (1 - v * 0.6) : (1 - v);
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, glow.clamp(0.0, 1.0)), const Color(0x00FFC24A)])
              .createShader(Rect.fromCircle(center: at, radius: r)));
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v * 0.8).clamp(0.0, 1.0))
      ..strokeWidth = big ? 3 : 2
      ..strokeCap = StrokeCap.round;
    final n = big ? 16 : 10;
    for (var i = 0; i < n; i++) {
      final a = i / n * math.pi * 2 + 0.4;
      final d0 = size.width * (0.08 + 0.28 * v);
      final d1 = d0 + size.width * 0.12;
      c.drawLine(at + Offset(math.cos(a) * d0, math.sin(a) * d0), at + Offset(math.cos(a) * d1, math.sin(a) * d1), spark);
    }
  }

  @override
  bool shouldRepaint(_FlashPainter old) => old.v != v || old.big != big;
}

/// The close-up of the tool on the cable: tap where the free hand goes; for
/// the crimper, the let-go button under it. The jaws close with each stroke.
class _Closeup extends StatelessWidget {
  const _Closeup({
    required this.cutter,
    required this.strokes,
    required this.clicked,
    required this.hand,
    required this.locked,
    required this.quiet,
    required this.zoneKeys,
    required this.releaseKey,
    required this.onZone,
    required this.onRelease,
  });

  final bool cutter;
  final int strokes;
  final bool clicked;
  final HydZone? hand;
  final bool locked;
  final bool quiet;
  final Map<HydZone, GlobalKey> zoneKeys;
  final GlobalKey releaseKey;
  final void Function(HydZone z, Offset at) onZone;
  final ValueChanged<Offset>? onRelease;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xEEF1ECE0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF3A4660), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 5))],
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 300 / 170,
            child: LayoutBuilder(
              builder: (context, box) {
                final k = box.maxWidth / 300;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: strokes / kHydStrokes),
                        duration: Duration(milliseconds: quiet ? 1 : 220),
                        builder: (_, v, _) => CustomPaint(painter: HydCloseupPainter(cutter: cutter, closing: v, done: false, hand: hand, locked: locked)),
                      ),
                    ),
                    for (final z in HydZone.values)
                      Positioned(
                        key: ValueKey('zone-${z.name}'),
                        left: hydZoneRect(z).left * k,
                        top: hydZoneRect(z).top * k,
                        width: hydZoneRect(z).width * k,
                        height: hydZoneRect(z).height * k,
                        child: Semantics(
                          key: zoneKeys[z],
                          label: HydLines.zoneBn(z),
                          button: true,
                          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => onZone(z, d.globalPosition)),
                        ),
                      ),
                    if (clicked)
                      Positioned(
                        key: const ValueKey('click-word'),
                        left: 120 * k,
                        top: 40 * k,
                        child: IgnorePointer(child: _ClickWord(quiet: quiet)),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        if (onRelease != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            key: releaseKey,
            width: 150,
            child: DoBigButton(label: HydLines.release, filled: false, onDark: true, onTapUp: (d) => onRelease!(d.globalPosition)),
          ),
        ],
      ],
    );
  }
}

class _ClickWord extends StatelessWidget {
  const _ClickWord({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: 0.5 + 0.5 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Text(HydLines.click,
          style: bangla(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF1F5F8F))
              .copyWith(shadows: const [Shadow(color: Color(0x66FFFFFF), blurRadius: 4)])),
    );
  }
}

/// The die tray: the dies, each stamped with its size. Tap outside to close.
class _DieTray extends StatelessWidget {
  const _DieTray({super.key, required this.dies, required this.quiet, required this.keyOf, required this.onPick, required this.onClose});
  final List<int> dies;
  final bool quiet;
  final GlobalKey Function(int size) keyOf;
  final void Function(int size, Offset at) onPick;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Semantics(
        label: HydLines.close,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: ColoredBox(
            color: const Color(0x66050A16),
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: quiet ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                builder: (_, v, child) => Transform.translate(offset: Offset(0, 60 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B2A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF7A5A39), width: 3),
                    boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, 8))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(HydLines.die, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final d in dies)
                            Semantics(
                              key: keyOf(d),
                              label: HydLines.dieOf(d),
                              button: true,
                              excludeSemantics: true,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapUp: (t) => onPick(d, t.globalPosition),
                                child: _DieChip(size: d),
                              ),
                            ),
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

class _DieChip extends StatelessWidget {
  const _DieChip({required this.size});
  final int size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFDCE1E6), Color(0xFF8E979F)]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4A535C), width: 1.6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hexagon_outlined, size: 22, color: Color(0xFF30363C)),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(HydLines.sqmm(size), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E2328))),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({super.key, required this.onTapUp});
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE60B1324),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: () {},
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.warning.withValues(alpha: 0.9), width: 1.8),
          ),
          child: Text(HydLines.stop, textAlign: TextAlign.center, style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
        ),
      ),
    );
  }
}

/// A step on the tool row: a round icon with its name under it; lit once done.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.enabled, required this.onTapUp});
  final IconData icon;
  final String label;
  final bool on;
  final bool enabled;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: enabled ? onTapUp : null,
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
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
