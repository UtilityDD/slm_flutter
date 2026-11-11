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
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm3_pillar_inspect_world.dart';
import 'mistake_kit.dart';
import 'order_steps.dart' show OrderTap, OrderTapKind;
import 'reason_table.dart';
import 'scene_kit.dart' show Carry, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm3_pillar_inspect_world.dart'
    show M3PillarInspectFault, M3PillarInspectGeo, M3PillarInspectSpot, m3PillarInspectFuseSpot, m3PillarInspectInside, m3PillarInspectOutside;

// Lesson 3.7 "এলটি ডিস্ট্রিবিউশন বক্স/ফিডার পিলার", কাজ 2 "পিলারের তল্লাশি"
// (pack do_3_7_b, engine m3_pillar_inspect). The routine visit to the LT
// feeder pillar beside the transformer, three stations a play:
//   ক বাইরে (spot) — the lesson's daily checks (points 1 and 3): is the door
//     shut and locked, broken or rusted, the top seal whole, the cable entry
//     at the bottom sealed? Two of four faults are dealt; the trainee rings
//     every fault and writes the report.
//   খ ভেতরে (inspect, eyes only) — point 3's faults: a hotspot (a black mark
//     and the burnt smell at a busbar or fuse connection), water coming in
//     at the top seal, a rat-gnawed cable at the glands, and myth 2: a thick
//     wire in place of an HRC fuse. Two of four are dealt; the neutral link
//     and the earthing terminal are always fine (decoys).
//   গ মেগারিং (order) — pro tip 4 and the film's rule ("লাইন বন্ধ করে ফিউজ
//     খুলে"): the docket names one outgoing feeder's cable for an IR test:
//     gloves on (film: full PPE before a hand goes in the box), that feeder's
//     SFU OFF, its fuses out, then the megger on its cable. Then the careless
//     coworker: "দরজা খোলা থাক, কাল আবার আসব" — the trainee locks the door
//     (pro tip 1).
//
// Deadly (FLAGGED for the owner): the megger leads on an outgoing cable whose
// SFU is still ON (a live 415 V cable — lesson myth 1: deadly shock / arc
// flash). Slips: a fault missed, a fine part reported as faulty, a hand in the
// box without gloves, the wrong feeder, fuses pulled before the switch is
// OFF, the megger with the fuses still in, the door left open on his say-so.
// Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m3_pillar_inspect_world.dart), corner guide, ◆ on the table →
// "কেন …?" → the next station by itself. Voice: the guide's lines by device
// TTS; the coworker's push by TTS until recorded (his exit line is recorded).

// ============================================================================
// Content
// ============================================================================

enum M3PillarInspectStation { outside, inside, megger }

/// Where each fault shows (hotspot and wire-for-fuse move: see the deal).
M3PillarInspectSpot? m3PillarInspectFixedSpot(M3PillarInspectFault f) => switch (f) {
      M3PillarInspectFault.noLock => M3PillarInspectSpot.lock,
      M3PillarInspectFault.roofSeal => M3PillarInspectSpot.roof,
      M3PillarInspectFault.doorRust => M3PillarInspectSpot.door,
      M3PillarInspectFault.entryGap => M3PillarInspectSpot.entry,
      M3PillarInspectFault.waterIn => M3PillarInspectSpot.top,
      M3PillarInspectFault.ratBite => M3PillarInspectSpot.glands,
      M3PillarInspectFault.hotspot || M3PillarInspectFault.wireFuse => null,
    };

const m3PillarInspectOutsideFaults = [M3PillarInspectFault.noLock, M3PillarInspectFault.roofSeal, M3PillarInspectFault.doorRust, M3PillarInspectFault.entryGap];
const m3PillarInspectInsideFaults = [M3PillarInspectFault.hotspot, M3PillarInspectFault.waterIn, M3PillarInspectFault.ratBite, M3PillarInspectFault.wireFuse];

