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
import 'm5_recloser_watch_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm5_recloser_watch_world.dart' show M5Event, M5EventKind, M5Fault, M5RecloserGeo, M5Weather;

// Lesson 5.1 "'লাইন ট্রিপ করেছে'—প্রথম কাজ কী?", কাজ 2 "ট্রিপ মানে ডেড নয়"
// (pack do_5_1_b, engineType m5_recloser_watch). Verb: count recloser shots
// against decoys.
//
// The crew is on a village road at dusk when the whole para goes dark: feeder
// 4 (dealt) has tripped. The operator asks what they see.
//
//  ১ গোনা (watch, 25–60 s): the recloser charges the line 2–3 times (every
//    window and street lamp on together for about a second, a bang and a flash
//    at the fault span, dark again), mixed with 1–2 decoys (lightning in a
//    storm, a motorbike's headlight, one house on its inverter). A tap on the
//    notepad adds a stroke (the player's own tally; a stray tap stays). Then
//    the final trip — lock-out: set the count wheel, tap the span of the flash,
//    জানান. Wrong = a slip, and the operator reads his record; right → ◆ →
//    "লাইনটা এখন কী অবস্থায়?".
//  ২ PTW: hold the radio to ask for the permit — the careless coworker cuts in
//    on the first press with the lesson's myth 1 word for word (the radio waits
//    for him: holdForCoworker). Refused, hold again: "ফিডার 4 আইসোলেট করা
//    হলো। PTW নম্বর 472 — লিখে নিন।" Drag the PTW slip to the trainee → ◆ →
//    "ট্রিপ লাইনে পারমিট (PTW) কেন লাগবে?". Then drag the van to the span of the flash
//    (the tea stall's locals point the way if asked).
//  ৩ আর্থ: at the span: hold the tester on each phase (0 V), hold to drive the
//    earth spike, drag the clamp onto the conductors → ◆ → "ওঠার আগে আর্থ কেন?".
//  ৪ মেরামত: "পোলে উঠুন" → the torch shows the fault → tap it off → pass.
//
// Deadly vs slip (Module 5 table, docs/module_specs/module5_rulings.md):
//   deadly — R1 climbing the tripped line before the PTW is in hand (own tap
//   on "পোলে উঠুন", which stands plain on the pole the whole play, or listening
//   to the coworker); R2 climbing before the tester showed 0 V on every phase;
//   R4 climbing before the earth is on; R5 the clamp on the line before the
//   spike is in.
//   slip — a wrong count / a wrong flash span (one slip per report); driving
//   off on patrol before the PTW (ruling M5-3 card text: inform control, a PTW
//   before any touch or climb); R3 the clamp before the tester proved the line
//   dead (ruling M5-2 card text).
// Three slips strike the level out; a deadly move freezes the scene grey and
// the line comes on in colour (the next reclose, or "ফিডার 4 চার্জ করছি…").
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m5_recloser_watch_world.dart), corner guide, ◆ on the table → "কেন?"
// three times, the coworker's two beats (his recorded voice; the myth line
// needs its clip), gesture hints for every waiting state (how, never what),
// mistake cards with the lesson's points, idle = zero frames. Voice: the guide,
// the operator and the locals by device TTS.

// ============================================================================
// Content
// ============================================================================

/// The play's steps (DoProgress groups them in four).
enum M5RecloserStage { watch, report, ptw, drive, span, climb, done }

/// The span tools (dealt in a row that never reads in a working order).
enum M5RecloserTool { tester, spike, clamp }

/// The three reasons asked.
enum M5RecloserWhy { lockout, ptw, earth }

abstract final class M5RecloserLines {
  static const title = 'ট্রিপ মানে ডেড নয়';
  static const intro = 'সন্ধে নামছে — হঠাৎ পুরো পাড়া অন্ধকার! লাইন ট্রিপ করেছে। চোখ রাখুন।';
  static const stages = ['গোনা', 'PTW', 'আর্থ', 'মেরামত'];

  // The guide's task now (tap him: the same task, a different way). Never
  // names the permit, the tester or the earth before the player acts.
  static const askWatch = 'চোখ রাখুন — লাইন চালু হলেই নোটপ্যাডে দাগ দিন।';
  static const askReport = 'কতবার লাইন চালু হতে দেখলেন? ঝলক কোথায়?';
  static const askPtw = 'লক-আউট হয়েছে। এবার প্রথম কাজ কী?';
  static const askSlip = 'পারমিট নম্বর এসেছে — কাগজটা ট্রেইনির হাতে দিন।';
  static const askDrive = 'এবার ঝলকের জায়গায় চলুন।';
  static const askSpan = 'পৌঁছে গেছেন। এবার কাজ শুরু করুন।';
  static const askClimb = 'এবার ফল্টটা সারান।';
  static const askClear = 'টর্চের আলোয় ফল্টটা সরিয়ে দিন।';
  static const tasks = [askWatch, askReport, askPtw, askSlip, askDrive, askSpan, askClimb, askClear];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const nothingHere = 'এখানে তো কিছু দেখা যাচ্ছে না।';

  // Labels a worker reads.
  static const sceneLabel = 'গ্রামের রাস্তা, 11 kV ফিডার';
  static const notepad = 'নোটপ্যাড';
  static const radio = 'রেডিও';
  static const climb = 'পোলে উঠুন';
  static const report = 'জানান';
  static const countUp = 'বাড়ান';
  static const countDown = 'কমান';
  static const times = 'বার';
  static const van = 'গাড়ি';
  static const stall = 'চায়ের দোকান';
  static const ptwSlip = 'PTW';
  static const dead = '0 V';
  static const phases = ['A', 'B', 'C'];
  static const operatorTag = 'কন্ট্রোল রুম';
  static const localTag = 'চায়ের দোকান';

  static String toolLabel(M5RecloserTool t) => switch (t) {
        M5RecloserTool.tester => 'টেস্টার',
        M5RecloserTool.spike => 'আর্থ স্পাইক',
        M5RecloserTool.clamp => 'ক্ল্যাম্প',
      };

  // The operator (device TTS), dealt phrasings.
  static List<String> opCall(int feeder) => [
        'ফিডার $feeder ট্রিপ করেছে। আপনারা ওখানেই আছেন — কী দেখছেন, জানাবেন।',
        'ফিডার $feeder ট্রিপ! আপনারা তো ওই এলাকাতেই — কী দেখছেন, জানাবেন।',
        'ফিডার $feeder ট্রিপ করল। আপনারা কাছেই আছেন — যা দেখবেন, জানাবেন।',
      ];
  static const opLockout = 'ফাইনাল ট্রিপ — লক-আউট।';
  static String opRecord(int shots, int span) =>
      'রেকর্ডে আছে, রিক্লোজার $shots বার চালু করেছিল। গ্রাহকেরা ${span + 1} আর ${span + 2} নম্বর পোলের মাঝে স্পার্ক দেখেছেন।';
  static const opNoted = 'ঠিক আছে, নোট করলাম।';
  static String opIssue(int feeder, int ptw) => 'ফিডার $feeder আইসোলেট করা হলো। পারমিট নম্বর $ptw — লিখে নিন।';
  static String opCharge(int feeder) => 'ফিডার $feeder চার্জ করছি…';
  static const recloseNow = 'রিক্লোজার আবার লাইন চালু করল…';

  // The locals at the tea stall (device TTS), pointing the way.
  static const locals = [
    'হ্যাঁ, ওই দিকেই আলো ঝলকে উঠে দপ করে নিভে গেল!',
    'ওই দিকে তারে আগুনের মতো ঝলক দেখলাম, তারপর সব অন্ধকার!',
    'ওদিকটায় দুম করে শব্দ হলো, আলো ঝলকে নিভে গেল!',
  ];

