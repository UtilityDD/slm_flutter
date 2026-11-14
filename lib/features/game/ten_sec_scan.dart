import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
import 'kit_check.dart' show KitDeath, KitDeathView;
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;

// Lesson 1.10, কাজ 1: "10 সেকেন্ডের স্ক্যান" (ladder step 29).
//
// The lesson's own 10-second safety scan (lesson 1.10, point 2), one check
// per question, in the lesson's order — the first five personal, the next
// five the surroundings:
//    1. PPE (helmet to sole: lesson 1.1)
//    2. harness worn and secure (lesson 1.4)
//    3. tools in order and at hand (the discharge rod: lesson 1.5)
//    4. the permit number and conditions (lesson 1.6)
//    5. state of mind — tired, distracted, rushed (lesson 1.10)
//    6. the pole, checked myself (lesson 1.3)
//    7. the লক্ষ্মণ রেখা (lesson 1.2)
//    8. other dangers: water, traffic, bees (lessons 1.3, 1.10)
//    9. the weather (lesson 1.9)
//   10. escape route and rescue plan (lesson 1.10)
//
// Each check shows one picture and the lesson's question (never the answer);
// the player presses GO or STOP. Every play deals which checks are safe and
// which fault each other check has, with at least one deadly-class fault and
// at least four safe checks. Owner rulings 2026-11-08: a nail in the sole,
// polyester/synthetic clothing and cut or frayed harness webbing are deadly;
// an expired harness label with no damage is a slip. A deadly GO freezes the
// scene grey, plays the consequence in colour, then DoDeathGuard.bookDeadly.
// Scoring is the shared Do rule: 100 − 15 per slip, pass ≥ 55, 3 slips strike
// out. The careless coworker comes once (recorded voice), on a dealt check of
// either kind; after him the same check is asked.

// ============================================================================
// Content & models
// ============================================================================

const kTenSecQuickMs = 45000;

