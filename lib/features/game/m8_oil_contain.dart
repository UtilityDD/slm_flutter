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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm8_oil_contain_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm8_oil_contain_world.dart' show M8Dest, M8Geo, M8Kit, M8Mat, M8Station, M8Veh, m8Hull, m8HullContains;

// Lesson 8.9 "পরিবেশগত নিয়মাবলী: রাজ্যের দৃষ্টিকোণ", কাজ 2 "এক ফোঁটাও মাটিতে নয়"
// (pack do_8_9_b, rung 8.9/do/1, engineType m8_oil_contain). Verb: spread a
// plastic sheet, flick sand over a spill and twist-seal a drum (M8-20: not
// 7.8a's boom ring, not 7.8b's vehicles). The old transformer is lowered on the
// ground, the electrical work finished, nothing live; no AB switch is scored
// (M8-19). Station 1 is always there, plus two of the other three, dealt order:
//
//  Station 1 (oil): drag গ্লাভস and the mask from the van's door onto the
//    worker; drag the four corners of the folded sheet out under the
//    transformer and its valve side (no outline of the drip zone); tap the valve
//    (before the kit = a PCB slip and it stays shut; over bare soil = a slip);
//    the oil runs into the drum and stops when it is full; twist the cap round
//    2–3 turns until it clicks (the drum moved on loose = a slip); drag the
//    sealed drum to one of the four dealt places — only the 'ডিসপোজাল সেন্টার'
//    truck is right (◆ → "কেন ড্রাম সিল করে ডিসপোজালে?").
//  Station 2 (store): the leaking drum's puddle spreads toward the floor drain.
//    Tap a material on the wall (sand or sawdust right; the hose = a slip, the
//    broom then pushes it toward the drain = a slip), then flick handfuls onto
//    the puddle until it is covered. The puddle reaching the drain first = a slip.
//  Station 3 (battery room): drag each old battery to the recycler's van; the
//    scrap cart (bell, a man waving cash) = a slip and the battery comes back.
//  Station 4 (job-site grass): rake strokes turn up 3–5 hidden offcuts; tap each
//    into the bag; the cows drift closer. 'সাফ' with one left = a slip.
//
// No deadly mistake (M8-1/M8-6: PCB oil without গ্লাভস and mask is a slip, all
// environmental acts are slips). Three slips strike out. The coworker, once a
// play, at the sealed drum (the myth word for word) or, when the store is dealt,
// at the first flick (the hose); listening = a slip (B1/X2) with the act's
// picture. Built on the shared level kit: guide first, full scene, corner guide,
// ReasonTable ("কেন?" cards at once), CoworkerMoment (his control waits for
// him), gesture hands for every waiting state (how, never what), MistakeCard,
// DoStrikeOut, pass panel with stars. Idle = zero frames: the clock redraws only
// while oil or the puddle is moving.

// ============================================================================
// Content
// ============================================================================

/// The coworker's push (one a play, dealt).
enum M8Push { weed, hose }

/// What a reason asks about.
enum M8Why { kit, sheet, route, sand, battery, offcut }

/// Where the play is (the current station's step).
enum M8Stage { prep, fill, seal, route, store, battery, grass, done }

abstract final class M8OilContainLines {
  static const title = 'এক ফোঁটাও মাটিতে নয়';

  // DRAFT wording — owner (M6-12): every guide line below is new text.
  static const intro = 'পুরনো ট্রান্সফরমারের তেল সামলান — এক ফোঁটাও মাটিতে নয়।';
  static const askPrep = 'তেল নামানোর কাজ শুরু করুন।';
  static const askFill = 'ড্রামে তেল নামছে।';
  static const askSeal = 'ভরা ড্রামটা সামলান।';
  static const askRoute = 'ড্রামটা এবার কোথায় যাবে?';
  static const askStore = 'স্টোরে তেল ছড়াচ্ছে — সামলান!';
  static const askBattery = 'ব্যাটারিগুলোর ব্যবস্থা করুন।';
  static const askGrass = 'কাজ শেষ — জায়গাটা সাফ করুন।';
  static const leadStore = 'এবার স্টোর রুমে চলুন।';
  static const leadBattery = 'এবার ব্যাটারি রুমে চলুন।';
  static const leadGrass = 'এবার কাজের জায়গার মাঠে চলুন।';
  static const tasks = [askPrep, askFill, askSeal, askRoute, askStore, askBattery, askGrass];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  static String ask(M8Stage s) => switch (s) {
        M8Stage.prep => askPrep,
        M8Stage.fill => askFill,
        M8Stage.seal => askSeal,
        M8Stage.route || M8Stage.done => askRoute,
        M8Stage.store => askStore,
        M8Stage.battery => askBattery,
        M8Stage.grass => askGrass,
      };

  static String lead(M8Station s) => switch (s) {
        M8Station.oil => '',
        M8Station.store => leadStore,
        M8Station.battery => leadBattery,
        M8Station.grass => leadGrass,
      };

  // On screen (only plates a real worker would read; the rest is picture).
  static const sceneLabel = 'কাজের জায়গা';
  static const truckPlate = 'ডিসপোজাল সেন্টার';
  static const vanPlate = 'অথরাইজড রিসাইক্লার';
  static const sweepLabel = 'সাফ';
  static const stationNames = <M8Station, String>{
    M8Station.oil: 'তেল',
    M8Station.store: 'স্টোর',
    M8Station.battery: 'ব্যাটারি',
    M8Station.grass: 'মাঠ',
  };