abstract final class M3PillarInspectLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askOutside, askInside, askMegger, askLock];

  static const title = 'পিলারের তল্লাশি';
  static const intro = 'ফিডার পিলারের তল্লাশি! খুঁটিয়ে দেখুন — বিপদ কোথায় লুকিয়ে?';
  static const rounds = ['ক', 'খ', 'গ'];

  static const askOutside = 'বাইরে থেকে দেখুন — কোথায় কোথায় ত্রুটি? দাগ দিয়ে রিপোর্ট করুন।';
  static const askInside = 'দরজা খোলা। ভেতরে কী কী বিপদ? হাত নয় — চোখে দেখে দাগ দিন।';
  static const askMegger = 'ডকেটের ফিডারের কেবিলে মেগার করতে হবে। শুরু করুন।';
  static const askLock = 'মাপা শেষ। পিলার ছেড়ে যাওয়ার আগে?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'ফিডার পিলার';
  static const report = 'দেখা শেষ — রিপোর্ট';
  static const lock = 'দরজা বন্ধ করে তালা';
  static const docketHead = 'ডকেট';
  static String docketFeeder(int k) => 'ফিডার ${enDigits('${k + 1}')}';
  static const docketJob = 'কেবিলের IR টেস্ট';
  static const stampReport = 'রিপোর্ট লেখা হলো';
  static const stampLock = 'পিলার তালাবন্ধ';

  // The reasons (34–46 letters each).
  static const whyOutsideQ = 'কেন এগুলো রিপোর্টে লিখলেন?';
  static const whyInsideQ = 'কেন এগুলো বিপদ ধরলেন?';
  static const whyMeggerQ = 'কেন এই ক্রমে মেগার করলেন?';

  static const faultWhy = {
    M3PillarInspectFault.noLock: 'তালা নেই, খোলা দরজা বাচ্চাদের প্রাণের ঝুঁকি',
    M3PillarInspectFault.roofSeal: 'ওপরের সিল ছেঁড়া, বৃষ্টির জল ঢুকে শর্ট হবে',
    M3PillarInspectFault.doorRust: 'ভাঙা, মরিচা ধরা দরজা দিয়ে ভেতরে জল ঢুকবে',
    M3PillarInspectFault.entryGap: 'নিচের কেবিল ঢোকার ফাঁকে ইঁদুর আর জল ঢোকে',
    M3PillarInspectFault.hotspot: 'কালো দাগ, পোড়া গন্ধ — ঢিলা কানেকশনে হটস্পট',
    M3PillarInspectFault.waterIn: 'ভেতরে জল ঢুকছে — শর্ট সার্কিট আর মরিচা হবে',
    M3PillarInspectFault.ratBite: 'ইঁদুরে কাটা ইনসুলেশনে শর্ট সার্কিট ঘটে',
    M3PillarInspectFault.wireFuse: 'ফিউজের বদলে তার — ফল্টে কেবিল পুড়ে যাবে',
  };
  static const outsideWrong = [
    'দেখতে খারাপ লাগে, তাই রং করাতে লিখলাম',
    'রিপোর্ট বেশি লিখলে সাহেব খুশি হন, তাই',
    'পাশের দোকানদার বলল, তাই লিখে দিলাম',
    'সব কিছুই লিখে দিই, দেখার দরকার হয় না',
    'নতুন বাক্স চাই, তাই একটু বাড়িয়ে লিখলাম',
    'ওপরওয়ালাকে কাজ দেখাতে হয়, তাই লিখলাম',
  ];
  static const insideWrong = [
    'কালো দাগ মানে রং চটে গেছে, নতুন রং চাই',
    'জল ঢুকলে শুধু বাক্সের রং নষ্ট হয়, তাই লিখি',
    'ইঁদুর ঢুকলে লোকে ভয় পায়, তাই লিখলাম',
    'পোড়া গন্ধে মাথা ধরে, তাই কাজ করা যায় না',
    'বাক্স পুরনো হয়েছে, নতুন বাক্স পাওয়ার জন্য',
    'সাথী বলল বিপদ, তাই না দেখেই লিখলাম',
  ];
  static const meggerRight = [
    'লাইন বন্ধ, ফিউজ খোলা — তবেই কেবিলে মেগার',
    'চালু কেবিলে মেগার নয়, আগে বন্ধ, ফিউজ খোলা',
    'গ্লাভস পরে, সুইচ বন্ধ, ফিউজ খুলে তবে মেগার',
  ];
  static const meggerWrong = [
    'মেগার নিজেই কারেন্ট দেয়, চালু লাইনেও চলে',
    'ফিউজ খোলা সময় নষ্ট, সুইচ বন্ধই যথেষ্ট',
    'গ্লাভস পরলে হাত ঘামে, তাই কাজ শেষে পরি',
    'যেকোনো ফিডারে মাপলেই হলো, সব একই কেবিল',
    'সাথী এভাবে করে, তাই আমিও এভাবে করলাম',
    'চারশো পনেরো ভোল্টে মেগারের কিছু হয় না',
  ];

  /// The right reasons for what this station was.
  static List<String> whyRight(M3PillarInspectStation s, Iterable<M3PillarInspectFault> faults) =>
      s == M3PillarInspectStation.megger ? meggerRight : [for (final f in faults) faultWhy[f]!];
  static List<String> whyWrong(M3PillarInspectStation s) => switch (s) {
        M3PillarInspectStation.outside => outsideWrong,
        M3PillarInspectStation.inside => insideWrong,
        M3PillarInspectStation.megger => meggerWrong,
      };
  static String whyQ(M3PillarInspectStation s) => switch (s) {
        M3PillarInspectStation.outside => whyOutsideQ,
        M3PillarInspectStation.inside => whyInsideQ,
        M3PillarInspectStation.megger => whyMeggerQ,
      };

  /// The careless coworker: leave it open, come back tomorrow.
  static const coworker = CoworkerScript(
    line: 'দরজা খোলা থাক, কাল আবার আসব। চলো, দেরি হচ্ছে!',
    exitLine: 'হুঁ! যা খুশি করুন।',
    right: ['না, পিলারের দরজা লক করেই যাব', 'খোলা দরজা বাচ্চাদের বিপদ, লক করছি', 'না, কাজ শেষে দরজায় তালা দিতেই হবে'],
    wrong: ['ঠিক আছে, কাল এসে দরজা বন্ধ করব', 'হ্যাঁ, এক রাত খোলা থাকলে কী হবে', 'চলো, তালা লাগানোটা কাল এসে হবে', 'ঠিক, এদিকে তো রাতে কেউ আসে না', 'আচ্ছা, দরজা ভেজিয়ে দিলেই হবে'],
    asks: ['ও বলছে দরজা খোলা রেখে চলে যেতে। কী করবেন?', 'দরজা খোলা রেখে যাবেন?', 'তালা দেবেন, না চলে যাবেন?'],
  );

  static const callHeld = 'ঠিক! খোলা পিলার মানে সবার বিপদ। তালা দিন।';
  static const allSet = 'পিলারের তল্লাশি শেষ — ত্রুটি ধরেছেন, নিয়ম মেনে মেগার, দরজায় তালা।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — খুঁটিয়ে দেখুন, আর আগে বন্ধ, ফিউজ খোলা, তবে মেগার।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtFault = {
    M3PillarInspectFault.noLock: 'তালাহীন দরজা',
    M3PillarInspectFault.roofSeal: 'ছেঁড়া ওপরের সিল',
    M3PillarInspectFault.doorRust: 'মরিচা ধরা ভাঙা দরজা',
    M3PillarInspectFault.entryGap: 'কেবিল ঢোকার ফাঁক',
    M3PillarInspectFault.hotspot: 'হটস্পট (কালো দাগ)',
    M3PillarInspectFault.waterIn: 'ভেতরে জল',
    M3PillarInspectFault.ratBite: 'ইঁদুরে কাটা কেবিল',
    M3PillarInspectFault.wireFuse: 'ফিউজের বদলে তার',
  };
  static const caughtMegger = 'বন্ধ, ফিউজ খোলা, তবে মেগার';
  static const caughtLock = 'কাজ শেষে দরজায় তালা';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class M3PillarInspectMistakes {
  static const _dir = 'assets/game/art/m3_pillar_inspect';
  static const _k = '3.7/m3_pillar_inspect';

  static const missedLock = DoMistake(
    key: '$_k/missed-lock',
    textBn: 'দরজায় তালা নেই, দরজা ঠিকমতো বন্ধও নয় — চোখ এড়িয়ে গেল। খোলা পিলার বাচ্চা আর পথচারীর জন্য মারাত্মক।',
    art: '$_dir/missed_lock.svg',
    lessonPoint: 0,
  );
  static const missedRoof = DoMistake(
    key: '$_k/missed-roof-seal',
    textBn: 'ওপরের সিল ছেঁড়া ছিল। সিল নষ্ট হলে বৃষ্টির জল ভেতরে ঢুকে শর্ট সার্কিট বা মরিচা ধরায়।',
    art: '$_dir/missed_roof.svg',
    lessonPoint: 2,
  );
  static const missedRust = DoMistake(
    key: '$_k/missed-rust',
    textBn: 'দরজা ভাঙা, মরিচা ধরা — দেখেও লেখা হয়নি। ভাঙা দরজা দিয়েই জল আর পোকামাকড় ঢোকে।',
    art: '$_dir/missed_rust.svg',
    lessonPoint: 0,
  );
  static const missedEntry = DoMistake(
    key: '$_k/missed-entry',
    textBn: 'নিচের কেবিল এন্ট্রিতে ফাঁক ছিল। ওই পথেই ইঁদুর আর জল ঢোকে — এন্ট্রি সিল করা চাই।',
    art: '$_dir/missed_entry.svg',
    lessonPoint: 2,
  );
  static const missedHot = DoMistake(
    key: '$_k/missed-hotspot',
    textBn: 'কানেকশনে কালো দাগ, পোড়া গন্ধ — হটস্পট চোখ এড়াল। ঢিলা কানেকশনে স্পার্কিং হয়, জায়গাটা অতিরিক্ত গরম হয়।',
    art: '$_dir/missed_hot.svg',
    lessonPoint: 2,
  );
  static const missedWater = DoMistake(
    key: '$_k/missed-water',
    textBn: 'ওপরের সিল দিয়ে ভেতরে জল ঢুকছিল। ভেতরে জল মানে শর্ট সার্কিট আর মরিচার বিপদ।',
    art: '$_dir/missed_water.svg',
    lessonPoint: 2,
  );
  static const missedRat = DoMistake(
    key: '$_k/missed-rat',
    textBn: 'কেবিলের ইনসুলেশন ইঁদুরে কাটা, নিচে নোংরা — দেখা হয়নি। কাটা ইনসুলেশন থেকেই শর্ট সার্কিট হয়।',
    art: '$_dir/missed_rat.svg',
    lessonPoint: 2,
  );
  static const missedWire = DoMistake(
    key: '$_k/missed-wire-fuse',
    textBn: 'ফিউজের জায়গায় মোটা তার লাগানো — চোখ এড়াল। ফল্টে ফিউজ উড়বে না, কেবিল বা ট্রান্সফরমার পুড়বে।',
    art: '$_dir/missed_wire.svg',
  );
  static const falseFlag = DoMistake(
    key: '$_k/false-flag',
    textBn: 'ঠিক থাকা অংশকেও ত্রুটি লিখলেন। খুঁটিয়ে দেখুন — কালো দাগ, জল, ফাঁক, মরিচা, তালা — তবেই রিপোর্ট।',
    art: '$_dir/false_flag.svg',
    lessonPoint: 2,
  );
  static const noGloves = DoMistake(
    key: '$_k/no-gloves',
    textBn: 'গ্লাভস ছাড়া পিলারে হাত! ভেতরটা লাইভ প্যানেলের মতোই বিপজ্জনক — সম্পূর্ণ PPE আর ইনসুলেটেড টুলস আগে।',
    art: '$_dir/no_gloves.svg',
    lessonPoint: 1,
  );
  static const wrongFeeder = DoMistake(
    key: '$_k/wrong-feeder',
    textBn: 'এটা ডকেটের ফিডার নয়। প্রতিটা ফিডার আলাদা — শুধু যার কেবিল মাপবেন, সেটাই বন্ধ করুন।',
    art: '$_dir/wrong_feeder.svg',
    lessonPoint: 0,
  );
  static const fuseBeforeOff = DoMistake(
    key: '$_k/fuse-before-off',
    textBn: 'সুইচ ON রেখেই ফিউজে হাত। নিয়ম: আগে লাইন বন্ধ, তারপর ফিউজ খোলা।',
    art: '$_dir/fuse_before_off.svg',
  );
  static const fusesIn = DoMistake(
    key: '$_k/fuses-in',
    textBn: 'ফিউজ না খুলেই মেগার। লাইন বন্ধ করে, ফিউজ খুলে, তবেই কেবিলের IR মাপা।',
    art: '$_dir/fuses_in.svg',
  );
  static const liveMegger = DoMistake(
    key: '$_k/live-megger',
    textBn: 'চালু কেবিলে মেগারের লিড! ৪১৫ ভোল্ট মারাত্মক শক দেয়, আর্ক ফ্ল্যাশও হতে পারে। আগে সুইচ বন্ধ, ফিউজ খোলা।',
    art: '$_dir/live_megger.svg',
    deadly: true,
  );
  static const doorOpen = DoMistake(
    key: '$_k/door-open',
    textBn: 'দরজা খোলা রেখে চলে গেলেন। কাজ শেষে পিলারে তালা — খোলা দরজা বাচ্চা ও সাধারণ মানুষের প্রাণের ঝুঁকি।',
    art: '$_dir/door_open.svg',
  );

  static const missedBy = {
    M3PillarInspectFault.noLock: missedLock,
    M3PillarInspectFault.roofSeal: missedRoof,
    M3PillarInspectFault.doorRust: missedRust,
    M3PillarInspectFault.entryGap: missedEntry,
    M3PillarInspectFault.hotspot: missedHot,
    M3PillarInspectFault.waterIn: missedWater,
    M3PillarInspectFault.ratBite: missedRat,
    M3PillarInspectFault.wireFuse: missedWire,
  };

  static List<DoMistake> get all => [
        missedLock,
        missedRoof,
        missedRust,
        missedEntry,
        missedHot,
        missedWater,
        missedRat,
        missedWire,
        falseFlag,
        noGloves,
        wrongFeeder,
        fuseBeforeOff,
        fusesIn,
        liveMegger,
        doorOpen,
      ];
}