  // The reasons (one right is dealt with two myths); 36–45 letters.
  static const whyQ = <M5RecloserWhy, String>{
    M5RecloserWhy.lockout: 'লাইনটা এখন কী অবস্থায়?',
    M5RecloserWhy.ptw: 'ট্রিপ লাইনে পারমিট (PTW) কেন লাগবে?',
    M5RecloserWhy.earth: 'ওঠার আগে আর্থ কেন?',
  };
  static const whyRight = <M5RecloserWhy, List<String>>{
    M5RecloserWhy.lockout: ['লক-আউট হলেও লাইনকে লাইভ ধরে নিতে হবে', 'ট্রিপ মানে ডেড নয়, আবার চালু হতে পারে'],
    M5RecloserWhy.ptw: ['কন্ট্রোল রুম ভুল করে লাইন চালু করে দিতে পারে', 'পারমিট ছাড়া ট্রিপ হওয়া লাইন ছোঁয়া যায় না'],
    M5RecloserWhy.earth: ['বন্ধ লাইনেও চার্জ থাকে, আর্থ তা মাটিতে নামায়', 'পারমিট আর ব্যক্তিগত আর্থিং ছাড়া লাইনে হাত নয়'],
  };
  static const myths = [
    'আলো নিভে গেছে, মানে তারে আর কারেন্ট নেই',
    'লক-আউট মানে লাইন আর কখনো চালু হবে না',
    'অপারেটর তো জানেন, পারমিট পরে নিলেই চলে',
    'রাত নামছে, তাড়াতাড়ি সারাটাই আসল কাজ',
    'রাবারের জুতো পরা থাকলে আর্থ না দিলেও চলে',
    'একটা ফেজে টেস্ট করলেই পুরো লাইন বোঝা যায়',
    'ট্রিপ করা লাইন তো এমনিতেই মরা, ভয় নেই',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  /// The careless coworker, on the first radio press: lesson 5.1 myth 1 word
  /// for word. Listening = climbing the tripped line without a PTW (deadly).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'লাইন তো ট্রিপ করেই আছে, তার মানে ওটা ডেড। তাড়াতাড়ি কাজ সারার জন্য পারমিটের দরকার নেই।',
    exitLine: coworkerExit,
    right: [
      'না, রিক্লোজার যেকোনো সময় লাইন চালু করতে পারে',
      'না, পারমিট আর আর্থিং ছাড়া ট্রিপ লাইনে হাত নয়',
      'না, কন্ট্রোল রুম ভুল করে লাইন চালু করতে পারে',
    ],
    wrong: [
      'ঠিক, লাইন তো মরা — উঠে তাড়াতাড়ি সেরে ফেলি',
      'হ্যাঁ, ট্রিপ লাইন তো ডেড, পারমিট লাগবে না',
      'আচ্ছা, পারমিট পরে নিলেই হবে, আগে উঠে যাই',
      'ঠিক আছে, আলো নিভে আছে, মানে কারেন্ট নেই',
      'হ্যাঁ, অন্ধকার নামছে, পারমিট ছাড়াই সারি',
    ],
    asks: ['ওকে কী বলবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'পারমিট ছাড়া ট্রিপ লাইনে উঠবেন?'],
  );

  /// His lines with no recorded clip yet (the director records them with
  /// tool/rival_clip.py; silent with the caption held until then).
  static List<String> get rivalToRecord => [coworker.line];

  static const callHeld = 'ঠিক! ট্রিপ লাইনকে লাইভ ধরেই কাজ।';
  static const allSet = 'ট্রিপ মানে ডেড নয় — গুনে, পারমিট (PTW) নিয়ে, টেস্ট আর আর্থ করে তবে ওঠা।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — মন দিয়ে গুনুন, আর ট্রিপ লাইনকে লাইভ ধরুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtCount = 'রিক্লোজার কতবার চালু করল, ঠিক গুনেছেন';
  static const caughtLive = 'লক-আউট লাইনকেও লাইভ ধরেছেন';
  static const caughtPtw = 'লাইনে হাত দেওয়ার আগে পারমিট (PTW) হাতে নিয়েছেন';
  static const caughtEarth = 'টেস্টারে 0 V, তারপর আর্থ — তবে ওঠা';
  static const caughtCall = '“পারমিট লাগবে না” — না বলেছেন';
}

abstract final class M5RecloserMistakes {
  static const _dir = 'assets/game/art/m5_recloser_watch';

  /// R1: the tripped line touched or climbed before the PTW (lesson 5.1, point
  /// 2 and myth 1's "মারাত্মক ভুল").
  static const noPtw = DoMistake(
    key: '5.1/m5_recloser_watch/no-ptw',
    textBn: 'ট্রিপ মানে ডেড নয়! রিক্লোজার বা কন্ট্রোল রুম যেকোনো মুহূর্তে লাইন চালু করতে পারে — পারমিট (PTW) আর আর্থিং ছাড়া হাত নয়।',
    art: '$_dir/no_ptw.svg',
    deadly: true,
    lessonPoint: 1,
  );

  /// R2 (M1 step 18, not lesson 5.1's text).
  static const noTest = DoMistake(
    key: '5.1/m5_recloser_watch/no-test',
    textBn: 'পারমিট (PTW) হাতে থাকলেও আগে টেস্টারে প্রতিটি ফেজে 0 V দেখুন — তারপর আর্থ, তবেই ওঠা।',
    art: '$_dir/no_test.svg',
    deadly: true,
  );

  /// R4 (lesson 5.1: "পারমিট (PTW) এবং ব্যক্তিগত আর্থিং ছাড়া … স্পর্শ করা যাবে না").
  static const noEarth = DoMistake(
    key: '5.1/m5_recloser_watch/no-earth',
    textBn: 'টেস্টারে 0 V দেখার পরও আর্থ ছাড়া ওঠা নয় — ব্যক্তিগত আর্থিং লাগিয়ে তবেই পোলে।',
    art: '$_dir/no_earth.svg',
    deadly: true,
    lessonPoint: 1,
  );

  /// R5 (M1 step 15, not lesson 5.1's text).
  static const clampFirst = DoMistake(
    key: '5.1/m5_recloser_watch/clamp-first',
    textBn: 'আগে আর্থ স্পাইক মাটিতে পুঁতুন, তারপর ক্ল্যাম্প তারে — উল্টো ক্রমে কখনো নয়।',
    art: '$_dir/clamp_first.svg',
    deadly: true,
  );

  /// R3 (slip; ruling M5-2's card text).
  static const testFirst = DoMistake(
    key: '5.1/m5_recloser_watch/test-first',
    textBn: 'আগে টেস্টার দিয়ে ডেড প্রমাণ, তারপর আর্থ — এই ক্রম বাধ্যতামূলক।',
    art: '$_dir/test_first.svg',
  );

  /// R6 (slip; ruling M5-3's card text — never a PTW as a legal must for a
  /// ground patrol).
  static const patrolEarly = DoMistake(
    key: '5.1/m5_recloser_watch/patrol-early',
    textBn: 'টহলের আগে কন্ট্রোল রুমকে জানিয়ে ফিল্ড মেমো/ডকেট নিন; লাইনে হাত দেওয়া বা ওঠার আগে পারমিট (PTW) বাধ্যতামূলক।',
    art: '$_dir/patrol_early.svg',
    lessonPoint: 1,
  );

  /// The lock-out report (lesson 5.1 point 1: how many times the recloser
  /// tried; flashes the public saw).
  static const countWrong = DoMistake(
    key: '5.1/m5_recloser_watch/count',
    textBn: 'গোনা ভুল হলো। পুরো পাড়ার আলো একসাথে জ্বলে উঠলে তবেই রিক্লোজার — বাজ, গাড়ির আলো বা একটা বাড়ির আলো নয়।',
    art: '$_dir/count.svg',
    lessonPoint: 0,
  );
  static const spanWrong = DoMistake(
    key: '5.1/m5_recloser_watch/span',
    textBn: 'ঝলকটা অন্য স্প্যানে ছিল। লাইন চালু হওয়ার মুহূর্তে যেখানে ঝলক ওঠে, ফল্ট সেখানেই।',
    art: '$_dir/span.svg',
    lessonPoint: 0,
  );
  static const bothWrong = DoMistake(
    key: '5.1/m5_recloser_watch/count-span',
    textBn: 'গোনা আর ঝলকের জায়গা — দুটোই ভুল। পুরো পাড়ার আলো একসাথে জ্বলা গুনুন, ঝলকটা কোন স্প্যানে দেখুন।',
    art: '$_dir/count.svg',
    lessonPoint: 0,
  );

  static List<DoMistake> get all => [noPtw, noTest, noEarth, clampFirst, testFirst, patrolEarly, countWrong, spanWrong, bothWrong];

