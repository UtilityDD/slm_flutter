import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'm5_searchlight_patrol_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm5_searchlight_patrol_world.dart' show M5SlDevice, M5SlJacket, M5SlSeat, M5SlWho, M5SlSide, M5SlFault, M5SlPole, M5SlGeo;

// Lesson 5.7 "রাতের বেলা ফল্ট খোঁজার কৌশল", কাজ 1 "সার্চলাইটের টহল"
// (pack do_5_7_a, engineType m5_searchlight_patrol). A feeder tripped at
// night; the trainee gets ready at the depot and patrols the line by van.
// Verb: steer the searchlight, call the speed.
//
//  ক ডিপো: hold each device (torch, headlamp, phone) to read its charge;
//    drag a low one to the charging dock (it comes back full); tap a jacket
//    peg; take the docket from the board (control informed); drag both
//    people into the van's seats (driver + searchlight hatch); রওনা.
//    One depot reason (dealt from what was done right).
//  খ পথ: the road forks — 'চেনা পাকা রাস্তা' or 'অচেনা মাঠের পথ' (dealt side).
//  গ টহল: a side-scrolling road beside the line, 8 poles on both sides. The
//    speed lever থামো · ধীরে · জোরে; tap / drag the sky to steer the roof
//    searchlight; a pole top shows its detail only when the spot rests on it
//    at a slow speed (or stopped); long-press inside the spot to mark it.
//    A marked fault → ◆ → "কেন এই পোলে চিহ্ন দিলেন?". The van halts as pole 2
//    comes level and the careless coworker says the lesson's myth 2; the van
//    does not move again until he is answered (holdForCoworker). At the end:
//    "কেন গাড়ি ধীরে চালাতে বললেন?" if the van never went fast.
//  ঘ রিপোর্ট: the trainee steps out at the last mark; the depot choices bite
//    (a truck rushes past a dark jacket; a low torch/headlamp dies); hold
//    the binoculars to read the pole plate, tap the phone to send it (a low
//    phone dies — the partner's phone sends it).
//
// The lesson's rules, and only those (lesson 5.7): keep the van slow at night,
// two people — one drives, one watches both sides; a familiar, safe road; a
// bright reflective jacket at the roadside; torch, headlamp and phone fully
// charged before going; never alone; a searchlight (not the headlights) to
// see pole tops; binoculars; broken insulators and branches are hard to see at
// night. Module rulings (docs/module_specs/module5_rulings.md): M5-3 — inform
// control and take the docket before the patrol (a slip); hands on or a climb
// of the line need a PTW. From lesson 5.1 (not 5.7): a tripped line is not
// dead — the control room or the recloser can charge it at any moment.
//
// Deadly: climbing the pole at the step-out to look closer (R1: a climb of a
// tripped line before a written PTW). Slips (R6, R27–R31): no docket, alone,
// the field track, a fault passing unmarked (at speed or not), a mark on a
// sound pole, listening to the coworker (headlights only → the searchlight
// is off for the next two poles), a low battery left unswapped, a dark
// jacket (the last two show at the step-out). Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md). Gesture hints (how,
// never what): a press-hold in turn over every device, a short drag nudge on
// a device read low, a sweep over the pegs, docket, people and রওনা; a sweep
// over both road signs; a swipe across the lever's stops; a sweep across the
// sky band on both sides (never stopping on a pole); a hold at the spot's
// centre once it rests on any pole; a sweep over the step-out tools. Voice:
// the guide by device TTS; the coworker's push is new (to be recorded — until
// then silent with his caption held); his exit line is his existing clip.

// ============================================================================
// Content
// ============================================================================

/// The play's stations.
enum M5SlStation { depot, fork, patrol, stepOut }

/// The speed lever.
enum M5SlSpeed { stop, slow, fast }

/// The step-out tools.
enum M5SlTool { binoculars, phone, climb }

/// What a reason card asks about.
enum M5SlWhy { battery, jacket, two, slow, insulator, branch }

/// The coworker comes as this pole comes level with the van (pole 2).
const m5SlCoworkerPole = 1;

/// After listening to him the searchlight is off for this many poles.
const m5SlDarkPoles = 2;

/// Below this the charge is low (the dealt low one is 8–22 %, the rest 84–100 %).
const m5SlLowCharge = 50;

abstract final class M5SearchlightLines {
  static const title = 'সার্চলাইটের টহল';
  static const intro = 'রাতে ফিডার ট্রিপ করেছে! গাড়ি নিয়ে লাইন ধরে ফল্ট খুঁজুন।';
  static const stations = ['ডিপো', 'পথ', 'টহল', 'রিপোর্ট'];

  // The guide's task now (tap him: the same task, a different way).
  static const askDepot = 'বেরোনোর আগে নিজেকে আর সরঞ্জাম তৈরি করুন।';
  static const askFork = 'কোন পথে টহলে যাবেন?';
  static const askPatrol = 'লাইন ধরে চলুন, প্রতিটি পোলের মাথা দেখুন।';
  static const askReport = 'নেমে পোলের নম্বর কন্ট্রোলে জানান।';
  static const tasks = [askDepot, askFork, askPatrol, askReport];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'রাতের টহল';
  static const go = 'রওনা';
  static const stop = 'থামো';
  static const slow = 'ধীরে';
  static const fast = 'জোরে';
  static const binoculars = 'বাইনোকুলার';
  static const phone = 'ফোন';
  static const climb = 'উঠে দেখুন';
  static const road = 'চেনা পাকা রাস্তা';
  static const field = 'অচেনা মাঠের পথ';
  static const control = 'কন্ট্রোল রুম';
  static const sent = 'পাঠানো হলো';

  static String speedLabel(M5SlSpeed s) => switch (s) {
        M5SlSpeed.stop => stop,
        M5SlSpeed.slow => slow,
        M5SlSpeed.fast => fast,
      };
  static String toolLabel(M5SlTool t) => switch (t) {
        M5SlTool.binoculars => binoculars,
        M5SlTool.phone => phone,
        M5SlTool.climb => climb,
      };
  static String deviceLabel(M5SlDevice d) => switch (d) {
        M5SlDevice.torch => 'টর্চ',
        M5SlDevice.headlamp => 'হেডল্যাম্প',
        M5SlDevice.phone => 'ফোন',
      };
  static String jacketLabel(M5SlJacket j) => j == M5SlJacket.dark ? 'গাঢ় জ্যাকেট' : 'প্রতিফলক জ্যাকেট';
  static String whoLabel(M5SlWho w) => w == M5SlWho.trainee ? 'আপনি' : 'সঙ্গী';
  static String seatLabel(M5SlSeat s) => s == M5SlSeat.driver ? 'চালকের আসন' : 'সার্চলাইটের জায়গা';
  static String docket(int feeder, int no) => enDigits('ফিডার $feeder · ডকেট $no');
  static String plate(int n) => enDigits('P-$n');
  static String charge(int pct) => enDigits('$pct%');
  static String report(int feeder, int plate) => enDigits('ফিডার $feeder · পোল P-$plate');