  // The reasons. The right ones fit what was done (lesson 8.9 points, pro tips
  // 2 and 3, the advanced PCB fact); the wrong ones are the lesson's myth and
  // field excuses. DRAFT wording — owner.
  static const whyQ = <M8Why, String>{
    M8Why.kit: 'কেন আগে গ্লাভস আর মাস্ক?',
    M8Why.sheet: 'কেন নিচে প্লাস্টিক শিট?',
    M8Why.route: 'কেন ড্রাম সিল করে ডিসপোজালে?',
    M8Why.sand: 'কেন বালু, জল নয়?',
    M8Why.battery: 'কেন অথরাইজড রিসাইক্লারকে দিলেন?',
    M8Why.offcut: 'কেন তারের টুকরো কুড়োলেন?',
  };
  static const whyRight = <M8Why, List<String>>{
    M8Why.kit: ['পুরনো ট্রান্সফরমারের তেলে PCBs থাকতে পারে, তাই', 'ওই তেলের PCBs থেকে ক্যান্সার হতে পারে, তাই'],
    M8Why.sheet: ['যাতে এক ফোঁটা তেলও মাটিতে গিয়ে না পড়ে, তাই', 'শিটের ওপর পড়লে তেল মাটি ছুঁতে পারে না, তাই'],
    M8Why.route: ['এই তেল মাটি ও জল দুটোকেই বিষাক্ত করে, তাই', 'সিল-করা ড্রামে ডিসপোজাল সেন্টারে পাঠাতে হয়, তাই'],
    M8Why.sand: ['জল দিলে তেল আরও ছড়িয়ে পড়ে, তাই বালু দিই', 'বালু বা কাঠের গুঁড়ো তেলকে ছড়াতে দেয় না, তাই'],
    M8Why.battery: ['সীসা আর এসিড পরিবেশের জন্য মারাত্মক ক্ষতিকর, তাই', 'বাতিল ব্যাটারি অথরাইজড রিসাইক্লারকেই দিতে হয়, তাই'],
    M8Why.offcut: ['গরু-ছাগল এগুলো খেয়ে মারা যেতে পারে, তাই', 'তারের টুকরো খেলে গরু-ছাগলের প্রাণ যেতে পারে, তাই'],
  };
  static const myths = [
    'পোড়া তেল আগাছা মারার জন্য খুব ভালো, তাই',
    'এটুকু তেল মাটি নিজেই শুষে নেবে, তাই কিছু হয় না',
    'এই নিয়ম বড় ফ্যাক্টরির জন্য, আমাদের নয়, তাই',
    'এসব না মানলেও কেউ ধরবে না, তাই কিছু হয় না',
    'কাজ তাড়াতাড়ি শেষ করার সোজা পথ এটাই, তাই',
    'ঝামেলা কমাতে সবাই এভাবেই কাজ করে থাকে, তাই',
    'টুকরো ছোট, তাতে কারও কিছু ক্ষতি হয় না, তাই',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play). The myth word for word and the
  // hose line (M8-14). DRAFT wording — owner; both need recording
  // (tool/rival_clip.py); the myth line reuses the board's clip.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerWeed = CoworkerScript(
    line: 'পোড়া মবিল বা ট্রান্সফরমার অয়েল আগাছা মারার জন্য খুব ভালো, তাই ওটা মাটিতে ঢেলে দিই।',
    exitLine: coworkerExit,
    right: [
      'না, মাটি অনুর্বর হয়, জল দূষিত হয়, ডিসপোজালে যাবে',
      'না, এই তেল ভূগর্ভস্থ জল নষ্ট করে, ড্রামেই থাকবে',
      'না, মাঠে ঢালা আইনত দণ্ডনীয়, ডিসপোজালেই পাঠাব',
    ],
    wrong: [
      'ঠিক, আগাছা মরে যাবে — মাঠের ধারে ঢেলে দিই',
      'ঠিক, তেল ঢাললে মাঠ সাফ থাকবে, তাই ঢেলে দিই',
      'ঠিক, ডিসপোজালে পাঠানো বড় ঝামেলা, মাঠেই ঢালি',
      'ঠিক, এটুকু তেলে মাটির কিছু হবে না, ঢেলে দিই',
      'ঠিক, কেউ দেখবে না, তাই মাঠের ধারে ঢেলে দেব',
    ],
    asks: ['কী করবেন?', 'ও বলছে তেলটা মাঠে ঢেলে দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerHose = CoworkerScript(
    line: 'জল দিয়ে ধুয়ে দাও, এক মিনিটে সাফ!',
    exitLine: coworkerExit,
    right: [
      'না, জলে তেল আরও ছড়ায় — বালু বা কাঠের গুঁড়ো দেব',
      'না, জল দিলে তেল ড্রেনে চলে যাবে, বালুই দেব',
      'না, আগে বালু ছড়িয়ে তেল শুষে নেব, জল নয়',
    ],
    wrong: [
      'ঠিক, পাইপ চালাও, ধুয়ে ফেলি, এক মিনিটের কাজ',
      'ঠিক, জল ঢাললে তেল ধুয়ে সরে যাবে, ধুয়ে ফেলি',
      'ঠিক, বালু লাগবে না, পাইপ চালিয়ে ধুয়ে দিই',
      'ঠিক, জলে ধুলেই সাফ হবে, পাইপটা চালিয়ে দিই',
      'ঠিক, ড্রেনে তো যাবেই, পাইপের জল চালিয়ে দিই',
    ],
    asks: ['কী করবেন?', 'ও বলছে জল দিয়ে ধুয়ে দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M8Push p) => switch (p) {
        M8Push.weed => coworkerWeed,
        M8Push.hose => coworkerHose,
      };
  static const allCoworkers = [coworkerWeed, coworkerHose];

  static String callHeld(M8Push p) => switch (p) {
        M8Push.weed => 'ঠিক! ওই তেলে মাটি অনুর্বর হয়, জলও দূষিত হয়।',
        M8Push.hose => 'ঠিক! জলে তেল ছড়ায় — বালু বা কাঠের গুঁড়ো দিন।',
      };

  static const allSet = 'এক ফোঁটাও মাটিতে যায়নি — সবকিছু ঠিক জায়গায়। দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — গ্লাভস আর মাস্ক পরে, শিট বিছিয়ে, তেল সিল করে ডিসপোজালে।';

  // "আজ যা ধরলেন" (on screen).
  static const caughtKit = 'গ্লাভস আর মাস্ক পরে তেলে হাত দিয়েছেন';
  static const caughtSheet = 'নিচে শিট বিছিয়ে তেল নামিয়েছেন';
  static const caughtRoute = 'তেল সিল করে ডিসপোজালে পাঠিয়েছেন';
  static const caughtSand = 'ছড়ানো তেলে বালু বা কাঠের গুঁড়ো দিয়েছেন';
  static const caughtBattery = 'ব্যাটারি অথরাইজড রিসাইক্লারকে দিয়েছেন';
  static const caughtOffcut = 'মাঠের তারের টুকরো কুড়িয়েছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Every new spoken guide line (DRAFT wording — owner; to be recorded): the
  /// guide's lines, the why-questions, the texts of the mistakes (read aloud the
  /// first time) and the rotated asks of the coworker's deck.
  static const newGuideLines = [
    intro,
    askPrep,
    askFill,
    askSeal,
    askRoute,
    askStore,
    askBattery,
    askGrass,
    leadStore,
    leadBattery,
    leadGrass,
    'কারণটা বেছে নিন।',
    'ঠিক কারণটা কোনটা?',
    'কেন আগে গ্লাভস আর মাস্ক?',
    'কেন নিচে প্লাস্টিক শিট?',
    'কেন ড্রাম সিল করে ডিসপোজালে?',
    'কেন বালু, জল নয়?',
    'কেন অথরাইজড রিসাইক্লারকে দিলেন?',
    'কেন তারের টুকরো কুড়োলেন?',
    'ঠিক! ওই তেলে মাটি অনুর্বর হয়, জলও দূষিত হয়।',
    'ঠিক! জলে তেল ছড়ায় — বালু বা কাঠের গুঁড়ো দিন।',
    allSet,
    quick,
    fail,
    'ও বলছে তেলটা মাঠে ঢেলে দিতে। কী করবেন?',
    'ও বলছে জল দিয়ে ধুয়ে দিতে। কী করবেন?',
    M8OilContainMistakes.pcbBn,
    M8OilContainMistakes.sheetBn,
    M8OilContainMistakes.looseBn,
    M8OilContainMistakes.routeBn,
    M8OilContainMistakes.hoseBn,
    M8OilContainMistakes.broomBn,
    M8OilContainMistakes.drainBn,
    M8OilContainMistakes.cartBn,
    M8OilContainMistakes.offcutBn,
    M8OilContainMistakes.listenWeedBn,
    M8OilContainMistakes.listenHoseBn,
  ];

  /// The coworker's pushes (DRAFT wording — owner; to be recorded in his voice).
  /// His exit line is recorded already; the myth line reuses the board's clip.
  static const newRivalLines = [
    'পোড়া মবিল বা ট্রান্সফরমার অয়েল আগাছা মারার জন্য খুব ভালো, তাই ওটা মাটিতে ঢেলে দিই।',
    'জল দিয়ে ধুয়ে দাও, এক মিনিটে সাফ!',
  ];
}

abstract final class M8OilContainMistakes {
  static const _dir = 'assets/game/art/m8_oil_contain';

