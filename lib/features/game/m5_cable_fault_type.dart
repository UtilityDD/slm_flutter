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
import 'm5_cable_fault_type_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm5_cable_fault_type_world.dart' show M5Core, M5End, M5Pt, M5Tool;

// Lesson 5.9 "কেবিল ফল্ট খোঁজার প্রাথমিক ধারণা", কাজ 1 "কোর থেকে কোরে: ফল্টের
// ধরন" (pack do_5_9_a, engineType m5_cable_fault_type). An underground cable
// has tripped; before anyone digs, the trainee finds out what kind of fault it
// is. Three rounds:
//
//  1–2. Two cables, played the same way (round 2's cable has two faults in
//     about half the plays):
//     • বিচ্ছিন্ন: pan to both ends (the far end is a swipe away), switch any
//       end that is ON to OFF, hold the hasp shut, hang the tag. A switch that
//       is ON shows ON only in its own place.
//     • ডিসচার্জ: the discharge rod on each core.
//     • মাপা, in any order, nine tests: the megger between each pair of cores
//       (R–Y, Y–B, R–B) and from each core to the armour (L on the core, E on
//       the armour), the multimeter from each core's near end to its far end
//       (a beep, or none). Pick up an instrument, put its two leads on two
//       points (tap or drag); with the megger hold TEST; the reading goes into
//       the notebook as a raw row. After a megger test the cable holds a
//       charge: the rod on the clip first, then the clip comes off.
//     • রায়: the verdict sheet always offers every type and every core (short
//       R–Y / Y–B / R–B, earth R / Y / B, open R / Y / B). Evidence-gated
//       (ruling M5-10): a verdict before all nine tests is a slip even when it
//       is right. ◆ → reason.
//  3. পিট: the street from the substation to the far end, 3 or 5 identical
//     joint pits with uneven chainage. Open the pit nearest the middle,
//     discharge the faulted core of each section, megger it to the armour each
//     way, tap the half that reads low.
//     ◆ → reason.
//
// The lesson's rules (5.9 point 2 and pro tip 3), and only those:
//   • megger between two cores reads zero or very low → short circuit;
//   • megger between a core and the armour / earth reads very low → earth fault;
//   • multimeter continuity between a core's two ends gives no beep → the core
//     is cut inside (open circuit);
//   • find the type before going to the field; split a long cable at a joint
//     box in the middle and megger each section — it tells which half.
// From lesson 2.7 (the megger), not 5.9: isolate and discharge before the
// test; L on the conductor, E on the armour; hold TEST; the test leaves a
// charge — discharge before the leads come off. Readings, the nine-test rule,
// far-end access, pits and chainage are game data (spec "unsupported").
//
// Deadly (Module 5 table): a lead on a core while either end is ON (R23), and
// the earthed discharge rod on such a core (R23 with R2: a live core shorted
// to earth); lifting a megger clip after TEST without discharging (R24).
// Slips: a lead before the core is discharged (R25, in the pit too: each
// split section's core is discharged before its first lead); a lead, or the
// rod on the armour, before both ends are locked and tagged (all OFF); the multimeter on an insulation pair; the megger across
// one core's two ends; L and E swapped on core–armour; a verdict with tests
// missing; a wrong type, core or half a double fault; the wrong pit; the wrong
// half, or a half called before both sides were measured; listening to the
// coworker (R29). Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m5_cable_fault_type_world.dart), corner guide, ◆ on the table →
// "কেন …?" (the isolation in round 1, the first after-test discharge in round 2,
// each verdict, the pit); the careless coworker once a play (A1 before the
// first test — the first lead waits for him; or A2 on the first low megger
// reading, before its row is written — every control waits for him; A2 is
// dealt only in a round with a short or earth fault). Gesture
// hints: a swipe until the far end is seen, a tap on the switch, a hold ring
// after an early hasp release, a short lead drag once an instrument is up, a
// hold on TEST only after an early release, sweeps over equal choices; none
// after TEST (unclipping is the deadly test). Voice: the guide by device TTS;
// the coworker in his recorded voice (new lines listed for recording).

// ============================================================================
// Content
// ============================================================================

/// The play's rounds.
enum M5CableRound { cable1, cable2, pit }

/// The nine single faults.
enum M5Fault { shortRY, shortYB, shortRB, earthR, earthY, earthB, openR, openY, openB }

enum M5Kind { short, earth, open }

/// The nine tests.
enum M5Test { insRY, insYB, insRB, earthR, earthY, earthB, contR, contY, contB }

extension M5FaultX on M5Fault {
  M5Kind get kind => index < 3 ? M5Kind.short : (index < 6 ? M5Kind.earth : M5Kind.open);

  Set<M5Core> get cores => switch (this) {
        M5Fault.shortRY => {M5Core.r, M5Core.y},
        M5Fault.shortYB => {M5Core.y, M5Core.b},
        M5Fault.shortRB => {M5Core.r, M5Core.b},
        M5Fault.earthR || M5Fault.openR => {M5Core.r},
        M5Fault.earthY || M5Fault.openY => {M5Core.y},
        M5Fault.earthB || M5Fault.openB => {M5Core.b},
      };

  /// The test that shows it (low, or no beep).
  M5Test get test => M5Test.values[index];
}

extension M5TestX on M5Test {
  bool get megger => index < 6;

  /// The notebook's pair label (what the leads were on).
  String get label => switch (this) {
        M5Test.insRY => 'R–Y',
        M5Test.insYB => 'Y–B',
        M5Test.insRB => 'R–B',
        M5Test.earthR => 'R–E',
        M5Test.earthY => 'Y–E',
        M5Test.earthB => 'B–E',
        M5Test.contR => 'R–R′',
        M5Test.contY => 'Y–Y′',
        M5Test.contB => 'B–B′',
      };
}

M5Test m5InsTest(M5Core a, M5Core b) {
  final s = {a, b};
  if (s.containsAll({M5Core.r, M5Core.y})) return M5Test.insRY;
  if (s.containsAll({M5Core.y, M5Core.b})) return M5Test.insYB;
  return M5Test.insRB;
}

M5Test m5EarthTest(M5Core c) => M5Test.values[3 + c.index];
M5Test m5ContTest(M5Core c) => M5Test.values[6 + c.index];

/// The pairs that may be dealt together (round 2): no two faults on one core,
/// and never two earth faults (they would read low between the cores too).
bool m5DoubleOk(M5Fault a, M5Fault b) =>
    a != b && a.cores.intersection(b.cores).isEmpty && !(a.kind == M5Kind.earth && b.kind == M5Kind.earth);

abstract final class M5CableLines {
  static const title = 'কোর থেকে কোরে: ফল্টের ধরন';
  static const intro = 'ইউজি কেবিল ট্রিপ করেছে! খোঁড়ার আগে বলুন — কী ধরনের ফল্ট?';
  static const rounds = ['কেবিল 1', 'কেবিল 2', 'পিট'];

  // The guide's task now (tap him: the same task, a different way).
  static const askIsolate = 'পরীক্ষার আগে কেবিলটা নিরাপদ করুন।';
  static const askTest = 'মেপে দেখুন — ফল্টটা কী ধরনের?';
  static const askVerdict = 'রিডিং দেখে রায় দিন।';
  static const askPit = 'ফল্ট কোন অর্ধেকে? কেবিলটা ভাগ করে দেখুন।';
  static const askPitTest = 'দুই দিকেই মেপে দেখুন।';
  static const tasks = [askIsolate, askTest, askVerdict, askPit, askPitTest];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const cable2 = 'আরেকটা কেবিল ট্রিপ করেছে। এটারও ধরন বের করুন।';
  static const pitIntro = 'এই কেবিলে আর্থ ফল্ট পাওয়া গেছে। এবার খুঁজুন কোন অর্ধেকে।';

  // Labels a worker reads.
  static const sceneLabel = 'কেবিল রুম';
  static const megger = 'মেগার';
  static const multi = 'মাল্টিমিটার';
  static const rod = 'ডিসচার্জ রড';
  static const verdict = 'রায়';
  static const farEnd = 'দূর প্রান্ত';
  static const nearEnd = 'কাছের প্রান্ত';
  static const test = 'TEST';
  static const hasp = 'হ্যাস্প';
  static const submit = 'রায় দিন';
  static const back = 'আরও মাপি';
  static const notebook = 'খাতা';
  static const short = 'শর্ট';
  static const earth = 'আর্থ';
  static const open = 'ওপেন';
  static const beep = 'বিপ';
  static const leftHalf = 'বাঁ সেকশন';
  static const rightHalf = 'ডান সেকশন';
  static const lengthWord = 'দৈর্ঘ্য';

  static String toolLabel(M5Tool t) => switch (t) {
        M5Tool.megger => megger,
        M5Tool.multi => multi,
        M5Tool.rod => rod,
      };