  // The reasons (lesson 5.7: section 4 and the pro tips). The wrong ones are
  // the lesson's myths and field excuses. 40–48 letters.
  static const whyQ = <M5SlWhy, String>{
    M5SlWhy.battery: 'কেন বেরোনোর আগে ব্যাটারি দেখলেন?',
    M5SlWhy.jacket: 'কেন প্রতিফলক জ্যাকেট পরলেন?',
    M5SlWhy.two: 'কেন দুজন একসাথে গেলেন?',
    M5SlWhy.slow: 'কেন গাড়ি ধীরে চালাতে বললেন?',
    M5SlWhy.insulator: 'কেন এই পোলে চিহ্ন দিলেন?',
    M5SlWhy.branch: 'কেন এই পোলে চিহ্ন দিলেন?',
  };
  static const whyRight = <M5SlWhy, List<String>>{
    M5SlWhy.battery: ['মাঝপথে আলো নিভলে অন্ধকারে কিছুই দেখা যাবে না', 'টর্চ, হেডল্যাম্প, ফোন — রাতে সবই পুরো চার্জ চাই'],
    M5SlWhy.jacket: ['প্রতিফলক জ্যাকেটে চালকরা দূর থেকে আমাকে দেখেন', 'রাস্তার পাশে রাতে চালকের চোখে পড়া দরকার'],
    M5SlWhy.two: ['একজন গাড়ি চালাবেন, অন্যজন দুই পাশের লাইন দেখবেন', 'রাতে একা নয় — সঙ্গী মানে সুরক্ষা আর সাহায্য'],
    M5SlWhy.slow: ['ধীরে চললে পোলের মাথার খুঁত চোখ এড়ায় না', 'রাতের টহল ধৈর্য আর পদ্ধতির কাজ, গতির নয়'],
    M5SlWhy.insulator: ['ইনসুলেটরটা ভাঙা — ফল্ট এখানেই হয়ে থাকতে পারে', 'ভাঙা ইনসুলেটর দেখেছি, তাই এই পোলটা চিহ্নিত'],
    M5SlWhy.branch: ['তারের ওপর গাছের ডাল — এখানেই ফল্ট হতে পারে', 'লাইনে ডাল পড়ে আছে দেখেছি, তাই পোলটা চিহ্নিত'],
  };
  // Wrong reasons on the question's own topic (so the right card cannot be
  // found by its topic alone): the lesson's myths (রাতে কিছু দেখা যায় না;
  // হেডলাইটই যথেষ্ট) and field excuses.
  static const batteryMyths = [
    'আধা চার্জেই সারা রাত চলে, দেখাটা শুধু অভ্যাস',
    'চার্জ কম থাকলেও গাড়ির হেডলাইটে কাজ চলে যায়',
    'ভরা চার্জ থাকলে টহল তাড়াতাড়ি শেষ হয়ে যায়',
    'অন্ধকারে চোখ সয়ে যায়, আলো না থাকলেও চলে',
    'সুপারভাইজার বলেছেন বলে দেখলাম, কারণ জানি না',
    'ব্যাটারির হিসাব খাতায় তুলতে হয়, তাই দেখলাম',
  ];
  static const jacketMyths = [
    'রাতে রাস্তায় কেউ থাকে না, তাই ভয়ের কিছু নেই',
    'জ্যাকেট পরলে রাতের ঠান্ডা লাগে না, তাই পরলাম',
    'গাঢ় জ্যাকেটেও চালকরা হেডলাইটে ঠিক দেখতে পান',
    'প্রতিফলক জ্যাকেট শুধু অফিসের নিয়ম রক্ষার জন্য',
    'জ্যাকেটের ঝিলিকে পোলের মাথা ভালো দেখা যায়',
    'সুপারভাইজার বলেছেন বলে পরলাম, কারণ জানি না',
  ];
  static const twoMyths = [
    'একা গেলেও চলত, দুজন যাওয়া শুধু নিয়মের খাতিরে',
    'দুজন থাকলে গল্প করতে করতে রাতটা কেটে যায়',
    'দুজনে গেলে একজন গাড়িতে ঘুমিয়ে নিতে পারেন',
    'একজন পোলে উঠবেন, অন্যজন নিচে পাহারা দেবেন',
    'দুজনে মিলে তাড়াতাড়ি সেরে ফেরা যায়, তাই গেলাম',
    'চালক একাই গাড়ি চালিয়ে লাইনও দেখে নিতে পারেন',
  ];
  static const slowMyths = [
    'রাতে কিছু দেখা যায় না, সকালেই খোঁজা ভালো',
    'ধীরে চালালে তেল বাঁচে, তাই ধীরে চালাতে বললাম',
    'ধীরে চললে গাড়ির হেডলাইটেই পোল দেখা যায়',
    'রাস্তা খারাপ বলে ধীরে, লাইনের সাথে সম্পর্ক নেই',
    'ধীরে চললে রাত কাটবে, সকালে আলোয় খোঁজা যাবে',
    'সুপারভাইজার বলেছেন বলে বললাম, কারণ জানি না',
  ];

  /// A mark's wrong reasons: guesses that never looked at the pole top.
  static const pinMyths = [
    'রাতে সব পোলেই চিহ্ন দিয়ে রাখি, পরে দেখা যাবে',
    'হেডলাইটের আলোয় মনে হলো ওপরে কিছু একটা আছে',
    'এত দূর এসেছি, একটা পোলে তো চিহ্ন দিতেই হবে',
    'পোলটা অন্যগুলোর চেয়ে পুরনো লাগল, তাই চিহ্ন',
    'আন্দাজে দিলাম, ভুল হলে সকালে ঠিক করা যাবে',
  ];

  /// The other fault kind (a mark's reason always deals one of these, so it
  /// checks which fault the player actually saw at the pole top).
  static const sawBranch = ['লাইনে গাছের ডাল ঝুলছে, তাই এখানে চিহ্ন দিলাম', 'তারের ওপর গাছের ডাল দেখেছি, তাই পোলটা চিহ্নিত'];
  static const sawInsulator = ['ইনসুলেটর ফেটে গেছে দেখেছি, তাই চিহ্ন দিলাম', 'ইনসুলেটর ভেঙে ঝুলছে, তাই এখানে চিহ্ন দিলাম'];

  /// The wrong reasons for [w] (a mark: the other fault kind + guesses).
  static List<String> wrongFor(M5SlWhy w) => switch (w) {
        M5SlWhy.battery => batteryMyths,
        M5SlWhy.jacket => jacketMyths,
        M5SlWhy.two => twoMyths,
        M5SlWhy.slow => slowMyths,
        M5SlWhy.insulator => [...sawBranch, ...pinMyths],
        M5SlWhy.branch => [...sawInsulator, ...pinMyths],
      };

  /// The other fault kind's lines for a mark's reason (empty for the rest).
  static List<String> crossFor(M5SlWhy w) => switch (w) {
        M5SlWhy.insulator => sawBranch,
        M5SlWhy.branch => sawInsulator,
        _ => const [],
      };

  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];
  static List<String> get allWhyWrong => {for (final w in M5SlWhy.values) ...wrongFor(w)}.toList();

  /// The careless coworker: lesson 5.7 myth 2, word for word.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'আমার গাড়ির হেডলাইটই যথেষ্ট, আলাদা টর্চের দরকার নেই।',
    exitLine: coworkerExit,
    right: ['না, হেডলাইট শুধু রাস্তা দেখায়, সার্চলাইট চাই', 'না, পোলের মাথা দেখতে সার্চলাইট জ্বালিয়ে রাখব', 'না, সার্চলাইট ছাড়া পোলের খুঁত দেখা যাবে না'],
    wrong: [
      'ঠিক, হেডলাইটেই চলবে, সার্চলাইট নিভিয়ে দিই',
      'আচ্ছা, সার্চলাইট বন্ধ রাখি, ব্যাটারি বাঁচুক',
      'হ্যাঁ, হেডলাইটের আলোতেই পোলগুলো দেখে নেব',
      'ঠিক আছে, সার্চলাইটের ঝামেলা আর না করি',
      'হ্যাঁ, রাস্তা দেখা গেলেই লাইনও দেখা যাবে',
    ],
    asks: ['ও বলছে হেডলাইটই যথেষ্ট। কী করবেন?', 'সার্চলাইট নিভিয়ে দেবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );

  /// His lines with no recorded clip yet (the director records them with
  /// tool/rival_clip.py); until then he is silent and his caption is held.
  static const rivalMissing = [
    'আমার গাড়ির হেডলাইটই যথেষ্ট, আলাদা টর্চের দরকার নেই।',
  ];

  static const callHeld = 'ঠিক! হেডলাইট শুধু রাস্তা দেখায় — পোলের মাথা দেখতে সার্চলাইট লাগবে।';
  static const allSet = 'নিরাপদ প্রস্তুতি, ধীর গতি, তীক্ষ্ণ চোখ — রাতের ফল্ট ধরা পড়ল।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে পুরো প্রস্তুতি, তারপর ধীরে চালিয়ে প্রতিটি পোল দেখুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const roadRight = 'ঠিক! চেনা, নিরাপদ পথেই টহল।';
  static const noMark = 'কোনো পোলে চিহ্ন নেই — কন্ট্রোলে জানানোর মতো ফল্ট পাওয়া গেল না।';

  // "আজ যা ধরলেন".
  static const caughtBattery = 'বেরোনোর আগে সব ব্যাটারি দেখেছেন';
  static const caughtJacket = 'প্রতিফলক জ্যাকেট পরেছেন';
  static const caughtTwo = 'দুজনে টহল — একজন চালান, একজন দেখেন';
  static const caughtDocket = 'কন্ট্রোলকে জানিয়ে ডকেট নিয়েছেন';
  static const caughtRoad = 'চেনা পাকা রাস্তা বেছেছেন';
  static const caughtFault = 'খুঁতওয়ালা পোলে চিহ্ন দিয়েছেন';
  static const caughtSlow = 'ধীরে চালিয়ে পোলের মাথা দেখেছেন';
  static const caughtCall = 'হেডলাইটের কথায় “না” বলেছেন';
  static const caughtReport = 'পোলের নম্বর কন্ট্রোলে জানিয়েছেন';
}

abstract final class M5SearchlightMistakes {
  static const _dir = 'assets/game/art/m5_searchlight_patrol';
  static const _k = '5.7/m5_searchlight_patrol';

