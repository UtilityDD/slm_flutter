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
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm4_streetlight_find_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 4.9 "রাস্তার আলো (Street Light) মেরামত", কাজ 1 "অন্ধকার রাস্তা —
// দোষ কোথায়?" (pack do_4_9_a, engineType m4_streetlight_find). Three dark
// street lights a play, on a street where the other lights burn. Each has one
// fault — no supply at the light, a dead lamp, or a dead ballast — dealt in
// any order. The trainee finds it the lesson's way and puts it right safely.
//
// The lesson's rules, and only those:
//   • point 1 (problem 1, the light does not burn): step 1 — check with a
//     multimeter that there is voltage at the light's terminals; none = the
//     fault is in the supply line or the fuse. Step 2 — voltage there: change
//     the lamp (the commonest fix). Step 3 — still dark: the control gear
//     (ignitor or ballast);
//   • point 2 + myth 1: before working on the light, switch off that light's
//     fuse / MCB and make sure with a tester or multimeter that there is no
//     voltage at the fixture — the contacts inside the holder are live; work
//     on a live fitting is deadly;
//   • myth 2: every lamp (e.g. 70W HPSV, 150W MH) needs a ballast of its own
//     wattage and type — the wrong one: the lamp will not burn or soon fails;
//   • point 0: HPSV gives yellow light, MH white; the gear = ballast, ignitor,
//     capacitor; the photocell on top. Engineering facts: a discharge lamp
//     takes a moment to reach full light (the warm-up glow).
// Not used (flagged in REGISTER.md): the supply voltage figure 230 V (the
// course's household supply, lesson 4.9 gives no figure); where the light's
// MCB sits (a box on the pole here); LED drivers, the photocell's faults
// (day-burning) and cycling lamps (left for another কাজ).
//
// Hands on: মাল্টিমিটার (tap the terminal block: with the MCB ON it reads the
// supply, 230 V or 0 V; with it OFF it proves the fitting dead) · the MCB on
// the pole (ON/OFF) · নতুন ল্যাম্প (tap the lamp) · ব্যালাস্ট (tap the gear
// box, then pick the one that matches the lamp's rating on the fitting).
//
// Deadly: a new lamp or ballast into the fitting with the MCB ON (also by
// listening to the coworker, "লাইন বন্ধ না করেই ল্যাম্পটা খুলে দেখো!").
// Slips: misreading the meter, working on the fitting before the step-1
// supply test, without proving it dead, changing the ballast before a new
// lamp has been tried, the wrong ballast. Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m4_streetlight_find_world.dart), corner guide, ◆ on the table →
// "কেন …?" → the next light by itself; the careless coworker once a play, on a
// light with supply, after the reading. The praise window takes no input
// ([ReasonTable.tableBusy]); switching the MCB OFF on his light before he
// came waits for him ([CoworkerMoment.holdForCoworker]) — his push ("no need
// to switch off") only fits while the MCB is ON and the old lamp is in. The
// tool row is never laid out in the lesson's order (meter → lamp → ballast).
// Idle hands get a gesture hint: a sweep over the tools and the MCB, over the
// fitting's parts with a tool in hand, or over the two answers — never the
// answer itself. Voice: the guide by device TTS; the coworker's new push is
// silent with its caption held until recorded (his exit line is his existing
// recorded clip).
//
// Listening to the coworker is deadly here, not the playbook's slip: the act
// he pushes (a lamp out of a live fitting) is this level's own deadly
// (MODULE4_LADDER step 26 lists both) — owner to confirm.

// ============================================================================
// Content
// ============================================================================

/// The one fault in a dark light.
enum M4StreetlightFindFault { noSupply, lamp, gear }

/// What the reason question asks about.
enum M4StreetlightFindWhy { supply, lamp, gear, ballast, isolate }

/// The hands-on tools.
enum M4StreetlightFindTool { none, meter, lamp, gear }

/// What the multimeter on the terminal block did.
enum M4StreetlightFindProbe { none, reading, dead, live }

/// The lesson's order of the tools (step 1 → 2 → 3): the tool row is never
/// laid out like this.
const m4StreetlightFindToolSteps = [M4StreetlightFindTool.meter, M4StreetlightFindTool.lamp, M4StreetlightFindTool.gear];

/// The tool row for a play: shuffled, never in the lesson's order.
List<M4StreetlightFindTool> m4StreetlightFindToolRow(math.Random rng) {
  final row = [...m4StreetlightFindToolSteps];
  do {
    row.shuffle(rng);
  } while (_inStepOrder(row));
  return row;
}

bool _inStepOrder(List<M4StreetlightFindTool> row) {
  for (var i = 0; i < row.length; i++) {
    if (row[i] != m4StreetlightFindToolSteps[i]) return false;
  }
  return true;
}

@immutable
class M4StreetlightFindPost {
  const M4StreetlightFindPost({required this.id, required this.fault, required this.lamp, required this.why, required this.pole, this.matchFirst = true});
  final String id;
  final M4StreetlightFindFault fault;
  final M4StreetlightFindLamp lamp;
  final M4StreetlightFindWhy why;

