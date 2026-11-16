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
import 'm6_pillar_thermal_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_pillar_thermal_world.dart' show M6Phase, M6Slot, M6ThermalGeo, m6SlotPhase, m6SlotsOf, m6ThermalColor;

// Lesson 6.9 "এলটি ডিস্ট্রিবিউশন পিলার: শেষ প্রবেশদ্বার", কাজ 1 "তাপের চোখ"
// (pack do_6_9_a, engineType m6_pillar_thermal). A lane corner by a DTR; the
// feeder pillar stands open for preventive maintenance (pro tip 3: a thermal
// camera finds loose connections and hotspots before the eye can).
//
//  স্ক্যান: drag the camera's aim frame across the pillar. Its live screen
//    (an inset) shows only the column under the frame in false colour: the
//    incomer (its R/Y/B lugs and its neutral) or an outgoing way (busbar-side
//    joint and cable lug per phase, and its neutral bolt on the link). A
//    column counts as scanned once the frame has stayed on it ~1 s (never
//    shown). 1–2 hotspots are dealt (any joint, any column; a loose joint
//    runs hot, point 3); tones vary from column to column and joint to
//    joint, so only a joint's sisters on the same way tell a hotspot. Tap a
//    hotter-than-its-sisters joint on the live screen: the job card writes
//    'F2 · Y · কেবিল লাগ'. The first hotspot → ◆ → "কেন এই জোড়াটা ধরলেন?".
//    An even joint tagged = slip (R32, needless report), once per joint.
//    'স্ক্যান শেষ' is always live: a hotspot left behind = slip (it is shown
//    on the pillar), else a column never scanned = slip; a full scan → ◆ →
//    "কেন সব ক'টা ওয়ে স্ক্যান করলেন?".
//  জব কার্ড: per tagged hotspot a deck of jobs to write. Right: tighten on a
//    dead board (ruling X4: DTR LT OFF, lock-tag, tester). Deadly: water on
//    the hot joint (R19, M6-4), tightening it live by bare hand (R18) or with
//    an insulated spanner (R18 widened by X4), a thick wire or strip in the
//    fuse's place (R12, lesson myth 2). Slip: 'চলছে তো, ছেড়ে দিন'. Right →
//    ◆ → "কেন টাইট দেওয়ার কাজ লিখলেন?".
//  Hand in the job card → the pass panel.
//
// The careless coworker once a play: after the frame has stayed on the 1st or
// 2nd clean column (dealt; swept from the incomer outward an 'early' hotspot
// is still to come then), or, on a quick sweep that passed over that many
// clean columns without staying, at the next tag or 'স্ক্যান শেষ' — always
// while a column that looks fine to the eye is still unscanned: "চোখে তো
// কিছু দেখা যাচ্ছে না, ক্যামেরা রাখো — সব ঠিক আছে।" The camera, the tags and
// 'স্ক্যান শেষ' wait for him (holdForCoworker). Listening = slip (ruling X2/B1: the act he
// pushes, ending the scan early, is a slip): the scan ends and any hotspot
// left behind is shown. Three slips strike out.
//
// Eye view: every joint alike, except a 'late' hotspot (dealt only as the
// second hotspot, never the one he comes before): a blackened joint and a
// smell wisp (point 3). No temperatures anywhere (the lesson gives none).
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_pillar_thermal_world.dart), corner guide, ReasonTable,
// CoworkerMoment, MistakeCard, the deadly freeze, StruckOutCard, the pass
// panel. Gesture hands (how, never what): a fixed left-to-right drag nudge on
// the frame; with the frame on a column, in turn, a sweep over every joint on
// the live screen and 'স্ক্যান শেষ' alike; a tap on 'জমা দিন' (the one way
// on). Decks carry their own sweep.

// ============================================================================
// Content
// ============================================================================

/// The jobs a hotspot may be written up for.
enum M6ThermalFix { deadTighten, water, bareHand, insulatedLive, thickWire, leaveIt }

/// What a reason asks about.
enum M6ThermalWhy { tag, fix, scan }

/// The level's stages.
enum M6ThermalStage { scan, fix, handIn, done }

/// What a tap on a joint did.
enum M6Tag { hot, even, again, closed }

/// The lesson point (0-based) the fail panel opens: point 3, troubleshooting.
const int m6ThermalLessonPoint = 2;

abstract final class M6PillarThermalLines {
  static const title = 'তাপের চোখ';
  // DRAFT wording — owner (M6-12).
  static const intro = 'প্রিভেন্টিভ মেইনটেন্যান্স — চোখে দেখার আগে গরম জোড়া খুঁজে বের করুন।';

  // The guide's task now (tap him: the same task, a different way).
  static const askSweep = 'ক্যামেরা ঘুরিয়ে প্রতিটা ওয়ে দেখুন।';
  static const askFix = 'এই গরম জোড়ার জন্য জব কার্ডে কী কাজ লিখবেন?';
  static const askHandIn = 'জব কার্ডটা জমা দিন।';
  static const moreHot = 'আরেকটা গরম জোড়া — জব কার্ডে উঠল।';
  static List<String> get tasks => const [askSweep, askFix, askHandIn];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // On the scene (a worker's own words).
  static const sceneLabel = 'ফিডার পিলার';
  static const camLabel = 'থার্মাল ক্যামেরা';
  static const scanDone = 'স্ক্যান শেষ';
  static const handIn = 'জমা দিন';
  static const jobCard = 'জব কার্ড';
  static const jobCardSub = 'পিলার PM';
  static const fixedMark = 'টাইট';

  /// The three stages (screen readers only: on screen they are dots).
  static const stages = ['স্ক্যান', 'জব কার্ড', 'জমা'];

