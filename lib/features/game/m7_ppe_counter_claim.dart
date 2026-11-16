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
import 'm7_ppe_counter_claim_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm7_ppe_counter_claim_world.dart'
    show M7Calendar, M7Claim, M7Docket, M7Item, M7Job, M7Look, M7Piece, M7PpeGeo, kM7PpeSkies, m7DeadlySign, m7FaultPool, m7GloveCuff, m7IsPrint, m7LookFits, m7RightClaim;

// Lesson 7.6 "ব্যক্তিগত সুরক্ষা সরঞ্জাম (PPE) সংক্রান্ত আইন", কাজ "কাউন্টারে দাবি"
// (pack do_7_6_a, rung 7.6/do/0, engineType m7_ppe_counter_claim). Dawn at the
// section store: the day's docket (an 11 kV pole job or an LT service-line pole
// job) lists the kit — হেলমেট · সেফটি জুতো · গ্লাভস · হারনেস. The storekeeper
// puts one item at a time on the mat. Tap it: a close-up tray shows every real
// marking at once (nothing circled); optionally drag it onto the trainee to see
// the fit (the only place a wrong size shows).
//
// The core verb: ink a legal claim on the issue register. One of six equal
// rubber stamps (positions shuffled, all six always on the stand) is dragged
// onto the item's ruled line and held ~0.6 s to ink:
//   'সই করে নিলাম'      the item is good (and nothing else is);
//   'বদলে দিন'           damaged or out-of-date (cracked helmet, split sole,
//                        torn glove, cut webbing, expired label);
//   'IS মার্ক চাই'       no IS mark or the wrong IS code (helmet IS 2925, shoes
//                        IS 15298);
//   'ঝুঁকি মতো রেটিং চাই' a glove that is not IS 4770 টাইপ 4 on an 11 kV job
//                        (the live lesson 7.6, X3; never '11 kV গ্লাভস');
//   'ঠিক সাইজ চাই'      wrong size (seen on the trainee only);
//   'আগে প্রশিক্ষণ চাই'  a new-type harness ('এই প্রথম এল').
// The right claim praises, puts ◆ on the table (the first of each claim kind a
// play opens the "কেন?" cards at once) and brings a replacement (a good one, or
// a second fault on the same line). Once a play the first right claim on a
// helmet, shoes or harness meets 'এটার স্টক এখন নেই।' (never gloves): that is the
// coworker's two-beat moment (the stamps wait for him); then the storekeeper
// finds one on the back shelf (dealt) or the item stays missing.
// After the four lines the docket's two stamps appear: 'কাজে যাচ্ছি' / 'PPE ছাড়া
// এই কাজ নয়' (drag + hold on the docket): a full valid kit goes; an item
// missing refuses.
//
// Deadly (module 7 table R10/R11, ruling M7-2/X3): signing for torn gloves or a
// lower-type glove on an 11 kV job, signing for a harness with cut webbing,
// 'কাজে যাচ্ছি' on an 11 kV job with the rated gloves missing (this last one is
// a guard in the rules: with the lesson's deal the gloves are never missing).
// Everything else is a slip (R12/R29/R30): signing for a cracked helmet, a split
// sole, an expired label, a missing/wrong IS mark, the wrong size, a new-type
// harness untrained; any claim on a good item; the wrong claim on a faulty
// one; going with a non-glove item missing; refusing with a full kit; listening
// to the coworker (his push is a market PPE: a slip, B1/X2). Three slips strike
// out. The claim on the wrong line springs back with no cost.
//
// Gesture hands (how, never what): with an item on the mat a tap on it, then a
// sweep over the six stamps, then (after a stamp was lifted) a hold ring on the
// current register line; with the tray open a sweep across the item and a
// generic downward drag nudge (try-on); at the docket a sweep over both stamps.
// Off during the intro, the storekeeper's speech, the coworker, praise, cards,
// freezes and results.

// ============================================================================
// Content
// ============================================================================

/// The eight "কেন?" questions.
enum M7Why { sign, replace, isMark, rating, size, training, refuse, go }

M7Why m7WhyOf(M7Claim c) => switch (c) {
      M7Claim.sign => M7Why.sign,
      M7Claim.replace => M7Why.replace,
      M7Claim.isMark => M7Why.isMark,
      M7Claim.rating => M7Why.rating,
      M7Claim.size => M7Why.size,
      M7Claim.training => M7Why.training,
    };

abstract final class M7PpeLines {
  static const title = 'কাউন্টারে দাবি';
  // DRAFT wording — owner (M6-12 / M7-10): every line below until the owner
  // gives the natural wording.
  static const intro = 'আজকের কাজের কিট নিন — আইনে যা আপনার পাওনা, ঠিক তাই নিন।';