  /// The lesson and point each mistake comes from (null point = the module's
  /// earlier lessons: M1 steps 15/18).
  static const sources = <String, String>{
    '5.1/m5_recloser_watch/no-ptw': '5.1 point 2 (PTW) + myth 1 reality',
    '5.1/m5_recloser_watch/no-test': 'M1 step 18 (lessons 1.5/1.6)',
    '5.1/m5_recloser_watch/no-earth': '5.1 myth 1 reality: পারমিট (PTW) এবং ব্যক্তিগত আর্থিং',
    '5.1/m5_recloser_watch/clamp-first': 'M1 step 15 (lesson 1.5)',
    '5.1/m5_recloser_watch/test-first': 'ruling M5-2 (4.1a)',
    '5.1/m5_recloser_watch/patrol-early': '5.1 point 2 + ruling M5-3',
    '5.1/m5_recloser_watch/count': '5.1 point 1 (অটো-রিক্লোজার — কতবার?)',
    '5.1/m5_recloser_watch/span': '5.1 point 1 (আলোর ঝলকানি) + pro tip 3',
    '5.1/m5_recloser_watch/count-span': '5.1 point 1',
  };
}

/// One play's deal.
@immutable
class M5RecloserDeal {
  const M5RecloserDeal({
    required this.weather,
    required this.fault,
    required this.faultSpan,
    required this.events,
    required this.lockAtMs,
    required this.feeder,
    required this.ptw,
  });

  final M5Weather weather;
  final M5Fault fault;

  /// The span of the flash (0–3: between poles span+1 and span+2).
  final int faultSpan;

  /// The watch, in time order (shots and decoys).
  final List<M5Event> events;

  /// The final trip (lock-out), from the start of the watch.
  final int lockAtMs;
  final int feeder;
  final int ptw;

  /// How many times the line came on (the right count).
  int get shots => events.where((e) => e.kind == M5EventKind.shot).length;
  int get decoys => events.length - shots;
}

M5RecloserDeal m5RecloserDeal(math.Random rng) {
  final weather = M5Weather.values[rng.nextInt(3)];
  final fault = switch (weather) {
    M5Weather.storm => M5Fault.branch,
    M5Weather.windy => M5Fault.clash,
    M5Weather.clear => rng.nextBool() ? M5Fault.bird : M5Fault.jumper,
  };
  final shots = 2 + rng.nextInt(2);
  final decoys = 1 + rng.nextInt(2);
  final pool = weather == M5Weather.storm
      ? const [M5EventKind.lightning, M5EventKind.headlight, M5EventKind.inverter]
      : const [M5EventKind.headlight, M5EventKind.inverter];
  final kinds = [
    for (var i = 0; i < shots; i++) M5EventKind.shot,
    for (var i = 0; i < decoys; i++) pool[rng.nextInt(pool.length)],
  ]..shuffle(rng);
  var t = 2500 + rng.nextInt(2000);
  final events = <M5Event>[];
  for (final k in kinds) {
    events.add(M5Event(atMs: t, kind: k, spot: rng.nextInt(5), fromLeft: rng.nextBool()));
    t += 6000 + rng.nextInt(5000);
  }
  final last = events.last;
  var lockAt = last.atMs + last.ms + 4000 + rng.nextInt(4000);
  if (lockAt < 25000) lockAt = 25000 + rng.nextInt(2500);
  return M5RecloserDeal(
    weather: weather,
    fault: fault,
    faultSpan: rng.nextInt(M5RecloserGeo.spans),
    events: List.unmodifiable(events),
    lockAtMs: math.min(lockAt, 60000),
    feeder: 1 + rng.nextInt(9),
    ptw: 100 + rng.nextInt(900),
  );
}

/// The play state (pure logic).
class M5RecloserRun {
  M5RecloserRun(this.deal);
  final M5RecloserDeal deal;

  M5RecloserStage stage = M5RecloserStage.watch;
  int slips = 0;
  int roundSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The step's work is done (its reason comes next).
  var roundDone = false;

  /// Strokes on the notepad (the player's own tally).
  int strokes = 0;

  var reported = false;
  var reportRight = false;
  var ptwIssued = false;
  var ptwInHand = false;
  var _patrolSlip = false;

  /// The span the van stands at (null = by pole 1).
  int? vanSpan;
  int tested = 0;
  var spike = false;
  var clamped = false;
  var aloft = false;
  var cleared = false;

  bool get done => stage == M5RecloserStage.done;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => roundSlips == 0;
  bool get _open => !ended && !roundDone;

  /// The DoProgress step (0–3; 4 = done).
  int get group => switch (stage) {
        M5RecloserStage.watch || M5RecloserStage.report => 0,
        M5RecloserStage.ptw || M5RecloserStage.drive => 1,
        M5RecloserStage.span => 2,
        M5RecloserStage.climb => 3,
        M5RecloserStage.done => 4,
      };

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlips++;
    return m;
  }

  /// A tap on the notepad during the watch.
  void stroke() {
    if (!ended && stage == M5RecloserStage.watch) strokes++;
  }

  /// The final trip: the report comes next.
  void lockOut() {
    if (!ended && stage == M5RecloserStage.watch) stage = M5RecloserStage.report;
  }

  /// The lock-out report: how many times the line came on and the flash's
  /// span. One slip per report; right → its reason.
  DoMistake? report(int count, int span) {
    if (!_open || stage != M5RecloserStage.report || reported) return null;
    reported = true;
    final c = count == deal.shots, s = span == deal.faultSpan;
    if (c && s) {
      reportRight = true;
      roundDone = true;
      _tag(M5RecloserLines.caughtCount);
      return null;
    }
    return _slip(!c && !s ? M5RecloserMistakes.bothWrong : (!c ? M5RecloserMistakes.countWrong : M5RecloserMistakes.spanWrong));
  }

  /// The radio answered with the PTW (the page holds the first press for the
  /// coworker). True when issued now.
  bool radio() {
    if (!_open || stage != M5RecloserStage.ptw || ptwIssued) return false;
    ptwIssued = true;
    return true;
  }

  /// The PTW slip handed to the trainee.
  bool takePtw() {
    if (!_open || stage != M5RecloserStage.ptw || !ptwIssued || ptwInHand) return false;
    ptwInHand = true;
    roundDone = true;
    _tag(M5RecloserLines.caughtLive);
    if (!_patrolSlip) _tag(M5RecloserLines.caughtPtw);
    return true;
  }

  /// The van dragged to [span]. Before the PTW = a slip (it stays by pole 1);
  /// at the fault span the crew is there (the span step begins).
  DoMistake? drive(int span) {
    if (ended) return null;
    switch (stage) {
      case M5RecloserStage.report || M5RecloserStage.ptw:
        if (roundDone) return null;
        _patrolSlip = true;
        return _slip(M5RecloserMistakes.patrolEarly);
      case M5RecloserStage.drive:
        vanSpan = span;
        if (span == deal.faultSpan) next();
        return null;
      default:
        return null;
    }
  }

  /// At the van's span is the fault (the tools are there).
  bool get atFault => vanSpan == deal.faultSpan;

  /// The tester held to the next phase.
  void test() {
    if (_open && stage == M5RecloserStage.span && tested < 3) tested++;
  }

  /// The earth spike driven in.
  void driveSpike() {
    if (_open && stage == M5RecloserStage.span) spike = true;
  }

  /// The earth clamp onto the conductors.
  DoMistake? clamp() {
    if (!_open || stage != M5RecloserStage.span || clamped) return null;
    if (!spike) return deadly = M5RecloserMistakes.clampFirst;
    if (tested < 3) return _slip(M5RecloserMistakes.testFirst);
    clamped = true;
    roundDone = true;
    if (thorough) _tag(M5RecloserLines.caughtEarth);
    return null;
  }

  /// "পোলে উঠুন" — the plain sign on the pole, there the whole play.
  DoMistake? climb() {
    if (ended || aloft || roundDone) return null;
    if (!ptwInHand) return deadly = M5RecloserMistakes.noPtw;
    if (tested < 3) return deadly = M5RecloserMistakes.noTest;
    if (!clamped) return deadly = M5RecloserMistakes.noEarth;
    aloft = true;
    return null;
  }

  /// The fault taken off the line (aloft, at the fault span).
  bool clearFault() {
    if (!_open || stage != M5RecloserStage.climb || !aloft || cleared) return false;
    cleared = true;
    stage = M5RecloserStage.done;
    return true;
  }

  /// Fails the play (listening to the coworker).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    if (done) return;
    stage = M5RecloserStage.values[stage.index + 1];
    roundSlips = 0;
    roundDone = false;
  }
}

/// The quick bonus: the play after the watch (the watch is dealt, 25–60 s)
/// a little under a thorough play (~85 %). ms, ~1500 per human action:
///   report: wheel + span + জানান ≈ 6000 + reason ~8200
///   PTW: hold, the coworker ~9600, hold, the operator ~4000, drag ≈ 17000
///        + reason ~8200; drive ≈ 3000
///   span: 3 tester holds, spike, clamp ≈ 8000 + reason ~8200
///   climb + clear ≈ 3000                                    ≈ 71600
/// 85 % ≈ 61000 → 70 s (after the lock-out).
const m5RecloserQuickMs = 70000;

