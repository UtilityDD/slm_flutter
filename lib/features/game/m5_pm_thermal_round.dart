import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
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
import 'm5_pm_thermal_round_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 5.10 "প্রিভেন্টিভ মেইনটেন্যান্স: গোয়েন্দা থেকে ডাক্তার", কাজ
// "লুকানো গরম: PM রাউন্ড" (pack do_5_10_a, engineType m5_pm_thermal_round).
// A live roadside DP structure on a PM morning, four rounds:
//
//  ক স্ক্যান (sweep + snap): drag the thermal camera's small window over the
//    live structure from the ground; hold it still 0.8 s on a joint to snap.
//    1–2 hotspots are dealt (one phase of one place, > 15 °C over the same
//    joint on the other two phases — ruling M5-15). The first hotspot → ◆ →
//    "বাইরে থেকে তো ঠিকঠাক দেখাচ্ছিল, কেন এটা ধরলেন?". A sound joint snapped =
//    a slip (R30), once per joint (it is never carded twice); "স্ক্যান শেষ"
//    with a hotspot missed = a slip (R31). Place loads vary widely, so no
//    single reading gives a hotspot away; only the other phases do.
//  খ শাটডাউন (order): phone (the planned shutdown) → the written PTW → the
//    tester shows 0 V → the mate hangs both earths → the wrench. The wrench
//    before the PTW (R1), before 0 V (R2) or before the earth (R4) = deadly;
//    the other steps out of order are slips (R3: earth before the test).
//    Reason: "টাইট দেওয়ার আগে কেন পারমিট আর টেস্টার?".
//  গ টাইট (circular drag): up the pole, turn the torque wrench round each
//    snapped joint (they need a full turn) and round 3–4 identical hardware
//    nuts (a tight nut clicks at once; the loose one — 2 plays in 3 — turns).
//    The loose nut → ◆ → "সামান্য একটা নাট, এখনই কেন টাইট দিলেন?".
//    "নামুন" with a snapped joint or the loose nut left = a slip.
//    Then the line clear (not scored) and a short IR re-glance.
//  ঘ লগবুক (drag cards + sign): drag the true cards onto the page (own
//    snaps, the work done, the oil-colour card when the "গত PM" photo differs
//    from today's) and sign; a wrong sign = a slip. Reason: "খাতায় এত লিখে কী
//    হবে?" or, with the oil changed, "তেলের রং বদলানোটা কেন লিখলেন?".
//
// The careless coworker once a play, dealt A or B: A after the snapped joints
// are tight, before "নামুন" ("গরমটা তো সারলে! … পরে করা যাবে, নামো!" — he
// comes even when nothing is left); B when the logbook opens ("PM মানে তো
// শুধু লাইন পরিষ্কার করা! …"). নামুন / সই wait for him (holdForCoworker).
// Listening = a slip (R29: a shortcut with no immediate danger); with A he
// climbs down at once, leaving whatever was left.
//
// Lesson sources (5.10): checklist point (index 1) — hotspot detection with a
// thermal camera, tightening connections and hardware; CBM point (index 2) —
// a lineman noticing and reporting oil colour change; pro tips 1–2 — fix a
// small loose nut at once ("পরে করা যাবে" breeds breakdowns), keep a logbook;
// myths 1–2 — "why open what works", "PM is just cleaning"; importance — a
// planned shutdown beats an unplanned blackout. The PTW / tester / earth
// sequence is Module 1's (lessons 1.5, 1.6) and the module table (R1, R2, R3,
// R4) — no 5.10 lesson point. Temperatures are not in the lesson (M5-15).
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m5_pm_thermal_round_world.dart), corner guide, ◆ on the table →
// "কেন …?", the coworker's two beats, mistake cards, the deadly freeze, three
// slips strike out. Gesture hands (how, never what): the camera dragged a
// short way toward the empty sky, then a hold ring (only off the joints); a
// sweep over the tool row; a sweep over every wrench target alike; a sweep
// over every logbook card and a page-curl swipe on the logbook. "স্ক্যান শেষ"
// and "নামুন" are never hinted. Voice: the guide by device TTS; the
// coworker's two pushes need recorded clips (listed for the director).

// ============================================================================
// Content
// ============================================================================

/// The play's rounds.
enum M5PmStage { scan, shutdown, tighten, logbook }

/// The shutdown round's buttons.
enum M5PmTool { phone, permit, tester, earth, wrench }

abstract final class M5PmLines {
  static const title = 'লুকানো গরম: PM রাউন্ড';
  static const intro = 'আজ PM-এর দিন। সব চলছে ঠিকঠাক, তবু রোগ লুকিয়ে থাকতে পারে। খুঁজে বের করুন!';
  static const rounds = ['স্ক্যান', 'শাটডাউন', 'টাইট', 'লগবুক'];

  // The guide's task now (tap him: the same task, a different way).
  static const askScan = 'থার্মাল ক্যামেরায় সব জোড় স্ক্যান করুন।';
  static const askShutdown = 'টাইট দিতে হবে — আগে নিরাপদ শাটডাউন।';
  static const askTighten = 'রেঞ্চ ঘুরিয়ে জোড় আর নাট টাইট দিন।';
  static const askLog = 'লগবুকে সত্যি কথাগুলো তুলে সই করুন।';
  static const tasks = [askScan, askShutdown, askTighten, askLog];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'ডিপি স্ট্রাকচার';
  static const phone = 'ফোন';
  static const permit = 'পারমিট';
  static const tester = 'টেস্টার';
  static const earth = 'আর্থ';
  static const wrench = 'রেঞ্চ';
  static const scanDone = 'স্ক্যান শেষ';
  static const down = 'নামুন';
  static const sign = 'সই';
  static const testerDead = '0 V';
  static const tight = 'টাইট';
  static const schedule = 'পরিকল্পিত শাটডাউন';
  static const logbook = 'লগবুক';
  static const lastPm = 'গত PM';
  static const today = 'আজ';

  static String toolLabel(M5PmTool t) => switch (t) {
        M5PmTool.phone => phone,
        M5PmTool.permit => permit,
        M5PmTool.tester => tester,
        M5PmTool.earth => earth,
        M5PmTool.wrench => wrench,
      };

  static const places = <M5PmPlace, String>{
    M5PmPlace.lineClamp: 'জাম্পার ক্ল্যাম্প',
    M5PmPlace.doTop: 'ডিও-র উপরের কন্ট্যাক্ট',
    M5PmPlace.doBottom: 'ডিও-র নিচের কন্ট্যাক্ট',
    M5PmPlace.htBushing: 'এইচটি বুশিং',
    M5PmPlace.ltLug: 'এলটি বুশিং লাগ',
    M5PmPlace.ltBox: 'এলটি বক্সের লাগ',
  };
  static const phases = ['R', 'Y', 'B'];

  // The logbook's cards.
  static String hotCard(M5PmJoint j) => 'হটস্পট: ${places[j.place]}, ${phases[j.phase]} ফেজ';
  static const workCard = 'গরম জোড় টাইট দিয়েছি';
  static const nutCard = 'আলগা নাট টাইট দিয়েছি';
  static const oilCard = 'তেলের রং গত PM-এর চেয়ে গাঢ়';
  static const untrueWork = [
    'ইনসুলেটর বদলেছি',
    'গাছের ডাল ছেঁটেছি',
    'আর্থ পিট মেরামত করেছি',
    'ডিও ফিউজ বদলেছি',
    'ট্রান্সফরমারের তেল বদলেছি',
  ];