  // The guide's task (tap him: the next of the pool, from the start).
  static const askLook = 'কাউন্টারে যা এল, দেখে নিন।';
  static const askWrite = 'রেজিস্টারে কী লিখবেন?';
  static const tapKit = 'ডকেটে কাজ আর কিটের তালিকা দেখে নিন।';
  static const askDocket = 'কিট মিলল? ডকেটে সিল দিন।';
  static const tasks = [askLook, askWrite, tapKit];
  static const docketTasks = [askDocket, tapKit];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The storekeeper (the guide's voice carries his lines).
  static const storeReplace = 'দাবি ঠিক — এই নিন, বদলে দিলাম।';
  static const storeNoStock = 'এটার স্টক এখন নেই।';
  static const storeFound = 'পিছনের তাক থেকে পেলাম — এই নিন।';
  static const storeNone = 'পিছনের তাকেও নেই।';

  // The register, the docket, the stamps (a worker's own words; English digits).
  static const registerWord = 'ইস্যু রেজিস্টার';
  static const docketWord = 'ডকেট';
  static const sceneLabel = 'সেকশন স্টোরের কাউন্টার';
  static const trayLabel = 'জিনিসটা কাছ থেকে';
  static const closeLabel = 'বন্ধ করুন';

  static String itemName(M7Item i) => switch (i) {
        M7Item.helmet => 'হেলমেট',
        M7Item.shoes => 'সেফটি জুতো',
        M7Item.gloves => 'গ্লাভস',
        M7Item.harness => 'হারনেস',
      };

  static String stampLabel(M7Claim c) => switch (c) {
        M7Claim.sign => 'সই করে নিলাম',
        M7Claim.replace => 'বদলে দিন',
        M7Claim.isMark => 'IS মার্ক চাই',
        M7Claim.rating => 'ঝুঁকি মতো রেটিং চাই',
        M7Claim.size => 'ঠিক সাইজ চাই',
        M7Claim.training => 'আগে প্রশিক্ষণ চাই',
      };

  static String docketStamp(M7Docket d) => switch (d) {
        M7Docket.go => 'কাজে যাচ্ছি',
        M7Docket.refuse => 'PPE ছাড়া এই কাজ নয়',
      };

  static String jobLine(M7Job j) => switch (j) {
        M7Job.kv11 => '11 kV লাইনের কাজ · পোলে ওঠা',
        M7Job.lt => 'LT সার্ভিস লাইন · পোলে ওঠা',
      };

  /// The docket's kit list (11 kV jobs: the type-4 glove).
  static List<String> kitList(M7Job j) => [
        itemName(M7Item.helmet),
        itemName(M7Item.shoes),
        j == M7Job.kv11 ? '${itemName(M7Item.gloves)} · IS 4770 · টাইপ 4' : itemName(M7Item.gloves),
        itemName(M7Item.harness),
      ];

  // The reasons (the right ones state the lesson's rule; the wrong ones are
  // myths and field excuses).
  static String whyQ(M7Why w) => switch (w) {
        M7Why.sign => 'কেন সই করে নিলেন?',
        M7Why.replace => 'কেন বদলে দিতে বললেন?',
        M7Why.isMark => 'কেন IS মার্ক চাইলেন?',
        M7Why.rating => 'কেন ঝুঁকি মতো রেটিং চাইলেন?',
        M7Why.size => 'কেন ঠিক সাইজ চাইলেন?',
        M7Why.training => 'কেন আগে প্রশিক্ষণ চাইলেন?',
        M7Why.refuse => 'কেন আজ এই কাজে গেলেন না?',
        M7Why.go => 'কেন কাজে গেলেন?',
      };

  static const whyRight = <M7Why, List<String>>{
    M7Why.sign: ['মার্ক, মাপ আর অবস্থা — সব মিলেছে, তাই সই করলাম', 'দেখেমিলিয়ে ঠিক পেলে তবেই সই করে নিতে হয়, নইলে নয়'],
    M7Why.replace: ['ক্ষতিগ্রস্ত বা মেয়াদ শেষ PPE বদলানো কোম্পানির দায়িত্ব', 'নষ্ট বা মেয়াদ পেরোনো PPE বদলে দেওয়ার দাবি করা যায়'],
    M7Why.isMark: ['IS মার্ক ছাড়া সরঞ্জামের মান নিশ্চিত করা যায় না', 'হেলমেটে IS 2925, সেফটি জুতোয় IS 15298 থাকতে হয়'],
    M7Why.rating: ['কাজের ঝুঁকি অনুযায়ী সঠিক PPE দেওয়া কোম্পানির দায়িত্ব', '11 kV লাইনের কাজে চাই IS 4770 টাইপ 4 গ্লাভস, কম নয়'],
    M7Why.size: ['ভুল সাইজের PPE সুরক্ষার বদলে অসুবিধার কারণ হয়', 'জুতো, গ্লাভস, হারনেস ঠিক সাইজের হওয়া অত্যন্ত জরুরি'],
    M7Why.training: ['নতুন ধরনের PPE ব্যবহারের আগে প্রশিক্ষণ চাওয়া অধিকার', 'নতুন PPE পরার আগে ঠিকমতো ব্যবহার শিখে নেওয়াই নিয়ম'],
    M7Why.refuse: ['সঠিক PPE না থাকলে কাজ অস্বীকার করার পূর্ণ অধিকার আছে', 'জীবন সবচেয়ে মূল্যবান — PPE ছাড়া ঝুঁকির কাজে যাব না'],
    M7Why.go: ['সব PPE আইনমতো ঠিক পেয়েছি, তাই কাজে যেতে বাধা নেই', 'মান, মাপ আর অবস্থা ঠিক — পুরো কিট নিয়েই কাজে যাচ্ছি'],
  };

  /// The myths and excuses shared by every question.
  static const myths = [
    'আমি অভিজ্ঞ লোক, আমার PPE লাগে না — ওটা নতুনদের জন্য',
    'বাজারের সস্তা PPE-তেও একই সুরক্ষা মেলে, চলে যাবে',
    'দাবি করলে সবাই বিরক্ত হবে, চুপচাপ নিয়ে নেওয়াই ভালো',
    'দেরি হয়ে যাচ্ছে, কাজ আগে শুরু হোক, পরে দেখা যাবে',
    'স্টোরের লোক যা দিয়েছে সেটাই ঠিক, প্রশ্ন করার কী আছে',
  ];
  static const _wrongBy = <M7Why, List<String>>{
    M7Why.sign: ['সই করলে রেজিস্টারে থাকবে, পরে ঠিক বদলে দেবে ওরা', 'কাউন্টারের জিনিস আবার দেখার কিছু নেই, সই করলেই কাজ শেষ'],
    M7Why.replace: ['একটু ছেঁড়াফাটা থাকলেও চলে, কাজের তাড়া আছে', 'নতুন জিনিস চাইলে তা নিজের টাকায় কিনে নিতে হবে'],
    M7Why.isMark: ['মার্কে কী আসে যায়, দেখতে ঠিকঠাক থাকলেই কাজ চলে', 'IS মার্ক শুধু দামি জিনিসে থাকে, সস্তায় লাগে না'],
    M7Why.rating: ['গ্লাভস তো গ্লাভসই, রেটিং যাই হোক সুরক্ষা সমান', 'যেকোনো রাবারের গ্লাভসেই 11 kV লাইনে কাজ চলে যায়'],
    M7Why.size: ['সাইজ একটু বড়-ছোট হলে অভ্যেস হয়ে যাবে পরে, চলবে', 'ঢিলে হলেও সুরক্ষা সমান, সাইজ নিয়ে ভাবার কিছু নেই'],
    M7Why.training: ['হারনেস সবই এক রকম, বাঁধার আবার শেখার কী আছে বলুন', 'প্রশিক্ষণে কাজের সময় নষ্ট, নিজেই বুঝে নেব আমি'],
    M7Why.refuse: ['আমি না গেলে অন্য কেউ যাবে, আমার কী আসে যায় বলুন', 'সবাই PPE ছাড়াই কাজে যায়, আমি আলাদা কেন হব বলুন'],
    M7Why.go: ['একটা PPE না পেলেও চলবে, এই কাজটা তো খুবই জরুরি', 'না গেলে সুপারভাইজার খুব রেগে যাবেন, তাই চললাম'],
  };

  /// The wrong reasons for a question (≥ 5: its own excuses + the myths).
  static List<String> whyWrong(M7Why w) => [..._wrongBy[w]!, ...myths];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];
  static List<String> get allWhyWrong => [for (final l in _wrongBy.values) ...l, ...myths];

  // The careless coworker: lesson 7.6 myth 1 (M7-10), after "no stock".
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'কোম্পানি ভালো PPE দেয় না, তাই আমি বাজার থেকে সস্তার একটা কিনে ব্যবহার করি। তুইও কিনে নে।',
    exitLine: coworkerExit,
    right: [
      'না — কোম্পানির কাছে রিপোর্ট করব, সস্তা জিনিস নয়।',
      'বাজারি সস্তা PPE আসল সুরক্ষা দেয় না, রিপোর্ট করব।',
      'না, সার্টিফায়েড PPE-ই চাই, না পেলে জানাব।',
    ],
    wrong: [
      'হ্যাঁ, বাজারের একটা দিয়েই আজ চালিয়ে নিই।',
      'দাম কম হলেও দেখতে তো একই রকম, চলে যাবে।',
      'ঠিক বলেছিস, রিপোর্টে লাভ নেই, কিনেই নিই।',
      'আচ্ছা, কাউন্টারের ঝামেলা ছেড়ে বাজারেই যাই।',
      'সস্তায় ক্ষতি কী, আমিও একটা বাজার থেকে কিনে নিই।',
    ],
    asks: ['ওর কথা শুনবেন?', 'কী করবেন?', 'ওর কথা শুনবেন, না আইন?'],
  );
  static const callHeld = 'ঠিক! কোম্পানি ঠিক PPE না দিলে রিপোর্ট করুন, বাজারের সস্তা জিনিস নয়।';

  static const allSet = 'কাউন্টারে সব দাবি আদায় — কিট ঠিক, কাজে রওনা!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে ভালো করে দেখে নিন, তারপর রেজিস্টারে লিখুন।';

  // "আজ যা ধরলেন".
  static String caughtClaim(M7Item i, M7Claim c) => '${itemName(i)}: ${stampLabel(c)}';
  static const caughtGo = 'কাজে গেছেন — কিট ঠিকঠাক';
  static const caughtRefuse = 'PPE ছাড়া কাজে যাননি';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Lines spoken here that already have a clip (the exit, an old ask, the
  /// quick-pass line).
  static const reused = {coworkerExit, 'কী করবেন?', quick};

  /// The coworker's new lines (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworker.line];

  static const storekeeperLines = [storeReplace, storeNoStock, storeFound, storeNone];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        askDocket,
        ...storekeeperLines,
        for (final w in M7Why.values) whyQ(w),
        ...coworker.asks.where((a) => !reused.contains(a)),
        callHeld,
        allSet,
        fail,
        for (final m in M7PpeMistakes.all) m.textBn,
      ];

  /// Every line the level speaks (guide, storekeeper and coworker).
  static List<String> get spokenLines => [...newGuideLines, ...newRivalLines, ...reused, ...tapWhy, ...docketTasks];
}