  static String kindLabel(M5Kind k) => switch (k) {
        M5Kind.short => short,
        M5Kind.earth => earth,
        M5Kind.open => open,
      };

  /// A verdict chip: the type and the core(s).
  static String chipCores(M5Fault f) => switch (f) {
        M5Fault.shortRY => 'R–Y',
        M5Fault.shortYB => 'Y–B',
        M5Fault.shortRB => 'R–B',
        M5Fault.earthR || M5Fault.openR => 'R',
        M5Fault.earthY || M5Fault.openY => 'Y',
        M5Fault.earthB || M5Fault.openB => 'B',
      };
  static String chipLabel(M5Fault f) => '${kindLabel(f.kind)} ${chipCores(f)}';

  // Readings (game data, spec "unsupported": no kV shown). Healthy
  // insulation reads hundreds of MΩ or GΩ (2.7 point 3); a fault zero or very
  // low (5.9 point 2).
  static const meggerGood = ['850 MΩ', '1200 MΩ', '2.5 GΩ', '640 MΩ', '1.8 GΩ', '980 MΩ'];
  static const meggerLow = ['0 MΩ', '0.02 MΩ', '0.1 MΩ', '0.3 MΩ'];
  static const ohmBeep = ['0.4 Ω', '0.6 Ω', '0.3 Ω', '0.5 Ω'];
  static const ohmOpen = 'OL';

  // The reasons: the right ones fit what was just done; the wrong ones are
  // the lesson's myths and field excuses.
  static const isoWhyQ = 'পরীক্ষার আগে দুই প্রান্তের সুইচ কেন দেখলেন?';
  static const isoWhy = ['এক প্রান্ত চালু থাকলেই পুরো কেবিল লাইভ থাকে', 'দুই প্রান্ত বিচ্ছিন্ন না হলে লিড দেওয়া নিষেধ'];
  static const dischargeWhyQ = 'ক্লিপ খোলার আগে কেন আবার ডিসচার্জ?';
  static const dischargeWhy = ['মেগারের টেস্ট ভোল্টেজ কেবিলে চার্জ হয়ে থাকে', 'টেস্টের পর কেবিলে চার্জ জমে, আগে তা নামাই'];
  static const kindWhyQ = <M5Kind, String>{
    M5Kind.short: 'কেন এটা শর্ট সার্কিট?',
    M5Kind.earth: 'কেন এটা আর্থ ফল্ট?',
    M5Kind.open: 'কেন বলছেন কোরটা ভেতরে কাটা?',
  };
  static const kindWhy = <M5Kind, List<String>>{
    M5Kind.short: ['দুই কোরের মাঝে মেগারে শূন্য বা খুব কম রিডিং', 'দুটি কোরের মধ্যে মেগার রিডিং প্রায় শূন্য এল'],
    M5Kind.earth: ['কোর আর আর্মারের মাঝে মেগারে খুব কম রিডিং', 'একটা কোর থেকে আর্মারে মেগার রিডিং প্রায় শূন্য'],
    M5Kind.open: ['কোরের দুই প্রান্তের মাঝে মাল্টিমিটারে বিপ নেই', 'এক প্রান্ত থেকে অন্য প্রান্তে কন্টিনিউটি নেই'],
  };
  static const pitWhyQ = 'কেন মাঝের পিটেই কেবিল ভাগ করলেন?';
  static const pitWhy = ['মাঝে ভাগ করলে মেগার বলে দেয় ফল্ট কোন অর্ধেকে', 'দুই সেকশনে ভাগ করে মাপলে খোঁজার জায়গা অর্ধেক'];
  static const myths = [
    'ইউজি কেবিল মাটির নিচে, তাই এতে কোনো বিপদ নেই',
    'ওভারহেডের অভিজ্ঞতা থাকলেই এ কাজ পারা যায়',
    'মাল্টিমিটারে ইনফিনিটি মানেই ইনসুলেশন ভালো',
    'যেখানে খুশি খুঁড়লে একসময় ফল্ট পাওয়া যাবেই',
    'সময় বাঁচাতে একটা রিডিং দেখেই রায় দেওয়া যায়',
    'বন্ধ কেবিলে কারেন্ট থাকে না, ভয়ের কিছু নেই',
    'রিডিং যা-ই আসুক, শেষে খুঁড়ে তো দেখতেই হবে',
  ];
  static List<String> get allWhyRight => [...isoWhy, ...dischargeWhy, for (final l in kindWhy.values) ...l, ...pitWhy];

  /// The careless coworker: A1 before the first test, or A2 on the first low
  /// megger reading (never on a silent multimeter: OL is not "কম"). His exit
  /// line is his existing clip.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerA1 = CoworkerScript(
    line: 'টাইপ-ফাইপ জেনে কী হবে? চলো, সোজা মাঠে গিয়ে খুঁড়ি!',
    exitLine: coworkerExit,
    right: ['না, আগে মেপে ফল্টের ধরন জানব, তারপর মাঠে', 'না, ধরন না জেনে খুঁড়লে শুধু সময় নষ্ট হবে', 'না, মেগার-মাল্টিমিটারে আগে ধরন বের করি'],
    wrong: [
      'ঠিক, চলো আগে মাঠে গিয়ে খুঁড়েই দেখি',
      'আচ্ছা, ধরন পরে জানলেও চলবে, চলো যাই',
      'হ্যাঁ, খুঁড়লেই তো ফল্টটা চোখে পড়বে',
      'ঠিক আছে, মাপামাপি বাদ, সোজা মাঠে চলি',
      'হ্যাঁ, টাইপ জেনে কাজ নেই, খোঁড়া শুরু করি',
    ],
    asks: ['কী করবেন?', 'ধরন না জেনেই খুঁড়বেন?', 'ওর কথা শুনবেন, না আগে মাপবেন?'],
  );
  static const coworkerA2 = CoworkerScript(
    line: 'একটাতেই তো কম পেয়েছ — বাকি জোড়া মাপার দরকার নেই, রায় দিয়ে দাও!',
    exitLine: coworkerExit,
    right: ['না, সব জোড়া মেপে তবেই রায় দেব', 'না, এক রিডিংয়ে পুরো ছবি মেলে না', 'না, আরও ফল্ট থাকতে পারে, সব মাপব'],
    wrong: [
      'ঠিক, একটা কম পেলেই রায় দেওয়া যায়',
      'আচ্ছা, বাকি জোড়া মাপার দরকার নেই',
      'হ্যাঁ, এটুকুতেই বোঝা গেছে, রায় দিই',
      'ঠিক আছে, বাকি মাপামাপি বাদ দিয়ে দিই',
      'হ্যাঁ, এক রিডিংয়েই ফল্ট ধরা পড়েছে',
    ],
    asks: ['কী করবেন?', 'বাকি জোড়া না মেপেই রায় দেবেন?', 'ওর কথা শুনবেন, না সব মাপবেন?'],
  );

  static const callHeld = 'ঠিক! আগে সব মেপে ধরন, তারপর অন্য কাজ।';
  static const allSet = 'দারুণ! নিরাপদে মেপে ধরন বের করেছেন, আর অর্ধেকটাও খুঁজে পেয়েছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে বিচ্ছিন্ন আর ডিসচার্জ, তারপর সব জোড়া মেপে রায়।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtIso = 'দুই প্রান্ত OFF, লক আর ট্যাগ — তবে লিড';
  static const caughtDischarge = 'টেস্টের পর ডিসচার্জ, তবে ক্লিপ খোলা';
  static const caughtType = 'সব জোড়া মেপে ফল্টের ধরন';
  static const caughtDouble = 'এক কেবিলে দুটো ফল্টই ধরেছেন';
  static const caughtPit = 'মাঝের পিটে ভাগ করে ফল্টের অর্ধেক';
  static const caughtCall = 'ওর তাড়ায় “না” বলেছেন';
}

abstract final class M5CableMistakes {
  static const _dir = 'assets/game/art/m5_cable_fault_type';
  static const _k = '5.9/m5_cable_fault_type';