  /// The pole number on the docket.
  final int pole;

  /// The matching ballast is the first of the two offered.
  final bool matchFirst;
}

abstract final class M4StreetlightFindLines {
  static const title = 'অন্ধকার রাস্তা — দোষ কোথায়?';
  static const intro = 'রাস্তার আলো নিভে আছে! ধাপে ধাপে দোষ খুঁজুন — আর হাত দেওয়ার আগে লাইন বন্ধ।';
  static const rounds = ['ক', 'খ', 'গ'];

  // The guide's task now (tap him: the same task, a different way).
  static const askMeasure = 'আগে দেখুন — লাইটে সাপ্লাই আসছে কি না।';
  static const askRead = 'মিটার কী বলছে?';
  static const askFix = 'সাপ্লাই আছে। এবার দোষটা সারান — নিরাপদে।';
  static const askNext = 'এবার কী করবেন?';
  static const askGear = 'নতুন ল্যাম্পেও আলো নেই। এবার?';
  static const askPick = 'কোন ব্যালাস্টটা লাগবে?';
  static const tasks = [askMeasure, askRead, askFix, askNext, askGear, askPick];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (tools, the docket, the meter).
  static const sceneLabel = 'রাস্তার আলোর খুঁটি';
  static const meter = 'মাল্টিমিটার';
  static const newLamp = 'নতুন ল্যাম্প';
  static const ballast = 'ব্যালাস্ট';
  static const sayLive = 'ভোল্টেজ আছে';
  static const sayDead = 'ভোল্টেজ নেই';
  static String gearPick(M4StreetlightFindLamp l) => 'ব্যালাস্ট ${m4StreetlightFindRating(l)}';
  static const docket = 'ডকেট';
  static String docketLine(int pole) => 'খুঁটি $pole · রাতে আলো জ্বলছে না';
  static const stampLit = 'আলো জ্বলেছে';
  static const stampSupply = 'সাপ্লাই / ফিউজ';
  static const supplyFound = 'ভোল্টেজ নেই — দোষ সাপ্লাই লাইন বা ফিউজে, ল্যাম্পে নয়।';

  // The reasons (lesson 4.9): the right ones fit this light and what was
  // done; the wrong ones are the lesson's myths and field excuses — never a
  // true rule marked wrong. Every card 42–52 letters.
  static const whySupplyQ = 'কেন ল্যাম্প না বদলে সাপ্লাই-ফিউজ ধরলেন?';
  static const whyLampQ = 'কেন আগে ল্যাম্পটাই বদলে দেখলেন?';
  static const whyGearQ = 'কেন শেষে ব্যালাস্ট বদলালেন?';
  static const whyBallastQ = 'কেন এই ব্যালাস্টটাই নিলেন?';
  static const whyIsolateQ = 'কেন হাত দেওয়ার আগে MCB বন্ধ করে মাপলেন?';
  static const supplyWhy = ['টার্মিনালে ভোল্টেজ নেই, তাই দোষ সাপ্লাই বা ফিউজে', 'ভোল্টেজই না এলে নতুন ল্যাম্পেও আলো জ্বলবে না'];
  static const lampWhy = ['ভোল্টেজ ঠিক থাকলে ল্যাম্প বদলই সবচেয়ে সাধারণ সমাধান', 'সাপ্লাই ঠিক পেলাম, তাই পরের ধাপ ল্যাম্প বদলে দেখা'];
  static const gearWhy = ['নতুন ল্যাম্পেও না জ্বললে দোষ কন্ট্রোল গিয়ারে', 'সাপ্লাই আর ল্যাম্প ঠিক, বাকি থাকে ব্যালাস্ট-ইগনিটর'];
  static const ballastWhy = ['ল্যাম্পের ওয়াট আর ধরন মিলিয়েই ব্যালাস্ট লাগে', 'ভুল ব্যালাস্টে ল্যাম্প জ্বলে না, বা দ্রুত নষ্ট হয়'];
  static const isolateWhy = ['হোল্ডারের ভেতরের পিন লাইভ থাকে, তাই আগে বন্ধ', 'MCB বন্ধ, মিটারে ভোল্টেজ নেই — তবেই ফিটিংয়ে হাত'];
  static const myths = [
    'সাবধানে করলে চালু লাইনেও ল্যাম্প বদলানো যায়',
    'যেকোনো ব্যালাস্ট যেকোনো ল্যাম্পের সাথে চলে যায়',
    'অন্ধকার লাইটে আগে ব্যালাস্ট বদলালেই ঝামেলা শেষ',
    'মিটারে মাপার দরকার নেই, দেখেই দোষটা বোঝা যায়',
    'ভোল্টেজ না থাকলেও নতুন ল্যাম্প ঠিক জ্বলে উঠবে',
    'লোকজন তাড়া দিচ্ছে, তাই মাপজোখ ছাড়াই সারলাম',
    'যত বেশি ওয়াটের ব্যালাস্ট, তত বেশি আলো হয়',
  ];
  static const allRight = [...supplyWhy, ...lampWhy, ...gearWhy, ...ballastWhy, ...isolateWhy];