@immutable
class M3PillarInspectDeal {
  const M3PillarInspectDeal({required this.outside, required this.inside, required this.feeder});

  /// Station ক's faults, by spot.
  final Map<M3PillarInspectSpot, M3PillarInspectFault> outside;

  /// Station খ's faults, by spot.
  final Map<M3PillarInspectSpot, M3PillarInspectFault> inside;

  /// The docket's feeder (0–2): never one with a fuse fault.
  final int feeder;
}

/// Two outside faults, two inside faults (the hotspot at the busbar or a fuse
/// unit, the wire in another unit), the docket's feeder — fresh every play.
M3PillarInspectDeal dealM3PillarInspect(math.Random rng) {
  final out = [...m3PillarInspectOutsideFaults]..shuffle(rng);
  final ins = [...m3PillarInspectInsideFaults]..shuffle(rng);
  final inside = <M3PillarInspectSpot, M3PillarInspectFault>{};
  final units = [0, 1, 2]..shuffle(rng);
  for (final f in ins.take(2)) {
    final fixed = m3PillarInspectFixedSpot(f);
    if (fixed != null) {
      inside[fixed] = f;
    } else if (f == M3PillarInspectFault.hotspot && rng.nextInt(4) == 0) {
      inside[M3PillarInspectSpot.busbar] = f;
    } else {
      inside[m3PillarInspectFuseSpot(units.removeLast())] = f;
    }
  }
  final free = [
    for (var k = 0; k < 3; k++)
      if (!inside.containsKey(m3PillarInspectFuseSpot(k))) k,
  ];
  return M3PillarInspectDeal(
    outside: {for (final f in out.take(2)) m3PillarInspectFixedSpot(f)!: f},
    inside: inside,
    feeder: free[rng.nextInt(free.length)],
  );
}