  // Lesson 2.7's rules (not 5.9's text): no lesson point here.
  static const liveLead = DoMistake(
    key: '$_k/live-lead',
    textBn: 'কেবিলের এক প্রান্ত চালু — কেবিল লাইভ! লিডের আগে দুই প্রান্তের সুইচ OFF, হ্যাস্পে লক আর ট্যাগ।',
    art: '$_dir/live_lead.svg',
    deadly: true,
  );
  static const liveRod = DoMistake(
    key: '$_k/live-rod',
    textBn: 'কেবিলের এক প্রান্ত চালু — আর্থ করা ডিসচার্জ রড লাইভ কোরে মানে সরাসরি আর্থ শর্ট! আগে দুই প্রান্তের সুইচ OFF, হ্যাস্পে লক আর ট্যাগ।',
    art: '$_dir/live_rod.svg',
    deadly: true,
  );
  static const chargedClip = DoMistake(
    key: '$_k/charged-clip',
    textBn: 'টেস্টের পর আগে ডিসচার্জ, তারপর ক্লিপ খুলুন — মেগারের টেস্ট ভোল্টেজ কেবিলে চার্জ হয়ে জমে থাকে।',
    art: '$_dir/charged_clip.svg',
    deadly: true,
  );
  static const isolateFirst = DoMistake(
    key: '$_k/isolate-first',
    textBn: 'আগে দুই প্রান্তই বিচ্ছিন্ন — সুইচ OFF, হ্যাস্পে লক, ট্যাগ ঝোলানো — তারপর ডিসচার্জ আর পরীক্ষা।',
    art: '$_dir/isolate.svg',
  );
  static const dischargeFirst = DoMistake(
    key: '$_k/discharge-first',
    textBn: 'লিড লাগানোর আগে কোরটা ডিসচার্জ রডে ভালোভাবে ডিসচার্জ করুন।',
    art: '$_dir/discharge_first.svg',
  );
  static const multiOnIns = DoMistake(
    key: '$_k/multi-on-insulation',
    textBn: 'দুই কোরের মাঝে বা কোর-আর্মারে মাপুন মেগার দিয়ে। মাল্টিমিটার শুধু একটা কোরের দুই প্রান্তের কন্টিনিউটি।',
    art: '$_dir/wrong_meter.svg',
    lessonPoint: 1,
  );
  static const meggerOneCore = DoMistake(
    key: '$_k/megger-one-core',
    textBn: 'একটা কোরের দুই প্রান্তের মাঝে কন্টিনিউটি — বিপ হয় কি না — দেখুন মাল্টিমিটারে। মেগার ইনসুলেশনের জন্য।',
    art: '$_dir/wrong_meter.svg',
    lessonPoint: 1,
  );
  static const swapped = DoMistake(
    key: '$_k/lead-swapped',
    textBn: "মেগারের 'লাইন' (L) লিড কোরে, 'আর্থ' (E) লিড কেবিলের আর্মারে।",
    art: '$_dir/swapped.svg',
  );
  static const testsMissing = DoMistake(
    key: '$_k/tests-missing',
    textBn: 'রায়ের আগে সব জোড়া মাপুন — কোর থেকে কোর, কোর থেকে আর্মার, প্রতিটা কোরের দুই প্রান্ত।',
    art: '$_dir/tests_missing.svg',
    lessonPoint: 1,
  );
  static const wrongVerdict = DoMistake(
    key: '$_k/wrong-verdict',
    textBn: 'রিডিং আবার দেখুন: দুই কোরে কম = শর্ট, কোর-আর্মারে কম = আর্থ, বিপ নেই = কোর ভেতরে কাটা।',
    art: '$_dir/verdict.svg',
    lessonPoint: 1,
  );
  static const wrongPit = DoMistake(
    key: '$_k/wrong-pit',
    textBn: 'সেকশনালাইজিং (প্রো টিপ 3): কেবিলটা মাঝখান থেকে ভাগ করুন — যে পিট দৈর্ঘ্যের মাঝের সবচেয়ে কাছে, সেটা খুলুন।',
    art: '$_dir/pit.svg',
    lessonPoint: 2,
  );
  static const wrongHalf = DoMistake(
    key: '$_k/wrong-half',
    textBn: 'সেকশনালাইজিং (প্রো টিপ 3): দুই সেকশনে মেগার — যে সেকশনে রিডিং কম, ফল্ট সেই অর্ধেকে।',
    art: '$_dir/half.svg',
    lessonPoint: 2,
  );
  static const halfUntested = DoMistake(
    key: '$_k/half-untested',
    textBn: 'সেকশনালাইজিং (প্রো টিপ 3): দুই সেকশনেই মেগার দিয়ে মেপে তবে বলুন ফল্ট কোন অর্ধেকে।',
    art: '$_dir/half.svg',
    lessonPoint: 2,
  );
  static const listenA1 = DoMistake(
    key: '$_k/listen-dig',
    textBn: 'ধরন না জেনে খোঁড়া নয় — মাঠে যাওয়ার আগে মেগার আর মাল্টিমিটারে ফল্টের ধরন বের করুন।',
    art: '$_dir/dig.svg',
    lessonPoint: 1,
  );
  static const listenA2 = DoMistake(
    key: '$_k/listen-one-reading',
    textBn: 'একটা কম রিডিং পুরো ছবি নয় — আরও ফল্ট থাকতে পারে। বাকি জোড়াও মেপে তবে রায়।',
    art: '$_dir/tests_missing.svg',
    lessonPoint: 1,
  );

  static List<DoMistake> get all => [
        liveLead,
        liveRod,
        chargedClip,
        isolateFirst,
        dischargeFirst,
        multiOnIns,
        meggerOneCore,
        swapped,
        testsMissing,
        wrongVerdict,
        wrongPit,
        wrongHalf,
        halfUntested,
        listenA1,
        listenA2,
      ];
}

/// One cable round's deal.
@immutable
class M5CableCase {
  const M5CableCase({required this.faults, required this.onEnd, required this.needle, required this.readings, required this.whyFault});

  final Set<M5Fault> faults;

  /// The end left ON (null: both OFF already).
  final M5End? onEnd;

  /// The megger's face: a needle dial (or digital).
  final bool needle;

  /// Every test's raw reading.
  final Map<M5Test, String> readings;

  /// The fault the verdict's reason asks about.
  final M5Fault whyFault;

  bool low(M5Test t) => faults.any((f) => f.test == t);
}

@immutable
class M5CableDeal {
  const M5CableDeal({
    required this.cases,
    required this.cwRound,
    required this.cwA2,
    required this.pits,
    required this.length,
    required this.faultAt,
    required this.pitCore,
    required this.pitLow,
    required this.pitGood,
    required this.look,
  });

  /// The two cable rounds.
  final List<M5CableCase> cases;

  /// The coworker's round (0 or 1) and push (A2: on the first low megger
  /// reading; dealt only in a round whose cable has one).
  final int cwRound;
  final bool cwA2;

  /// Round 3: the pits' chainage (m, ascending), the cable's length, the
  /// fault's chainage, the earth-faulted core and its two readings.
  final List<int> pits;
  final int length;
  final int faultAt;
  final M5Core pitCore;
  final String pitLow;
  final String pitGood;

  /// The street's dressing (0–2).
  final int look;

  /// The pit nearest the middle of the cable.
  int get rightPit {
    var best = 0;
    for (var i = 1; i < pits.length; i++) {
      if ((pits[i] * 2 - length).abs() < (pits[best] * 2 - length).abs()) best = i;
    }
    return best;
  }

  /// The fault lies in the left section (substation side) of the right pit.
  bool get faultLeft => faultAt < pits[rightPit];
}

M5CableCase _dealCase(math.Random rng, {required bool allowDouble}) {
  final faults = <M5Fault>{M5Fault.values[rng.nextInt(9)]};
  if (allowDouble && rng.nextBool()) {
    final second = [for (final f in M5Fault.values) if (m5DoubleOk(faults.first, f)) f];
    faults.add(second[rng.nextInt(second.length)]);
  }
  final r = rng.nextDouble();
  final on = r < 0.6 ? null : (r < 0.8 ? M5End.near : M5End.far);
  String pick(List<String> l) => l[rng.nextInt(l.length)];
  final low = {for (final f in faults) f.test};
  final readings = {
    for (final t in M5Test.values)
      t: t.megger ? (low.contains(t) ? pick(M5CableLines.meggerLow) : pick(M5CableLines.meggerGood)) : (low.contains(t) ? M5CableLines.ohmOpen : pick(M5CableLines.ohmBeep)),
  };
  final list = faults.toList();
  return M5CableCase(faults: faults, onEnd: on, needle: rng.nextBool(), readings: readings, whyFault: list[rng.nextInt(list.length)]);
}

/// The cable reads low on the megger somewhere (a short or an earth fault).
bool m5MeggerLow(M5CableCase c) => c.faults.any((f) => f.test.megger);

