import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show LongPressGestureRecognizer, TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
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
import 'm7_street_warn_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm7_street_warn_world.dart' show M7WarnGeo, M7WarnLane, M7WarnLook, M7WarnRoof, M7WarnRoofState;

// Lesson 7.3 "ন্যূনতম ক্লিয়ারেন্স: আইনত কতটা দূরত্ব?", কাজ 2 "পাড়ার পাহারা"
// (pack do_7_3_b, engineType m7_street_warn). The verb: hold on a moving
// person (or a roof, the plot, a span) to warn or to report.
//
// A breezy পাড়া: the 11 kV line along the main road, the LT line over the
// back lane (two spans, x 16–240) and a free lane with no line over it. The
// trainee stands at the lane corner. People come and go on a game clock
// (~90 s) that stops for every hold chip, card, table, deck, coworker beat
// and freeze; with nobody on the move it jumps ahead (no frames drawn).
// Holding ~0.6 s on any person, roof, the plot or an LT span opens the same
// chip: 'ডেকে সতর্ক করে দিন' / 'সুপারভাইজারকে জানান' (+ 'ছেড়ে দিন'); each
// is a two-step pick (preview ✓ / ✕).
//
// Dealt fresh: 3–4 hazards (1–2 carriers — a man with a long iron rod or two
// labourers with a long bamboo — walking to a spot under the 11 kV or the LT
// line, where they lift the load; one roof item — wet clothes or a bamboo
// leaning to the LT wire on house A or B, appearing at 32–40 s; and one or
// two report items — a half-built house under the 11 kV line, a sagging LT
// span), plus 2–3 decoys (a cyclist, a vendor, a man with a short bag, a
// bamboo pair in the free lane, clothes on house D's roof with no wire
// near), entry sides, times, speeds and stops; a decoy walks whenever a
// carrier does.
//
// Rules (lesson 7.3 section 4; pro tip 2; myth 1; rulings M7-3, M7-2):
//  carrier: warn in time → he turns away; warn in the last 2.4 s (as he
//    lifts) → slip (late, he still turns); report → slip (wrong response);
//    his load reaching the line unwarned → the scene freezes: DEADLY (R17,
//    M7-3, after a clear timed chance of ≥ 4 s).
//  roof item: warn → removed; report → slip; left at the end → slip.
//  half-built house: warn the masons AND report it (each; left = slip each).
//  sagging span: report; warn → slip; left at the end → slip.
//  any warn or report on a decoy (an ordinary span, an empty roof, the
//    vacant plot, a person with no long load or in the free lane) → slip.
//  The coworker comes once, the moment the roof item appears (clock paused,
//  item locked): refuse → the item is the player's again; listen → slip
//  (X2/B1: what he pushes is a slip here) and the guide warns the owner.
// A reason deck follows the first right warning and the first right report
// only. After 90 s each static hazard left is a slip; then pass/fail. Three
// slips strike out.
//
// Gesture hands (how, never what): watching (≥ 2 holdables are always on
// screen) — the play's first hand is a hold ring on empty road, then a sweep
// over every holdable alike; the chip — a sweep over its two buttons; card
// previews and decks have their own. None in the intro, coworker beats,
// cards, freeze or results.

// ============================================================================
// Content
// ============================================================================

/// Who walks (the carriers are the hazards).
enum M7WarnKind { rod, bamboo, cyclist, vendor, bag, laneBamboo }

/// What can be held.
enum M7WarnSpot { person, houseA, houseB, houseD, plot, span0, span1 }

/// The chip's two answers.
enum M7WarnAct { warn, report }

/// What a hold's answer came to.
enum M7WarnOutcome { right, late, wrongType, needless, already, ignored }

/// What a reason asks about (fits what was done).
enum M7WarnWhy { carrier, clothes, bamboo, masons, build, sag }

/// The play ends this long into the game clock (ms).
const int kM7WarnEndMs = 90000;

/// A carrier lifts his load this long before it reaches the wire.
const int kM7WarnLiftMs = 1600;

/// A warning in the last this-many ms before contact is late (a slip).
const int kM7WarnLateMs = 2400;

/// The hold that opens the chip.
const int kM7WarnHoldMs = 600;

/// With nobody on the move the clock jumps ahead, at most this long (real ms).
const int kM7WarnGapMaxMs = 2500;

M7WarnLook m7WarnLookOf(M7WarnKind k) => switch (k) {
      M7WarnKind.rod => M7WarnLook.rod,
      M7WarnKind.bamboo || M7WarnKind.laneBamboo => M7WarnLook.bamboo,
      M7WarnKind.cyclist => M7WarnLook.cyclist,
      M7WarnKind.vendor => M7WarnLook.vendor,
      M7WarnKind.bag => M7WarnLook.bag,
    };

abstract final class M7StreetWarnLines {
  static const title = 'পাড়ার পাহারা';
  // DRAFT wording — owner (M7-10 / M6-12) for every line below.
  static const intro = 'পাড়ার ওপর দিয়ে লাইন গেছে। কেউ বিপদে গেলে চেপে ধরে থামান।';

  // The guide's task now (tap him: the same task, a different way; he never
  // names a person).
  static const askWatch = 'চারদিকে নজর রাখুন।';
  static const askChip = 'কী করবেন — ডেকে সতর্ক, না সুপারভাইজারকে ফোন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const tasks = [askWatch, askChip];

  // The chip (a worker's own words; alike in length).
  static const warn = 'ডেকে সতর্ক করে দিন';
  static const report = 'সুপারভাইজারকে জানান';
  static const letGo = 'ছেড়ে দিন';
  static String act(M7WarnAct a) => a == M7WarnAct.warn ? warn : report;

  static const sceneLabel = 'পাড়ার রাস্তা';
  static const phoneTag = 'সুপারভাইজার';

  // The trainee's shout (warn) and his phone call (report), read by the guide.
  static const shoutCarrier = 'দাঁড়ান! মাথার ওপর তার!';
  static const shoutClothes = 'দিদি, ভেজা কাপড়টা তারের কাছ থেকে সরিয়ে নিন!';
  static const shoutBamboo = 'দাদা, বাঁশটা নামিয়ে নিন — তারে লেগে যাবে!';
  static const shoutMasons = 'সাবধান! মাথার ওপর 11 kV লাইন!';
  static const phoneBuild = 'স্যার, 11 kV লাইনের ঠিক নিচে বাড়ি উঠছে — একবার দেখে যান।';
  static const phoneSag = 'স্যার, পাড়ার LT তার অনেকটা ঝুলে পড়েছে — রিপোর্ট করছি।';
  static const already = 'এটা তো আগেই করেছেন।';
  static String shoutRoof(M7WarnRoof r) => r == M7WarnRoof.clothes ? shoutClothes : shoutBamboo;