/// A stop at a span with no flash: the van idles this long before it can
/// move again (a needless stop costs time; the report already scored the span).
const m5RecloserWrongStopMs = 2000;

/// The span tools in a row that never reads left to right in a working order.
List<M5RecloserTool> m5RecloserToolRow(math.Random rng) {
  final tools = [...M5RecloserTool.values];
  do {
    tools.shuffle(rng);
  } while (m5RecloserInWorkOrder(tools));
  return tools;
}

/// True if tapping [row] left to right would be a right play (the clamp last:
/// tester then spike, or spike then tester, both work).
bool m5RecloserInWorkOrder(List<M5RecloserTool> row) => row.last == M5RecloserTool.clamp;

@immutable
class M5RecloserPack {
  const M5RecloserPack({required this.id, required this.titleBn, this.quickMs = m5RecloserQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5RecloserPack> m5RecloserPacks = {
  'do_5_1_b': M5RecloserPack(id: 'do_5_1_b', titleBn: M5RecloserLines.title),
};

/// Test hook: the live deal and step.
class M5RecloserProbe {
  M5RecloserDeal? deal;
  M5RecloserStage? stage;
  bool watching = false;
}

// ============================================================================
// Page
// ============================================================================

class M5RecloserPage extends StatefulWidget {
  const M5RecloserPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.probe});

  final LevelContext ctx;
  final M5RecloserPack pack;
  final bool muted;
  final int? seed;
  final M5RecloserProbe? probe;

  @override
  State<M5RecloserPage> createState() => _M5RecloserPageState();
}

class _M5RecloserPageState extends State<M5RecloserPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _RecloserRunPage(
        key: ValueKey(_round),
        ctx: widget.ctx,
        pack: widget.pack,
        muted: _muted,
        probe: widget.probe,
        rng: widget.seed == null ? math.Random() : math.Random(widget.seed! + _round),
        onRetry: (m) => setState(() {
          _muted = m;
          _round++;
        }),
      );
}

class _RecloserRunPage extends ConsumerStatefulWidget {
  const _RecloserRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry, this.probe});

  final LevelContext ctx;
  final M5RecloserPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;
  final M5RecloserProbe? probe;

  @override
  ConsumerState<_RecloserRunPage> createState() => _RecloserRunPageState();
}

enum _Hold { radio, tester, spike }