abstract final class M7PpeMistakes {
  static const _dir = 'assets/game/art/m7_ppe_counter_claim';

  // Lesson 7.6 points (0-based): 0 the employer's duty (right PPE, replace
  // damaged or expired, training), 1 the worker's duty, 2 the IS standards.
  static const _duty = 0;
  static const _standard = 2;

  // --- deadly (R10 / R11, M7-2 / X3) ------------------------------------------
  // DRAFT wording — owner (M6-12).
  static const signTornGloves = DoMistake(
    key: '7.6/m7_ppe_counter_claim/sign-torn-gloves',
    textBn: 'ছেঁড়া গ্লাভস সই করে নিলেন! এই গ্লাভস কারেন্ট আটকাবে না। ক্ষতিগ্রস্ত PPE বদলে দেওয়া কোম্পানির আইনি দায়িত্ব — “বদলে দিন” লিখুন।',
    art: '$_dir/gloves_torn.svg',
    deadly: true,
    lessonPoint: _duty,
  );
  static const signLowGloves = DoMistake(
    key: '7.6/m7_ppe_counter_claim/sign-low-gloves',
    textBn: 'এই গ্লাভস 11 kV কাজের জন্য নয়! 11 kV লাইনের জন্য চাই IS 4770 টাইপ 4 গ্লাভস, যা 17,000 ভোল্ট পর্যন্ত কাজের জন্য তৈরি।',
    art: '$_dir/gloves_low.svg',
    deadly: true,
    lessonPoint: _duty,
  );
  static const signCutHarness = DoMistake(
    key: '7.6/m7_ppe_counter_claim/sign-cut-harness',
    textBn: 'কাটা বেল্টের হারনেস সই করে নিলেন! পোলে উঠলে ছিঁড়ে পড়তে পারেন। ক্ষতিগ্রস্ত PPE বদলে দেওয়ার দাবি করুন।',
    art: '$_dir/harness_cut.svg',
    deadly: true,
    lessonPoint: _duty,
  );
  static const goNoGloves = DoMistake(
    key: '7.6/m7_ppe_counter_claim/go-no-gloves',
    textBn: '11 kV লাইনের কাজে IS 4770 টাইপ 4 গ্লাভস ছাড়াই রওনা দিলেন! সঠিক PPE না থাকলে কাজ করতে অস্বীকার করার পূর্ণ অধিকার আপনার আছে।',
    art: '$_dir/docket.svg',
    deadly: true,
    lessonPoint: _duty,
  );

  // --- slips: signed for a faulty item (R12) ------------------------------------
  static const signCrackedHelmet = DoMistake(
    key: '7.6/m7_ppe_counter_claim/sign-cracked-helmet',
    textBn: 'ফাটা হেলমেট সই করে নিলেন। ক্ষতিগ্রস্ত PPE বদলে দেওয়ার ব্যবস্থা করা কোম্পানির আইনি দায়িত্ব।',
    art: '$_dir/helmet_cracked.svg',
    lessonPoint: _duty,
  );
  static const signSplitShoes = DoMistake(
    key: '7.6/m7_ppe_counter_claim/sign-split-shoes',
    textBn: 'সোল ফেটে আলাদা হওয়া জুতো সই করে নিলেন। ক্ষতিগ্রস্ত PPE বদলে দিতে বলুন।',
    art: '$_dir/shoe_split.svg',
    lessonPoint: _duty,
  );
  static const signExpiredHarness = DoMistake(
    key: '7.6/m7_ppe_counter_claim/sign-expired-harness',
    textBn: 'হারনেসের লেবেলে মেয়াদ শেষ — দেয়ালের ক্যালেন্ডারের তারিখের সঙ্গে মিলিয়ে দেখুন। মেয়াদ উত্তীর্ণ PPE বদলে দেওয়া কোম্পানির দায়িত্ব।',
    art: '$_dir/harness_expired.svg',
    lessonPoint: _duty,
  );
  static const signNoIsHelmet = DoMistake(
    key: '7.6/m7_ppe_counter_claim/sign-no-is-helmet',
    textBn: 'হেলমেটে IS মার্ক নেই। সেফটি হেলমেটের জন্য IS 2925 — মার্ক দেখে তবে নিন।',
    art: '$_dir/helmet_nois.svg',
    lessonPoint: _standard,
  );
  static const signNoIsShoes = DoMistake(
    key: '7.6/m7_ppe_counter_claim/sign-no-is-shoes',
    textBn: 'জুতোয় IS মার্ক নেই। সেফটি জুতোর জন্য IS 15298 — মার্ক দেখে তবে নিন।',
    art: '$_dir/shoe_nois.svg',
    lessonPoint: _standard,
  );
  static const signWrongIsHelmet = DoMistake(
    key: '7.6/m7_ppe_counter_claim/sign-wrong-is-helmet',
    textBn: 'এই হেলমেটে IS 15298 লেখা — ওটা সেফটি জুতোর কোড। সেফটি হেলমেটের জন্য IS 2925।',
    art: '$_dir/helmet_nois.svg',
    lessonPoint: _standard,
  );
  static const signWrongIsShoes = DoMistake(
    key: '7.6/m7_ppe_counter_claim/sign-wrong-is-shoes',
    textBn: 'এই জুতোয় IS 2925 লেখা — ওটা হেলমেটের কোড। সেফটি জুতোর জন্য IS 15298।',
    art: '$_dir/shoe_nois.svg',
    lessonPoint: _standard,
  );
  static const signWrongSize = DoMistake(
    key: '7.6/m7_ppe_counter_claim/sign-wrong-size',
    textBn: 'ভুল সাইজের PPE সুরক্ষার বদলে অসুবিধার কারণ হতে পারে। গায়ে লাগিয়ে দেখে ঠিক সাইজ চেয়ে নিন।',
    art: '$_dir/size.svg',
  );
  static const signNewHarness = DoMistake(
    key: '7.6/m7_ppe_counter_claim/sign-new-harness',
    textBn: 'নতুন ধরনের হারনেস ব্যবহারের আগে সঠিক প্রশিক্ষণের দাবি জানান। এটা আপনার অধিকার।',
    art: '$_dir/harness_new.svg',
    lessonPoint: _duty,
  );