  // Lesson point indexes (lesson 5.7, one section): 0 challenges (visibility),
  // 1 gear (searchlight, binoculars), 2 spark/corona, 3 patrol technique (the
  // pro tips — jacket, battery, never alone — follow it in the reader).
  static const noDocket = DoMistake(
    key: '$_k/no-docket',
    textBn: 'টহলের আগে কন্ট্রোল রুমকে জানিয়ে ফিল্ড মেমো/ডকেট নিন; লাইনে হাত দেওয়া বা ওঠার আগে পারমিট (PTW) বাধ্যতামূলক।',
    art: '$_dir/no_docket.svg',
  );
  static const alone = DoMistake(
    key: '$_k/alone',
    textBn: 'রাতে একা টহল নয় — একজন গাড়ি চালাবেন, অন্যজন দুই পাশের লাইন দেখবেন।',
    art: '$_dir/alone.svg',
    lessonPoint: 3,
  );
  static const fieldTrack = DoMistake(
    key: '$_k/field-track',
    textBn: 'সম্ভব হলে চেনা ও নিরাপদ রাস্তা দিয়ে টহল দিন — রাতে অচেনা পথে গর্তে পড়ার ঝুঁকি বাড়ে।',
    art: '$_dir/field_track.svg',
    lessonPoint: 3,
  );
  static const lowBattery = DoMistake(
    key: '$_k/low-battery',
    textBn: 'বেরোনোর আগে টর্চ, হেডল্যাম্প আর ফোনের চার্জ দেখে নিন — পুরো চার্জ না থাকলে বদলে নিন।',
    art: '$_dir/low_battery.svg',
    lessonPoint: 3,
  );
  static const darkJacket = DoMistake(
    key: '$_k/dark-jacket',
    textBn: 'রাতে রাস্তার পাশে উজ্জ্বল প্রতিফলক জ্যাকেট পরুন, যাতে চালকরা দূর থেকে আপনাকে দেখতে পান।',
    art: '$_dir/dark_jacket.svg',
    lessonPoint: 3,
  );
  static const fastMissed = DoMistake(
    key: '$_k/fast-missed',
    textBn: 'রাতে গাড়ি ধীরে চালান — জোরে চললে পোলের মাথার খুঁত চোখ এড়িয়ে যায়।',
    art: '$_dir/fast_missed.svg',
    lessonPoint: 3,
  );
  static const missed = DoMistake(
    key: '$_k/missed',
    textBn: 'খুঁতওয়ালা পোল পার হয়ে গেল! প্রতিটি পোলের মাথায় সার্চলাইট ফেলে ভালো করে দেখুন।',
    art: '$_dir/missed.svg',
    lessonPoint: 0,
  );
  static const soundPin = DoMistake(
    key: '$_k/sound-pin',
    textBn: 'এই পোলটা তো ঠিক আছে। আলো ফেলে ভালো করে দেখে তবেই চিহ্ন দিন।',
    art: '$_dir/sound_pin.svg',
    lessonPoint: 0,
  );
  static const headlights = DoMistake(
    key: '$_k/headlights',
    textBn: 'হেডলাইট শুধু রাস্তা দেখায় — পোলের মাথা আর লাইনের কাঠামো দেখতে সার্চলাইট লাগে।',
    art: '$_dir/headlights.svg',
    lessonPoint: 1,
  );

  // Lesson 5.1 (not 5.7's text) and ruling M5-3: no lesson point here.
  static const climb = DoMistake(
    key: '$_k/climb',
    textBn: 'ট্রিপ করা লাইন ডেড নয় — কন্ট্রোল রুম বা অটো-রিক্লোজার যেকোনো মুহূর্তে চালু করতে পারে। পারমিট (PTW) ছাড়া পোলে ওঠা নয়।',
    art: '$_dir/climb.svg',
    deadly: true,
  );

  static const all = [noDocket, alone, fieldTrack, lowBattery, darkJacket, fastMissed, missed, soundPin, headlights, climb];
}

@immutable
class M5SlDeal {
  const M5SlDeal({
    required this.lowDevice,
    required this.charge,
    required this.pegs,
    required this.fieldLeft,
    required this.poles,
    required this.feeder,
    required this.docketNo,
    required this.depotWhy,
    required this.tools,
  });

  /// The device dealt low (none in about a quarter of plays).
  final M5SlDevice? lowDevice;

  /// Each device's charge (%).
  final Map<M5SlDevice, int> charge;

  /// The jackets on the pegs, left to right.
  final List<M5SlJacket> pegs;

  /// The field track branches off to the left.
  final bool fieldLeft;

  /// The patrolled stretch (8 poles, both sides; 1–2 faults, never pole 2).
  final List<M5SlPole> poles;

  final int feeder;
  final int docketNo;

  /// The depot reason's preference (the first one done right is asked).
  final List<M5SlWhy> depotWhy;

  /// The step-out tool row, never in a working order.
  final List<M5SlTool> tools;

  List<int> get faults => [for (var i = 0; i < poles.length; i++) if (poles[i].fault != M5SlFault.none) i];
}

/// The cards for the [why] reason: one right, two wrong from its own topic.
/// A mark's reason always deals the other fault kind as one of the wrong
/// cards, so the player must know which fault was at the pole top.
List<ChoiceOption> m5SlReasonDeal(M5SlWhy why, math.Random rng) {
  final right = M5SearchlightLines.whyRight[why]!;
  final cross = M5SearchlightLines.crossFor(why);
  if (cross.isEmpty) return dealChoices(right, M5SearchlightLines.wrongFor(why), rng);
  final guess = [...M5SearchlightLines.pinMyths]..shuffle(rng);
  return [
    ChoiceOption(right[rng.nextInt(right.length)], true),
    ChoiceOption(cross[rng.nextInt(cross.length)], false),
    ChoiceOption(guess.first, false),
  ]..shuffle(rng);
}

/// True if tapping [row] from left to right would be a right report.
bool m5SlInWorkOrder(List<M5SlTool> row) => row.first == M5SlTool.binoculars && row[1] == M5SlTool.phone;

M5SlDeal m5SlDeal(math.Random rng) {
  final low = rng.nextInt(4) == 0 ? null : M5SlDevice.values[rng.nextInt(3)];
  final charge = {for (final d in M5SlDevice.values) d: d == low ? 8 + rng.nextInt(15) : 84 + rng.nextInt(17)};
  final pegs = [...M5SlJacket.values]..shuffle(rng);
  // Sides: random, at least two on each side.
  List<M5SlSide> sides;
  do {
    sides = [for (var i = 0; i < 8; i++) rng.nextBool() ? M5SlSide.far : M5SlSide.near];
  } while (sides.where((s) => s == M5SlSide.far).length < 2 || sides.where((s) => s == M5SlSide.near).length < 2);
  final spots = [for (var i = 0; i < 8; i++) if (i != m5SlCoworkerPole) i]..shuffle(rng);
  final faults = spots.take(1 + rng.nextInt(2)).toSet();
  final plate0 = 20 + rng.nextInt(60);
  final poles = [
    for (var i = 0; i < 8; i++)
      M5SlPole(
        side: sides[i],
        fault: faults.contains(i) ? (rng.nextBool() ? M5SlFault.insulator : M5SlFault.branch) : M5SlFault.none,
        porcelain: rng.nextBool(),
        plate: plate0 + i,
      ),
  ];
  final tools = [...M5SlTool.values];
  do {
    tools.shuffle(rng);
  } while (m5SlInWorkOrder(tools));
  return M5SlDeal(
    lowDevice: low,
    charge: charge,
    pegs: pegs,
    fieldLeft: rng.nextBool(),
    poles: poles,
    feeder: 1 + rng.nextInt(9),
    docketNo: 100 + rng.nextInt(900),
    depotWhy: [M5SlWhy.battery, M5SlWhy.jacket, M5SlWhy.two]..shuffle(rng),
    tools: tools,
  );
}

/// The play state (pure logic).
class M5SlRun {
  M5SlRun(this.deal);
  final M5SlDeal deal;

  int index = 0;
  int slips = 0;
  int stationSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  // ডিপো
  final Set<M5SlDevice> read = {};
  final Set<M5SlDevice> swapped = {};
  M5SlJacket? jacket;
  final Map<M5SlSeat, M5SlWho> seats = {};
  var docket = false;
  var departed = false;
  var _alone = false;

  // পথ
  var forkDone = false;

  // টহল
  final Set<int> pinned = {};
  final Set<int> passed = {};
  final Set<int> dark = {};
  var everFast = false;
  var listened = false;

  // রিপোর্ট
  var plateRead = false;
  var sent = false;
  var _phoneDied = false;