@immutable
class TenSecPack {
  const TenSecPack({required this.id, required this.titleBn, this.quickMs = kTenSecQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const tenSecPacks = {
  'do_1_10_a': TenSecPack(id: 'do_1_10_a', titleBn: TenSecLines.title),
};

/// The lesson's ten questions, in the lesson's order.
enum ScanTopic { ppe, harness, tools, permit, mind, pole, rekha, around, weather, escape }

/// What a deadly GO does, played in colour over the frozen scene.
enum ScanDeath { synthetic, nail, shock, arc, fall, collapse, strike }

@immutable
class TenSecTopic {
  const TenSecTopic({required this.topic, required this.nameBn, required this.askBn, required this.whyWrong});
  final ScanTopic topic;

  /// The short name on the card's header.
  final String nameBn;

  /// The lesson's own question (the card's caption; never the answer).
  final String askBn;

  /// Wrong reasons (myths and excuses) for every check of this question.
  final List<String> whyWrong;
}

@immutable
class TenSecCheck {
  const TenSecCheck({
    required this.id,
    required this.topic,
    required this.art,
    required this.whyRight,
    required this.caughtTag,
    this.fault,
    this.death,
  });

  final String id;
  final ScanTopic topic;
  final String art;

  /// Null = safe (GO is right); else the fault STOP catches.
  final DoMistake? fault;

  /// How a GO on a deadly fault kills (null unless the fault is deadly).
  final ScanDeath? death;
  final List<String> whyRight;
  final String caughtTag;

  bool get isSafe => fault == null;
  bool get deadly => fault?.deadly ?? false;
}

const _art = 'assets/game/art/scan_board';

abstract final class TenSecMistakes {
  // 1 — PPE (lesson 1.1)
  static const helmetCrack = DoMistake(
    key: '1.10/scan/helmet-crack',
    textBn: 'ফাটল ধরা হেলমেট মানে ফুটো ছাতা — আঘাতের শক আর নিতে পারে না। তখনই বদলান।',
    art: '$_art/kit_helmet_crack.svg',
    lessonPoint: 1,
  );
  static const bootsNail = DoMistake(
    key: '1.10/scan/boots-nail',
    textBn: 'সোলে পেরেক বা মেটাল ঢুকে থাকলে কারেন্ট মাটিতে নামার রাস্তা পায় — সাক্ষাৎ মৃত্যুফাঁদ।',
    art: '$_art/kit_nail_sole.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const polyester = DoMistake(
    key: '1.10/scan/dirty-polyester',
    textBn: 'পলিয়েস্টার বা সিন্থেটিক জামা স্পার্কে গলে চামড়ায় সেঁটে যায় — 100% সুতি বা FR কাপড় চাই।',
    art: '$_art/kit_polyester.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const gloveLeak = DoMistake(
    key: '1.10/scan/no-air-test',
    textBn: 'এয়ার টেস্টে সামান্য লিক থাকলেও সেই গ্লাভস নয় — পিনের ডগার মতো ফুটোতেও মৃত্যু নিশ্চিত।',
    art: '$_art/kit_glove_leak.svg',
    deadly: true,
    lessonPoint: 1,
  );

  // 2 — harness (lesson 1.4)
  static const looseChest = DoMistake(
    key: '1.10/scan/loose-harness',
    textBn: 'ঢিলেঢালা হারনেস পতনের সময় শরীর থেকে খুলে যেতে পারে — বুকের ফিতে আঁটুন।',
    art: '$_art/harness_loose_chest.svg',
    lessonPoint: 1,
  );
  static const chestHigh = DoMistake(
    key: '1.10/scan/chest-strap-high',
    textBn: 'বুকের ফিতে থাকবে বুকের মাঝ বরাবর — ভুল জায়গায় চাপে গুরুতর আঘাত হয়।',
    art: '$_art/harness_chest_high.svg',
    lessonPoint: 1,
  );
  static const twisted = DoMistake(
    key: '1.10/scan/twisted-strap',
    textBn: 'ফিতে পেঁচিয়ে থাকলে ফিটিং ভুল — পড়লে ভুল জায়গায় চাপ পড়ে গুরুতর আঘাত হয়।',
    art: '$_art/harness_twisted.svg',
    lessonPoint: 1,
  );
  static const frayedWebbing = DoMistake(
    key: '1.10/scan/frayed-webbing',
    textBn: 'ছোট কাটা বা ছেঁড়া ফিতেই হারনেসের শক্তি 50% পর্যন্ত কমিয়ে দেয় — সেই হারনেস বাতিল।',
    art: '$_art/harness_frayed.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const expiredLabel = DoMistake(
    key: '1.10/scan/expired-harness',
    textBn: 'লেবেলের মেয়াদ পেরিয়ে গেছে — দেখতে মজবুত হলেও মেয়াদ উত্তীর্ণ হারনেস ব্যবহার করা যাবে না।',
    art: '$_art/harness_label_expired.svg',
    lessonPoint: 1,
  );

  // 3 — tools (lesson 1.5)
  static const rodCracked = DoMistake(
    key: '1.10/scan/rod-cracked',
    textBn: 'রডের ইনসুলেটিং স্টিক হবে পরিষ্কার, শুকনো আর ফাটলমুক্ত — ভাঙা রড নিজেই পরিবাহী হতে পারে।',
    art: '$_art/tool_rod_cracked.svg',
    lessonPoint: 1,
  );
  static const rodPvc = DoMistake(
    key: '1.10/scan/rod-pvc',
    textBn: 'পিভিসি পাইপে মেটাল হুক লাগানো জুগাড় ডিসচার্জ রড নয় — স্ট্যান্ডার্ড রড ছাড়া কাজ নয়।',
    art: '$_art/tool_rod_pvc.svg',
    deadly: true,
    lessonPoint: 1,
  );

  // 4 — permit (lesson 1.6)
  static const verbalPtw = DoMistake(
    key: '1.10/scan/verbal-ptw',
    textBn: 'ফোনে "লাইন বন্ধ আছে" শুনে কাজ শুরু করা মারাত্মক ভুল — লিখিত, সই করা পারমিট চাই।',
    art: '$_art/ptw_verbal_phone.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const ptwNoRead = DoMistake(
    key: '1.10/scan/ptw-no-read',
    textBn: 'পারমিটের নম্বর, শর্ত আর ফিডারের নাম না মিলিয়ে কাজে নামা মারাত্মক ভুল।',
    art: '$_art/ptw_no_read.svg',
    deadly: true,
    lessonPoint: 1,
  );

  // 5 — state of mind (lesson 1.10)
  static const mindTired = DoMistake(
    key: '1.10/scan/mind-tired',
    textBn: 'ক্লান্ত বা বিক্ষিপ্ত মন ছোট কিন্তু জরুরি ধাপ ভুলে যায় — সন্দেহ হলে থামুন।',
    art: '$_art/mind_tired.svg',
    lessonPoint: 0,
  );
  static const mindRushed = DoMistake(
    key: '1.10/scan/mind-rushed',
    textBn: 'তাড়াহুড়ো চেকলিস্টের প্রধান শত্রু — এটা রেস নয়, আগে নিরাপদে বাড়ি ফেরা।',
    art: '$_art/mind_rushed.svg',
    lessonPoint: 0,
  );

  // 6 — pole (lesson 1.3)
  static const rustedPole = DoMistake(
    key: '1.10/scan/rusted-pole',
    textBn: 'মাটির সংযোগস্থলে মরিচা আর ভোঁতা শব্দ মানে পোল বিপজ্জনকভাবে দুর্বল — এই পোলে ওঠা নয়।',
    art: '$_art/pole_rusted_base.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const leaningPole = DoMistake(
    key: '1.10/scan/leaning-pole',
    textBn: 'হেলে থাকা পোল আপনার শরীরের ভারে ভেঙে পড়তে পারে — গোড়ায় ফাটল থাকলে ওঠা নয়।',
    art: '$_art/pole_lean.svg',
    deadly: true,
    lessonPoint: 1,
  );

  // 7 — লক্ষ্মণ রেখা (lesson 1.2)
  static const insideClearance = DoMistake(
    key: '1.10/scan/inside-clearance',
    textBn: 'লম্বা টুলের ডগাও আপনার হাত — না ছুঁয়েও বিদ্যুৎ বাতাস ভেদ করে লাফিয়ে আসে।',
    art: '$_art/clearance_inside.svg',
    deadly: true,
    lessonPoint: 1,
  );

  // 8 — other dangers (lessons 1.3, 1.10)
  static const beehive = DoMistake(
    key: '1.10/scan/beehive-crossarm',
    textBn: 'পোলে বোলতা বা মৌমাছির চাক মানেই বিপদ — না উঠে আগে জানান।',
    art: '$_art/hazard_beehive.svg',
    lessonPoint: 1,
  );
  static const traffic = DoMistake(
    key: '1.10/scan/traffic-no-barrier',
    textBn: 'আশেপাশের ট্র্যাফিকও বিপদ — চারপাশ না দেখে পা মাটি ছাড়বেন না।',
    art: '$_art/hazard_traffic.svg',
    lessonPoint: 1,
  );
  static const water = DoMistake(
    key: '1.10/scan/water-at-base',
    textBn: 'পোলের গোড়ায় জল জমে আছে — মাটি ক্ষয়েছে কিনা আগে গোড়া পরীক্ষা করুন।',
    art: '$_art/hazard_water.svg',
    lessonPoint: 1,
  );

  // 9 — weather (lesson 1.9)
  static const stormSky = DoMistake(
    key: '1.10/scan/storm-sky',
    textBn: 'বজ্রপাতে কোনো PPE কাজ করে না — এটা রেড লাইন। কাজ বন্ধ, ওঠা নয়।',
    art: '$_art/hazard_storm_sky.svg',
    deadly: true,
    lessonPoint: 1,
  );

  // 10 — escape and rescue (lesson 1.10)
  static const rescueBlocked = DoMistake(
    key: '1.10/scan/rescue-blocked',
    textBn: 'নামার পথ আটকানো — কিছু ভুল হলে কীভাবে নামবেন? আগে পথ ফাঁকা করুন।',
    art: '$_art/rescue_blocked.svg',
    lessonPoint: 1,
  );

  /// A STOP on a safe check (the picture shown is that check's own).
  static const safeStopped = DoMistake(
    key: '1.10/scan/safe-stopped',
    textBn: 'এখানে সব ঠিক ছিল — ছবিটা আরেকবার দেখুন, লেখা প্রশ্নের উত্তর মিলিয়ে নিন।',
    art: '$_art/mind_calm.svg',
    lessonPoint: 1,
  );

  static const all = [
    helmetCrack,
    bootsNail,
    polyester,
    gloveLeak,
    looseChest,
    chestHigh,
    twisted,
    frayedWebbing,
    expiredLabel,
    rodCracked,
    rodPvc,
    verbalPtw,
    ptwNoRead,
    mindTired,
    mindRushed,
    rustedPole,
    leaningPole,
    insideClearance,
    beehive,
    traffic,
    water,
    stormSky,
    rescueBlocked,
    safeStopped,
  ];

  /// Where the level's "পাঠে দেখুন" opens: the lesson and 0-based point that
  /// teach the fault. ([DoMistake.lessonPoint] is lesson 1.10's own point 1
  /// — the 10-second scan — which the mistakes book opens.)
  static const sourceOf = <String, (String, int)>{
    '1.10/scan/helmet-crack': ('1.1', 1),
    '1.10/scan/boots-nail': ('1.1', 2),
    '1.10/scan/dirty-polyester': ('1.1', 0),
    '1.10/scan/no-air-test': ('1.1', 3),
    '1.10/scan/loose-harness': ('1.4', 2),
    '1.10/scan/chest-strap-high': ('1.4', 2),
    '1.10/scan/twisted-strap': ('1.4', 2),
    '1.10/scan/frayed-webbing': ('1.4', 1),
    '1.10/scan/expired-harness': ('1.4', 1),
    '1.10/scan/rod-cracked': ('1.5', 2),
    '1.10/scan/rod-pvc': ('1.5', 4),
    '1.10/scan/verbal-ptw': ('1.6', 1),
    '1.10/scan/ptw-no-read': ('1.6', 1),
    '1.10/scan/mind-tired': ('1.10', 0),
    '1.10/scan/mind-rushed': ('1.10', 0),
    '1.10/scan/rusted-pole': ('1.3', 1),
    '1.10/scan/leaning-pole': ('1.3', 0),
    '1.10/scan/inside-clearance': ('1.2', 2),
    '1.10/scan/beehive-crossarm': ('1.3', 2),
    '1.10/scan/traffic-no-barrier': ('1.10', 1),
    '1.10/scan/water-at-base': ('1.3', 0),
    '1.10/scan/storm-sky': ('1.9', 1),
    '1.10/scan/rescue-blocked': ('1.10', 1),
    '1.10/scan/safe-stopped': ('1.10', 1),
  };
}

abstract final class TenSecLines {
  static const title = '10 সেকেন্ডের স্ক্যান';
  static const intro = 'পা মাটি ছাড়ার আগে 10 সেকেন্ডের স্ক্যান! প্রতিটা প্রশ্নে ছবি দেখুন — GO, না STOP?';
  static const ask = 'ছবিটা দেখুন — চালিয়ে যাবেন, না থামবেন?';
  static const stopBtn = 'থামুন · STOP';
  static const goBtn = 'চালিয়ে যান · GO';
  static const why = 'কেন এই সিদ্ধান্ত?';
  static const coworkerWhy = 'কেন ওর কথায় চেকলিস্ট বাদ দেবেন না?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const taskNudges = [ask, 'প্রশ্নটা পড়ুন, ছবিটা মিলিয়ে নিন।', 'সব ঠিক থাকলে GO, কিছু ভুল থাকলে STOP।'];
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtCall = 'চাপেও চেকলিস্ট শেষ করেছেন';

  static const coworker = CoworkerScript(
    line: 'কী ভাবছেন দাঁড়িয়ে? 20 বছর ধরে তো কাজ করছি, এসব চেকলিস্টের কী দরকার!',
    exitLine: 'আমি 20 বছর ধরে এই কাজ করছি, আমার এসব চেকলিস্টের দরকার নেই। সবকিছু আমার মাথায় আছে।',
    right: [
      'অভিজ্ঞতা ভালো, কিন্তু এই 10 সেকেন্ডের স্ক্যানই জীবন বাঁচায়।',
      'মাঠে আত্মবিশ্বাস ভালো, কিন্তু নিয়ম না মানলে একবারের ভুলেই শেষ।',
      'চেকলিস্ট নিয়ম — পা মাটি ছাড়ার আগে 10 সেকেন্ড দেখতেই হবে।',
    ],
    wrong: [
      'ঠিকই তো, এত বছর যখন কিছুই হয়নি, আজ আর দেখে কী হবে!',
      'সময় নষ্ট করে লাভ নেই, চেকলিস্ট ছাড়াই কাজ শুরু করে দিই।',
      'সিনিয়র যখন বলছে, তখন আর চেকলিস্টে সময় নষ্ট না করাই ভালো।',
      'মাঠে এত ভাবার সময় নেই, বাকি প্রশ্নগুলো পরে দেখা যাবে।',
      'ওর কথাই ঠিক, 20 বছরের অভিজ্ঞ লোকের মাথায় তো সবই থাকে।',
    ],
    asks: [
      'সহকর্মীর কথায় চেকলিস্ট বাদ দেবেন, নাকি স্ক্যান শেষ করবেন?',
      '20 বছরের দেমাকে নিয়ম ভুলবেন, নাকি 10 সেকেন্ড স্ক্যান করবেন?',
    ],
  );

  static const coworkerWhyRight = [
    'অভিজ্ঞতা চেকলিস্টের জায়গা নেয় না, তাকে আরও শক্ত করে',
    'রুটিন কাজ করতে করতেই মানুষ সবচেয়ে বেশি ভুল করে',
    'মাত্র 10 সেকেন্ড — দুর্ঘটনার ক্ষতির তুলনায় কিছুই না',
  ];

  static const coworkerWhyWrong = [
    'সিনিয়র যা বলেন তা চোখ বুজে মানাই মাঠের নিয়ম',
    'কাজের গতি বাড়াতে মাঝে মাঝে চেকলিস্ট বাদ দেওয়া যায়',
    '20 বছরের কাজের পর আবার চেকলিস্টের কী দরকার!',
    'মাঠে এত ভাবার সময় নেই, চেকলিস্ট বাবুদের জিনিস!',
    'চেকলিস্ট শুধু নতুন আর আনাড়ি কর্মীদের শেখার জন্য',
  ];

  static const allSet = '10 সেকেন্ডের স্ক্যান সফল! মাটিতে দাঁড়িয়ে সব যাচাই — তবেই পোলে।';
  static const quick = 'নিখুঁত আর ঝটপট — স্ক্যান এখন অভ্যাস!';
  static const fail = 'আরেকবার — পা মাটি ছাড়ার আগে 10টা প্রশ্নই মন দিয়ে দেখুন।';
}

const tenSecTopics = <ScanTopic, TenSecTopic>{
  ScanTopic.ppe: TenSecTopic(
    topic: ScanTopic.ppe,
    nameBn: 'পিপিই',
    askBn: 'আমার PPE কি 100% ঠিক আছে?',
    whyWrong: [
      'রোজকার চেনা পিপিই আলাদা করে দেখার দরকার নেই',
      'সাথী তো দেখেই নিয়েছে, নিজে আর দেখার কী দরকার',
      'একটু ফাটা হেলমেটেও মাথা ঠিকই বেঁচে যায় সব সময়',
      'পলিয়েস্টার জামা পরলেও ছোটখাটো কাজে ক্ষতি হয় না',
      'নতুন গ্লাভস হলে আর এয়ার টেস্ট করার দরকার নেই',
    ],
  ),
  ScanTopic.harness: TenSecTopic(
    topic: ScanTopic.harness,
    nameBn: 'হারনেস',
    askBn: 'আমার হারনেস কি সঠিকভাবে পরা এবং সুরক্ষিত?',
    whyWrong: [
      'বুকের ফিতে খোলা রাখলে পোলে কাজ করতে সুবিধা হয়',
      'হারনেসের ফিতে ঢিলেঢালা রাখলে শরীরে আরাম থাকে',
      'সামান্য সুতো উঠলেও হারনেসের জোর একই থেকে যায়',
      'দেখতে মজবুত হলে মেয়াদ পেরোলেও হারনেস দিব্যি চলে',
      'কোমর-রশা থাকলে হারনেসের ফিটিং দেখার দরকার নেই',
    ],
  ),
  ScanTopic.tools: TenSecTopic(
    topic: ScanTopic.tools,
    nameBn: 'টুলস',
    askBn: 'আমার টুলস কি ঠিকঠাক এবং হাতের কাছে আছে?',
    whyWrong: [
      'রড দেখতে রডের মতো হলেই হলো, স্টিক দেখার দরকার নেই',
      'পিভিসি পাইপ তো প্লাস্টিক, তাই জুগাড় রডও নিরাপদ',
      'টুলস ওপরে গিয়েই খুঁজে নেওয়া যাবে, আগে ভাবার কী',
      'ফাটা স্টিকে টেপ জড়ালে রড আবার নতুনের মতো হয়',
      'স্টোরের রড না পেলে যা হাতে আছে তা দিয়েই কাজ চলে',
    ],
  ),
  ScanTopic.permit: TenSecTopic(
    topic: ScanTopic.permit,
    nameBn: 'পারমিট',
    askBn: 'আমি কি পারমিট নম্বর এবং শর্তগুলো জানি?',
    whyWrong: [
      'ফোনে কেউ লাইন বন্ধ বললে সরাসরি কাজ শুরু করা যায়',
      'পারমিট পকেটে থাকলেই হলো, পড়ে দেখার দরকার নেই',
      'সুপারভাইজার জানলেই হলো, কাগজে সইয়ের দরকার নেই',
      'চেনা লাইনে ফিডারের নাম মেলানোর দরকার পড়ে না',
      'পারমিট মানেই লাইন 100% নিরাপদ, আর কিছু দেখার নেই',
    ],
  ),
  ScanTopic.mind: TenSecTopic(
    topic: ScanTopic.mind,
    nameBn: 'মনের অবস্থা',
    askBn: 'আমার মানসিক অবস্থা কি স্থিতিশীল?',
    whyWrong: [
      'দেরি হয়ে যাচ্ছে ভেবে দ্রুত গতিতে কাজে নামা উচিত',
      'খুব ক্লান্ত লাগলেও কাজ ফেলে বিশ্রাম নেওয়া বোকামি',
      'অভিজ্ঞ লোকের মন সবসময় স্থির, দেখার দরকার নেই',
      'যে আগে কাজ শেষ করে, সেই আসল দক্ষ লাইনম্যান',
      'মাথা ভার লাগলেও পোলে উঠলে সব ঠিক হয়ে যায়',
    ],
  ),
  ScanTopic.pole: TenSecTopic(
    topic: ScanTopic.pole,
    nameBn: 'পোল',
    askBn: 'আমি কি পোলটি নিজে পরীক্ষা করেছি?',
    whyWrong: [
      'রোজকার চেনা পোল পরীক্ষা না করে উঠলেও বিপদ হয় না',
      'একটু হেলে থাকা পোলে সাবধানে কাজ করলে কিছুই হয় না',
      'স্টিলের পোল শুধু বাঁকে, জং ধরলেও কখনো ভাঙে না',
      'চোখ দিয়ে পোল দেখলেই হয়, হাতুড়ি ঠোকার কাজ নেই',
      'চুলের মতো ফাটল তো সব পোলেই থাকে, ওতে কিছু হয় না',
    ],
  ),
  ScanTopic.rekha: TenSecTopic(
    topic: ScanTopic.rekha,
    nameBn: 'লক্ষ্মণ রেখা',
    askBn: "আমার চারপাশের 'লক্ষ্মণ রেখা' কোনটি?",
    whyWrong: [
      'লক্ষ্মণ রেখার ভেতর হাত বাড়ালেও তার না ছুঁলে চলে',
      'টুলের ডগা তারে না ছুঁলে দূরত্বের হিসেব লাগে না',
      'রাবারের বুট থাকলে বাতাস দিয়ে আর্ক শরীরে আসে না',
      'একটু কাছে গিয়ে কাজ সারলে কারেন্ট টের পায় না',
      'দূরত্ব শুধু বর্ষাকালের নিয়ম, শুকনো দিনে লাগে না',
    ],
  ),
  ScanTopic.around: TenSecTopic(
    topic: ScanTopic.around,
    nameBn: 'চারপাশ',
    askBn: 'আশেপাশে অন্য কোনো বিপদ (জল, ট্র্যাফিক, মৌমাছি) আছে কি?',
    whyWrong: [
      'নিচে গাড়ি চলাচল করলেও পোলে উঠে কাজ করা নিরাপদ',
      'মৌচাক থাকলেও বিরক্ত না করলে কোনো হুল ফোটে না',
      'গোড়ায় একটু জল জমলে পোলের কিছুই যায় আসে না',
      'চারপাশ দেখার কাজ সঙ্গীর, আমার কাজ শুধু পোলে ওঠা',
      'ওপরে উঠে গেলে নিচের বিপদ আর ছুঁতে পারে না',
    ],
  ),
  ScanTopic.weather: TenSecTopic(
    topic: ScanTopic.weather,
    nameBn: 'আবহাওয়া',
    askBn: 'আবহাওয়া কি নিরাপদ এবং স্থিতিশীল?',
    whyWrong: [
      'রাবারের জুতো-গ্লাভস থাকলে বাজেও কিছু হয় না',
      'ভারী বৃষ্টি না নামা পর্যন্ত ওপরে কাজ চালানো যায়',
      'মেঘ ডাকলে তাড়াতাড়ি কাজ সেরে নামাই বুদ্ধিমানের',
      'দূরে বাজ পড়লে পোলের কাছে তার কোনো বিপদ নেই',
      'আকাশ দেখা অফিসের কাজ, লাইনম্যানের কাজ নয়',
    ],
  ),
  ScanTopic.escape: TenSecTopic(
    topic: ScanTopic.escape,
    nameBn: 'নামার পথ',
    askBn: 'আমার পালানোর পথ এবং রেসকিউ প্ল্যান কী?',
    whyWrong: [
      'নামার পথ বন্ধ থাকলেও কাজের কোনো ক্ষতি হয় না',
      'রেসকিউর কথা আগে ভাবলে কাজে অমঙ্গল ডেকে আনে',
      'কিছু হলে তখন ভাবা যাবে, আগে প্ল্যান লাগে না',
      'নিচে কেউ না থাকলেও একা উঠে কাজ সারা যায়',
      'পালানোর পথ শুধু আগুনে লাগে, পোলের কাজে নয়',
    ],
  ),
};

/// Every check the dealer can use: per question, the safe pictures first,
/// then the faults.
abstract final class TenSecChecks {
  static const ppe = [
    TenSecCheck(
      id: 'ppe_ok_a',
      topic: ScanTopic.ppe,
      art: '$_art/kit_ok_a.svg',
      whyRight: ['হেলমেট থেকে সোল পর্যন্ত নিজে দেখেছি — সব অক্ষত', 'এয়ার টেস্টে লিক নেই, সোলে পেরেক নেই, জামা সুতির'],
      caughtTag: 'পিপিই নিজে যাচাই',
    ),
    TenSecCheck(
      id: 'ppe_ok_b',
      topic: ScanTopic.ppe,
      art: '$_art/kit_ok_b.svg',
      whyRight: ['হেলমেট থেকে সোল পর্যন্ত নিজে দেখেছি — সব অক্ষত', 'এয়ার টেস্টে লিক নেই, সোলে পেরেক নেই, জামা সুতির'],
      caughtTag: 'পিপিই নিজে যাচাই',
    ),
    TenSecCheck(
      id: 'ppe_helmet_crack',
      topic: ScanTopic.ppe,
      art: '$_art/kit_helmet_crack.svg',
      fault: TenSecMistakes.helmetCrack,
      whyRight: ['ফাটল ধরা হেলমেট ফুটো ছাতা — আঘাত আর ঠেকায় না', 'হেলমেটে সূক্ষ্ম ফাটল দেখলেই তখনই বদলাতে হয়'],
      caughtTag: 'ফাটা হেলমেট ধরেছেন',
    ),
    TenSecCheck(
      id: 'ppe_nail',
      topic: ScanTopic.ppe,
      art: '$_art/kit_nail_sole.svg',
      fault: TenSecMistakes.bootsNail,
      death: ScanDeath.nail,
      whyRight: ['সোলে পেরেক মানে কারেন্টের মাটিতে নামার রাস্তা', 'পেরেক বা তার গাঁথা জুতো তখনই বাতিল করতে হয়'],
      caughtTag: 'সোলে পেরেক ধরেছেন',
    ),
    TenSecCheck(
      id: 'ppe_glove_leak',
      topic: ScanTopic.ppe,
      art: '$_art/kit_glove_leak.svg',
      fault: TenSecMistakes.gloveLeak,
      death: ScanDeath.shock,
      whyRight: ['এয়ার টেস্টে লিক মানে ফুটো — সেই গ্লাভস নয়', 'পিনের ডগার মতো ফুটোতেও শক ঢুকে প্রাণ যায়'],
      caughtTag: 'গ্লাভসের লিক ধরেছেন',
    ),
    TenSecCheck(
      id: 'ppe_polyester',
      topic: ScanTopic.ppe,
      art: '$_art/kit_polyester.svg',
      fault: TenSecMistakes.polyester,
      death: ScanDeath.synthetic,
      whyRight: ['সিন্থেটিক কাপড় স্পার্কে গলে চামড়ায় সেঁটে যায়', 'লাইনের কাজে 100% সুতি বা FR কাপড়ই চাই'],
      caughtTag: 'পলিয়েস্টার জামা ধরেছেন',
    ),
  ];

  static const harness = [
    TenSecCheck(
      id: 'harness_snug',
      topic: ScanTopic.harness,
      art: '$_art/harness_snug.svg',
      whyRight: ['ফিতের নিচে 4 আঙুল, বুকের ফিতে মাঝ বরাবর', 'বকলস লক, ফিতে সোজা আর অক্ষত — ফিটিং ঠিক'],
      caughtTag: 'হারনেসের ফিটিং যাচাই',
    ),
    TenSecCheck(
      id: 'harness_tail',
      topic: ScanTopic.harness,
      art: '$_art/harness_tail.svg',
      whyRight: ['ফিতের নিচে 4 আঙুল, বুকের ফিতে মাঝ বরাবর', 'বকলস লক, ফিতে সোজা আর অক্ষত — ফিটিং ঠিক'],
      caughtTag: 'হারনেসের ফিটিং যাচাই',
    ),
    TenSecCheck(
      id: 'harness_loose',
      topic: ScanTopic.harness,
      art: '$_art/harness_loose_chest.svg',
      fault: TenSecMistakes.looseChest,
      whyRight: ['বুকের ফিতে খোলা থাকলে পড়ার সময় হারনেস খোলে', 'ঢিলেঢালা হারনেস শরীর থেকে খুলে যেতে পারে'],
      caughtTag: 'খোলা বুকের ফিতে ধরেছেন',
    ),
    TenSecCheck(
      id: 'harness_high',
      topic: ScanTopic.harness,
      art: '$_art/harness_chest_high.svg',
      fault: TenSecMistakes.chestHigh,
      whyRight: ['বুকের ফিতে থাকে বুকের মাঝে, গলার কাছে নয়', 'ভুল জায়গার ফিতে পড়ার সময় গুরুতর আঘাত দেয়'],
      caughtTag: 'ফিতের ভুল জায়গা ধরেছেন',
    ),
    TenSecCheck(
      id: 'harness_twisted',
      topic: ScanTopic.harness,
      art: '$_art/harness_twisted.svg',
      fault: TenSecMistakes.twisted,
      whyRight: ['পেঁচানো ফিতে মানে ভুল ফিটিং, ওঠার আগে ঠিক চাই', 'ফিতে পেঁচিয়ে থাকলে পড়ার চাপ ভুল জায়গায় পড়ে'],
      caughtTag: 'পেঁচানো ফিতে ধরেছেন',
    ),
    TenSecCheck(
      id: 'harness_frayed',
      topic: ScanTopic.harness,
      art: '$_art/harness_frayed.svg',
      fault: TenSecMistakes.frayedWebbing,
      death: ScanDeath.fall,
      whyRight: ['ছোট কাটাতেই হারনেসের শক্তি 50% পর্যন্ত কমে যায়', 'কাটা বা সুতো ওঠা ফিতের হারনেস বাতিল করতে হয়'],
      caughtTag: 'কাটা ফিতে ধরেছেন',
    ),
    TenSecCheck(
      id: 'harness_expired',
      topic: ScanTopic.harness,
      art: '$_art/harness_label_expired.svg',
      fault: TenSecMistakes.expiredLabel,
      whyRight: ['মেয়াদ উত্তীর্ণ হারনেস দেখতে ভালো হলেও চলে না', 'রোদ-ঘামে ফিতে ভেতর থেকে দুর্বল, তাই মেয়াদ মানা'],
      caughtTag: 'মেয়াদ পেরোনো লেবেল ধরেছেন',
    ),
  ];

  static const tools = [
    TenSecCheck(
      id: 'tools_ready',
      topic: ScanTopic.tools,
      art: '$_art/tool_ready.svg',
      whyRight: ['রড পরিষ্কার, শুকনো, ফাটলহীন — টুলস হাতের কাছে', 'যা লাগবে সব ব্যাগে তৈরি, রডের স্টিকও অক্ষত'],
      caughtTag: 'টুলস আর রড যাচাই',
    ),
    TenSecCheck(
      id: 'tools_rod_cracked',
      topic: ScanTopic.tools,
      art: '$_art/tool_rod_cracked.svg',
      fault: TenSecMistakes.rodCracked,
      whyRight: ['রডের স্টিক হবে পরিষ্কার, শুকনো আর ফাটলমুক্ত', 'ভাঙা রড নিজেই বিদ্যুৎ পরিবাহী হয়ে উঠতে পারে'],
      caughtTag: 'ফাটা রড ধরেছেন',
    ),
    TenSecCheck(
      id: 'tools_rod_pvc',
      topic: ScanTopic.tools,
      art: '$_art/tool_rod_pvc.svg',
      fault: TenSecMistakes.rodPvc,
      death: ScanDeath.shock,
      whyRight: ['পিভিসি জুগাড় সার্টিফায়েড ডিসচার্জ রড নয়', 'জুগাড়ের হুক মেটাল — লাইনের কাছে নেওয়া বিপদ'],
      caughtTag: 'জুগাড় রড ধরেছেন',
    ),
  ];

  static const permit = [
    TenSecCheck(
      id: 'permit_signed',
      topic: ScanTopic.permit,
      art: '$_art/ptw_signed.svg',
      whyRight: ['লিখিত, সই করা পারমিট — নম্বর আর শর্ত জানি', 'কাগজে ফিডারের নাম মিলিয়েছি, তবেই কাজের দিকে'],
      caughtTag: 'লিখিত পারমিট যাচাই',
    ),
    TenSecCheck(
      id: 'permit_phone',
      topic: ScanTopic.permit,
      art: '$_art/ptw_verbal_phone.svg',
      fault: TenSecMistakes.verbalPtw,
      death: ScanDeath.shock,
      whyRight: ['ফোনে "লাইন বন্ধ" শোনা পারমিট নয় — কাগজ চাই', 'লিখিত পারমিট ছাড়া লাইন আবার চালু হতে পারে'],
      caughtTag: 'ফোনের "পারমিট" ফিরিয়েছেন',
    ),
    TenSecCheck(
      id: 'permit_unread',
      topic: ScanTopic.permit,
      art: '$_art/ptw_no_read.svg',
      fault: TenSecMistakes.ptwNoRead,
      death: ScanDeath.shock,
      whyRight: ['পারমিটের নম্বর, শর্ত না জেনে কাজে নামা নয়', 'পারমিটের ফিডার আর কাজের ফিডার মেলাতেই হবে'],
      caughtTag: 'না-পড়া পারমিট ধরেছেন',
    ),
  ];

  static const mind = [
    TenSecCheck(
      id: 'mind_calm',
      topic: ScanTopic.mind,
      art: '$_art/mind_calm.svg',
      whyRight: ['মন শান্ত, ক্লান্তি নেই, কোনো তাড়াহুড়োও নেই', 'স্থির মনে চেকলিস্ট চালালে ছোট ধাপও বাদ পড়ে না'],
      caughtTag: 'মনের অবস্থা যাচাই',
    ),
    TenSecCheck(
      id: 'mind_rushed',
      topic: ScanTopic.mind,
      art: '$_art/mind_rushed.svg',
      fault: TenSecMistakes.mindRushed,
      whyRight: ['তাড়াহুড়ো চেকলিস্টের প্রধান শত্রু — এটা রেস নয়', 'গতি নয়, নিরাপদে বাড়ি ফেরাই আসল দক্ষতার পরিচয়'],
      caughtTag: 'তাড়াহুড়ো থামিয়েছেন',
    ),
    TenSecCheck(
      id: 'mind_tired',
      topic: ScanTopic.mind,
      art: '$_art/mind_tired.svg',
      fault: TenSecMistakes.mindTired,
      whyRight: ['ক্লান্ত মন ছোট কিন্তু জরুরি ধাপ ভুলে যায়', 'ক্লান্ত বা বিক্ষিপ্ত থাকলে আগে থামা, পরে ওঠা'],
      caughtTag: 'ক্লান্তিতে থেমেছেন',
    ),
  ];

  static const pole = [
    TenSecCheck(
      id: 'pole_sound',
      topic: ScanTopic.pole,
      art: '$_art/pole_sound.svg',
      whyRight: ['গোড়ায় হাতুড়িতে নিরেট "ঠক্" — পোল ভেতরে মজবুত', 'পোল সোজা, গোড়া অক্ষত — নিজে পরীক্ষা করেছি'],
      caughtTag: 'পোল নিজে পরীক্ষা',
    ),
    TenSecCheck(
      id: 'pole_rusted',
      topic: ScanTopic.pole,
      art: '$_art/pole_rusted_base.svg',
      fault: TenSecMistakes.rustedPole,
      death: ScanDeath.collapse,
      whyRight: ['মাটির কাছে জং আর ভোঁতা শব্দ মানে পোল দুর্বল', 'স্টিলের মরিচা বাইরে না বুঝলেও ভেতর শেষ করে'],
      caughtTag: 'জং ধরা গোড়া ধরেছেন',
    ),
    TenSecCheck(
      id: 'pole_lean',
      topic: ScanTopic.pole,
      art: '$_art/pole_lean.svg',
      fault: TenSecMistakes.leaningPole,
      death: ScanDeath.collapse,
      whyRight: ['হেলে থাকা পোল শরীরের ভারে ভেঙে পড়তে পারে', 'গোড়ায় ফাটল মানে ভিত দুর্বল — এই পোলে নয়'],
      caughtTag: 'হেলে থাকা পোল ধরেছেন',
    ),
  ];

  static const rekha = [
    TenSecCheck(
      id: 'rekha_out',
      topic: ScanTopic.rekha,
      art: '$_art/clearance_spot.svg',
      whyRight: ['টুলের ডগাও লক্ষ্মণ রেখার বাইরে — দূরত্ব ঠিক', 'ডগাসহ পুরো শরীর লাইভ তার থেকে নিরাপদ দূরে আছে'],
      caughtTag: 'লক্ষ্মণ রেখা চিনেছেন',
    ),
    TenSecCheck(
      id: 'rekha_in',
      topic: ScanTopic.rekha,
      art: '$_art/clearance_inside.svg',
      fault: TenSecMistakes.insideClearance,
      death: ScanDeath.arc,
      whyRight: ['টুলের ডগাও হাত — রেখার ভেতরে ঢোকা নিষিদ্ধ', 'না ছুঁয়েও আর্ক বাতাস ভেদ করে লাফিয়ে আসে'],
      caughtTag: 'রেখার ভেতরে ডগা ধরেছেন',
    ),
  ];

  static const around = [
    TenSecCheck(
      id: 'around_clear',
      topic: ScanTopic.around,
      art: '$_art/site_clear.svg',
      whyRight: ['গোড়া শুকনো, রাস্তা ফাঁকা, পোলে কোনো চাক নেই', 'জল, ট্র্যাফিক, মৌমাছি — চারপাশে কিছুই নেই'],
      caughtTag: 'চারপাশ দেখে নিয়েছেন',
    ),
    TenSecCheck(
      id: 'around_hive',
      topic: ScanTopic.around,
      art: '$_art/hazard_beehive.svg',
      fault: TenSecMistakes.beehive,
      whyRight: ['পোলে বোলতা বা মৌমাছির চাক — না উঠে আগে জানাই', 'চাক থাকা পোলে ওঠা নয়, আগে ব্যবস্থা চাই'],
      caughtTag: 'মৌচাক ধরেছেন',
    ),
    TenSecCheck(
      id: 'around_traffic',
      topic: ScanTopic.around,
      art: '$_art/hazard_traffic.svg',
      fault: TenSecMistakes.traffic,
      whyRight: ['গা ঘেঁষে গাড়ি চলছে — ট্র্যাফিকও বড় বিপদ', 'চারপাশের বিপদ না সামলে পা মাটি ছাড়া নয়'],
      caughtTag: 'ট্র্যাফিক ধরেছেন',
    ),
    TenSecCheck(
      id: 'around_water',
      topic: ScanTopic.around,
      art: '$_art/hazard_water.svg',
      fault: TenSecMistakes.water,
      whyRight: ['গোড়ায় জল জমা — মাটি ক্ষয়েছে কিনা আগে দেখা চাই', 'জলও বিপদ — ভেজা গোড়া পরীক্ষা না করে ওঠা নয়'],
      caughtTag: 'গোড়ায় জল ধরেছেন',
    ),
  ];

  static const weather = [
    TenSecCheck(
      id: 'weather_clear',
      topic: ScanTopic.weather,
      art: '$_art/weather_clear.svg',
      whyRight: ['আকাশ পরিষ্কার, বাতাস শান্ত — আবহাওয়া স্থির', 'মেঘ নেই, বাজ নেই, হাওয়াও শান্ত — ওঠা যায়'],
      caughtTag: 'আকাশ দেখে নিয়েছেন',
    ),
    TenSecCheck(
      id: 'weather_storm',
      topic: ScanTopic.weather,
      art: '$_art/hazard_storm_sky.svg',
      fault: TenSecMistakes.stormSky,
      death: ScanDeath.strike,
      whyRight: ['বজ্রপাতে কোনো PPE কাজ করে না — এটা রেড লাইন', 'বাজ দেখলে কাজ বন্ধ, নিরাপদ জায়গায় যেতে হয়'],
      caughtTag: 'বাজে কাজ থামিয়েছেন',
    ),
  ];

  static const escape = [
    TenSecCheck(
      id: 'escape_ready',
      topic: ScanTopic.escape,
      art: '$_art/rescue_mate.svg',
      whyRight: ['নামার পথ ফাঁকা, সঙ্গী নিচে তৈরি — প্ল্যান আছে', 'কিছু হলে কীভাবে নামব জানি, সঙ্গীও দেখছে'],
      caughtTag: 'নামার পথ ও রেসকিউ প্ল্যান',
    ),
    TenSecCheck(
      id: 'escape_blocked',
      topic: ScanTopic.escape,
      art: '$_art/rescue_blocked.svg',
      fault: TenSecMistakes.rescueBlocked,
      whyRight: ['নামার পথ আটকানো — কিছু হলে নামব কীভাবে?', 'পালানোর পথ ফাঁকা না করে পোলে ওঠা নয়'],
      caughtTag: 'আটকানো পথ ধরেছেন',
    ),
  ];

  /// Per question, in the lesson's order.
  static const byTopic = <ScanTopic, List<TenSecCheck>>{
    ScanTopic.ppe: ppe,
    ScanTopic.harness: harness,
    ScanTopic.tools: tools,
    ScanTopic.permit: permit,
    ScanTopic.mind: mind,
    ScanTopic.pole: pole,
    ScanTopic.rekha: rekha,
    ScanTopic.around: around,
    ScanTopic.weather: weather,
    ScanTopic.escape: escape,
  };

  static List<TenSecCheck> get all => [for (final l in byTopic.values) ...l];
}

/// Safe checks in a deal: at least [kMinSafe], at most [kMaxSafe].
const kMinSafe = 4;
const kMaxSafe = 6;

@immutable
class TenSecDeal {
  const TenSecDeal({required this.checks, required this.coworkerRound});
  final List<TenSecCheck> checks;
  final int coworkerRound;
}

/// A fresh play: one check per question in the lesson's order; 4–6 of them
/// safe; at least one fault is deadly; the coworker comes on check 3–6
/// (0-based 2–5), safe or not, so his arrival tells nothing.
TenSecDeal dealTenSec(math.Random rng) {
  final topics = ScanTopic.values;
  bool canKill(ScanTopic t) => TenSecChecks.byTopic[t]!.any((c) => c.deadly);
  final numSafe = kMinSafe + rng.nextInt(kMaxSafe - kMinSafe + 1);
  final order = [...topics]..shuffle(rng);
  final faulty = order.skip(numSafe).toSet();
  if (!faulty.any(canKill)) {
    // Swap one safe question that can kill with a faulty one that cannot:
    // the counts stay, and a deadly fault becomes possible.
    final inKill = order.take(numSafe).where(canKill).toList();
    final out = faulty.toList();
    faulty
      ..remove(out[rng.nextInt(out.length)])
      ..add(inKill[rng.nextInt(inKill.length)]);
  }
  final picks = <ScanTopic, TenSecCheck>{};
  for (final t in topics) {
    final pool = TenSecChecks.byTopic[t]!;
    final from = pool.where((c) => faulty.contains(t) ? !c.isSafe : c.isSafe).toList();
    picks[t] = from[rng.nextInt(from.length)];
  }
  if (!picks.values.any((c) => c.deadly)) {
    final killers = faulty.where(canKill).toList();
    final t = killers[rng.nextInt(killers.length)];
    final deadly = TenSecChecks.byTopic[t]!.where((c) => c.deadly).toList();
    picks[t] = deadly[rng.nextInt(deadly.length)];
  }
  return TenSecDeal(checks: [for (final t in topics) picks[t]!], coworkerRound: 2 + rng.nextInt(4));
}

// ============================================================================
// TenSecRun (pure rules)
// ============================================================================

class TenSecRun {
  TenSecRun(this.deal);
  final TenSecDeal deal;

  int index = 0;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.checks.length;
  bool get ended => done || deadly != null;
  TenSecCheck get current => deal.checks[index.clamp(0, deal.checks.length - 1)];

  /// The shared Do rule: 100 − 15 per slip, pass ≥ 55.
  int get percent => (100 - slips * 15).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// A slip that is not a check's answer (listening to the coworker).
  void slip() => slips++;

  /// The player's call on the current check: null when right, else the
  /// mistake (a STOP on a safe check is a slip; GO on a fault is its fault).
  DoMistake? evaluate(bool chooseGo) {
    if (ended) return null;
    final c = current;
    if (chooseGo == c.isSafe) {
      tag(c.caughtTag);
      return null;
    }
    if (c.isSafe) {
      slips++;
      return TenSecMistakes.safeStopped;
    }
    final m = c.fault!;
    if (m.deadly) {
      deadly = m;
    } else {
      slips++;
    }
    return m;
  }

  void advance() {
    if (index < deal.checks.length) index++;
  }
}

// ============================================================================
// The page
// ============================================================================

class TenSecScanPage extends StatefulWidget {
  const TenSecScanPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final TenSecPack pack;
  final bool muted;
  final int? seed;

  @override
  State<TenSecScanPage> createState() => _TenSecScanPageState();
}

class _TenSecScanPageState extends State<TenSecScanPage> {
  var _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _TenSecRunPage(
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

class _TenSecRunPage extends ConsumerStatefulWidget {
  const _TenSecRunPage({
    super.key,
    required this.ctx,
    required this.pack,
    required this.muted,
    required this.rng,
    required this.onRetry,
  });

  final LevelContext ctx;
  final TenSecPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_TenSecRunPage> createState() => _TenSecRunPageState();
}

class _TenSecRunPageState extends ConsumerState<_TenSecRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final TenSecRun _run = TenSecRun(dealTenSec(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;

  /// The card came from listening to the coworker: the same check is asked after it.
  var _cardFromCoworker = false;

  /// The open reason deck is the coworker's: the same check is asked after it.
  var _coworkerReason = false;
  var _busy = false;
  var _ended = false;
  var _popped = false;
  var _passed = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;

  // The deadly freeze.
  var _freeze = false;
  Completer<void>? _frozen;
  ScanDeath? _death;

  var _ready = false;
  int _stepTok = 0;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  LevelContext get deathCtx => widget.ctx;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _stepTok++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  // --- speech ----------------------------------------------------------------
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

  void _cue(String path, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(path, volume: volume, muted: false));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? TenSecLines.tapWhy[_nudgeN++ % TenSecLines.tapWhy.length]
            : _nudge.next(TenSecLines.taskNudges[_nudgeN++ % TenSecLines.taskNudges.length]);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    unawaited(_sayChain([line]));
  }

  // --- the run ---------------------------------------------------------------
  void _start() {
    if (!mounted) return;
    setState(() => _intro = false);
    _clock.start();
    _beginCheck();
  }

  /// Arms the current check (again, after the coworker).
  void _beginCheck() {
    final tok = ++_stepTok;
    setState(() => _ready = false);
    if (_run.index == _run.deal.coworkerRound && !coworkerDone) scheduleCoworker();
    unawaited(() async {
      await Future<void>.delayed(Duration(milliseconds: _quiet ? 50 : 220));
      if (!mounted || tok != _stepTok || _ended) return;
      setState(() => _ready = true);
      if (!coworkerOpen && !_waitingForCoworker) await _sayChain([_run.current.topicData.askBn]);
    }());
  }

  bool get _waitingForCoworker => _run.index == _run.deal.coworkerRound && !coworkerDone;

  bool get _canDecide =>
      !_intro && _ready && !_busy && !_ended && _card == null && !tableBusy && !coworkerOpen && !_waitingForCoworker;

  Future<void> _decide(bool chooseGo, Offset origin) async {
    if (!_canDecide) return;
    _busy = true;
    _hush();
    final c = _run.current;
    final m = _run.evaluate(chooseGo);
    if (m == null) {
      HapticFeedback.lightImpact();
      _cue('sounds/quiz_right.wav', volume: 0.65);
      _coworkerReason = false;
      putOnTable(15);
      _busy = false;
      await askReason(
        deal: () => dealChoices(c.whyRight, c.topicData.whyWrong, widget.rng),
        question: TenSecLines.why,
        stillValid: () => mounted && !_ended,
      );
      return;
    }
    if (m.deadly) {
      await _deadly(m, c.death ?? ScanDeath.shock);
      return;
    }
    // A STOP on a safe check shows that check's own picture.
    final shown = c.isSafe
        ? DoMistake(key: m.key, textBn: m.textBn, art: c.art, lessonPoint: m.lessonPoint)
        : m;
    _busy = false;
    await _slip(shown, counted: true);
  }

  /// A slip: the card (the third → struck out). [counted]: the run already counted it.
  Future<void> _slip(DoMistake m, {required bool counted, bool fromCoworker = false}) async {
    if (!counted) _run.slip();
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _cardFromCoworker = fromCoworker;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    await _sayChain([m.textBn], mood: GuideMood.warn);
  }

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  /// GO on a deadly fault: the scene freezes grey, the consequence plays in
  /// colour, then near-miss or death (DoDeathGuard).
  Future<void> _deadly(DoMistake m, ScanDeath how) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue(how == ScanDeath.strike ? 'sounds/learn/thunder_near.wav' : 'sounds/accident.wav', volume: 0.9);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _death = how;
    });
    await frozen.future;
    if (!mounted) return;
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    await _sayChain([death ? TenSecLines.deadlyWord : TenSecLines.nearMissWord, m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        final again = _cardFromCoworker;
        setState(() {
          _card = null;
          _cardFromCoworker = false;
        });
        again ? _beginCheck() : _advance();
      case MistakeTone.nearMiss:
        _hush();
        widget.onRetry(_muted);
      case MistakeTone.deadly:
        _popped = true;
        unawaited(dieAndLeave());
    }
  }

  void _advance() {
    _run.advance();
    if (_run.done) {
      unawaited(_finish());
    } else {
      _beginCheck();
    }
  }

  Future<void> _levelDelta(int delta, Offset origin, {GuideMood? mood}) async {
    final next = math.max(0, _runScore + delta);
    final real = next - _runScore;
    if (real == 0 || !mounted) return;
    setState(() => _runScore = next);
    await BeatFx.levelDelta(ref, real, mood: mood, originGlobal: origin, muted: _muted);
  }

  /// The shared end of play (as sky_read): result, clear, bonuses, score, time, stars.
  Future<void> _finish() async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    final rung = widget.ctx.rungId;
    final save = ref.read(gameSaveProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final centre = Offset(size.width / 2, size.height * 0.45);
    final ms = _clock.elapsedMilliseconds;
    final mark = _run.percent;
    await save.recordLevelResult(rung, mark);
    if (!mounted) return;
    if (_run.passed) {
      await save.markRungCleared(rung);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && ms < widget.pack.quickMs) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(rung, _runScore);
    if (_run.passed) await save.recordBestTime(rung, ms);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: ms < widget.pack.quickMs);
    if (stars > 0) await save.recordStars(rung, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    if (_passed) {
      _cue('sounds/level_done.wav', volume: 0.8);
    } else {
      _cue('sounds/learn/level_fail.wav');
    }
    await _say(!_passed ? TenSecLines.fail : (_quickBonus ? TenSecLines.quick : TenSecLines.allSet),
        mood: _passed ? GuideMood.celebrate : GuideMood.warn);
  }

  // --- ReasonTable hooks -------------------------------------------------------
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
    if (_coworkerReason) {
      // He came in on this check: now it is asked.
      _coworkerReason = false;
      _beginCheck();
    } else {
      _advance();
    }
  }

  // --- CoworkerMoment hooks ----------------------------------------------------
  @override
  CoworkerScript get coworkerScript => TenSecLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;

  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.index != _run.deal.coworkerRound) return null;
    if (_intro || _busy || _card != null || tableBusy) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      await _slip(TenSecMistakes.mindRushed, counted: false, fromCoworker: true);
      return;
    }
    _run.tag(TenSecLines.caughtCall);
    unawaited(coworkerSnarl());
    _coworkerReason = true;
    putOnTable(20);
    await askReason(
      deal: () => dealChoices(TenSecLines.coworkerWhyRight, TenSecLines.coworkerWhyWrong, widget.rng),
      question: TenSecLines.coworkerWhy,
      stillValid: () => mounted && !_ended,
    );
  }

  // --- leaving -----------------------------------------------------------------
  Future<void> _leave() async {
    _hush();
    if (deathPending) {
      _popped = true;
      await dieAndLeave();
      return;
    }
    if (_runScore > 0 && !_ended) {
      final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: true);
      if (leave != true || !mounted) return;
    }
    _popOnce(false);
  }

  void _popOnce(bool passed) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(passed);
  }

  void _openLesson(DoMistake m) {
    final src = TenSecMistakes.sourceOf[m.key];
    unawaited(openLessonPoint(
      context,
      ref,
      lessonId: src?.$1 ?? widget.ctx.lessonId,
      point: src?.$2 ?? m.lessonPoint,
      muted: _muted,
    ));
  }

  // --- build -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final playing = !_intro && _mark == null && !struckOut && _card == null && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _ready && !_waitingForCoworker && !tableBusy;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final showCard = !_intro && _mark == null && !struckOut && !_run.done;

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
              labels: [for (var i = 1; i <= _run.deal.checks.length; i++) enDigits('$i')],
              done: {for (var i = 0; i < math.min(_run.index, _run.deal.checks.length); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => [
              Positioned.fill(
                key: const ValueKey('scene'),
                child: ColorFiltered(
                  colorFilter: grey,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const DoBackdrop(asset: 'assets/zero_loss/scene/bg_span_two_poles.webp', alignment: Alignment(0, -0.2)),
                      if (showCard)
                        Positioned(
                          key: ValueKey('scan-card-${_run.index}'),
                          left: 16,
                          right: 16,
                          top: pad.top + 64,
                          bottom: pad.bottom + (deckUp ? 280 : 160),
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: deckUp ? 0.75 : 1.0,
                              duration: const Duration(milliseconds: 250),
                              child: ScanCard(
                                check: _run.current,
                                step: _run.index + 1,
                                total: _run.deal.checks.length,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 130), quiet: quiet),
              if (handsOn)
                Positioned(
                  key: const ValueKey('hud-decide'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _StopButton(
                          label: TenSecLines.stopBtn,
                          onTapUp: (d) => unawaited(_decide(false, d.globalPosition)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: DoBigButton(
                          label: TenSecLines.goBtn,
                          filled: true,
                          onTapUp: (d) => unawaited(_decide(true, d.globalPosition)),
                        ),
                      ),
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
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck'))
                        : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 236 : 72),
                  onLeft: coworkerFromRight,
                ),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_freeze && _card == null && _death != null)
                FreezeFrame(
                  key: const ValueKey('freeze'),
                  muted: _muted,
                  ms: quiet ? 300 : 2400,
                  consequence: ScanDeathView(
                    key: ValueKey('death-${_death!.name}'),
                    how: _death!,
                    quiet: quiet,
                  ),
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
                  mistake: _card!,
                  tone: _cardTone,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null ? null : () => _openLesson(_card!),
                  onGo: _cardGo,
                ),
              if (struckOut && _card == null)
                StruckOutCard(
                  key: const ValueKey('struck'),
                  mistake: strikeOutBy!,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.electric,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_mark != null)
                Positioned.fill(
                  key: const ValueKey('result'),
                  child: ColoredBox(
                    color: const Color(0xE6050A16),
                    child: SafeArea(
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
                                  onRead: () => unawaited(openLessonPoint(
                                    context,
                                    ref,
                                    lessonId: widget.ctx.lessonId,
                                    point: 1,
                                    muted: _muted,
                                  )),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: TenSecLines.intro,
                  alarm: 'sounds/learn/rush_in.wav',
                  muted: _muted,
                  onDone: _start,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on TenSecCheck {
  TenSecTopic get topicData => tenSecTopics[topic]!;
}

// ============================================================================
// Pieces
// ============================================================================

/// One check: the question's short name, its picture and the lesson's
/// question — never the answer.
class ScanCard extends StatelessWidget {
  const ScanCard({super.key, required this.check, required this.step, required this.total});

  final TenSecCheck check;
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final topic = tenSecTopics[check.topic]!;
    return Container(
      width: 310,
      constraints: const BoxConstraints(maxHeight: 330),
      decoration: BoxDecoration(
        color: SlmColors.navy900.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.4), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: SlmColors.navy800,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: SlmColors.gold500.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      enDigits('$step/$total'),
                      style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.gold300),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      topic.nameBn,
                      style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ivory),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Container(
                color: const Color(0xFF09101F),
                padding: const EdgeInsets.all(10),
                child: AspectRatio(
                  aspectRatio: 200 / 220,
                  child: SvgPicture.asset(check.art, fit: BoxFit.contain),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              color: SlmColors.navy950,
              child: Text(
                enDigits(topic.askBn),
                textAlign: TextAlign.center,
                style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: SlmColors.ivory, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.label, required this.onTapUp});
  final String label;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE60B1324),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: () {},
        child: Container(
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.warning.withValues(alpha: 0.9), width: 1.8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory),
          ),
        ),
      ),
    );
  }
}

/// What the deadly GO does, in colour over the grey scene: the synthetic
/// shirt or the nail (lesson 1.1, the step-2 death views), the current
/// through the body, the arc jumping to the tool tip, the fall, the strike.
/// One short animation, then a still frame.
class ScanDeathView extends StatelessWidget {
  const ScanDeathView({super.key, required this.how, required this.quiet});
  final ScanDeath how;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    switch (how) {
      case ScanDeath.synthetic:
        return KitDeathView(kind: KitDeath.synthetic, quiet: quiet);
      case ScanDeath.nail:
        return KitDeathView(kind: KitDeath.nail, quiet: quiet);
      case ScanDeath.shock:
      case ScanDeath.arc:
      case ScanDeath.fall:
      case ScanDeath.collapse:
      case ScanDeath.strike:
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: quiet ? 1 : 0, end: 1),
          duration: const Duration(milliseconds: 1800),
          builder: (_, t, _) => Opacity(
            opacity: (t * 5).clamp(0.0, 1.0),
            child: CustomPaint(painter: ScanDeathPainter(how, t), child: const SizedBox.expand()),
          ),
        );
    }
  }
}