class _RecloserRunPageState extends ConsumerState<_RecloserRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5RecloserRun _run;
  late final List<M5RecloserTool> _tools;
  late final String _callLine;
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

  // The watch.
  var _lit = true;
  var _watching = false;
  var _demo = false;
  Timer? _watchTimer;
  Timer? _eventTimer;
  // Clock reading at the lock-out: the quick window runs from here.
  int? _lockClockMs;
  // A needless stop costs time: the van idles before it can move again.
  Timer? _vanRestTimer;
  var _vanResting = false;
  M5Event? _event;
  late final AnimationController _ev = AnimationController(vsync: this);

  // The report.
  int? _count;
  int? _span;
  double _wheelDrag = 0;

  // The operator / the locals (a bubble while they speak; device TTS).
  String? _opLine;
  var _opBusy = false;
  int _opTok = 0;
  String? _localLine;
  int _localN = 0;
  int _localTok = 0;

  // The PTW.
  var _radioPressed = false;
  Offset? _ptwDragAt;

  // The van (design px while dragged).
  double? _vanDrag;

  // Holds (radio, tester, spike) and the clamp drag.
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  _Hold? _holding;
  Offset? _clampAt;

  // The deadly consequence.
  var _freeze = false;
  var _climbShown = false;
  String? _consequence;
  Offset? _arcAt;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // The gesture hand.
  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  final _wheelKey = GlobalKey();
  final _reportKey = GlobalKey();
  final _radioKey = GlobalKey();
  final _slipKey = GlobalKey();
  final _vanKey = GlobalKey();
  final _traineeKey = GlobalKey();
  final Map<M5RecloserTool, GlobalKey> _toolKeys = {for (final t in M5RecloserTool.values) t: GlobalKey()};
  M5RecloserGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    // The deal first (a seed's play is the same), then the tool row.
    _run = M5RecloserRun(m5RecloserDeal(widget.rng));
    _tools = m5RecloserToolRow(widget.rng);
    final calls = M5RecloserLines.opCall(_run.deal.feeder);
    _callLine = calls[widget.rng.nextInt(calls.length)];
    _localN = widget.rng.nextInt(M5RecloserLines.locals.length);
    _ev.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _event = null);
        _ev.value = 0;
      }
    });
    _hold.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) _holdDone();
    });
    _probe();
  }

  void _probe() {
    final p = widget.probe;
    if (p == null) return;
    p.deal = _run.deal;
    p.stage = _run.stage;
    p.watching = _watching;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _watchTimer?.cancel();
    _eventTimer?.cancel();
    _vanRestTimer?.cancel();
    _ev.dispose();
    _hold.dispose();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _probe();
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

  /// The operator on the radio: his bubble while he speaks (device TTS),
  /// held for a reading time when muted. The scene is voice-locked meanwhile.
  Future<void> _operator(String line) async {
    final tok = ++_opTok;
    _hush();
    _cue('sounds/intro/click.ogg', volume: 0.5);
    setState(() {
      _opLine = line;
      _opBusy = true;
    });
    final clock = Stopwatch()..start();
    await MascotSpeechLibrary.speak(line, muted: _muted, pitch: 0.82);
    if (_muted) {
      final rest = math.min(2600, MascotSpeechLibrary.readHold(line).inMilliseconds) - clock.elapsedMilliseconds;
      if (rest > 0) await Future<void>.delayed(Duration(milliseconds: rest));
    }
    if (!mounted || tok != _opTok) return;
    setState(() {
      _opBusy = false;
      _opLine = null;
    });
  }

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze && !_opBusy;

  String get _task => switch (_run.stage) {
        M5RecloserStage.watch => M5RecloserLines.askWatch,
        M5RecloserStage.report => M5RecloserLines.askReport,
        M5RecloserStage.ptw => _run.ptwIssued ? M5RecloserLines.askSlip : M5RecloserLines.askPtw,
        M5RecloserStage.drive => M5RecloserLines.askDrive,
        M5RecloserStage.span => M5RecloserLines.askSpan,
        M5RecloserStage.climb => _run.aloft ? M5RecloserLines.askClear : M5RecloserLines.askClimb,
        M5RecloserStage.done => M5RecloserLines.allSet,
      };

  // --- the watch ----------------------------------------------------------------
  Future<void> _start() async {
    _clock.start();
    // The para goes dark.
    _cue('sounds/learn/dull_steel.ogg', volume: 0.5);
    setState(() {
      _lit = false;
      _wake++;
    });
    await _operator(_callLine);
    if (!mounted || _ended) return;
    // One-time demo: a stroke on the notepad, then rubbed out.
    setState(() => _demo = true);
    _cue('sounds/intro/tick.ogg', volume: 0.4);
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted || _ended) return;
    setState(() => _demo = false);
    unawaited(_sayChain([M5RecloserLines.askWatch]));
    _beginWatch();
  }

  void _beginWatch() {
    setState(() => _watching = true);
    _schedule(0, 0);
  }

  /// Plays event [i] (the previous one started at [prevMs]), then the next.
  void _schedule(int i, int prevMs) {
    final ev = _run.deal.events;
    if (_ended) return;
    if (i >= ev.length) {
      _watchTimer = Timer(Duration(milliseconds: math.max(0, _run.deal.lockAtMs - prevMs)), _lockOut);
      return;
    }
    _watchTimer = Timer(Duration(milliseconds: math.max(0, ev[i].atMs - prevMs)), () {
      if (!mounted || _ended) return;
      _play(ev[i]);
      _schedule(i + 1, ev[i].atMs);
    });
  }

  void _play(M5Event e) {
    switch (e.kind) {
      case M5EventKind.shot:
        _cue('sounds/learn/spark.ogg', volume: 0.8);
        _eventTimer?.cancel();
        _eventTimer = Timer(Duration(milliseconds: (e.ms * 0.66).round()), () => _cue('sounds/intro/impact_metal.ogg', volume: 0.9));
      case M5EventKind.lightning:
        _cue('sounds/learn/thunder_near.ogg', volume: 0.8);
      case M5EventKind.headlight:
        _cue('sounds/learn/wind_gust.ogg', volume: 0.35);
      case M5EventKind.inverter:
        _cue('sounds/intro/click.ogg', volume: 0.4);
    }
    setState(() => _event = e);
    if (_quiet) {
      // Reduced motion: one still frame of the event for its length.
      _ev.value = switch (e.kind) {
        M5EventKind.shot => 0.69,
        M5EventKind.lightning => 0.1,
        M5EventKind.headlight || M5EventKind.inverter => 0.5,
      };
      Timer(Duration(milliseconds: e.ms), () {
        if (!mounted || _event != e) return;
        setState(() => _event = null);
        _ev.value = 0;
      });
    } else {
      _ev.duration = Duration(milliseconds: e.ms);
      unawaited(_ev.forward(from: 0));
    }
  }

  void _lockOut() {
    if (!mounted || _ended || _run.stage != M5RecloserStage.watch) return;
    _run.lockOut();
    _lockClockMs = _clock.elapsedMilliseconds;
    setState(() {
      _watching = false;
      _wake++;
    });
    unawaited(() async {
      await _operator(M5RecloserLines.opLockout);
      if (!mounted || _ended) return;
      unawaited(_sayChain([M5RecloserLines.askReport], mood: GuideMood.think));
    }());
  }

  void _tapNotepad() {
    if (_intro || _ended || _freeze || _card != null || _run.stage != M5RecloserStage.watch || !_watching) {
      _hints.missTap();
      return;
    }
    _tick('sounds/intro/tick.ogg', 0.5);
    setState(_run.stroke);
  }

  // --- the report ---------------------------------------------------------------
  bool get _reporting => _run.stage == M5RecloserStage.report && !_run.reported;

  void _stepCount(int d) {
    if (!_canPlay || !_reporting) return;
    _tick('sounds/learn/tick.ogg', 0.4);
    setState(() => _count = ((_count ?? 0) + d).clamp(0, 6));
  }

  void _wheelUpdate(double dy) {
    if (!_canPlay || !_reporting) return;
    _wheelDrag += dy;
    while (_wheelDrag <= -22) {
      _wheelDrag += 22;
      _stepCount(1);
    }
    while (_wheelDrag >= 22) {
      _wheelDrag -= 22;
      _stepCount(-1);
    }
  }

  Future<void> _sendReport(Offset global) async {
    final c = _count, s = _span;
    if (!_canPlay || !_reporting || c == null || s == null) return;
    _tick('sounds/intro/confirm.ogg', 0.6);
    final m = _run.report(c, s);
    setState(() => _wake++);
    if (m != null) {
      await _mistake(m, global);
      return;
    }
    unawaited(_operator(M5RecloserLines.opNoted).then((_) {
      if (mounted && !_ended) _stepDone(M5RecloserWhy.lockout);
    }));
  }

  /// After a wrong report: the operator reads his record; the play goes on.
  Future<void> _readRecord() async {
    await _operator(M5RecloserLines.opRecord(_run.deal.shots, _run.deal.faultSpan));
    if (!mounted || _ended) return;
    setState(() {
      _count = _run.deal.shots;
      _span = _run.deal.faultSpan;
    });
    _next();
  }

  // --- the PTW ------------------------------------------------------------------
  void _holdStart(_Hold h) {
    if (!_canPlay || _holding != null) return;
    switch (h) {
      case _Hold.radio:
        if (_run.stage != M5RecloserStage.ptw || _run.ptwIssued) {
          _hints.missTap();
          return;
        }
        _radioPressed = true;
        // The first press: he cuts in, the radio waits for him.
        if (holdForCoworker()) return;
      case _Hold.tester:
        if (_run.tested >= 3) return;
      case _Hold.spike:
        if (_run.spike) return;
    }
    _cue(h == _Hold.radio ? 'sounds/intro/click.ogg' : 'sounds/learn/tick.ogg', volume: 0.4);
    setState(() => _holding = h);
    if (_quiet) {
      _holdDone();
    } else {
      unawaited(_hold.forward(from: 0));
    }
  }

  void _holdEnd() {
    if (_holding == null) return;
    _hold.stop();
    _hold.value = 0;
    setState(() => _holding = null);
  }

  void _holdDone() {
    final h = _holding;
    _hold.value = 0;
    setState(() => _holding = null);
    if (h == null || !_canPlay) return;
    switch (h) {
      case _Hold.radio:
        if (!_run.radio()) return;
        HapticFeedback.lightImpact();
        unawaited(() async {
          await _operator(M5RecloserLines.opIssue(_run.deal.feeder, _run.deal.ptw));
          if (!mounted || _ended) return;
          unawaited(_sayChain([M5RecloserLines.askSlip]));
        }());
      case _Hold.tester:
        _run.test();
        _cue('sounds/learn/dmm_beep.ogg', volume: 0.6);
        setState(() => _wake++);
      case _Hold.spike:
        _run.driveSpike();
        _cue('sounds/learn/knock_solid.ogg', volume: 0.7);
        setState(() => _wake++);
    }
  }

  Rect? _globalOf(GlobalKey k, {double inflate = 0}) => HintSpec.globalRectOf(k)?.inflate(inflate);

  void _ptwDrag(Offset global) {
    if (!_canPlay || !_run.ptwIssued || _run.ptwInHand) return;
    setState(() => _ptwDragAt = global);
  }

  void _ptwDrop() {
    final at = _ptwDragAt;
    setState(() => _ptwDragAt = null);
    if (at == null || !_canPlay) return;
    final to = _globalOf(_traineeKey, inflate: 28);
    if (to == null || !to.contains(at)) return;
    if (!_run.takePtw()) return;
    _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
    _stepDone(M5RecloserWhy.ptw);
  }

  // --- the van --------------------------------------------------------------------
  bool get _vanMovable =>
      _canPlay &&
      !_vanResting &&
      (_run.stage == M5RecloserStage.report || _run.stage == M5RecloserStage.ptw || _run.stage == M5RecloserStage.drive);

  void _vanUpdate(double dx, M5RecloserGeo geo) {
    if (!_vanMovable) return;
    setState(() => _vanDrag = ((_vanDrag ?? geo.vanX(_run.vanSpan)) + dx).clamp(20.0, 340.0));
  }

  void _vanEnd(M5RecloserGeo geo, Offset global) {
    final x = _vanDrag;
    if (x == null) return;
    final from = geo.vanX(_run.vanSpan);
    if (!_vanMovable || (x - from).abs() < 14) {
      setState(() => _vanDrag = null);
      return;
    }
    var best = 0;
    for (var i = 1; i < M5RecloserGeo.spans; i++) {
      if ((geo.vanX(i) - x).abs() < (geo.vanX(best) - x).abs()) best = i;
    }
    _cue('sounds/van_arrive.ogg', volume: 0.5);
    final m = _run.drive(best);
    setState(() {
      _vanDrag = null;
      _wake++;
    });
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    if (_run.stage == M5RecloserStage.span) {
      unawaited(_sayChain([M5RecloserLines.askSpan]));
    } else {
      // A needless stop: the van idles a moment before it can move again.
      _vanRestTimer?.cancel();
      setState(() => _vanResting = true);
      _vanRestTimer = Timer(const Duration(milliseconds: m5RecloserWrongStopMs), () {
        if (mounted) setState(() => _vanResting = false);
      });
      unawaited(_sayChain([M5RecloserLines.nothingHere, M5RecloserLines.askDrive]));
    }
  }

  void _askLocals() {
    _tick();
    final line = M5RecloserLines.locals[_localN++ % M5RecloserLines.locals.length];
    final tok = ++_localTok;
    setState(() => _localLine = line);
    _hush();
    unawaited(() async {
      final clock = Stopwatch()..start();
      await MascotSpeechLibrary.speak(line, muted: _muted, pitch: 1.12);
      final rest = math.min(2600, MascotSpeechLibrary.readHold(line).inMilliseconds) - clock.elapsedMilliseconds;
      if (rest > 0) await Future<void>.delayed(Duration(milliseconds: rest));
      if (mounted && tok == _localTok) setState(() => _localLine = null);
    }());
  }

  // --- the span -------------------------------------------------------------------
  void _clampDrag(Offset global) {
    if (!_canPlay || _run.stage != M5RecloserStage.span || _run.clamped) return;
    setState(() => _clampAt = global);
  }

  void _clampDrop(M5RecloserGeo geo) {
    final at = _clampAt;
    setState(() => _clampAt = null);
    if (at == null || !_canPlay) return;
    final span = _run.vanSpan;
    if (span == null) return;
    final to = _sceneRect(geo.spanHit(span).inflate(10));
    if (to == null || !to.contains(at)) return;
    _cue('sounds/learn/ring_steel.ogg', volume: 0.6);
    final m = _run.clamp();
    setState(() {
      _wake++;
      if (m != null && m.deadly) _arcAt = Offset(M5RecloserGeo.poleX[geo.poleOf(span)] + 14, geo.wireY(2, M5RecloserGeo.poleX[geo.poleOf(span)] + 14));
    });
    if (m != null) {
      unawaited(_mistake(m, at));
      return;
    }
    _stepDone(M5RecloserWhy.earth);
  }

  // --- the climb ------------------------------------------------------------------
  void _tapClimb(M5RecloserGeo geo, Offset global) {
    if (!_canPlay) return;
    if (_run.stage == M5RecloserStage.watch && !_watching) return;
    _tick('sounds/intro/click.ogg', 0.5);
    final m = _run.climb();
    final pole = geo.poleOf(_run.vanSpan);
    if (m != null) {
      setState(() {
        _climbShown = true;
        final box = geo.aloft(pole);
        _arcAt = Offset(box.center.dx, box.top + 8);
      });
      unawaited(_mistake(m, global));
      return;
    }
    if (!_run.aloft) return;
    _cue('sounds/learn/stomp.ogg', volume: 0.5);
    setState(() => _wake++);
    unawaited(_sayChain([M5RecloserLines.askClear]));
  }

  void _tapScene(Offset p, M5RecloserGeo geo, Offset global) {
    if (!_canPlay) {
      if (_watching && _card == null && !_freeze) _hints.missTap();
      return;
    }
    switch (_run.stage) {
      case M5RecloserStage.report:
        for (var i = 0; i < M5RecloserGeo.spans; i++) {
          if (geo.spanHit(i).contains(p) && _reporting) {
            _tick();
            setState(() => _span = i);
            return;
          }
        }
      case M5RecloserStage.drive || M5RecloserStage.span:
        if (geo.stall.inflate(6).contains(p)) {
          _askLocals();
          return;
        }
      case M5RecloserStage.climb:
        if (_run.aloft && geo.spanHit(_run.deal.faultSpan).contains(p)) {
          if (_run.clearFault()) {
            HapticFeedback.mediumImpact();
            _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
            _cue('sounds/quiz_right.ogg', volume: 0.6);
            setState(() => _wake++);
            unawaited(Future<void>.delayed(const Duration(milliseconds: 900), () {
              if (mounted && !_ended) unawaited(_finish());
            }));
          }
          return;
        }
      default:
        break;
    }
    _hints.missTap();
  }

  // --- the steps ----------------------------------------------------------------
  /// A step's work is done: ◆ on the table, then its reason.
  void _stepDone(M5RecloserWhy why) {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final stage = _run.stage;
    unawaited(askReason(
      deal: () => dealChoices(M5RecloserLines.whyRight[why]!, M5RecloserLines.myths, widget.rng),
      question: M5RecloserLines.whyQ[why]!,
      stillValid: () => _run.stage == stage && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startStage();
  }

  void _startStage() {
    setState(() => _wake++);
    if (_run.stage == M5RecloserStage.ptw) scheduleCoworker();
    unawaited(_sayChain([_task]));
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
    final stage = _run.stage;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.stage == stage) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M5RecloserLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.stage != M5RecloserStage.ptw || _run.ptwIssued) return null;
    if (_intro || _card != null || tableBusy || _freeze || _opBusy) return false;
    // He waits for the first press of the radio.
    return _radioPressed;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: up the tripped line without a permit.
      _run.failDeadly(M5RecloserMistakes.noPtw);
      final geo = _geoNow;
      if (geo != null) {
        final box = geo.aloft(geo.poleOf(_run.vanSpan));
        setState(() {
          _climbShown = true;
          _arcAt = Offset(box.center.dx, box.top + 8);
        });
      }
      await _deadly(M5RecloserMistakes.noPtw);
      return;
    }
    _run.caught.add(M5RecloserLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M5RecloserLines.callHeld, M5RecloserLines.askPtw], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5RecloserLines.tapWhy[_nudgeN++ % M5RecloserLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _stopWatch();
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  void _stopWatch() {
    _watchTimer?.cancel();
    _eventTimer?.cancel();
    _ev.stop();
    _ev.value = 0;
    _event = null;
    _watching = false;
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
    final speak = await SpokenOnce.first('recloser/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly move: the scene freezes grey and the line comes on in colour
  /// (the next reclose, or the control room's charge); then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    final beforeLockout = _run.stage == M5RecloserStage.watch;
    _stopWatch();
    _clock.stop();
    _hush();
    _holding = null;
    _hold.value = 0;
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _opLine = null;
      _opBusy = false;
      _localLine = null;
      _consequence = beforeLockout ? M5RecloserLines.recloseNow : M5RecloserLines.opCharge(_run.deal.feeder);
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
    final speak = await SpokenOnce.first('recloser/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5RecloserLines.deadlyWord : M5RecloserLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        final wrongReport = _run.stage == M5RecloserStage.report && _run.reported && !_run.reportRight;
        setState(() {
          _card = null;
          _wake++;
        });
        if (wrongReport) {
          unawaited(_readRecord());
        } else {
          unawaited(_sayChain([_task]));
        }
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

  /// The quick clock runs from the lock-out (the watch is dealt).
  bool get _quick => _clock.elapsedMilliseconds - (_lockClockMs ?? 0) < widget.pack.quickMs;

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
      if (mark == 100 && _quick) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _quick);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? M5RecloserLines.fail : (_quickBonus ? M5RecloserLines.quick : M5RecloserLines.allSet),
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
    if (_run.aloft || _climbShown) return LinemanMode.hold;
    if (_holding == _Hold.tester || _holding == _Hold.spike) return LinemanMode.hold;
    if (_run.stage == M5RecloserStage.watch && _watching) return LinemanMode.point;
    return LinemanMode.idle;
  }

  M5RecloserRig get _rig => M5RecloserRig(
        weather: _run.deal.weather,
        fault: _run.deal.fault,
        faultSpan: _run.deal.faultSpan,
        lit: _lit,
        night: _run.stage.index >= M5RecloserStage.drive.index,
        torch: _run.aloft,
        cleared: _run.cleared,
        pole: _run.vanSpan ?? 0,
        spike: _run.spike,
        clamp: _run.clamped,
        tested: _run.tested,
      );

  /// A design-px rect of the scene on screen (null before layout).
  Rect? _sceneRect(Rect r) {
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return Rect.fromPoints(box.localToGlobal(r.topLeft), box.localToGlobal(r.bottomRight));
  }

  /// The gesture hand for the waiting state: how to touch, never what.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    switch (_run.stage) {
      case M5RecloserStage.report:
        if (_count == null) {
          final w = HintSpec.globalRectOf(_wheelKey);
          return w == null ? null : HintSpec.swipe(w.center, toward: const Offset(0, -1), travel: 60);
        }
        if (_span == null) {
          final rects = [for (var i = 0; i < M5RecloserGeo.spans; i++) ?_sceneRect(geo.spanHit(i))];
          return rects.length < 2 ? null : HintSpec.sweep(rects);
        }
        return HintSpec.tapOn(_reportKey);
      case M5RecloserStage.ptw:
        if (!_run.ptwIssued) {
          // Radio and van are both live here (the climb sign is never hinted):
          // a sweep over both shows what can be touched, never which is right.
          final rects = [?HintSpec.globalRectOf(_radioKey), ?HintSpec.globalRectOf(_vanKey)];
          return rects.length < 2 ? null : HintSpec.sweep(rects);
        }
        return HintSpec.dragFrom(_slipKey, toward: const Offset(-1, -1));
      case M5RecloserStage.drive:
        return HintSpec.dragFrom(_vanKey, toward: const Offset(1, 0));
      case M5RecloserStage.span:
        final rects = [for (final t in _tools) ?HintSpec.globalRectOf(_toolKeys[t]!)];
        return rects.length < 2 ? null : HintSpec.sweep(rects);
      case M5RecloserStage.climb:
        // "পোলে উঠুন" is never hinted; aloft, the fault is the one thing to tap.
        if (!_run.aloft) return null;
        final r = _sceneRect(geo.spanHit(_run.deal.faultSpan));
        return r == null ? null : HintSpec.tap(r.center);
      default:
        return null;
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5RecloserGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final rig = _rig;
    final pole = geo.poleOf(_run.vanSpan);
    final vanX = _vanDrag ?? geo.vanX(_run.vanSpan);
    final van = geo.vanRect(vanX);
    final up = _run.aloft || _climbShown;
    final tb = up ? geo.aloft(pole) : geo.ground(vanX);
    final dragging = _vanDrag != null;
    final dur = dragging || quiet ? Duration.zero : const Duration(milliseconds: 650);
    final local = _localLine;
    final showClimb = !_intro && !up && !_run.done;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('village'),
                child: RepaintBoundary(child: CustomPaint(painter: M5RecloserPainter(geo: geo, rig: rig))),
              ),
              Positioned.fill(
                key: const ValueKey('event'),
                child: IgnorePointer(
                  child: RepaintBoundary(child: CustomPaint(painter: M5EventPainter(geo: geo, rig: rig, event: _event, t: _ev))),
                ),
              ),
              AnimatedPositioned(
                key: const ValueKey('van'),
                duration: dur,
                curve: Curves.easeInOut,
                left: van.left,
                top: van.top,
                width: van.width,
                height: van.height,
                child: KeyedSubtree(key: _vanKey, child: const CustomPaint(painter: M5VanPainter())),
              ),
              AnimatedPositioned(
                key: const ValueKey('trainee'),
                duration: dur,
                curve: Curves.easeInOut,
                left: tb.left,
                top: tb.top,
                width: tb.width,
                height: tb.height,
                child: IgnorePointer(
                  child: KeyedSubtree(
                    key: _traineeKey,
                    child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                  ),
                ),
              ),
              for (var p = 0; p < _run.tested; p++)
                Positioned(
                  key: ValueKey('reading-$p'),
                  left: math.max(2.0, M5RecloserGeo.poleX[pole] - 48),
                  top: geo.wireY(p, M5RecloserGeo.poleX[pole]) + 4 + p * 8,
                  child: IgnorePointer(child: _Reading(text: '${M5RecloserLines.phases[p]} ${M5RecloserLines.dead}')),
                ),
            ],
          ),
        ),
      ),
      // The player's own span pick (the report).
      if (_span != null && _reporting && !_freeze)
        Positioned.fromRect(
          key: ValueKey('pick-$_span'),
          rect: geo.spanHit(_span!),
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFE08A), width: 2)),
            ),
          ),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5RecloserLines.sceneLabel,
          child: GestureDetector(
            key: _touchKey,
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
          ),
        ),
      ),
      // The van over the touch layer (it is dragged).
      AnimatedPositioned(
        key: const ValueKey('van-grip'),
        duration: dur,
        curve: Curves.easeInOut,
        left: van.left,
        top: van.top,
        width: van.width,
        height: van.height,
        child: Semantics(
          label: M5RecloserLines.van,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onPanUpdate: (d) => _vanUpdate(d.delta.dx, geo),
            onPanEnd: (_) => _vanEnd(geo, _sceneRect(van)?.center ?? Offset.zero),
          ),
        ),
      ),
      if (showClimb)
        Positioned.fromRect(
          key: ValueKey('climb-$pole'),
          rect: geo.climbSign(pole),
          child: _ClimbSign(onTap: (g) => _tapClimb(geo, g)),
        ),
      if (local != null && !_freeze)
        Positioned(
          key: ValueKey('local-$_localTok'),
          left: (geo.stall.center.dx - 90).clamp(6.0, 174.0),
          top: geo.stall.top - 66,
          width: 180,
          child: IgnorePointer(
            child: _LocalBubble(text: local, pointLeft: geo.spanMid(_run.deal.faultSpan).dx < geo.stall.center.dx),
          ),
        ),
      if (_freeze && _arcAt != null)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 0.5 : 0, end: quiet ? 0.5 : 1),
              duration: const Duration(milliseconds: 1600),
              builder: (_, v, _) => CustomPaint(painter: M5ArcPainter(at: _arcAt!, v: v)),
            ),
          ),
        ),
      if (_freeze && _consequence != null)
        Positioned(
          key: const ValueKey('consequence'),
          left: 30,
          right: 30,
          top: geo.topY - 70,
          child: IgnorePointer(child: _RadioBubble(tag: M5RecloserLines.operatorTag, text: _consequence!)),
        ),
      // The next step: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('step-${_run.group}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.group == 0 ? 0 : 0.5, end: 0),
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
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOnScreen && _card == null && !_opBusy;
    final stage = _run.stage;
    final hintWaiting = handsOn &&
        !tableBusy &&
        _holding == null &&
        _ptwDragAt == null &&
        _clampAt == null &&
        _vanDrag == null &&
        stage != M5RecloserStage.watch &&
        !(stage == M5RecloserStage.climb && !_run.aloft) &&
        !(stage == M5RecloserStage.report && _run.reported);
    final showPad = playing && stage.index <= M5RecloserStage.drive.index && !deckUp;
    final showRadio = showPad;
    final showWheel = handsOn && _reporting;
    final showTools = handsOn && stage == M5RecloserStage.span && _run.atFault;
    final showSlip = handsOn && stage == M5RecloserStage.ptw && _run.ptwIssued && !_run.ptwInHand;
    final opLine = _opLine;
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
              labels: M5RecloserLines.stages,
              done: {for (var i = 0; i < math.min(_run.group, 4); i++) i},
              current: _run.done ? null : _run.group,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: hintWaiting,
            hintKey: '${stage.name}/${_count != null}/${_span != null}/${_run.ptwIssued}/${_run.vanSpan}/${_run.tested}/${_run.spike}/${_run.aloft}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (showPad)
                Positioned(
                  key: const ValueKey('hud-notepad'),
                  left: 8,
                  bottom: pad.bottom + 10,
                  child: _Notepad(strokes: _run.strokes, demo: _demo, onTap: _tapNotepad),
                ),
              if (showRadio)
                Positioned(
                  key: const ValueKey('hud-radio'),
                  right: 8,
                  bottom: pad.bottom + 10,
                  child: Listener(
                    key: _radioKey,
                    onPointerDown: (_) => _holdStart(_Hold.radio),
                    onPointerUp: (_) => _holdEnd(),
                    onPointerCancel: (_) => _holdEnd(),
                    child: _HoldButton(
                      label: M5RecloserLines.radio,
                      icon: Icons.settings_input_antenna_rounded,
                      ring: _holding == _Hold.radio ? _hold : null,
                      width: 84,
                    ),
                  ),
                ),
              if (showWheel)
                Positioned(
                  key: const ValueKey('hud-report'),
                  left: 96,
                  right: 92,
                  bottom: pad.bottom + 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CountWheel(
                        key: _wheelKey,
                        value: _count,
                        onStep: _stepCount,
                        onDrag: _wheelUpdate,
                        onDragEnd: () => _wheelDrag = 0,
                      ),
                      const SizedBox(width: 8),
                      _ReportButton(key: _reportKey, enabled: _count != null && _span != null, onTap: (g) => unawaited(_sendReport(g))),
                    ],
                  ),
                ),
              if (showTools)
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final t in _tools)
                        if (t == M5RecloserTool.clamp)
                          GestureDetector(
                            key: _toolKeys[t],
                            behavior: HitTestBehavior.opaque,
                            dragStartBehavior: DragStartBehavior.down,
                            onPanStart: (d) => _clampDrag(d.globalPosition),
                            onPanUpdate: (d) => _clampDrag(d.globalPosition),
                            onPanEnd: (_) => _clampDrop(_geoNow!),
                            child: _HoldButton(label: M5RecloserLines.toolLabel(t), icon: Icons.link_rounded, ring: null, on: _run.clamped),
                          )
                        else
                          Listener(
                            key: _toolKeys[t],
                            onPointerDown: (_) => _holdStart(t == M5RecloserTool.tester ? _Hold.tester : _Hold.spike),
                            onPointerUp: (_) => _holdEnd(),
                            onPointerCancel: (_) => _holdEnd(),
                            child: _HoldButton(
                              label: M5RecloserLines.toolLabel(t),
                              icon: t == M5RecloserTool.tester ? Icons.flash_on_rounded : Icons.hardware_rounded,
                              ring: _holding == (t == M5RecloserTool.tester ? _Hold.tester : _Hold.spike) ? _hold : null,
                              on: t == M5RecloserTool.tester ? _run.tested >= 3 : _run.spike,
                            ),
                          ),
                    ],
                  ),
                ),
              // Kept in the tree while dragged (its detector owns the gesture).
              if (showSlip)
                Positioned(
                  key: const ValueKey('hud-slip'),
                  right: 100,
                  bottom: pad.bottom + 18,
                  child: GestureDetector(
                    key: _slipKey,
                    behavior: HitTestBehavior.opaque,
                    dragStartBehavior: DragStartBehavior.down,
                    onPanStart: (d) => _ptwDrag(d.globalPosition),
                    onPanUpdate: (d) => _ptwDrag(d.globalPosition),
                    onPanEnd: (_) => _ptwDrop(),
                    child: Opacity(opacity: _ptwDragAt == null ? 1 : 0.3, child: _PtwSlip(number: _run.deal.ptw)),
                  ),
                ),
              if (_ptwDragAt != null)
                Positioned(
                  key: const ValueKey('hud-slip-drag'),
                  left: _ptwDragAt!.dx - 40,
                  top: _ptwDragAt!.dy - 28,
                  child: IgnorePointer(child: _PtwSlip(number: _run.deal.ptw)),
                ),
              if (_clampAt != null)
                Positioned(
                  key: const ValueKey('hud-clamp-drag'),
                  left: _clampAt!.dx - 20,
                  top: _clampAt!.dy - 20,
                  child: const IgnorePointer(child: Icon(Icons.link_rounded, size: 40, color: Color(0xFF6FD39A))),
                ),
              if (opLine != null && playing && !deckUp)
                Positioned(
                  key: ValueKey('op-$_opTok'),
                  right: 10,
                  left: 60,
                  bottom: pad.bottom + 104,
                  child: IgnorePointer(child: Align(alignment: Alignment.bottomRight, child: _RadioBubble(tag: M5RecloserLines.operatorTag, text: opLine))),
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
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (opLine != null ? 200 : 104)), onLeft: coworkerOnScreen ? coworkerFromRight : (_run.vanSpan ?? 0) >= 2),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.stage.name}-$strikes'),
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
                  line: M5RecloserLines.intro,
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