  M5SlStation get station => M5SlStation.values[index.clamp(0, 3)];
  bool get done => index >= 4;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passedLevel => done && deadly == null && percent >= 55;
  bool get thorough => stationSlips == 0;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stationSlips++;
    return m;
  }

  // --- ডিপো -------------------------------------------------------------------
  int charge(M5SlDevice d) => swapped.contains(d) ? 100 : deal.charge[d]!;
  bool low(M5SlDevice d) => charge(d) < m5SlLowCharge;

  void readDevice(M5SlDevice d) {
    if (station == M5SlStation.depot) read.add(d);
  }

  /// A device dropped on the dock: swapped for a full one only if it was read
  /// and is low (returns true then); otherwise it goes back to the shelf.
  bool dock(M5SlDevice d) {
    if (station != M5SlStation.depot || !read.contains(d) || !low(d)) return false;
    swapped.add(d);
    return true;
  }

  void wear(M5SlJacket j) {
    if (station == M5SlStation.depot) jacket = j;
  }

  void takeDocket() {
    if (station == M5SlStation.depot) docket = true;
  }

  /// [w] into [s]; false if the seat is taken by the other.
  bool seat(M5SlWho w, M5SlSeat s) {
    if (station != M5SlStation.depot) return false;
    final there = seats[s];
    if (there != null && there != w) return false;
    seats.removeWhere((_, who) => who == w);
    seats[s] = w;
    return true;
  }

  void unseat(M5SlWho w) => seats.removeWhere((_, who) => who == w);

  M5SlSeat? seatOf(M5SlWho w) {
    for (final e in seats.entries) {
      if (e.value == w) return e.key;
    }
    return null;
  }

  bool get canDepart => station == M5SlStation.depot && !departed && seats[M5SlSeat.driver] != null;

  bool get batteryRight => read.length == M5SlDevice.values.length && (deal.lowDevice == null || swapped.contains(deal.lowDevice));

  /// রওনা. No docket = a slip and the van stays; one person = a slip, the
  /// partner jumps in and the van goes.
  DoMistake? depart() {
    if (!canDepart) return null;
    if (!docket) return _slip(M5SearchlightMistakes.noDocket);
    departed = true;
    _tag(M5SearchlightLines.caughtDocket);
    if (seats.length < 2) {
      _alone = true;
      final empty = seats.containsKey(M5SlSeat.driver) ? M5SlSeat.light : M5SlSeat.driver;
      final out = seats.containsValue(M5SlWho.trainee) ? M5SlWho.partner : M5SlWho.trainee;
      seats[empty] = out;
      return _slip(M5SearchlightMistakes.alone);
    }
    _tag(M5SearchlightLines.caughtTwo);
    if (jacket == M5SlJacket.reflective) _tag(M5SearchlightLines.caughtJacket);
    if (batteryRight) _tag(M5SearchlightLines.caughtBattery);
    return null;
  }

  /// The depot reason: the first of the dealt order that was done right.
  M5SlWhy? get depotWhy {
    for (final w in deal.depotWhy) {
      final ok = switch (w) {
        M5SlWhy.battery => batteryRight,
        M5SlWhy.jacket => jacket == M5SlJacket.reflective,
        M5SlWhy.two => departed && !_alone,
        _ => false,
      };
      if (ok) return w;
    }
    return null;
  }

  // --- পথ ---------------------------------------------------------------------
  DoMistake? chooseFork({required bool field}) {
    if (station != M5SlStation.fork || forkDone) return null;
    forkDone = true;
    if (field) return _slip(M5SearchlightMistakes.fieldTrack);
    _tag(M5SearchlightLines.caughtRoad);
    return null;
  }

  // --- টহল --------------------------------------------------------------------
  /// A long-press on pole [i]'s lit top.
  DoMistake? pin(int i) {
    if (station != M5SlStation.patrol || pinned.contains(i) || passed.contains(i)) return null;
    if (deal.poles[i].fault == M5SlFault.none) return _slip(M5SearchlightMistakes.soundPin);
    pinned.add(i);
    _tag(M5SearchlightLines.caughtFault);
    return null;
  }

  /// Pole [i] has left the screen; [fast] = the van was going fast.
  DoMistake? pass(int i, {required bool fast}) {
    if (station != M5SlStation.patrol || passed.contains(i)) return null;
    passed.add(i);
    if (deal.poles[i].fault == M5SlFault.none || pinned.contains(i) || dark.contains(i)) return null;
    return _slip(fast ? M5SearchlightMistakes.fastMissed : M5SearchlightMistakes.missed);
  }

  void markFast() => everFast = true;

  /// Listened to the coworker: the searchlight is off for the next poles.
  /// Every pole not yet gone up to there goes dark with them (at the halt the
  /// pole before his is still on screen behind the van): one slip in all, so
  /// no fault that passes in the dark is booked again.
  DoMistake listen() {
    listened = true;
    final last = math.min(m5SlCoworkerPole + m5SlDarkPoles, deal.poles.length - 1);
    for (var i = 0; i <= last; i++) {
      if (!passed.contains(i) && !pinned.contains(i)) dark.add(i);
    }
    return _slip(M5SearchlightMistakes.headlights);
  }

  void refuse() => _tag(M5SearchlightLines.caughtCall);

  bool get patrolDone => passed.length == deal.poles.length;

  /// Where the trainee steps out: the last mark (or the end of the stretch).
  int get stepPole => pinned.isEmpty ? deal.poles.length - 1 : pinned.reduce(math.max);

  /// No pole was marked: there is no fault to report (the step-out has only
  /// the depot bites, then the level ends without the binoculars and phone).
  bool get nothingToReport => pinned.isEmpty;

  // --- রিপোর্ট ----------------------------------------------------------------
  /// The depot choices that bite at the step-out (in order): a dark (or no)
  /// jacket, a low torch or headlamp left unswapped.
  List<DoMistake> get stepBites => [
        if (jacket != M5SlJacket.reflective) M5SearchlightMistakes.darkJacket,
        if (deal.lowDevice != null && deal.lowDevice != M5SlDevice.phone && !swapped.contains(deal.lowDevice)) M5SearchlightMistakes.lowBattery,
      ];

  DoMistake bite(DoMistake m) => _slip(m);

  void binoculars() {
    if (station == M5SlStation.stepOut && !nothingToReport) plateRead = true;
  }

  /// The phone: does nothing before the plate is read; a low phone dies (a
  /// slip — the partner's phone sends it); otherwise the number is sent.
  DoMistake? phone() {
    if (station != M5SlStation.stepOut || nothingToReport || !plateRead || sent) return null;
    sent = true;
    if (deal.lowDevice == M5SlDevice.phone && !swapped.contains(M5SlDevice.phone) && !_phoneDied) {
      _phoneDied = true;
      return _slip(M5SearchlightMistakes.lowBattery);
    }
    _tag(M5SearchlightLines.caughtReport);
    return null;
  }

  bool get phoneDied => _phoneDied;

  /// Climbing the pole to look closer: deadly.
  DoMistake climb() => deadly = M5SearchlightMistakes.climb;

  void next() {
    index++;
    stationSlips = 0;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   ডিপো: 3 holds, a dock drag, a jacket, the docket, 2 drags, রওনা ≈ 15000 + reason ~8200
///   পথ: one tap ≈ 2000
///   টহল: 8 × 176 px at ধীরে (48 px/s) ≈ 29000; 1.5 marks × (stop, aim, hold ≈ 4000 + reason ~8200) ≈ 18300
///        + the coworker ≈ 9600 + the patrol reason ~8200
///   রিপোর্ট: binoculars, phone ≈ 4000                           ≈ 102300
/// 85 % ≈ 87000 → 90 s.
const m5SlQuickMs = 90000;

/// Van speeds (design px / s).
const m5SlSlowPx = 48.0;
const m5SlFastPx = 150.0;

@immutable
class M5SearchlightPack {
  const M5SearchlightPack({required this.id, required this.titleBn, this.quickMs = m5SlQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5SearchlightPack> m5SearchlightPacks = {
  'do_5_7_a': M5SearchlightPack(id: 'do_5_7_a', titleBn: M5SearchlightLines.title),
};

/// Test hook: the page's live state (tests only).
class M5SearchlightProbe {
  M5SlRun? run;
  M5SlPatrolView? view;
  M5SlGeo? geo;
  M5SlSpeed speed = M5SlSpeed.stop;
  bool halted = false;

  /// Design px (the scene) → global px, or null before layout.
  Offset? Function(Offset design)? toGlobal;
}

// ============================================================================
// Page
// ============================================================================

class M5SearchlightPage extends StatefulWidget {
  const M5SearchlightPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.probe});

  final LevelContext ctx;
  final M5SearchlightPack pack;
  final bool muted;
  final int? seed;
  final M5SearchlightProbe? probe;

  @override
  State<M5SearchlightPage> createState() => _M5SearchlightPageState();
}

class _M5SearchlightPageState extends State<M5SearchlightPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PatrolRunPage(
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

class _PatrolRunPage extends ConsumerStatefulWidget {
  const _PatrolRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry, this.probe});

  final LevelContext ctx;
  final M5SearchlightPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;
  final M5SearchlightProbe? probe;

  @override
  ConsumerState<_PatrolRunPage> createState() => _PatrolRunPageState();
}

/// What the open reason card is about (what follows it).
enum _ReasonFor { depot, pin, slow }

/// A depot choice biting at the step-out.
enum _Bite { truck, torch }

class _PatrolRunPageState extends ConsumerState<_PatrolRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5SlRun _run;
  late final int _seed = _run.deal.feeder * 31 + _run.deal.docketNo;
  final _view = M5SlPatrolView();
  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  VoidCallback? _afterSlip;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  _ReasonFor _reasonFor = _ReasonFor.depot;

  // ডিপো: drags in progress (design px).
  final Map<M5SlDevice, Offset> _devDrag = {};
  final Map<M5SlWho, Offset> _figDrag = {};
  M5SlDevice? _justDocked;
  int _dockTok = 0;

  // পথ / station change: input waits while the van drives off.
  var _leaving = false;

  // টহল
  M5SlSpeed _speed = M5SlSpeed.stop;
  var _halted = false;
  var _patrolEnding = false;

  // রিপোর্ট
  final List<DoMistake> _bites = [];
  var _biting = false;
  _Bite? _bite;
  int _biteTok = 0;
  var _beamDead = false;
  var _binoOn = false;
  var _phoneOn = false;
  var _phoneDead = false;
  Timer? _viewTimer;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand: the scene's touch layer (design px → screen) and the
  /// HUD controls.
  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  final _goKey = GlobalKey();
  final _leverKey = GlobalKey();
  final Map<M5SlTool, GlobalKey> _toolKeys = {for (final t in M5SlTool.values) t: GlobalKey()};
  int _hintN = 0;
  M5SlGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M5SlRun(m5SlDeal(widget.rng));
    final p = widget.probe;
    if (p != null) {
      p.run = _run;
      p.view = _view;
      p.toGlobal = (d) {
        final box = _touchKey.currentContext?.findRenderObject();
        if (box is! RenderBox || !box.hasSize || !box.attached) return null;
        return box.localToGlobal(d);
      };
    }
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _viewTimer?.cancel();
    _ticker.dispose();
    _view.dispose();
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

  bool get _overlayBusy => _binoOn || _phoneOn;

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !tableBusy && !coworkerOpen && !_freeze && !_leaving && !_biting && !_overlayBusy && !_patrolEnding;

  String get _task => switch (_run.station) {
        M5SlStation.depot => M5SearchlightLines.askDepot,
        M5SlStation.fork => M5SearchlightLines.askFork,
        M5SlStation.patrol => M5SearchlightLines.askPatrol,
        M5SlStation.stepOut => _run.nothingToReport ? M5SearchlightLines.noMark : M5SearchlightLines.askReport,
      };

  Future<void> _start() async {
    _clock.start();
    _startStation();
  }

  void _startStation() {
    if (_run.station == M5SlStation.patrol) {
      final g = _geoNow;
      _speed = M5SlSpeed.stop;
      _view
        ..x = 0
        ..lightOn = true
        ..headlights = true
        ..lit = null
        ..resolved = false
        ..aim = Offset(250, g == null ? 260 : (g.farTopY + g.nearTopY) / 2 - 34);
    }
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  void _next() {
    setState(() {
      _run.next();
      _leaving = false;
      _wake++;
    });
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startStation();
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  Offset get _centre {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * 0.45);
  }

  // --- ডিপো --------------------------------------------------------------------
  void _readDevice(M5SlDevice d) {
    if (!_canPlay || _run.station != M5SlStation.depot) return;
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _run.readDevice(d);
      _wake++;
    });
  }

  void _dragDevice(M5SlDevice d, Offset delta) {
    if (!_canPlay || _run.station != M5SlStation.depot) return;
    setState(() => _devDrag[d] = (_devDrag[d] ?? Offset.zero) + delta);
  }

  void _dropDevice(M5SlDevice d) {
    final geo = _geoNow;
    final off = _devDrag.remove(d) ?? Offset.zero;
    if (geo == null || !_canPlay) {
      setState(() {});
      return;
    }
    final c = geo.deviceHome(d).center + off;
    if (geo.dock.inflate(16).contains(c) && _run.dock(d)) {
      _tick('sounds/learn/tag_slap.ogg', 0.6);
      setState(() {
        _justDocked = d;
        _dockTok++;
        _wake++;
      });
      return;
    }
    if (off.distance > 12) _tick('sounds/intro/tick.ogg', 0.35);
    setState(() {});
  }

  void _wear(M5SlJacket j) {
    if (!_canPlay || _run.station != M5SlStation.depot) return;
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    setState(() {
      _run.wear(j);
      _wake++;
    });
  }

  void _takeDocket() {
    if (!_canPlay || _run.station != M5SlStation.depot || _run.docket) return;
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    setState(() {
      _run.takeDocket();
      _wake++;
    });
  }

  void _dragFigure(M5SlWho w, Offset delta) {
    if (!_canPlay || _run.station != M5SlStation.depot) return;
    setState(() => _figDrag[w] = (_figDrag[w] ?? Offset.zero) + delta);
  }

  Rect _figureRect(M5SlGeo geo, M5SlWho w) {
    final s = _run.seatOf(w);
    if (s == null) return geo.figureHome(w);
    final r = geo.seat(s);
    return Rect.fromCenter(center: r.center, width: 26, height: 56);
  }

  void _dropFigure(M5SlWho w) {
    final geo = _geoNow;
    final off = _figDrag.remove(w) ?? Offset.zero;
    if (geo == null || !_canPlay) {
      setState(() {});
      return;
    }
    final c = _figureRect(geo, w).center + off;
    for (final s in M5SlSeat.values) {
      if (geo.seat(s).inflate(18).contains(c)) {
        if (_run.seat(w, s)) _tick('sounds/intro/click.ogg', 0.5);
        setState(() => _wake++);
        return;
      }
    }
    if (off.distance > 24 && _run.seatOf(w) != null) _run.unseat(w);
    setState(() => _wake++);
  }

  void _depart(Offset global) {
    if (!_canPlay || _run.station != M5SlStation.depot) return;
    if (!_run.canDepart) {
      _hints.missTap();
      return;
    }
    _tick('sounds/intro/click.ogg', 0.6);
    final m = _run.depart();
    setState(() => _wake++);
    if (m != null) {
      _afterSlip = _run.departed ? _afterDepart : null;
      unawaited(_mistake(m, global));
      return;
    }
    _afterDepart();
  }

  void _afterDepart() {
    final why = _run.depotWhy;
    _cue('sounds/learn/rush_in.ogg', volume: 0.4);
    if (why == null) {
      setState(() => _leaving = true);
      unawaited(Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted && !_ended && _run.station == M5SlStation.depot) _next();
      }));
      return;
    }
    _roundTable(why, _ReasonFor.depot);
  }

  void _roundTable(M5SlWhy why, _ReasonFor what) {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    _reasonFor = what;
    putOnTable(15 + (what != _ReasonFor.pin && _run.thorough ? 5 : 0));
    final idx = _run.index;
    final pins = _run.pinned.length;
    unawaited(askReason(
      deal: () => m5SlReasonDeal(why, widget.rng),
      question: M5SearchlightLines.whyQ[why]!,
      stillValid: () => _run.index == idx && _run.pinned.length == pins && !_ended,
    ));
  }

  // --- পথ ----------------------------------------------------------------------
  void _pickFork(bool left, Offset global) {
    if (!_canPlay || _run.station != M5SlStation.fork) return;
    _tick('sounds/intro/click.ogg', 0.6);
    final m = _run.chooseFork(field: left == _run.deal.fieldLeft);
    if (m != null) {
      _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
      _afterSlip = _next;
      unawaited(_mistake(m, global));
      return;
    }
    _cue('sounds/quiz_right.ogg', volume: 0.5);
    setState(() => _leaving = true);
    unawaited(_sayChain([M5SearchlightLines.roadRight], mood: GuideMood.glad));
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.station == M5SlStation.fork) _next();
    }));
  }

  // --- টহল ---------------------------------------------------------------------
  bool get _patrolOn => _run.station == M5SlStation.patrol && !_ended && !_intro;
  bool get _paused => !_patrolOn || _card != null || tableBusy || coworkerOpen || _halted || _freeze || _patrolEnding;
  bool get _wantTick => !_paused && (_speed != M5SlSpeed.stop || (_view.lit != null && !_view.resolved && _speed != M5SlSpeed.fast));

  void _syncTicker() {
    if (!mounted) return;
    final want = _wantTick;
    if (want && !_ticker.isActive) {
      _last = Duration.zero;
      unawaited(_ticker.start());
    } else if (!want && _ticker.isActive) {
      _ticker.stop();
    }
    final p = widget.probe;
    if (p != null) {
      p.speed = _speed;
      p.halted = _halted;
      p.geo = _geoNow;
    }
  }

  double get _speedPx => switch (_speed) {
        M5SlSpeed.stop => 0,
        M5SlSpeed.slow => m5SlSlowPx,
        M5SlSpeed.fast => m5SlFastPx,
      };

  void _onTick(Duration e) {
    final dt = ((e - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = e;
    final geo = _geoNow;
    if (_paused || geo == null) {
      _ticker.stop();
      return;
    }
    _view.x += _speedPx * dt;
    _updateLit(dt);
    _checkLight(geo);
    _view.changed();
    _checkPoles(geo);
    if (!_wantTick && _ticker.isActive) _ticker.stop();
  }

  int? _litPole(M5SlGeo geo) {
    if (!_view.lightOn) return null;
    int? best;
    var bd = M5SlGeo.litRadius;
    for (var i = 0; i < _run.deal.poles.length; i++) {
      if (_run.passed.contains(i)) continue;
      final d = (geo.poleTop(_run.deal.poles[i], i, _view.x) - _view.aim).distance;
      if (d <= bd) {
        best = i;
        bd = d;
      }
    }
    return best;
  }

  void _updateLit(double dt) {
    final geo = _geoNow;
    if (geo == null) return;
    final lit = _litPole(geo);
    final fast = _speed == M5SlSpeed.fast;
    _view.fast = fast;
    var changed = false;
    if (lit != _view.lit) {
      changed = _view.resolved || (_view.lit == null) != (lit == null);
      _view
        ..lit = lit
        ..dwell = 0
        ..resolved = false;
    }
    if (lit != null && !fast && !_view.resolved) {
      _view.dwell += dt;
      if (_view.dwell >= 0.45) {
        _view.resolved = true;
        changed = true;
      }
    }
    if (fast && _view.resolved) {
      _view.resolved = false;
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }

  /// After listening, the light comes back once the dark poles have passed.
  void _checkLight(M5SlGeo geo) {
    if (_view.lightOn || !_run.listened) return;
    if (_run.dark.every((i) => geo.poleScreenX(i, _view.x) < geo.levelX - 30)) {
      setState(() => _view.lightOn = true);
    }
  }

  void _checkPoles(M5SlGeo geo) {
    // The van halts as pole 2 comes level; he comes now (the van waits).
    if (!coworkerDone && !_halted) {
      final sx = geo.poleScreenX(m5SlCoworkerPole, _view.x);
      if (!coworkerDue && sx < geo.levelX + 150) scheduleCoworker();
      if (sx <= geo.levelX) {
        _view.x = M5SlGeo.poleWorldX(m5SlCoworkerPole) - geo.levelX;
        _ticker.stop();
        setState(() {
          _halted = true;
          _wake++;
        });
        _cue('sounds/intro/impact_metal.ogg', volume: 0.3);
        holdForCoworker();
        return;
      }
    }
    for (var i = 0; i < _run.deal.poles.length; i++) {
      if (_run.passed.contains(i) || geo.poleScreenX(i, _view.x) >= M5SlGeo.goneX) continue;
      final m = _run.pass(i, fast: _speed == M5SlSpeed.fast);
      if (m != null) {
        _ticker.stop();
        _afterSlip = null;
        unawaited(_mistake(m, _centre));
        return;
      }
    }
    if (_run.patrolDone) _patrolDone();
  }

  void _setSpeed(M5SlSpeed s) {
    if (!_canPlay || _run.station != M5SlStation.patrol) return;
    // While he is due at the halt, the lever waits for him.
    if (_halted && holdForCoworker()) return;
    if (s == _speed) return;
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _speed = s;
      if (s == M5SlSpeed.fast) _run.markFast();
      _view.fast = s == M5SlSpeed.fast;
      _wake++;
    });
    _syncTicker();
  }

  void _aimAt(Offset p) {
    if (!_canPlay || _run.station != M5SlStation.patrol) return;
    final g = _geoNow;
    if (g == null) return;
    _view.aim = Offset(p.dx.clamp(6.0, 354.0), p.dy.clamp(120.0, g.roadTop - 12));
    _updateLit(0);
    _view.changed();
    _syncTicker();
  }

  void _pinAt(Offset p, Offset global) {
    if (!_canPlay || _run.station != M5SlStation.patrol) return;
    final lit = _view.lit;
    if (lit == null || !_view.resolved || !_view.lightOn || (p - _view.aim).distance > M5SlGeo.spot + 18) {
      _aimAt(p);
      _hints.missTap();
      return;
    }
    if (_halted && holdForCoworker()) return;
    final m = _run.pin(lit);
    setState(() => _wake++);
    if (m != null) {
      _afterSlip = null;
      unawaited(_mistake(m, global));
      return;
    }
    _view.pinned.add(lit);
    _view.changed();
    final why = _run.deal.poles[lit].fault == M5SlFault.insulator ? M5SlWhy.insulator : M5SlWhy.branch;
    _roundTable(why, _ReasonFor.pin);
  }

  void _patrolDone() {
    if (_patrolEnding) return;
    _ticker.stop();
    setState(() => _patrolEnding = true);
    if (!_run.everFast) {
      _run.caught.add(M5SearchlightLines.caughtSlow);
      _roundTable(M5SlWhy.slow, _ReasonFor.slow);
      return;
    }
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 900), () {
      if (mounted && !_ended) _toStepOut();
    }));
  }

  void _toStepOut() {
    final geo = _geoNow;
    final i = _run.stepPole;
    setState(() {
      _run.next();
      _patrolEnding = false;
      _speed = M5SlSpeed.stop;
      _view
        ..x = M5SlGeo.stepX(i)
        ..lightOn = true
        ..fast = false
        ..lit = i
        ..resolved = true;
      if (geo != null) _view.aim = geo.poleTop(_run.deal.poles[i], i, _view.x);
      _bites
        ..clear()
        ..addAll(_run.stepBites);
      _biting = _bites.isNotEmpty;
      _wake++;
    });
    _view.changed();
    if (_biting) {
      unawaited(Future<void>.delayed(const Duration(milliseconds: 600), _nextBite));
    } else {
      _reportOrEnd();
    }
  }

  /// After the bites: the report task, or (no pole marked) no report at all —
  /// a sound pole's number is never sent as the fault's place.
  void _reportOrEnd() {
    if (!_run.nothingToReport) {
      unawaited(_sayChain([_task]));
      return;
    }
    setState(() => _leaving = true);
    unawaited(_sayChain([_task], mood: GuideMood.warn));
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 900 : 2600), () {
      if (mounted && !_ended && _run.station == M5SlStation.stepOut) _next();
    }));
  }

  // --- রিপোর্ট -----------------------------------------------------------------
  void _nextBite() {
    if (!mounted || _ended) return;
    if (_bites.isEmpty) {
      setState(() => _biting = false);
      _reportOrEnd();
      return;
    }
    final m = _bites.removeAt(0);
    final kind = m == M5SearchlightMistakes.darkJacket ? _Bite.truck : _Bite.torch;
    setState(() {
      _bite = kind;
      _biteTok++;
      _wake++;
    });
    _cue(kind == _Bite.truck ? 'sounds/learn/rush_in.ogg' : 'sounds/intro/tick.ogg', volume: 0.8);
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1500), () {
      if (!mounted || _ended) return;
      setState(() {
        _bite = null;
        if (kind == _Bite.torch) _beamDead = true;
      });
      final b = _run.bite(m);
      _afterSlip = _nextBite;
      unawaited(_mistake(b, _centre));
    }));
  }

  void _useTool(M5SlTool t, Offset global, {bool held = false}) {
    if (!_canPlay || _run.station != M5SlStation.stepOut) return;
    switch (t) {
      case M5SlTool.binoculars:
        _tick('sounds/intro/click.ogg', 0.5);
        _run.binoculars();
        _viewTimer?.cancel();
        setState(() {
          _binoOn = true;
          _wake++;
        });
        _viewTimer = Timer(Duration(milliseconds: held ? 1800 : 1500), () {
          if (mounted) setState(() => _binoOn = false);
        });
      case M5SlTool.phone:
        if (!_run.plateRead) {
          _tick('sounds/intro/tick.ogg', 0.35);
          _hints.missTap();
          return;
        }
        _tick('sounds/intro/click.ogg', 0.6);
        final m = _run.phone();
        _viewTimer?.cancel();
        setState(() {
          _phoneOn = true;
          _phoneDead = m != null;
          _wake++;
        });
        if (m != null) {
          _viewTimer = Timer(const Duration(milliseconds: 900), () {
            if (!mounted) return;
            setState(() => _phoneOn = false);
            _afterSlip = _reportSent;
            unawaited(_mistake(m, global));
          });
          return;
        }
        _cue('sounds/quiz_right.ogg', volume: 0.6);
        _viewTimer = Timer(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          setState(() => _phoneOn = false);
          _reportSent();
        });
      case M5SlTool.climb:
        _tick('sounds/intro/click.ogg', 0.6);
        final m = _run.climb();
        setState(() => _wake++);
        unawaited(_mistake(m, global));
    }
  }

  /// The number is with the control room (the partner's phone if the trainee's died).
  void _reportSent() {
    if (!mounted || _ended) return;
    if (_run.phoneDied) {
      _run.caught.add(M5SearchlightLines.caughtReport);
      setState(() {
        _phoneOn = true;
        _phoneDead = false;
      });
      _viewTimer?.cancel();
      _viewTimer = Timer(const Duration(milliseconds: 1300), () {
        if (!mounted) return;
        setState(() => _phoneOn = false);
        _next();
      });
      return;
    }
    _next();
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
    final what = _reasonFor;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (!mounted || _ended || _run.index != idx) return;
      switch (what) {
        case _ReasonFor.depot:
          _next();
        case _ReasonFor.pin:
          setState(() => _wake++);
          unawaited(_sayChain([_task]));
          _syncTicker();
        case _ReasonFor.slow:
          _toStepOut();
      }
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M5SearchlightLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.station != M5SlStation.patrol) return null;
    if (_intro || _card != null || tableBusy || _freeze || !_halted) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened: the searchlight goes off for the next two poles.
      final m = _run.listen();
      setState(() {
        _view.lightOn = false;
        _view.lit = null;
        _view.resolved = false;
        _halted = false;
      });
      _view.changed();
      _afterSlip = null;
      await _mistake(m, origin);
      return;
    }
    _run.refuse();
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    setState(() => _halted = false);
    _syncTicker();
    unawaited(_sayChain([M5SearchlightLines.callHeld, M5SearchlightLines.askPatrol], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5SearchlightLines.tapWhy[_nudgeN++ % M5SearchlightLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _ticker.stop();
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
    _ticker.stop();
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m5sl/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Climbing the tripped line: the scene freezes grey and the arc comes off
  /// the pole top in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _ticker.stop();
    _hush();
    _viewTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _binoOn = false;
      _phoneOn = false;
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
    final speak = await SpokenOnce.first('m5sl/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5SearchlightLines.deadlyWord : M5SearchlightLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        final then = _afterSlip;
        _afterSlip = null;
        setState(() {
          _card = null;
          _wake++;
        });
        if (then != null) {
          then();
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
    _ticker.stop();
    final save = ref.read(gameSaveProvider.notifier);
    final centre = _centre;
    final mark = _run.percent;
    await save.recordLevelResult(_rungId, mark);
    if (!mounted) return;
    if (_run.passedLevel) {
      await save.markRungCleared(_rungId);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && _clock.elapsedMilliseconds < widget.pack.quickMs) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passedLevel) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passedLevel, strikes: strikes, quick: _clock.elapsedMilliseconds < widget.pack.quickMs);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passedLevel ? M5SearchlightLines.fail : (_quickBonus ? M5SearchlightLines.quick : M5SearchlightLines.allSet),
        mood: _run.passedLevel ? GuideMood.celebrate : GuideMood.warn);
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
    if (_binoOn || _phoneOn) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  LinemanLook get _traineeLook {
    const t = LinemanLook.trainee;
    final vest = switch (_run.jacket) {
      M5SlJacket.reflective => const Color(0xFFC8EE3C),
      M5SlJacket.dark => const Color(0xFF1C2330),
      null => t.shirt,
    };
    return LinemanLook(helmet: t.helmet, shirt: t.shirt, vest: vest, pants: t.pants, skin: t.skin, gloves: true);
  }

  static const _partnerLook = LinemanLook(
    helmet: Color(0xFFF2F4F7),
    shirt: Color(0xFF5B6B7F),
    vest: Color(0xFF5B6B7F),
    pants: Color(0xFF2B2F36),
    skin: Color(0xFF9C6644),
    moustache: true,
  );

  /// A design-px rect of the scene on screen (null before layout).
  Rect? _sceneRect(Rect r) {
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return Rect.fromPoints(box.localToGlobal(r.topLeft), box.localToGlobal(r.bottomRight));
  }

  Offset? _scenePoint(Offset p) => _sceneRect(Rect.fromCenter(center: p, width: 2, height: 2))?.center;

  /// The gesture hand for the waiting state (how to touch, never what).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    switch (_run.station) {
      case M5SlStation.depot:
        // A press-hold in turn over every device (all alike); a short nudge
        // on a device read low; a sweep over the rest of the depot choices.
        final specs = <HintSpec>[
          for (final d in M5SlDevice.values)
            if (_scenePoint(geo.deviceHome(d).center) case final p?) HintSpec.hold(p),
          for (final d in M5SlDevice.values)
            if (_run.read.contains(d) && _run.low(d))
              if (_scenePoint(geo.deviceHome(d).center) case final p?) HintSpec.drag(p, toward: const Offset(0, -1), travel: 48),
        ];
        final rest = [
          for (var i = 0; i < 2; i++) ?_sceneRect(geo.peg(i)),
          if (!_run.docket) ?_sceneRect(geo.docket),
          for (final w in M5SlWho.values) ?_sceneRect(_figureRect(geo, w)),
          ?HintSpec.globalRectOf(_goKey),
        ];
        if (rest.length >= 2) specs.add(HintSpec.sweep(rest));
        if (specs.isEmpty) return null;
        return specs[_hintN++ % specs.length];
      case M5SlStation.fork:
        final signs = [?_sceneRect(geo.sign(true)), ?_sceneRect(geo.sign(false))];
        return signs.length < 2 ? null : HintSpec.sweep(signs);
      case M5SlStation.patrol:
        if (_view.lit != null && _view.resolved && _view.lightOn) {
          final p = _scenePoint(_view.aim);
          return p == null ? null : HintSpec.hold(p);
        }
        if (_speed == M5SlSpeed.stop && (_hintN++).isEven) {
          final lever = HintSpec.globalRectOf(_leverKey);
          if (lever != null) return HintSpec.swipe(Offset(lever.center.dx, lever.bottom - 24), toward: const Offset(0, -1), travel: lever.height - 48);
        }
        // The sweep never stops on a pole top (silhouettes are alike, but the
        // hand must not seem to point at one).
        final tops = [
          for (var i = 0; i < _run.deal.poles.length; i++)
            if (!_run.passed.contains(i)) geo.poleTop(_run.deal.poles[i], i, _view.x),
        ];
        final sky = [for (final r in geo.skyBandClear(tops)) ?_sceneRect(r)];
        return sky.length < 2 ? null : HintSpec.sweep(sky);
      case M5SlStation.stepOut:
        return HintSpec.sweepOver([for (final t in _run.deal.tools) _toolKeys[t]!]);
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5SlGeo.forScene(m.height, m.inset);
    widget.probe?.geo = geo;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final world = switch (_run.station) {
      M5SlStation.depot => _depotLayers(geo),
      M5SlStation.fork => _forkLayers(geo),
      M5SlStation.patrol || M5SlStation.stepOut => _patrolLayers(geo),
    };
    final quiet = _quiet;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(colorFilter: grey, child: Stack(children: world)),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M5SlFlashPainter(at: _flashAt(geo), v: v)),
            ),
          ),
        ),
      // The next station: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('station-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 0.7, end: 0),
              duration: const Duration(milliseconds: 560),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(3, 6, 14, v)),
            ),
          ),
        ),
    ];
  }

  Offset _flashAt(M5SlGeo geo) {
    final i = _run.stepPole;
    final p = _run.deal.poles[i];
    return geo.poleTop(p, i, _view.x);
  }

  Widget _touch({required Widget child}) => Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(label: M5SearchlightLines.sceneLabel, child: child),
      );

  List<Widget> _depotLayers(M5SlGeo geo) {
    final quiet = _quiet;
    return [
      Positioned.fill(
        key: const ValueKey('depot'),
        child: RepaintBoundary(child: CustomPaint(painter: M5SlDepotPainter(geo: geo, seed: _seed))),
      ),
      _touch(
        child: GestureDetector(
          key: _touchKey,
          behavior: HitTestBehavior.opaque,
          onTapUp: (_) => _hints.missTap(),
        ),
      ),
      if (!_run.docket)
        Positioned.fromRect(
          key: const ValueKey('docket'),
          rect: geo.docket,
          child: Semantics(
            button: true,
            label: M5SearchlightLines.docket(_run.deal.feeder, _run.deal.docketNo),
            excludeSemantics: true,
            child: GestureDetector(onTap: _takeDocket, child: _DocketChip(text: M5SearchlightLines.docket(_run.deal.feeder, _run.deal.docketNo))),
          ),
        ),
      for (final (i, j) in _run.deal.pegs.indexed)
        if (_run.jacket != j)
          Positioned.fromRect(
            key: ValueKey('peg-${j.name}'),
            rect: geo.peg(i),
            child: Semantics(
              button: true,
              label: M5SearchlightLines.jacketLabel(j),
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _wear(j),
                child: CustomPaint(painter: M5SlJacketPainter(j)),
              ),
            ),
          ),
      // A device just docked: a short green glow on the dock.
      if (_justDocked != null)
        Positioned.fromRect(
          key: ValueKey('docked-$_dockTok'),
          rect: geo.dock,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 900),
              builder: (_, v, _) => v <= 0.001
                  ? const SizedBox.shrink()
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: SlmColors.success.withValues(alpha: v), width: 3),
                      ),
                    ),
            ),
          ),
        ),
      for (final d in M5SlDevice.values) ..._device(geo, d),
      for (final w in M5SlWho.values)
        Positioned.fromRect(
          key: ValueKey('fig-${w.name}'),
          rect: _figureRect(geo, w).shift(_figDrag[w] ?? Offset.zero),
          child: Semantics(
            label: M5SearchlightLines.whoLabel(w),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) => _dragFigure(w, d.delta),
              onPanEnd: (_) => _dropFigure(w),
              onPanCancel: () => _dropFigure(w),
              child: LinemanFigure(
                look: w == M5SlWho.trainee ? _traineeLook : _partnerLook,
                mode: w == M5SlWho.trainee ? _mode : LinemanMode.idle,
                wake: _wake,
                quiet: quiet,
              ),
            ),
          ),
        ),
      // Seat targets (for tests and screen readers; drawn by the painter).
      for (final s in M5SlSeat.values)
        Positioned.fromRect(
          key: ValueKey('seat-${s.name}'),
          rect: geo.seat(s),
          child: IgnorePointer(child: Semantics(label: M5SearchlightLines.seatLabel(s), child: const SizedBox.expand())),
        ),
    ];
  }

  List<Widget> _device(M5SlGeo geo, M5SlDevice d) {
    final home = geo.deviceHome(d);
    final r = home.shift(_devDrag[d] ?? Offset.zero);
    final read = _run.read.contains(d);
    return [
      Positioned.fromRect(
        key: ValueKey('dev-${d.name}'),
        rect: r,
        child: Semantics(
          button: true,
          label: M5SearchlightLines.deviceLabel(d),
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _hints.missTap(),
            onLongPress: () => _readDevice(d),
            onPanUpdate: (e) => _dragDevice(d, e.delta),
            onPanEnd: (_) => _dropDevice(d),
            onPanCancel: () => _dropDevice(d),
            child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0x22000000), borderRadius: BorderRadius.circular(10)),
              child: CustomPaint(painter: M5SlDevicePainter(d)),
            ),
          ),
        ),
      ),
      if (read)
        Positioned(
          key: ValueKey('charge-${d.name}'),
          left: r.left - 8,
          top: r.top - 22,
          width: r.width + 16,
          child: IgnorePointer(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: _ChargeChip(pct: _run.charge(d))))),
        ),
    ];
  }

  List<Widget> _forkLayers(M5SlGeo geo) {
    return [
      Positioned.fill(
        key: const ValueKey('fork'),
        child: RepaintBoundary(child: CustomPaint(painter: M5SlForkPainter(geo: geo, fieldLeft: _run.deal.fieldLeft, seed: _seed))),
      ),
      _touch(
        child: GestureDetector(
          key: _touchKey,
          behavior: HitTestBehavior.opaque,
          onTapUp: (_) => _hints.missTap(),
        ),
      ),
      for (final left in [true, false])
        Positioned.fromRect(
          key: ValueKey('sign-${left ? 'l' : 'r'}'),
          rect: geo.sign(left),
          child: Builder(builder: (context) {
            final label = left == _run.deal.fieldLeft ? M5SearchlightLines.field : M5SearchlightLines.road;
            return Semantics(
              button: true,
              label: label,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _pickFork(left, d.globalPosition),
                child: _RoadSign(text: label, pointLeft: left),
              ),
            );
          }),
        ),
    ];
  }

  List<Widget> _patrolLayers(M5SlGeo geo) {
    final quiet = _quiet;
    final step = _run.station == M5SlStation.stepOut;
    final stepTop = step ? geo.poleTop(_run.deal.poles[_run.stepPole], _run.stepPole, _view.x) : Offset.zero;
    final head = geo.stepFigure.topCenter.translate(4, 14);
    return [
      Positioned.fill(
        key: const ValueKey('patrol'),
        child: RepaintBoundary(child: CustomPaint(painter: M5SlPatrolPainter(geo: geo, poles: _run.deal.poles, view: _view, seed: _seed))),
      ),
      if (!step)
        _touch(
          child: GestureDetector(
            key: _touchKey,
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _aimAt(d.localPosition),
            onPanStart: (d) => _aimAt(d.localPosition),
            onPanUpdate: (d) => _aimAt(d.localPosition),
            onLongPressStart: (d) => _pinAt(d.localPosition, d.globalPosition),
          ),
        )
      else
        _touch(
          child: GestureDetector(
            key: _touchKey,
            behavior: HitTestBehavior.opaque,
            onTapUp: (_) => _hints.missTap(),
          ),
        ),
      if (step)
        Positioned.fill(
          key: const ValueKey('beam'),
          child: IgnorePointer(
            child: _bite == _Bite.torch
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: quiet ? 1 : 0, end: 1),
                    duration: const Duration(milliseconds: 1400),
                    builder: (_, v, _) => CustomPaint(
                      painter: M5SlBeamPainter(
                        from: head,
                        to: Offset(stepTop.dx, geo.baseY(_run.deal.poles[_run.stepPole].side) - 30),
                        on: v >= 1 ? 0 : (math.sin(v * 40).abs() * (1 - v)),
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: M5SlBeamPainter(
                      from: head,
                      to: Offset(stepTop.dx, geo.baseY(_run.deal.poles[_run.stepPole].side) - 30),
                      on: _beamDead ? 0 : 1,
                    ),
                  ),
          ),
        ),
      if (step)
        Positioned.fromRect(
          key: const ValueKey('trainee'),
          rect: _freeze ? Rect.fromCenter(center: stepTop.translate(-14, 40), width: 40, height: 88) : geo.stepFigure,
          child: LinemanFigure(look: _traineeLook, mode: _mode, wake: _wake, quiet: quiet),
        ),
      if (_bite == _Bite.truck)
        Positioned.fill(
          key: ValueKey('truck-$_biteTok'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1300),
              builder: (_, v, _) => CustomPaint(painter: M5SlTruckPainter(geo: geo, v: v)),
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
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_biting && !_leaving && !_patrolEnding;
    final station = _run.station;
    if (_wantTick != _ticker.isActive) SchedulerBinding.instance.addPostFrameCallback((_) => _syncTicker());
    final probe = widget.probe;
    if (probe != null) {
      probe.speed = _speed;
      probe.halted = _halted;
    }
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
              labels: M5SearchlightLines.stations,
              done: {for (var i = 0; i < math.min(_run.index, 4); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !_overlayBusy,
            hintKey: switch (station) {
              M5SlStation.depot => 'depot-${_run.read.length}-${_run.swapped.length}-${_run.jacket}-${_run.seats.length}-${_run.docket}',
              M5SlStation.patrol => 'patrol-${_run.pinned.length}-${_view.lit != null && _view.resolved}',
              _ => '${station.name}-${_run.plateRead}',
            },
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && station == M5SlStation.depot)
                Positioned(
                  key: const ValueKey('hud-go'),
                  right: 18,
                  bottom: pad.bottom + 10,
                  child: _ToolButton(key: _goKey, icon: Icons.local_shipping_rounded, label: M5SearchlightLines.go, on: false, onTap: _depart),
                ),
              if (playing && station == M5SlStation.patrol && !_patrolEnding)
                Positioned(
                  key: const ValueKey('hud-lever'),
                  right: 6,
                  bottom: pad.bottom + 92,
                  child: _SpeedLever(key: _leverKey, value: _speed, enabled: handsOn && !tableBusy, onChanged: _setSpeed),
                ),
              if (handsOn && station == M5SlStation.stepOut)
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final t in _run.deal.tools)
                        _ToolButton(
                          key: _toolKeys[t],
                          icon: _icons[t]!,
                          label: M5SearchlightLines.toolLabel(t),
                          on: t == M5SlTool.binoculars && _run.plateRead,
                          onTap: (g) => _useTool(t, g),
                          onHold: t == M5SlTool.binoculars ? (g) => _useTool(t, g, held: true) : null,
                        ),
                    ],
                  ),
                ),
              if (_binoOn)
                Positioned.fill(
                  key: const ValueKey('bino'),
                  child: IgnorePointer(child: Center(child: _BinocularView(plate: M5SearchlightLines.plate(_run.deal.poles[_run.stepPole].plate)))),
                ),
              if (_phoneOn)
                Positioned.fill(
                  key: const ValueKey('phone-view'),
                  child: IgnorePointer(
                    child: Center(
                      child: _PhoneView(
                        dead: _phoneDead,
                        text: M5SearchlightLines.report(_run.deal.feeder, _run.deal.poles[_run.stepPole].plate),
                      ),
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
                  line: M5SearchlightLines.intro,
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
                        child: _run.passedLevel
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

  static const _icons = {
    M5SlTool.binoculars: Icons.visibility_rounded,
    M5SlTool.phone: Icons.phone_in_talk_rounded,
    M5SlTool.climb: Icons.north_rounded,
  };
}

// ============================================================================
// Pieces
// ============================================================================

/// The docket pinned on the board.
class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EEDC),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.15, color: const Color(0xFF2B2F36))),
    );
  }
}