  static List<String> whyRight(M4StreetlightFindPost p) => switch (p.why) {
        M4StreetlightFindWhy.supply => supplyWhy,
        M4StreetlightFindWhy.lamp => lampWhy,
        M4StreetlightFindWhy.gear => gearWhy,
        M4StreetlightFindWhy.ballast => ballastWhy,
        M4StreetlightFindWhy.isolate => isolateWhy,
      };
  static String whyQuestion(M4StreetlightFindPost p) => switch (p.why) {
        M4StreetlightFindWhy.supply => whySupplyQ,
        M4StreetlightFindWhy.lamp => whyLampQ,
        M4StreetlightFindWhy.gear => whyGearQ,
        M4StreetlightFindWhy.ballast => whyBallastQ,
        M4StreetlightFindWhy.isolate => whyIsolateQ,
      };

  /// The careless coworker: open the lamp live.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'লাইন বন্ধ না করেই ল্যাম্পটা খুলে দেখো! MCB নামানোর ঝামেলা কে করে?',
    exitLine: coworkerExit,
    right: ['না, আগে MCB বন্ধ করে মেপে তবে ল্যাম্প', 'না, হোল্ডারের পিন লাইভ, আগে বন্ধ করি', 'না, বন্ধ করে ভোল্টেজ নেই দেখে তবে কাজ'],
    wrong: [
      'ঠিক, চালু রেখেই ল্যাম্পটা খুলে দেখি',
      'আচ্ছা, খুব সাবধানে চালুতেই খুলি',
      'MCB নামানোর ঝামেলা না করেই খুলি',
      'ঠিক আছে, এক মিনিটের কাজ, চালুতেই',
      'হ্যাঁ, শুধু ল্যাম্প তো, বন্ধ লাগবে না',
    ],
    asks: ['ও বলছে চালু রেখেই ল্যাম্প খুলতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'চালু ফিটিংয়ে হাত দেবেন?'],
  );

  static const callHeld = 'ঠিক! চালু ফিটিংয়ে কখনো হাত নয়।';
  static const allSet = 'রাস্তা আলোয় ফিরল — ধাপে ধাপে দোষ খুঁজে, লাইন বন্ধ করে।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে মাপুন, তারপর বন্ধ করে মেরামত।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtMeasure = 'আগে টার্মিনালে ভোল্টেজ মেপেছেন';
  static const caughtSupply = 'ভোল্টেজ নেই — দোষ সাপ্লাই বা ফিউজে';
  static const caughtIsolate = 'MCB বন্ধ, মেপে মৃত — তবে হাত';
  static const caughtLamp = 'আগে ল্যাম্প বদলে দেখেছেন';
  static const caughtGear = 'মিলিয়ে ঠিক ব্যালাস্ট';
  static const caughtCall = 'চালু লাইনে “না” বলেছেন';
}

abstract final class M4StreetlightFindMistakes {
  static const _dir = 'assets/game/art/m4_streetlight_find';

  static const liveWork = DoMistake(
    key: '4.9/m4_streetlight_find/live-work',
    textBn: 'চালু লাইনে ফিটিংয়ে হাত নয়! হোল্ডারের ভেতরের পিন লাইভ থাকে — আগে MCB বা ফিউজ বন্ধ, মিটারে ভোল্টেজ নেই দেখে তবে কাজ।',
    art: '$_dir/live_work.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const noProve = DoMistake(
    key: '4.9/m4_streetlight_find/not-proven-dead',
    textBn: 'MCB নামালেই হলো না — টেস্টার বা মাল্টিমিটারে দেখে নিন ফিক্সচারে সত্যিই ভোল্টেজ নেই, তবেই হাত।',
    art: '$_dir/prove_dead.svg',
    lessonPoint: 2,
  );
  static const noMeasure = DoMistake(
    key: '4.9/m4_streetlight_find/no-supply-test',
    textBn: 'আগে ধাপ 1: লাইটের টার্মিনালে মাল্টিমিটারে ভোল্টেজ মাপুন। ভোল্টেজ না থাকলে দোষ সাপ্লাই লাইন বা ফিউজে — ল্যাম্পে নয়।',
    art: '$_dir/measure_first.svg',
    lessonPoint: 1,
  );
  static const misread = DoMistake(
    key: '4.9/m4_streetlight_find/misread',
    textBn: 'মিটার ভুল পড়লেন। ডিসপ্লেতে যা লেখা, সেটাই টার্মিনালের ভোল্টেজ — 0 মানে লাইটে সাপ্লাই আসছে না।',
    art: '$_dir/meter_read.svg',
    lessonPoint: 1,
  );
  static const gearFirst = DoMistake(
    key: '4.9/m4_streetlight_find/gear-before-lamp',
    textBn: 'আগে নতুন ল্যাম্প লাগিয়ে চালু করে দেখুন — সেটাই সবচেয়ে সাধারণ সমাধান। তাতেও না জ্বললে তবে ব্যালাস্ট-ইগনিটর।',
    art: '$_dir/gear_order.svg',
    lessonPoint: 1,
  );
  static const wrongBallast = DoMistake(
    key: '4.9/m4_streetlight_find/wrong-ballast',
    textBn: 'ল্যাম্পের ওয়াট আর ধরন মিলিয়ে ব্যালাস্ট লাগান — ভুল ব্যালাস্টে ল্যাম্প জ্বলবে না, বা তাড়াতাড়ি নষ্ট হবে।',
    art: '$_dir/ballast_match.svg',
    lessonPoint: 0,
  );