/// The notepad: the player's own tally (a stroke per tap; five crossed).
class _Notepad extends StatelessWidget {
  const _Notepad({required this.strokes, required this.demo, required this.onTap});
  final int strokes;
  final bool demo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M5RecloserLines.notepad,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 88,
          height: 84,
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEDC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF8C7A55), width: 1.4),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _TallyPainter(strokes: strokes, demo: demo),
                ),
              ),
              Text(M5RecloserLines.notepad, style: bangla(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF5A4A2E))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TallyPainter extends CustomPainter {
  const _TallyPainter({required this.strokes, required this.demo});
  final int strokes;
  final bool demo;

  @override
  void paint(Canvas canvas, Size size) {
    final lines = Paint()
      ..color = const Color(0x332A5A9A)
      ..strokeWidth = 1;
    for (var y = 10.0; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lines);
    }
    final ink = Paint()
      ..color = const Color(0xFF1E2A44)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final n = strokes;
    for (var i = 0; i < n; i++) {
      final group = i ~/ 5, k = i % 5;
      final gx = 4 + (group % 2) * 36.0, gy = 4 + (group ~/ 2) * 22.0;
      if (gy + 18 > size.height) break;
      if (k < 4) {
        canvas.drawLine(Offset(gx + k * 7, gy), Offset(gx + k * 7 - 1, gy + 18), ink);
      } else {
        canvas.drawLine(Offset(gx - 3, gy + 15), Offset(gx + 25, gy + 3), ink);
      }
    }
    if (demo) {
      final p = Paint()
        ..color = const Color(0x881E2A44)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(size.width - 14, 4), Offset(size.width - 15, 22), p);
      canvas.drawCircle(Offset(size.width - 14, 13), 12, Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x66C9A227)
        ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_TallyPainter old) => old.strokes != strokes || old.demo != demo;
}

