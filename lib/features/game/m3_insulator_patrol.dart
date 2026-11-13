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
import 'm3_insulator_patrol_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show Carry, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm3_insulator_patrol_world.dart'
    show M3InsulatorPatrolBody, M3InsulatorPatrolFault, M3InsulatorPatrolGeo, M3InsulatorPatrolKind, M3InsulatorPatrolUnit;

// Lesson 3.2 "ইনসুলেটর পরিচিতি: পিন, ডিস্ক, শ্যাকল", কাজ 2 "দূরবিনে টহল"
// (Module 3). A patrol along a live line: at each pole the trainee looks at
// the pole's head through binoculars from the ground (lesson point 1's daily
// check: "নিচ থেকে বাইনোকুলার দিয়ে … ইনসুলেটর কি ভাঙা? নাকি কালচে দাগ
// আছে?"), marks every faulty insulator, and decides: all fine, or report.
// Three poles a play, dealt fresh — an 11 kV cross-arm with three pin
// insulators, a 33 kV cross-arm with three strings of three discs (pro tip
// 1), an LT pole with four shackles — one of them sound, the others with one
// or two faults from the lesson:
//   • a hairline crack (point 4), a broken corner (myth 1), black marks
//     (point 1), a bird's nest and droppings (pro tip 4), a salt/dust layer
//     (pro tip 2), a toughened glass disc gone to pieces (myth 2), a shackle
//     worn sharp (point 3);
//   • sound decoys: a polymer pin insulator (pro tip 3), a string of glass
//     discs (myth 2) — different is not faulty.
// Hands on: tap an insulator in the view to mark it (tap again to clear),
// then "সব ঠিক" or "রিপোর্ট".
//
// Slips: a fault left unmarked (or "সব ঠিক" on a faulty pole), a sound pole
// reported, a sound insulator marked (an over-call costs a slip; the guide's
// replies before the decision never say which pole is sound). Deadly (the careless coworker, once a
// play, on any of the three poles, the sound one too, so his arrival gives
// nothing away): "ওপরে উঠে কাছ থেকে দেখে নাও!" — listening = the climb onto
// a live pole before shutdown (the brief: line work only after shutdown,
// PTW, test and earth; point 1: "ইনসুলেটর … না থাকলে কারেন্ট পোল হয়ে
// মাটিতে নামত, আর যে পোলে হাত দিত, সে ওখানেই শেষ"). Three slips strike out. A report with nothing marked is not
// scored: the guide asks for the marks first (the same neutral line on any
// pole). On his pole the decision waits for him (holdForCoworker): a fast
// "সব ঠিক"/"রিপোর্ট" brings him in first. Gesture hints: a sweep over the
// insulators and both buttons while the pole waits; none during cards,
// decks, the freeze or the coworker's visit (the decks bring their own).
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m3_insulator_patrol_world.dart), corner guide, ◆ on the table →
// "কেন …?" → the next pole by itself. Voice: the guide's lines by device TTS;
// the coworker's push by TTS until recorded (his exit line is recorded).
//
// Flagged to the owner: the "patrol + report" framing (the lesson says only
// look from below before climbing; replace a broken one, clean droppings, wash
// salt); black marks as a reportable fault is from point 1's daily check, its
// fix is not named; the 11 kV pin / 33 kV three-disc / LT shackle heads follow
// the lesson's pro tip 1 and points 2–4.

// ============================================================================
// Content
// ============================================================================

/// One pole on the patrol.
@immutable
class M3InsulatorPatrolPole {
  const M3InsulatorPatrolPole({required this.id, required this.kind, required this.units});
  final String id;
  final M3InsulatorPatrolKind kind;
  final List<M3InsulatorPatrolUnit> units;

  Set<int> get faulty => {
        for (final (i, u) in units.indexed)
          if (u.bad) i,
      };

  List<M3InsulatorPatrolFault> get faults => [
        for (final u in units)
          if (u.fault != null) u.fault!,
      ];

  bool get sound => faulty.isEmpty;
  bool get hasPolymer => units.any((u) => u.body == M3InsulatorPatrolBody.polymer);
  bool get hasGlass => units.any((u) => u.body == M3InsulatorPatrolBody.glass && !u.bad);
}