/// The play state (pure logic).
class M3PillarInspectRun {
  M3PillarInspectRun(this.deal);

  final M3PillarInspectDeal deal;
  int index = 0;

  // Stations ক, খ.
  final Set<M3PillarInspectSpot> flagged = {};
  final Set<M3PillarInspectSpot> missed = {};

  // Station গ.
  var gloves = false;
  final Set<int> off = {};
  final Set<int> fusesOut = {};
  int? meggerOn;
  var locked = false;
  var leftOpen = false;

  var shown = false;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= 3;
  bool get ended => done || deadly != null;
  M3PillarInspectStation get station => M3PillarInspectStation.values[index.clamp(0, 2)];
  bool get tested => meggerOn != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get _open => !ended && !shown;

  /// The faults at this station (none at গ).
  Map<M3PillarInspectSpot, M3PillarInspectFault> get faultsHere => switch (station) {
        M3PillarInspectStation.outside => deal.outside,
        M3PillarInspectStation.inside => deal.inside,
        M3PillarInspectStation.megger => const {},
      };

  List<M3PillarInspectSpot> get spotsHere => switch (station) {
        M3PillarInspectStation.outside => m3PillarInspectOutside,
        M3PillarInspectStation.inside => m3PillarInspectInside,
        M3PillarInspectStation.megger => const [],
      };

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    return m;
  }

  /// Ring (or un-ring) a spot as faulty. Returns whether it is ringed now.
  bool? toggle(M3PillarInspectSpot s) {
    if (!_open || !spotsHere.contains(s)) return null;
    if (!flagged.remove(s)) flagged.add(s);
    return flagged.contains(s);
  }

  /// Hand in the report: every fault ringed and nothing else.
  DoMistake? report() {
    if (!_open || station == M3PillarInspectStation.megger) return null;
    final f = faultsHere;
    shown = true;
    final miss = [
      for (final s in spotsHere)
        if (f.containsKey(s) && !flagged.contains(s)) s,
    ];
    if (miss.isNotEmpty) {
      missed.addAll(miss);
      return _slip(M3PillarInspectMistakes.missedBy[f[miss.first]]!);
    }
    if (flagged.any((s) => !f.containsKey(s))) return _slip(M3PillarInspectMistakes.falseFlag);
    for (final x in f.values) {
      _tag(M3PillarInspectLines.caughtFault[x]!);
    }
    return null;
  }

  static const _ok = OrderTap(OrderTapKind.ok);
  static const _ignored = OrderTap(OrderTapKind.ignored);
  OrderTap _mistake(DoMistake m) {
    if (m.deadly) {
      deadly = m;
    } else {
      slips++;
    }
    return OrderTap(OrderTapKind.mistake, mistake: m);
  }

  bool get _meggerOpen => _open && station == M3PillarInspectStation.megger;

  OrderTap tapGloves() {
    if (!_meggerOpen || gloves) return _ignored;
    gloves = true;
    return _ok;
  }

  OrderTap tapSwitch(int k) {
    if (!_meggerOpen || tested) return _ignored;
    if (!gloves) return _mistake(M3PillarInspectMistakes.noGloves);
    if (k != deal.feeder) return _mistake(M3PillarInspectMistakes.wrongFeeder);
    if (!off.add(k)) return _ignored;
    return _ok;
  }

  OrderTap tapFuses(int k) {
    if (!_meggerOpen || tested) return _ignored;
    if (!gloves) return _mistake(M3PillarInspectMistakes.noGloves);
    if (k != deal.feeder) return _mistake(M3PillarInspectMistakes.wrongFeeder);
    if (!off.contains(k)) return _mistake(M3PillarInspectMistakes.fuseBeforeOff);
    if (!fusesOut.add(k)) return _ignored;
    return _ok;
  }

  /// The megger's leads on outgoing cable [k].
  OrderTap tapCable(int k) {
    if (!_meggerOpen || tested) return _ignored;
    if (!off.contains(k)) return _mistake(M3PillarInspectMistakes.liveMegger);
    if (!gloves) return _mistake(M3PillarInspectMistakes.noGloves);
    if (!fusesOut.contains(k)) return _mistake(M3PillarInspectMistakes.fusesIn);
    meggerOn = k;
    _tag(M3PillarInspectLines.caughtMegger);
    return _ok;
  }

  /// Close and lock the door: the station is done.
  bool lock() {
    if (!_meggerOpen || !tested) return false;
    locked = true;
    shown = true;
    _tag(M3PillarInspectLines.caughtLock);
    return true;
  }

  /// Listened to him: the door left open — a slip; the station ends.
  DoMistake? leaveOpen() {
    if (!_meggerOpen) return null;
    leftOpen = true;
    shown = true;
    return _slip(M3PillarInspectMistakes.doorOpen);
  }

  void next() {
    index++;
    flagged.clear();
    missed.clear();
    shown = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %). Station ক: look