/// A round control with its name under it: held (radio, tester, spike) with a
/// filling ring, or dragged (the clamp). Lit once done.
class _HoldButton extends StatelessWidget {
  const _HoldButton({required this.label, required this.icon, required this.ring, this.on = false, this.width = 82});
  final String label;
  final IconData icon;
  final Animation<double>? ring;
  final bool on;
  final double width;

  @override
  Widget build(BuildContext context) {
    final edge = on ? SlmColors.success : SlmColors.gold300;
    final r = ring;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                alignment: Alignment.center,
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
                      border: Border.all(color: edge.withValues(alpha: 0.9), width: on ? 2.4 : 1.7),
                      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                    ),
                    child: Icon(icon, size: 25, color: edge),
                  ),
                  if (r != null) Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _RingPainter(r)))),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
              child: Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t) : super(repaint: t);
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - 2);
    canvas.drawArc(
      r,
      -math.pi / 2,
      2 * math.pi * t.value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = SlmColors.gold400,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

/// The count wheel: swipe up/down (or ▲/▼); "?" until set.
class _CountWheel extends StatelessWidget {
  const _CountWheel({super.key, required this.value, required this.onStep, required this.onDrag, required this.onDragEnd});
  final int? value;
  final ValueChanged<int> onStep;
  final ValueChanged<double> onDrag;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    Widget arrow(int d) => Semantics(
          button: true,
          label: d > 0 ? M5RecloserLines.countUp : M5RecloserLines.countDown,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onStep(d),
            child: SizedBox(
              width: 56,
              height: 30,
              child: Icon(d > 0 ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: SlmColors.gold300, size: 28),
            ),
          ),
        );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (d) => onDrag(d.delta.dy),
      onVerticalDragEnd: (_) => onDragEnd(),
      child: Container(
        width: 64,
        decoration: BoxDecoration(
          color: const Color(0xEE0B1324),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF6E7C90), width: 1.4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            arrow(1),
            Text(value == null ? '?' : enDigits('$value'), style: bangla(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
            Text(M5RecloserLines.times, style: bangla(fontSize: 10, fontWeight: FontWeight.w700, color: SlmColors.ivory, height: 1.1)),
            arrow(-1),
          ],
        ),
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  const _ReportButton({super.key, required this.enabled, required this.onTap});
  final bool enabled;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: M5RecloserLines.report,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: enabled ? (d) => onTap(d.globalPosition) : null,
        child: Container(
          width: 92,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFF1F4A7A) : const Color(0xAA1C2433),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: enabled ? SlmColors.gold300 : const Color(0xFF4A5568), width: 1.6),
          ),
          child: Text(M5RecloserLines.report,
              style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: enabled ? Colors.white : const Color(0xFF8A94A6))),
        ),
      ),
    );
  }
}