  static const endLine = 'পাড়া এখন ফাঁকা। দেখি কিছু বাকি রইল কি না।';

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses (all about the same length).
  static const whyQ = <M7WarnWhy, String>{
    M7WarnWhy.carrier: 'কেন ওঁকে থামালেন?',
    M7WarnWhy.clothes: 'কেন ভেজা কাপড় সরাতে বললেন?',
    M7WarnWhy.bamboo: 'কেন ছাদের বাঁশ সরাতে বললেন?',
    M7WarnWhy.masons: 'কেন মিস্ত্রিদের সাবধান করলেন?',
    M7WarnWhy.build: 'কেন নির্মাণ দেখে ফোন করলেন?',
    M7WarnWhy.sag: 'কেন সুপারভাইজারকে জানালেন?',
  };
  static const whyRight = <M7WarnWhy, List<String>>{
    M7WarnWhy.carrier: ['লাইনের নিচে রড বা বাঁশ গেলে তারে ঠেকতে পারে', 'বাঁশ বা রড তারে লাগলেই শক — আগে থামাতে হয়'],
    M7WarnWhy.clothes: ['ভেজা কাপড় বিদ্যুৎ পরিবহন করতে পারে, তাই সরাই', 'কাপড় তুললে তার আর ছাদের ফাঁক কমে যায়'],
    M7WarnWhy.bamboo: ['বাঁশ তুললে তার আর ছাদের ফাঁক কমে যায়', 'বাতাসে তার দুলে দূর থেকেও আর্ক হতে পারে'],
    M7WarnWhy.masons: ['লাইনের খুব কাছে কাজ করলে বিপদ — বলতে হয়', 'মাথার ওপর তার — মিস্ত্রিদের বিপদ বোঝাতে হয়'],
    M7WarnWhy.build: ['লাইনের নিচে নির্মাণ হলে অবিলম্বে জানাতে হয়', 'তারের নিচে বাড়ি উঠছে — সুপারভাইজার জানবেন'],
    M7WarnWhy.sag: ['ঝুলে পড়া তার আইন মেনে নেই — রিপোর্ট করতে হয়', 'নিচু তার ছিঁড়ে বা ছুঁয়ে বড় দুর্ঘটনা হতে পারে'],
  };
  static const myths = [
    'ছাদ থেকে তার দূরে, বাঁশ রাখলে কিছু হয় না',
    'শুকনো দিনে তারের নিচে বাঁশ নিলে ভয় নেই',
    'ক্লিয়ারেন্স একটু কম হলে কেউ মাপতে আসে না',
    'লোকের কাজে নাক গলানো লাইনম্যানের কাজ নয়',
    'বাঁশ তো কাঠ, ওতে কারেন্ট আসতেই পারে না',
    'ঝোলা তার নিজে থেকেই আবার টানটান হয়ে যায়',
    'নির্মাণ তো বাড়ির মালিকের ব্যাপার, আমাদের কী',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker: once, the moment the roof item appears (myth 1
  // without 'আমার বাড়ির' — the shortcut line of M7-10, to record).
  static const coworkerLine = 'ছাদ থেকে তারটা তো অনেক দূরেই আছে, ওখানে একটা বাঁশ রাখলে বা কাপড় শুকোতে দিলে কিছু হবে না।';
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerAsks = ['উনি বলছেন কিছু হবে না। আপনি কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'];
  static const coworkerWrong = [
    'ঠিকই বলেছ, তার তো অনেক দূরেই আছে, থাক',
    'ছাদ ওঁদের, ওসব নিয়ে আমাদের কী দরকার',
    'কাপড়ে আবার কারেন্ট কীসের, ছেড়ে দিই',
    'একটা বাঁশে কিছু হয় না, চলো এগিয়ে যাই',
    'পরে বলব, এখন থাক — এখনও অনেক কাজ আছে',
  ];
  static const coworkerClothes = CoworkerScript(
    line: coworkerLine,
    exitLine: coworkerExit,
    right: ['ভেজা কাপড় বিদ্যুৎ টানে — ওঁকে সাবধান করি', 'না, কাপড় তুললে তারের ফাঁক কমে — বলে দিই'],
    wrong: coworkerWrong,
    asks: coworkerAsks,
  );
  static const coworkerBamboo = CoworkerScript(
    line: coworkerLine,
    exitLine: coworkerExit,
    right: ['বাতাসে তার দোলে — বাঁশটা সরাতে বলি', 'না, বাঁশ তুললে তারের ফাঁক কমে — বলে দিই'],
    wrong: coworkerWrong,
    asks: coworkerAsks,
  );
  static CoworkerScript coworker(M7WarnRoof r) => r == M7WarnRoof.clothes ? coworkerClothes : coworkerBamboo;
  static const allCoworkers = [coworkerClothes, coworkerBamboo];

  static String callHeld(M7WarnRoof r) =>
      r == M7WarnRoof.clothes ? 'ঠিক! ভেজা কাপড় বিদ্যুৎ টানে — এবার ওঁকে বলুন।' : 'ঠিক! বাতাসে তার দোলে — এবার বাঁশ সরাতে বলুন।';

  /// After the player listened to him, the guide warns the owner himself.
  static const guideWarns = 'ঠিক আছে, আমিই বলে দিচ্ছি।';

  static const allSet = 'পাড়ার সব বিপদ সময়মতো ধরেছেন — দারুণ পাহারা!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — রড বা বাঁশ দেখলে সতর্ক, নির্মাণ বা ঝোলা তার দেখলে ফোন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন" (on screen).
  static const caughtCarrier = 'রড-বাঁশ তারের দিকে — সময়মতো থামিয়েছেন';
  static const caughtClothes = 'ছাদের ভেজা কাপড় সরাতে বলেছেন';
  static const caughtBamboo = 'ছাদের বাঁশ সরাতে বলেছেন';
  static const caughtMasons = 'লাইনের নিচে মিস্ত্রিদের সাবধান করেছেন';
  static const caughtBuild = 'লাইনের নিচে নির্মাণ — সুপারভাইজারকে ফোন';
  static const caughtSag = 'ঝুলে পড়া তার রিপোর্ট করেছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's lines to record in his voice (tool/rival_clip.py); the
  /// exit is recorded already.
  static List<String> get newRivalLines => [coworkerLine];

  /// Every spoken guide line (DRAFT — owner wording, then recorded; until
  /// then the device voice). The kit's own praise and 'wrong' bags are left
  /// out.
  static List<String> get newGuideLines => <String>{
        intro,
        ...tasks,
        ...tapWhy,
        shoutCarrier,
        shoutClothes,
        shoutBamboo,
        shoutMasons,
        phoneBuild,
        phoneSag,
        already,
        endLine,
        ...whyQ.values,
        ...coworkerAsks,
        for (final r in M7WarnRoof.values) callHeld(r),
        guideWarns,
        allSet,
        quick,
        fail,
        deadlyWord,
        nearMissWord,
        for (final m in M7StreetWarnMistakes.all) m.textBn,
      }.toList();
}

abstract final class M7StreetWarnMistakes {
  static const _dir = 'assets/game/art/m7_street_warn';

  // DRAFT wording — owner (M7-10). Lesson 7.3 points: 1 = building
  // clearance (roof, building under the line), 3 = 'নিয়ম লঙ্ঘনের পরিণাম'
  // (warn the public; report a line not as the law says).
  static const contact = DoMistake(
    key: '7.3/m7_street_warn/contact',
    textBn: 'বাঁশ বা রড তারে ঠেকে গেল! লাইনের নিচে কেউ বাঁশ বা লোহার রড নিয়ে গেলে সময় থাকতে তাঁকে সতর্ক করা উচিত।',
    art: '$_dir/contact.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const lateWarn = DoMistake(
    key: '7.3/m7_street_warn/late-warn',
    textBn: 'বড্ড দেরিতে থামালেন — ভার প্রায় তারে উঠে গিয়েছিল। লাইনের দিকে বাঁশ বা রড যেতে দেখলেই আগে সতর্ক করুন।',
    art: '$_dir/late.svg',
    lessonPoint: 3,
  );
  static const carrierReport = DoMistake(
    key: '7.3/m7_street_warn/carrier-report',
    textBn: 'উনি এখনই ভার নিয়ে তারের দিকে যাচ্ছেন — ফোনে জানাতে জানাতে দেরি হয়ে যাবে। এখনই ডেকে সতর্ক করুন।',
    art: '$_dir/carrier_report.svg',
    lessonPoint: 3,
  );
  static const roofReport = DoMistake(
    key: '7.3/m7_street_warn/roof-report',
    textBn: 'ছাদের ভেজা কাপড় বা বাঁশ সরাতে বাড়ির লোককেই সাবধান করতে হয় — এখনই ডেকে বলুন।',
    art: '$_dir/roof_report.svg',
    lessonPoint: 1,
  );
  static const roofClothesLeft = DoMistake(
    key: '7.3/m7_street_warn/roof-clothes-left',
    textBn: 'ছাদের ভেজা কাপড় তারের নিচেই থেকে গেল। ভেজা কাপড় বিদ্যুৎ পরিবহন করতে পারে — বাড়ির লোককে সরাতে বলুন।',
    art: '$_dir/roof_clothes.svg',
    lessonPoint: 1,
  );
  static const roofBambooLeft = DoMistake(
    key: '7.3/m7_street_warn/roof-bamboo-left',
    textBn: 'ছাদের বাঁশ তারের দিকে হেলেই থেকে গেল। বাতাসে তার দুলে দূর থেকেও আর্ক হতে পারে — বাঁশ সরাতে বলুন।',
    art: '$_dir/roof_bamboo.svg',
    lessonPoint: 1,
  );
  static const buildNoWarn = DoMistake(
    key: '7.3/m7_street_warn/build-no-warn',
    textBn: 'লাইনের ঠিক নিচে মিস্ত্রিরা কাজ করছিলেন, কেউ সাবধান করেনি। লাইনের খুব কাছে নির্মাণ হলে তাঁদের বিপদের কথা বলুন।',
    art: '$_dir/build_warn.svg',
    lessonPoint: 3,
  );
  static const buildNoReport = DoMistake(
    key: '7.3/m7_street_warn/build-no-report',
    textBn: 'লাইনের নিচে বা খুব কাছে নতুন নির্মাণ দেখলে অবিলম্বে সুপারভাইজারকে জানাতে হয়।',
    art: '$_dir/build_report.svg',
    lessonPoint: 1,
  );
  static const sagLeft = DoMistake(
    key: '7.3/m7_street_warn/sag-left',
    textBn: 'ঝুলে পড়া তার রিপোর্ট হলো না। লাইন আইন অনুযায়ী না থাকলে (যেমন তার ঝুলে পড়েছে) রিপোর্ট করা আপনার দায়িত্ব।',
    art: '$_dir/sag.svg',
    lessonPoint: 3,
  );
  static const sagWarned = DoMistake(
    key: '7.3/m7_street_warn/sag-warned',
    textBn: 'ঝোলা তার কাউকে ডেকে বললে ঠিক হয় না — এটা সুপারভাইজারকে রিপোর্ট করতে হয়।',
    art: '$_dir/sag.svg',
    lessonPoint: 3,
  );
  static const needless = DoMistake(
    key: '7.3/m7_street_warn/needless',
    textBn: 'এখানে লাইনের কোনো বিপদ ছিল না। অকারণে লোক থামালে বা ফোন করলে আসল বিপদের সময় নষ্ট হয়।',
    art: '$_dir/needless.svg',
    lessonPoint: 3,
  );
  static const listenClothes = DoMistake(
    key: '7.3/m7_street_warn/listen-clothes',
    textBn: 'ভেজা কাপড় বিদ্যুৎ পরিবহন করতে পারে, আর কাপড় তুললে তার আর ছাদের ফাঁক কমে যায়। ওর কথায় চুপ থাকা চলে না।',
    art: '$_dir/roof_clothes.svg',
    lessonPoint: 1,
  );
  static const listenBamboo = DoMistake(
    key: '7.3/m7_street_warn/listen-bamboo',
    textBn: 'বাঁশ তুললে তার আর ছাদের ফাঁক কমে যায়, বাতাসে তার দুলে আর্কও হতে পারে। ওর কথায় চুপ থাকা চলে না।',
    art: '$_dir/roof_bamboo.svg',
    lessonPoint: 1,
  );

  static DoMistake roofLeft(M7WarnRoof r) => r == M7WarnRoof.clothes ? roofClothesLeft : roofBambooLeft;
  static DoMistake listen(M7WarnRoof r) => r == M7WarnRoof.clothes ? listenClothes : listenBamboo;

  static const List<DoMistake> all = [
    contact,
    lateWarn,
    carrierReport,
    roofReport,
    roofClothesLeft,
    roofBambooLeft,
    buildNoWarn,
    buildNoReport,
    sagLeft,
    sagWarned,
    needless,
    listenClothes,
    listenBamboo,
  ];

  /// The level's deadly keys (the catalog's deadlyRules).
  static List<String> get deadlyKeys => [for (final m in all) if (m.deadly) m.key];
}

// ============================================================================
// The deal and the rules (pure)
// ============================================================================

/// One person's walk.
@immutable
class M7WarnPlan {
  const M7WarnPlan({
    required this.id,
    required this.kind,
    required this.lane,
    required this.forward,
    required this.startMs,
    required this.walkMs,
    this.stopAt = 1,
    this.tint = 0,
  });

  final int id;
  final M7WarnKind kind;
  final M7WarnLane lane;

  /// Left → right (main road, back lane); into the free lane.
  final bool forward;
  final int startMs;

  /// A decoy: the time to cross; a carrier: the time to reach his stop.
  final int walkMs;

  /// A carrier stops (and lifts) at this progress along his lane.
  final double stopAt;
  final int tint;

  bool get hazard => kind == M7WarnKind.rod || kind == M7WarnKind.bamboo;
  int get liftMs => startMs + walkMs;
  int get contactMs => liftMs + kM7WarnLiftMs;
  int get lateFromMs => contactMs - kM7WarnLateMs;

  /// A decoy has left the scene by then.
  int get endMs => startMs + walkMs;
}

/// A person on the scene (the run moves him).
class M7WarnActor {
  M7WarnActor(this.plan);
  final M7WarnPlan plan;

  /// Game ms when he was warned (he turns back), and where he was then.
  double? warnedAt;
  double _warnedP = 0;
  double _warnedLift = 0;

  /// A needless warn or report was made on him (no more holds).
  var bothered = false;

  bool get hazard => plan.hazard;
  double get _speed => hazard ? plan.stopAt / plan.walkMs : 1 / plan.walkMs;

  double progressAt(double ms) {
    if (ms < plan.startMs) return 0;
    final w = warnedAt;
    if (w != null) return math.max(0, _warnedP - (ms - w) * _speed);
    final p = (ms - plan.startMs) * _speed;
    return hazard ? math.min(p, plan.stopAt) : p;
  }

  double liftAt(double ms) {
    if (!hazard) return 0;
    final w = warnedAt;
    if (w != null) return math.max(0, _warnedLift - (ms - w) / 400);
    return ((ms - plan.liftMs) / kM7WarnLiftMs).clamp(0.0, 1.0);
  }

  bool goneAt(double ms) {
    if (ms < plan.startMs) return false;
    if (warnedAt != null) return progressAt(ms) <= 0;
    return !hazard && (ms - plan.startMs) * _speed >= 1;
  }

  bool visibleAt(double ms) => ms >= plan.startMs && !goneAt(ms);
  bool holdableAt(double ms) => visibleAt(ms) && warnedAt == null && !bothered;

  /// He walks the other way now (warned).
  bool get turned => warnedAt != null;

  void turn(double ms) {
    _warnedP = progressAt(ms);
    _warnedLift = liftAt(ms);
    warnedAt = ms;
  }
}

/// What can be held: a person (by id) or a place.
@immutable
class M7WarnTarget {
  const M7WarnTarget.person(this.actor) : spot = M7WarnSpot.person;
  const M7WarnTarget.place(this.spot) : actor = -1;
  final M7WarnSpot spot;
  final int actor;

  @override
  bool operator ==(Object other) => other is M7WarnTarget && other.spot == spot && other.actor == actor;
  @override
  int get hashCode => Object.hash(spot, actor);
  @override
  String toString() => spot == M7WarnSpot.person ? 'person#$actor' : spot.name;
}

@immutable
class M7WarnDeal {
  const M7WarnDeal({
    required this.actors,
    required this.roof,
    required this.roofHouse,
    required this.roofAt,
    required this.build,
    required this.sagSpan,
    required this.decoyRoof,
  });

  final List<M7WarnPlan> actors;

  /// The roof item (the coworker's item), on house A (0) or B (1), from
  /// [roofAt] game ms.
  final M7WarnRoof roof;
  final int roofHouse;
  final int roofAt;

  /// A half-built house on the plot under the 11 kV line.
  final bool build;

  /// The sagging LT span (0 or 1), or none.
  final int? sagSpan;

  /// Clothes on house D's roof (no wire near): a decoy.
  final bool decoyRoof;

  bool get sag => sagSpan != null;
  List<M7WarnPlan> get carriers => [for (final a in actors) if (a.hazard) a];
  List<M7WarnPlan> get movingDecoys => [for (final a in actors) if (!a.hazard) a];
  int get hazardCount => carriers.length + 1 + (build ? 1 : 0) + (sag ? 1 : 0);
  int get decoyCount => movingDecoys.length + (decoyRoof ? 1 : 0);
  M7WarnSpot get roofSpot => roofHouse == 0 ? M7WarnSpot.houseA : M7WarnSpot.houseB;
}

M7WarnDeal m7WarnDeal(math.Random rng) {
  final two = rng.nextInt(3) == 0;
  final roof = rng.nextBool() ? M7WarnRoof.clothes : M7WarnRoof.bamboo;
  final roofHouse = rng.nextInt(2);
  bool build;
  bool sag;
  if (two) {
    build = rng.nextBool();
    sag = !build;
  } else {
    final r = rng.nextInt(3);
    build = r != 1;
    sag = r != 0;
  }
  final roofAt = 32000 + rng.nextInt(8001);
  int slotA() => 6000 + rng.nextInt(10001);
  int slotB() => 48000 + rng.nextInt(12001);
  final slots = two ? [slotA(), slotB()] : [rng.nextBool() ? slotA() : slotB()];
  final plans = <M7WarnPlan>[];
  var id = 0;
  var tint = rng.nextInt(6);
  var laneBambooUsed = false;
  for (final (i, s) in slots.indexed) {
    // The carrier: a lane under a line, a stop under it, a side to come from
    // that leaves him at least ~5 s of walk.
    final lane = rng.nextBool() ? M7WarnLane.main : M7WarnLane.back;
    final stopX = lane == M7WarnLane.main ? 70 + rng.nextDouble() * 220 : 40 + rng.nextDouble() * 180;
    final okF = M7WarnGeo.progressAt(stopX, true) >= 0.38;
    final okB = M7WarnGeo.progressAt(stopX, false) >= 0.38;
    final forward = okF && okB ? rng.nextBool() : okF;
    final stopAt = M7WarnGeo.progressAt(stopX, forward);
    final walkMs = math.max(5200, (stopAt * (13500 + rng.nextInt(3000))).round());
    final carrier = M7WarnPlan(
      id: id++,
      kind: rng.nextBool() ? M7WarnKind.rod : M7WarnKind.bamboo,
      lane: lane,
      forward: forward,
      startMs: s,
      walkMs: walkMs,
      stopAt: stopAt,
      tint: tint++,
    );
    plans.add(carrier);
    // A decoy on screen all the while he walks (drawn alike when it is the
    // free lane's bamboo pair).
    final lb = !laneBambooUsed && (i == 0 ? rng.nextInt(5) < 3 : rng.nextBool());
    laneBambooUsed |= lb;
    final kind = lb ? M7WarnKind.laneBamboo : (rng.nextBool() ? M7WarnKind.vendor : M7WarnKind.bag);
    final cStart = s - 500 - rng.nextInt(1500);
    final cWalk = math.max(15000 + rng.nextInt(2500), carrier.contactMs - cStart + 1500);
    plans.add(M7WarnPlan(
      id: id++,
      kind: kind,
      lane: lb ? M7WarnLane.free : (rng.nextBool() ? M7WarnLane.main : M7WarnLane.back),
      forward: rng.nextBool(),
      startMs: cStart,
      walkMs: cWalk,
      tint: tint++,
    ));
  }
  // Extra decoys: 2–3 in all.
  final extra = two ? rng.nextInt(2) : 1 + rng.nextInt(2);
  final pool = <String>['cyclist', 'roof', 'walker', if (!laneBambooUsed) 'laneBamboo']..shuffle(rng);
  var decoyRoof = false;
  for (final p in pool.take(extra)) {
    switch (p) {
      case 'roof':
        decoyRoof = true;
      case 'cyclist':
        final walk = 6000 + rng.nextInt(1500);
        plans.add(M7WarnPlan(
          id: id++,
          kind: M7WarnKind.cyclist,
          lane: M7WarnLane.main,
          forward: rng.nextBool(),
          startMs: 20000 + rng.nextInt(60000),
          walkMs: walk,
          tint: tint++,
        ));
      case 'walker':
        final walk = 15000 + rng.nextInt(2000);
        plans.add(M7WarnPlan(
          id: id++,
          kind: rng.nextBool() ? M7WarnKind.vendor : M7WarnKind.bag,
          lane: rng.nextBool() ? M7WarnLane.main : M7WarnLane.back,
          forward: rng.nextBool(),
          startMs: 18000 + rng.nextInt(90000 - 18000 - walk - 1000),
          walkMs: walk,
          tint: tint++,
        ));
      case 'laneBamboo':
        final walk = 14000 + rng.nextInt(2000);
        plans.add(M7WarnPlan(
          id: id++,
          kind: M7WarnKind.laneBamboo,
          lane: M7WarnLane.free,
          forward: rng.nextBool(),
          startMs: 18000 + rng.nextInt(90000 - 18000 - walk - 1000),
          walkMs: walk,
          tint: tint++,
        ));
    }
  }
  return M7WarnDeal(
    actors: plans,
    roof: roof,
    roofHouse: roofHouse,
    roofAt: roofAt,
    build: build,
    sagSpan: sag ? rng.nextInt(2) : null,
    decoyRoof: decoyRoof,
  );
}

/// What a hold's answer came to.
@immutable
class M7WarnResult {
  const M7WarnResult(this.outcome, {this.mistake, this.why, this.line});
  final M7WarnOutcome outcome;
  final DoMistake? mistake;

  /// The first right warning / report of the play asks this reason.
  final M7WarnWhy? why;

  /// The trainee's shout or phone line (read by the guide).
  final String? line;

  static const ignored = M7WarnResult(M7WarnOutcome.ignored);
}

/// What one clock step brought.
@immutable
class M7WarnTick {
  const M7WarnTick({this.contact, this.roofAppeared = false});
  final M7WarnActor? contact;
  final bool roofAppeared;
}

/// The play state (pure logic; the page moves the clock).
class M7WarnRun {
  M7WarnRun(this.deal) : actors = [for (final p in deal.actors) M7WarnActor(p)];
  final M7WarnDeal deal;
  final List<M7WarnActor> actors;

  /// Game ms.
  double ms = 0;
  int slips = 0;
  int needless = 0;
  final List<String> caught = [];

  var roofState = M7WarnRoofState.hidden;

  /// The guide warned the roof's owner (the player listened to him).
  var roofByGuide = false;
  var masonsWarned = false;
  var buildReported = false;
  var sagReported = false;
  final Set<M7WarnSpot> bothered = {};
  var _warnAsked = false;
  var _reportAsked = false;
  DoMistake? deadly;

  /// The end's slips are taken: the play is over.
  var over = false;

  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get ended => deadly != null || over;
  bool get passed => over && deadly == null && percent >= 55;
  bool get thorough => slips == 0 && needless == 0;

  bool get anyVisible => actors.any((a) => a.visibleAt(ms));
  bool get watchOver => ms >= kM7WarnEndMs && !anyVisible;

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  /// The clock at [now]: the roof item shows; a carrier nobody warned
  /// touches the line (deadly).
  M7WarnTick tick(double now) {
    if (ended) return const M7WarnTick();
    ms = math.max(ms, now);
    var roof = false;
    if (roofState == M7WarnRoofState.hidden && ms >= deal.roofAt) {
      roofState = M7WarnRoofState.shown;
      roof = true;
    }
    for (final a in actors) {
      if (a.hazard && a.warnedAt == null && ms >= a.plan.contactMs) {
        deadly = M7StreetWarnMistakes.contact;
        return M7WarnTick(contact: a, roofAppeared: roof);
      }
    }
    return M7WarnTick(roofAppeared: roof);
  }

  /// The next thing that happens with nobody on the move: someone sets
  /// off, the roof item shows, or the end.
  double nextEventMs() {
    var next = kM7WarnEndMs.toDouble();
    for (final a in actors) {
      if (a.plan.startMs > ms && a.plan.startMs < next) next = a.plan.startMs.toDouble();
    }
    if (roofState == M7WarnRoofState.hidden && deal.roofAt > ms && deal.roofAt < next) next = deal.roofAt.toDouble();
    return math.max(next, ms);
  }

  /// Everything that can be held now.
  List<M7WarnTarget> holdables() => [
        for (final a in actors)
          if (a.holdableAt(ms)) M7WarnTarget.person(a.plan.id),
        for (final s in M7WarnSpot.values)
          if (s != M7WarnSpot.person && !bothered.contains(s)) M7WarnTarget.place(s),
      ];

  bool holdable(M7WarnTarget t) =>
      !ended && (t.spot == M7WarnSpot.person ? actors[t.actor].holdableAt(ms) : !bothered.contains(t.spot));

  Offset feetOf(M7WarnGeo g, M7WarnActor a) => g.at(a.plan.lane, a.progressAt(ms), a.plan.forward);

  /// A target's hold area on [g].
  Rect rectOf(M7WarnGeo g, M7WarnTarget t) => switch (t.spot) {
        M7WarnSpot.person => g.personRect(feetOf(g, actors[t.actor]), m7WarnLookOf(actors[t.actor].plan.kind)),
        M7WarnSpot.houseA => g.house(0).inflate(4),
        M7WarnSpot.houseB => g.house(1).inflate(4),
        M7WarnSpot.houseD => g.house(2).inflate(4),
        M7WarnSpot.plot => g.plot,
        M7WarnSpot.span0 => g.span(0, sagSpan: deal.sagSpan),
        M7WarnSpot.span1 => g.span(1, sagSpan: deal.sagSpan),
      };

  /// What a finger at [p] holds (people first, then spans, houses, plot).
  M7WarnTarget? hitTest(M7WarnGeo g, Offset p) {
    final hold = holdables();
    M7WarnTarget? best;
    var bestD = double.infinity;
    for (final t in hold) {
      if (t.spot != M7WarnSpot.person) continue;
      final r = rectOf(g, t);
      if (!r.contains(p)) continue;
      final d = (r.center - p).distance;
      if (d < bestD) {
        bestD = d;
        best = t;
      }
    }
    if (best != null) return best;
    for (final s in const [M7WarnSpot.span0, M7WarnSpot.span1, M7WarnSpot.houseA, M7WarnSpot.houseB, M7WarnSpot.houseD, M7WarnSpot.plot]) {
      final t = M7WarnTarget.place(s);
      if (hold.contains(t) && rectOf(g, t).contains(p)) return t;
    }
    return null;
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    return m;
  }

  M7WarnResult _needless(M7WarnTarget t) {
    needless++;
    if (t.spot == M7WarnSpot.person) {
      actors[t.actor].bothered = true;
    } else if (t.spot != deal.roofSpot) {
      // The roof item's house stays holdable (its item may come later).
      bothered.add(t.spot);
    }
    return M7WarnResult(M7WarnOutcome.needless, mistake: _slip(M7StreetWarnMistakes.needless));
  }

  M7WarnResult _rightWarn(M7WarnWhy why, String tag, String line) {
    _tag(tag);
    final ask = !_warnAsked;
    _warnAsked = true;
    return M7WarnResult(M7WarnOutcome.right, why: ask ? why : null, line: line);
  }

  M7WarnResult _rightReport(M7WarnWhy why, String tag, String line) {
    _tag(tag);
    final ask = !_reportAsked;
    _reportAsked = true;
    return M7WarnResult(M7WarnOutcome.right, why: ask ? why : null, line: line);
  }

  /// The chip's answer [a] on [t] at the current game ms.
  M7WarnResult act(M7WarnTarget t, M7WarnAct a) {
    if (!holdable(t)) return M7WarnResult.ignored;
    switch (t.spot) {
      case M7WarnSpot.person:
        final x = actors[t.actor];
        if (!x.hazard) return _needless(t);
        if (a == M7WarnAct.report) return M7WarnResult(M7WarnOutcome.wrongType, mistake: _slip(M7StreetWarnMistakes.carrierReport));
        final late = ms >= x.plan.lateFromMs;
        x.turn(ms);
        if (late) {
          return M7WarnResult(M7WarnOutcome.late, mistake: _slip(M7StreetWarnMistakes.lateWarn), line: M7StreetWarnLines.shoutCarrier);
        }
        return _rightWarn(M7WarnWhy.carrier, M7StreetWarnLines.caughtCarrier, M7StreetWarnLines.shoutCarrier);
      case M7WarnSpot.houseA || M7WarnSpot.houseB:
        if (t.spot == deal.roofSpot) {
          if (roofState == M7WarnRoofState.shown) {
            if (a == M7WarnAct.report) return M7WarnResult(M7WarnOutcome.wrongType, mistake: _slip(M7StreetWarnMistakes.roofReport));
            roofState = M7WarnRoofState.cleared;
            return deal.roof == M7WarnRoof.clothes
                ? _rightWarn(M7WarnWhy.clothes, M7StreetWarnLines.caughtClothes, M7StreetWarnLines.shoutClothes)
                : _rightWarn(M7WarnWhy.bamboo, M7StreetWarnLines.caughtBamboo, M7StreetWarnLines.shoutBamboo);
          }
          if (roofState == M7WarnRoofState.cleared) return const M7WarnResult(M7WarnOutcome.already, line: M7StreetWarnLines.already);
        }
        return _needless(t);
      case M7WarnSpot.houseD:
        return _needless(t);
      case M7WarnSpot.plot:
        if (!deal.build) return _needless(t);
        if (a == M7WarnAct.warn) {
          if (masonsWarned) return const M7WarnResult(M7WarnOutcome.already, line: M7StreetWarnLines.already);
          masonsWarned = true;
          return _rightWarn(M7WarnWhy.masons, M7StreetWarnLines.caughtMasons, M7StreetWarnLines.shoutMasons);
        }
        if (buildReported) return const M7WarnResult(M7WarnOutcome.already, line: M7StreetWarnLines.already);
        buildReported = true;
        return _rightReport(M7WarnWhy.build, M7StreetWarnLines.caughtBuild, M7StreetWarnLines.phoneBuild);
      case M7WarnSpot.span0 || M7WarnSpot.span1:
        final j = t.spot == M7WarnSpot.span0 ? 0 : 1;
        if (deal.sagSpan != j) return _needless(t);
        if (sagReported) return const M7WarnResult(M7WarnOutcome.already, line: M7StreetWarnLines.already);
        if (a == M7WarnAct.warn) return M7WarnResult(M7WarnOutcome.wrongType, mistake: _slip(M7StreetWarnMistakes.sagWarned));
        sagReported = true;
        return _rightReport(M7WarnWhy.sag, M7StreetWarnLines.caughtSag, M7StreetWarnLines.phoneSag);
    }
  }

  /// Listened to the coworker: a slip, and the guide warns the owner.
  DoMistake listen() {
    roofByGuide = true;
    if (roofState == M7WarnRoofState.shown) roofState = M7WarnRoofState.cleared;
    return _slip(M7StreetWarnMistakes.listen(deal.roof));
  }

  void refuse() => _tag(M7StreetWarnLines.caughtCall);

  /// The lane is clear: every static hazard left is a slip (in order).
  List<DoMistake> endSlips() {
    if (over || deadly != null) return const [];
    final out = <DoMistake>[
      if (roofState == M7WarnRoofState.shown) M7StreetWarnMistakes.roofLeft(deal.roof),
      if (deal.build && !masonsWarned) M7StreetWarnMistakes.buildNoWarn,
      if (deal.build && !buildReported) M7StreetWarnMistakes.buildNoReport,
      if (deal.sag && !sagReported) M7StreetWarnMistakes.sagLeft,
    ];
    slips += out.length;
    over = true;
    return out;
  }

  /// The scene's still part now.
  M7WarnSceneView get sceneView => M7WarnSceneView(
        sagSpan: deal.sagSpan,
        roof: deal.roof,
        roofHouse: deal.roofHouse,
        roofState: roofState,
        decoyRoof: deal.decoyRoof,
        build: deal.build,
        masonsDown: masonsWarned,
      );

  /// The people as drawn now.
  List<M7WarnActorView> views(M7WarnGeo g) {
    final out = <M7WarnActorView>[];
    for (final a in actors) {
      if (!a.visibleAt(ms)) continue;
      final p = a.progressAt(ms);
      final feet = g.at(a.plan.lane, p, a.plan.forward);
      final turned = a.turned;
      final goingRight = a.plan.lane == M7WarnLane.free ? !a.plan.forward : a.plan.forward;
      final lift = a.liftAt(ms);
      final walking = turned || !a.hazard || p < a.plan.stopAt;
      // Fade in/out at the free lane's far end.
      var opacity = 1.0;
      if (a.plan.lane == M7WarnLane.free) {
        final q = a.plan.forward ? p : 1 - p;
        opacity = q > 0.85 ? ((1 - q) / 0.15).clamp(0.0, 1.0) : 1.0;
      }
      final up = a.plan.lane == M7WarnLane.free && (a.plan.forward ? p : 1 - p) >= 0.5;
      out.add(M7WarnActorView(
        at: feet,
        look: m7WarnLookOf(a.plan.kind),
        facingLeft: turned ? goingRight : !goingRight,
        tint: a.plan.tint,
        phase: walking ? ((ms - a.plan.startMs) / (a.plan.kind == M7WarnKind.cyclist ? 380 : 560)) % 1 : null,
        lift: lift,
        liftTo: lift > 0 ? g.wireAbove(a.plan.lane, feet, sagSpan: deal.sagSpan) : null,
        opacity: opacity,
        lowered: turned,
        palm: turned && ms - a.warnedAt! < 1400,
        up: up,
      ));
    }
    return out;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded).
/// ms: the game clock runs 90 s, of which the empty stretches jump ahead
/// (~25 s saved) ≈ 65000; 5 holds + chip + ✓ ≈ 5 × 3500 = 17500; two reasons
/// ≈ 2 × 8200 = 16400; the coworker ≈ 9600; the end ≈ 1500 → ≈ 110000;
/// 85 % ≈ 94000 → 95 s (a builder's estimate; owner may tune after playtest).
const m7StreetWarnQuickMs = 95000;

@immutable
class M7StreetWarnPack {
  const M7StreetWarnPack({required this.id, required this.titleBn, this.quickMs = m7StreetWarnQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7StreetWarnPack> m7StreetWarnPacks = {
  'do_7_3_b': M7StreetWarnPack(id: 'do_7_3_b', titleBn: M7StreetWarnLines.title),
};

/// Test hook: the play on screen (tests only read it).
class M7StreetWarnProbe {
  _WarnRunPageState? _s;
  M7WarnRun? get run => _s?._run;
  M7WarnDeal? get deal => _s?._run.deal;
  M7WarnGeo? get geo => _s?._geoNow;
  double get gameMs => _s?._gameMs ?? 0;

  /// 'intro', 'watch', 'chip', 'preview', 'end', 'done'.
  String get phase {
    final s = _s;
    if (s == null) return 'none';
    if (s._intro) return 'intro';
    if (s._mark != null) return 'done';
    if (s._endPhase) return 'end';
    if (s._preview != null) return 'preview';
    if (s._chip != null) return 'chip';
    return 'watch';
  }

  /// The clock is running (people move or a jump is timed).
  bool get clockRunning => _s?._clockFree ?? false;

  /// A hold would open the chip now.
  bool get canHold => _s?._canHold ?? false;

  /// The roof item is up and the coworker is due or on screen.
  bool get waitingForHim => (_s?._waitHim ?? false) || (_s?.coworkerOpen ?? false);

  /// A target's centre on screen.
  Offset? targetGlobal(M7WarnTarget t) {
    final s = _s;
    final g = s?._geoNow;
    if (s == null || g == null) return null;
    final r = s._run.rectOf(g, t);
    final c = t.spot == M7WarnSpot.person ? Offset(r.center.dx, r.center.dy + r.height * 0.15) : r.center;
    return s._toGlobal(c);
  }
}

// ============================================================================
// Page
// ============================================================================

class M7StreetWarnPage extends StatefulWidget {
  const M7StreetWarnPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.probe});

  final LevelContext ctx;
  final M7StreetWarnPack pack;
  final bool muted;
  final int? seed;
  final M7StreetWarnProbe? probe;

  @override
  State<M7StreetWarnPage> createState() => _M7StreetWarnPageState();
}

class _M7StreetWarnPageState extends State<M7StreetWarnPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _WarnRunPage(
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

class _WarnRunPage extends ConsumerStatefulWidget {
  const _WarnRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry, this.probe});

  final LevelContext ctx;
  final M7StreetWarnPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;
  final M7StreetWarnProbe? probe;

  @override
  ConsumerState<_WarnRunPage> createState() => _WarnRunPageState();
}

class _WarnRunPageState extends ConsumerState<_WarnRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7WarnRun _run;
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

  // The game clock: a ticker while people move, a timer over the empty
  // stretches; still whenever the play waits for the player.
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;
  double _gameMs = 0;
  int _lastStep = -1;
  Timer? _gap;
  final _frame = ValueNotifier<int>(0);

  /// The roof item is up and he is on his way (the clock waits for him).
  var _waitHim = false;

  // The hold, the chip and its preview.
  M7WarnTarget? _pressTarget;
  Offset? _pressAt;
  int _pressN = 0;
  M7WarnTarget? _chip;
  Offset _chipAt = Offset.zero;
  M7WarnAct? _preview;
  final Set<M7WarnAct> _aside = {};
  final _warnKey = GlobalKey();
  final _reportKey = GlobalKey();

  // The trainee's shout / phone call (a moment).
  var _shouting = false;
  var _phoning = false;
  Timer? _poseTimer;

  // The end: the static hazards left, shown one by one.
  var _endPhase = false;
  final List<DoMistake> _endQueue = [];

  var _freeze = false;
  Completer<void>? _frozen;
  Offset? _flashAt;
  final _nudge = TaskNudge();
  int _nudgeN = 0;
  final List<Timer> _timers = [];

  // The gesture hand.
  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  M7WarnGeo? _geoNow;
  int _hintN = 0;
  int _steps = 0;

  @override
  void initState() {
    super.initState();
    _run = M7WarnRun(m7WarnDeal(widget.rng));
    widget.probe?._s = this;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _ticker.dispose();
    _gap?.cancel();
    _poseTimer?.cancel();
    for (final t in _timers) {
      t.cancel();
    }
    _frame.dispose();
    _chain++;
    if (widget.probe?._s == this) widget.probe?._s = null;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  void _later(int ms, VoidCallback f) {
    _timers.add(Timer(Duration(milliseconds: ms), () {
      if (mounted && !_ended) f();
    }));
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

  /// The guide says [lines], then (after a reading time) his bubble goes, so
  /// it never hides part of the পাড়া while people walk.
  Future<void> _sayThenClear(List<String> lines, {GuideMood mood = GuideMood.talk}) async {
    final chain = ++_chain;
    for (final line in lines) {
      if (!mounted || chain != _chain) return;
      final clock = Stopwatch()..start();
      await _say(line, mood: mood);
      final rest = MascotSpeechLibrary.readHold(line) - clock.elapsed;
      if (rest > Duration.zero) await Future<void>.delayed(rest);
    }
    if (!mounted || chain != _chain || _ended || _endPhase || coworkerOpen || reasonOpen) return;
    ref.read(guideDirectorProvider.notifier).softClearLine();
  }

  void _hush() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
  }

  void _cue(String file, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(file, volume: volume, muted: false));
  }

  Offset? _toGlobal(Offset design) {
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(design);
  }

  String get _task => _chip != null ? M7StreetWarnLines.askChip : M7StreetWarnLines.askWatch;

  /// The play is waiting on nothing: the clock may run.
  bool get _clockFree =>
      !_intro &&
      !_ended &&
      !_endPhase &&
      !_freeze &&
      _card == null &&
      !tableBusy &&
      !reasonOpen &&
      !coworkerOpen &&
      !_waitHim &&
      _chip == null &&
      _preview == null;

  /// A hold may start.
  bool get _canHold => _clockFree && !_run.ended;

  // --- the clock -------------------------------------------------------------------
  /// Starts or stops the clock as the play now stands.
  void _sync() {
    if (!mounted) return;
    if (!_clockFree) {
      if (_ticker.isActive) _ticker.stop();
      _gap?.cancel();
      _gap = null;
      return;
    }
    if (_run.watchOver) {
      _gap?.cancel();
      _gap = null;
      if (_ticker.isActive) _ticker.stop();
      _endWatch();
      return;
    }
    if (_run.anyVisible) {
      _gap?.cancel();
      _gap = null;
      if (!_ticker.isActive) {
        _lastTick = Duration.zero;
        unawaited(_ticker.start());
      }
      return;
    }
    if (_ticker.isActive) _ticker.stop();
    if (_gap != null) return;
    final next = _run.nextEventMs();
    final wait = math.min(next - _gameMs, kM7WarnGapMaxMs.toDouble()).round();
    _gap = Timer(Duration(milliseconds: math.max(0, wait)), () {
      _gap = null;
      if (!mounted || !_clockFree) return;
      _advance(next);
      _sync();
    });
  }

  void _onTick(Duration now) {
    final dt = (now - _lastTick).inMicroseconds / 1000.0;
    _lastTick = now;
    if (!_clockFree) {
      _ticker.stop();
      return;
    }
    _advance(_gameMs + dt.clamp(0.0, 64.0));
    if (!mounted || !_clockFree) {
      if (_ticker.isActive) _ticker.stop();
      return;
    }
    if (!_run.anyVisible) {
      _ticker.stop();
      _frame.value++;
      _sync();
      return;
    }
    final step = (_gameMs / 200).floor();
    if (!_quiet || step != _lastStep) {
      _lastStep = step;
      _frame.value++;
    }
  }

  /// Moves the game clock to [to] and answers what that brought.
  void _advance(double to) {
    _gameMs = to;
    final t = _run.tick(to);
    final hit = t.contact;
    if (hit != null) {
      _frame.value++;
      final g = _geoNow;
      final feet = g == null ? null : _run.feetOf(g, hit);
      final at = g == null || feet == null ? null : g.wireAbove(hit.plan.lane, feet, sagSpan: _run.deal.sagSpan);
      unawaited(_deadly(M7StreetWarnMistakes.contact, at: at));
      return;
    }
    if (t.roofAppeared) {
      // The roof item: the clock waits; he comes in now, once a play.
      setState(() {
        _waitHim = true;
        _wake++;
      });
      _frame.value++;
      _cue('sounds/intro/tick.ogg', volume: 0.4);
      scheduleCoworker();
    }
  }

  // --- the steps -----------------------------------------------------------------
  void _start() {
    _clock.start();
    setState(() {
      _intro = false;
      _wake++;
    });
    unawaited(_sayThenClear([M7StreetWarnLines.askWatch]));
    _sync();
  }

  void _endWatch() {
    if (_endPhase || _ended) return;
    setState(() {
      _endPhase = true;
      _wake++;
    });
    _endQueue
      ..clear()
      ..addAll(_run.endSlips());
    if (_endQueue.isEmpty) {
      unawaited(_finish());
      return;
    }
    unawaited(() async {
      await _sayChain([M7StreetWarnLines.endLine]);
      if (!mounted || _ended) return;
      _nextEndSlip();
    }());
  }

  void _nextEndSlip() {
    if (_endQueue.isEmpty) {
      unawaited(_finish());
      return;
    }
    final m = _endQueue.removeAt(0);
    final size = MediaQuery.sizeOf(context);
    unawaited(_levelDelta(-10, Offset(size.width / 2, size.height * 0.4), mood: GuideMood.warn));
    unawaited(_slip(m));
  }

  // --- the hold --------------------------------------------------------------------
  void _pressDown(Offset p) {
    final geo = _geoNow;
    if (geo == null || !_canHold) return;
    final t = _run.hitTest(geo, p);
    setState(() {
      _pressTarget = t;
      _pressAt = p;
      _pressN++;
    });
  }

  void _pressCancel() {
    if (_pressAt == null) return;
    setState(() {
      _pressAt = null;
      _pressTarget = null;
    });
  }

  void _pressHeld(Offset p) {
    final t = _pressTarget;
    setState(() {
      _pressAt = null;
      _pressTarget = null;
    });
    if (holdForCoworker()) return;
    if (!_canHold) return;
    if (t == null || !_run.holdable(t)) {
      _hints.missTap();
      return;
    }
    final geo = _geoNow;
    final r = geo == null ? null : _run.rectOf(geo, t);
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/confirm.ogg', volume: 0.55);
    _steps++;
    setState(() {
      _chip = t;
      _chipAt = (r == null ? null : _toGlobal(r.center)) ?? _toGlobal(p) ?? Offset.zero;
      _aside.clear();
      _wake++;
    });
    _frame.value++;
    _sync();
    unawaited(_sayChain([M7StreetWarnLines.askChip], mood: GuideMood.think));
  }

  void _tap(Offset p) {
    if (!_canHold) return;
    _hints.missTap();
  }

  void _openPreview(M7WarnAct a) {
    if (_chip == null || _preview != null || _ended) return;
    HapticFeedback.selectionClick();
    setState(() => _preview = a);
  }

  void _rejectPreview() {
    final a = _preview;
    if (a == null) return;
    setState(() {
      _preview = null;
      _aside.add(a);
    });
  }

  void _letGo() {
    if (_chip == null) return;
    _hush();
    HapticFeedback.selectionClick();
    _steps++;
    setState(() {
      _chip = null;
      _preview = null;
      _aside.clear();
      _wake++;
    });
    ref.read(guideDirectorProvider.notifier).softClearLine();
    _sync();
  }

  void _confirmPreview() {
    final a = _preview;
    final t = _chip;
    if (a == null || t == null) return;
    final geo = _geoNow;
    final origin = _chipAt;
    setState(() {
      _preview = null;
      _chip = null;
      _aside.clear();
      _wake++;
    });
    _steps++;
    final r = _run.act(t, a);
    _frame.value++;
    final line = r.line;
    switch (r.outcome) {
      case M7WarnOutcome.ignored:
        _sync();
        return;
      case M7WarnOutcome.already:
        unawaited(_sayThenClear([line!]));
        _sync();
        return;
      case M7WarnOutcome.right:
        if (a == M7WarnAct.warn) {
          _pose(shout: true);
        } else {
          _pose(shout: false);
        }
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
        final why = r.why;
        if (why != null) {
          _hush();
          _cue('sounds/quiz_right.ogg', volume: 0.6);
          putOnTable(15);
          unawaited(_say(line!, mood: GuideMood.glad));
          unawaited(askReason(
            deal: () => dealChoices(M7StreetWarnLines.whyRight[why]!, M7StreetWarnLines.myths, widget.rng),
            question: M7StreetWarnLines.whyQ[why]!,
            stillValid: () => !_ended,
          ));
        } else {
          final carrier = t.spot == M7WarnSpot.person;
          unawaited(_levelDelta(carrier ? 10 : 5, origin, mood: GuideMood.glad));
          unawaited(_sayThenClear([line!], mood: GuideMood.glad));
        }
        _sync();
        return;
      case M7WarnOutcome.late:
        _pose(shout: true);
        unawaited(_mistake(r.mistake!, origin));
        return;
      case M7WarnOutcome.wrongType || M7WarnOutcome.needless:
        if (geo != null && t.spot == M7WarnSpot.person) _frame.value++;
        unawaited(_mistake(r.mistake!, origin));
        return;
    }
  }

  /// The trainee shouts (warn) or phones (report) for a moment.
  void _pose({required bool shout}) {
    _poseTimer?.cancel();
    setState(() {
      _shouting = shout;
      _phoning = !shout;
      _wake++;
    });
    _poseTimer = Timer(Duration(milliseconds: shout ? 1200 : 2200), () {
      if (mounted) {
        setState(() {
          _shouting = false;
          _phoning = false;
        });
      }
    });
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
    _later(_quiet ? 300 : 700, () {
      setState(() => _wake++);
      unawaited(_sayThenClear([M7StreetWarnLines.askWatch]));
      _sync();
    });
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M7StreetWarnLines.coworker(_run.deal.roof);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.ended || coworkerDone) return null;
    if (!_waitHim) return false;
    if (_card != null || tableBusy || _freeze || _chip != null || _preview != null || _endPhase) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final roof = _run.deal.roof;
    if (!held) {
      final m = _run.listen();
      setState(() {
        _waitHim = false;
        _wake++;
      });
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m, guideWarns: true);
      return;
    }
    _run.refuse();
    setState(() {
      _waitHim = false;
      _wake++;
    });
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayThenClear([M7StreetWarnLines.callHeld(roof)], mood: GuideMood.glad));
    _sync();
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7StreetWarnLines.tapWhy[_nudgeN++ % M7StreetWarnLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    unawaited(coworkerOpen || reasonOpen || _chip != null ? _sayChain([line]) : _sayThenClear([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _ticker.stop();
    _gap?.cancel();
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  var _guideWarnsAfter = false;

  Future<void> _slip(DoMistake m, {bool guideWarns = false}) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    _hush();
    _ticker.stop();
    _gap?.cancel();
    _gap = null;
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _guideWarnsAfter = guideWarns;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m7streetwarn/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A load touched the line: the scene freezes grey and the flash comes off
  /// the wire in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m, {Offset? at}) async {
    if (_ended) return;
    _ended = true;
    _ticker.stop();
    _gap?.cancel();
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _flashAt = at;
      _chip = null;
      _preview = null;
      _pressAt = null;
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
    final speak = await SpokenOnce.first('m7streetwarn/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M7StreetWarnLines.deadlyWord : M7StreetWarnLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        final warns = _guideWarnsAfter;
        setState(() {
          _card = null;
          _guideWarnsAfter = false;
          _wake++;
        });
        if (_endPhase) {
          _nextEndSlip();
          return;
        }
        if (warns) {
          // The guide warns the roof's owner himself.
          _pose(shout: true);
          unawaited(_sayThenClear([M7StreetWarnLines.guideWarns, M7StreetWarnLines.shoutRoof(_run.deal.roof)]));
        } else {
          unawaited(_sayThenClear([M7StreetWarnLines.askWatch]));
        }
        _sync();
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

  /// Quick: under the pack's time with no needless warn or report (warning
  /// everyone must not pay).
  bool get _quick => _clock.elapsedMilliseconds < widget.pack.quickMs && _run.needless == 0;

  Future<void> _finish() async {
    if (_ended) return;
    _ended = true;
    _ticker.stop();
    _gap?.cancel();
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
    await _say(!_run.passed ? M7StreetWarnLines.fail : (_quickBonus ? M7StreetWarnLines.quick : M7StreetWarnLines.allSet),
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
    if (_shouting) return LinemanMode.point;
    if (_phoning) return LinemanMode.talk;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what (see the header comment).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    if (_chip != null) return HintSpec.sweepOver([_warnKey, _reportKey]);
    final rects = [for (final t in _run.holdables()) _run.rectOf(geo, t)];
    if (rects.length < 2) return null;
    if (_hintN++ == 0) return HintSpec.hold(geo.emptyRoad, space: HintSpace.scene);
    return HintSpec.sweep(rects, space: HintSpace.scene);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M7WarnGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final flash = _flashAt;
    final press = _pressAt;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('lane'),
                child: RepaintBoundary(child: CustomPaint(painter: M7WarnLanePainter(geo: geo, view: _run.sceneView))),
              ),
              Positioned.fill(
                key: const ValueKey('people'),
                child: RepaintBoundary(
                  child: CustomPaint(painter: M7WarnActorsPainter(geo: geo, views: () => _run.views(geo), repaint: _frame)),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
              if (_phoning)
                Positioned(
                  key: const ValueKey('phone'),
                  left: geo.trainee.right - 4,
                  top: geo.trainee.top - 4,
                  child: const IgnorePointer(child: Icon(Icons.phone_in_talk_rounded, size: 20, color: Color(0xFF9BE3B4))),
                ),
            ],
          ),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M7StreetWarnLines.sceneLabel,
          child: RawGestureDetector(
            key: _touchKey,
            behavior: HitTestBehavior.opaque,
            gestures: {
              LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(duration: const Duration(milliseconds: kM7WarnHoldMs)),
                (r) => r
                  ..onLongPressDown = ((d) => _pressDown(d.localPosition))
                  ..onLongPressCancel = _pressCancel
                  ..onLongPressStart = ((d) => _pressHeld(d.localPosition)),
              ),
              TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                TapGestureRecognizer.new,
                (r) => r..onTapUp = ((d) => _tap(d.localPosition)),
              ),
            },
          ),
        ),
      ),
      // The hold ring under the finger.
      if (press != null && !_freeze)
        Positioned.fill(
          key: ValueKey('ring-$_pressN'),
          child: IgnorePointer(
            child: quiet
                ? CustomPaint(painter: M7WarnHoldRingPainter(at: press, v: 0.5))
                : TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: kM7WarnHoldMs),
                    builder: (_, v, _) => CustomPaint(painter: M7WarnHoldRingPainter(at: press, v: v)),
                  ),
          ),
        ),
      if (_freeze && flash != null)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M7WarnFlashPainter(at: flash, v: v)),
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
    final chipUp = playing && _chip != null && _card == null && !deckUp;
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
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: playing && !deckUp && _card == null && !_endPhase && !_waitHim && !coworkerOpen && !tableBusy && _preview == null,
            hintKey: '${_chip != null}-$_steps',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (chipUp)
                Positioned.fill(
                  key: ValueKey('chip-${_chip!}-$_steps'),
                  child: _HoldChip(
                    at: _chipAt,
                    quiet: quiet,
                    warnKey: _warnKey,
                    reportKey: _reportKey,
                    asideWarn: _aside.contains(M7WarnAct.warn),
                    asideReport: _aside.contains(M7WarnAct.report),
                    onPick: _openPreview,
                    onLetGo: _letGo,
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
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: ValueKey('why-deck-$_steps')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              // Over the corner guide: nothing may cover the card's ✓ / ✕.
              if (chipUp && _preview != null)
                Positioned.fill(
                  key: ValueKey('act-preview-${_preview!.name}'),
                  child: CardPreviewOverlay(
                    textBn: M7StreetWarnLines.act(_preview!),
                    icon: _preview == M7WarnAct.warn ? Icons.campaign_rounded : Icons.phone_in_talk_rounded,
                    quiet: quiet,
                    muted: _muted,
                    bottom: pad.bottom,
                    onConfirm: _confirmPreview,
                    onReject: _rejectPreview,
                  ),
                ),
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
                  line: M7StreetWarnLines.intro,
                  alarm: 'sounds/learn/rush_in.ogg',
                  muted: _muted,
                  onDone: _start,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 3, muted: _muted)),
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