  // Lesson 8.9 points as the reader numbers them (0-based): 0 the cut-or-trim
  // item, 1 RoW maintenance, 2 transformer oil (drum, sheet, drain, PCB, pro
  // tip 2), 3 old batteries (and pro tip 3's waste). All slips (M8-1, M8-6).
  // DRAFT wording — owner (read aloud the first time).
  static const pcbBn = 'পুরনো ট্রান্সফরমারের তেলে PCBs থাকতে পারে, যা ক্যান্সার ঘটায়। গ্লাভস ও মাস্ক পরা বাধ্যতামূলক — আগে সেটা পরুন।';
  static const pcb = DoMistake(key: '8.9/m8_oil_contain/pcb', textBn: pcbBn, art: '$_dir/pcb.svg', lessonPoint: 2);
  static const sheetBn = 'শিট তেল পড়ার জায়গা ঢাকেনি — মাটিতে দাগ পড়ল। ট্রান্সফরমারের নিচে প্লাস্টিক শিট এমনভাবে বিছান, যাতে এক ফোঁটা তেলও মাটিতে না পড়ে।';
  static const sheet = DoMistake(key: '8.9/m8_oil_contain/sheet', textBn: sheetBn, art: '$_dir/sheet.svg', lessonPoint: 2);
  static const looseBn = 'ঢাকনা আলগা ছিল — সরাতে গিয়ে তেল চলকে পড়ল। ড্রামে ভরে সিল করে তবেই সরান।';
  static const loose = DoMistake(key: '8.9/m8_oil_contain/loose', textBn: looseBn, art: '$_dir/loose.svg', lessonPoint: 2);
  static const routeBn = 'এই তেল মাটি ও জলকে বিষাক্ত করে। ড্রামে ভরে সিল করে নির্দিষ্ট ডিসপোজাল সেন্টারে পাঠাতে হয় — ড্রেনে বা মাঠে ফেলা আইনত দণ্ডনীয়।';
  static const route = DoMistake(key: '8.9/m8_oil_contain/route', textBn: routeBn, art: '$_dir/route.svg', lessonPoint: 2);
  static const hoseBn = 'জল দিলে তেল আরও ছড়িয়ে পড়ে। বালু বা কাঠের গুঁড়ো সঙ্গে সঙ্গে ছড়িয়ে দিন, জল দিয়ে ধুবেন না।';
  static const hose = DoMistake(key: '8.9/m8_oil_contain/hose', textBn: hoseBn, art: '$_dir/hose.svg', lessonPoint: 2);
  static const broomBn = 'ঝাড়ু দিয়ে ঠেললে তেল ড্রেনের দিকেই ছড়ায়। আগে বালু বা কাঠের গুঁড়ো ছড়িয়ে তেল শুষে নিন।';
  static const broom = DoMistake(key: '8.9/m8_oil_contain/broom', textBn: broomBn, art: '$_dir/broom.svg', lessonPoint: 2);
  static const drainBn = 'তেল মেঝের ড্রেনে পৌঁছে গেল! লিকেজ হওয়া তেল ড্রেনে ফেলা আইনত দণ্ডনীয়। ছড়ানোর আগেই বালু দিয়ে ঢাকুন।';
  static const drain = DoMistake(key: '8.9/m8_oil_contain/drain', textBn: drainBn, art: '$_dir/drain.svg', lessonPoint: 2);
  static const cartBn = 'ব্যাটারির সীসা আর এসিড পরিবেশের জন্য মারাত্মক ক্ষতিকর। বাতিল ব্যাটারি শুধু অথরাইজড রিসাইক্লারকেই দেওয়া যায় — ভাঙাড়ির গাড়িকে নয়।';
  static const cart = DoMistake(key: '8.9/m8_oil_contain/cart', textBn: cartBn, art: '$_dir/cart.svg', lessonPoint: 3);
  static const offcutBn = 'মাঠে তারের টুকরো থেকে গেছে। গরু-ছাগল এগুলো খেয়ে মারা যেতে পারে — কাজ শেষে একটাও ফেলে আসবেন না।';
  static const offcut = DoMistake(key: '8.9/m8_oil_contain/offcut', textBn: offcutBn, art: '$_dir/offcut.svg', lessonPoint: 3);
  static const listenWeedBn = 'ওই তেল ঢাললে মাটি চিরতরে অনুর্বর হয়ে যায়, ভূগর্ভস্থ জল দূষিত হয় — আইন অনুযায়ী বড় অপরাধ।';
  static const listenWeed = DoMistake(key: '8.9/m8_oil_contain/listen-weed', textBn: listenWeedBn, art: '$_dir/listen_weed.svg', lessonPoint: 2);
  static const listenHoseBn = 'জল দিয়ে ধুলে তেল আরও ছড়িয়ে পড়ে। বালু বা কাঠের গুঁড়োই ঠিক।';
  static const listenHose = DoMistake(key: '8.9/m8_oil_contain/listen-hose', textBn: listenHoseBn, art: '$_dir/listen_hose.svg', lessonPoint: 2);

  static DoMistake push(M8Push p) => switch (p) {
        M8Push.weed => listenWeed,
        M8Push.hose => listenHose,
      };

  static const List<DoMistake> all = [pcb, sheet, loose, route, hose, broom, drain, cart, offcut, listenWeed, listenHose];
}

// ============================================================================
// The rules (pure)
// ============================================================================

/// Cap turns are counted in radians; this many full turns, dealt 2 or 3.
const double m8FullTurn = 2 * math.pi;

/// A drum dragged loose farther than this (design px) sloshes.
const double m8LooseMove = 36;

/// How close (design px) a rake pass must come to uncover an offcut.
const double m8RakeReach = 24;

/// A flick slower than this (design px a second) is only a wave.
const double m8FlickSpeed = 250;

/// The puddle's spread speeds by band (design px a second).
const List<double> m8PuddleRates = [10, 13, 16];

/// The puddle's first size.
const double m8PuddleStart = 16;

/// One play's deal.
@immutable
class M8Deal {
  const M8Deal({
    required this.order,
    required this.valveFlip,
    required this.fx,
    required this.fw,
    required this.capTurns,
    required this.fillSecs,
    required this.dests,
    required this.mats,
    required this.storeFlip,
    required this.band,
    required this.flicks,
    required this.vanSlot,
    required this.batteries,
    required this.offcuts,
    required this.cwAtStore,
    required this.push,
    required this.dusk,
    required this.whyRoll,
    required this.hintIx,
  });

  /// The stations in play order: the oil yard and two of the other three.
  final List<M8Station> order;

  /// The valve side (the whole yard mirrors) and the transformer's footprint.
  final bool valveFlip;
  final double fx;
  final double fw;

  /// Full turns of the cap until it clicks (2 or 3) and the seconds the oil runs.
  final int capTurns;
  final double fillSecs;

  /// What lies in each of the four destination slots (a permutation).
  final List<M8Dest> dests;

  /// What hangs in each of the four wall slots (a permutation).
  final List<M8Mat> mats;
  final bool storeFlip;

  /// Spread-speed band 0–2 ([m8PuddleRates]) and the handfuls that cover it.
  final int band;
  final int flicks;

  /// The recycler's van is on this side (0 left, 1 right); how many batteries.
  final int vanSlot;
  final int batteries;

  /// Hidden offcuts as 0..1 places in the grass.
  final List<Offset> offcuts;

  /// The coworker comes at the store's first flick (else at the sealed drum).
  final bool cwAtStore;
  final M8Push push;
  final bool dusk;
  final int whyRoll;

  /// A random pick for the hands (which kit item, which corner, which strip).
  final int hintIx;