  static List<DoMistake> get all => const [liveWork, noProve, noMeasure, misread, gearFirst, wrongBallast];
}

@immutable
class M4StreetlightFindDeal {
  const M4StreetlightFindDeal({required this.posts, required this.callAt, this.tools = const [M4StreetlightFindTool.lamp, M4StreetlightFindTool.gear, M4StreetlightFindTool.meter]});
  final List<M4StreetlightFindPost> posts;

  /// The light the careless coworker comes to (one with supply).
  final int callAt;

  /// The tool row, left to right (never the lesson's order).
  final List<M4StreetlightFindTool> tools;
}

/// Three dark lights: one with no supply, one with a dead lamp, one with a
/// dead ballast (any order), so changing the lamp everywhere cannot win; one
/// of the two repairs asks why the line went off first; lamps and pole
/// numbers vary; the tool row is shuffled (never meter → lamp → ballast).
M4StreetlightFindDeal m4StreetlightFindDeal(math.Random rng) {
  final faults = [...M4StreetlightFindFault.values]..shuffle(rng);
  final isolateOnLamp = rng.nextBool();
  final base = 10 + rng.nextInt(30);
  final posts = <M4StreetlightFindPost>[
    for (final (i, f) in faults.indexed)
      M4StreetlightFindPost(
        id: 'l$i',
        fault: f,
        lamp: rng.nextBool() ? M4StreetlightFindLamp.hpsv70 : M4StreetlightFindLamp.mh150,
        pole: base + i * (2 + rng.nextInt(3)),
        matchFirst: rng.nextBool(),
        why: switch (f) {
          M4StreetlightFindFault.noSupply => M4StreetlightFindWhy.supply,
          M4StreetlightFindFault.lamp => isolateOnLamp ? M4StreetlightFindWhy.isolate : M4StreetlightFindWhy.lamp,
          M4StreetlightFindFault.gear => isolateOnLamp
              ? (rng.nextBool() ? M4StreetlightFindWhy.gear : M4StreetlightFindWhy.ballast)
              : M4StreetlightFindWhy.isolate,
        },
      ),
  ];
  final fixes = [
    for (final (i, p) in posts.indexed)
      if (p.fault != M4StreetlightFindFault.noSupply) i,
  ];
  return M4StreetlightFindDeal(posts: posts, callAt: fixes[rng.nextInt(fixes.length)], tools: m4StreetlightFindToolRow(rng));
}

/// The play state (pure logic).
class M4StreetlightFindRun {
  M4StreetlightFindRun(this.deal);
  final M4StreetlightFindDeal deal;
  int index = 0;
  int slips = 0;
  int postSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  // --- this light ---
  var mcbOn = true;
  var proved = false;
  var measured = false;
  var readingUp = false;
  var relamped = false;

  /// Switched back ON after the new lamp went in (so it has been tried).
  var tried = false;
  var choosingGear = false;
  var gearDone = false;
  var lit = false;
  var diagnosed = false;
  M4StreetlightFindTool tool = M4StreetlightFindTool.none;