  // The reasons (the right ones fit what was just done; the wrong ones are
  // the lesson's myths and field excuses). 38–48 letters.
  static const hotWhyQ = 'বাইরে থেকে তো ঠিকঠাক দেখাচ্ছিল, কেন এটা ধরলেন?';
  static const ptwWhyQ = 'টাইট দেওয়ার আগে কেন পারমিট আর টেস্টার?';
  static const nutWhyQ = 'সামান্য একটা নাট, এখনই কেন টাইট দিলেন?';
  static const logWhyQ = 'খাতায় এত লিখে কী হবে?';
  static const oilWhyQ = 'তেলের রং বদলানোটা কেন লিখলেন?';
  static const hotWhy = [
    'অন্য দুই ফেজের একই জোড়ের চেয়ে এটা অনেক গরম',
    'একই লোডে পাশের দুই ফেজের চেয়ে 15°C-এর বেশি গরম',
    'লুজ কানেকশন বাইরে দেখা যায় না, গরমে ধরা পড়ে',
  ];
  static const ptwWhy = ['লিখিত পারমিট আর টেস্টারে 0 V — তবেই লাইনে হাত', 'ফোনের কথায় নয়, টেস্টারে ডেড প্রমাণ হলে তবে কাজ'];
  static const nutWhy = ['ছোট লুজ নাট ফেলে রাখলেই পরে বড় ব্রেকডাউন হয়', '"পরে করা যাবে" মনোভাবই বড় ব্রেকডাউন ডেকে আনে'];
  static const logWhy = ['কী পেলাম, কী করলাম — পরের পরিকল্পনায় কাজে লাগে', 'রেকর্ড থাকলে পরের PM-এ তুলনা করে দেখা যায়'];
  static const oilWhy = ['তেলের রং বদলানো অবনতির লক্ষণ, রিপোর্ট করতে হয়', 'অবস্থার অবনতি জানালে সময়মতো মেরামত করা যায়'];
  static const myths = [
    'যা ঠিকঠাক চলছে, তা নাড়াচাড়া করলেই বিপদ বাড়ে',
    'PM মানে তো শুধু লাইনটা পরিষ্কার করে দেওয়া',
    'ছোটখাটো জিনিস পরে সময় পেলে সারলেই চলে',
    'লাইন তো দিব্যি চলছিল, তাই সমস্যা ছিল না',
    'খাতা তো কেউ পড়ে না, লেখা শুধু নিয়মরক্ষা',
    'কন্ট্রোল রুম ফোনে বলেছে, তাই লাইন বন্ধই',
    'গরম জোড় একটু পরে নিজে থেকেই ঠান্ডা হয়',
    'অভিজ্ঞ চোখই যথেষ্ট, ক্যামেরা লাগে না কখনো',
  ];
  static List<String> get allWhyRight => [...hotWhy, ...ptwWhy, ...nutWhy, ...logWhy, ...oilWhy];

  /// The careless coworker, push A: leave the small things for later.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerA = CoworkerScript(
    line: 'গরমটা তো সারলে! বাকি ছোটখাটো যা আছে, পরে করা যাবে, নামো!',
    exitLine: coworkerExit,
    right: ['না, ছোট সমস্যা এখনই সারাই, পরে নয়', 'না, সব নাট দেখে তবেই আমি নামব', 'না, "পরে করব" থেকেই বড় ব্রেকডাউন'],
    wrong: [
      'ঠিক, গরমটা সারলেই যথেষ্ট, নামি',
      'আচ্ছা, বাকি নাট পরের PM-এ দেখব',
      'হ্যাঁ, ছোটখাটো জিনিস পরে হবে',
      'ঠিক আছে, এখন নেমে চা খেয়ে আসি',
      'হ্যাঁ, বাকিটা পরে এসে করে দেব',
    ],
    asks: ['ও বলছে বাকিটা পরে করতে। কী করবেন?', 'এখনই সারবেন, না পরে?', 'ছোট সমস্যা ফেলে নামবেন?'],
  );

  /// Push B: write "cleaned" in the logbook and go.
  static const coworkerB = CoworkerScript(
    line: 'PM মানে তো শুধু লাইন পরিষ্কার করা! খাতায় পরিষ্কার লিখে দাও, চলো।',
    exitLine: coworkerExit,
    right: ['না, যা পেলাম আর যা করলাম সব লিখব', 'না, পরিষ্কার শুধু একটা অংশ মাত্র', 'না, আসল কাজ তো পরীক্ষা আর রেকর্ড'],
    wrong: [
      'ঠিক, শুধু "পরিষ্কার" লিখে দিই',
      'আচ্ছা, খাতা পরে অফিসে লিখব',
      'হ্যাঁ, এত লেখার দরকার নেই',
      'ঠিক আছে, শুধু সইটা করে দিই',
      'হ্যাঁ, হটস্পট না লিখলেও চলে',
    ],
    asks: ['ও বলছে শুধু "পরিষ্কার" লিখতে। কী করবেন?', 'খাতায় কী লিখবেন?', 'শুধু পরিষ্কার লিখলেই কি PM?'],
  );

  /// The coworker lines that need his recorded voice (the director records
  /// them with tool/rival_clip.py; the exit line is already recorded).
  static List<String> get rivalLines => [coworkerA.line, coworkerB.line];

  static const snapMore = 'আরেকটা হটস্পট — ছবি তোলা হলো!';
  static const scanAll = 'সব হটস্পট ধরা হলো। এবার শাটডাউন।';
  static const jointDone = 'জোড় টাইট!';
  static const lineClear = 'নেমে এলেন। আর্থ খুলে, পারমিট ফেরত — লাইন ক্লিয়ার।';
  static const reglance = 'চালু লাইনে আরেকবার দেখুন — জোড় এখন ঠান্ডা।';
  static const callHeldA = 'ঠিক! ছোট সমস্যা এখনই — পরে নয়।';
  static const callHeldB = 'ঠিক! যা পেলেন, যা করলেন — সব খাতায়।';
  static const allSet = 'লুকানো গরম ধরা, নিরাপদে টাইট, খাতায় সব লেখা — এই তো PM!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — সব জোড় তুলনা করে দেখুন, শাটডাউনে টাইট, খাতায় সত্যি।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtScan = 'অন্য ফেজের সাথে তুলনা করে হটস্পট ধরেছেন';
  static const caughtPtw = 'ফোন, লিখিত পারমিট, 0 V, আর্থ — তবে রেঞ্চ';
  static const caughtNut = 'সামান্য লুজ নাটও তখনই টাইট';
  static const caughtLog = 'লগবুকে যা পেলেন, যা করলেন — সব সত্যি';
  static const caughtCallA = '“পরে করা যাবে”-তে “না” বলেছেন';
  static const caughtCallB = '“শুধু পরিষ্কার”-এ “না” বলেছেন';
}

abstract final class M5PmMistakes {
  static const _dir = 'assets/game/art/m5_pm_thermal_round';