  bool has(M8Station s) => order.contains(s);
  double get rate => m8PuddleRates[band];
}

M8Deal m8OilDeal(math.Random rng) {
  final others = [M8Station.store, M8Station.battery, M8Station.grass]..shuffle(rng);
  final two = others.take(2).toList();
  final order = rng.nextBool() ? [M8Station.oil, ...two] : [two[0], M8Station.oil, two[1]];
  final cwAtStore = order.contains(M8Station.store) && rng.nextBool();
  final n = 3 + rng.nextInt(3);
  final pts = <Offset>[];
  var guard = 0;
  while (pts.length < n && guard++ < 600) {
    final c = Offset(rng.nextDouble(), rng.nextDouble());
    final ok = pts.every((p) => Offset((p.dx - c.dx) * 292, (p.dy - c.dy) * 110).distance >= 56);
    if (ok) pts.add(c);
  }
  while (pts.length < n) {
    pts.add(Offset(0.1 + 0.2 * pts.length, pts.length.isEven ? 0.2 : 0.8));
  }
  return M8Deal(
    order: order,
    valveFlip: rng.nextBool(),
    fx: rng.nextInt(13).toDouble(),
    fw: rng.nextInt(15).toDouble(),
    capTurns: 2 + rng.nextInt(2),
    fillSecs: 2.5 + rng.nextDouble() * 2.0,
    dests: [...M8Dest.values]..shuffle(rng),
    mats: [...M8Mat.values]..shuffle(rng),
    storeFlip: rng.nextBool(),
    band: rng.nextInt(3),
    flicks: 3 + rng.nextInt(3),
    vanSlot: rng.nextInt(2),
    batteries: 2 + rng.nextInt(2),
    offcuts: pts,
    cwAtStore: cwAtStore,
    push: cwAtStore ? M8Push.hose : M8Push.weed,
    dusk: rng.nextInt(4) == 0,
    whyRoll: rng.nextInt(1000),
    hintIx: rng.nextInt(1000),
  );
}

/// What one tick of the puddle clock did.
@immutable
class M8Tick {
  const M8Tick({this.changed = false, this.slip});
  final bool changed;
  final DoMistake? slip;
}

/// What one flick did.
@immutable
class M8Flick {
  const M8Flick({this.landed = false, this.covered = false, this.slip});
  final bool landed;
  final bool covered;
  final DoMistake? slip;
}

/// The play state (pure logic).
class M8OilRun {
  M8OilRun(this.deal) : flicksNeeded = deal.flicks;

  final M8Deal deal;
  int ix = 0;
  var finished = false;

  M8Station get station => deal.order[ix];
  bool get lastStation => ix == deal.order.length - 1;

  // --- station 1: the DTR yard ----------------------------------------------------
  var gloves = false;
  var mask = false;
  List<Offset>? corners;
  var cornersMoved = false;
  var valveWasOpen = false;
  var valveOpen = false;
  double fill = 0;
  var full = false;
  double capAngle = 0;
  var sealed = false;
  var routed = false;
  var stain = false;
  var kitReasoned = false;

  // --- station 2: the store ---------------------------------------------------------
  var storeLive = false;
  M8Mat? selected;
  double puddleS = m8PuddleStart;
  int flicksNeeded;
  int flicksDone = 0;
  var held = false;
  var atDrain = false;
  var sheen = false;
  var covered = false;

  // --- station 3: the battery room ------------------------------------------------
  late final List<bool> loaded = List<bool>.filled(deal.batteries, false);

  // --- station 4: the grass ---------------------------------------------------------
  late final List<bool> revealed = List<bool>.filled(deal.offcuts.length, false);
  late final List<bool> bagged = List<bool>.filled(deal.offcuts.length, false);
  var clean = false;

  int slips = 0;
  int stageSlips = 0;
  final List<String> caught = [];

  bool get kitOn => gloves && mask;
  bool get touched => gloves || mask || cornersMoved;
  bool get batteriesDone => loaded.every((x) => x);
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get ended => finished;
  bool get passed => finished && percent >= 55;
  bool get anyRevealed => revealed.any((x) => x);
  int get cowSteps => revealed.where((x) => x).length + bagged.where((x) => x).length;

  /// The cow's progress toward the grass, 0..1.
  double get cow => deal.offcuts.isEmpty ? 0 : (cowSteps / (2 * deal.offcuts.length)).clamp(0.0, 1.0);

  bool get stationDone => switch (station) {
        M8Station.oil => routed,
        M8Station.store => covered,
        M8Station.battery => batteriesDone,
        M8Station.grass => clean,
      };

  M8Stage get stage {
    switch (station) {
      case M8Station.oil:
        if (!valveWasOpen) return M8Stage.prep;
        if (!full) return M8Stage.fill;
        if (!sealed) return M8Stage.seal;
        if (!routed) return M8Stage.route;
        return M8Stage.done;
      case M8Station.store:
        return covered ? M8Stage.done : M8Stage.store;
      case M8Station.battery:
        return batteriesDone ? M8Stage.done : M8Stage.battery;
      case M8Station.grass:
        return clean ? M8Stage.done : M8Stage.grass;
    }
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stageSlips++;
    return m;
  }

  /// The play moves to the next station.
  void advance() {
    if (ix < deal.order.length - 1) ix++;
    stageSlips = 0;
  }

  /// The table was paid: the next step's slips count afresh.
  void tablePaid() => stageSlips = 0;

  // --- oil ----------------------------------------------------------------------------
  /// Gloves or mask dropped on the worker.
  bool wear(M8Kit k) {
    if (k == M8Kit.gloves) {
      if (gloves) return false;
      gloves = true;
    } else {
      if (mask) return false;
      mask = true;
    }
    return true;
  }

  /// A sheet corner dragged to [p] (kept on the ground); locked once the oil
  /// has run.
  bool moveCorner(int i, Offset p, M8Geo geo) {
    if (valveWasOpen || station != M8Station.oil) return false;
    final c = corners ??= List<Offset>.of(geo.sheetHome);
    c[i] = geo.clampCorner(p);
    cornersMoved = true;
    return true;
  }

  /// Does the sheet cover every point where oil drips.
  bool sheetCovers(M8Geo geo) {
    final c = corners;
    if (c == null) return false;
    return geo.zoneSamples.every((p) => m8HullContains(c, p));
  }

  /// The valve tapped. Before the kit: a slip (PCB oil, the valve stays shut).
  /// Over bare soil: a slip (a stain, the valve shuts). Else the oil runs.
  DoMistake? tapValve(M8Geo geo) {
    if (valveWasOpen || station != M8Station.oil) return null;
    if (!kitOn) return _slip(M8OilContainMistakes.pcb);
    if (!sheetCovers(geo)) {
      stain = true;
      return _slip(M8OilContainMistakes.sheet);
    }
    valveOpen = true;
    valveWasOpen = true;
    _tag(M8OilContainLines.caughtKit);
    _tag(M8OilContainLines.caughtSheet);
    return null;
  }

  /// The oil runs into the drum; true while something changed. The valve
  /// closes by itself when the drum is full.
  bool tickFill(double dt) {
    if (!valveOpen) return false;
    fill = math.min(1.0, fill + dt / deal.fillSecs);
    if (fill >= 1) {
      valveOpen = false;
      full = true;
    }
    return true;
  }

  /// The finger turned the cap by [delta] radians (the sign is the direction;
  /// back and forth cancels). Clicks shut after the dealt turns.
  bool turnCap(double delta) {
    if (!full || sealed) return false;
    capAngle += delta;
    if (capAngle.abs() >= deal.capTurns * m8FullTurn) {
      sealed = true;
      return true;
    }
    return false;
  }

  /// The drum moved on while the cap is loose.
  DoMistake? moveLoose() => full && !sealed ? _slip(M8OilContainMistakes.loose) : null;

  /// The sealed drum let go on a destination.
  DoMistake? routeTo(M8Dest d) {
    if (!sealed || routed) return null;
    if (d == M8Dest.truck) {
      routed = true;
      _tag(M8OilContainLines.caughtRoute);
      return null;
    }
    return _slip(M8OilContainMistakes.route);
  }