  static String unitName(int unit) => unit == 0 ? 'ইনকামার' : 'F$unit';
  static String phaseName(M6Phase p) => switch (p) {
        M6Phase.r => 'R',
        M6Phase.y => 'Y',
        M6Phase.b => 'B',
        M6Phase.n => 'N',
      };
  static String slotName(M6Slot s) => switch (s) {
        M6Slot.busR || M6Slot.busY || M6Slot.busB => 'বাসবার দিক',
        M6Slot.lugR || M6Slot.lugY || M6Slot.lugB => 'কেবিল লাগ',
        M6Slot.n => 'নিউট্রাল লিঙ্ক',
      };

  /// The job card's line for a joint: 'F2 · Y · কেবিল লাগ'.
  static String entry(int unit, M6Slot s) => '${unitName(unit)} · ${phaseName(m6SlotPhase(s))} · ${slotName(s)}';

  // The job deck (one per tagged hotspot): about the same length each.
  static const fixRight = [
    'DTR-এর LT OFF, তালা-ট্যাগ, ডেড প্রমাণে টাইট',
    'বোর্ড ডেড প্রমাণ করে জোড়াটা টাইট দেওয়া',
  ];
  static const fixWrong = <M6ThermalFix, String>{
    M6ThermalFix.water: 'গরম জোড়ায় জল ঢেলে এখনই ঠান্ডা করা',
    M6ThermalFix.bareHand: 'এখনই খালি হাতে নাটটা ঘুরিয়ে টাইট দেওয়া',
    M6ThermalFix.insulatedLive: 'চালু অবস্থাতেই ইনসুলেটেড স্প্যানারে টাইট',
    M6ThermalFix.thickWire: 'ফিউজের জায়গায় মোটা তার বা পাত লাগানো',
    M6ThermalFix.leaveIt: 'চলছে তো, এখন কিছু না করে ছেড়ে দেওয়া',
  };
  static M6ThermalFix fixOf(String text) {
    if (fixRight.contains(text)) return M6ThermalFix.deadTighten;
    return fixWrong.entries.firstWhere((e) => e.value == text).key;
  }

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses.
  static const whyQ = <M6ThermalWhy, String>{
    M6ThermalWhy.tag: 'কেন এই জোড়াটা ধরলেন?',
    M6ThermalWhy.fix: 'কেন টাইট দেওয়ার কাজ লিখলেন?',
    M6ThermalWhy.scan: "কেন সব ক'টা ওয়ে স্ক্যান করলেন?",
  };
  static const whyRight = <M6ThermalWhy, List<String>>{
    M6ThermalWhy.tag: ['পাশের জোড়াগুলোর চেয়ে এটা অনেক বেশি গরম', 'বাকি জোড়ার তুলনায় গরম — ঢিলা হওয়ার লক্ষণ'],
    M6ThermalWhy.fix: ['ঢিলা কানেকশনেই স্পার্কিং আর হটস্পট হয়', 'লুজ কানেকশন টাইট দিলে গরম হওয়া থামে'],
    M6ThermalWhy.scan: ['চোখে দেখার আগেই ক্যামেরা হটস্পট ধরে', 'কোন ওয়েতে ঢিলা জোড়া, আগে জানা যায় না'],
  };
  static const myths = [
    'চোখে কিছু না দেখা গেলে জোড়া ঠিকই আছে',
    'LT বক্সে তো শুধু 415 ভোল্ট, ভয় নেই',
    'যেকোনো একটা জোড়া লিখলেই কাজ হয়ে যায়',
    'ফিউজ বারবার গেলে মোটা তার দিলেই হয়',
    'গরম জোড়ায় একটু জল দিলেই ঠিক হয়ে যায়',
    'যত বেশি জোড়া লিখব, কাজ তত ভালো দেখাবে',
    'চলছে যখন, গরম হলেও কিছু যায় আসে না',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (once a play, mid-scan).
  // DRAFT wording — owner (M6-12): his push is the spec's.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'চোখে তো কিছু দেখা যাচ্ছে না, ক্যামেরা রাখো — সব ঠিক আছে।',
    exitLine: coworkerExit,
    right: [
      'না, চোখে দেখার আগেই ক্যামেরা হটস্পট ধরে',
      "না, সব ক'টা ওয়ে দেখে তবেই স্ক্যান শেষ",
      'না, না দেখা ওয়েতেই গরম জোড়া থাকতে পারে',
    ],
    wrong: [
      'ঠিক, চোখে তো কিছু নেই, ক্যামেরা রাখি',
      'আচ্ছা, সব ঠিকই আছে মনে হচ্ছে, থামি',
      'হ্যাঁ, বাকি ওয়েগুলো পরে দেখা যাবে',
      'ঠিক আছে, এখানেই স্ক্যান শেষ করে দিই',
      'হ্যাঁ, এত খুঁটিয়ে দেখার দরকার নেই',
    ],
    asks: ['কী করবেন?', 'ও বলছে ক্যামেরা রেখে দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const callHeld = 'ঠিক! চোখে দেখার আগেই ক্যামেরা হটস্পট ধরে — সব ওয়ে দেখুন।';

  static const allSet = 'সব ওয়ে দেখা, গরম জোড়া জব কার্ডে — দারুণ কাজ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — প্রতিটা ওয়ে ক্যামেরায় দেখুন, পাশের জোড়ার সঙ্গে মিলিয়ে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtHot = 'গরম জোড়া ক্যামেরায় ধরেছেন';
  static const caughtScan = "সব ক'টা ওয়ে স্ক্যান করেছেন";
  static const caughtFix = 'বোর্ড ডেড প্রমাণ করে টাইটের কাজ';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';
  static const caughtAll = [caughtHot, caughtScan, caughtFix, caughtCall];

  /// The coworker's new push (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworker.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => <String>{
        intro,
        askSweep,
        askFix,
        askHandIn,
        moreHot,
        ...whyQ.values,
        ...tapWhy,
        ...coworker.asks,
        callHeld,
        allSet,
        fail,
        for (final m in M6PillarThermalMistakes.all) m.textBn,
      }.toList();
}

abstract final class M6PillarThermalMistakes {
  static const _dir = 'assets/game/art/m6_pillar_thermal';