/// What can go wrong on an insulator of [body] on a [kind] pole.
List<M3InsulatorPatrolFault> m3InsulatorPatrolFaultsFor(M3InsulatorPatrolKind kind, M3InsulatorPatrolBody body) {
  if (body == M3InsulatorPatrolBody.polymer) return const [];
  if (body == M3InsulatorPatrolBody.glass) return const [M3InsulatorPatrolFault.shattered];
  if (kind == M3InsulatorPatrolKind.shackle) {
    return const [M3InsulatorPatrolFault.sharp, M3InsulatorPatrolFault.burnt, M3InsulatorPatrolFault.bird];
  }
  return const [
    M3InsulatorPatrolFault.crack,
    M3InsulatorPatrolFault.chipped,
    M3InsulatorPatrolFault.burnt,
    M3InsulatorPatrolFault.bird,
    M3InsulatorPatrolFault.salt,
  ];
}

abstract final class M3InsulatorPatrolLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask];

  static const title = 'দূরবিনে টহল';
  static const intro = 'লাইনে টহল! দূরবিনে প্রতিটা ইনসুলেটর দেখুন — খারাপটায় দাগ দিন।';
  static const rounds = ['ক', 'খ', 'গ'];
  static const ask = 'খারাপ ইনসুলেটরে দাগ দিন, নয়তো বলুন সব ঠিক।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const markFirst = 'দাগ ছাড়া রিপোর্ট হয় না — দূরবিনে আবার দেখুন, তারপর ঠিক করুন।';

  // Labels a worker reads.
  static const sceneLabel = 'দূরবিনে পোলের মাথা';
  static const ok = 'সব ঠিক — পরের পোল';
  static const report = 'রিপোর্ট — ত্রুটি আছে';

  static const stampOk = 'পোল ঠিক আছে';
  static const stampReport = 'রিপোর্ট হলো';

  // The reasons: the right ones fit what this pole was; the wrong ones are
  // bad motives (to report) and myths (to pass). 36–44 letters each.
  static const whyReport = 'কেন রিপোর্ট করলেন?';
  static const whyOk = 'কেন পোলটা ঠিক বললেন?';

  static const faultWhy = <M3InsulatorPatrolFault, List<String>>{
    M3InsulatorPatrolFault.crack: ['সরু ফাটলেও হাই ভোল্টেজে ব্লাস্ট হতে পারে', 'ছোট ফাটলও বড় বিপদ, ওটা অবহেলা চলে না'],
    M3InsulatorPatrolFault.chipped: ['ভাঙা কোণায় জল-ধুলো জমে লিকেজ শুরু হয়', 'কোণা ভাঙা ইনসুলেটর বদলাতেই হবে, রাখা নয়'],
    M3InsulatorPatrolFault.burnt: ['কালচে দাগ বিপদের চিহ্ন, নিচ থেকেই জানাতে হয়', 'ইনসুলেটরে কালচে দাগ দেখলে রিপোর্ট নিয়ম'],
    M3InsulatorPatrolFault.bird: ['ভেজা বিষ্ঠা তারের মতো কারেন্ট বয়, ট্রিপ করে', 'বাসা-বিষ্ঠা পরিষ্কার না হলে বৃষ্টিতে ট্রিপ'],
    M3InsulatorPatrolFault.salt: ['লবণের স্তরে ভেজা দিনে লিক করে ফ্ল্যাশওভার', 'নোংরা ইনসুলেটর রুটিন করে ধোলাই করা মাস্ট'],
    M3InsulatorPatrolFault.shattered: ['টাফেনড গ্লাস নষ্ট হলে গুঁড়ো হয়, ওটাই চিহ্ন', 'গুঁড়ো হওয়া কাঁচের ডিস্কটা বদলাতে হবে'],
    M3InsulatorPatrolFault.sharp: ['ধারালো শ্যাকল কন্ডাক্টরের তার কেটে দিতে পারে', 'ঘষা খেয়ে ধারালো শ্যাকল তার কেটে ফেলে'],
  };
  static const reportExcuses = [
    'রিপোর্ট লিখলে ওভারটাইম মেলে, তাই লিখলাম',
    'সুপারভাইজার খুশি হবেন, তাই লিখে দিলাম',
    'ইনসুলেটর পুরোনো দেখাচ্ছিল, তাই লিখলাম',
    'নিজে উঠতে হবে না, তাই রিপোর্ট করে দিলাম',
    'সাথী বলল লিখে দাও, তাই আমিও লিখে দিলাম',
    'খাতায় কিছু না লিখলে ফাঁকা দেখায়, তাই',
  ];

  static const okWhy = ['প্রতিটা ইনসুলেটর দেখেছি, ফাটল-দাগ কিছু নেই', 'সব আস্ত — ভাঙা, কালচে দাগ, বাসা কিছুই নেই'];
  static const polymerWhy = 'পলিমার ইনসুলেটর ত্রুটি নয়, ওটা ভালো কাজ করে';
  static const glassWhy = 'কাঁচের ডিস্ক আস্ত আছে, নষ্ট হলে গুঁড়ো হতো';
  static const okMyths = [
    'পোলটা নতুন, তাই খুঁটিয়ে দেখার দরকার নেই',
    'একটু ভাঙা থাকলেও চিনামাটি তো অনেক মোটা',
    'নিচ থেকে কিছু বোঝা যায় না, তাই ঠিক বললাম',
    'তাড়া ছিল, তাই এক নজরে ঠিক বলে দিলাম',
    'পাখির বাসায় কিছু হয় না, তাই ঠিক বললাম',
    'কাঁচের ইনসুলেটর এমনিতেই ফালতু, বাদ দিলাম',
  ];

  static List<String> whyRight(M3InsulatorPatrolPole p) => p.sound
      ? [...okWhy, if (p.hasPolymer) polymerWhy, if (p.hasGlass) glassWhy]
      : faultWhy[p.faults.first]!;
  static List<String> whyWrong(M3InsulatorPatrolPole p) => p.sound ? okMyths : reportExcuses;

  /// The careless coworker: binoculars are for cowards, climb and look.
  static const coworker = CoworkerScript(
    line: 'দূর থেকে কী বুঝবে? ওপরে উঠে কাছ থেকে দেখে নাও!',
    exitLine: 'হুঁ! যা খুশি করুন।',
    right: ['না, লাইভ পোলে উঠব না — নিচ থেকেই দেখব', 'না, ভাঙা ইনসুলেটরে পোলটাই লাইভ হতে পারে', 'না, দূরবিনে দেখে রিপোর্ট, ওঠা শাটডাউনে'],
    wrong: [
      'ঠিক, ওপরে উঠে হাত দিয়ে দেখে নিই',
      'আচ্ছা, একটু উঠে কাছ থেকে দেখে আসি',
      'হ্যাঁ, পোল তো মাটিতে পোঁতা, ভয় নেই',
      'ঠিক আছে, তাড়াতাড়ি উঠে দেখে নামি',
      'ঠিক, দূরবিনে কিছু বোঝা যায় না, উঠি',
    ],
    asks: ['ও বলছে উঠে দেখতে। আপনি কী করবেন?', 'লাইভ পোলে উঠে দেখবেন?', 'উঠবেন, না নিচ থেকেই দেখবেন?'],
  );

  /// Said while the pole is still undecided: nothing about the verdict.
  static const callHeld = 'ঠিক! লাইভ পোলে ওঠা নয় — নিচ থেকে দূরবিনেই দেখুন।';
  static const allSet = 'টহল শিখে গেছেন — নিচ থেকে দূরবিনে দেখা, খারাপটা রিপোর্ট।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — দূরবিনে প্রতিটা ইনসুলেটর খুঁটিয়ে দেখুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caught = <M3InsulatorPatrolFault, String>{
    M3InsulatorPatrolFault.crack: 'দূরবিনে সরু ফাটল ধরেছেন',
    M3InsulatorPatrolFault.chipped: 'কোণা ভাঙা ইনসুলেটর ধরেছেন',
    M3InsulatorPatrolFault.burnt: 'কালচে দাগ ধরেছেন',
    M3InsulatorPatrolFault.bird: 'পাখির বাসা-বিষ্ঠা ধরেছেন',
    M3InsulatorPatrolFault.salt: 'লবণের আস্তরণ ধরেছেন',
    M3InsulatorPatrolFault.shattered: 'গুঁড়ো কাঁচের ডিস্ক ধরেছেন',
    M3InsulatorPatrolFault.sharp: 'ধারালো শ্যাকল ধরেছেন',
  };
  static const caughtSound = 'ভালো পোলকে ঠিক বলেছেন';
  static const caughtDecoy = 'পলিমার/কাঁচ মানেই খারাপ নয়';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class M3InsulatorPatrolMistakes {
  static const _dir = 'assets/game/art/m3_insulator_patrol';
  static const _k = '3.2/m3_insulator_patrol';

  static const missedCrack = DoMistake(
    key: '$_k/missed-crack',
    textBn: 'ফাটল চোখ এড়িয়ে গেল! সরু চুলের মতো ফাটলও ইগনোর নয় — হাই ভোল্টেজে ওখান দিয়েই ব্লাস্ট হয়।',
    art: '$_dir/missed_crack.svg',
    lessonPoint: 3,
  );
  static const missedChipped = DoMistake(
    key: '$_k/missed-chipped',
    textBn: 'কোণা ভাঙা ইনসুলেটর ছেড়ে দিলেন। ভাঙা খাঁজে জল-ধুলো জমে লিকেজ শুরু হয় — ওটা বদলাতেই হবে।',
    art: '$_dir/missed_chipped.svg',
    lessonPoint: 0,
  );
  static const missedBurnt = DoMistake(
    key: '$_k/missed-burnt',
    textBn: 'কালচে দাগ চোখে পড়েনি। নিচ থেকে দেখার নিয়ম — ইনসুলেটর কি ভাঙা? কালচে দাগ আছে? থাকলে রিপোর্ট।',
    art: '$_dir/missed_burnt.svg',
    lessonPoint: 0,
  );

  /// Pro tip 4 (not a lesson point).
  static const missedBird = DoMistake(
    key: '$_k/missed-bird',
    textBn: 'পাখির বাসা-বিষ্ঠা চোখে পড়েনি। ভেজা বিষ্ঠা তারের মতো কারেন্ট বয় — বৃষ্টির দিনে ওখান থেকেই লাইন ট্রিপ করবে।',
    art: '$_dir/missed_bird.svg',
  );

  /// Pro tip 2 (not a lesson point).
  static const missedSalt = DoMistake(
    key: '$_k/missed-salt',
    textBn: 'লবণ-ধুলোর আস্তরণ ধরা পড়েনি। কুয়াশা বা বৃষ্টিতে ওই স্তর দিয়েই কারেন্ট লিক করে ফ্ল্যাশওভার হয় — ধোলাই চাই।',
    art: '$_dir/missed_salt.svg',
  );

  /// Myth 2 (not a lesson point).
  static const missedShattered = DoMistake(
    key: '$_k/missed-shattered',
    textBn: 'গুঁড়ো হয়ে যাওয়া কাঁচের ডিস্ক দেখেননি। টাফেনড গ্লাস নষ্ট হলে গুঁড়ো হয়ে যায় — নিচ থেকেই বোঝা যায়।',
    art: '$_dir/missed_shattered.svg',
  );
  static const missedSharp = DoMistake(
    key: '$_k/missed-sharp',
    textBn: 'ঘষা খেয়ে ধারালো শ্যাকল ছেড়ে দিলেন। ওটা কন্ডাক্টরের ইনসুলেশন বা তার কেটে দিতে পারে।',
    art: '$_dir/missed_sharp.svg',
    lessonPoint: 2,
  );
  static const falseAlarm = DoMistake(
    key: '$_k/false-alarm',
    textBn: 'এই পোলের সব ইনসুলেটর ভালো ছিল। খুঁটিয়ে দেখে তবেই রিপোর্ট — পলিমার বা কাঁচের ইনসুলেটর মানেই খারাপ নয়।',
    art: '$_dir/false_alarm.svg',
    lessonPoint: 0,
  );
  static const falseMark = DoMistake(
    key: '$_k/false-mark',
    textBn: 'একটা ভালো ইনসুলেটরেও দাগ দিলেন। ফাটল, ভাঙা কোণা, কালচে দাগ, বাসা বা আস্তরণ দেখে তবেই দাগ — প্রতিটা আলাদা করে দেখুন।',
    art: '$_dir/false_mark.svg',
    lessonPoint: 0,
  );
  static const climbLive = DoMistake(
    key: '$_k/climb-live',
    textBn: 'লাইভ লাইনের পোলে ওঠা শুধু শাটডাউনের পরে। একটা ইনসুলেটর ফেইল করলেই পোলটাই লাইভ — যে হাত দেয়, সে ওখানেই শেষ। টহলে ওঠা নয়: নিচ থেকে দূরবিনে দেখুন।',
    art: '$_dir/climb_live.svg',
    deadly: true,
    lessonPoint: 0,
  );

  static DoMistake missed(M3InsulatorPatrolFault f) => switch (f) {
        M3InsulatorPatrolFault.crack => missedCrack,
        M3InsulatorPatrolFault.chipped => missedChipped,
        M3InsulatorPatrolFault.burnt => missedBurnt,
        M3InsulatorPatrolFault.bird => missedBird,
        M3InsulatorPatrolFault.salt => missedSalt,
        M3InsulatorPatrolFault.shattered => missedShattered,
        M3InsulatorPatrolFault.sharp => missedSharp,
      };

  static List<DoMistake> get all => [
        for (final f in M3InsulatorPatrolFault.values) missed(f),
        falseAlarm,
        falseMark,
        climbLive,
      ];
}