  // Module 1's PTW / tester / earth rules (R1, R2, R4 deadly; R3 slip): no
  // 5.10 lesson point.
  static const noPermit = DoMistake(
    key: '5.10/m5_pm_thermal_round/no-permit',
    textBn: 'লিখিত পারমিট ছাড়া লাইনে হাত নয় — ফোনের "লাইন বন্ধ" কথা পারমিট নয়। আগে লিখিত PTW, তারপর টেস্টার।',
    art: '$_dir/no_permit.svg',
    deadly: true,
  );
  static const noTest = DoMistake(
    key: '5.10/m5_pm_thermal_round/no-test',
    textBn: 'পারমিট হাতে, তবু টেস্টারে 0 V না দেখে হাত দিলেন! আগে টেস্টারে ডেড প্রমাণ, তারপর আর্থ, তবে কাজ।',
    art: '$_dir/no_test.svg',
    deadly: true,
  );
  static const noEarth = DoMistake(
    key: '5.10/m5_pm_thermal_round/no-earth',
    textBn: 'টেস্টের পর আর্থ না দিয়েই কাজ! দুই দিকে আর্থ ঝোলানো হলে তবেই রেঞ্চ হাতে উঠুন।',
    art: '$_dir/no_earth.svg',
    deadly: true,
  );
  static const phoneFirst = DoMistake(
    key: '5.10/m5_pm_thermal_round/phone-first',
    textBn: 'আগে কন্ট্রোল রুমকে ফোন করে পরিকল্পিত শাটডাউন — তারপর লিখিত পারমিট।',
    art: '$_dir/ptw_order.svg',
  );
  static const permitFirst = DoMistake(
    key: '5.10/m5_pm_thermal_round/permit-first',
    textBn: 'আগে লিখিত পারমিট হাতে — তারপর টেস্টার আর আর্থ।',
    art: '$_dir/ptw_order.svg',
  );
  static const testFirst = DoMistake(
    key: '5.10/m5_pm_thermal_round/test-first',
    textBn: 'আগে টেস্টার দিয়ে ডেড প্রমাণ, তারপর আর্থ — এই ক্রম বাধ্যতামূলক।',
    art: '$_dir/test_first.svg',
  );
  static const soundSnap = DoMistake(
    key: '5.10/m5_pm_thermal_round/sound-snap',
    textBn: 'এই জোড়টা অন্য দুই ফেজের মতোই — হটস্পট নয়। একই লোডে থাকা অন্য দুই ফেজের একই জোড়ের সাথে তুলনা করুন।',
    art: '$_dir/sound_snap.svg',
    lessonPoint: 1,
  );
  static const missedHot = DoMistake(
    key: '5.10/m5_pm_thermal_round/missed-hot',
    textBn: 'একটা হটস্পট রয়ে গেল! তুলনা করুন একই লোডে থাকা অন্য দুই ফেজের একই জোড়ের সাথে; >15°C বেশি হলে এখনই মেরামত।',
    art: '$_dir/missed_hot.svg',
    lessonPoint: 1,
  );
  static const nutLeft = DoMistake(
    key: '5.10/m5_pm_thermal_round/nut-left',
    textBn: 'কাজ বাকি রেখে নামবেন না! সামান্য লুজ নাটও তখনই টাইট দিন — "পরে করা যাবে" মনোভাবই বড় ব্রেকডাউনের জন্ম দেয়।',
    art: '$_dir/nut_left.svg',
    lessonPoint: 1,
  );
  static const pushA = DoMistake(
    key: '5.10/m5_pm_thermal_round/push-later',
    textBn: 'ওর কথায় বাকি কাজ ফেলে নামলেন! পিএম-এ সামান্য লুজ নাট বা মরিচা ধরা ক্ল্যাম্প দেখলে তখনই ঠিক করুন।',
    art: '$_dir/nut_left.svg',
    lessonPoint: 1,
  );
  static const pushB = DoMistake(
    key: '5.10/m5_pm_thermal_round/push-clean-only',
    textBn: 'পিএম মানে শুধু পরিষ্কার নয় — আসল কাজ পরীক্ষা আর সরঞ্জামের স্বাস্থ্য যাচাই। যা পেলেন, যা করলেন, সব লিখুন।',
    art: '$_dir/clean_only.svg',
    lessonPoint: 1,
  );
  static const wrongSign = DoMistake(
    key: '5.10/m5_pm_thermal_round/wrong-sign',
    textBn: 'লগবুকে শুধু সত্যি — যা পেলেন আর যা করলেন সবই, যা হয়নি তা নয়। তেলের রং বদলালে সেটাও লিখুন।',
    art: '$_dir/wrong_sign.svg',
    lessonPoint: 2,
  );

  static List<DoMistake> get all => [
        noPermit,
        noTest,
        noEarth,
        phoneFirst,
        permitFirst,
        testFirst,
        soundSnap,
        missedHot,
        nutLeft,
        pushA,
        pushB,
        wrongSign,
      ];
}

@immutable
class M5PmDeal {
  const M5PmDeal({
    required this.hot,
    required this.temps,
    required this.light,
    required this.nuts,
    required this.loose,
    required this.oilLast,
    required this.oilToday,
    required this.pushB,
    required this.decoy,
    required this.untrueWork,
  });

  /// The hotspots (1–2, on different places).
  final List<M5PmJoint> hot;

  /// Every joint's temperature (°C).
  final Map<M5PmJoint, int> temps;

  /// The morning's light (0–2).
  final int light;

  /// The hardware nuts to check aloft (3–4).
  final List<M5PmNut> nuts;

  /// The loose one among [nuts], or none (1 play in 3).
  final M5PmNut? loose;

  /// The oil colour in the "গত PM" photo and today (index into m5PmOils).
  final int oilLast;
  final int oilToday;

  /// The coworker's push: B (the logbook) or A (before নামুন).
  final bool pushB;

  /// A sound joint named on an untrue hotspot card.
  final M5PmJoint decoy;

  /// Work not done today, offered on the logbook (1–2).
  final List<String> untrueWork;

  bool get oilChanged => oilLast != oilToday;
}

/// Two hotspots never sit where their wrench targets would crowd.
const _crowded = [
  {M5PmPlace.doTop, M5PmPlace.doBottom},
  {M5PmPlace.doBottom, M5PmPlace.htBushing},
  {M5PmPlace.htBushing, M5PmPlace.ltLug},
];

M5PmDeal m5PmDeal(math.Random rng) {
  final order = [...M5PmPlace.values]..shuffle(rng);
  final n = rng.nextBool() ? 1 : 2;
  final places = <M5PmPlace>[];
  for (final p in order) {
    if (places.length == n) break;
    if (places.any((q) => _crowded.any((s) => s.contains(p) && s.contains(q)))) continue;
    places.add(p);
  }
  final hot = [for (final p in places) (place: p, phase: rng.nextInt(3))];
  // Each place carries its own load, from a light 26 °C to a heavy 61 °C (the
  // transformer side often heavier still), so a sound joint on a loaded place
  // often reads hotter than a hotspot on a light one, even in the same deal:
  // only the same joint on the other two phases tells (M5-15), never one
  // cut-off reading and never "the brightest one".
  final temps = <M5PmJoint, int>{};
  for (final p in M5PmPlace.values) {
    final pb = 26 + rng.nextInt(36) + (p.index >= 3 ? rng.nextInt(8) : 0);
    for (var i = 0; i < 3; i++) {
      temps[(place: p, phase: i)] = pb + rng.nextInt(3) - 1;
    }
  }
  for (final j in hot) {
    final others = [for (var i = 0; i < 3; i++) if (i != j.phase) temps[(place: j.place, phase: i)]!];
    temps[j] = others.reduce(math.max) + 16 + rng.nextInt(10);
  }
  final light = rng.nextInt(3);
  final pool = [...M5PmNut.values]..shuffle(rng);
  final nuts = pool.take(3 + rng.nextInt(2)).toList()..sort((a, b) => a.index - b.index);
  final loose = rng.nextInt(3) < 2 ? nuts[rng.nextInt(nuts.length)] : null;
  // Today's oil colour alone never answers: every shade shows up both changed
  // and unchanged, so only the "গত PM" photo beside it tells.
  final changed = rng.nextBool();
  final int oilLast;
  final int oilToday;
  if (changed) {
    oilToday = 1 + rng.nextInt(2);
    oilLast = rng.nextInt(oilToday);
  } else {
    oilLast = rng.nextInt(3);
    oilToday = oilLast;
  }
  final pushB = rng.nextBool();
  final sound = [for (final j in m5PmAllJoints) if (!hot.contains(j)) j];
  final decoy = sound[rng.nextInt(sound.length)];
  final work = [...M5PmLines.untrueWork]..shuffle(rng);
  return M5PmDeal(
    hot: hot,
    temps: temps,
    light: light,
    nuts: nuts,
    loose: loose,
    oilLast: oilLast,
    oilToday: oilToday,
    pushB: pushB,
    decoy: decoy,
    untrueWork: work.take(1 + rng.nextInt(2)).toList(),
  );
}