/// "পোলে উঠুন": a plain sign on the pole, the same all play long.
class _ClimbSign extends StatelessWidget {
  const _ClimbSign({required this.onTap});
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M5RecloserLines.climb,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xDD1A2230),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF59657A), width: 1.2),
            ),
            child: Text(M5RecloserLines.climb, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFFD7DCE4))),
          ),
        ),
      ),
    );
  }
}

class _PtwSlip extends StatelessWidget {
  const _PtwSlip({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M5RecloserLines.ptwSlip,
      excludeSemantics: true,
      child: Container(
        width: 80,
        height: 56,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFB08A3A), width: 1.4),
          boxShadow: const [BoxShadow(color: Color(0x77000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(M5RecloserLines.ptwSlip, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF7A4A12), height: 1)),
            const SizedBox(height: 3),
            Text(enDigits('$number'), style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ink, height: 1)),
          ],
        ),
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xEE101A2B),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF6E7C90), width: 1),
      ),
      child: Text(text, style: bangla(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
    );
  }
}

/// The operator's words (radio).
class _RadioBubble extends StatelessWidget {
  const _RadioBubble({required this.tag, required this.text});
  final String tag;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xF2101826),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5BA3D6), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings_input_antenna_rounded, size: 13, color: Color(0xFF8FC8EE)),
              const SizedBox(width: 4),
              Text(tag, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF8FC8EE))),
            ],
          ),
          const SizedBox(height: 3),
          Text(enDigits(text), style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3)),
        ],
      ),
    );
  }
}

/// The locals' words at the tea stall, a hand pointing the way.
class _LocalBubble extends StatelessWidget {
  const _LocalBubble({required this.text, required this.pointLeft});
  final String text;
  final bool pointLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 6),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8C6A3A), width: 1.2),
      ),
      child: Row(
        children: [
          if (pointLeft) const Icon(Icons.west_rounded, size: 18, color: Color(0xFF8C6A3A)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(M5RecloserLines.localTag, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w900, color: const Color(0xFF8C6A3A))),
                Text(text, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.25)),
              ],
            ),
          ),
          if (!pointLeft) const Icon(Icons.east_rounded, size: 18, color: Color(0xFF8C6A3A)),
        ],
      ),
    );
  }
}