M5CableDeal m5CableDeal(math.Random rng) {
  final c1 = _dealCase(rng, allowDouble: false);
  final c2 = _dealCase(rng, allowDouble: true);
  // The street: 3 or 5 pits, uneven, one clearly nearest the middle.
  final n = rng.nextBool() ? 3 : 5;
  late List<int> pits;
  late int length;
  while (true) {
    length = 640 + rng.nextInt(77) * 10;
    final lo = (length * 0.1).round(), hi = (length * 0.9).round();
    final minGap = (length * 0.14).round();
    pits = [];
    var tries = 0;
    while (pits.length < n && tries++ < 200) {
      final c = ((lo + rng.nextInt(hi - lo)) / 10).round() * 10;
      if (pits.every((p) => (p - c).abs() >= minGap)) pits.add(c);
    }
    if (pits.length < n) continue;
    pits.sort();
    final d = [for (final p in pits) (p * 2 - length).abs()]..sort();
    // Uneven gaps: equal spacing would point at the middle pit by itself.
    final gaps = [pits.first, for (var i = 1; i < n; i++) pits[i] - pits[i - 1], length - pits.last]..sort();
    if (d[1] - d[0] >= length * 0.12 && gaps.last - gaps.first >= length * 0.06) break;
  }
  // The coworker: A2 pushes on the first low megger reading, so he comes only
  // in a round whose cable has a short or an earth fault (an open-only cable
  // never reads low on the megger). No such round → A1.
  var cwRound = rng.nextInt(2);
  var cwA2 = rng.nextBool();
  final cases = [c1, c2];
  if (cwA2 && !m5MeggerLow(cases[cwRound])) {
    if (m5MeggerLow(cases[1 - cwRound])) {
      cwRound = 1 - cwRound;
    } else {
      cwA2 = false;
    }
  }
  final deal0 = M5CableDeal(
    cases: cases,
    cwRound: cwRound,
    cwA2: cwA2,
    pits: pits,
    length: length,
    faultAt: 0,
    pitCore: M5Core.values[rng.nextInt(3)],
    pitLow: M5CableLines.meggerLow[rng.nextInt(M5CableLines.meggerLow.length)],
    pitGood: M5CableLines.meggerGood[rng.nextInt(M5CableLines.meggerGood.length)],
    look: rng.nextInt(3),
  );
  final mid = pits[deal0.rightPit];
  int at;
  do {
    at = ((length * 0.06 + rng.nextDouble() * length * 0.88) / 10).round() * 10;
  } while ((at - mid).abs() < length * 0.1);
  return M5CableDeal(
    cases: deal0.cases,
    cwRound: deal0.cwRound,
    cwA2: deal0.cwA2,
    pits: pits,
    length: length,
    faultAt: at,
    pitCore: deal0.pitCore,
    pitLow: deal0.pitLow,
    pitGood: deal0.pitGood,
    look: deal0.look,
  );
}

/// A notebook row: what the leads were on, and the raw reading.
@immutable
class M5Row {
  const M5Row(this.label, this.tool, this.reading);
  final String label;
  final M5Tool tool;
  final String reading;

  String get text => '$label · ${M5CableLines.toolLabel(tool)} · $reading';
}

/// What a finished pair of clips measured.
@immutable
class M5Reading {
  const M5Reading({required this.row, required this.low, this.test, this.pitSide});
  final M5Row row;

  /// Low insulation, or no beep.
  final bool low;

  /// The cable rounds' test (null: in the pit, or a test that is not one of
  /// the nine).
  final M5Test? test;

  /// In the pit: the faulted core measured on this side (true = left).
  final bool? pitSide;
}

/// The play state (pure logic).
class M5CableRun {
  M5CableRun(this.deal) {
    _startRound();
  }
  final M5CableDeal deal;

  int index = 0;
  int slips = 0;
  int roundSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The round's work is done (its reason comes next).
  var roundDone = false;

  // Isolation.
  final Set<M5End> on = {};
  final Set<M5End> locked = {};
  final Set<M5End> tagged = {};

  // Discharge and tests.
  final Set<M5Core> discharged = {};
  M5Tool? hand;

  /// The instrument whose leads are on (the clips belong to it).
  M5Tool? clipTool;
  M5Pt? clipA;
  M5Pt? clipB;

  /// The megger's TEST was held on the clips that are on.
  var tested = false;

  /// The cable holds the megger's charge.
  var charged = false;

  /// The clips that are on make a valid test (TEST may be held).
  var ready = false;
  M5Reading? last;

  /// The notebook (raw rows, in the order written).
  final List<M5Row> rows = [];
  final Set<M5Test> done = {};

  /// A low reading's row waits for the coworker (A2).
  var holdLowRow = false;
  M5Reading? rowPending;

  /// After-test discharges this round (the first in round 2 gets a reason).
  int afterDischarges = 0;

  // The pit.
  var pitOpen = false;
  final Set<bool> pitSides = {};

  /// The pit's split ends discharged (each section's core before its first
  /// lead).
  final Set<M5Pt> pitDischarged = {};

  M5CableRound get round => M5CableRound.values[index.clamp(0, 2)];
  bool get done3 => index >= 3;
  bool get ended => done3 || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done3 && deadly == null && percent >= 55;
  bool get thorough => roundSlips == 0;
  bool get _open => !ended && !roundDone;
  bool get isCable => index < 2;
  M5CableCase get cable => deal.cases[index.clamp(0, 1)];