  // --- slips: the wrong claim, a needless claim (R12 / R29) --------------------
  /// The wrong claim on a faulty item: only this line (no hint at the fault).
  static const wrongClaim = DoMistake(
    key: '7.6/m7_ppe_counter_claim/wrong-claim',
    textBn: 'এটা তো সেই সমস্যা নয়।',
    art: '$_dir/claim.svg',
  );
  static const needlessHelmet = DoMistake(
    key: '7.6/m7_ppe_counter_claim/needless-helmet',
    textBn: 'এই হেলমেট ঠিকই ছিল — IS 2925 মার্ক আছে, ফাটা নেই, মাপও ঠিক। দেখে নিয়ে তবে দাবি করুন।',
    art: '$_dir/counter_ok.svg',
    lessonPoint: _standard,
  );
  static const needlessShoes = DoMistake(
    key: '7.6/m7_ppe_counter_claim/needless-shoes',
    textBn: 'এই জুতো ঠিকই ছিল — IS 15298 মার্ক আছে, সোল ঠিক, মাপও ঠিক। দেখে নিয়ে তবে দাবি করুন।',
    art: '$_dir/counter_ok.svg',
    lessonPoint: _standard,
  );
  static const needlessGloves = DoMistake(
    key: '7.6/m7_ppe_counter_claim/needless-gloves',
    textBn: 'এই গ্লাভস ঠিকই ছিল — রেটিং মিলছে, ছেঁড়া নেই। দেখে নিয়ে তবে দাবি করুন।',
    art: '$_dir/counter_ok.svg',
    lessonPoint: _duty,
  );
  static const needlessHarness = DoMistake(
    key: '7.6/m7_ppe_counter_claim/needless-harness',
    textBn: 'এই হারনেস ঠিকই ছিল — বেল্ট অক্ষত, লেবেলের মেয়াদ আছে। দেখে নিয়ে তবে দাবি করুন।',
    art: '$_dir/counter_ok.svg',
    lessonPoint: _duty,
  );

  // --- the docket (R12 / R29) ---------------------------------------------------
  static const goMissing = DoMistake(
    key: '7.6/m7_ppe_counter_claim/go-missing',
    textBn: 'একটা PPE এখনও মেলেনি — তবু কাজে রওনা দিলেন। সঠিক PPE না থাকলে কাজ করতে অস্বীকার করার পূর্ণ অধিকার আছে।',
    art: '$_dir/docket.svg',
  );
  static const refuseFull = DoMistake(
    key: '7.6/m7_ppe_counter_claim/refuse-full',
    textBn: 'কিট পুরো আর ঠিকঠাক ছিল — তবু কাজে গেলেন না। অস্বীকার করার অধিকার তখনই, যখন সঠিক PPE নেই।',
    art: '$_dir/docket.svg',
  );

  // --- listening to the coworker (lesson 7.6 myth 1 and its reality; R30, B1) ---
  static const pushListen = DoMistake(
    key: '7.6/m7_ppe_counter_claim/push-listen',
    textBn: 'বাজারের সস্তা, সার্টিফিকেট ছাড়া PPE আসল সুরক্ষা দেয় না, সুরক্ষার মিথ্যা আশ্বাস দেয় মাত্র। কোম্পানি ঠিক PPE না দিলে কর্তৃপক্ষকে রিপোর্ট করুন।',
    art: '$_dir/market.svg',
  );

  /// Signing for a faulty [look] on [item]: its mistake (a deadly one for a
  /// torn or lower-type glove, cut webbing).
  static DoMistake sign(M7Item item, M7Look look) => switch (look) {
        M7Look.torn => signTornGloves,
        M7Look.lowType => signLowGloves,
        M7Look.cutWebbing => signCutHarness,
        M7Look.cracked => signCrackedHelmet,
        M7Look.splitSole => signSplitShoes,
        M7Look.expired => signExpiredHarness,
        M7Look.noIs => item == M7Item.helmet ? signNoIsHelmet : signNoIsShoes,
        M7Look.wrongIs => item == M7Item.helmet ? signWrongIsHelmet : signWrongIsShoes,
        M7Look.wrongSize => signWrongSize,
        M7Look.newType => signNewHarness,
        M7Look.ok => throw ArgumentError('signing for a good item is not a mistake'),
      };

  static DoMistake needless(M7Item i) => switch (i) {
        M7Item.helmet => needlessHelmet,
        M7Item.shoes => needlessShoes,
        M7Item.gloves => needlessGloves,
        M7Item.harness => needlessHarness,
      };

  static const List<DoMistake> all = [
    signTornGloves,
    signLowGloves,
    signCutHarness,
    goNoGloves,
    signCrackedHelmet,
    signSplitShoes,
    signExpiredHarness,
    signNoIsHelmet,
    signNoIsShoes,
    signWrongIsHelmet,
    signWrongIsShoes,
    signWrongSize,
    signNewHarness,
    wrongClaim,
    needlessHelmet,
    needlessShoes,
    needlessGloves,
    needlessHarness,
    goMissing,
    refuseFull,
    pushListen,
  ];
}

// ============================================================================
// Deal and rules
// ============================================================================

@immutable
class M7PpeDeal {
  const M7PpeDeal({
    required this.job,
    required this.order,
    required this.chains,
    required this.stockItem,
    required this.found,
    required this.stampOrder,
    required this.docketSwap,
    required this.calendar,
    required this.light,
  });

  final M7Job job;

  /// The four items in the order the storekeeper brings them.
  final List<M7Item> order;

  /// Per item: what comes on the mat in turn (the first one, then each
  /// replacement a right claim brings). The stock item has only its first.
  final Map<M7Item, List<M7Piece>> chains;

  /// The helmet, shoes or harness that is out of stock after its first right
  /// claim (never gloves).
  final M7Item stockItem;

  /// What the storekeeper finds on the back shelf (null = nothing).
  final M7Piece? found;

  /// The six stamps' places on the stand (all six, shuffled).
  final List<M7Claim> stampOrder;

  /// The docket stamps swapped.
  final bool docketSwap;

  final M7Calendar calendar;
  final int light;

  List<M7Docket> get docketOrder => docketSwap ? const [M7Docket.refuse, M7Docket.go] : const [M7Docket.go, M7Docket.refuse];

  /// The faulty items.
  List<M7Item> get faulty => [for (final i in M7Item.values) if (chains[i]!.first.look != M7Look.ok) i];
}

M7PpeDeal m7PpeDeal(math.Random rng) {
  final job = rng.nextBool() ? M7Job.kv11 : M7Job.lt;
  final order = [...M7Item.values]..shuffle(rng);
  final cand = [for (final i in M7Item.values) if (m7FaultPool(i, job).isNotEmpty) i]..shuffle(rng);
  // 2–3 faulty items, never all four (a good item every play).
  final faulty = cand.take(math.min(2 + rng.nextInt(2), cand.length)).toSet();
  final stock = (faulty.where((i) => i != M7Item.gloves).toList()..shuffle(rng)).first;
  var n = 0;
  final cal = M7Calendar(day: 1 + rng.nextInt(28), month: 1 + rng.nextInt(12), year: 2026 + rng.nextInt(2));
  M7Piece piece(M7Item i, M7Look l) => M7Piece(
        id: n++,
        item: i,
        look: l,
        labelMonths: i == M7Item.harness && l == M7Look.expired ? -(2 + rng.nextInt(7)) : 3 + rng.nextInt(12),
        tint: rng.nextInt(3),
        big: rng.nextBool(),
      );
  final chains = <M7Item, List<M7Piece>>{};
  for (final i in M7Item.values) {
    if (!faulty.contains(i)) {
      chains[i] = [piece(i, M7Look.ok)];
      continue;
    }
    final pool = m7FaultPool(i, job);
    final first = pool[rng.nextInt(pool.length)];
    final chain = [piece(i, first)];
    if (i != stock) {
      // A replacement: good, or (3 in 10) a second fault, then a good one.
      if (pool.length > 1 && rng.nextInt(10) < 3) {
        final other = [for (final l in pool) if (l != first) l];
        chain.add(piece(i, other[rng.nextInt(other.length)]));
      }
      chain.add(piece(i, M7Look.ok));
    }
    chains[i] = chain;
  }
  return M7PpeDeal(
    job: job,
    order: order,
    chains: chains,
    stockItem: stock,
    found: rng.nextBool() ? piece(stock, M7Look.ok) : null,
    stampOrder: [...M7Claim.values]..shuffle(rng),
    docketSwap: rng.nextBool(),
    calendar: cal,
    light: rng.nextInt(kM7PpeSkies.length),
  );
}