/// The torque wrench's sweep before it clicks: a tight nut at once, a loose
/// nut or a hot joint only after nearly a full turn (radians).
const m5PmTightTurn = 70 * math.pi / 180;
const m5PmFullTurn = 300 * math.pi / 180;

/// The play state (pure logic).
class M5PmRun {
  M5PmRun(this.deal);
  final M5PmDeal deal;

  int index = 0;
  int slips = 0;
  int roundSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The round's work is done (its reason or the line clear comes next).
  var roundDone = false;

  // স্ক্যান
  final Set<M5PmJoint> snapped = {};

  /// Sound joints already photographed by mistake: carded once, never again.
  final Set<M5PmJoint> wrongSnapped = {};
  var _scanSlip = false;

  // শাটডাউন
  var phone = false;
  var permit = false;
  var tested = false;
  var earthed = false;

  // টাইট
  var aloft = false;
  final Set<M5PmJoint> jointsDone = {};
  final Set<M5PmNut> nutsChecked = {};
  var looseFixed = false;
  var listened = false;

  // লগবুক
  final Set<String> page = <String>{};

  M5PmStage get stage => M5PmStage.values[index.clamp(0, 3)];
  bool get done => index >= 4;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => roundSlips == 0;
  bool get _open => !ended && !roundDone;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlips++;
    return m;
  }

  // --- স্ক্যান ---------------------------------------------------------------
  bool get allHotSnapped => deal.hot.every(snapped.contains);

  /// A joint photographed. Returns the mistake, if any.
  DoMistake? snap(M5PmJoint j) {
    if (!_open || stage != M5PmStage.scan || snapped.contains(j) || wrongSnapped.contains(j)) return null;
    if (!deal.hot.contains(j)) {
      wrongSnapped.add(j);
      _scanSlip = true;
      return _slip(M5PmMistakes.soundSnap);
    }
    snapped.add(j);
    return null;
  }

  /// "স্ক্যান শেষ".
  DoMistake? endScan() {
    if (!_open || stage != M5PmStage.scan) return null;
    if (!allHotSnapped) {
      _scanSlip = true;
      return _slip(M5PmMistakes.missedHot);
    }
    roundDone = true;
    if (!_scanSlip) _tag(M5PmLines.caughtScan);
    return null;
  }

  // --- শাটডাউন -------------------------------------------------------------
  /// A shutdown button. Returns the mistake, if any.
  DoMistake? use(M5PmTool t) {
    if (!_open || stage != M5PmStage.shutdown) return null;
    switch (t) {
      case M5PmTool.phone:
        phone = true;
      case M5PmTool.permit:
        if (permit) return null;
        if (!phone) return _slip(M5PmMistakes.phoneFirst);
        permit = true;
      case M5PmTool.tester:
        if (tested) return null;
        if (!permit) return _slip(M5PmMistakes.permitFirst);
        tested = true;
      case M5PmTool.earth:
        if (earthed) return null;
        if (!permit) return _slip(M5PmMistakes.permitFirst);
        if (!tested) return _slip(M5PmMistakes.testFirst);
        earthed = true;
      case M5PmTool.wrench:
        if (!permit) return deadly = M5PmMistakes.noPermit;
        if (!tested) return deadly = M5PmMistakes.noTest;
        if (!earthed) return deadly = M5PmMistakes.noEarth;
        roundDone = true;
        if (thorough) _tag(M5PmLines.caughtPtw);
    }
    return null;
  }

  // --- টাইট ------------------------------------------------------------------
  bool get hotDone => deal.hot.every(jointsDone.contains);
  bool get nutLeft => deal.loose != null && !looseFixed;

  /// How far the wrench sweeps on this nut before it clicks.
  double turnForNut(M5PmNut n) => n == deal.loose && !looseFixed ? m5PmFullTurn : m5PmTightTurn;

  /// A snapped joint turned tight.
  void wrenchJoint(M5PmJoint j) {
    if (!_open || stage != M5PmStage.tighten || !deal.hot.contains(j)) return;
    jointsDone.add(j);
  }

  /// A hardware nut checked; true if it was the loose one (now tight).
  bool wrenchNut(M5PmNut n) {
    if (!_open || stage != M5PmStage.tighten || !deal.nuts.contains(n)) return false;
    nutsChecked.add(n);
    if (n == deal.loose && !looseFixed) {
      looseFixed = true;
      _tag(M5PmLines.caughtNut);
      return true;
    }
    return false;
  }

  /// "নামুন".
  DoMistake? climbDown() {
    if (!_open || stage != M5PmStage.tighten) return null;
    if (!hotDone || nutLeft) return _slip(M5PmMistakes.nutLeft);
    aloft = false;
    roundDone = true;
    return null;
  }

  // --- লগবুক -----------------------------------------------------------------
  /// The true cards this play.
  Set<String> get logTrue => {
        for (final j in deal.hot) M5PmLines.hotCard(j),
        M5PmLines.workCard,
        if (looseFixed) M5PmLines.nutCard,
        if (deal.oilChanged) M5PmLines.oilCard,
      };

  /// Every card offered (true and untrue), shuffled.
  List<String> logPool(math.Random rng) => [
        for (final j in deal.hot) M5PmLines.hotCard(j),
        M5PmLines.hotCard(deal.decoy),
        M5PmLines.workCard,
        M5PmLines.nutCard,
        M5PmLines.oilCard,
        ...deal.untrueWork,
      ]..shuffle(rng);

  void place(String card) {
    if (_open && stage == M5PmStage.logbook) page.add(card);
  }

  void unplace(String card) {
    if (_open && stage == M5PmStage.logbook) page.remove(card);
  }

  /// "সই": a wrong page is a slip and its untrue cards come off.
  DoMistake? sign() {
    if (!_open || stage != M5PmStage.logbook) return null;
    final truth = logTrue;
    if (!setEquals(page, truth)) {
      page.removeWhere((c) => !truth.contains(c));
      return _slip(M5PmMistakes.wrongSign);
    }
    roundDone = true;
    if (thorough) _tag(M5PmLines.caughtLog);
    return null;
  }

  // --- the coworker --------------------------------------------------------
  /// Listened to him: a slip. Push A: he climbs down at once (what was left
  /// stays left).
  DoMistake listen() {
    listened = true;
    if (!deal.pushB) {
      aloft = false;
      roundDone = true;
      return _slip(M5PmMistakes.pushA);
    }
    return _slip(M5PmMistakes.pushB);
  }

  /// A repaired joint reads like the same joint on the other two phases.
  Map<M5PmJoint, int> get cooled => {
        for (final j in jointsDone)
          j: ([for (var i = 0; i < 3; i++) if (i != j.phase) deal.temps[(place: j.place, phase: i)]!]..sort()).first + 1,
      };

  void next() {
    index++;
    roundSlips = 0;
    roundDone = false;
    if (stage == M5PmStage.tighten && !done) aloft = true;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   স্ক্যান: sweep ~8 joints ≈ 14000 + reason ~8200 + স্ক্যান শেষ 1500
///   শাটডাউন: 5 buttons ≈ 7500 + reason ~8200
///   টাইট: 2 joints × 3000 + 4 nuts × 2000 + reason ~8200 + নামুন 1500
///   line clear + re-glance ≈ 3600 (no input)
///   লগবুক: 5 cards × 1500 + sign + reason ~8200
/// + the coworker once ≈ 9600                                    ≈ 92000
/// 85 % ≈ 78000 → 80 s.
const m5PmQuickMs = 80000;

/// The shutdown buttons, shuffled so that the row never reads left to right
/// in a working order (no answer in the layout).
List<M5PmTool> m5PmToolRow(math.Random rng) {
  final tools = [...M5PmTool.values];
  do {
    tools.shuffle(rng);
  } while (m5PmInWorkOrder(tools));
  return tools;
}

/// True if tapping [row] from left to right would read as the working order.
bool m5PmInWorkOrder(List<M5PmTool> row) {
  int at(M5PmTool t) => row.indexOf(t);
  final steps = at(M5PmTool.phone) < at(M5PmTool.permit) && at(M5PmTool.permit) < at(M5PmTool.tester) && at(M5PmTool.tester) < at(M5PmTool.earth);
  return steps || (at(M5PmTool.permit) < at(M5PmTool.tester) && row.last == M5PmTool.wrench);
}

@immutable
class M5PmPack {
  const M5PmPack({required this.id, required this.titleBn, this.quickMs = m5PmQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5PmPack> m5PmThermalRoundPacks = {
  'do_5_10_a': M5PmPack(id: 'do_5_10_a', titleBn: M5PmLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M5PmThermalRoundPage extends StatefulWidget {
  const M5PmThermalRoundPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M5PmPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M5PmThermalRoundPage> createState() => _M5PmThermalRoundPageState();
}

class _M5PmThermalRoundPageState extends State<M5PmThermalRoundPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PmRunPage(
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

class _PmRunPage extends ConsumerStatefulWidget {
  const _PmRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M5PmPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PmRunPage> createState() => _PmRunPageState();
}

/// Which reason the table is asking.
enum _Why { hot, ptw, nut, log }

class _PmRunPageState extends ConsumerState<_PmRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5PmRun _run;
  late final List<M5PmTool> _tools;
  late final int _seed = _run.deal.light * 13 + _run.deal.hot.first.place.index * 3 + _run.deal.hot.first.phase;
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
  _Why _why = _Why.hot;

  // স্ক্যান: the camera's window (design px), the hold ring.
  late final ValueNotifier<Offset> _finder = ValueNotifier(Offset.zero);
  var _finderSet = false;
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_onRing);
  var _dragging = false;
  Offset _anchor = Offset.zero;
  M5PmJoint? _holdJoint;
  int _shotTok = 0;

  // শাটডাউন: the tester's reading.
  var _tester = false;
  Timer? _testerTimer;

  // টাইট: the target under the wrench.
  final _turn = ValueNotifier<(int, double, double)>((-1, 0, 0));
  int? _active;
  double _lastA = 0;
  double _accum = 0;
  Offset? _tightAt;
  int _tightTok = 0;

  // The line clear and the re-glance (no input).
  var _clearing = false;
  var _earthOff = false;
  var _reglance = false;

  // লগবুক.
  List<String> _pool = const [];

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _hintN = 0;
  final Map<M5PmTool, GlobalKey> _toolKeys = {for (final t in M5PmTool.values) t: GlobalKey()};
  final Map<String, GlobalKey> _cardKeys = {};
  final _pageKey = GlobalKey();
  M5PmGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    // The deal first (a seed's play is the same), then the tool row.
    _run = M5PmRun(m5PmDeal(widget.rng));
    _tools = m5PmToolRow(widget.rng);
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _testerTimer?.cancel();
    _ring.dispose();
    _finder.dispose();
    _turn.dispose();
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
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze && !_clearing;

  String get _task => switch (_run.stage) {
        M5PmStage.scan => M5PmLines.askScan,
        M5PmStage.shutdown => M5PmLines.askShutdown,
        M5PmStage.tighten => M5PmLines.askTighten,
        M5PmStage.logbook => M5PmLines.askLog,
      };

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  void _startRound() {
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  void _resume() {
    if (!mounted || _ended) return;
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  // --- স্ক্যান -------------------------------------------------------------------
  void _scanStart(M5PmGeo geo) {
    if (!_canPlay || _run.stage != M5PmStage.scan) return;
    _dragging = true;
    _anchor = _finder.value;
    // A finger put down while the window already sits on a joint and held
    // still photographs it too.
    _restartHold(geo);
  }

  void _scanMove(Offset delta, M5PmGeo geo) {
    if (!_dragging) return;
    if (!_canPlay) {
      _scanStop();
      return;
    }
    _finder.value = geo.clampFinder(_finder.value + delta);
    if ((_finder.value - _anchor).distance > 4) {
      _anchor = _finder.value;
      _restartHold(geo);
    }
  }

  void _restartHold(M5PmGeo geo) {
    _ring.stop();
    _ring.value = 0;
    _holdJoint = null;
    final j = geo.jointAt(_finder.value);
    if (j == null || _run.snapped.contains(j) || _run.wrongSnapped.contains(j)) return;
    _holdJoint = j;
    unawaited(_ring.forward(from: 0));
  }

  void _scanStop() {
    _dragging = false;
    _holdJoint = null;
    _ring.stop();
    _ring.value = 0;
  }

  void _onRing(AnimationStatus s) {
    if (s != AnimationStatus.completed) return;
    final j = _holdJoint;
    final geo = _geoNow;
    _ring.value = 0;
    _holdJoint = null;
    if (j == null || geo == null || !_dragging || !_canPlay || geo.jointAt(_finder.value) != j) return;
    _snap(j, geo);
  }

  void _snap(M5PmJoint j, M5PmGeo geo) {
    _cue('sounds/intro/click.ogg', volume: 0.8);
    HapticFeedback.lightImpact();
    final m = _run.snap(j);
    setState(() {
      _shotTok++;
      _wake++;
    });
    final origin = _toGlobal(geo.joint(j));
    if (m != null) {
      _scanStop();
      unawaited(_mistake(m, origin));
      return;
    }
    if (_run.snapped.length == 1) {
      _scanStop();
      _hush();
      _cue('sounds/learn/tag_slap.wav', volume: 0.7);
      _cue('sounds/quiz_right.wav', volume: 0.6);
      putOnTable(15);
      _askWhy(_Why.hot);
      return;
    }
    _cue('sounds/quiz_right.wav', volume: 0.6);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(_sayChain([M5PmLines.snapMore], mood: GuideMood.glad));
  }

  void _endScan(Offset global) {
    if (!_canPlay || _run.stage != M5PmStage.scan) return;
    _tick('sounds/intro/click.ogg', 0.5);
    _scanStop();
    final m = _run.endScan();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    _hush();
    _cue('sounds/learn/tag_slap.wav', volume: 0.6);
    unawaited(_levelDelta(5, global, mood: GuideMood.glad));
    unawaited(_sayChain([M5PmLines.scanAll], mood: GuideMood.glad));
    final idx = _run.index;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1200), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- শাটডাউন -------------------------------------------------------------------
  void _useTool(M5PmTool t, Offset global) {
    if (!_canPlay || _run.stage != M5PmStage.shutdown) return;
    _tick(t == M5PmTool.permit ? 'sounds/learn/tag_slap.wav' : 'sounds/intro/click.ogg', 0.5);
    final m = _run.use(t);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    switch (t) {
      case M5PmTool.tester:
        _testerTimer?.cancel();
        setState(() => _tester = true);
        _testerTimer = Timer(const Duration(milliseconds: 2200), () {
          if (mounted) setState(() => _tester = false);
        });
      case M5PmTool.earth:
        _cue('sounds/intro/impact_metal.ogg', volume: 0.55);
      default:
        break;
    }
    if (_run.roundDone) {
      _hush();
      HapticFeedback.mediumImpact();
      _cue('sounds/learn/tag_slap.wav', volume: 0.7);
      _cue('sounds/quiz_right.wav', volume: 0.6);
      putOnTable(15 + (_run.thorough ? 5 : 0));
      _askWhy(_Why.ptw);
    }
  }

  // --- টাইট ----------------------------------------------------------------------
  /// The wrench targets: the snapped joints first, then the hardware nuts.
  List<Offset> _targets(M5PmGeo geo) => [for (final j in _run.deal.hot) geo.joint(j), for (final n in _run.deal.nuts) geo.nut(n)];

  List<bool> get _targetDone => [
        for (final j in _run.deal.hot) _run.jointsDone.contains(j),
        for (final n in _run.deal.nuts) _run.nutsChecked.contains(n),
      ];

  double _need(int i) {
    final hot = _run.deal.hot;
    return i < hot.length ? m5PmFullTurn : _run.turnForNut(_run.deal.nuts[i - hot.length]);
  }

  bool _turns(int i) {
    final hot = _run.deal.hot;
    return i < hot.length || _run.deal.nuts[i - hot.length] == _run.deal.loose;
  }

  void _turnStart(Offset p, M5PmGeo geo) {
    if (!_canPlay || _run.stage != M5PmStage.tighten) return;
    final targets = _targets(geo);
    final done = _targetDone;
    int? best;
    var bestD = M5PmGeo.targetHit + 8;
    for (final (i, c) in targets.indexed) {
      final d = (c - p).distance;
      if (!done[i] && d <= bestD) {
        bestD = d;
        best = i;
      }
    }
    if (best == null) {
      _hints.missTap();
      return;
    }
    final c = targets[best];
    _active = best;
    _lastA = math.atan2(p.dy - c.dy, p.dx - c.dx);
    _accum = 0;
    _turn.value = (best, 0, 0);
    _tick('sounds/intro/tick.ogg', 0.35);
  }

  void _turnMove(Offset p, M5PmGeo geo) {
    final i = _active;
    if (i == null) return;
    if (!_canPlay) {
      _turnStop();
      return;
    }
    final c = _targets(geo)[i];
    if ((p - c).distance < 3) return;
    final a = math.atan2(p.dy - c.dy, p.dx - c.dx);
    var d = a - _lastA;
    if (d > math.pi) d -= 2 * math.pi;
    if (d < -math.pi) d += 2 * math.pi;
    _lastA = a;
    _accum += d;
    final need = _need(i);
    _turn.value = (i, _turns(i) ? _accum : 0, _accum.abs() / (2 * math.pi));
    if (_accum.abs() >= need) _turnDone(i, geo);
  }

  void _turnStop() {
    _active = null;
    _accum = 0;
    _turn.value = (-1, 0, 0);
  }

  void _turnDone(int i, M5PmGeo geo) {
    _turnStop();
    final hot = _run.deal.hot;
    final at = _targets(geo)[i];
    final origin = _toGlobal(at);
    _cue('sounds/intro/impact_metal.ogg', volume: 0.5);
    HapticFeedback.mediumImpact();
    if (i < hot.length) {
      _run.wrenchJoint(hot[i]);
      setState(() => _wake++);
      unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
      unawaited(_sayChain([M5PmLines.jointDone], mood: GuideMood.glad));
      if (_run.hotDone && !_run.deal.pushB && !coworkerDone) scheduleCoworker();
      return;
    }
    final loose = _run.wrenchNut(_run.deal.nuts[i - hot.length]);
    setState(() {
      _wake++;
      _tightAt = at;
      _tightTok++;
    });
    if (loose) {
      _hush();
      _cue('sounds/learn/tag_slap.wav', volume: 0.7);
      _cue('sounds/quiz_right.wav', volume: 0.6);
      putOnTable(15);
      _askWhy(_Why.nut);
    }
  }

  void _climbDown(Offset global) {
    if (!_canPlay || _run.stage != M5PmStage.tighten) return;
    // He is due (push A): "নামুন" waits for him.
    if (holdForCoworker()) return;
    _tick('sounds/intro/click.ogg', 0.5);
    final m = _run.climbDown();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    unawaited(_lineClear());
  }

  /// The line clear (not scored) and a short IR re-glance; then the logbook.
  Future<void> _lineClear() async {
    if (_clearing || _ended) return;
    _hush();
    setState(() {
      _clearing = true;
      _wake++;
    });
    unawaited(_sayChain([M5PmLines.lineClear]));
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 700 : 1600));
    if (!mounted || _ended) return;
    final geo = _geoNow;
    setState(() {
      _earthOff = true;
      _reglance = true;
      if (geo != null) _finder.value = geo.joint(_run.deal.hot.first);
      _finderSet = true;
    });
    _cue('sounds/intro/click.ogg', volume: 0.6);
    unawaited(_sayChain([M5PmLines.reglance]));
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 900 : 1900));
    if (!mounted || _ended) return;
    setState(() {
      _reglance = false;
      _clearing = false;
      _run.next();
      _pool = _run.logPool(widget.rng);
    });
    if (_run.deal.pushB && !coworkerDone) scheduleCoworker();
    _startRound();
  }

  // --- লগবুক ---------------------------------------------------------------------
  void _toggleCard(String card) {
    if (!_canPlay || _run.stage != M5PmStage.logbook) return;
    _tick('sounds/learn/card_deal_a.wav', 0.45);
    setState(() {
      if (_run.page.contains(card)) {
        _run.unplace(card);
      } else {
        _run.place(card);
      }
      _wake++;
    });
  }

  void _dropCard(String card) {
    if (!_canPlay || _run.stage != M5PmStage.logbook || _run.page.contains(card)) return;
    _tick('sounds/learn/tag_slap.wav', 0.45);
    setState(() {
      _run.place(card);
      _wake++;
    });
  }

  void _sign(Offset global) {
    if (!_canPlay || _run.stage != M5PmStage.logbook) return;
    // He is due (push B): "সই" waits for him.
    if (holdForCoworker()) return;
    _tick('sounds/learn/tag_slap.wav', 0.55);
    final m = _run.sign();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_right.wav', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    _askWhy(_Why.log);
  }

  // --- reasons -------------------------------------------------------------------
  void _askWhy(_Why why) {
    _why = why;
    final idx = _run.index;
    final oil = _run.deal.oilChanged;
    final (right, question) = switch (why) {
      _Why.hot => (M5PmLines.hotWhy, M5PmLines.hotWhyQ),
      _Why.ptw => (M5PmLines.ptwWhy, M5PmLines.ptwWhyQ),
      _Why.nut => (M5PmLines.nutWhy, M5PmLines.nutWhyQ),
      _Why.log => oil ? (M5PmLines.oilWhy, M5PmLines.oilWhyQ) : (M5PmLines.logWhy, M5PmLines.logWhyQ),
    };
    unawaited(askReason(
      deal: () => dealChoices(right, M5PmLines.myths, widget.rng),
      question: question,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
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
    final why = _why;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (!mounted || _ended || _run.index != idx) return;
      // The shutdown and the logbook end their round; the hotspot and the
      // nut reasons come mid-round and the round goes on.
      if (_run.roundDone && (why == _Why.ptw || why == _Why.log)) {
        _next();
      } else {
        _resume();
      }
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => _run.deal.pushB ? M5PmLines.coworkerB : M5PmLines.coworkerA;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    final stage = _run.deal.pushB ? M5PmStage.logbook : M5PmStage.tighten;
    if (_run.stage != stage || _run.roundDone) return null;
    if (_intro || _card != null || tableBusy || _freeze || _clearing || _active != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.listen();
      setState(() => _wake++);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(_run.deal.pushB ? M5PmLines.caughtCallB : M5PmLines.caughtCallA);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([_run.deal.pushB ? M5PmLines.callHeldB : M5PmLines.callHeldA, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5PmLines.tapWhy[_nudgeN++ % M5PmLines.tapWhy.length]
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
    final speak = await SpokenOnce.first('pmthermal/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A wrench on the line before it is proved dead and earthed: the scene
  /// freezes grey and the flash comes off the joint in colour; then
  /// near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _testerTimer?.cancel();
    _scanStop();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _tester = false;
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
    final speak = await SpokenOnce.first('pmthermal/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5PmLines.deadlyWord : M5PmLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        // Listened to push A: he is already down — the line clear follows.
        if (_run.stage == M5PmStage.tighten && _run.roundDone) {
          unawaited(_lineClear());
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
    await _say(!_run.passed ? M5PmLines.fail : (_quickBonus ? M5PmLines.quick : M5PmLines.allSet),
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
  /// A design-px point of the scene in global coordinates (for the flying ◆).
  Offset _toGlobal(Offset design) {
    final size = MediaQuery.sizeOf(context);
    final k = size.width / 360;
    final geo = _geoNow;
    final dy = geo == null ? 0.0 : (size.height - geo.height * k) / 2;
    return Offset(design.dx * k, design.dy * k + dy);
  }

  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_run.aloft || _run.stage == M5PmStage.scan) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  static const _mateLook = LinemanLook(
    helmet: Color(0xFFF4F4F4),
    shirt: Color(0xFF5B6B3A),
    vest: Color(0xFFFFC02E),
    pants: Color(0xFF2E3440),
    skin: Color(0xFF9C6440),
    moustache: true,
    gloves: true,
  );

  M5PmRig get _rig => M5PmRig(
        earthOn: _run.earthed && !_earthOff,
        snapped: _run.snapped,
        light: _run.deal.light,
        oil: m5PmOils[_run.deal.oilToday],
      );

  /// The gesture hand: how to touch, never what.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    switch (_run.stage) {
      case M5PmStage.scan:
        // The camera dragged a short way toward the empty sky (the same way
        // every play), then a hold ring — only where no joint is under it.
        final c = _finder.value;
        final onJoint = geo.jointAt(c, within: 30) != null;
        if ((_hintN++).isOdd && !onJoint) return HintSpec.hold(c, space: HintSpace.scene);
        final sky = geo.skyBand.center - c;
        final toward = sky.distance < 8 ? const Offset(-1, 0) : sky;
        return HintSpec.drag(c, toward: toward, travel: 64, space: HintSpace.scene);
      case M5PmStage.shutdown:
        return HintSpec.sweepOver([for (final t in _tools) _toolKeys[t]!]);
      case M5PmStage.tighten:
        // Every wrench target alike, top to bottom, left to right.
        final pts = _targets(geo)..sort((a, b) => a.dy == b.dy ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
        final rects = [for (final p in pts) Rect.fromCircle(center: p, radius: M5PmGeo.targetHit)];
        return rects.length < 2 ? null : HintSpec.sweep(rects, space: HintSpace.scene);
      case M5PmStage.logbook:
        final pageRect = HintSpec.globalRectOf(_pageKey);
        if ((_hintN++).isOdd && pageRect != null) {
          // A page-curl on the logbook.
          return HintSpec.swipe(Offset(pageRect.right - 18, pageRect.bottom - 12), toward: const Offset(-1, -0.5), travel: 80);
        }
        final cards = [for (final c in _pool) ?_cardKeys[c]];
        final spec = HintSpec.sweepOver(cards);
        if (spec != null && spec.options.length >= 2) return spec;
        return pageRect == null ? null : HintSpec.swipe(Offset(pageRect.right - 18, pageRect.bottom - 12), toward: const Offset(-1, -0.5), travel: 80);
    }
  }

  bool _toolOn(M5PmTool t) => switch (t) {
        M5PmTool.phone => _run.phone,
        M5PmTool.permit => _run.permit,
        M5PmTool.tester => _run.tested,
        M5PmTool.earth => _run.earthed,
        M5PmTool.wrench => false,
      };

  static const _icons = {
    M5PmTool.phone: Icons.phone_in_talk_rounded,
    M5PmTool.permit: Icons.assignment_turned_in_rounded,
    M5PmTool.tester: Icons.flash_on_rounded,
    M5PmTool.earth: Icons.link_rounded,
    M5PmTool.wrench: Icons.build_rounded,
  };

  void _tapScene(Offset p, M5PmGeo geo) {
    if (!_canPlay) return;
    _hints.missTap();
  }

  void _panStart(Offset p, M5PmGeo geo) {
    if (!_canPlay) return;
    switch (_run.stage) {
      case M5PmStage.scan:
        _scanStart(geo);
      case M5PmStage.tighten:
        _turnStart(p, geo);
      default:
        _hints.missTap();
    }
  }

  void _panUpdate(DragUpdateDetails d, M5PmGeo geo) {
    switch (_run.stage) {
      case M5PmStage.scan:
        _scanMove(d.delta, geo);
      case M5PmStage.tighten:
        _turnMove(d.localPosition, geo);
      default:
        break;
    }
  }

  void _panEnd() {
    if (_dragging) _scanStop();
    if (_active != null) _turnStop();
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5PmGeo.forScene(m.height, m.inset);
    if (!_finderSet) {
      _finder.value = geo.finderHome;
      _anchor = _finder.value;
      _finderSet = true;
    }
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final tb = _run.aloft ? geo.aloft : geo.ground;
    final scanning = _run.stage == M5PmStage.scan && !_run.done;
    final tightening = _run.stage == M5PmStage.tighten && _run.aloft && !_clearing;
    final tight = _tightAt;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('dp'),
                child: RepaintBoundary(child: CustomPaint(painter: M5PmPainter(geo: geo, rig: _rig, seed: _seed))),
              ),
              Positioned.fromRect(
                key: const ValueKey('schedule'),
                rect: Rect.fromLTWH(geo.van.left - 6, geo.van.top - 17, 70, 13),
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: const Color(0xFFFFF4D6), borderRadius: BorderRadius.circular(3), border: Border.all(color: const Color(0xFFC48A2E))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FittedBox(
                        child: Text(M5PmLines.schedule, style: bangla(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF5A3B0E))),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('mate'),
                rect: geo.mate,
                child: LinemanFigure(look: _mateLook, mode: _run.earthed && !_earthOff ? LinemanMode.point : LinemanMode.idle, wake: _wake, quiet: quiet),
              ),
              if (_run.aloft)
                Positioned.fill(
                  key: const ValueKey('strap'),
                  child: IgnorePointer(child: CustomPaint(painter: M5PmStrapPainter(box: tb))),
                ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: tb,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
              if (scanning || _reglance)
                Positioned.fill(
                  key: const ValueKey('camera'),
                  child: IgnorePointer(child: CustomPaint(painter: M5PmCameraPainter(box: geo.ground))),
                ),
            ],
          ),
        ),
      ),
      if (_tester && !_freeze)
        Positioned(
          key: const ValueKey('tester'),
          left: geo.ground.left - 18,
          top: geo.ground.top - 40,
          child: const IgnorePointer(child: _TesterChip()),
        ),
      if (tightening && !_freeze)
        Positioned.fill(
          key: const ValueKey('wrench'),
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: M5PmWrenchPainter(targets: _targets(geo), done: _targetDone, turn: _turn)),
            ),
          ),
        ),
      // A tight nut clicked: a short "টাইট" over it.
      if (tight != null && tightening && !_freeze)
        Positioned(
          key: ValueKey('tight-$_tightTok'),
          left: tight.dx - 30,
          top: tight.dy - 40,
          width: 60,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 1100),
              builder: (_, v, _) => v <= 0.001
                  ? const SizedBox.shrink()
                  : Opacity(
                      opacity: v,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xEE101A2B), borderRadius: BorderRadius.circular(8)),
                          child: Text(M5PmLines.tight, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: SlmColors.success)),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5PmLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The camera and the wrench follow the finger from where it went
            // down (no lost slop).
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d, geo),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: _panEnd,
          ),
        ),
      ),
      if ((scanning || _reglance) && !_freeze)
        Positioned.fill(
          key: const ValueKey('finder'),
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: M5PmFinderPainter(geo: geo, at: _finder, ring: _ring, temps: _run.deal.temps, cooled: _run.cooled),
              ),
            ),
          ),
        ),
      // The shutter: a short white flash in the camera's window.
      if (_shotTok > 0 && scanning && !_freeze)
        Positioned.fromRect(
          key: ValueKey('shot-$_shotTok'),
          rect: M5PmGeo.finderRect(_finder.value),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 0 : 0.8, end: 0),
              duration: const Duration(milliseconds: 320),
              builder: (_, v, _) => v <= 0.001
                  ? const SizedBox.shrink()
                  : DecoratedBox(decoration: BoxDecoration(color: Color.fromRGBO(255, 255, 255, v), borderRadius: BorderRadius.circular(10))),
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
              builder: (_, v, _) => CustomPaint(painter: M5PmFlashPainter(at: geo.joint(_run.deal.hot.first), v: v)),
            ),
          ),
        ),
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

  Widget _logbook(double maxHeight) {
    final placed = [for (final c in _pool) if (_run.page.contains(c)) c];
    final free = [for (final c in _pool) if (!_run.page.contains(c)) c];
    GlobalKey keyOf(String c) => _cardKeys.putIfAbsent(c, GlobalKey.new);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF6EFDC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF243F7A), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Color(0xFF243F7A), size: 22),
                  const SizedBox(width: 6),
                  Text(M5PmLines.logbook, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1C2E4A))),
                  const SizedBox(width: 8),
                  _GaugePhoto(label: M5PmLines.lastPm, oil: m5PmOils[_run.deal.oilLast]),
                  const SizedBox(width: 6),
                  _GaugePhoto(label: M5PmLines.today, oil: m5PmOils[_run.deal.oilToday]),
                  const Spacer(),
                  // সই in the header: always in reach, however many cards.
                  _ActionButton(key: const ValueKey('m5pm-sign'), icon: Icons.draw_rounded, label: M5PmLines.sign, onTap: _sign),
                ],
              ),
              const SizedBox(height: 6),
              DragTarget<String>(
                onWillAcceptWithDetails: (d) => !_run.page.contains(d.data),
                onAcceptWithDetails: (d) => _dropCard(d.data),
                builder: (context, cand, _) => Container(
                  key: _pageKey,
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cand.isEmpty ? const Color(0xFFFFFDF6) : const Color(0xFFFFF4C9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFB9A57A), width: 1.4),
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in placed)
                        _LogCard(key: ValueKey('log-on-$c'), text: c, onPage: true, onTap: () => _toggleCard(c)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in free)
                    Draggable<String>(
                      key: ValueKey('log-pool-$c'),
                      data: c,
                      feedback: Material(type: MaterialType.transparency, child: _LogCardBody(text: c, onPage: false, lifted: true)),
                      childWhenDragging: Opacity(opacity: 0.3, child: _LogCardBody(text: c, onPage: false)),
                      child: KeyedSubtree(key: keyOf(c), child: _LogCard(text: c, onPage: false, onTap: () => _toggleCard(c))),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null && !_clearing && !_run.done;
    final stage = _run.stage;
    final logUp = handsOn && stage == M5PmStage.logbook;
    final logMax = math.min(480.0, size.height * 0.58);
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
              labels: M5PmLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 4); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !_dragging && _active == null,
            hintKey: '${_run.index}/${_run.snapped.length}/${_run.jointsDone.length}/${_run.nutsChecked.length}/${_run.page.length}/$strikes',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && stage == M5PmStage.shutdown)
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 2,
                  right: 2,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final t in _tools)
                        _ToolButton(
                          key: _toolKeys[t],
                          icon: _icons[t]!,
                          label: M5PmLines.toolLabel(t),
                          on: _toolOn(t),
                          onTap: (g) => _useTool(t, g),
                        ),
                    ],
                  ),
                ),
              if (handsOn && (stage == M5PmStage.scan || stage == M5PmStage.tighten))
                Positioned(
                  key: ValueKey('hud-act-${stage.name}'),
                  right: 12,
                  bottom: pad.bottom + 14,
                  child: stage == M5PmStage.scan
                      ? _ActionButton(icon: Icons.task_alt_rounded, label: M5PmLines.scanDone, onTap: _endScan)
                      : _ActionButton(icon: Icons.south_rounded, label: M5PmLines.down, onTap: _climbDown),
                ),
              if (logUp)
                Positioned(
                  key: const ValueKey('hud-logbook'),
                  left: 0,
                  right: 0,
                  bottom: pad.bottom,
                  child: _logbook(logMax),
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
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (logUp ? logMax + 8 : deckUp ? 236 : 84),
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
                  line: M5PmLines.intro,
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

class _TesterChip extends StatelessWidget {
  const _TesterChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xEE101A2B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6E7C90), width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 14, height: 14, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3A3F45))),
          const SizedBox(width: 6),
          Text(M5PmLines.testerDead, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }
}