  // DRAFT wording — owner (M6-12).
  static const evenTag = DoMistake(
    key: '6.9/m6_pillar_thermal/even-tag',
    textBn: 'এই জোড়াটা পাশের জোড়াগুলোর মতোই — হটস্পট নয়। অকারণে কাজ লিখবেন না; একই ওয়ের অন্য জোড়ার সঙ্গে মিলিয়ে দেখুন।',
    art: '$_dir/even_tag.svg',
    lessonPoint: 2,
  );
  static const missedHot = DoMistake(
    key: '6.9/m6_pillar_thermal/missed-hot',
    textBn: 'একটা গরম জোড়া ধরা পড়েনি! ঢিলা কানেকশনে স্পার্কিং আর হটস্পট — এর থেকেই লো-ভোল্টেজ, পাওয়ার কাট। প্রতিটা ওয়ে ক্যামেরায় দেখুন।',
    art: '$_dir/missed_hot.svg',
    lessonPoint: 2,
  );
  static const unscanned = DoMistake(
    key: '6.9/m6_pillar_thermal/unscanned',
    textBn: 'একটা ওয়ে না দেখেই শেষ! থার্মাল ক্যামেরায় প্রতিটা ওয়ে দেখলে চোখে দেখার আগেই লুজ কানেকশন ধরা যায়।',
    art: '$_dir/unscanned.svg',
    lessonPoint: 2,
  );
  static const listened = DoMistake(
    key: '6.9/m6_pillar_thermal/listened',
    textBn: 'চোখে কিছু না দেখা মানেই সব ঠিক নয় — থার্মাল ক্যামেরা চোখে দেখার আগেই হটস্পট ধরে। না দেখা ওয়েতে গরম জোড়া থেকে যেতে পারে।',
    art: '$_dir/unscanned.svg',
    lessonPoint: 2,
  );
  static const leaveIt = DoMistake(
    key: '6.9/m6_pillar_thermal/leave-it',
    textBn: 'গরম জোড়া “চলছে তো” বলে ছাড়লে স্পার্কিং বাড়ে — শেষে লো-ভোল্টেজ, পাওয়ার কাট, বড় দুর্ঘটনা। লুজ কানেকশন টাইট দেওয়ার কাজ লিখুন।',
    art: '$_dir/leave_it.svg',
    lessonPoint: 2,
  );
  static const water = DoMistake(
    key: '6.9/m6_pillar_thermal/water',
    textBn: 'চালু জোড়ায় জল মানেই শর্ট সার্কিট আর আর্ক ফ্ল্যাশ! আগে DTR-এর LT সুইচ OFF, তালা-ট্যাগ, টেস্টারে ডেড প্রমাণ — তারপর টাইট।',
    art: '$_dir/water.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const bareHand = DoMistake(
    key: '6.9/m6_pillar_thermal/bare-hand',
    textBn: 'পিলারের ভেতরটা লাইভ প্যানেলের মতোই বিপজ্জনক — চালু অবস্থায় খালি হাতে নাট নয়! DTR-এর LT সুইচ OFF, তালা-ট্যাগ, টেস্টারে ডেড প্রমাণ, তারপর টাইট।',
    art: '$_dir/live_tighten.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const insulatedLive = DoMistake(
    key: '6.9/m6_pillar_thermal/insulated-live',
    textBn: 'ইনসুলেটেড স্প্যানার হলেও চালু বোর্ডের জোড়ায় হাত নয় — 415 ভোল্টের বিশাল ফল্ট কারেন্টে আর্ক ফ্ল্যাশ। আগে LT OFF, তালা-ট্যাগ, টেস্টারে ডেড প্রমাণ।',
    art: '$_dir/live_tighten.svg',
    deadly: true,
    lessonPoint: 1,
  );
  // Lesson 6.9 myth 2 and its reality (not a numbered point).
  static const thickWire = DoMistake(
    key: '6.9/m6_pillar_thermal/thick-wire',
    textBn: 'ফিউজের জায়গায় মোটা তার বা পাত ফিউজের সুরক্ষাই নষ্ট করে — ফল্টের সময় ফিউজ না উড়ে কেবিল বা ট্রান্সফরমার পুড়ে যাবে।',
    art: '$_dir/thick_wire.svg',
    deadly: true,
  );

  static DoMistake? forFix(M6ThermalFix f) => switch (f) {
        M6ThermalFix.deadTighten => null,
        M6ThermalFix.water => water,
        M6ThermalFix.bareHand => bareHand,
        M6ThermalFix.insulatedLive => insulatedLive,
        M6ThermalFix.thickWire => thickWire,
        M6ThermalFix.leaveIt => leaveIt,
      };

  static const List<DoMistake> all = [evenTag, missedHot, unscanned, listened, leaveIt, water, bareHand, insulatedLive, thickWire];
}

/// A dealt hotspot.
@immutable
class M6ThermalSpot {
  const M6ThermalSpot({required this.unit, required this.slot, this.late = false});
  final int unit;
  final M6Slot slot;

  /// Hot long enough to show to the eye (blackened, a smell wisp).
  final bool late;

  (int, M6Slot) get at => (unit, slot);

  @override
  bool operator ==(Object other) => other is M6ThermalSpot && other.unit == unit && other.slot == slot && other.late == late;