/// What a stamp did.
enum M7Res { signed, replaced, stockOut, slip, deadly, already }

/// The play state (pure logic).
class M7PpeRun {
  M7PpeRun(this.deal) {
    for (final i in M7Item.values) {
      _pos[i] = 0;
      _cur[i] = deal.chains[i]!.first;
    }
  }
  final M7PpeDeal deal;

  /// The line being worked (0..3 in [M7PpeDeal.order]); 4 = the docket.
  int index = 0;
  int slips = 0;
  DoMistake? deadly;
  bool docketDone = false;
  bool stockHappened = false;

  /// The stock event waits for the coworker and the storekeeper's search.
  bool awaitingStock = false;

  final Map<M7Item, int> _pos = {};
  final Map<M7Item, M7Piece?> _cur = {};

  /// Items settled for good (signed good, or missing).
  final Set<M7Item> resolved = {};

  /// Items whose kit slot is empty (not found).
  final Set<M7Item> missing = {};

  /// The claims inked on each register line, in order.
  final Map<M7Item, List<M7Claim>> marks = {for (final i in M7Item.values) i: []};

  /// The reasons already asked this play.
  final Set<M7Why> asked = {};
  final List<String> caught = [];

  bool get atDocket => index >= deal.order.length;
  bool get done => docketDone;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// The item whose line is open (null at the docket).
  M7Item? get item => atDocket ? null : deal.order[index];

  /// The piece on the mat (null while nothing is there).
  M7Piece? get piece => item == null || awaitingStock ? null : _cur[item];

  /// Does the kit hold a valid [i] (a good one signed for)?
  bool kitHas(M7Item i) => resolved.contains(i) && !missing.contains(i);

  bool get glovesOk => kitHas(M7Item.gloves);

  DoMistake _slip(DoMistake m) {
    slips++;
    return m;
  }

  /// A stamp inked on the open line.
  (M7Res, DoMistake?) claim(M7Claim c) {
    final it = item;
    final p = piece;
    if (ended || it == null || p == null) return (M7Res.already, null);
    marks[it]!.add(c);
    if (c == M7Claim.sign) {
      if (p.look == M7Look.ok) {
        resolved.add(it);
        _note(it, c);
        return (M7Res.signed, null);
      }
      final m = M7PpeMistakes.sign(it, p.look);
      if (m.deadly) {
        deadly = m;
        return (M7Res.deadly, m);
      }
      return (M7Res.slip, _slip(m));
    }
    if (p.look == M7Look.ok) return (M7Res.slip, _slip(M7PpeMistakes.needless(it)));
    if (c != m7RightClaim(p.look)) return (M7Res.slip, _slip(M7PpeMistakes.wrongClaim));
    // The right claim.
    _note(it, c);
    if (it == deal.stockItem && !stockHappened) {
      stockHappened = true;
      awaitingStock = true;
      return (M7Res.stockOut, null);
    }
    _pos[it] = _pos[it]! + 1;
    _cur[it] = deal.chains[it]![_pos[it]!];
    return (M7Res.replaced, null);
  }

  void _note(M7Item i, M7Claim c) => caught.add(M7PpeLines.caughtClaim(i, c));

  /// The storekeeper's search is over: true = he found one (now on the mat).
  bool stockOutcome() {
    awaitingStock = false;
    final it = deal.stockItem;
    final f = deal.found;
    if (f != null) {
      _cur[it] = f;
      return true;
    }
    _cur[it] = null;
    missing.add(it);
    resolved.add(it);
    return false;
  }

  /// The open line is settled (signed good, or missing): the next item.
  bool get lineSettled => item != null && resolved.contains(item);

  void next() {
    index++;
  }

  /// Items missing from the kit.
  bool get anyMissing => missing.isNotEmpty;

  /// A docket stamp.
  (M7Res, DoMistake?) docket(M7Docket d) {
    if (ended || !atDocket) return (M7Res.already, null);
    if (d == M7Docket.go) {
      if (deal.job == M7Job.kv11 && !glovesOk) {
        deadly = M7PpeMistakes.goNoGloves;
        return (M7Res.deadly, deadly);
      }
      if (anyMissing) return (M7Res.slip, _slip(M7PpeMistakes.goMissing));
      caught.add(M7PpeLines.caughtGo);
      return (M7Res.signed, null);
    }
    if (!anyMissing && !(deal.job == M7Job.kv11 && !glovesOk)) return (M7Res.slip, _slip(M7PpeMistakes.refuseFull));
    caught.add(M7PpeLines.caughtRefuse);
    return (M7Res.signed, null);
  }

  /// The docket decision stood: the play is over.
  void finishDocket() => docketDone = true;

  /// The reason is due the first time each question comes up in a play.
  bool reasonDue(M7Why w) => asked.add(w);

  /// Listened to the coworker.
  DoMistake pushSlip() => _slip(M7PpeMistakes.pushListen);