@immutable
class M3InsulatorPatrolDeal {
  const M3InsulatorPatrolDeal({required this.poles, required this.callAt});
  final List<M3InsulatorPatrolPole> poles;

  /// The pole the careless coworker comes at: any of the three, the sound
  /// one too, so his arrival never tells the verdict. Climbing a live pole
  /// before shutdown is deadly on any pole.
  final int callAt;
}

/// Three poles (pin, disc, shackle) in a fresh order: one sound, the others
/// with one or two faults (kinds spread over the play); sometimes a polymer
/// pin or a string of glass discs as a sound decoy.
M3InsulatorPatrolDeal m3InsulatorPatrolDeal(math.Random rng) {
  final kinds = [...M3InsulatorPatrolKind.values]..shuffle(rng);
  final soundAt = rng.nextInt(3);
  final twoAt = rng.nextBool() ? ([0, 1, 2]..remove(soundAt))[rng.nextInt(2)] : -1;
  final used = <M3InsulatorPatrolFault>{};
  final poles = <M3InsulatorPatrolPole>[];
  for (var p = 0; p < 3; p++) {
    final kind = kinds[p];
    final n = M3InsulatorPatrolGeo.count(kind);
    final bodies = List.filled(n, M3InsulatorPatrolBody.porcelain);
    if (kind == M3InsulatorPatrolKind.pin && rng.nextBool()) bodies[rng.nextInt(n)] = M3InsulatorPatrolBody.polymer;
    if (kind == M3InsulatorPatrolKind.disc && rng.nextBool()) {
      final s = rng.nextInt(3);
      for (var j = 0; j < 3; j++) {
        bodies[s * 3 + j] = M3InsulatorPatrolBody.glass;
      }
    }
    final faults = List<M3InsulatorPatrolFault?>.filled(n, null);
    final count = p == soundAt ? 0 : (p == twoAt ? 2 : 1);
    final onPole = <M3InsulatorPatrolFault>{};
    for (var k = 0; k < count; k++) {
      final free = [
        for (var i = 0; i < n; i++)
          if (faults[i] == null && m3InsulatorPatrolFaultsFor(kind, bodies[i]).where((f) => !onPole.contains(f)).isNotEmpty) i,
      ];
      final i = free[rng.nextInt(free.length)];
      final can = m3InsulatorPatrolFaultsFor(kind, bodies[i]).where((f) => !onPole.contains(f)).toList();
      final fresh = can.where((f) => !used.contains(f)).toList();
      final f = (fresh.isEmpty ? can : fresh)[rng.nextInt((fresh.isEmpty ? can : fresh).length)];
      faults[i] = f;
      onPole.add(f);
      used.add(f);
    }
    poles.add(M3InsulatorPatrolPole(
      id: 'p$p',
      kind: kind,
      units: [for (var i = 0; i < n; i++) M3InsulatorPatrolUnit(bodies[i], faults[i])],
    ));
  }
  return M3InsulatorPatrolDeal(poles: poles, callAt: rng.nextInt(3));
}