  bool get isolated => !isCable || (on.isEmpty && locked.length == 2 && tagged.length == 2);
  bool get anyOn => on.isNotEmpty;
  bool get clipsOn => clipA != null;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlips++;
    return m;
  }

  /// Books a slip from outside the rules (listening to the coworker).
  DoMistake bookSlip(DoMistake m) => _slip(m);

  void _startRound() {
    on.clear();
    locked.clear();
    tagged.clear();
    discharged.clear();
    hand = null;
    clipTool = null;
    clipA = clipB = null;
    tested = charged = ready = false;
    last = null;
    rows.clear();
    done.clear();
    holdLowRow = false;
    rowPending = null;
    afterDischarges = 0;
    pitOpen = false;
    pitSides.clear();
    pitDischarged.clear();
    if (isCable) {
      final e = cable.onEnd;
      if (e != null) on.add(e);
    } else {
      rows.add(M5Row('${m5CoreName(deal.pitCore)}–E', M5Tool.megger, deal.pitLow));
    }
  }

  // --- isolation -------------------------------------------------------------
  /// The lever: ON → OFF. True if it moved.
  bool switchOff(M5End e) {
    if (!_open || !isCable || !on.contains(e)) return false;
    on.remove(e);
    return true;
  }

  /// The hasp held shut (only over an OFF lever). True if it locked now.
  bool lock(M5End e) {
    if (!_open || !isCable || on.contains(e) || locked.contains(e)) return false;
    locked.add(e);
    return true;
  }

  /// The tag hung on the locked hasp. True if it went on now.
  bool hangTag(M5End e) {
    if (!_open || !isCable || !locked.contains(e) || tagged.contains(e)) return false;
    tagged.add(e);
    if (isolated && index == 0) _tag(M5CableLines.caughtIso);
    return true;
  }

  // --- tools -----------------------------------------------------------------
  /// Picks a tool up. False when another instrument's leads are still on.
  bool lift(M5Tool t) {
    if (!_open) return false;
    if (clipsOn && t != M5Tool.rod && t != clipTool) return false;
    hand = t;
    return true;
  }

  /// The rod on a point: a pre-test discharge, the after-test discharge (on a
  /// clipped core), or — tapped again on a clip once the charge is gone —
  /// the clip comes off.
  DoMistake? rodOn(M5Pt p) {
    if (!_open || hand != M5Tool.rod) return null;
    // The earthed rod on a core with an end ON shorts a live core to earth.
    if (isCable && p.core != null && anyOn) return deadly = M5CableMistakes.liveRod;
    if (isCable && !isolated) return _slip(M5CableMistakes.isolateFirst);
    final clipped = p == clipA || p == clipB;
    if (clipped && !charged) return unclip();
    final c = p.core;
    if (c == null) return null;
    if (clipped && charged) {
      charged = false;
      afterDischarges++;
      _tag(M5CableLines.caughtDischarge);
      return null;
    }
    if (isCable) {
      discharged.add(c);
    } else {
      pitDischarged.add(p);
    }
    return null;
  }

  /// A lead goes on [p]. Returns the mistake, if any.
  DoMistake? clip(M5Pt p) {
    if (!_open) return null;
    final t = hand;
    if (t == null || t == M5Tool.rod) return null;
    if (clipB != null || p == clipA) return null;
    if (clipsOn && t != clipTool) return null;
    if (isCable) {
      if (p.core != null && anyOn) return deadly = M5CableMistakes.liveLead;
      if (!isolated) return _slip(M5CableMistakes.isolateFirst);
      if (p.core != null && !discharged.contains(p.core)) return _slip(M5CableMistakes.dischargeFirst);
    } else if (p.core != null && !pitDischarged.contains(p)) {
      // A freshly split section: discharge it before the lead, as in the room.
      return _slip(M5CableMistakes.dischargeFirst);
    }
    if (clipA == null) {
      clipA = p;
      clipTool = t;
      return null;
    }
    clipB = p;
    final slip = _check(t, clipA!, p);
    if (slip != null) {
      _clear();
      return _slip(slip);
    }
    ready = true;
    if (t == M5Tool.multi) _record();
    return null;
  }

  DoMistake? _check(M5Tool t, M5Pt a, M5Pt b) {
    final ca = a.core, cb = b.core;
    if (t == M5Tool.megger) {
      if (ca != null && cb != null) return ca == cb ? M5CableMistakes.meggerOneCore : null;
      if (ca == null && cb != null) return M5CableMistakes.swapped;
      return null;
    }
    // The multimeter: only one core's two ends.
    if (ca != null && ca == cb && a.isFar != b.isFar && !a.isPit) return null;
    return M5CableMistakes.multiOnIns;
  }

  /// The megger's TEST held to the end.
  M5Reading? holdTest() {
    if (!_open || clipTool != M5Tool.megger || !ready || tested) return null;
    tested = true;
    charged = true;
    return _record();
  }

  M5Reading _record() {
    final a = clipA!, b = clipB!, tool = clipTool!;
    final ca = a.core, cb = b.core;
    M5Reading r;
    if (isCable) {
      final M5Test test = tool == M5Tool.multi ? m5ContTest(ca!) : (cb == null ? m5EarthTest(ca!) : m5InsTest(ca!, cb));
      final low = cable.low(test);
      r = M5Reading(row: M5Row(test.label, tool, cable.readings[test]!), low: low, test: test);
    } else if (cb == null) {
      final faulted = ca == deal.pitCore;
      final low = faulted && a.pitLeft == deal.faultLeft;
      final side = a.pitLeft ? M5CableLines.leftHalf : M5CableLines.rightHalf;
      r = M5Reading(
        row: M5Row('$side ${m5CoreName(ca!)}–E', tool, low ? deal.pitLow : deal.pitGood),
        low: low,
        pitSide: faulted ? a.pitLeft : null,
      );
    } else {
      r = M5Reading(row: M5Row('${m5CoreName(ca!)}–${m5CoreName(cb)}', tool, deal.pitGood), low: false);
    }
    last = r;
    // A2's push is "one low reading": only a megger reading reads low (a
    // silent multimeter reads OL, not low).
    if (holdLowRow && r.low && tool == M5Tool.megger) {
      holdLowRow = false;
      rowPending = r;
    } else {
      _write(r);
    }
    return r;
  }

  void _write(M5Reading r) {
    final t = r.test;
    if (t != null && done.contains(t)) return;
    if (t != null) done.add(t);
    if (r.pitSide != null) pitSides.add(r.pitSide!);
    if (!rows.any((x) => x.text == r.row.text)) rows.add(r.row);
  }

  /// The row that waited for the coworker goes into the notebook.
  void writePending() {
    final r = rowPending;
    rowPending = null;
    if (r != null) _write(r);
  }

  /// The clips come off. Deadly while the megger's charge is still in the cable.
  DoMistake? unclip() {
    if (!_open || !clipsOn) return null;
    if (charged) return deadly = M5CableMistakes.chargedClip;
    if (hand == M5Tool.rod) hand = clipTool;
    _clear();
    return null;
  }

  void _clear() {
    clipA = clipB = null;
    clipTool = null;
    tested = charged = ready = false;
    last = null;
  }

  // --- verdict ---------------------------------------------------------------
  DoMistake? verdict(Set<M5Fault> pick) {
    if (!_open || !isCable) return null;
    if (done.length < M5Test.values.length) return _slip(M5CableMistakes.testsMissing);
    if (pick.length != cable.faults.length || !pick.containsAll(cable.faults)) return _slip(M5CableMistakes.wrongVerdict);
    roundDone = true;
    if (thorough) _tag(M5CableLines.caughtType);
    if (cable.faults.length > 1) _tag(M5CableLines.caughtDouble);
    return null;
  }

  // --- the pit ---------------------------------------------------------------
  DoMistake? openPit(int i) {
    if (!_open || isCable || pitOpen) return null;
    if (i != deal.rightPit) return _slip(M5CableMistakes.wrongPit);
    pitOpen = true;
    return null;
  }

  DoMistake? tapHalf(bool left) {
    if (!_open || isCable || !pitOpen) return null;
    if (pitSides.length < 2) return _slip(M5CableMistakes.halfUntested);
    if (left != deal.faultLeft) return _slip(M5CableMistakes.wrongHalf);
    roundDone = true;
    _tag(M5CableLines.caughtPit);
    return null;
  }

  /// Fails the play.
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    roundSlips = 0;
    roundDone = false;
    if (index < 3) _startRound();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   a cable round: isolation (2 pans, lever, 2 hasps, 2 tags) 10500 +
///     rod + 3 discharges 6000 + 6 megger tests × 6 actions 54000 +
///     3 continuity tests × 5 (2 clips, 2 pans, unclip) 22500 + the verdict
///     (open, 1–2 chips, submit) 6000 + 2 reasons 16400        ≈ 115000
///   × 2 rounds                                                  ≈ 230000
///   the pit: pit, rod, 2 discharges, megger, 2 tests × 6, the
///     half 27000 + reason                                       ≈  35200
///   + the coworker once                                         ≈   9600
///                                                               ≈ 274800
/// 85 % ≈ 233600 → 230000.
const m5CableQuickMs = 230000;