  /// Test hook: set the kit at the docket directly.
  @visibleForTesting
  void debugAtDocket({Set<M7Item> good = const {}, Set<M7Item> gone = const {}}) {
    index = deal.order.length;
    resolved
      ..clear()
      ..addAll(good)
      ..addAll(gone);
    missing
      ..clear()
      ..addAll(gone);
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   per item: the arrival 1200, a look in the tray 3000, a claim (lift,
///     drag, hold) 3200, a replacement ~ 3 × (1200 + 3000 + 3200) shared ≈ 7500
///     → 4 items ≈ 4 × 7400 ≈ 30000, + 2.3 replacements ≈ 17000
///   + a reason for each claim kind (~4.5 × 8200)                  ≈ 37000
///   + the stock event, the coworker                               ≈ 12000
///   + the docket and its reason                                   ≈ 12000
///                                                                 ≈ 108000
/// 85 % ≈ 92000 → 90 s (a builder's estimate; owner may tune after playtest).
const m7PpeQuickMs = 90000;

@immutable
class M7PpePack {
  const M7PpePack({required this.id, required this.titleBn, this.quickMs = m7PpeQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7PpePack> m7PpePacks = {
  'do_7_6_a': M7PpePack(id: 'do_7_6_a', titleBn: M7PpeLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M7PpeProbe {
  static M7PpeRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M7PpeCounterClaimPage extends StatefulWidget {
  const M7PpeCounterClaimPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7PpePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7PpeCounterClaimPage> createState() => _M7PpeCounterClaimPageState();
}

class _M7PpeCounterClaimPageState extends State<M7PpeCounterClaimPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PpeRunPage(
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

class _PpeRunPage extends ConsumerStatefulWidget {
  const _PpeRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7PpePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PpeRunPage> createState() => _PpeRunPageState();
}

class _PpeRunPageState extends ConsumerState<_PpeRunPage> with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7PpeRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  VoidCallback? _afterCards;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  var _freeze = false;
  Completer<void>? _frozen;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  int _taskN = 0;
  int _whyN = 0;
  int _steps = 0;

  /// A piece is sliding onto the mat.
  var _arriving = false;
  int _arrivalN = 0;
  Timer? _arriveTimer;

  /// The close-up tray is open; a try-on drag from it; the try-on shown.
  var _tray = false;
  var _tryDrag = false;
  Offset _tryAt = Offset.zero;
  M7Piece? _tryOn;
  Timer? _tryTimer;

  /// A stamp in hand (its slot), where its pin is (design px), the hold on the
  /// target.
  int? _drag;
  Offset _dragAt = Offset.zero;
  Timer? _holdTimer;
  var _holding = false;
  int _holdN = 0;
  var _stampTried = false;

  /// What a right move will do once its reason is paid.
  VoidCallback? _afterReason;
  var _askedWrite = false;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _hintN = 0;
  M7PpeGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M7PpeRun(m7PpeDeal(widget.rng));
    M7PpeProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M7PpeDeal get _deal => _run.deal;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _holdTimer?.cancel();
    _tryTimer?.cancel();
    _arriveTimer?.cancel();
    if (identical(M7PpeProbe.run, _run)) M7PpeProbe.run = null;
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
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_freeze && !_arriving && !_run.ended && !struckOut;

  bool get _docketPhase => _run.atDocket;

  /// The item sits on the mat and the player may work on it.
  bool get _itemUp => _run.piece != null && !_run.awaitingStock;

  List<String> get _taskPool => _docketPhase ? M7PpeLines.docketTasks : M7PpeLines.tasks;
  String get _task => _docketPhase ? M7PpeLines.askDocket : (_askedWrite ? M7PpeLines.askWrite : M7PpeLines.askLook);

  Future<void> _start() async {
    _clock.start();
    _arrive(first: true);
  }

  /// The storekeeper puts the line's piece on the mat.
  void _arrive({bool first = false, List<String> before = const []}) {
    _askedWrite = false;
    _hintN = 0;
    _stampTried = false;
    _arriveTimer?.cancel();
    setState(() {
      _arrivalN++;
      _arriving = !_quiet;
      _tray = false;
      _drag = null;
      _wake++;
    });
    if (!_quiet) _arriveTimer = Timer(const Duration(milliseconds: 950), _arrived);
    unawaited(_sayChain([...before, M7PpeLines.askLook]));
  }

  void _arrived() {
    if (!mounted || !_arriving) return;
    setState(() => _arriving = false);
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  // --- hands on -----------------------------------------------------------------
  void _openTray() {
    if (!_canPlay || !_itemUp) return;
    _tick();
    setState(() {
      _tray = true;
      _hintN = 0;
    });
  }

  void _closeTray() {
    if (!_tray) return;
    _tick();
    setState(() {
      _tray = false;
      _tryDrag = false;
      _hintN = 0;
    });
    if (!_askedWrite && _itemUp) {
      _askedWrite = true;
      unawaited(_sayChain([M7PpeLines.askWrite]));
    }
  }

  void _tapScene(Offset p, M7PpeGeo geo) {
    if (!_canPlay) return;
    if (_tray) {
      if (geo.trayClose.contains(p) || !geo.tray.contains(p)) {
        _closeTray();
      }
      return;
    }
    if (_itemUp && geo.mat.inflate(4).contains(p)) {
      _openTray();
      return;
    }
    _hints.missTap();
  }

  void _panStart(Offset p, M7PpeGeo geo) {
    _drag = null;
    _tryDrag = false;
    if (!_canPlay) return;
    if (_tray && geo.trayArt.contains(p)) {
      _tick('sounds/intro/click.ogg', 0.4);
      setState(() {
        _tryDrag = true;
        _tryAt = p;
      });
      return;
    }
    final slot = geo.stampAt(p, docketPhase: _docketPhase);
    if (slot == null) return;
    // The stamps wait for him (his two-beat moment).
    if (holdForCoworker()) return;
    _tick('sounds/intro/click.ogg', 0.4);
    _stampTried = true;
    setState(() {
      _tray = false;
      _drag = slot;
      _dragAt = p.translate(0, -M7PpeGeo.lift);
    });
  }

  bool _onTarget(Offset pin, M7PpeGeo geo) => _docketPhase ? geo.docket.inflate(10).contains(pin) : geo.lineAt(pin) == _run.index;

  void _panUpdate(Offset p) {
    final geo = _geoNow;
    if (_tryDrag) {
      if (!_canPlay) {
        setState(() => _tryDrag = false);
        return;
      }
      setState(() => _tryAt = p);
      return;
    }
    if (_drag == null || geo == null) return;
    if (!_canPlay) {
      _cancelHold();
      setState(() => _drag = null);
      return;
    }
    final pin = p.translate(0, -M7PpeGeo.lift);
    final on = _onTarget(pin, geo);
    setState(() => _dragAt = pin);
    if (on && _holdTimer == null) {
      setState(() {
        _holding = true;
        _holdN++;
      });
      _holdTimer = Timer(const Duration(milliseconds: M7PpeGeo.holdMs), _ink);
    } else if (!on && _holdTimer != null) {
      _cancelHold();
    }
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (_holding && mounted) setState(() => _holding = false);
  }

  void _panEnd(Offset global) {
    if (_tryDrag) {
      final geo = _geoNow;
      final p = _run.piece;
      setState(() => _tryDrag = false);
      if (geo != null && p != null && geo.trainee.inflate(16).contains(_tryAt)) _startTryOn(p);
      return;
    }
    if (_drag != null) {
      // Let go before the ink took: the stamp springs back, no cost.
      _cancelHold();
      setState(() => _drag = null);
      _hints.missTap();
    }
  }

  void _startTryOn(M7Piece p) {
    _tick('sounds/intro/click.ogg', 0.5);
    _tryTimer?.cancel();
    setState(() {
      _tryOn = p;
      _wake++;
    });
    _tryTimer = Timer(Duration(milliseconds: _quiet ? 900 : 2200), () {
      if (mounted) setState(() => _tryOn = null);
    });
  }

  /// The stamp stayed on its target long enough: it inks.
  void _ink() {
    _holdTimer = null;
    final slot = _drag;
    final geo = _geoNow;
    if (!mounted || slot == null || geo == null || !_canPlay) {
      if (mounted) setState(() => _holding = false);
      return;
    }
    final origin = _docketPhase ? geo.docket.center : geo.line(_run.index).center;
    setState(() {
      _drag = null;
      _holding = false;
    });
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    if (_docketPhase) {
      _onDocket(_deal.docketOrder[slot], origin);
    } else {
      _onClaim(_deal.stampOrder[slot], origin);
    }
  }

  void _onClaim(M7Claim c, Offset origin) {
    final (res, m) = _run.claim(c);
    switch (res) {
      case M7Res.already:
        return;
      case M7Res.slip:
        setState(() => _wake++);
        unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
        unawaited(_slip(m!));
      case M7Res.deadly:
        setState(() => _wake++);
        unawaited(_deadly(m!));
      case M7Res.signed || M7Res.replaced || M7Res.stockOut:
        _stepDone();
        _rightMove(m7WhyOf(c), origin, () => _afterClaim(res));
    }
  }

  void _onDocket(M7Docket d, Offset origin) {
    final (res, m) = _run.docket(d);
    switch (res) {
      case M7Res.already:
        return;
      case M7Res.slip:
        setState(() => _wake++);
        unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
        unawaited(_slip(m!));
      case M7Res.deadly:
        setState(() => _wake++);
        unawaited(_deadly(m!));
      case M7Res.signed || M7Res.replaced || M7Res.stockOut:
        _stepDone();
        _rightMove(d == M7Docket.go ? M7Why.go : M7Why.refuse, origin, () {
          _run.finishDocket();
          unawaited(_finish());
        });
    }
  }

  /// A right move: the first of each question a play puts ◆ on the table and
  /// opens its "কেন?" cards at once; a later one pays at once.
  void _rightMove(M7Why why, Offset origin, VoidCallback after) {
    if (_run.reasonDue(why)) {
      _hush();
      putOnTable(15);
      _afterReason = after;
      unawaited(askReason(
        deal: () => dealChoices(M7PpeLines.whyRight[why]!, M7PpeLines.whyWrong(why), widget.rng),
        question: M7PpeLines.whyQ(why),
        stillValid: () => !_ended,
      ));
      return;
    }
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    after();
  }

  /// What a right claim does next.
  void _afterClaim(M7Res res) {
    switch (res) {
      case M7Res.signed:
        unawaited(_goNext());
      case M7Res.replaced:
        // A replacement (a good one, or a second fault) comes on the mat.
        _arriveAfter(before: [M7PpeLines.storeReplace]);
      case M7Res.stockOut:
        setState(() => _wake++);
        unawaited(_sayChain([M7PpeLines.storeNoStock]));
        scheduleCoworker();
      default:
        break;
    }
  }

  void _arriveAfter({List<String> before = const []}) {
    if (!mounted || _ended) return;
    _arrive(before: before);
  }

  /// The coworker has been dealt with: the storekeeper goes to the back shelf.
  void _stockSearch() {
    if (!mounted || _ended) return;
    final found = _run.stockOutcome();
    if (found) {
      _arrive(before: [M7PpeLines.storeFound]);
      return;
    }
    setState(() => _wake++);
    unawaited(_sayChain([M7PpeLines.storeNone]));
    unawaited(_goNext(delay: 1400));
  }

  Future<void> _goNext({int delay = 600}) async {
    if (_ended) return;
    await Future<void>.delayed(Duration(milliseconds: delay));
    if (!mounted || _ended) return;
    setState(_run.next);
    if (_run.atDocket) {
      _hintN = 0;
      _stampTried = false;
      setState(() {
        _tray = false;
        _wake++;
      });
      unawaited(_sayChain([M7PpeLines.askDocket]));
      return;
    }
    _arrive();
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
    final after = _afterReason;
    _afterReason = null;
    if (!mounted) return;
    setState(() => _wake++);
    after?.call();
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M7PpeLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || struckOut || _run.ended || _freeze) return null;
    if (_intro || _card != null || tableBusy || _drag != null || _tryDrag || _arriving) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.pushSlip();
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      _afterCards = _stockSearch;
      await _slip(m);
      return;
    }
    _run.caught.add(M7PpeLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M7PpeLines.callHeld], mood: GuideMood.glad));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _stockSearch();
  }

  /// Tap the guide: the next task line of the pool, from the start.
  void _tapGuide() {
    if (_intro || _ended || _freeze) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7PpeLines.tapWhy[_whyN++ % M7PpeLines.tapWhy.length]
            : _taskPool[++_taskN % _taskPool.length];
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    _afterCards = null;
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
      _tray = false;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m7ppe/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly act: the scene freezes grey, then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _cancelHold();
    HapticFeedback.heavyImpact();
    _cue('sounds/accident.ogg', volume: 0.9);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _drag = null;
      _tray = false;
      _tryDrag = false;
    });
    await frozen.future;
    if (!mounted) return;
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('m7ppe/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? 'থামুন!' : 'অল্পের জন্য বেঁচে গেলেন!', if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        final after = _afterCards;
        _afterCards = null;
        if (after != null) {
          after();
          return;
        }
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
    await _say(!_run.passed ? M7PpeLines.fail : (_quickBonus ? M7PpeLines.quick : M7PpeLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leave() async {
    if (deathPending) {
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
    if (_card != null) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_tryOn != null || _drag != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what.
  HintSpec? _hint() {
    final g = _geoNow;
    if (g == null) return null;
    final n = _hintN++;
    if (_tray) {
      return n.isEven
          ? HintSpec.sweep([Rect.fromLTWH(g.trayArt.left, g.trayArt.top, g.trayArt.width / 2, g.trayArt.height), Rect.fromLTWH(g.trayArt.center.dx, g.trayArt.top, g.trayArt.width / 2, g.trayArt.height)], space: HintSpace.scene)
          : HintSpec.drag(g.trayArt.center, toward: const Offset(0, 1), travel: 56, space: HintSpace.scene);
    }
    if (_docketPhase) {
      return HintSpec.sweep([g.docketStamp(0), g.docketStamp(1)], space: HintSpace.scene);
    }
    final ways = <HintSpec>[
      HintSpec.tap(g.item.center, space: HintSpace.scene),
      HintSpec.sweep([for (var i = 0; i < 6; i++) g.stamp(i)], space: HintSpace.scene),
      if (_stampTried) HintSpec.hold(g.line(_run.index).center, space: HintSpace.scene),
    ];
    return ways[n % ways.length];
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M7PpeGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final piece = _run.piece;
    final drag = _drag;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('back'),
                child: RepaintBoundary(child: CustomPaint(painter: M7PpeBackPainter(geo: geo, light: _deal.light, cal: _deal.calendar))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet)),
                    if (_tryOn != null)
                      Positioned.fill(
                        key: ValueKey('tryon-${_tryOn!.id}'),
                        child: IgnorePointer(child: CustomPaint(painter: M7TryOnPainter(piece: _tryOn!, job: _deal.job, cal: _deal.calendar))),
                      ),
                  ],
                ),
              ),
              if (piece != null && !_tray && !_intro)
                Positioned.fromRect(
                  key: ValueKey('piece-${piece.id}'),
                  rect: geo.item,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('arrive-$_arrivalN'),
                    tween: Tween(begin: quiet ? 1 : 0, end: 1),
                    duration: Duration(milliseconds: quiet ? 1 : 900),
                    curve: Curves.easeOutCubic,
                    child: Semantics(
                      label: M7PpeLines.itemName(piece.item),
                      child: RepaintBoundary(child: CustomPaint(painter: M7PiecePainter(piece: piece, job: _deal.job, cal: _deal.calendar))),
                    ),
                    builder: (_, v, child) => Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(-70 * (1 - v), -14 * (1 - v)), child: child)),
                  ),
                ),
              Positioned.fromRect(
                key: const ValueKey('docket'),
                rect: geo.docket,
                child: _Docket(job: _deal.job, stamped: _run.docketDone),
              ),
              Positioned.fromRect(
                key: const ValueKey('register'),
                rect: geo.register,
                child: _Register(geo: geo, run: _run, dateText: _deal.calendar.dateText),
              ),
              if (_holding)
                Positioned.fromRect(
                  key: ValueKey('hold-$_holdN'),
                  rect: _docketPhase ? geo.docket : geo.line(_run.index),
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: _quiet ? 1 : M7PpeGeo.holdMs),
                      builder: (_, v, _) => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(widthFactor: v, heightFactor: 1, child: ColoredBox(color: const Color(0x661F3F8F))),
                      ),
                    ),
                  ),
                ),
              Positioned.fromRect(
                key: const ValueKey('stand'),
                rect: geo.stand,
                child: _Stand(geo: geo, deal: _deal, docketPhase: _docketPhase, lifted: drag),
              ),
              if (_tray && piece != null)
                Positioned.fromRect(
                  key: ValueKey('tray-${piece.id}'),
                  rect: geo.tray,
                  child: _Tray(geo: geo, piece: piece, job: _deal.job, cal: _deal.calendar, ghost: _tryDrag),
                ),
            ],
          ),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M7PpeLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (d) => _panEnd(d.globalPosition),
            onPanCancel: () {
              _cancelHold();
              if (_drag != null || _tryDrag) {
                setState(() {
                  _drag = null;
                  _tryDrag = false;
                });
              }
            },
          ),
        ),
      ),
      // The stamp in hand, its pin at the finger's tip.
      if (drag != null)
        Positioned(
          key: const ValueKey('drag-stamp'),
          left: _dragAt.dx - 27,
          top: _dragAt.dy - 4,
          width: 54,
          height: M7PpeGeo.standH - 18,
          child: IgnorePointer(
            child: _StampFace(
              label: _docketPhase ? M7PpeLines.docketStamp(_deal.docketOrder[drag]) : M7PpeLines.stampLabel(_deal.stampOrder[drag]),
              lifted: true,
              wide: _docketPhase,
            ),
          ),
        ),
      // The item in hand for the try-on.
      if (_tryDrag && piece != null)
        Positioned(
          key: const ValueKey('drag-item'),
          left: _tryAt.dx - 40,
          top: _tryAt.dy - 30,
          width: 80,
          height: 60,
          child: IgnorePointer(
            child: Opacity(opacity: 0.9, child: CustomPaint(painter: M7PiecePainter(piece: piece, job: _deal.job, cal: _deal.calendar))),
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
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_run.ended && !_arriving;
    // The guide stands just above the stamp stand (screen px).
    final guideBottom = M7PpeGeo.standH * size.width / 360 + pad.bottom * 0.6 + 2;
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
              labels: [for (final i in _deal.order) M7PpeLines.itemName(i)],
              done: {for (var i = 0; i < math.min(_run.index, 4); i++) i},
              current: _run.atDocket ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _drag == null && !_tryDrag && (_itemUp || _docketPhase),
            hintKey: '${_run.index}/$_steps/${_run.slips}/$_tray',
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
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: deckUp ? pad.bottom + 236 : guideBottom, onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
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
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M7PpeLines.intro,
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

/// A rubber stamp: a wooden knob over a rubber block with its label.
class _StampFace extends StatelessWidget {
  const _StampFace({required this.label, this.lifted = false, this.wide = false});
  final String label;
  final bool lifted;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: wide ? 34 : 22,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF8A5A2C),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [BoxShadow(color: const Color(0x66000000), blurRadius: lifted ? 8 : 2, offset: Offset(0, lifted ? 4 : 1))],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2B4A82), Color(0xFF1B3158)]),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFE9C46A), width: 1.2),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 120 : 46),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: bangla(fontSize: wide ? 12 : 10, fontWeight: FontWeight.w900, color: const Color(0xFFF7F1DE), height: 1.15),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The stamp stand: six equal stamps (shuffled), or the two docket stamps.