  bool get done => index >= deal.posts.length;
  bool get ended => done || deadly != null;
  M4StreetlightFindPost get post => deal.posts[index.clamp(0, deal.posts.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// The supply reaches the light's terminals (with the MCB ON).
  bool get supply => post.fault != M4StreetlightFindFault.noSupply;

  /// What the multimeter reads at the terminals now.
  int get volts => mcbOn && supply ? 230 : 0;

  /// This light is found (no supply) or burning again.
  bool get finished => lit || diagnosed;

  /// Done this light without a slip (+5 on the table).
  bool get thorough => postSlips == 0;

  bool get _open => !ended && !finished;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    postSlips++;
    return m;
  }

  /// Picks up [t] (or puts it down, if held).
  void hold(M4StreetlightFindTool t) {
    if (!_open || readingUp || choosingGear) return;
    tool = tool == t ? M4StreetlightFindTool.none : t;
  }

  /// The tool in hand on the terminal block.
  M4StreetlightFindProbe tapTerminals() {
    if (!_open || readingUp || choosingGear || tool != M4StreetlightFindTool.meter) return M4StreetlightFindProbe.none;
    if (!mcbOn) {
      proved = true;
      return M4StreetlightFindProbe.dead;
    }
    if (!measured) {
      readingUp = true;
      return M4StreetlightFindProbe.reading;
    }
    return M4StreetlightFindProbe.live;
  }

  /// Reads the meter: [sayLive] = "ভোল্টেজ আছে".
  DoMistake? answer(bool sayLive) {
    if (!_open || !readingUp) return null;
    if (sayLive != supply) return _slip(M4StreetlightFindMistakes.misread);
    readingUp = false;
    measured = true;
    tool = M4StreetlightFindTool.none;
    _tag(M4StreetlightFindLines.caughtMeasure);
    if (!supply) {
      diagnosed = true;
      _tag(M4StreetlightFindLines.caughtSupply);
    }
    return null;
  }

  /// Hands in the fitting: ON = deadly; not proven dead; no step-1 test yet.
  DoMistake? _guard() {
    if (mcbOn) return deadly = M4StreetlightFindMistakes.liveWork;
    if (!proved) return _slip(M4StreetlightFindMistakes.noProve);
    if (!measured) return _slip(M4StreetlightFindMistakes.noMeasure);
    return null;
  }

  /// The tool in hand on the lamp.
  DoMistake? tapLamp() {
    if (!_open || readingUp || choosingGear || tool != M4StreetlightFindTool.lamp) return null;
    final m = _guard();
    if (m != null || relamped) return m;
    relamped = true;
    tool = M4StreetlightFindTool.none;
    _tag(M4StreetlightFindLines.caughtIsolate);
    _tag(M4StreetlightFindLines.caughtLamp);
    return null;
  }

  /// The tool in hand on the gear box: the choice of ballast comes up.
  DoMistake? tapGear() {
    if (!_open || readingUp || choosingGear || tool != M4StreetlightFindTool.gear) return null;
    final m = _guard();
    if (m != null) return m;
    if (!(relamped && tried)) return _slip(M4StreetlightFindMistakes.gearFirst);
    if (gearDone) return null;
    choosingGear = true;
    return null;
  }

  /// Picks a ballast: [match] = the one rated like the lamp.
  DoMistake? pickGear(bool match) {
    if (!_open || !choosingGear) return null;
    if (!match) return _slip(M4StreetlightFindMistakes.wrongBallast);
    choosingGear = false;
    gearDone = true;
    tool = M4StreetlightFindTool.none;
    _tag(M4StreetlightFindLines.caughtIsolate);
    _tag(M4StreetlightFindLines.caughtGear);
    return null;
  }

  /// The MCB's toggle. False = it did not move now.
  bool toggleMcb() {
    if (!_open || readingUp || choosingGear) return false;
    mcbOn = !mcbOn;
    if (mcbOn) {
      proved = false;
      if (relamped) tried = true;
      lit = supply && (post.fault != M4StreetlightFindFault.lamp || relamped) && (post.fault != M4StreetlightFindFault.gear || gearDone);
    } else {
      lit = false;
    }
    return true;
  }

  /// The new lamp is in and tried, and the light is still dark.
  bool get stillDark => relamped && tried && !gearDone;

  /// Fails the play (listening to the coworker).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    postSlips = 0;
    mcbOn = true;
    proved = false;
    measured = false;
    readingUp = false;
    relamped = false;
    tried = false;
    choosingGear = false;
    gearDone = false;
    lit = false;
    diagnosed = false;
    tool = M4StreetlightFindTool.none;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   no supply: meter, tap, read ~2000 + answer, reason ~8200     ≈ 14000
///   dead lamp: the test ≈ 5500, OFF, meter, tap ~2200, lamp tool,
///     tap, ON + the warm-up ~2500, reason ~8200                  ≈ 24000
///   dead ballast: as the lamp ≈ 15800, OFF, meter, tap, ballast,
///     tap, pick ≈ 9200, ON + warm-up ~2500, reason ~8200         ≈ 35700
/// + the coworker once ≈ 9600                                     ≈ 83300
/// 85 % ≈ 70800 → 70 s.
const kM4StreetlightFindQuickMs = 70000;

@immutable
class M4StreetlightFindPack {
  const M4StreetlightFindPack({required this.id, required this.titleBn, this.quickMs = kM4StreetlightFindQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M4StreetlightFindPack> m4StreetlightFindPacks = {
  'do_4_9_a': M4StreetlightFindPack(id: 'do_4_9_a', titleBn: M4StreetlightFindLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M4StreetlightFindPage extends StatefulWidget {
  const M4StreetlightFindPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M4StreetlightFindPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4StreetlightFindPage> createState() => _M4StreetlightFindPageState();
}

class _M4StreetlightFindPageState extends State<M4StreetlightFindPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _RunPage(
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

class _RunPage extends ConsumerStatefulWidget {
  const _RunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4StreetlightFindPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_RunPage> createState() => _RunPageState();
}

class _RunPageState extends ConsumerState<_RunPage> with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4StreetlightFindRun _run = M4StreetlightFindRun(m4StreetlightFindDeal(widget.rng));
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
  var _coworkerArmed = false;

  /// The multimeter's reading for a moment after a check (not the step-1 read).
  int? _flash;
  Timer? _flashTimer;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // Gesture hints: the scene's touch layer (design → screen) and the buttons.
  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  final _toolKeys = {for (final t in m4StreetlightFindToolSteps) t: GlobalKey()};
  final _readKeys = [GlobalKey(), GlobalKey()];
  final _gearKeys = [GlobalKey(), GlobalKey()];
  M4StreetlightFindGeo? _geo;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _flashTimer?.cancel();
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

  Future<void> _start() async {
    _clock.start();
    _startPost();
  }

  bool get _canPlay => !_intro && !_ended && _card == null && !tableBusy && !coworkerOpen && !_run.finished && !_freeze;

  String get _task {
    if (_run.readingUp) return M4StreetlightFindLines.askRead;
    if (_run.choosingGear) return M4StreetlightFindLines.askPick;
    if (!_run.measured) return M4StreetlightFindLines.askMeasure;
    if (_run.stillDark) return M4StreetlightFindLines.askGear;
    if (_run.relamped) return M4StreetlightFindLines.askNext;
    return M4StreetlightFindLines.askFix;
  }

  void _startPost() {
    _flashTimer?.cancel();
    setState(() {
      _flash = null;
      _wake++;
    });
    unawaited(_sayChain([M4StreetlightFindLines.askMeasure]));
  }

  // --- hands on -----------------------------------------------------------------
  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  void _hold(M4StreetlightFindTool t) {
    if (!_canPlay || _run.readingUp || _run.choosingGear) return;
    _tick('sounds/quiz_select.ogg');
    setState(() {
      _run.hold(t);
      _wake++;
    });
  }

  void _showFlash(int volts) {
    _flashTimer?.cancel();
    setState(() {
      _flash = volts;
      _wake++;
    });
    _flashTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  void _toggleMcb() {
    if (_run.toggleMcb()) {
      _tick('sounds/intro/impact_metal.ogg', 0.6);
    } else {
      _tick('sounds/intro/click.ogg', 0.3);
    }
    _flashTimer?.cancel();
    setState(() {
      _flash = null;
      _wake++;
    });
  }

  void _tapScene(Offset p, M4StreetlightFindGeo geo, Offset global) {
    if (_intro || _ended || _card != null || tableBusy || _freeze || _run.finished) return;
    // While he talks, only the MCB answers him (going OFF refuses him).
    if (coworkerOpen) {
      if (coworkerChoiceUp && geo.mcbHit.contains(p) && _run.mcbOn && _run.toggleMcb()) {
        _tick('sounds/intro/impact_metal.ogg', 0.6);
        setState(() => _wake++);
        unawaited(answerCoworker(true, global, direct: true));
      }
      return;
    }
    if (_run.readingUp || _run.choosingGear) {
      _hints.missTap();
      return;
    }
    if (geo.mcbHit.contains(p)) {
      // Switching OFF ends his moment ("no need to switch off"): on his light
      // a fast OFF waits for him; he cuts in now.
      if (_run.mcbOn && holdForCoworker()) {
        setState(() => _wake++);
        return;
      }
      _toggleMcb();
      if (_run.lit) {
        unawaited(_postDone());
      } else if (_run.mcbOn && _run.stillDark) {
        unawaited(_sayChain([M4StreetlightFindLines.askGear]));
      }
      return;
    }
    if (geo.terminalHit.contains(p) && _run.tool == M4StreetlightFindTool.meter) {
      _tick();
      switch (_run.tapTerminals()) {
        case M4StreetlightFindProbe.none:
          return;
        case M4StreetlightFindProbe.reading:
          setState(() => _wake++);
          _cue('sounds/learn/card_deal_a.ogg', volume: 0.5);
          unawaited(_sayChain([M4StreetlightFindLines.askRead]));
        case M4StreetlightFindProbe.dead:
        case M4StreetlightFindProbe.live:
          _showFlash(_run.volts);
      }
      return;
    }
    if (geo.lampHit.contains(p) && _run.tool == M4StreetlightFindTool.lamp) {
      _tick('sounds/intro/click.ogg', 0.6);
      final m = _run.tapLamp();
      setState(() => _wake++);
      if (m != null) {
        unawaited(_mistake(m, global));
      } else if (_run.relamped) {
        _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
        unawaited(_sayChain([M4StreetlightFindLines.askNext]));
      }
      return;
    }
    if (geo.gearHit.contains(p) && _run.tool == M4StreetlightFindTool.gear) {
      _tick('sounds/intro/click.ogg', 0.6);
      final m = _run.tapGear();
      setState(() => _wake++);
      if (m != null) {
        unawaited(_mistake(m, global));
      } else if (_run.choosingGear) {
        _cue('sounds/learn/card_deal_a.ogg', volume: 0.5);
        unawaited(_sayChain([M4StreetlightFindLines.askPick]));
      }
      return;
    }
    // A tap on nothing (or a part with no tool for it in hand).
    _hints.missTap();
  }

  void _answer(bool sayLive, Offset origin) {
    if (!_canPlay || !_run.readingUp) return;
    _hush();
    final m = _run.answer(sayLive);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, origin));
      return;
    }
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.5);
    if (_run.diagnosed) {
      unawaited(_postDone());
      return;
    }
    if (!_coworkerArmed && _run.index == _run.deal.callAt) {
      _coworkerArmed = true;
      scheduleCoworker();
    }
    unawaited(_sayChain([_task]));
  }

  void _pickGear(bool match, Offset origin) {
    if (!_canPlay || !_run.choosingGear) return;
    _hush();
    final m = _run.pickGear(match);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, origin));
      return;
    }
    _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
    unawaited(_sayChain([M4StreetlightFindLines.askNext]));
  }

  Future<void> _postDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    final p = _run.post;
    final idx = _run.index;
    if (_run.diagnosed) await _say(M4StreetlightFindLines.supplyFound, mood: GuideMood.glad);
    if (!mounted || _ended || _run.index != idx) return;
    putOnTable(15 + (_run.thorough ? 5 : 0));
    unawaited(askReason(
      deal: () => dealChoices(M4StreetlightFindLines.whyRight(p), M4StreetlightFindLines.myths, widget.rng),
      question: M4StreetlightFindLines.whyQuestion(p),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startPost();
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
  CoworkerScript get coworkerScript => M4StreetlightFindLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // His push ("open the lamp without switching off") fits only while the
    // MCB is ON and the old lamp is still in, after the step-1 reading.
    if (_ended || _run.index != _run.deal.callAt || _run.relamped || _run.finished || !_run.mcbOn || !_run.measured) return null;
    if (tableBusy || _intro || _card != null || _run.readingUp || _run.choosingGear || _flash != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: the lamp comes out of a live holder.
      _run.failDeadly(M4StreetlightFindMistakes.liveWork);
      await _deadly(M4StreetlightFindMistakes.liveWork);
      return;
    }
    _run.caught.add(M4StreetlightFindLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M4StreetlightFindLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M4StreetlightFindLines.tapWhy[_nudgeN++ % M4StreetlightFindLines.tapWhy.length]
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
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('streetlight/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Hands in a live fitting: the street freezes grey and the flash comes
  /// off the holder in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _flashTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _flash = null;
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
    final speak = await SpokenOnce.first('streetlight/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M4StreetlightFindLines.deadlyWord : M4StreetlightFindLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same light goes on from where it was.
        _hush();
        setState(() {
          _card = null;
          _wake++;
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
    await _say(!_run.passed ? M4StreetlightFindLines.fail : (_quickBonus ? M4StreetlightFindLines.quick : M4StreetlightFindLines.allSet),
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
    if (_run.lit) return LinemanMode.cheer;
    if (_run.tool != M4StreetlightFindTool.none || _run.readingUp) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  /// The meter's face: the step-1 reading, or a check a moment after.
  int? get _meterVolts => _run.readingUp ? _run.volts : _flash;

  M4StreetlightFindPoleState get _pole => M4StreetlightFindPoleState(
        lamp: _run.post.lamp,
        mcbOn: _run.mcbOn,
        lit: _run.lit,
        newLamp: _run.relamped,
        newGear: _run.gearDone,
        probes: _meterVolts != null,
      );

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = M4StreetlightFindGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final pole = _pole;
    final seed = _run.index * 5 + 3;
    final volts = _meterVolts;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('street'),
                child: RepaintBoundary(
                  child: pole.lit
                      ? TweenAnimationBuilder<double>(
                          key: ValueKey('warm-${_run.index}'),
                          tween: Tween(begin: quiet ? 1 : 0.25, end: 1),
                          duration: const Duration(milliseconds: 1600),
                          curve: Curves.easeOut,
                          builder: (_, v, _) => CustomPaint(painter: M4StreetlightFindStreetPainter(geo: geo, pole: pole, seed: seed, warm: v)),
                        )
                      : CustomPaint(painter: M4StreetlightFindStreetPainter(geo: geo, pole: pole, seed: seed)),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      if (volts != null && !_freeze)
        Positioned.fromRect(
          key: const ValueKey('meter'),
          rect: geo.meterCard,
          child: IgnorePointer(child: _MeterCard(volts: volts, quiet: quiet)),
        ),
      if (_run.finished && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: 40,
          width: 170,
          top: geo.fitTop + 128,
          child: IgnorePointer(child: _StampPop(text: _run.lit ? M4StreetlightFindLines.stampLit : M4StreetlightFindLines.stampSupply, warn: !_run.lit, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4StreetlightFindLines.sceneLabel,
          child: GestureDetector(key: _touchKey, behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M4StreetlightFindArcPainter(geo: geo, v: v)),
            ),
          ),
        ),
      // The next light: a short fade from the last one.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('night-${_run.index}'),
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

  // --- gesture hints -----------------------------------------------------------
  /// A scene rect (design px) on the screen, through the touch layer.
  Rect? _sceneRect(Rect r) {
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return Rect.fromPoints(box.localToGlobal(r.topLeft), box.localToGlobal(r.bottomRight));
  }

  /// How to interact now, never what is right: the reading and the ballast
  /// sweep over both answers; empty hands sweep over the tools and the MCB;
  /// a tool in hand sweeps over every part of the fitting and the MCB.
  HintSpec? _hint() {
    if (_run.readingUp) return HintSpec.sweepOver(_readKeys);
    if (_run.choosingGear) return HintSpec.sweepOver(_gearKeys);
    final geo = _geo;
    if (geo == null) return null;
    final options = _run.tool == M4StreetlightFindTool.none
        ? [
            for (final t in _run.deal.tools) ?HintSpec.globalRectOf(_toolKeys[t]!),
            ?_sceneRect(geo.mcbHit),
          ]
        : [
            ?_sceneRect(geo.terminalHit),
            ?_sceneRect(geo.lampHit),
            ?_sceneRect(geo.gearHit),
            ?_sceneRect(geo.mcbHit),
          ];
    return options.isEmpty ? null : HintSpec.sweep(options);
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.finished && !deckUp && !coworkerOpen && _card == null && !tableBusy;
    final p = _run.post;
    final other = p.lamp == M4StreetlightFindLamp.hpsv70 ? M4StreetlightFindLamp.mh150 : M4StreetlightFindLamp.hpsv70;
    final gears = p.matchFirst ? [(p.lamp, true), (other, false)] : [(other, false), (p.lamp, true)];
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
              labels: M4StreetlightFindLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn,
            hintKey: '${_run.index}-${_run.tool.name}-${_run.readingUp}-${_run.choosingGear}-${_run.mcbOn}-${_run.measured}-${_run.relamped}',
            hintController: _hints,
            overlays: [
              if (playing && !_run.done && !coworkerOpen)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(pole: p.pole)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && _run.readingUp)
                Positioned(
                  key: const ValueKey('hud-read'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(child: DoBigButton(key: _readKeys[0], label: M4StreetlightFindLines.sayLive, filled: true, onTapUp: (d) => _answer(true, d.globalPosition))),
                      const SizedBox(width: 10),
                      Expanded(child: DoBigButton(key: _readKeys[1], label: M4StreetlightFindLines.sayDead, filled: true, onTapUp: (d) => _answer(false, d.globalPosition))),
                    ],
                  ),
                ),
              if (handsOn && _run.choosingGear)
                Positioned(
                  key: const ValueKey('hud-gear'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      for (final (i, (lamp, match)) in gears.indexed) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: DoBigButton(key: _gearKeys[i], label: M4StreetlightFindLines.gearPick(lamp), filled: true, onTapUp: (d) => _pickGear(match, d.globalPosition))),
                      ],
                    ],
                  ),
                ),
              if (handsOn && !_run.readingUp && !_run.choosingGear)
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Shuffled each play: never in the lesson's order.
                      for (final t in _run.deal.tools)
                        _ToolButton(
                          key: _toolKeys[t],
                          icon: switch (t) {
                            M4StreetlightFindTool.lamp => Icons.lightbulb_rounded,
                            M4StreetlightFindTool.gear => Icons.memory_rounded,
                            _ => Icons.speed_rounded,
                          },
                          label: switch (t) {
                            M4StreetlightFindTool.lamp => M4StreetlightFindLines.newLamp,
                            M4StreetlightFindTool.gear => M4StreetlightFindLines.ballast,
                            _ => M4StreetlightFindLines.meter,
                          },
                          on: _run.tool == t,
                          onTap: () => _hold(t),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: !coworkerOnScreen || coworkerFromRight),
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
                  line: M4StreetlightFindLines.intro,
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
}

// ============================================================================
// Pieces
// ============================================================================

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.pole});
  final int pole;

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
          Text(M4StreetlightFindLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(M4StreetlightFindLines.docketLine(pole), style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
        ],
      ),
    );
  }
}

/// The multimeter in his hand, its LCD big enough to read.
class _MeterCard extends StatelessWidget {
  const _MeterCard({required this.volts, required this.quiet});
  final int volts;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.translate(offset: Offset(0, 40 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: RepaintBoundary(
          child: Semantics(
            label: '$volts V',
            child: CustomPaint(painter: M4StreetlightFindMeterPainter(volts: volts)),
          ),
        ),
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit while in use.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 84,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
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
                child: Icon(icon, size: 25, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StampPop extends StatelessWidget {
  const _StampPop({required this.text, required this.warn, required this.quiet});
  final String text;
  final bool warn;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final col = warn ? const Color(0xFFD9822B) : SlmColors.success;
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
          border: Border.all(color: col, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: col)),
      ),
    );
  }
}