  @override
  int get hashCode => Object.hash(unit, slot, late);
}

@immutable
class M6ThermalDeal {
  const M6ThermalDeal({
    required this.ways,
    required this.metal,
    required this.mirror,
    required this.spots,
    required this.tones,
    required this.coworkerAfter,
  });

  /// Outgoing ways (3–5); columns are the incomer (0) and F1….
  final int ways;
  final bool metal;
  final bool mirror;
  final List<M6ThermalSpot> spots;

  /// Every joint's tone on the camera (0…1), per column.
  final List<Map<M6Slot, double>> tones;

  /// He comes once the frame has stayed on this many clean columns (1 or 2).
  final int coworkerAfter;

  int get units => ways + 1;
  bool hotUnit(int u) => spots.any((s) => s.unit == u);
}

/// ms the frame must stay on a column for it to count as scanned.
const int kM6DwellMs = 1000;

M6ThermalDeal m6ThermalDeal(math.Random rng) {
  final ways = 3 + rng.nextInt(3);
  final units = ways + 1;
  final metal = rng.nextBool();
  final mirror = rng.nextBool();
  final hotCount = 1 + rng.nextInt(2);
  late List<int> hot;
  late int after;
  late List<int> hidden;
  for (var tries = 0;; tries++) {
    hot = ([for (var u = 0; u < units; u++) u]..shuffle(rng)).take(hotCount).toList()..sort();
    final clean = [for (var u = 0; u < units; u++) if (!hot.contains(u)) u];
    after = clean.length >= 3 && rng.nextBool() ? 2 : 1;
    // A hotspot still to come (counting from the incomer outward) when he
    // comes after the after-th clean column.
    final kth = clean[after - 1];
    hidden = [for (final u in hot) if (u > kth) u];
    if (hidden.isNotEmpty || tries > 60) break;
  }
  if (hidden.isEmpty) {
    // Never reached in practice; keep the rule anyway: the last column hot.
    hot = [units - 1];
    after = 1;
    hidden = [units - 1];
  }
  final before = hidden[rng.nextInt(hidden.length)];
  final tones = <Map<M6Slot, double>>[];
  for (var u = 0; u < units; u++) {
    final base = 0.14 + rng.nextDouble() * 0.38;
    tones.add({
      for (final s in M6Slot.values) s: s == M6Slot.n ? base - 0.04 + (rng.nextDouble() - 0.5) * 0.06 : base + (rng.nextDouble() - 0.5) * 0.08,
    });
  }
  final spots = <M6ThermalSpot>[];
  for (final u in hot) {
    final slots = m6SlotsOf(u);
    // The neutral bolt a little less often than a phase joint.
    final slot = rng.nextDouble() < 0.12 ? M6Slot.n : slots.where((s) => s != M6Slot.n).elementAt(rng.nextInt(slots.length - 1));
    final late = hot.length == 2 && u != before && rng.nextBool();
    spots.add(M6ThermalSpot(unit: u, slot: slot, late: late));
    final base = [for (final s in slots) tones[u][s]!].reduce(math.max);
    tones[u][slot] = math.min(0.97, base + 0.26 + rng.nextDouble() * 0.12);
  }
  return M6ThermalDeal(ways: ways, metal: metal, mirror: mirror, spots: spots, tones: tones, coworkerAfter: after);
}

/// The play state (pure logic).
class M6ThermalRun {
  M6ThermalRun(this.deal);
  final M6ThermalDeal deal;

  var stage = M6ThermalStage.scan;
  int slips = 0;
  int stageSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// Columns the frame has stayed on (or tagged on).
  final Set<int> scanned = {};

  /// Hotspots on the job card, in the order found.
  final List<M6ThermalSpot> tagged = [];

  /// Even joints already tagged (a slip once each).
  final Set<(int, M6Slot)> evenTagged = {};

  /// The hotspot whose job is being written (stage fix).
  int fixIndex = 0;

  /// Where the frame is now (the page writes it; tests read it).
  double frameX = 0;

  bool get ended => stage == M6ThermalStage.done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => stage == M6ThermalStage.done && deadly == null && percent >= 55;
  bool get thorough => stageSlips == 0;

  /// Columns the frame has passed over (no dwell needed), as well as the
  /// scanned ones: a quick sweep shows every column but scans none.
  final Set<int> seen = {};

  int get cleanScanned => scanned.where((u) => !deal.hotUnit(u)).length;
  int get cleanSeen => {...seen, ...scanned}.where((u) => !deal.hotUnit(u)).length;

  /// The frame passed over column [u].
  void see(int u) {
    if (u >= 0 && u < deal.units) seen.add(u);
  }

  /// A column still unscanned that looks fine to the eye (not a 'late'
  /// hotspot's blackened column): his "চোখে তো কিছু দেখা যাচ্ছে না… সব ঠিক
  /// আছে" is true to the eye and a wrong push (listening ends the scan with
  /// that column unscanned). He comes only while this holds.
  bool get uncheckedLeft {
    for (var u = 0; u < deal.units; u++) {
      if (scanned.contains(u)) continue;
      if (deal.spots.any((s) => s.late && s.unit == u && !tagged.contains(s))) continue;
      return true;
    }
    return false;
  }

  M6ThermalSpot? spotAt(int u, M6Slot s) {
    for (final p in deal.spots) {
      if (p.unit == u && p.slot == s) return p;
    }
    return null;
  }

  /// Hotspots left behind once the scan is over.
  List<M6ThermalSpot> get missed => stage == M6ThermalStage.scan ? const [] : [for (final s in deal.spots) if (!tagged.contains(s)) s];