  // --- store ------------------------------------------------------------------------------
  /// The material on the wall tapped: the hose is a slip (the sheen races out
  /// and one more handful is needed); the rest is taken in hand.
  DoMistake? tapMat(M8Mat m) {
    if (!storeLive || covered) return null;
    if (m == M8Mat.hose) {
      selected = null;
      sheen = true;
      puddleS = math.min(puddleS + 30, 190 - 6);
      flicksNeeded++;
      return _slip(M8OilContainMistakes.hose);
    }
    selected = m;
    return null;
  }

  /// A flick that landed on the puddle. Sand or sawdust covers it a little
  /// more (the spread stops with the first handful); the broom pushes it toward
  /// the drain (a slip).
  M8Flick flick() {
    if (!storeLive || covered || selected == null) return const M8Flick();
    if (selected == M8Mat.broom) {
      selected = null;
      puddleS = math.min(puddleS + 40, 190 - 6);
      return M8Flick(slip: _slip(M8OilContainMistakes.broom));
    }
    flicksDone++;
    held = true;
    if (flicksDone >= flicksNeeded) {
      covered = true;
      selected = null;
      _tag(M8OilContainLines.caughtSand);
      return const M8Flick(landed: true, covered: true);
    }
    return const M8Flick(landed: true);
  }

  /// [dt] playable seconds: the oil spreads until the first handful (or the
  /// drain). Reaching the drain first is a slip, once.
  M8Tick tickPuddle(double dt, M8Geo geo) {
    if (!storeLive || held || covered || atDrain) return const M8Tick();
    puddleS = math.min(geo.reachS, puddleS + deal.rate * dt);
    if (puddleS >= geo.reachS) {
      atDrain = true;
      return M8Tick(changed: true, slip: _slip(M8OilContainMistakes.drain));
    }
    return const M8Tick(changed: true);
  }

  // --- battery ----------------------------------------------------------------------------
  /// Battery [i] let go on a vehicle: the recycler takes it; the scrap cart is a
  /// slip and the battery comes back.
  DoMistake? dropBattery(int i, M8Veh v) {
    if (station != M8Station.battery || loaded[i]) return null;
    if (v == M8Veh.van) {
      loaded[i] = true;
      if (batteriesDone) _tag(M8OilContainLines.caughtBattery);
      return null;
    }
    return _slip(M8OilContainMistakes.cart);
  }

  // --- grass --------------------------------------------------------------------------------
  /// A rake pass at [p]: uncovers the offcuts it passes over. Returns how many
  /// came to light.
  int rake(Offset p, M8Geo geo) {
    if (station != M8Station.grass || clean) return 0;
    var n = 0;
    for (var i = 0; i < revealed.length; i++) {
      if (!revealed[i] && (geo.offcutAt(deal.offcuts[i].dx, deal.offcuts[i].dy) - p).distance <= m8RakeReach) {
        revealed[i] = true;
        n++;
      }
    }
    return n;
  }

  /// An offcut tapped into the bag.
  bool bag(int i) {
    if (!revealed[i] || bagged[i]) return false;
    bagged[i] = true;
    return true;
  }

  /// 'সাফ' with an offcut left (in the grass or not yet found) is a slip.
  DoMistake? sweep() {
    if (station != M8Station.grass || clean) return null;
    if (!bagged.every((x) => x)) return _slip(M8OilContainMistakes.offcut);
    clean = true;
    _tag(M8OilContainLines.caughtOffcut);
    return null;
  }