class _Stand extends StatelessWidget {
  const _Stand({required this.geo, required this.deal, required this.docketPhase, required this.lifted});
  final M7PpeGeo geo;
  final M7PpeDeal deal;
  final bool docketPhase;
  final int? lifted;

  @override
  Widget build(BuildContext context) {
    final b = geo.stand;
    final slots = docketPhase ? 2 : 6;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6B4A28), Color(0xFF3F2A14)]),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.85), width: 1.5),
              boxShadow: const [BoxShadow(color: Color(0x77000000), blurRadius: 8, offset: Offset(0, -2))],
            ),
          ),
        ),
        for (var i = 0; i < slots; i++)
          Positioned(
            key: ValueKey('${docketPhase ? 'dk' : 'st'}-$i'),
            left: (docketPhase ? geo.docketStamp(i) : geo.stamp(i)).left - b.left,
            top: (docketPhase ? geo.docketStamp(i) : geo.stamp(i)).top - b.top,
            width: (docketPhase ? geo.docketStamp(i) : geo.stamp(i)).width,
            height: (docketPhase ? geo.docketStamp(i) : geo.stamp(i)).height,
            child: Semantics(
              label: docketPhase ? M7PpeLines.docketStamp(deal.docketOrder[i]) : M7PpeLines.stampLabel(deal.stampOrder[i]),
              child: Opacity(
                opacity: lifted == i ? 0.3 : 1,
                child: _StampFace(label: docketPhase ? M7PpeLines.docketStamp(deal.docketOrder[i]) : M7PpeLines.stampLabel(deal.stampOrder[i]), wide: docketPhase),
              ),
            ),
          ),
      ],
    );
  }
}