  M6ThermalSpot? get fixSpot => stage == M6ThermalStage.fix && fixIndex < tagged.length ? tagged[fixIndex] : null;

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stageSlips++;
    return m;
  }

  /// The frame stayed on column [u]: true when it is newly scanned.
  bool scan(int u) {
    if (ended || stage != M6ThermalStage.scan || u < 0 || u >= deal.units) return false;
    return scanned.add(u);
  }

  /// A tap on joint [s] of column [u] on the live screen.
  M6Tag tag(int u, M6Slot s) {
    if (ended || stage != M6ThermalStage.scan) return M6Tag.closed;
    scanned.add(u);
    final hot = spotAt(u, s);
    if (hot != null) {
      if (tagged.contains(hot)) return M6Tag.again;
      tagged.add(hot);
      _tag(M6PillarThermalLines.caughtHot);
      return M6Tag.hot;
    }
    if (!evenTagged.add((u, s))) return M6Tag.again;
    _slip(M6PillarThermalMistakes.evenTag);
    return M6Tag.even;
  }

  void _afterScan() {
    stage = tagged.isEmpty ? M6ThermalStage.handIn : M6ThermalStage.fix;
    fixIndex = 0;
  }

  /// 'স্ক্যান শেষ': a hotspot left behind, else a column never scanned, is a
  /// slip; a full scan is right. The scan is over either way.
  DoMistake? endScan() {
    if (ended || stage != M6ThermalStage.scan) return null;
    final full = scanned.length >= deal.units;
    final left = deal.spots.any((s) => !tagged.contains(s));
    _afterScan();
    if (left) return _slipNewStage(M6PillarThermalMistakes.missedHot);
    if (!full) return _slipNewStage(M6PillarThermalMistakes.unscanned);
    // A full scan: its reason's bonus counts the scan's own slips.
    _tag(M6PillarThermalLines.caughtScan);
    return null;
  }

  DoMistake _slipNewStage(DoMistake m) {
    stageSlips = 0;
    slips++;
    return m;
  }

  /// Listened to him: the scan ends here (a slip).
  DoMistake listen() {
    if (stage == M6ThermalStage.scan) _afterScan();
    return _slipNewStage(M6PillarThermalMistakes.listened);
  }

  /// The job written for the hotspot in hand.
  DoMistake? fix(M6ThermalFix f) {
    if (ended || stage != M6ThermalStage.fix) return null;
    final m = M6PillarThermalMistakes.forFix(f);
    if (m == null) {
      _tag(M6PillarThermalLines.caughtFix);
      fixIndex++;
      if (fixIndex >= tagged.length) stage = M6ThermalStage.handIn;
      return null;
    }
    if (m.deadly) return deadly = m;
    return _slip(m);
  }

  /// A new job deck (a new hotspot): its own slips count afresh.
  void nextJob() => stageSlips = 0;

  /// Hand in the job card.
  bool handIn() {
    if (ended || stage != M6ThermalStage.handIn) return false;
    stage = M6ThermalStage.done;
    return true;
  }

  /// Listening to a deadly push (none in this level) / an outside fail.
  void failDeadly(DoMistake m) => deadly = m;
}

/// The quick bonus: a little under a thorough play (~85 %, rounded).
/// ms, ~1500 per human action:
///   স্ক্যান: 4–6 columns × (drag ≈ 1500 + dwell 1000 + a look ≈ 1000)
///     ≈ 14000–21000; 1–2 tags ≈ 1500–3000; স্ক্যান শেষ 1500
///   reasons: tag + scan + 1–2 fixes ≈ 3–4 × 8200 ≈ 24600–32800
///   job decks: 1–2 × (preview + ✓ ≈ 3000); hand in 1500
///   the coworker once ≈ 9600                                ≈ 56000–75000
/// 55 s ≈ 85 % of the middle (~65500) of that range, about the short end
/// itself (a builder's estimate; owner may tune).
const m6PillarThermalQuickMs = 55000;