  /// Listened to the coworker: a slip (B1; nothing in 8.9 is deadly). The
  /// hose line also makes the spill bigger (one more handful).
  DoMistake listen(M8Push p) {
    if (p == M8Push.hose) {
      sheen = true;
      flicksNeeded++;
    }
    return _slip(M8OilContainMistakes.push(p));
  }
}

/// The reason topic of a step's ◆ (every one fits what was done).
M8Why m8StationWhy(M8Station s) => switch (s) {
      M8Station.oil => M8Why.route,
      M8Station.store => M8Why.sand,
      M8Station.battery => M8Why.battery,
      M8Station.grass => M8Why.offcut,
    };

/// The quick bonus: a little under a thorough play (~85 %, rounded to 5 s).
/// ms, ~1500 per human action:
///   oil: kit 2 drags + its reason ≈ 11000, the sheet 4 drags ≈ 7000, the valve
///     + its reason ≈ 9500, the oil runs ≈ 3500, the cap ≈ 4000, the drum + its
///     reason ≈ 10500 = 45500
///   store ≈ 16000, battery ≈ 13000, grass ≈ 35000 (two of the three ≈ 48000)
///   the guide's lead-ins ≈ 5000, the coworker once ≈ 9600
///   ≈ 108000; 85 % ≈ 92000 → 90 s.
const m8OilContainQuickMs = 90000;

/// Test hook: the play state of the page now on screen (tests only).
abstract final class M8OilContainProbe {
  @visibleForTesting
  static M8OilRun? run;
}

@immutable
class M8OilContainPack {
  const M8OilContainPack({required this.id, required this.titleBn, this.quickMs = m8OilContainQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8OilContainPack> m8OilContainPacks = {
  'do_8_9_b': M8OilContainPack(id: 'do_8_9_b', titleBn: M8OilContainLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M8OilContainPage extends StatefulWidget {
  const M8OilContainPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8OilContainPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8OilContainPage> createState() => _M8OilContainPageState();
}

class _M8OilContainPageState extends State<M8OilContainPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _OilRunPage(
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

class _OilRunPage extends ConsumerStatefulWidget {
  const _OilRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8OilContainPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_OilRunPage> createState() => _OilRunPageState();
}

/// What a pan on the scene is doing.
enum _Pan { none, kit, corner, cap, drum, flick, rake, battery }

class _OilRunPageState extends ConsumerState<_OilRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8OilRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  Timer? _tickTimer;
  final _stroke = ValueNotifier<List<Offset>>(const []);
  final List<List<Offset>> _raked = [];

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  int _steps = 0;
  int _nudgeN = 0;

  /// The act card (the consequence of listening): null = none, false = the oil
  /// poured on the field, true = the hose.
  bool? _act;
  Timer? _actTimer;

  final _nudge = TaskNudge();
  final _hints = IdleHintController();
  M8Geo? _geoNow;

  // A pan on the scene.
  _Pan _pan = _Pan.none;
  Offset _panStartAt = Offset.zero;
  Offset _panNow = Offset.zero;
  int _panIdx = -1;
  M8Kit? _kitKind;
  Offset? _kitAt;
  Offset? _drumAt;
  double _capPrev = 0;
  int? _batIdx;
  Offset? _batAt;
  final List<Offset> _pts = [];

  @override
  void initState() {
    super.initState();
    _run = M8OilRun(m8OilDeal(widget.rng));
    M8OilContainProbe.run = _run;
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => _clockTick());
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M8Deal get _deal => _run.deal;

  @override
  void dispose() {
    disposeCoworker();
    _tickTimer?.cancel();
    _actTimer?.cancel();
    _stroke.dispose();
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

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && _act == null && !_run.ended;

  String get _task => M8OilContainLines.ask(_run.stage);

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  Future<void> _start() async {
    _clock.start();
    _beginStation();
    unawaited(_sayChain([_task]));
  }

  /// A station begins: the store's puddle starts, and the coworker is due there
  /// when he is dealt to the store.
  void _beginStation() {
    if (_run.station == M8Station.store) {
      _run.storeLive = true;
      if (_deal.cwAtStore) scheduleCoworker();
    }
  }

  void _advance() {
    _hush();
    _pan = _Pan.none;
    _kitAt = null;
    _drumAt = null;
    _batAt = null;
    _run.advance();
    setState(() => _wake++);
    _beginStation();
    unawaited(_sayChain([M8OilContainLines.lead(_run.station), _task]));
  }

  // --- the clock ----------------------------------------------------------------------
  /// Playable time only: the oil and the puddle wait while a card, a deck, the
  /// table or the coworker is up. Redraws only while something moves.
  void _clockTick() {
    if (!mounted || !_canPlay) return;
    final geo = _geoNow;
    if (geo == null) return;
    switch (_run.station) {
      case M8Station.oil:
        if (!_run.valveOpen) return;
        if (_run.tickFill(0.1)) setState(() => _wake++);
        if (_run.full) {
          _tick('sounds/learn/ring_steel.ogg', 0.5);
          unawaited(_sayChain([_task]));
        }
      case M8Station.store:
        final t = _run.tickPuddle(0.1, geo);
        if (t.changed) setState(() => _wake++);
        final m = t.slip;
        if (m != null) {
          _hints.missTap();
          unawaited(_mistake(m, _toGlobal(geo.floorDrain.center)));
        }
      case M8Station.battery:
      case M8Station.grass:
        break;
    }
  }

  /// A rough global position of a design point (for the flying ◆ only).
  Offset _toGlobal(Offset p) {
    final size = MediaQuery.sizeOf(context);
    final k = size.width / 360;
    return Offset(p.dx * k, p.dy * k);
  }

  // --- reasons --------------------------------------------------------------------------
  void _ask(M8Why w) {
    putOnTable(15 + (_run.stageSlips == 0 ? 5 : 0));
    unawaited(askReason(
      deal: () => dealChoices(M8OilContainLines.whyRight[w]!, M8OilContainLines.myths, widget.rng),
      question: M8OilContainLines.whyQ[w]!,
      stillValid: () => !_ended,
    ));
  }

  // --- taps ---------------------------------------------------------------------------------
  void _tapAt(Offset p, M8Geo geo) {
    if (!_canPlay) return;
    switch (_run.station) {
      case M8Station.oil:
        if (!_run.valveWasOpen && geo.valveHit.contains(p)) {
          _valveTap(geo);
          return;
        }
      case M8Station.store:
        for (var i = 0; i < 4; i++) {
          if (geo.matSlot(i).contains(p)) {
            _matTap(_deal.mats[i], p);
            return;
          }
        }
      case M8Station.grass:
        for (var i = 0; i < _run.revealed.length; i++) {
          if (_run.revealed[i] && !_run.bagged[i] && geo.offcutHit(geo.offcutAt(_deal.offcuts[i].dx, _deal.offcuts[i].dy)).contains(p)) {
            if (_run.bag(i)) {
              _tick('sounds/intro/drop.ogg', 0.6);
              _stepDone();
            }
            return;
          }
        }
        if (geo.sweepBtn.contains(p)) {
          _sweepTap(p);
          return;
        }
      case M8Station.battery:
        break;
    }
    _hints.missTap();
  }

  void _valveTap(M8Geo geo) {
    final m = _run.tapValve(geo);
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, _toGlobal(geo.valvePt)));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/ring_steel.ogg', volume: 0.6);
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
    _ask(M8Why.sheet);
  }

  void _matTap(M8Mat m, Offset p) {
    final slip = _run.tapMat(m);
    if (slip != null) {
      setState(() => _wake++);
      unawaited(_mistake(slip, _toGlobal(p)));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.5);
    _stepDone();
  }

  void _sweepTap(Offset p) {
    final m = _run.sweep();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, _toGlobal(p)));
      return;
    }
    _tick('sounds/intro/drop.ogg', 0.6);
    setState(() => _wake++);
    _ask(M8Why.offcut);
  }

  // --- pans ---------------------------------------------------------------------------------
  void _panStart(Offset p, M8Geo geo) {
    _pan = _Pan.none;
    if (!_canPlay) return;
    _panStartAt = p;
    _panNow = p;
    switch (_run.station) {
      case M8Station.oil:
        for (final k in M8Kit.values) {
          final worn = k == M8Kit.gloves ? _run.gloves : _run.mask;
          if (!worn && geo.kitHit(geo.kitHome(k)).contains(p)) {
            _pan = _Pan.kit;
            setState(() {
              _kitKind = k;
              _kitAt = p;
            });
            return;
          }
        }
        if (!_run.valveWasOpen) {
          final cs = _run.corners ?? geo.sheetHome;
          var best = -1;
          var bestD = 30.0;
          for (var i = 0; i < 4; i++) {
            final d = (cs[i] - p).distance;
            if (d < bestD) {
              bestD = d;
              best = i;
            }
          }
          if (best >= 0) {
            _pan = _Pan.corner;
            _panIdx = best;
            return;
          }
        }
        if (_run.full && !_run.sealed && geo.capHit.contains(p)) {
          _pan = _Pan.cap;
          _capPrev = math.atan2(p.dy - geo.capCentre.dy, p.dx - geo.capCentre.dx);
          return;
        }
        if (_run.full && geo.drumHit.contains(p)) {
          if (_run.sealed && _run.stage == M8Stage.route && holdForCoworker()) return;
          _pan = _Pan.drum;
          setState(() => _drumAt = geo.drum.center);
          return;
        }
      case M8Station.store:
        _pan = _Pan.flick;
        return;
      case M8Station.battery:
        for (var i = 0; i < _run.loaded.length; i++) {
          if (!_run.loaded[i] && geo.batteryHit(geo.batteryHome(i)).contains(p)) {
            _pan = _Pan.battery;
            setState(() {
              _batIdx = i;
              _batAt = geo.batteryHome(i);
            });
            return;
          }
        }
      case M8Station.grass:
        if (geo.grass.inflate(10).contains(p)) {
          _pan = _Pan.rake;
          _pts
            ..clear()
            ..add(p);
          _stroke.value = List.of(_pts);
          _rakeAt(p, geo);
        }
    }
  }

  void _rakeAt(Offset p, M8Geo geo) {
    if (_run.rake(p, geo) > 0) {
      _tick('sounds/intro/click.ogg', 0.5);
      _stepDone();
    }
  }

  void _panUpdate(Offset p, M8Geo geo) {
    final prev = _panNow;
    _panNow = p;
    switch (_pan) {
      case _Pan.kit:
        setState(() => _kitAt = p);
      case _Pan.corner:
        if (_run.moveCorner(_panIdx, p, geo)) setState(() => _wake++);
      case _Pan.cap:
        final c = geo.capCentre;
        final dist = (p - c).distance;
        if (dist < 6 || dist > 110) break;
        final a = math.atan2(p.dy - c.dy, p.dx - c.dx);
        var d = a - _capPrev;
        while (d > math.pi) {
          d -= 2 * math.pi;
        }
        while (d < -math.pi) {
          d += 2 * math.pi;
        }
        _capPrev = a;
        if (_run.turnCap(d)) _capClicked();
      case _Pan.drum:
        if (!_run.sealed && (p - _panStartAt).distance > m8LooseMove) {
          // Moved on with the cap loose: it sloshes and leaks on the way.
          _pan = _Pan.none;
          setState(() => _drumAt = null);
          unawaited(_mistake(_run.moveLoose()!, _toGlobal(p)));
          break;
        }
        setState(() => _drumAt = p);
      case _Pan.battery:
        setState(() => _batAt = p);
      case _Pan.rake:
        if (_pts.isEmpty || (p - _pts.last).distance >= 5) {
          _pts.add(p);
          _stroke.value = List.of(_pts);
          // Every step between two points is checked, so a fast pass never skips.
          final steps = ((p - prev).distance / 10).ceil().clamp(1, 12);
          for (var i = 1; i <= steps; i++) {
            _rakeAt(Offset.lerp(prev, p, i / steps)!, geo);
          }
        }
      case _Pan.flick:
      case _Pan.none:
        break;
    }
  }

  void _panEnd(M8Geo geo, [DragEndDetails? details]) {
    final kind = _pan;
    _pan = _Pan.none;
    switch (kind) {
      case _Pan.kit:
        final k = _kitKind;
        final at = _kitAt;
        setState(() {
          _kitKind = null;
          _kitAt = null;
        });
        if (k != null && at != null && _canPlay && geo.wearZone.contains(at) && _run.wear(k)) {
          _tick('sounds/intro/click.ogg', 0.55);
          _stepDone();
          if (_run.kitOn && !_run.kitReasoned) {
            _run.kitReasoned = true;
            _ask(M8Why.kit);
          }
        } else {
          _hints.missTap();
        }
      case _Pan.corner:
        _stepDone();
      case _Pan.cap:
        break;
      case _Pan.drum:
        final at = _drumAt ?? _panNow;
        setState(() => _drumAt = null);
        if (_canPlay && _run.sealed && !_run.routed) {
          final i = geo.destAt(at);
          if (i < 0) {
            _hints.missTap();
          } else {
            unawaited(_dropDrum(_deal.dests[i], at));
          }
        }
      case _Pan.battery:
        final i = _batIdx;
        final at = _batAt ?? _panNow;
        setState(() {
          _batIdx = null;
          _batAt = null;
        });
        if (i != null && _canPlay) {
          final s = geo.vehicleAt(at);
          if (s < 0) {
            _hints.missTap();
          } else {
            _batteryLet(i, s == _deal.vanSlot ? M8Veh.van : M8Veh.cart, at);
          }
        }
      case _Pan.rake:
        if (_pts.length > 1) {
          _raked.add(List.of(_pts));
          var total = _raked.fold<int>(0, (a, s) => a + s.length);
          while (total > 700 && _raked.length > 1) {
            total -= _raked.removeAt(0).length;
          }
        }
        _pts.clear();
        _stroke.value = const [];
        setState(() => _wake++);
      case _Pan.flick:
        final scale = MediaQuery.sizeOf(context).width / 360;
        final v = (details?.velocity.pixelsPerSecond ?? Offset.zero) / scale;
        if (_canPlay) _flickEnd(_panNow, v, geo);
      case _Pan.none:
        break;
    }
  }

  void _capClicked() {
    _pan = _Pan.none;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/ring_steel.ogg', volume: 0.65);
    _cue('sounds/intro/click.ogg', volume: 0.6);
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
    if (!_deal.cwAtStore) scheduleCoworker();
  }

  Future<void> _dropDrum(M8Dest d, Offset at) async {
    final m = _run.routeTo(d);
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, _toGlobal(at)));
      return;
    }
    _tick('sounds/intro/drop.ogg', 0.6);
    setState(() => _wake++);
    _ask(M8Why.route);
  }

  void _batteryLet(int i, M8Veh v, Offset at) {
    final m = _run.dropBattery(i, v);
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, _toGlobal(at)));
      return;
    }
    _tick('sounds/intro/drop.ogg', 0.6);
    _stepDone();
    if (_run.batteriesDone) _ask(M8Why.battery);
  }

  /// A flick: material in hand, thrown at the puddle fast enough. His control
  /// (the first handful) waits for him.
  void _flickEnd(Offset last, Offset v, M8Geo geo) {
    if (_run.selected == null || v.distance < m8FlickSpeed) {
      _hints.missTap();
      return;
    }
    final zone = geo.flickZone(_run.puddleS);
    if (!zone.contains(last + v * 0.12) && !zone.contains(last)) {
      _hints.missTap();
      return;
    }
    if (holdForCoworker()) return;
    final r = _run.flick();
    if (r.slip != null) {
      setState(() => _wake++);
      unawaited(_mistake(r.slip!, _toGlobal(last)));
      return;
    }
    if (!r.landed) return;
    HapticFeedback.lightImpact();
    _cue('sounds/intro/drop.ogg', volume: 0.5);
    _stepDone();
    if (r.covered) _ask(M8Why.sand);
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
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
    _run.tablePaid();
    setState(() => _wake++);
    if (_run.stationDone) {
      if (_run.lastStation) {
        _run.finished = true;
        _maybeFinish();
      } else {
        _advance();
      }
      return;
    }
    unawaited(_sayChain([_task]));
  }

  void _maybeFinish() {
    if (!_run.finished || _ended) return;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 800), () {
      if (mounted && !_ended) unawaited(_finish());
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M8OilContainLines.coworker(_deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.ended) return null;
    if (_deal.cwAtStore) {
      if (_run.station != M8Station.store) return _run.ix < _deal.order.indexOf(M8Station.store) ? false : null;
      if (_run.flicksDone > 0 || _run.covered) return null;
    } else {
      if (_run.station != M8Station.oil) return _run.ix < _deal.order.indexOf(M8Station.oil) ? false : null;
      if (_run.routed) return null;
      if (!_run.sealed) return false;
    }
    if (_intro || _card != null || tableBusy || _act != null || _pan != _Pan.none) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _deal.push;
    if (!held) {
      final m = _run.listen(p);
      // The act's picture (what the myth leads to), then the card.
      setState(() {
        _act = p == M8Push.hose;
        _wake++;
      });
      _actTimer?.cancel();
      final done = Completer<void>();
      _actTimer = Timer(Duration(milliseconds: _quiet ? 500 : 1800), done.complete);
      await done.future;
      if (!mounted) return;
      setState(() => _act = null);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M8OilContainLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8OilContainLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M8OilContainLines.tapWhy[_nudgeN++ % M8OilContainLines.tapWhy.length]
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
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8oil/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The play goes on from where it was (the drum is back, the sheet is
    // still down, the spill is still there).
    _hush();
    setState(() {
      _card = null;
      _wake++;
    });
    unawaited(_sayChain([_task]));
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
    await _say(!_run.passed ? M8OilContainLines.fail : (_quickBonus ? M8OilContainLines.quick : M8OilContainLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leave() async {
    if (_passed) {
      _popOnce(true);
      return;
    }
    final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: true);
    if (leave == true) _popOnce(false);
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null || coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_pan != _Pan.none) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M8Geo _geoFor(SceneMetrics m) => M8Geo.forScene(
        m.height,
        m.inset,
        flip: switch (_run.station) {
          M8Station.oil => _deal.valveFlip,
          M8Station.store => _deal.storeFlip,
          _ => false,
        },
        fx: _deal.fx,
        fw: _deal.fw,
      );

  M8Rig get _rig {
    final r = _run;
    return M8Rig(
      station: r.station,
      dusk: _deal.dusk,
      glovesOn: r.gloves,
      maskOn: r.mask,
      kitDrag: _kitKind,
      kitDragAt: _kitAt,
      corners: r.corners,
      stain: r.stain,
      valveOpen: r.valveOpen,
      fill: r.fill,
      sealed: r.sealed,
      drumAt: _drumAt,
      destsUp: r.sealed && !r.routed,
      dests: _deal.dests,
      routed: r.routed,
      mats: _deal.mats,
      selected: r.selected,
      puddleS: r.puddleS,
      flicks: r.flicksDone,
      flicksNeeded: r.flicksNeeded,
      atDrain: r.atDrain,
      sheen: r.sheen,
      covered: r.covered,
      vanSlot: _deal.vanSlot,
      batteries: _deal.batteries,
      loaded: r.loaded,
      batDrag: _batIdx,
      batDragAt: _batAt,
      offcuts: [for (final o in _deal.offcuts) _geoNow?.offcutAt(o.dx, o.dy) ?? Offset.zero],
      revealed: r.revealed,
      bagged: r.bagged,
      raked: _raked,
      cow: r.cow,
      clean: r.clean,
    );
  }

  /// The gesture hand: how to touch, never what. Yard untouched: a sweep over
  /// the kit, the valve and the folded sheet alike; started, a nudge straight up
  /// on a random unworn kit item; the kit on, an outward nudge on a random
  /// corner; the sheet out, a sweep over the valve and the corners. Cap: a short
  /// drag along the rim (the only way on). Drum: a nudge straight up (never
  /// toward a place). Store: a sweep over the four wall things; with one in
  /// hand a generic flick. Batteries: an upward nudge from a random one that is
  /// left. Grass: a swipe across a random strip; once something is raked up a
  /// sweep over the grass and 'সাফ'.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final r = _run;
    final ix = _deal.hintIx;
    switch (r.stage) {
      case M8Stage.prep:
        if (!r.touched) return HintSpec.sweep(geo.oilSweep(), space: HintSpace.scene);
        if (!r.kitOn) {
          final left = [if (!r.gloves) M8Kit.gloves, if (!r.mask) M8Kit.mask];
          return HintSpec.drag(geo.kitHome(left[ix % left.length]), toward: const Offset(0, -1), travel: 36, space: HintSpace.scene);
        }
        if (!r.cornersMoved) {
          final c = geo.sheetHome[ix % 4];
          return HintSpec.drag(c, toward: Offset(geo.flip ? -1 : 1, 0), travel: 44, space: HintSpace.scene);
        }
        return HintSpec.sweep([geo.valveHit, for (final c in r.corners ?? geo.sheetHome) Rect.fromCenter(center: c, width: 40, height: 40)], space: HintSpace.scene);
      case M8Stage.fill:
        return null;
      case M8Stage.seal:
        // A short arc along the rim: the finger starts at the rim and goes round.
        final c = geo.capCentre;
        return HintSpec.drag(c + const Offset(20, 0), toward: const Offset(0, 1), travel: 28, space: HintSpace.scene);
      case M8Stage.route:
        return HintSpec.drag(geo.drum.center, toward: const Offset(0, -1), travel: 36, space: HintSpace.scene);
      case M8Stage.store:
        if (r.selected == null) return HintSpec.sweep([for (var i = 0; i < 4; i++) geo.matSlot(i)], space: HintSpace.scene);
        return HintSpec.swipe(geo.storeTrainee.center + const Offset(0, 24), toward: const Offset(0, -1), travel: 90, space: HintSpace.scene);
      case M8Stage.battery:
        final left = [for (var i = 0; i < r.loaded.length; i++) if (!r.loaded[i]) i];
        if (left.isEmpty) return null;
        return HintSpec.drag(geo.batteryHome(left[ix % left.length]), toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
      case M8Stage.grass:
        if (!r.anyRevealed) return HintSpec.swipe(geo.stripStart(ix), toward: const Offset(1, 0), travel: 110, space: HintSpace.scene);
        return HintSpec.sweep([geo.grass, geo.sweepBtn], space: HintSpace.scene);
      case M8Stage.done:
        return null;
    }
  }

  static const _bareLook = LinemanLook(
    helmet: Color(0xFFFFD34E),
    shirt: Color(0xFF1F5F8F),
    vest: Color(0xFFFF851B),
    pants: Color(0xFF26303D),
    skin: Color(0xFFA86E48),
  );

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = _geoFor(m);
    final quiet = _quiet;
    final st = _run.station;
    final tr = geo.trainee(st);
    return [
      Positioned.fill(
        key: ValueKey('world-${st.name}'),
        child: Stack(
          children: [
            Positioned.fill(
              key: const ValueKey('yard'),
              child: RepaintBoundary(child: CustomPaint(painter: M8Painter(geo: geo, rig: _rig, stroke: _stroke))),
            ),
            Positioned.fromRect(
              key: const ValueKey('trainee'),
              rect: tr,
              child: LinemanFigure(
                look: _run.gloves || st != M8Station.oil ? LinemanLook.trainee : _bareLook,
                mode: _mode,
                wake: _wake,
                quiet: quiet,
              ),
            ),
            if (_run.mask)
              Positioned(
                key: const ValueKey('mask'),
                left: tr.left + 12,
                top: tr.top + 17,
                width: 20,
                height: 10,
                child: const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFEFF3F6), borderRadius: BorderRadius.all(Radius.circular(5)), border: Border.fromBorderSide(BorderSide(color: Color(0xFF9AA7B0), width: 1))))),
              ),
            ..._plates(geo, st),
          ],
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M8OilContainLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A pan is judged by where the finger went down (a kit item, a
            // corner, the cap, the drum, a battery), not where it passed the slop.
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapAt(d.localPosition, geo),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, geo),
            onPanEnd: (d) => _panEnd(geo, d),
            onPanCancel: () => _panEnd(geo),
          ),
        ),
      ),
      if (_act != null)
        Positioned.fromRect(
          key: const ValueKey('act'),
          rect: M8Geo.actCard,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 360),
              builder: (_, v, child) => Opacity(opacity: v, child: child),
              child: M8ActCard(hose: _act!),
            ),
          ),
        ),
    ];
  }

  /// The plates a real worker would read: the disposal truck once the drum is
  /// sealed, the recycler's van, the 'সাফ' button.
  List<Widget> _plates(M8Geo geo, M8Station st) {
    Widget plate(Key key, Rect rect, String text, double size, Color bg, Color fg) => Positioned.fromRect(
          key: key,
          rect: rect,
          child: IgnorePointer(
            child: Semantics(
              label: text,
              excludeSemantics: true,
              child: DecoratedBox(
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: size, fontWeight: FontWeight.w800, color: fg)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    switch (st) {
      case M8Station.oil:
        if (!_run.sealed || _run.routed) return const [];
        final i = _deal.dests.indexOf(M8Dest.truck);
        final s = geo.destSlot(i);
        return [plate(const ValueKey('plate-truck'), Rect.fromLTWH(s.left + 6, s.top + 8, 46, 20), M8OilContainLines.truckPlate, 8, const Color(0xFFF2F2F0), const Color(0xFF1E5E3A))];
      case M8Station.battery:
        final v = geo.vehicle(_deal.vanSlot);
        return [plate(const ValueKey('plate-van'), Rect.fromLTWH(v.left + 8, v.top + 10, 84, 34), M8OilContainLines.vanPlate, 11, const Color(0xFFF2F2F0), const Color(0xFF1E5E3A))];
      case M8Station.grass:
        return [plate(const ValueKey('plate-sweep'), geo.sweepBtn, M8OilContainLines.sweepLabel, 18, const Color(0xFF2E7D4F), Colors.white)];
      case M8Station.store:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && _act == null && !_run.ended;
    final stage = _run.stage;
    final order = _deal.order;
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
              labels: [for (final s in order) M8OilContainLines.stationNames[s]!],
              done: {
                for (var i = 0; i < order.length; i++)
                  if (i < _run.ix || (i == _run.ix && _run.stationDone && (_run.lastStation ? _run.finished : false))) i,
              },
              current: _run.finished ? null : _run.ix,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _pan == _Pan.none && stage != M8Stage.fill && stage != M8Stage.done,
            hintKey: '${_run.ix}/${stage.name}/$_steps/${_run.gloves}/${_run.mask}/${_run.cornersMoved}/${_run.selected?.name}/${_run.flicksDone}/${_run.stageSlips}',
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$strikes'),
                  mistake: _card!,
                  tone: MistakeTone.slip,
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
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M8OilContainLines.intro,
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