/// The issue register: a date and one ruled line per item with the claims
/// inked on it.
class _Register extends StatelessWidget {
  const _Register({required this.geo, required this.run, required this.dateText});
  final M7PpeGeo geo;
  final M7PpeRun run;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    final r = geo.register;
    return Semantics(
      label: M7PpeLines.registerWord,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F1DE),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF8A6A3C), width: 2),
                boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3))],
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            top: 2,
            height: 14,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('${M7PpeLines.registerWord} · $dateText', style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A16))),
            ),
          ),
          for (var k = 0; k < 4; k++) _row(k, r),
        ],
      ),
    );
  }

  Widget _row(int k, Rect r) {
    final line = geo.line(k);
    final item = run.deal.order[k];
    final marks = run.marks[item]!;
    final shown = marks.length > 2 ? marks.sublist(marks.length - 2) : marks;
    return Positioned(
      key: ValueKey('line-$k'),
      left: line.left - r.left,
      top: line.top - r.top,
      width: line.width,
      height: line.height,
      child: DecoratedBox(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x663A2A16), width: 1))),
        child: Row(
          children: [
            SizedBox(
              width: 66,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(M7PpeLines.itemName(item), style: bangla(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF3A2A16))),
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? const SizedBox.shrink()
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        shown.map(M7PpeLines.stampLabel).join(' · '),
                        maxLines: 1,
                        style: bangla(fontSize: 9.5, fontWeight: FontWeight.w900, color: const Color(0xFF1F3F8F)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The day's docket: the job and the kit list; the decision stamp lands on it.
class _Docket extends StatelessWidget {
  const _Docket({required this.job, required this.stamped});
  final M7Job job;
  final bool stamped;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M7PpeLines.docketWord,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6EA),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF8A6A3C), width: 1.6),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 5, 6, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(M7PpeLines.docketWord, style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFFB4262B))),
              const SizedBox(height: 2),
              Text(enDigits(M7PpeLines.jobLine(job)), maxLines: 2, style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018), height: 1.15)),
              const SizedBox(height: 3),
              for (final l in M7PpeLines.kitList(job))
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('• ${enDigits(l)}', maxLines: 1, style: bangla(fontSize: 8.5, fontWeight: FontWeight.w700, color: const Color(0xFF3A2A16))),
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

/// The close-up tray: the item big, every marking at once; its ✕.
class _Tray extends StatelessWidget {
  const _Tray({required this.geo, required this.piece, required this.job, required this.cal, required this.ghost});
  final M7PpeGeo geo;
  final M7Piece piece;
  final M7Job job;
  final M7Calendar cal;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    final t = geo.tray;
    final a = geo.trayArt;
    return Semantics(
      label: M7PpeLines.trayLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEDE6D2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SlmColors.gold300, width: 2),
                boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
            ),
          ),
          Positioned(
            left: a.left - t.left,
            top: a.top - t.top,
            width: a.width,
            height: a.height,
            child: Opacity(opacity: ghost ? 0.35 : 1, child: RepaintBoundary(child: CustomPaint(painter: M7PiecePainter(piece: piece, job: job, cal: cal)))),
          ),
          Positioned(
            right: 4,
            top: 4,
            width: 32,
            height: 32,
            child: Semantics(
              label: M7PpeLines.closeLabel,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFF2B4A82), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFFF7F1DE)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