/// 6000 + 2 rings 3000 + report 1500 + reason 8200 ≈ 18700; খ ≈ 21000 (more
/// to look at); গ: gloves, switch, fuses, megger 6000 + the needle 1500 + the
/// coworker 9600 + lock 1500 + reason 8200 ≈ 26800: ≈ 66500; 85 % ≈ 57 s.
const kM3PillarInspectQuickMs = 57000;

@immutable
class M3PillarInspectPack {
  const M3PillarInspectPack({required this.id, required this.titleBn, this.quickMs = kM3PillarInspectQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m3PillarInspectPacks = {
  'do_3_7_b': M3PillarInspectPack(id: 'do_3_7_b', titleBn: M3PillarInspectLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M3PillarInspectPage extends StatefulWidget {
  const M3PillarInspectPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M3PillarInspectPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3PillarInspectPage> createState() => _M3PillarInspectPageState();
}

class _M3PillarInspectPageState extends State<M3PillarInspectPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PillarRunPage(
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

class _PillarRunPage extends ConsumerStatefulWidget {
  const _PillarRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3PillarInspectPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PillarRunPage> createState() => _PillarRunPageState();
}

class _PillarRunPageState extends ConsumerState<_PillarRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3PillarInspectRun _run = M3PillarInspectRun(dealM3PillarInspect(widget.rng));
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
  String? _stamp;
  var _coworkerArmed = false;
  int? _zapCable;

  var _freeze = false;
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
    _startStation();
  }

  bool get _canPlay => !_intro && !_busy && !_ended && _card == null && !reasonOpen && !coworkerOpen && !_run.shown;

  /// The current task (what the guide says and repeats).
  String get _task => switch (_run.station) {
        M3PillarInspectStation.outside => M3PillarInspectLines.askOutside,
        M3PillarInspectStation.inside => M3PillarInspectLines.askInside,
        M3PillarInspectStation.megger => _run.tested ? M3PillarInspectLines.askLock : M3PillarInspectLines.askMegger,
      };

  void _startStation() {
    setState(() {
      _stamp = null;
      _wake++;
    });
    unawaited(_sayChain([_task]));
  }

  // --- hands on ---------------------------------------------------------------
  void _tapScene(Offset p, M3PillarInspectGeo geo) {
    if (!_canPlay) return;
    if (_run.station == M3PillarInspectStation.megger) {
      _tapMegger(p, geo);
      return;
    }
    M3PillarInspectSpot? hit;
    for (final s in _run.spotsHere) {
      if (geo.spot(s).contains(p)) {
        hit = s;
        break;
      }
    }
    if (hit == null) return;
    final on = _run.toggle(hit);
    if (on == null) return;
    HapticFeedback.selectionClick();
    _cue(on ? 'sounds/learn/tag_slap.wav' : 'sounds/intro/tick.ogg', volume: 0.5);
    setState(() => _wake++);
  }

  void _tapMegger(Offset p, M3PillarInspectGeo geo) {
    OrderTap? r;
    int? cable;
    if (geo.gloves.contains(p)) {
      r = _run.tapGloves();
    } else {
      for (var k = 0; k < 3 && r == null; k++) {
        if (geo.handle(k).contains(p)) {
          r = _run.tapSwitch(k);
        } else if (geo.fuses(k).contains(p)) {
          r = _run.tapFuses(k);
        } else if (geo.cable(k).contains(p)) {
          cable = k;
          r = _run.tapCable(k);
        }
      }
    }
    if (r == null || r.kind == OrderTapKind.ignored) return;
    final origin = geo.trainee.center;
    if (r.kind == OrderTapKind.mistake) {
      final m = r.mistake!;
      if (m.deadly) {
        _zapCable = cable;
        unawaited(_deadly(m));
        return;
      }
      setState(() => _wake++);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      unawaited(_slip(m));
      return;
    }
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.55);
    setState(() => _wake++);
    if (_run.tested) {
      _cue('sounds/quiz_select.wav', volume: 0.4);
      unawaited(_sayChain([M3PillarInspectLines.askLock]));
      if (!_coworkerArmed) {
        _coworkerArmed = true;
        scheduleCoworker();
      }
    }
  }

  // --- the decisions -----------------------------------------------------------
  Future<void> _report(Offset origin) async {
    if (!_canPlay) return;
    _hush();
    final m = _run.report();
    if (!_run.shown) return;
    HapticFeedback.mediumImpact();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _cue('sounds/learn/tag_slap.wav', volume: 0.7);
    _cue('sounds/quiz_right.wav', volume: 0.6);
    setState(() {
      _stamp = M3PillarInspectLines.stampReport;
      _wake++;
    });
    _ask();
  }

  Future<void> _lock(Offset origin) async {
    if (!_canPlay || !_run.tested) return;
    _hush();
    if (!_run.lock()) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/click.ogg', volume: 0.7);
    _cue('sounds/quiz_right.wav', volume: 0.6);
    setState(() {
      _stamp = M3PillarInspectLines.stampLock;
      _wake++;
    });
    _ask();
  }

  /// ◆ on the table, then "কেন …?".
  void _ask() {
    putOnTable(15);
    final s = _run.station;
    final faults = _run.faultsHere.values.toList();
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M3PillarInspectLines.whyRight(s, faults), M3PillarInspectLines.whyWrong(s), widget.rng),
      question: M3PillarInspectLines.whyQ(s),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startStation();
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
  CoworkerScript get coworkerScript => M3PillarInspectLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.station != M3PillarInspectStation.megger || _run.shown) return null;
    if (_intro || _busy || _card != null || reasonOpen || !_run.tested) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.leaveOpen();
      if (m == null) return;
      setState(() => _wake++);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    if (!_run.caught.contains(M3PillarInspectLines.caughtCall)) _run.caught.add(M3PillarInspectLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    setState(() => _wake++);
    unawaited(_sayChain([M3PillarInspectLines.callHeld]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3PillarInspectLines.tapWhy[_nudgeN++ % M3PillarInspectLines.tapWhy.length]
            : _nudge.next(_task);
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
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('pillar/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The megger's leads on a live cable: the scene freezes grey and the
  /// flash shows at the cable in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.wav', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() => _freeze = true);
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.wav', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('pillar/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M3PillarInspectLines.deadlyWord : M3PillarInspectLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        // A report or the open door ends the station; an order slip does not.
        if (_run.shown) {
          _next();
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
    await _say(!_run.passed ? M3PillarInspectLines.fail : (_quickBonus ? M3PillarInspectLines.quick : M3PillarInspectLines.allSet),
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
    if (_stamp != null) return LinemanMode.cheer;
    return _run.station == M3PillarInspectStation.megger ? LinemanMode.hold : LinemanMode.point;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = M3PillarInspectGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final st = _run.station;
    final megger = st == M3PillarInspectStation.megger && !_run.done;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final tb = geo.trainee;
    final hand = tb.topLeft + LinemanFigure.tipOf(LinemanMode.hold, Carry.none, tb.size);
    // Station ক's missing lock stays missing until he locks it at গ.
    final lockMissing = _run.deal.outside.containsValue(M3PillarInspectFault.noLock);
    // Later stations keep what station ক showed (the roof seal).
    final faults = st == M3PillarInspectStation.outside ? _run.deal.outside : {..._run.deal.outside, ..._run.deal.inside};
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('land'),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: M3PillarInspectPainter(
                      geo: geo,
                      view: st == M3PillarInspectStation.outside ? M3PillarInspectView.closed : M3PillarInspectView.open,
                      faults: faults,
                      flagged: {..._run.flagged},
                      missed: {..._run.missed},
                      switchedOff: {..._run.off},
                      fusesOut: {..._run.fusesOut},
                      meggerOn: _run.meggerOn,
                      glovesOn: _run.gloves,
                      lockedNew: _run.locked,
                      lockMissing: lockMissing,
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: tb,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
              if (_run.gloves)
                Positioned.fill(
                  key: const ValueKey('gloves'),
                  child: IgnorePointer(child: CustomPaint(painter: M3PillarInspectGlovesPainter(hands: [hand]))),
                ),
            ],
          ),
        ),
      ),
      if (megger)
        Positioned(
          key: const ValueKey('docket-card'),
          left: 6,
          top: geo.pillar.top - 4,
          width: 106,
          child: IgnorePointer(child: _Docket(feeder: _run.deal.feeder)),
        ),
      if (_stamp != null && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: geo.pillar.left + 10,
          width: geo.pillar.width - 20,
          top: geo.pillar.top + 40,
          child: IgnorePointer(child: _StampPop(text: _stamp!, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M3PillarInspectLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M3PillarInspectZapPainter(at: geo.cableLug(_zapCable ?? _run.deal.feeder), v: v)),
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.shown && !deckUp && !coworkerOpen && _card == null && !_run.done;
    final spotting = handsOn && _run.station != M3PillarInspectStation.megger;
    final locking = handsOn && _run.station == M3PillarInspectStation.megger && _run.tested && coworkerDone;
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
              labels: M3PillarInspectLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (spotting || locking)
                Positioned(
                  key: ValueKey(spotting ? 'hud-report' : 'hud-lock'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: DoBigButton(
                    label: spotting ? M3PillarInspectLines.report : M3PillarInspectLines.lock,
                    filled: true,
                    onTapUp: (d) => unawaited(spotting ? _report(d.globalPosition) : _lock(d.globalPosition)),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 72), onLeft: coworkerFromRight),
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
                  sound: FailSound.electric,
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
                  line: M3PillarInspectLines.intro,
                  alarm: 'sounds/learn/tag_slap.wav',
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

/// The job's docket, pinned beside the pillar (a worker reads it).
class _Docket extends StatelessWidget {
  const _Docket({required this.feeder});
  final int feeder;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.04,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF8C6D3F), width: 1.4),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(M3PillarInspectLines.docketHead, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF8C6D3F))),
            Text(M3PillarInspectLines.docketFeeder(feeder),
                key: const ValueKey('docket-feeder'), style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
            Text(M3PillarInspectLines.docketJob, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF2B2416))),
          ],
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
      builder: (_, v, child) => Transform.rotate(angle: -0.08, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.success, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