/// A shutdown button: a round icon with its name under it; lit once done.
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
          width: 66,
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

/// "স্ক্যান শেষ" / "নামুন" / "সই": a pill with an icon.
class _ActionButton extends StatelessWidget {
  const _ActionButton({super.key, required this.icon, required this.label, required this.onTap});
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
          constraints: const BoxConstraints(minHeight: 48, minWidth: 96),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: SlmColors.gold300),
              const SizedBox(width: 6),
              Text(label, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A logbook card (tap to put it on the page / take it off).
class _LogCard extends StatelessWidget {
  const _LogCard({super.key, required this.text, required this.onPage, required this.onTap});
  final String text;
  final bool onPage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: _LogCardBody(text: text, onPage: onPage)),
    );
  }
}

class _LogCardBody extends StatelessWidget {
  const _LogCardBody({required this.text, required this.onPage, this.lifted = false});
  final String text;
  final bool onPage;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34, maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: onPage ? const Color(0xFF1F3B63) : const Color(0xFF1C2E4A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: onPage ? const Color(0xFF9FC3EF) : const Color(0xFF55657E), width: 1.4),
        boxShadow: lifted ? const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4))] : null,
      ),
      child: Text(text, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, height: 1.2, color: SlmColors.ivory)),
    );
  }
}

/// A photo of the oil gauge glass in the logbook.
class _GaugePhoto extends StatelessWidget {
  const _GaugePhoto({required this.label, required this.oil});
  final String label;
  final Color oil;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 40, height: 34, child: CustomPaint(painter: M5PmGaugePhotoPainter(oil: oil))),
          const SizedBox(height: 2),
          Text(label, style: bangla(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF1C2E4A))),
        ],
      ),
    );
  }
}