@immutable
class M6PillarThermalPack {
  const M6PillarThermalPack({required this.id, required this.titleBn, this.quickMs = m6PillarThermalQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6PillarThermalPack> m6PillarThermalPacks = {
  'do_6_9_a': M6PillarThermalPack(id: 'do_6_9_a', titleBn: M6PillarThermalLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M6PillarThermalProbe {
  static M6ThermalRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M6PillarThermalPage extends StatefulWidget {
  const M6PillarThermalPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6PillarThermalPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6PillarThermalPage> createState() => _M6PillarThermalPageState();
}

class _M6PillarThermalPageState extends State<M6PillarThermalPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _ThermalRunPage(
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

class _ThermalRunPage extends ConsumerStatefulWidget {
  const _ThermalRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6PillarThermalPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_ThermalRunPage> createState() => _ThermalRunPageState();
}

class _ThermalRunPageState extends ConsumerState<_ThermalRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6ThermalRun _run;
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

  /// The camera in hand (drag start: finger x, frame x).
  (double, double)? _drag;
  Timer? _dwell;

  /// The job deck for the hotspot in hand.
  List<ChoiceOption> _fixOpts = const [];
  final Set<String> _fixWrong = {};
  String? _fixPicked;
  int _fixDeal = 0;

  /// A card was picked on this deal (no second pick until it is re-dealt).
  var _fixBusy = false;

  /// What the open reason is about (where to go after it).
  M6ThermalWhy _whyTopic = M6ThermalWhy.tag;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;
  var _flashWater = false;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final Map<M6Slot, GlobalKey> _jointKeys = {for (final s in M6Slot.values) s: GlobalKey()};
  final _scanKey = GlobalKey();
  final _handInKey = GlobalKey();
  int _hintN = 0;
  int _steps = 0;
  M6ThermalGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M6ThermalRun(m6ThermalDeal(widget.rng));
    M6PillarThermalProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    _dwell?.cancel();
    disposeCoworker();
    _chain++;
    if (identical(M6PillarThermalProbe.run, _run)) M6PillarThermalProbe.run = null;
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

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_freeze;

  String get _task => switch (_run.stage) {
        M6ThermalStage.scan => M6PillarThermalLines.askSweep,
        M6ThermalStage.fix => M6PillarThermalLines.askFix,
        _ => M6PillarThermalLines.askHandIn,
      };

  M6ThermalGeo _geoFor(double h, double inset) => M6ThermalGeo.forScene(h, inset, ways: _run.deal.ways, mirror: _run.deal.mirror);

  /// The column in the frame now.
  int? get _unitNow => _geoNow?.unitAt(_run.frameX);

  Future<void> _start() async {
    _clock.start();
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  // --- the camera ---------------------------------------------------------------
  /// The frame starts to dwell on the column it is on (silently).
  void _armDwell() {
    _dwell?.cancel();
    _dwell = null;
    final u = _unitNow;
    if (u == null || _run.stage != M6ThermalStage.scan || _run.scanned.contains(u)) return;
    _dwell = Timer(const Duration(milliseconds: kM6DwellMs), () => _dwellDone(u));
  }

  void _dwellDone(int u) {
    _dwell = null;
    if (!mounted || _ended || _unitNow != u || _run.stage != M6ThermalStage.scan) return;
    // A card, a deck or the coworker: the dwell starts again afterwards.
    if (!_canPlay) return;
    if (_run.scan(u)) _maybeCoworker();
  }

  bool get _coworkerFree => !coworkerDone && !coworkerDue && !coworkerOpen && _run.stage == M6ThermalStage.scan && _run.uncheckedLeft;

  /// He is dealt after the frame stayed on the n-th clean column, while a
  /// column that looks fine is still unscanned ([M6ThermalRun.uncheckedLeft]).
  void _maybeCoworker() {
    if (!_coworkerFree) return;
    if (_run.cleanScanned >= _run.deal.coworkerAfter) scheduleCoworker();
  }

  /// At a decisive control (a tag, 'স্ক্যান শেষ'): a quick sweep that passed
  /// over the n-th clean column without staying on it still brings him, now,
  /// before the control works (he can't be skipped by playing fast).
  bool _holdAtControl() {
    if (_coworkerFree && _run.cleanSeen >= _run.deal.coworkerAfter) scheduleCoworker();
    return holdForCoworker();
  }

  /// Every column the frame passed over between [x0] and [x1] (a fast swipe
  /// may jump over one between two pointer events).
  void _seeBetween(M6ThermalGeo geo, double x0, double x1) {
    final lo = math.min(x0, x1), hi = math.max(x0, x1);
    for (var u = 0; u < _run.deal.units; u++) {
      final x = geo.unitX(u), r = geo.unitReach(u);
      if (x + r >= lo && x - r <= hi) _run.see(u);
    }
  }

  /// Play comes back (after a card, a reason or him).
  void _resume() {
    if (!mounted || _ended) return;
    setState(() => _wake++);
    _armDwell();
  }

  void _panStart(Offset p, M6ThermalGeo geo) {
    _drag = null;
    if (!_canPlay || _run.stage != M6ThermalStage.scan) return;
    if (!geo.dragHit.inflate(8).contains(p)) return;
    if (holdForCoworker()) return;
    _drag = (p.dx, _run.frameX);
  }

  void _panUpdate(Offset p, M6ThermalGeo geo) {
    final d = _drag;
    if (d == null) return;
    if (!_canPlay) {
      _drag = null;
      return;
    }
    final before = geo.unitAt(_run.frameX);
    final nx = (d.$2 + p.dx - d.$1).clamp(geo.frameMinX, geo.frameMaxX);
    if (nx == _run.frameX) return;
    _seeBetween(geo, _run.frameX, nx);
    setState(() => _run.frameX = nx);
    final now = geo.unitAt(nx);
    if (now != before) {
      if (now != null) _tick('sounds/intro/tick.ogg', 0.25);
      _armDwell();
    }
  }

  void _panEnd() {
    if (_drag == null) return;
    _drag = null;
    _stepDone();
  }

  void _tapScene(Offset p, M6ThermalGeo geo, Offset global) {
    if (!_canPlay) return;
    if (_run.stage == M6ThermalStage.scan) {
      final u = geo.unitAt(_run.frameX);
      if (u != null) {
        for (final s in m6SlotsOf(u)) {
          if (geo.camJointHit(u, s).contains(p)) {
            _tagJoint(u, s, global);
            return;
          }
        }
      }
    }
    _hints.missTap();
  }

  void _tagJoint(int u, M6Slot s, Offset global) {
    if (_holdAtControl()) return;
    final firstHot = _run.tagged.isEmpty;
    final r = _run.tag(u, s);
    switch (r) {
      case M6Tag.hot:
        _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
        HapticFeedback.mediumImpact();
        _stepDone();
        if (firstHot) {
          _hush();
          putOnTable(15);
          _whyTopic = M6ThermalWhy.tag;
          unawaited(askReason(
            deal: () => dealChoices(M6PillarThermalLines.whyRight[M6ThermalWhy.tag]!, M6PillarThermalLines.myths, widget.rng),
            question: M6PillarThermalLines.whyQ[M6ThermalWhy.tag]!,
            stillValid: () => !_ended && _run.stage == M6ThermalStage.scan,
          ));
        } else {
          unawaited(_levelDelta(10, global, mood: GuideMood.glad));
          unawaited(_sayChain([M6PillarThermalLines.moreHot]));
        }
      case M6Tag.even:
        _maybeCoworker();
        setState(() => _wake++);
        unawaited(_mistake(M6PillarThermalMistakes.evenTag, global));
      case M6Tag.again:
      case M6Tag.closed:
        _tick();
    }
  }

  void _endScan(Offset global) {
    if (!_canPlay || _run.stage != M6ThermalStage.scan) return;
    if (_holdAtControl()) return;
    _dwell?.cancel();
    _dwell = null;
    _tick('sounds/intro/click.ogg', 0.6);
    final m = _run.endScan();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    _whyTopic = M6ThermalWhy.scan;
    unawaited(askReason(
      deal: () => dealChoices(M6PillarThermalLines.whyRight[M6ThermalWhy.scan]!, M6PillarThermalLines.myths, widget.rng),
      question: M6PillarThermalLines.whyQ[M6ThermalWhy.scan]!,
      stillValid: () => !_ended,
    ));
  }

  // --- the job card ---------------------------------------------------------------
  /// After the scan (or a job): the next deck, or the hand-in.
  void _enterStage() {
    if (!mounted || _ended) return;
    if (_run.stage == M6ThermalStage.fix) {
      _dealFix();
    } else {
      setState(() => _wake++);
    }
    unawaited(_sayChain([_task]));
  }

  void _dealFix() {
    setState(() {
      _fixOpts = dealChoices(M6PillarThermalLines.fixRight, M6PillarThermalLines.fixWrong.values.toList(), widget.rng);
      _fixWrong.clear();
      _fixPicked = null;
      _fixBusy = false;
      _fixDeal++;
      _wake++;
    });
  }

  bool get _fixDeckUp => _run.stage == M6ThermalStage.fix && _fixOpts.isNotEmpty && !_intro && !_ended && _card == null && !tableBusy && !_freeze;

  Future<void> _pickFix(ChoiceOption o, Offset at) async {
    if (!_fixDeckUp || _fixPicked != null || _fixBusy) return;
    final spot = _run.fixSpot;
    if (spot == null) return;
    _fixBusy = true;
    final f = M6PillarThermalLines.fixOf(o.textBn);
    final m = _run.fix(f);
    if (m == null) {
      setState(() => _fixPicked = o.textBn);
      _hush();
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted || _ended) return;
      setState(() => _fixOpts = const []);
      putOnTable(15 + (_run.thorough ? 5 : 0));
      _whyTopic = M6ThermalWhy.fix;
      unawaited(askReason(
        deal: () => dealChoices(M6PillarThermalLines.whyRight[M6ThermalWhy.fix]!, M6PillarThermalLines.myths, widget.rng),
        question: M6PillarThermalLines.whyQ[M6ThermalWhy.fix]!,
        stillValid: () => !_ended,
      ));
      return;
    }
    setState(() => _fixWrong.add(o.textBn));
    if (m.deadly) {
      final geo = _geoNow;
      if (geo != null) _flashAt = geo.joint(spot.unit, spot.slot);
      _flashWater = f == M6ThermalFix.water;
      await _deadly(m);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || _ended) return;
    unawaited(_mistake(m, at));
  }

  void _handIn() {
    if (!_canPlay || _run.stage != M6ThermalStage.handIn) return;
    _tick('sounds/learn/tag_slap.ogg', 0.6);
    if (!_run.handIn()) return;
    _stepDone();
    unawaited(_finish());
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
    final topic = _whyTopic;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 900), () {
      if (!mounted || _ended) return;
      if (topic == M6ThermalWhy.tag) {
        _resume();
        unawaited(_sayChain([_task]));
        return;
      }
      _run.nextJob();
      _enterStage();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M6PillarThermalLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.stage != M6ThermalStage.scan || !_run.uncheckedLeft) return null;
    if (_intro || _card != null || tableBusy || _freeze) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    _drag = null;
    if (!held) {
      _dwell?.cancel();
      _dwell = null;
      final m = _run.listen();
      setState(() => _wake++);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M6PillarThermalLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    _resume();
    unawaited(_sayChain([M6PillarThermalLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6PillarThermalLines.tapWhy[_nudgeN++ % M6PillarThermalLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _dwell?.cancel();
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
      _drag = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6thermal/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A live joint touched (water, a spanner, a hand) or the fuse bypassed:
  /// the scene freezes grey and the arc flash comes off the joint in colour;
  /// then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _dwell?.cancel();
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
    final speak = await SpokenOnce.first('m6thermal/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6PillarThermalLines.deadlyWord : M6PillarThermalLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        if (_run.stage == M6ThermalStage.scan) {
          _resume();
          unawaited(_sayChain([_task]));
        } else {
          _enterStage();
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
    _dwell?.cancel();
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
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _clock.elapsedMilliseconds < widget.pack.quickMs);
    if (_run.passed) {
      await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
      await save.recordStars(_rungId, stars);
    }
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? M6PillarThermalLines.fail : (_quickBonus ? M6PillarThermalLines.quick : M6PillarThermalLines.allSet),
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
    if (_run.stage == M6ThermalStage.scan) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M6PillarLook get _look => M6PillarLook(
        metal: _run.deal.metal,
        late: [for (final s in _run.deal.spots) if (s.late) s.at],
        missed: [for (final s in _run.missed) s.at],
        tagged: [for (final s in _run.tagged) s.at],
      );

  /// The gesture hand: how to touch, never what. The job card to hand in: a
  /// tap on 'জমা দিন' (the one way on). Scanning: a fixed left-to-right drag
  /// nudge on the frame; with the frame on a column, in turn, a sweep over
  /// every joint on the live screen and 'স্ক্যান শেষ' alike.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    if (_run.stage == M6ThermalStage.handIn) return HintSpec.tapOn(_handInKey);
    if (_run.stage != M6ThermalStage.scan) return null;
    final n = _hintN++;
    final u = geo.unitAt(_run.frameX);
    if (u == null || n.isEven) {
      return HintSpec.drag(geo.frameAt(_run.frameX).center, toward: const Offset(1, 0), travel: 80, space: HintSpace.scene);
    }
    return HintSpec.sweepOver([for (final s in m6SlotsOf(u)) _jointKeys[s]!, _scanKey]);
  }

  List<Widget> _scene(SceneMetrics m) {
    final first = _geoNow == null;
    final geo = _geoNow = _geoFor(m.height, m.inset);
    if (first) _run.frameX = geo.frameStart;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final u = geo.unitAt(_run.frameX);
    final scanning = _run.stage == M6ThermalStage.scan;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('pillar'),
                child: RepaintBoundary(child: CustomPaint(painter: M6PillarPainter(geo: geo, look: _look))),
              ),
              if (scanning)
                Positioned.fill(
                  key: const ValueKey('frame'),
                  child: RepaintBoundary(child: CustomPaint(painter: M6AimFramePainter(rect: geo.frameAt(_run.frameX), on: u != null))),
                ),
              Positioned.fill(
                key: const ValueKey('screen'),
                child: Semantics(
                  label: M6PillarThermalLines.camLabel,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: M6ThermalScreenPainter(
                        geo: geo,
                        unit: scanning ? u : null,
                        tones: u == null || !scanning ? const {} : _run.deal.tones[u],
                        tagged: u == null ? const {} : {for (final s in _run.tagged) if (s.unit == u) s.slot},
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('job-card'),
                rect: geo.jobCard,
                child: _JobCard(
                  entries: [for (final s in _run.tagged) M6PillarThermalLines.entry(s.unit, s.slot)],
                  fixed: _run.stage == M6ThermalStage.fix ? _run.fixIndex : (_run.stage.index > M6ThermalStage.fix.index ? _run.tagged.length : 0),
                  current: _run.stage == M6ThermalStage.fix ? _run.fixIndex : null,
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
      // The joints' places on the live screen, for the sweep (no paint).
      if (scanning && u != null)
        for (final s in m6SlotsOf(u))
          Positioned.fromRect(
            key: ValueKey('joint-box-${s.name}'),
            rect: geo.camJointHit(u, s),
            child: IgnorePointer(child: SizedBox.expand(key: _jointKeys[s])),
          ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M6PillarThermalLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, geo),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: () => _drag = null,
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
              builder: (_, v, _) => CustomPaint(painter: M6ThermalFlashPainter(at: _flashAt, v: v, water: _flashWater)),
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
    final fixUp = playing && _fixDeckUp;
    final deckUp = reasonOpen || coworkerChoiceUp || fixUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !tableBusy;
    final stage = _run.stage;
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
              labels: M6PillarThermalLines.stages,
              done: {for (var i = 0; i < math.min(stage.index, 3); i++) i},
              current: stage == M6ThermalStage.done ? null : stage.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && (stage == M6ThermalStage.scan || stage == M6ThermalStage.handIn),
            hintKey: '${stage.name}/$_steps/${_unitNow ?? -1}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && stage == M6ThermalStage.scan)
                Positioned(
                  key: const ValueKey('hud-scan-done'),
                  right: 8,
                  bottom: pad.bottom + 10,
                  child: _PillButton(key: _scanKey, icon: Icons.task_alt_rounded, label: M6PillarThermalLines.scanDone, onTap: _endScan),
                ),
              if (handsOn && stage == M6ThermalStage.handIn)
                Positioned(
                  key: const ValueKey('hud-hand-in'),
                  right: 8,
                  bottom: pad.bottom + 10,
                  child: _PillButton(key: _handInKey, icon: Icons.assignment_turned_in_rounded, label: M6PillarThermalLines.handIn, onTap: (_) => _handIn()),
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
                        : coworkerChoiceUp
                            ? coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck'))
                            : ChoiceDeck(
                                key: ValueKey('fix-deck-$_fixDeal'),
                                options: _fixOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _fixWrong,
                                picked: _fixPicked,
                                onPick: (o, at) => unawaited(_pickFix(o, at)),
                              ),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
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
                  line: M6PillarThermalLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: m6ThermalLessonPoint, muted: _muted)),
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

/// The job card on the floor row: the tagged joints as written (never a
/// count of what is left), the one whose job is being written marked, the
/// jobs written ticked 'টাইট'.
class _JobCard extends StatelessWidget {
  const _JobCard({required this.entries, required this.fixed, required this.current});
  final List<String> entries;

  /// How many entries already have their job written.
  final int fixed;

  /// The entry whose job is being written now.
  final int? current;

  @override
  Widget build(BuildContext context) {
    final ink = bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF2A2018));
    return Semantics(
      label: M6PillarThermalLines.jobCard,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F1DE),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF8A6A3C), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(M6PillarThermalLines.jobCard, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A16))),
                  const Spacer(),
                  Text(M6PillarThermalLines.jobCardSub, style: ink),
                ],
              ),
              const Divider(height: 5, thickness: 1, color: Color(0x668A6A3C)),
              for (final (i, e) in entries.indexed)
                Container(
                  key: ValueKey('job-entry-$i'),
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: current == i ? const Color(0xFFFFE08A) : const Color(0x00000000),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(i < fixed ? '$e — ${M6PillarThermalLines.fixedMark}' : e, style: ink),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 'স্ক্যান শেষ' / 'জমা দিন': a pill with an icon.
class _PillButton extends StatelessWidget {
  const _PillButton({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52, minWidth: 104),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: SlmColors.gold300),
              const SizedBox(width: 6),
              Text(label, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}