/// The play state (pure logic).
class M3InsulatorPatrolRun {
  M3InsulatorPatrolRun(this.deal);

  final M3InsulatorPatrolDeal deal;
  int index = 0;

  /// The insulators marked on this pole.
  final Set<int> marks = {};

  var shown = false;
  int slips = 0;
  int needless = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.poles.length;
  bool get ended => done || deadly != null;
  M3InsulatorPatrolPole get current => deal.poles[index.clamp(0, deal.poles.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get _open => !ended && !shown;

  /// The +5: two faults on one pole both found, or a decoy left unmarked.
  bool get thorough => current.faulty.length >= 2 || current.hasPolymer || current.hasGlass;

  /// Mark (or clear) insulator [i]; returns whether it is marked now.
  bool toggle(int i) {
    if (!_open || i < 0 || i >= current.units.length) return false;
    if (!marks.remove(i)) marks.add(i);
    return marks.contains(i);
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// "সব ঠিক" ([report] false) or "রিপোর্ট". A report with nothing marked is
  /// not scored: no mistake, [shown] stays false (see [needless]).
  DoMistake? decide({required bool report}) {
    if (!_open) return null;
    final p = current;
    if (report && marks.isEmpty) {
      needless++;
      return null;
    }
    shown = true;
    if (!report) {
      if (p.sound) {
        _tag(M3InsulatorPatrolLines.caughtSound);
        if (p.hasPolymer || p.hasGlass) _tag(M3InsulatorPatrolLines.caughtDecoy);
        return null;
      }
      slips++;
      return M3InsulatorPatrolMistakes.missed(p.units[p.faulty.first].fault!);
    }
    if (p.sound) {
      slips++;
      return M3InsulatorPatrolMistakes.falseAlarm;
    }
    final missed = p.faulty.difference(marks);
    if (missed.isNotEmpty) {
      slips++;
      return M3InsulatorPatrolMistakes.missed(p.units[missed.first].fault!);
    }
    if (marks.difference(p.faulty).isNotEmpty) {
      slips++;
      return M3InsulatorPatrolMistakes.falseMark;
    }
    for (final f in p.faults) {
      _tag(M3InsulatorPatrolLines.caught[f]!);
    }
    if (p.hasPolymer || p.hasGlass) _tag(M3InsulatorPatrolLines.caughtDecoy);
    return null;
  }

  /// Up the live pole to look closer (his push): deadly.
  DoMistake? climb() {
    if (!_open) return null;
    shown = true;
    return deadly = M3InsulatorPatrolMistakes.climbLive;
  }

  void next() {
    index++;
    marks.clear();
    shown = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %). A pole (ms): look
/// ~5000, two marks 2000, decide 1500, reason ~8200 ≈ 16700; three ≈ 50100,
/// the coworker ~9600: ≈ 59700; 85 % ≈ 51 s.
const m3InsulatorPatrolQuickMs = 51000;

@immutable
class M3InsulatorPatrolPack {
  const M3InsulatorPatrolPack({required this.id, required this.titleBn, this.quickMs = m3InsulatorPatrolQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m3InsulatorPatrolPacks = {
  'do_3_2_b': M3InsulatorPatrolPack(id: 'do_3_2_b', titleBn: M3InsulatorPatrolLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M3InsulatorPatrolPage extends StatefulWidget {
  const M3InsulatorPatrolPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final M3InsulatorPatrolPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3InsulatorPatrolPage> createState() => _M3InsulatorPatrolPageState();
}

class _M3InsulatorPatrolPageState extends State<M3InsulatorPatrolPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PatrolRunPage(
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

class _PatrolRunPage extends ConsumerStatefulWidget {
  const _PatrolRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3InsulatorPatrolPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PatrolRunPage> createState() => _PatrolRunPageState();
}

class _PatrolRunPageState extends ConsumerState<_PatrolRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3InsulatorPatrolRun _run = M3InsulatorPatrolRun(m3InsulatorPatrolDeal(widget.rng));
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

  /// The verdict stamped on this pole (true = report).
  bool? _stamp;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// Gesture hints: taps on nothing are reported here.
  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  final _okKey = GlobalKey();
  final _reportKey = GlobalKey();

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
    _startRound();
  }

  bool get _canPlay =>
      !_intro && !_busy && !_ended && !_freeze && _card == null && !tableBusy && !coworkerOpen && !_run.shown && !_run.ended;

  void _startRound() {
    setState(() {
      _stamp = null;
      _wake++;
    });
    unawaited(_sayChain([M3InsulatorPatrolLines.ask]));
    if (_run.index == _run.deal.callAt) scheduleCoworker();
  }

  // --- hands on -----------------------------------------------------------------------
  void _tapScene(Offset p) {
    if (!_canPlay) return;
    if (!M3InsulatorPatrolGeo.inLens(p)) {
      _hints.missTap();
      return;
    }
    final kind = _run.current.kind;
    for (var i = 0; i < M3InsulatorPatrolGeo.count(kind); i++) {
      if (!M3InsulatorPatrolGeo.unitHit(kind, i).contains(p)) continue;
      HapticFeedback.selectionClick();
      final on = _run.toggle(i);
      _cue(on ? 'sounds/learn/tag_slap.wav' : 'sounds/intro/tick.ogg', volume: on ? 0.45 : 0.5);
      setState(() => _wake++);
      return;
    }
    _hints.missTap();
  }

  // --- the decision ----------------------------------------------------------------
  Future<void> _decide(bool report, Offset origin) async {
    if (!_canPlay) return;
    // On his pole the call waits for him: a fast tap brings him in first.
    if (holdForCoworker()) return;
    _hush();
    final m = _run.decide(report: report);
    if (m == null && !_run.shown) {
      HapticFeedback.selectionClick();
      _cue('sounds/intro/click.ogg', volume: 0.5);
      setState(() => _wake++);
      unawaited(_sayChain([M3InsulatorPatrolLines.markFirst]));
      return;
    }
    HapticFeedback.mediumImpact();
    if (m == null) {
      _cue('sounds/learn/tag_slap.wav', volume: 0.7);
      _cue('sounds/quiz_right.wav', volume: 0.6);
      setState(() {
        _stamp = report;
        _wake++;
      });
      putOnTable(15 + (_run.thorough ? 5 : 0));
      final p = _run.current;
      final idx = _run.index;
      unawaited(askReason(
        deal: () => dealChoices(M3InsulatorPatrolLines.whyRight(p), M3InsulatorPatrolLines.whyWrong(p), widget.rng),
        question: report ? M3InsulatorPatrolLines.whyReport : M3InsulatorPatrolLines.whyOk,
        stillValid: () => _run.index == idx && !_ended,
      ));
      return;
    }
    setState(() {});
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
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
  CoworkerScript get coworkerScript => M3InsulatorPatrolLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.ended || _run.index != _run.deal.callAt || _run.shown) return null;
    if (_intro || _busy || _freeze || _card != null || tableBusy) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: up the live pole.
      final m = _run.climb();
      if (m != null) await _deadly(m);
      return;
    }
    if (!_run.caught.contains(M3InsulatorPatrolLines.caughtCall)) _run.caught.add(M3InsulatorPatrolLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    unawaited(_sayChain([M3InsulatorPatrolLines.callHeld]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3InsulatorPatrolLines.tapWhy[_nudgeN++ % M3InsulatorPatrolLines.tapWhy.length]
            : _nudge.next(M3InsulatorPatrolLines.ask);
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
    final speak = await SpokenOnce.first('patrol/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Up the live pole: the scene freezes grey and the flash comes at his
  /// hand on the pole, in colour; then near-miss or death.
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
    final speak = await SpokenOnce.first('patrol/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M3InsulatorPatrolLines.deadlyWord : M3InsulatorPatrolLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
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
    await _say(!_run.passed ? M3InsulatorPatrolLines.fail : (_quickBonus ? M3InsulatorPatrolLines.quick : M3InsulatorPatrolLines.allSet),
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

  // --- gesture hints -------------------------------------------------------
  /// While the pole waits: a sweep over every insulator in the view and both
  /// buttons (how to answer, never which). Never over a card.
  HintSpec? _hint() {
    if (_card != null) return null;
    final rects = <Rect>[];
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.attached && box.hasSize) {
      final kind = _run.current.kind;
      for (var i = 0; i < M3InsulatorPatrolGeo.count(kind); i++) {
        final b = M3InsulatorPatrolGeo.unitBody(kind, i);
        rects.add(Rect.fromPoints(box.localToGlobal(b.topLeft), box.localToGlobal(b.bottomRight)));
      }
    }
    for (final k in [_okKey, _reportKey]) {
      final r = HintSpec.globalRectOf(k);
      if (r != null) rects.add(r);
    }
    return rects.length < 2 ? null : HintSpec.sweep(rects);
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_stamp != null) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = M3InsulatorPatrolGeo.forScene(m.height, m.inset);
    final p = _run.current;
    final quiet = _quiet;
    // The deadly move: he has gone to the pole and put his hand on it.
    final tb = _freeze ? geo.trainee.shift(Offset(geo.poleX - geo.trainee.right + 4, 0)) : geo.trainee;
    final mode = _freeze ? LinemanMode.point : _mode;
    final hand = tb.topLeft + LinemanFigure.tipOf(LinemanMode.hold, Carry.none, tb.size);
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('land'),
                child: RepaintBoundary(child: CustomPaint(painter: M3InsulatorPatrolWorldPainter(geo: geo, kind: p.kind))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: tb,
                child: LinemanFigure(look: LinemanLook.trainee, mode: mode, wake: _wake, quiet: quiet),
              ),
              if (mode == LinemanMode.hold)
                Positioned.fill(
                  key: const ValueKey('binoculars'),
                  child: IgnorePointer(child: CustomPaint(painter: M3InsulatorPatrolBinocularsPainter(at: hand))),
                ),
              Positioned.fill(
                key: const ValueKey('lens'),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: M3InsulatorPatrolLensPainter(
                      kind: p.kind,
                      units: p.units,
                      marks: {..._run.marks},
                      reveal: _run.shown,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      if (_stamp != null && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: 90,
          width: 180,
          top: M3InsulatorPatrolGeo.lensCy + 66,
          child: IgnorePointer(child: _StampPop(text: _stamp! ? M3InsulatorPatrolLines.stampReport : M3InsulatorPatrolLines.stampOk, quiet: quiet)),
        ),
      // Tap an insulator in the view: mark it (or clear the mark).
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M3InsulatorPatrolLines.sceneLabel,
          child: GestureDetector(key: _touchKey, behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M3InsulatorPatrolZapPainter(at: Offset(geo.poleX, hand.dy), v: v)),
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
    final handsOn = playing && !_run.shown && !deckUp && !coworkerOpen && _card == null && !tableBusy;
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
              labels: M3InsulatorPatrolLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            // Off during cards, decks, the freeze and his whole visit (exit too).
            hintWaiting: handsOn && !coworkerOnScreen,
            hintKey: 'pole-${_run.index}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn)
                Positioned(
                  key: const ValueKey('hud-decide'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(
                          child: DoBigButton(
                              key: _okKey, label: M3InsulatorPatrolLines.ok, filled: false, onDark: true, onTapUp: (d) => unawaited(_decide(false, d.globalPosition)))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: DoBigButton(key: _reportKey, label: M3InsulatorPatrolLines.report, filled: true, onTapUp: (d) => unawaited(_decide(true, d.globalPosition)))),
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
                  line: M3InsulatorPatrolLines.intro,
                  alarm: 'sounds/learn/wind_gust.wav',
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 0, muted: _muted)),
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