/// A device's charge, shown once it has been held.
class _ChargeChip extends StatelessWidget {
  const _ChargeChip({required this.pct});
  final int pct;

  @override
  Widget build(BuildContext context) {
    final low = pct < m5SlLowCharge;
    final c = low ? const Color(0xFFE5483B) : SlmColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xEE101A2B), borderRadius: BorderRadius.circular(8), border: Border.all(color: c, width: 1.2)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: c, width: 1), borderRadius: BorderRadius.circular(2)),
              child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: (pct / 100).clamp(0.08, 1.0), child: ColoredBox(color: c)),
            ),
          ),
          const SizedBox(width: 3),
          Text(M5SearchlightLines.charge(pct), style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }
}

/// A road sign at the fork.
class _RoadSign extends StatelessWidget {
  const _RoadSign({required this.text, required this.pointLeft});
  final String text;
  final bool pointLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F5E3B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9EEF2), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          if (pointLeft) const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
          Expanded(
            child: Text(text,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: bangla(fontSize: 13, fontWeight: FontWeight.w800, height: 1.15, color: Colors.white)),
          ),
          if (!pointLeft) const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
        ],
      ),
    );
  }
}

/// The speed lever: three stops (জোরে on top, ধীরে, থামো at the bottom);
/// tap a stop or slide the knob.
class _SpeedLever extends StatelessWidget {
  const _SpeedLever({super.key, required this.value, required this.enabled, required this.onChanged});
  final M5SlSpeed value;
  final bool enabled;
  final ValueChanged<M5SlSpeed> onChanged;