/// The hold chip: two answers alike in look, and 'ছেড়ে দিন'. A tap on an
/// answer opens its preview (✓ / ✕); a dimmed answer was set aside.
class _HoldChip extends StatelessWidget {
  const _HoldChip({
    required this.at,
    required this.quiet,
    required this.warnKey,
    required this.reportKey,
    required this.asideWarn,
    required this.asideReport,
    required this.onPick,
    required this.onLetGo,
  });

  final Offset at;
  final bool quiet;
  final GlobalKey warnKey;
  final GlobalKey reportKey;
  final bool asideWarn;
  final bool asideReport;
  final ValueChanged<M7WarnAct> onPick;
  final VoidCallback onLetGo;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    const w = 236.0;
    const h = 176.0;
    final left = (at.dx - w / 2).clamp(12.0, math.max(12.0, size.width - w - 12)).toDouble();
    // Above the target when there is room, else below it.
    final above = at.dy - h - 28;
    final top = (above > pad.top + 96 ? above : at.dy + 28).clamp(pad.top + 96, math.max(pad.top + 96, size.height - h - pad.bottom - 12)).toDouble();
    Widget button(M7WarnAct a, GlobalKey key, bool aside) => CardAside(
          aside: aside,
          child: Semantics(
            button: true,
            label: M7StreetWarnLines.act(a),
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey('chip-${a.name}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onPick(a),
              child: Container(
                key: key,
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                  border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.6),
                ),
                child: Row(
                  children: [
                    Icon(a == M7WarnAct.warn ? Icons.campaign_rounded : Icons.phone_in_talk_rounded, size: 20, color: SlmColors.gold300),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(M7StreetWarnLines.act(a),
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    final card = Container(
      width: w,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0xF0101A2B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.6), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          button(M7WarnAct.warn, warnKey, asideWarn),
          const SizedBox(height: 8),
          button(M7WarnAct.report, reportKey, asideReport),
          Semantics(
            button: true,
            label: M7StreetWarnLines.letGo,
            excludeSemantics: true,
            child: GestureDetector(
              key: const ValueKey('chip-letgo'),
              behavior: HitTestBehavior.opaque,
              onTap: onLetGo,
              child: SizedBox(
                height: 48,
                child: Center(
                  child: Text(M7StreetWarnLines.letGo, style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: SlmColors.ivory.withValues(alpha: 0.8))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return Stack(
      children: [
        // A tap beside the chip lets go too.
        Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onLetGo)),
        Positioned(
          left: left,
          top: top,
          child: quiet
              ? card
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) => Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.scale(scale: 0.9 + 0.1 * v, child: child)),
                  child: card,
                ),
        ),
      ],
    );
  }
}