class ScanDeathPainter extends CustomPainter {
  ScanDeathPainter(this.how, this.t);
  final ScanDeath how;
  final double t;

  static const _bolt = Color(0xFFBFE8FF);
  static const _hot = Color(0xFFFFF4B0);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.42);
    final s = math.min(size.width, size.height) / 360;
    final glow = Paint()..shader = RadialGradient(colors: [_hot.withValues(alpha: 0.9), _hot.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: 150 * s));
    final bolt = Paint()
      ..color = _bolt
      ..strokeWidth = 5 * s
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final body = Paint()..color = const Color(0xFF1F5F8F);
    final skin = Paint()..color = const Color(0xFFA86E48);
    final helmet = Paint()..color = const Color(0xFFFACC15);

    void figure(Offset feet, double tilt) {
      canvas.save();
      canvas.translate(feet.dx, feet.dy);
      canvas.rotate(tilt);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-14 * s, -96 * s, 28 * s, 44 * s), Radius.circular(6 * s)), body);
      canvas.drawRect(Rect.fromLTWH(-12 * s, -52 * s, 10 * s, 52 * s), Paint()..color = const Color(0xFF2A3442));
      canvas.drawRect(Rect.fromLTWH(2 * s, -52 * s, 10 * s, 52 * s), Paint()..color = const Color(0xFF2A3442));
      canvas.drawCircle(Offset(0, -110 * s), 13 * s, skin);
      canvas.drawArc(Rect.fromCircle(center: Offset(0, -112 * s), radius: 15 * s), math.pi, math.pi, true, helmet);
      canvas.restore();
    }

    Path zig(Offset a, Offset b, int n, double amp) {
      final p = Path()..moveTo(a.dx, a.dy);
      for (var i = 1; i < n; i++) {
        final f = i / n;
        final side = (i.isEven ? 1 : -1) * amp;
        final d = b - a;
        final nrm = Offset(-d.dy, d.dx) / d.distance;
        final q = a + d * f + nrm * side;
        p.lineTo(q.dx, q.dy);
      }
      p.lineTo(b.dx, b.dy);
      return p;
    }

    final grow = Curves.easeOut.transform(t.clamp(0.0, 1.0));
    switch (how) {
      case ScanDeath.shock:
        final feet = Offset(c.dx, c.dy + 120 * s);
        figure(feet, 0);
        canvas.drawCircle(c, 150 * s * grow, glow);
        final top = Offset(c.dx - 10 * s, c.dy - 160 * s);
        final hand = Offset(c.dx - 18 * s, c.dy - 30 * s);
        canvas.drawPath(zig(top, hand, 7, 10 * s), bolt);
        canvas.drawPath(zig(hand, feet, 6, 8 * s), bolt..color = _bolt.withValues(alpha: 0.8));
        canvas.drawCircle(feet, 26 * s * grow, Paint()..color = _hot.withValues(alpha: 0.7));
      case ScanDeath.arc:
        final wireY = c.dy - 120 * s;
        canvas.drawLine(Offset(0, wireY), Offset(size.width, wireY), Paint()
          ..color = const Color(0xFF2B3138)
          ..strokeWidth = 4 * s);
        final feet = Offset(c.dx + 50 * s, c.dy + 120 * s);
        figure(feet, 0);
        final tip = Offset(c.dx - 20 * s, wireY + 50 * s);
        canvas.drawLine(Offset(feet.dx - 10 * s, feet.dy - 70 * s), tip, Paint()
          ..color = const Color(0xFFFBC02D)
          ..strokeWidth = 5 * s);
        canvas.drawCircle(tip, 90 * s * grow, glow);
        canvas.drawPath(zig(Offset(tip.dx + 6 * s, wireY), tip, 4, 7 * s), bolt);
      case ScanDeath.fall:
        // The webbing parts: he drops from the pole top to the ground.
        final pole = Paint()..color = const Color(0xFFBDBAB2);
        canvas.drawRect(Rect.fromLTWH(c.dx - 70 * s, c.dy - 200 * s, 22 * s, 340 * s), pole);
        final top = Offset(c.dx - 30 * s, c.dy - 60 * s);
        final ground = Offset(c.dx + 30 * s, c.dy + 140 * s);
        figure(Offset.lerp(top, ground, Curves.easeIn.transform(grow))!, 1.4 * grow);
        final strap = Paint()
          ..color = const Color(0xFFF7811F)
          ..strokeWidth = 5 * s
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(c.dx - 48 * s, c.dy - 150 * s), Offset(c.dx - 30 * s, c.dy - 120 * s), strap);
        canvas.drawLine(Offset(c.dx - 30 * s, c.dy - 106 * s), Offset(c.dx - 22 * s, c.dy - 92 * s), strap);
        canvas.drawOval(Rect.fromCenter(center: Offset(ground.dx, ground.dy + 6 * s), width: 140 * s * grow, height: 16 * s), Paint()..color = const Color(0x667A5C3A));
      case ScanDeath.collapse:
        final base = Offset(c.dx - 30 * s, c.dy + 140 * s);
        final lean = -0.08 - 0.55 * grow;
        canvas.save();
        canvas.translate(base.dx, base.dy);
        canvas.rotate(lean);
        canvas.drawRect(Rect.fromLTWH(-10 * s, -280 * s, 20 * s, 280 * s), Paint()..color = const Color(0xFFBDBAB2));
        canvas.restore();
        final from = Offset(base.dx + math.sin(-lean) * -200 * s, base.dy - math.cos(lean) * 200 * s);
        final feet = Offset.lerp(from, Offset(c.dx + 60 * s, c.dy + 140 * s), grow)!;
        figure(feet, 1.2 * grow);
        canvas.drawOval(Rect.fromCenter(center: Offset(c.dx + 40 * s, c.dy + 146 * s), width: 160 * s * grow, height: 18 * s), Paint()..color = const Color(0x667A5C3A));
      case ScanDeath.strike:
        canvas.drawRect(Offset.zero & size, Paint()..color = _hot.withValues(alpha: 0.25 * (1 - grow)));
        final feet = Offset(c.dx + 20 * s, c.dy + 120 * s);
        figure(feet, 0);
        canvas.drawCircle(Offset(feet.dx, feet.dy - 100 * s), 140 * s * grow, glow);
        canvas.drawPath(zig(Offset(c.dx + 40 * s, 0), Offset(feet.dx, feet.dy - 120 * s), 8, 14 * s), bolt..strokeWidth = 7 * s);
      case ScanDeath.synthetic:
      case ScanDeath.nail:
        break;
    }
  }

  @override
  bool shouldRepaint(ScanDeathPainter old) => old.t != t || old.how != how;
}