  static const _order = [M5SlSpeed.fast, M5SlSpeed.slow, M5SlSpeed.stop];
  static const double _stop = 54;

  void _slide(Offset local) {
    final i = (local.dy / _stop).floor().clamp(0, 2);
    onChanged(_order[i]);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: enabled ? (d) => _slide(d.localPosition) : null,
      child: Container(
        width: 70,
        height: _stop * 3 + 12,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xCC0B1324),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x66FFE7A8), width: 1.4),
        ),
        child: Column(
          children: [
            for (final s in _order)
              Semantics(
                button: true,
                selected: s == value,
                label: M5SearchlightLines.speedLabel(s),
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: enabled ? () => onChanged(s) : null,
                  child: SizedBox(
                    height: _stop,
                    width: 70,
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: s == value ? const Color(0xFFE0A21B) : const Color(0x00000000),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: s == value ? const Color(0xFFFFE7A8) : const Color(0x44FFFFFF), width: 1.2),
                        ),
                        child: Text(M5SearchlightLines.speedLabel(s),
                            style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: s == value ? const Color(0xFF14171D) : SlmColors.ivory)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The binoculars' view of the pole plate.
class _BinocularView extends StatelessWidget {
  const _BinocularView({required this.plate});
  final String plate;

  @override
  Widget build(BuildContext context) {
    Widget lens() => Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0E1830),
            border: Border.all(color: const Color(0xFF14171D), width: 8),
          ),
        );
    return SizedBox(
      width: 236,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(left: 0, child: lens()),
          Positioned(right: 0, child: lens()),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFE2E6EC), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF59606C), width: 2)),
            child: Text(plate, style: bangla(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF14171D))),
          ),
        ],
      ),
    );
  }
}

/// The phone: the report to the control room (or a dead screen).
class _PhoneView extends StatelessWidget {
  const _PhoneView({required this.dead, required this.text});
  final bool dead;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dead ? const Color(0xFF050608) : const Color(0xFF16233B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF59606C), width: 3),
      ),
      child: dead
          ? Center(child: Text(M5SearchlightLines.charge(0), style: bangla(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFFE5483B))))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(M5SearchlightLines.control, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.gold300)),
                const SizedBox(height: 6),
                Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: SlmColors.success, size: 18),
                    const SizedBox(width: 4),
                    Text(M5SearchlightLines.sent, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: SlmColors.success)),
                  ],
                ),
              ],
            ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit once done.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTap, this.onHold});
  final IconData icon;
  final String label;
  final bool on;
  final ValueChanged<Offset> onTap;
  final ValueChanged<Offset>? onHold;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    final hold = onHold;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        onLongPressStart: hold == null ? null : (d) => hold(d.globalPosition),
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