@immutable
class M5CablePack {
  const M5CablePack({required this.id, required this.titleBn, this.quickMs = m5CableQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5CablePack> m5CableFaultTypePacks = {
  'do_5_9_a': M5CablePack(id: 'do_5_9_a', titleBn: M5CableLines.title),
};

/// The coworker's script this play.
CoworkerScript m5CableCoworker(M5CableDeal d) => d.cwA2 ? M5CableLines.coworkerA2 : M5CableLines.coworkerA1;

/// The reason after a round's work.
List<String> m5CableWhyRight(M5CableRun r) => r.isCable ? M5CableLines.kindWhy[r.cable.whyFault.kind]! : M5CableLines.pitWhy;
String m5CableWhyQ(M5CableRun r) => r.isCable ? M5CableLines.kindWhyQ[r.cable.whyFault.kind]! : M5CableLines.pitWhyQ;

// ============================================================================
// Page
// ============================================================================

class M5CableFaultTypePage extends StatefulWidget {
  const M5CableFaultTypePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M5CablePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M5CableFaultTypePage> createState() => _M5CableFaultTypePageState();
}

class _M5CableFaultTypePageState extends State<M5CableFaultTypePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CableRunPage(
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

class _CableRunPage extends ConsumerStatefulWidget {
  const _CableRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M5CablePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_CableRunPage> createState() => _CableRunPageState();
}

class _CableRunPageState extends ConsumerState<_CableRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5CableRun _run;
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

  /// The camera in the cable room: 0 = the substation end, 1 = the far end.
  int _view = 0;
  var _panning = false;
  var _seenFar = false;

  /// The verdict sheet.
  var _sheet = false;
  final Set<M5Fault> _pick = {};

  /// A lead being dragged (world px), and the rod's spark.
  Offset? _drag;
  int _sparkTok = 0;
  Offset? _sparkAt;

  /// An early release (the hint then shows the hold).
  final Set<M5End> _haspEarly = {};
  var _testEarly = false;

  /// After the reason: does the round end (the verdict / the pit)?
  var _reasonEnds = false;

  var _freeze = false;
  Offset _flashAt = const Offset(180, 400);
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  final _hints = IdleHintController();
  final Map<Object, GlobalKey> _keys = {};
  GlobalKey _key(Object id) => _keys.putIfAbsent(id, GlobalKey.new);
  M5CableGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M5CableRun(m5CableDeal(widget.rng));
    _run.holdLowRow = _run.deal.cwA2 && _run.deal.cwRound == 0;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
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

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze;

  String get _task {
    if (!_run.isCable) return _run.pitOpen ? M5CableLines.askPitTest : M5CableLines.askPit;
    if (_sheet) return M5CableLines.askVerdict;
    return _run.isolated ? M5CableLines.askTest : M5CableLines.askIsolate;
  }

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  void _startRound() {
    setState(() {
      _wake++;
      _panning = _view != 0 && !_quiet;
      _view = 0;
      _seenFar = false;
      _sheet = false;
      _pick.clear();
      _haspEarly.clear();
      _testEarly = false;
    });
    final lead = switch (_run.index) {
      1 => M5CableLines.cable2,
      2 => M5CableLines.pitIntro,
      _ => null,
    };
    unawaited(_sayChain([?lead, _task]));
  }

  // --- hands on -----------------------------------------------------------------
  void _pan(int to) {
    if (!_canPlay || _panning || _view == to || !_run.isCable || _sheet) return;
    _tick('sounds/intro/click.ogg', 0.4);
    setState(() {
      _view = to;
      _panning = !_quiet;
      if (to == 1) _seenFar = true;
      _drag = null;
    });
  }

  M5End get _viewEnd => _view == 0 ? M5End.near : M5End.far;

  /// A tap on the scene (world px: the cable room is 720 wide).
  void _tapWorld(Offset p, Offset global) {
    final geo = _geoNow;
    if (geo == null || !_canPlay || _panning || _sheet) return;
    if (_run.isCable) {
      final e = _viewEnd;
      if (geo.leverHit(e).contains(p)) {
        if (_run.switchOff(e)) {
          _tick('sounds/intro/impact_metal.ogg', 0.6);
          setState(() => _wake++);
        } else {
          _tick('sounds/intro/click.ogg', 0.35);
        }
        return;
      }
      if (geo.tagHit(e).contains(p)) {
        if (_run.hangTag(e)) {
          _tick('sounds/learn/tag_slap.wav', 0.55);
          setState(() => _wake++);
          if (_run.isolated) _isolated();
        } else {
          _hints.missTap();
        }
        return;
      }
      for (final pt in _view == 0 ? M5CableGeo.nearPts : M5CableGeo.farPts) {
        if (geo.hit(pt).contains(p)) {
          _point(pt, global);
          return;
        }
      }
      _hints.missTap();
      return;
    }
    // The street.
    if (!_run.pitOpen) {
      for (var i = 0; i < _run.deal.pits.length; i++) {
        if (geo.pitHit(_run.deal.pits[i], _run.deal.length).contains(p)) {
          _tick('sounds/intro/impact_metal.ogg', 0.5);
          final m = _run.openPit(i);
          setState(() => _wake++);
          if (m != null) {
            unawaited(_mistake(m, global, p));
          } else {
            unawaited(_sayChain([M5CableLines.askPitTest]));
          }
          return;
        }
      }
      _hints.missTap();
      return;
    }
    for (final pt in M5CableGeo.pitPts) {
      if (geo.hit(pt).contains(p)) {
        _point(pt, global);
        return;
      }
    }
    final at = geo.pitX(_run.deal.pits[_run.deal.rightPit], _run.deal.length);
    for (final left in [true, false]) {
      if (geo.halfHit(left, at).contains(p)) {
        _tick();
        final m = _run.tapHalf(left);
        setState(() => _wake++);
        if (m != null) {
          unawaited(_mistake(m, global, p));
        } else if (_run.roundDone) {
          unawaited(_roundDone());
        }
        return;
      }
    }
    _hints.missTap();
  }

  /// A lug / the armour tapped with whatever is in hand.
  void _point(M5Pt pt, Offset global) {
    final hand = _run.hand;
    if (hand == null) {
      _hints.missTap();
      return;
    }
    if (holdForCoworker()) return;
    final geo = _geoNow!;
    if (hand == M5Tool.rod) {
      final wasCharged = _run.charged;
      final m = _run.rodOn(pt);
      if (m != null) {
        setState(() => _wake++);
        unawaited(_mistake(m, global, geo.lugAt(pt)));
        return;
      }
      _cue('sounds/intro/impact_metal.ogg', volume: 0.45);
      HapticFeedback.lightImpact();
      setState(() {
        _wake++;
        _sparkTok++;
        _sparkAt = geo.lugAt(pt);
      });
      if (wasCharged && !_run.charged && _run.index == 1 && _run.afterDischarges == 1) {
        // The first after-test discharge of round 2: ◆ → reason.
        _hush();
        putOnTable(10);
        _reasonEnds = false;
        final idx = _run.index;
        unawaited(askReason(
          deal: () => dealChoices(M5CableLines.dischargeWhy, M5CableLines.myths, widget.rng),
          question: M5CableLines.dischargeWhyQ,
          stillValid: () => _run.index == idx && !_ended,
        ));
      }
      return;
    }
    // A meter: the clip comes off (tapped on itself) or a lead goes on.
    if (pt == _run.clipA || pt == _run.clipB) {
      _unclip(global, geo.lugAt(pt));
      return;
    }
    _clipOn(pt, global);
  }

  void _clipOn(M5Pt pt, Offset global) {
    final geo = _geoNow!;
    final m = _run.clip(pt);
    setState(() {
      _wake++;
      _testEarly = false;
    });
    if (m != null) {
      unawaited(_mistake(m, global, geo.lugAt(pt)));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.55);
    final r = _run.last;
    if (r != null && _run.clipTool == M5Tool.multi) _reading(r);
  }

  void _unclip(Offset global, Offset world) {
    if (holdForCoworker()) return;
    final m = _run.unclip();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global, world));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.5);
  }

  void _liftTool(M5Tool t) {
    if (!_canPlay || _panning || _sheet) return;
    if (holdForCoworker()) return;
    if (!_run.lift(t)) {
      _tick('sounds/intro/click.ogg', 0.3);
      return;
    }
    _tick(t == M5Tool.rod ? 'sounds/intro/impact_metal.ogg' : 'sounds/learn/tag_slap.wav', 0.45);
    setState(() => _wake++);
  }

  void _testDone() {
    if (!_canPlay) return;
    final r = _run.holdTest();
    if (r == null) return;
    setState(() {
      _wake++;
      _testEarly = false;
    });
    _reading(r);
  }

  void _reading(M5Reading r) {
    final multi = _run.clipTool == M5Tool.multi;
    if (multi && !r.low) {
      _cue('sounds/intro/tick.ogg', volume: 0.9);
    } else {
      _tick('sounds/intro/click.ogg', 0.6);
    }
    if (_run.rowPending != null) scheduleCoworker();
  }

  void _lockHasp(M5End e) {
    if (!_canPlay || _panning) return;
    if (_run.lock(e)) {
      _tick('sounds/intro/impact_metal.ogg', 0.6);
      setState(() {
        _wake++;
        _haspEarly.remove(e);
      });
    } else {
      _tick('sounds/intro/click.ogg', 0.35);
    }
  }

  /// Both ends are OFF, locked and tagged.
  void _isolated() {
    final coworkerHere = _run.deal.cwRound == _run.index && !_run.deal.cwA2;
    if (_run.index == 0) {
      _hush();
      HapticFeedback.mediumImpact();
      _cue('sounds/quiz_right.wav', volume: 0.6);
      putOnTable(10);
      _reasonEnds = false;
      final idx = _run.index;
      unawaited(askReason(
        deal: () => dealChoices(M5CableLines.isoWhy, M5CableLines.myths, widget.rng),
        question: M5CableLines.isoWhyQ,
        stillValid: () => _run.index == idx && !_ended,
      ));
    } else {
      _cue('sounds/quiz_right.wav', volume: 0.5);
      unawaited(_sayChain([M5CableLines.askTest]));
    }
    if (coworkerHere) scheduleCoworker();
  }

  void _openSheet() {
    if (!_canPlay || _panning || _sheet || !_run.isCable) return;
    if (holdForCoworker()) return;
    if (_run.clipsOn) {
      _tick('sounds/intro/click.ogg', 0.3);
      return;
    }
    _tick('sounds/learn/card_deal_a.wav', 0.55);
    setState(() {
      _sheet = true;
      _pick.clear();
    });
    unawaited(_sayChain([M5CableLines.askVerdict], mood: GuideMood.think));
  }

  void _closeSheet() {
    if (!_sheet) return;
    _tick();
    setState(() => _sheet = false);
    unawaited(_sayChain([_task]));
  }

  void _togglePick(M5Fault f) {
    if (!_canPlay || !_sheet) return;
    _tick();
    setState(() => _pick.contains(f) ? _pick.remove(f) : _pick.add(f));
  }

  void _submit(Offset global) {
    if (!_canPlay || !_sheet) return;
    if (holdForCoworker()) return;
    final m = _run.verdict(_pick);
    if (m != null) {
      setState(() {
        if (m == M5CableMistakes.testsMissing) _sheet = false;
        _wake++;
      });
      unawaited(_mistake(m, global, null));
      return;
    }
    setState(() => _sheet = false);
    unawaited(_roundDone());
  }

  Future<void> _roundDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.7);
    _cue('sounds/quiz_right.wav', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    _reasonEnds = true;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(m5CableWhyRight(_run), M5CableLines.myths, widget.rng),
      question: m5CableWhyQ(_run),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done3) {
      unawaited(_finish());
      return;
    }
    _run.holdLowRow = _run.deal.cwA2 && _run.deal.cwRound == _run.index && !coworkerDone;
    _startRound();
  }

  Future<void> _mistake(DoMistake m, Offset origin, Offset? world) async {
    if (m.deadly) {
      final geo = _geoNow;
      if (world != null && geo != null) _flashAt = _run.isCable ? world - Offset(360.0 * _view, 0) : world;
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
    if (!_reasonEnds) {
      unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
        if (mounted && !_ended && _run.index == idx) unawaited(_sayChain([_task]));
      }));
      return;
    }
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => m5CableCoworker(_run.deal);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    final d = _run.deal;
    if (_ended || _run.index != d.cwRound || _run.roundDone) return null;
    if (d.cwA2) {
      if (_run.rowPending == null) return null;
    } else if (_run.rows.isNotEmpty) {
      return null;
    }
    if (_intro || _card != null || tableBusy || _sheet || _freeze || _panning) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    _run.writePending();
    setState(() => _wake++);
    if (!held) {
      final m = _run.bookSlip(_run.deal.cwA2 ? M5CableMistakes.listenA2 : M5CableMistakes.listenA1);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M5CableLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M5CableLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5CableLines.tapWhy[_nudgeN++ % M5CableLines.tapWhy.length]
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
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m5cable/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A lead on a live core, or a clip off a charged cable: the scene freezes
  /// grey and the flash comes off the lug in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _sheet = false;
      _drag = null;
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
    final speak = await SpokenOnce.first('m5cable/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5CableLines.deadlyWord : M5CableLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same round goes on from where it was.
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
    await _say(!_run.passed ? M5CableLines.fail : (_quickBonus ? M5CableLines.quick : M5CableLines.allSet),
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

  // --- the lead drag (or a swipe that pans the cable room) ---------------------
  Offset? _swipeFrom;
  Offset? _swipeTo;
  Offset _dragGlobal = Offset.zero;

  void _dragStart(Offset world, Offset global) {
    final geo = _geoNow;
    _swipeFrom = _swipeTo = null;
    if (geo == null || !_canPlay || _panning || _sheet) return;
    final shift = _run.isCable ? 360.0 * _view : 0.0;
    final t = _run.hand;
    if (t != null && t != M5Tool.rod && _run.clipB == null && geo.leadGrab.shift(Offset(shift, 0)).contains(world)) {
      _dragGlobal = global;
      setState(() => _drag = world);
      return;
    }
    _swipeFrom = _swipeTo = world;
  }

  void _dragMove(Offset world, Offset global) {
    if (_drag == null) {
      if (_swipeFrom != null) _swipeTo = world;
      return;
    }
    _dragGlobal = global;
    setState(() => _drag = world);
  }

  void _dragEnd() {
    final d = _drag;
    if (d == null) {
      final from = _swipeFrom, to = _swipeTo;
      _swipeFrom = _swipeTo = null;
      if (from != null && to != null && _run.isCable) {
        final dx = to.dx - from.dx;
        if (dx.abs() > 40 && dx.abs() > (to.dy - from.dy).abs()) _pan(dx < 0 ? 1 : 0);
      }
      return;
    }
    setState(() => _drag = null);
    final geo = _geoNow;
    if (geo == null || !_canPlay) return;
    final pts = !_run.isCable ? M5CableGeo.pitPts : (_view == 0 ? M5CableGeo.nearPts : M5CableGeo.farPts);
    for (final pt in pts) {
      if (geo.hit(pt).inflate(8).contains(d)) {
        if (holdForCoworker()) return;
        _clipOn(pt, _dragGlobal);
        return;
      }
    }
    _hints.missTap();
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_run.hand != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M5CableRig get _rig => M5CableRig(on: {..._run.on}, locked: {..._run.locked}, tagged: {..._run.tagged}, cable: _run.index.clamp(0, 1));

  Rect _view2scene(Rect r) => _run.isCable ? r.shift(Offset(-360.0 * _view, 0)) : r;

  /// The gesture hand (how to touch, never what).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    if (_sheet) {
      return HintSpec.sweepOver([for (final f in M5Fault.values) _key(f)]);
    }
    final tools = [M5Tool.megger, M5Tool.multi, M5Tool.rod];
    HintSpec? sweepTools() => HintSpec.sweepOver([for (final t in tools) _key(t), if (_run.isCable) _key('verdict')]);
    final mid = Offset(180, geo.up(260));
    if (_run.isCable && !_run.isolated) {
      if (!_seenFar) return HintSpec.swipe(mid.translate(70, 0), toward: const Offset(-1, 0), space: HintSpace.scene);
      final e = _viewEnd;
      final rest = _run.on.contains(e) || !_run.locked.contains(e) || !_run.tagged.contains(e);
      if (!rest) {
        return HintSpec.swipe(mid.translate(_view == 0 ? 70 : -70, 0), toward: Offset(_view == 0 ? -1 : 1, 0), space: HintSpace.scene);
      }
      if (_haspEarly.contains(e) && !_run.on.contains(e) && !_run.locked.contains(e)) {
        return HintSpec.hold(_view2scene(geo.haspHit(e)).center, space: HintSpace.scene);
      }
      return HintSpec.tap(_view2scene(geo.switchBox(e)).center, space: HintSpace.scene);
    }
    if (!_run.isCable && !_run.pitOpen) {
      return HintSpec.sweep([for (final c in _run.deal.pits) geo.pitHit(c, _run.deal.length)], space: HintSpace.scene);
    }
    // No hint once TEST has been held: taking the clip off is the test.
    if (_run.tested || _run.charged) return null;
    if (_run.clipB != null) {
      return _testEarly ? HintSpec.hold(geo.testPad.center, space: HintSpace.scene) : null;
    }
    final hand = _run.hand;
    if (hand == M5Tool.megger || hand == M5Tool.multi) {
      return HintSpec.drag(geo.socketL, toward: const Offset(0, -1), travel: 60, space: HintSpace.scene);
    }
    if (hand == M5Tool.rod && !_run.clipsOn) {
      final pts = !_run.isCable ? M5CableGeo.pitPts : (_view == 0 ? M5CableGeo.nearPts : M5CableGeo.farPts);
      return HintSpec.sweep([for (final p in pts) _view2scene(geo.hit(p))], space: HintSpace.scene);
    }
    if (!_run.isCable && _run.pitSides.length == 2) {
      final at = geo.pitX(_run.deal.pits[_run.deal.rightPit], _run.deal.length);
      return HintSpec.sweep([geo.halfHit(true, at), geo.halfHit(false, at)], space: HintSpace.scene);
    }
    return sweepTools();
  }

  String get _hintKey =>
      '${_run.index}/${_run.isolated}/${_run.hand}/${_run.clipA}/${_run.clipB}/${_run.tested}/$_view/$_sheet/$_testEarly/${_haspEarly.length}/${_run.rows.length}/${_run.pitOpen}/${_run.pitSides.length}/$_seenFar';

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5CableGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final hand = _run.hand;
    final r = _run.last;
    final meterTool = _run.clipTool ?? hand;

    // The world (world px): painted, the hold pads, the rod's spark, the touch layer.
    final world = Stack(
      children: [
        Positioned.fill(
          key: const ValueKey('room'),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _run.isCable
                  ? M5CableRoomPainter(geo: geo, rig: _rig)
                  : M5CableStreetPainter(
                      geo: geo,
                      pits: _run.deal.pits,
                      length: _run.deal.length,
                      opened: _run.pitOpen ? _run.deal.rightPit : null,
                      look: _run.deal.look,
                    ),
            ),
          ),
        ),
        if (_sparkAt != null && !_freeze)
          Positioned(
            key: ValueKey('spark-$_sparkTok'),
            left: _sparkAt!.dx - 24,
            top: _sparkAt!.dy - 24,
            width: 48,
            height: 48,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: quiet ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 420),
                builder: (_, v, _) => v >= 0.999 ? const SizedBox.shrink() : CustomPaint(painter: _SparkPainter(v)),
              ),
            ),
          ),
        Positioned.fill(
          key: const ValueKey('touch'),
          child: Semantics(
            label: M5CableLines.sceneLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _tapWorld(d.localPosition, d.globalPosition),
              onPanStart: (d) => _dragStart(d.localPosition, d.globalPosition),
              onPanUpdate: (d) => _dragMove(d.localPosition, d.globalPosition),
              onPanEnd: (_) => _dragEnd(),
              onPanCancel: () {
                _swipeFrom = _swipeTo = null;
                if (_drag != null) setState(() => _drag = null);
              },
            ),
          ),
        ),
        if (_run.isCable)
          for (final e in M5End.values)
            Positioned.fromRect(
              key: ValueKey('hasp-${e.name}'),
              rect: geo.haspHit(e),
              child: _HoldPad(
                key: ValueKey('m5c-hasp-${e.name}'),
                label: M5CableLines.hasp,
                ms: 900,
                enabled: _canPlay && !_panning && !_sheet,
                onDone: () => _lockHasp(e),
                onEarly: () => setState(() => _haspEarly.add(e)),
              ),
            ),
      ],
    );

    final worldW = _run.isCable ? 720.0 : 360.0;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: _run.isCable ? _view.toDouble() : 0),
            duration: Duration(milliseconds: quiet ? 0 : 450),
            curve: Curves.easeInOut,
            onEnd: () {
              if (mounted && _panning) setState(() => _panning = false);
            },
            builder: (context, v, child) => Stack(
              children: [
                Positioned(key: const ValueKey('cam'), left: -360 * v, top: 0, width: worldW, height: m.height, child: child!),
                if (_run.clipsOn || _drag != null)
                  Positioned.fill(
                    key: const ValueKey('leads'),
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: M5CableLeadPainter(
                          geo: geo,
                          clipL: _run.clipA == null ? null : geo.lugAt(_run.clipA!),
                          clipE: _run.clipB == null ? null : geo.lugAt(_run.clipB!),
                          shift: 360 * v,
                          drag: _drag,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            child: world,
          ),
        ),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: IgnorePointer(
          child: ColorFiltered(
            colorFilter: grey,
            child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
          ),
        ),
      ),
      if (meterTool != null && !_freeze)
        Positioned.fill(
          key: ValueKey('meter-${meterTool.name}'),
          child: IgnorePointer(
            child: CustomPaint(
              painter: M5CableMeterPainter(
                geo: geo,
                tool: meterTool,
                rod: hand == M5Tool.rod && meterTool != M5Tool.rod,
                needle: _run.isCable ? _run.cable.needle : true,
                reading: r?.row.reading,
                low: r?.low ?? false,
                beep: r != null && !r.low && _run.clipTool == M5Tool.multi,
              ),
            ),
          ),
        ),
      if (_run.clipTool == M5Tool.megger && _run.ready && !_run.tested && hand == M5Tool.megger && !_freeze)
        Positioned.fromRect(
          key: const ValueKey('test-pad'),
          rect: geo.testPad,
          child: _HoldPad(
            key: const ValueKey('m5c-test'),
            label: M5CableLines.test,
            ms: 1200,
            enabled: _canPlay,
            button: true,
            onDone: _testDone,
            onEarly: () => setState(() => _testEarly = true),
          ),
        ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M5CableFlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
      // The next round: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('round-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 0.6, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  static const _icons = {
    M5Tool.megger: Icons.speed_rounded,
    M5Tool.multi: Icons.graphic_eq_rounded,
    M5Tool.rod: Icons.hardware_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
    final showRows = playing && (_run.rows.isNotEmpty || !_run.isCable);
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
              labels: M5CableLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done3 ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !_panning && _drag == null,
            hintKey: _hintKey,
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (showRows)
                Positioned(
                  key: const ValueKey('hud-rows'),
                  top: pad.top + 92,
                  left: 10,
                  right: 10,
                  child: IgnorePointer(child: _Notebook(rows: _run.rows, length: _run.isCable ? null : _run.deal.length)),
                ),
              if (handsOn && _run.isCable && !_sheet)
                Positioned(
                  key: ValueKey('hud-pan-$_view'),
                  top: size.height * 0.30,
                  left: _view == 1 ? 4 : null,
                  right: _view == 0 ? 4 : null,
                  child: _PanButton(
                    label: _view == 0 ? M5CableLines.farEnd : M5CableLines.nearEnd,
                    right: _view == 0,
                    onTap: () => _pan(_view == 0 ? 1 : 0),
                  ),
                ),
              if (handsOn && !_sheet)
                Positioned(
                  key: ValueKey('hud-tools-${_run.index}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final t in [M5Tool.megger, M5Tool.multi, M5Tool.rod])
                        _ToolButton(
                          key: _key(t),
                          icon: _icons[t]!,
                          label: M5CableLines.toolLabel(t),
                          on: _run.hand == t,
                          onTap: (_) => _liftTool(t),
                        ),
                      if (_run.isCable)
                        _ToolButton(
                          key: _key('verdict'),
                          icon: Icons.menu_book_rounded,
                          label: M5CableLines.verdict,
                          on: false,
                          onTap: (_) => _openSheet(),
                        ),
                    ],
                  ),
                ),
              if (handsOn && _sheet)
                Positioned(
                  key: const ValueKey('hud-sheet'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: _VerdictSheet(
                      picked: _pick,
                      keyFor: _key,
                      onToggle: _togglePick,
                      onSubmit: _submit,
                      onBack: _closeSheet,
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
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck'))
                        : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 236 : (_sheet ? 300 : 84)),
                  onLeft: !coworkerOnScreen || coworkerFromRight,
                ),
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
                  line: M5CableLines.intro,
                  alarm: 'sounds/learn/rush_in.wav',
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

/// A press-and-hold control: a ring fills while held; [onDone] when full,
/// [onEarly] when let go before. Draws nothing while not held (idle = no frames).
class _HoldPad extends StatefulWidget {
  const _HoldPad({super.key, required this.label, required this.ms, required this.enabled, required this.onDone, required this.onEarly, this.button = false});
  final String label;
  final int ms;
  final bool enabled;
  final VoidCallback onDone;
  final VoidCallback onEarly;

  /// Draw a round button (TEST) under the ring.
  final bool button;

  @override
  State<_HoldPad> createState() => _HoldPadState();
}

class _HoldPadState extends State<_HoldPad> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.ms))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _fired = true;
        widget.onDone();
      }
    });
  var _fired = false;
  var _down = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _press() {
    if (!widget.enabled) return;
    _down = true;
    _fired = false;
    HapticFeedback.selectionClick();
    unawaited(_c.forward(from: 0));
  }

  void _release() {
    // The pad may be gone by the time the finger lifts (TEST done → removed).
    if (!_down || !mounted) return;
    _down = false;
    if (!_fired) {
      _c.stop();
      _c.value = 0;
      widget.onEarly();
    } else {
      _c.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _press(),
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: CustomPaint(
          foregroundPainter: _RingPainter(_c),
          child: widget.button
              ? Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(colors: [Color(0xFFE5483C), Color(0xFF9E2219)]),
                      border: Border.all(color: const Color(0xFF2A0E0B), width: 2),
                      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: const Text(M5CableLines.test, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                )
              : const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v) : super(repaint: v);
  final Animation<double> v;

  @override
  void paint(Canvas canvas, Size size) {
    final t = v.value;
    if (t <= 0) return;
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 + 2;
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0x55FFFFFF));
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * t, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = SlmColors.gold300);
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.v);
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final p = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Color.fromRGBO(255, 240, 170, 1 - v);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(c + Offset.fromDirection(a, 4 + 6 * v), c + Offset.fromDirection(a, 8 + 14 * v), p);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.v != v;
}

/// The notebook: the raw rows in the order they were written.
class _Notebook extends StatelessWidget {
  const _Notebook({required this.rows, this.length});
  final List<M5Row> rows;

  /// Round 3: the cable's length.
  final int? length;

  @override
  Widget build(BuildContext context) {
    final style = bangla(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF1E2A36));
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 6),
      decoration: BoxDecoration(
        color: const Color(0xF2F4EEDC),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 2,
        children: [
          Text(M5CableLines.notebook, style: style.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF7A4B12))),
          if (length != null) Text(enDigits('${M5CableLines.lengthWord} $length m'), style: style),
          for (final r in rows) Text(enDigits(r.text), style: style),
        ],
      ),
    );
  }
}

class _PanButton extends StatelessWidget {
  const _PanButton({required this.label, required this.right, required this.onTap});
  final String label;
  final bool right;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(12), border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.7))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(right ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: SlmColors.gold300, size: 24),
              Text(label, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The verdict sheet: every type, every core, always.
class _VerdictSheet extends StatelessWidget {
  const _VerdictSheet({required this.picked, required this.keyFor, required this.onToggle, required this.onSubmit, required this.onBack});
  final Set<M5Fault> picked;
  final GlobalKey Function(Object id) keyFor;
  final ValueChanged<M5Fault> onToggle;
  final ValueChanged<Offset> onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    Widget chip(M5Fault f) {
      final on = picked.contains(f);
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Semantics(
            button: true,
            selected: on,
            label: M5CableLines.chipLabel(f),
            excludeSemantics: true,
            child: GestureDetector(
              key: keyFor(f),
              behavior: HitTestBehavior.opaque,
              onTap: () => onToggle(f),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? const Color(0xFF2B4E7A) : const Color(0xFF16233A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: on ? SlmColors.gold300 : const Color(0xFF3A4A62), width: on ? 2.2 : 1.2),
                ),
                child: Text(M5CableLines.chipCores(f), style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
              ),
            ),
          ),
        ),
      );
    }

    Widget row(M5Kind k) => Row(
          children: [
            SizedBox(
              width: 58,
              child: Text(M5CableLines.kindLabel(k), style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.gold300)),
            ),
            for (final f in M5Fault.values)
              if (f.kind == k) chip(f),
          ],
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Color(0xF20B1324),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [BoxShadow(color: Color(0x88000000), blurRadius: 12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final k in M5Kind.values) row(k),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: M5CableLines.back,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onBack,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF5A6A82))),
                      child: Text(M5CableLines.back, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  button: true,
                  label: M5CableLines.submit,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => onSubmit(d.globalPosition),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: const Color(0xFFB8841E), borderRadius: BorderRadius.circular(12)),
                      child: Text(M5CableLines.submit, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit while in hand.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: SizedBox(
          width: 80,
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
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: on ? 2.4 : 1.7),
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
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
