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
import 'level_frame.dart';
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;

// Lesson 1.10, কাজ 1: "১০ সেকেন্ডের স্ক্যান" (Ladder step 29).
// The capstone Do level of Module 1. A rapid-fire 10-check field checklist
// before feet leave the ground, testing the entire Module 1 curriculum:
//   1. Clothing & Boots (1.1)
//   2. Helmet & Chin Strap (1.1)
//   3. Rubber Gloves (1.2)
//   4. Full Body Harness (1.4)
//   5. Tools & Bag (1.5)
//   6. Pole Base & Stability (1.5)
//   7. Lakshman Rekha / Clearance (1.6)
//   8. PTW & Team Briefing (1.6)
//   9. Weather & Surroundings (1.8, 1.9)
//  10. Rescue & Mindset (1.7, 1.10)
//
// Hands-on: inspect the item/condition, decide whether to GO (চালিয়ে যান)
// or STOP (থামুন). 10 checks dealt fresh every play.
// Coworker pressure moment appears mid-run with recorded voice clips
// (r_2054ee9516.mp3 push, r_b3d015de00.mp3 snarl).
// Mistakes link directly to lesson reader points. Deadly mistakes trigger
// DoDeathGuard freeze.

// ============================================================================
// Content & Models
// ============================================================================

@immutable
class TenSecPack {
  const TenSecPack({required this.id, required this.titleBn});
  final String id;
  final String titleBn;
}

const tenSecPacks = {
  'do_1_10_a': TenSecPack(id: 'do_1_10_a', titleBn: TenSecLines.title),
};

@immutable
class TenSecCheck {
  const TenSecCheck({
    required this.id,
    required this.categoryBn,
    required this.labelBn,
    required this.svgArt,
    required this.isSafe,
    required this.mistake,
    required this.whyRight,
    required this.whyWrong,
    required this.caughtTag,
  });

  final String id;
  final String categoryBn;
  final String labelBn;
  final String svgArt;
  final bool isSafe;
  final DoMistake mistake;
  final List<String> whyRight;
  final List<String> whyWrong;
  final String caughtTag;
}

abstract final class TenSecMistakes {
  static const bootsNail = DoMistake(
    key: '1.10/scan/boots-nail',
    textBn: 'বুটের তলায় পেরেক থাকলে বা তলা ফাটা হলে আর্দিং হয়ে মারাত্মক শক লাগতে পারে।',
    art: 'assets/game/art/scan_board/ppe_nail_sole.svg',
    lessonPoint: 2,
  );

  static const dirtyPolyester = DoMistake(
    key: '1.10/scan/dirty-polyester',
    textBn: 'ঢিলেঢালা পলিয়েস্টার কাপড়ে আর্কের তাপে আগুন ধরে ত্বকে গলে লেগে যায় — সুতির ফুলহাতা পরা বাধ্যতামূলক।',
    art: 'assets/game/art/scan_board/ppe_dirty_cut.svg',
    lessonPoint: 0,
  );

  static const unstrappedHelmet = DoMistake(
    key: '1.10/scan/unstrapped-helmet',
    textBn: 'চিবুকের ফিতে শক্তভাবে না বাঁধলে ঝাঁকুনিতে হেলমেট খসে পড়ে মাথায় মারাত্মক আঘাত লাগতে পারে।',
    art: 'assets/game/art/scan_board/ppe_unstrapped.svg',
    lessonPoint: 1,
  );

  static const noAirTest = DoMistake(
    key: '1.10/scan/no-air-test',
    textBn: 'এয়ার টেস্ট ছাড়া গ্লাভস পরা মারাত্মক — সুঁইয়ের মতো সূক্ষ্ম ফুটো দিয়েও প্রাণঘাতী শক ঢুকে যায়।',
    art: 'assets/game/art/scan_board/ppe_no_check.svg',
    deadly: true,
    lessonPoint: 1,
  );

  static const looseHarness = DoMistake(
    key: '1.10/scan/loose-harness',
    textBn: 'হারনেসের বুকের বাকল আলগা থাকলে পড়ে গেলে শরীর ছিটকে বেরিয়ে মৃত্যু হতে পারে।',
    art: 'assets/game/art/scan_board/harness_loose_chest.svg',
    lessonPoint: 1,
  );

  static const expiredHarness = DoMistake(
    key: '1.10/scan/expired-harness',
    textBn: 'ঘষা খাওয়া বা মেয়াদোত্তীর্ণ হারনেস পতনের প্রবল টান সহ্য করতে না পেরে ছিঁড়ে যায়।',
    art: 'assets/game/art/scan_board/harness_expired.svg',
    lessonPoint: 2,
  );

  static const toolHandClimb = DoMistake(
    key: '1.10/scan/tool-hand-climb',
    textBn: 'হাতে সরঞ্জাম নিয়ে পোলে উঠবেন না — দুই হাত ও পা সব সময় তিন বিন্দু সংযোগে থাকবে। সরঞ্জাম ব্যাগে তুলুন।',
    art: 'assets/game/art/scan_board/tool_hand_climb.svg',
    lessonPoint: 2,
  );

  static const toolOverload = DoMistake(
    key: '1.10/scan/tool-overload',
    textBn: 'পকেটে বা বেল্টে আলগা ভারী সরঞ্জাম ঝোলালে তা নিচে সহকর্মীর গায়ে পড়ে দুর্ঘটনা ঘটে।',
    art: 'assets/game/art/scan_board/tool_overload.svg',
    lessonPoint: 2,
  );

  static const rustedPole = DoMistake(
    key: '1.10/scan/rusted-pole',
    textBn: 'গোড়া ক্ষয়প্রাপ্ত বা ফাঁপা পোলে কখনোই উঠবেন না — লাইনম্যানের ভারে গোড়া ভেঙে পড়ে নিশ্চিত মৃত্যু।',
    art: 'assets/game/art/scan_board/pole_rusted_base.svg',
    deadly: true,
    lessonPoint: 1,
  );

  static const leaningPole = DoMistake(
    key: '1.10/scan/leaning-pole',
    textBn: 'হেলে থাকা পোল অতিরিক্ত টানে থাকে — উপরে ওঠার আগে সাপোর্ট বা গাইড তার ঠিক করা জরুরি।',
    art: 'assets/game/art/scan_board/pole_hug_lean.svg',
    deadly: true,
    lessonPoint: 1,
  );

  static const insideClearance = DoMistake(
    key: '1.10/scan/inside-clearance',
    textBn: 'লক্ষ্মণ রেখা বা ন্যূনতম নিরাপদ দূরত্ব লঙ্ঘন মারাত্মক — স্পর্শ না করলেও ১১ কেভি আর্ক লাফিয়ে এসে পুড়িয়ে দেয়।',
    art: 'assets/game/art/scan_board/clearance_inside.svg',
    deadly: true,
    lessonPoint: 2,
  );

  static const verbalPtw = DoMistake(
    key: '1.10/scan/verbal-ptw',
    textBn: 'মৌখিক বা ফোনে পারমিট নয় — লিখিত পিটিডব্লিউ ও ডিসচার্জ ছাড়া লাইনে হাত দেওয়া নিষিদ্ধ।',
    art: 'assets/game/art/scan_board/ptw_verbal_phone.svg',
    deadly: true,
    lessonPoint: 0,
  );

  static const ptwNoRead = DoMistake(
    key: '1.10/scan/ptw-no-read',
    textBn: 'পিটিডব্লিউ না পড়ে ও ফিডার নম্বর না মিলিয়ে অনুমান করে কাজ শুরু করা মারাত্মক ঝুঁকিপূর্ণ।',
    art: 'assets/game/art/scan_board/ptw_no_read.svg',
    deadly: true,
    lessonPoint: 1,
  );

  static const stormSky = DoMistake(
    key: '1.10/scan/storm-sky',
    textBn: 'মেঘের গর্জন বা বজ্র দেখলে পোলে কাজ বন্ধ — কোনো পিপিই বজ্রপাত আটকাতে পারে না।',
    art: 'assets/game/art/scan_board/hazard_storm_sky.svg',
    deadly: true,
    lessonPoint: 1,
  );

  static const beehiveCrossarm = DoMistake(
    key: '1.10/scan/beehive-crossarm',
    textBn: 'পোলে বা ক্রসআর্মে বলতার চাক থাকলে আগে উপযুক্ত ব্যবস্থা নিন, পোলে উঠে কামড় খেলে ভারসাম্য হারাবেন।',
    art: 'assets/game/art/scan_board/hazard_beehive.svg',
    lessonPoint: 3,
  );

  static const trafficNoBarrier = DoMistake(
    key: '1.10/scan/traffic-no-barrier',
    textBn: 'রাস্তার পাশে কাজের জায়গায় ট্র্যাফিক কোণ ও ব্যারিকেড ছাড়া কাজ বিপজ্জনক — চলমান গাড়ি মইয়ে ধাক্কা দিতে পারে।',
    art: 'assets/game/art/scan_board/hazard_traffic.svg',
    lessonPoint: 2,
  );

  static const rescueBlocked = DoMistake(
    key: '1.10/scan/rescue-blocked',
    textBn: 'জরুরি উদ্ধারের ব্যবস্থা ও ফার্স্ট এইড কিট ছাড়া কাজ শুরু করবেন না — গোল্ডেন মিনিটে সাহায্য না পেলে প্রাণ যায়।',
    art: 'assets/game/art/scan_board/rescue_blocked.svg',
    lessonPoint: 0,
  );

  static const mindTired = DoMistake(
    key: '1.10/scan/mind-tired',
    textBn: 'শারীরিক অসুস্থতা বা ক্লান্তিতে মনোযোগ হারায় — সুস্থ বোধ না করলে স্টপ ওয়ার্ক বলুন।',
    art: 'assets/game/art/scan_board/mind_tired.svg',
    lessonPoint: 1,
  );

  static const mindRushed = DoMistake(
    key: '1.10/scan/mind-rushed',
    textBn: 'তাড়াহুড়ো বা সহকর্মীর চাপে সুরক্ষা ধাপ বাদ দেবেন না — শান্ত মনে ১০ সেকেন্ডের স্ক্যান শেষ করুন।',
    art: 'assets/game/art/scan_board/mind_rushed.svg',
    lessonPoint: 1,
  );

  static const safeStopped = DoMistake(
    key: '1.10/scan/safe-stopped',
    textBn: 'সবকিছু সম্পূর্ণ নিরাপদ ও নিয়ম মেনে ছিল — এখানে অযথা কাজ থামানোর প্রয়োজন ছিল না।',
    art: 'assets/game/art/scan_board/ppe_head_toe.svg',
    lessonPoint: 0,
  );

  static const all = [
    bootsNail,
    dirtyPolyester,
    unstrappedHelmet,
    noAirTest,
    looseHarness,
    expiredHarness,
    toolHandClimb,
    toolOverload,
    rustedPole,
    leaningPole,
    insideClearance,
    verbalPtw,
    ptwNoRead,
    stormSky,
    beehiveCrossarm,
    trafficNoBarrier,
    rescueBlocked,
    mindTired,
    mindRushed,
    safeStopped,
  ];
}

abstract final class TenSecLines {
  static const title = '১০ সেকেন্ডের স্ক্যান';
  static const intro = 'পা মাটি ছাড়ার আগে ১০ সেকেন্ডের স্ক্যান! পোশাক, হারনেস, পোল থেকে শুরু করে আকাশ ও পারমিট — সব দেখে Go বা Stop চাপুন।';
  static const ask = 'স্ক্যান করুন — কাজ চালিয়ে যাবেন, না থামবেন?';
  static const stopBtn = 'থামুন · STOP';
  static const goBtn = 'চালিয়ে যান · GO';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const taskNudges = [ask, '১০ সেকেন্ডের স্ক্যান — শান্ত মাথায় সিদ্ধান্ত নিন।', 'Go নাকি Stop? ঠিক বোতামটি বাছুন।'];

  static const coworker = CoworkerScript(
    line: 'কী ভাবছেন দাঁড়িয়ে? 20 বছর ধরে তো কাজ করছি, এসব চেকলিস্টের কী দরকার!',
    exitLine: 'আমি 20 বছর ধরে এই কাজ করছি, আমার এসব চেকলিস্টের দরকার নেই। সবকিছু আমার মাথায় আছে।',
    right: [
      'অভিজ্ঞতা ভালো, কিন্তু এই ১০ সেকেন্ডের স্ক্যানই জীবন বাঁচায়।',
      'মাঠে আত্মবিশ্বাস ভালো, কিন্তু নিয়ম না মানলে একবারের ভুলেই শেষ।',
      'চেকলিস্ট নিয়ম — পা মাটি ছাড়ার আগে ১০ সেকেন্ড দেখতেই হবে।',
    ],
    wrong: [
      'ঠিকই তো, এত বছর যখন কিছু হয়নি, আজ আর দেখে কী হবে!',
      'সময় নষ্ট করে লাভ নেই, চেকলিস্ট ছাড়াই কাজ শুরু করে দিই।',
      'সিনিয়র যখন বলছে, তখন আর চেকলিস্টে সময় নষ্ট না করাই ভালো।',
    ],
    asks: [
      'সহকর্মীর কথায় চেকলিস্ট বাদ দেবেন, নাকি স্ক্যান শেষ করবেন?',
      '২০ বছরের অহংকারে নিয়ম ভুলবেন, না ১০ সেকেন্ডের স্ক্যান চালাবেন?',
    ],
  );

  static const coworkerWhyRight = [
    '১০ সেকেন্ডের স্ক্যান যে কোনো ভুলের ফাঁদ আগেই ধরে ফেলে',
    'দীর্ঘদিনের অভ্যাসেও অসাবধানতা ঘটতে পারে, চেকলিস্ট রক্ষা করে',
  ];

  static const coworkerWhyWrong = [
    'সিনিয়র লাইনম্যান যা বলেন তা না দেখে মেনে নেওয়াই নিয়ম',
    'কাজের গতি বাড়াতে মাঝে মাঝে চেকলিস্ট এড়িয়ে যাওয়া যায়',
    '২০ বছরের অভিজ্ঞতার পর আর সুরক্ষা চেকলিস্টের দরকার পড়ে না',
  ];

  static const allSet = '১০ সেকেন্ডের মানসিক চেকলিস্ট সফল! মাটিতে দাঁড়িয়ে সব যাচাই করলেই মাঠে নিরাপদ।';
  static const fail = 'আরেকবার — পা মাটি ছাড়ার আগে ১০ সেকেন্ডের সব কয়টি ধাপ নিখুঁতভাবে দেখুন।';
}

@immutable
class TenSecDeal {
  const TenSecDeal({required this.checks, required this.coworkerRound});
  final List<TenSecCheck> checks;
  final int coworkerRound;
}

TenSecDeal dealTenSec(math.Random rng) {
  // 10 categories
  // 1. Clothing & Boots
  const c1Safe = TenSecCheck(
    id: 'c1_ppe',
    categoryBn: 'পোশাক ও বুট',
    labelBn: 'সুতির ফুল হাতা জামা ও খাঁজকাটা অক্ষত বুট',
    svgArt: 'assets/game/art/scan_board/ppe_head_toe.svg',
    isSafe: true,
    mistake: TenSecMistakes.safeStopped,
    whyRight: ['সুতির পোশাক ও আর্দিং-মুক্ত বুট বিদ্যুৎ শক থেকে রক্ষা করে'],
    whyWrong: [
      'সাধারণ কাপড়ে কাজ করা যায়, আলাদা পোশাকের দরকার পড়ে না',
      'সুতির ফুলহাতা পোশাক শুধু রোদের তাপ থেকে শরীর বাঁচাতে পরা হয়',
    ],
    caughtTag: 'সুতির পোশাক ও আর্দিং-মুক্ত বুট',
  );
  const c1Hazard1 = TenSecCheck(
    id: 'c1_nail',
    categoryBn: 'পোশাক ও বুট',
    labelBn: 'বুটের তলায় পেরেক ঢুকে আছে বা তলা ফাটা',
    svgArt: 'assets/game/art/scan_board/ppe_nail_sole.svg',
    isSafe: false,
    mistake: TenSecMistakes.bootsNail,
    whyRight: ['ফাটা বুট বা পেরেকের মাধ্যমে মাটিতে প্রাণঘাতী কারেন্ট যেতে পারে'],
    whyWrong: [
      'রাবারের ভারী জুতোয় পেরেক ফুটে থাকলেও কোনো ইলেকট্রিক শক লাগে না',
      'ছোট পেরেক কখনো বুটের মোটা সোল ভেদ করে লাইনম্যানের পায়ে লাগে না',
    ],
    caughtTag: 'ফাটা বুটের বিপদ চিহ্নিতকরণ',
  );
  const c1Hazard2 = TenSecCheck(
    id: 'c1_polyester',
    categoryBn: 'পোশাক ও বুট',
    labelBn: 'পলিয়েস্টার ঢিলেঢালা জামা ও তেলচিটে পোশাক',
    svgArt: 'assets/game/art/scan_board/ppe_dirty_cut.svg',
    isSafe: false,
    mistake: TenSecMistakes.dirtyPolyester,
    whyRight: ['পলিয়েস্টার কাপড়ে আর্কের আঁচে আগুন ধরে ত্বকে গলে লেগে যায়'],
    whyWrong: [
      'পলিয়েস্টার জামা যথেষ্ট মজবুত তাই বৈদ্যুতিক কাজে সম্পূর্ণ নিরাপদ',
      'তেলচিটে ময়লা দাগের সাথে বিদ্যুতের মারাত্মক শকের কোনো সম্পর্ক নেই',
    ],
    caughtTag: 'পলিয়েস্টার পোশাক বর্জন',
  );

  // 2. Helmet & Chin Strap
  const c2Safe = TenSecCheck(
    id: 'c2_helmet_ok',
    categoryBn: 'হেলমেট ও ফিতে',
    labelBn: 'নন-ভেন্টেড আইএসআই হেলমেট, চিবুকের ফিতে শক্ত বাঁধা',
    svgArt: 'assets/game/art/scan_board/ppe_strap_sole.svg',
    isSafe: true,
    mistake: TenSecMistakes.safeStopped,
    whyRight: ['ফিতে শক্ত করে বাঁধা হেলমেট মাথায় ওপর থেকে পড়া ভারী বস্তু ঠেকায়'],
    whyWrong: [
      'ফিতে একটু আলগা রাখলে মাথায় বাতাস খেলে এবং কাজ করার সময় আরাম লাগে',
      'হেলমেটের সাইজ ঠিক থাকলে ফিতে না বাঁধলেও মাথার ওপর সুন্দর ব্যালান্স থাকে',
    ],
    caughtTag: 'চিবুকের ফিতে বাঁধা হেলমেট',
  );
  const c2Hazard = TenSecCheck(
    id: 'c2_helmet_open',
    categoryBn: 'হেলমেট ও ফিতে',
    labelBn: 'হেলমেটের চিবুকের ফিতে খোলা ঝুলছে',
    svgArt: 'assets/game/art/scan_board/ppe_unstrapped.svg',
    isSafe: false,
    mistake: TenSecMistakes.unstrappedHelmet,
    whyRight: ['ফিতে না বাঁধলে পোলের ঝাঁকুনিতে হেলমেট খসে নিচে পড়ে যেতে পারে'],
    whyWrong: [
      'হেলমেট মাথার মাপে ঠিক থাকলে চিবুকের ফিতে আলাদা বাঁধার দরকার নেই',
      'ফিতে ছাড়া হেলমেট পরলে প্রয়োজনের সময় দ্রুত মাথা থেকে খুলে ফেলা যায়',
    ],
    caughtTag: 'খোলা হেলমেট ফিতে আটকানো',
  );

  // 3. Rubber Gloves
  const c3Safe = TenSecCheck(
    id: 'c3_gloves_ok',
    categoryBn: 'রবার গ্লাভস',
    labelBn: 'এয়ার টেস্ট করে যাচাই করা অক্ষত রবার গ্লাভস',
    svgArt: 'assets/game/art/scan_board/ppe_head_toe.svg',
    isSafe: true,
    mistake: TenSecMistakes.safeStopped,
    whyRight: ['এয়ার টেস্ট করে সূক্ষ্ম লিক না থাকলে তবেই হাত বৈদ্যুতিক শকে নিরাপদ'],
    whyWrong: [
      'প্যাকেট থেকে বের করা নতুন গ্লাভস হলে আলাদা এয়ার টেস্টের দরকার নেই',
      'চামড়ার সাধারণ ওয়ার্কিং গ্লাভস রবারের চেয়ে বেশি ভোল্টেজ শক আটকায়',
    ],
    caughtTag: 'এয়ার টেস্ট করা রবার গ্লাভস',
  );
  const c3Hazard = TenSecCheck(
    id: 'c3_gloves_no_test',
    categoryBn: 'রবার গ্লাভস',
    labelBn: 'এয়ার টেস্ট না করে না দেখে গ্লাভস পরা হয়েছে',
    svgArt: 'assets/game/art/scan_board/ppe_no_check.svg',
    isSafe: false,
    mistake: TenSecMistakes.noAirTest,
    whyRight: ['না-দেখা সূক্ষ্ম পিনহোল দিয়েও ১১ কেভি বিদ্যুৎ ঢুকে জীবনহানি ঘটাতে পারে'],
    whyWrong: [
      'চোখে ফাটল বা দাগ না দেখলে গ্লাভস সম্পূর্ণ ঠিক বলে ধরে নেওয়া নিয়ম',
      'এয়ার টেস্ট কাজের মাঠে হয় না, ওটা শুধু ল্যাবরেটরিতে করার নিয়মকানুন',
    ],
    caughtTag: 'এয়ার টেস্টবিহীন গ্লাভস শনাক্ত',
  );

  // 4. Full Body Harness
  const c4Safe = TenSecCheck(
    id: 'c4_harness_ok',
    categoryBn: 'ফুল বডি হারনেস',
    labelBn: 'বুক ও উরুর বাকল ঠিকভাবে আঁটা ফুল বডি হারনেস',
    svgArt: 'assets/game/art/scan_board/harness_snug.svg',
    isSafe: true,
    mistake: TenSecMistakes.safeStopped,
    whyRight: ['সঠিকভাবে আঁটা ফুল বডি হারনেস পতনের সময় শরীরের আঘাত সমান ছড়ায়'],
    whyWrong: [
      'কোমর-বেল্ট পরা ফুল বডি হারনেসের চেয়ে অনেক বেশি আরামদায়ক ও সহজ',
      'হারনেস একটু ঢিলেঢালা করে পরলে পোলের ওপরে শরীর নাড়াচাড়া করা সহজ হয়',
    ],
    caughtTag: 'স্ন্যাগ ফিট ফুল বডি হারনেস',
  );
  const c4Hazard1 = TenSecCheck(
    id: 'c4_harness_loose',
    categoryBn: 'ফুল বডি হারনেস',
    labelBn: 'হারনেসের বুকের বাকল আলগা বা খোলা রাখা হয়েছে',
    svgArt: 'assets/game/art/scan_board/harness_loose_chest.svg',
    isSafe: false,
    mistake: TenSecMistakes.looseHarness,
    whyRight: ['বুকের ফিতে খোলা থাকলে পা পিছলে উল্টে গেলে শরীর হারনেস থেকে ছিটকে পড়ে'],
    whyWrong: [
      'উরুর বাকল শক্ত আঁটা থাকলে বুকের আলাদা বাকল বাঁধার কোনো দরকার হয় না',
      'বুকের বাকল খোলা রেখে কাজ করলে পোলের ওপরে দাঁড়িয়ে শ্বাস নিতে সুবিধা হয়',
    ],
    caughtTag: 'আলগা বুকের বাকল শুধরানো',
  );
  const c4Hazard2 = TenSecCheck(
    id: 'c4_harness_expired',
    categoryBn: 'ফুল বডি হারনেস',
    labelBn: 'ঘষা খাওয়া সুতো ওঠা মেয়াদোত্তীর্ণ হারনেস ল্যানিয়ার্ড',
    svgArt: 'assets/game/art/scan_board/harness_expired.svg',
    isSafe: false,
    mistake: TenSecMistakes.expiredHarness,
    whyRight: ['ক্ষয়প্রাপ্ত বা পুরনো ল্যানিয়ার্ড পতনের প্রবল টান সহ্য না করে ছিঁড়ে যায়'],
    whyWrong: [
      'সামান্য সুতো উঠলেও হারনেসের আসল বুনন ও ধারণক্ষমতা সম্পূর্ণ ঠিক থাকে',
      'ল্যানিয়ার্ড যতই ঘষা বা পুরনো হোক না কেন তা লাইফলাইনে কখনও ছিঁড়ে না',
    ],
    caughtTag: 'ক্ষয়প্রাপ্ত ল্যানিয়ার্ড বর্জন',
  );

  // 5. Tools & Bag
  const c5Safe = TenSecCheck(
    id: 'c5_tools_ok',
    categoryBn: 'টুলব্যাগ ও সরঞ্জাম',
    labelBn: 'সরঞ্জাম পাউচে রাখা এবং দড়ি দিয়ে ব্যাগে তোলা',
    svgArt: 'assets/game/art/scan_board/tool_bagged.svg',
    isSafe: true,
    mistake: TenSecMistakes.safeStopped,
    whyRight: ['সরঞ্জাম ব্যাগে তোলায় দুই হাত খালি থাকে এবং ৩-পয়েন্ট কন্টাক্ট ঠিক থাকে'],
    whyWrong: [
      'হাতে স্প্যানার নিয়ে সরাসরি পোলে উঠলে উপরে গিয়ে দ্রুত কাজ শুরু করা যায়',
      'টুলব্যাগ সবসময় ভারী বোঝা তাই ওটা মাটিতে রেখে পোলে ওঠাই বুদ্ধিমানের কাজ',
    ],
    caughtTag: 'সরঞ্জাম ব্যাগে ৩-পয়েন্ট কন্টাক্ট',
  );
  const c5Hazard1 = TenSecCheck(
    id: 'c5_tools_hand',
    categoryBn: 'টুলব্যাগ ও সরঞ্জাম',
    labelBn: 'হাতে ভারী রেঞ্চ ধরে পোলে ওঠার চেষ্টা',
    svgArt: 'assets/game/art/scan_board/tool_hand_climb.svg',
    isSafe: false,
    mistake: TenSecMistakes.toolHandClimb,
    whyRight: ['হাতে ভারী যন্ত্রপাতি ধরলে পোলে ওঠার সময় তিন বিন্দু সংযোগ নষ্ট হয়ে পড়ে'],
    whyWrong: [
      'এক হাতে শক্ত পোল ধরে অন্য হাতে রেঞ্চ নিয়ে ওঠা পোলের কাজে খুব সাধারণ নিয়ম',
      'হাতে সরঞ্জাম রাখলে নিচে দাঁড়িয়ে থাকা সহকর্মীকে সহজে ছুড়ে দেওয়া যায়',
    ],
    caughtTag: 'হাতে সরঞ্জাম নিয়ে ওঠা বন্ধ',
  );
  const c5Hazard2 = TenSecCheck(
    id: 'c5_tools_overload',
    categoryBn: 'টুলব্যাগ ও সরঞ্জাম',
    labelBn: 'পকেটে ও বেল্টে আলগাভাবে ঝুলিয়ে রাখা ভারী যন্ত্রপাতি',
    svgArt: 'assets/game/art/scan_board/tool_overload.svg',
    isSafe: false,
    mistake: TenSecMistakes.toolOverload,
    whyRight: ['পকেটে ঝুলন্ত ভারী যন্ত্রপাতি নিচে পড়লে সহকর্মীর মারাত্মক আঘাত লাগতে পারে'],
    whyWrong: [
      'প্যান্টের পকেটে সব যন্ত্রপাতি রাখলে উপরে উঠে আর আলাদা ব্যাগ খুঁজতে হয় না',
      'শরীরে ভারী ভারী যন্ত্রপাতি ঝুলিয়ে রাখা কাজের দক্ষতা ও শক্তির বড় প্রমাণ',
    ],
    caughtTag: 'আলগা ঝুলন্ত যন্ত্রপাতি নিরোধ',
  );

  // 6. Pole Base & Stability
  const c6Safe = TenSecCheck(
    id: 'c6_pole_ok',
    categoryBn: 'পোলের গোড়া',
    labelBn: 'গোড়া সম্পূর্ণ শক্ত, ফাটল নেই এবং মাটিতে নিরেট গাঁথা',
    svgArt: 'assets/game/art/scan_board/pole_sound.svg',
    isSafe: true,
    mistake: TenSecMistakes.safeStopped,
    whyRight: ['মাটিতে শক্ত পোক্ত ভিত নিশ্চিত করে যে উপরে উঠলে পোল ভেঙে মাটিতে পড়বে না'],
    whyWrong: [
      'পোলে টানা তার বাঁধা থাকলেই পোলের মাটির গোড়া পরীক্ষা করার কোনো দরকার নেই',
      'কংক্রিটের শক্ত পোল মাটিতে সহজে ভাঙে না তাই গোড়া দেখার কোনো প্রয়োজন নেই',
    ],
    caughtTag: 'পোলের সুদৃঢ় ভিত্তি যাচাই',
  );
  const c6Hazard1 = TenSecCheck(
    id: 'c6_pole_rusted',
    categoryBn: 'পোলের গোড়া',
    labelBn: 'পোলের গোড়ায় মারাত্মক মরিচা ও মাটি ক্ষয়ে ফাঁপা',
    svgArt: 'assets/game/art/scan_board/pole_rusted_base.svg',
    isSafe: false,
    mistake: TenSecMistakes.rustedPole,
    whyRight: ['গোড়া ক্ষয়প্রাপ্ত ফাঁপা পোলে উঠলে লাইনম্যানের ভারে গোড়া মটকে আছড়ে পড়ে'],
    whyWrong: [
      'উপরে তারের বাঁধন থাকলে গোড়া ভাঙলেও পোল কখনোই নিচে পড়ে যেতে পারে না',
      'বাইরে শুধু হালকা রঙের মরিচা লেগেছে, ভেতরের লোহা এখনও সম্পূর্ণ শক্ত আছে',
    ],
    caughtTag: 'মরিচা ধরা ফাঁপা পোল চিহ্নিত',
  );
  const c6Hazard2 = TenSecCheck(
    id: 'c6_pole_lean',
    categoryBn: 'পোলের গোড়া',
    labelBn: 'পোল বিপজ্জনকভাবে একপাশে হেলে আছে এবং তারে টান বেশি',
    svgArt: 'assets/game/art/scan_board/pole_hug_lean.svg',
    isSafe: false,
    mistake: TenSecMistakes.leaningPole,
    whyRight: ['বেশি হেলে থাকা পোলে মারাত্মক বাড়তি টান থাকে, উঠলে পোল উপড়ে পড়তে পারে'],
    whyWrong: [
      'পোল একটু হেলে থাকলে মই লাগিয়ে উপরে দ্রুত ওঠার ক্ষেত্রে বেশ সুবিধা হয়',
      'গ্রামের সাধারণ ১১ কেভি লাইনে পোল একটু বাঁকা বা হেলে থাকা খুব স্বাভাবিক ব্যাপার',
    ],
    caughtTag: 'ঝুঁকিপূর্ণ হেলে থাকা পোল নিরোধ',
  );

  // 7. Lakshman Rekha / Clearance
  const c7Safe = TenSecCheck(
    id: 'c7_clearance_ok',
    categoryBn: 'লক্ষ্মণ রেখা',
    labelBn: '১১ কেভি লাইভ লাইনের লক্ষ্মণ রেখা ও নিরাপদ ব্যবধান নিশ্চিত',
    svgArt: 'assets/game/art/scan_board/clearance_spot.svg',
    isSafe: true,
    mistake: TenSecMistakes.safeStopped,
    whyRight: ['১১ কেভি লাইভ লাইনের নিরাপদ ব্যবধান বজায় রাখলে আর্ক জাম্পের ঝুঁকি থাকে না'],
    whyWrong: [
      'কাছে গিয়ে হাত দিয়ে তার না ছোঁয়া পর্যন্ত কোনো ইলেকট্রিক শকের ভয় নেই',
      '১.২ মিটারের নিরাপদ লক্ষ্মণ রেখা দূরত্ব শুধুমাত্র ঘোর বর্ষার দিনের নিয়ম',
    ],
    caughtTag: '১১ কেভি লক্ষ্মণ রেখা পালন',
  );
  const c7Hazard = TenSecCheck(
    id: 'c7_clearance_inside',
    categoryBn: 'লক্ষ্মণ রেখা',
    labelBn: 'কাজের পরিধি লাইভ ১১ কেভি লাইনের নিরাপদ সীমার ভেতরে',
    svgArt: 'assets/game/art/scan_board/clearance_inside.svg',
    isSafe: false,
    mistake: TenSecMistakes.insideClearance,
    whyRight: ['লক্ষ্মণ রেখা লঙ্ঘন মারাত্মক — তার স্পর্শ না করলেও বিদ্যুৎ বাতাসে লাফিয়ে আসে'],
    whyWrong: [
      'হাত না লাগিয়ে শরীর সাবধানে একটু লাইনের ভেতরে নিলে কোনো কারেন্ট আসে না',
      'পায়ে রাবারের আর্দিং-মুক্ত বুট থাকলে বাতাস দিয়ে আর্ক শরীরে ঢুকতে পারে না',
    ],
    caughtTag: 'আর্ক দূরত্বের সীমা রক্ষা',
  );

  // 8. PTW & Team Briefing
  const c8Safe = TenSecCheck(
    id: 'c8_ptw_ok',
    categoryBn: 'পিটিডব্লিউ ও ব্রিফিং',
    labelBn: 'লিখিত সাইন করা পিটিডব্লিউ হাতে এবং টিমে কাজের ব্রিফিং সম্পন্ন',
    svgArt: 'assets/game/art/scan_board/ptw_signed.svg',
    isSafe: true,
    mistake: TenSecMistakes.safeStopped,
    whyRight: ['লিখিত পারমিট ও ব্রিফিং দলের সবাইকে শাটডাউনের নির্দিষ্ট সীমা স্পষ্ট করে'],
    whyWrong: [
      'ব্রিফিংয়ে সময় নষ্ট না করে সরাসরি লাইনে কাজ শুরু করাই কাজের আসল গতি',
      'পিটিডব্লিউ কেবল অফিসের কাগজ, মাঠের লাইনের কাজে ওসবের কোনো গুরুত্ব নেই',
    ],
    caughtTag: 'লিখিত পিটিডব্লিউ ও ব্রিফিং',
  );
  const c8Hazard1 = TenSecCheck(
    id: 'c8_ptw_verbal',
    categoryBn: 'পিটিডব্লিউ ও ব্রিফিং',
    labelBn: 'কোনো লিখিত পিটিডব্লিউ নেই, শুধু ফোনে মৌখিক অনুমতিতে কাজ শুরু',
    svgArt: 'assets/game/art/scan_board/ptw_verbal_phone.svg',
    isSafe: false,
    mistake: TenSecMistakes.verbalPtw,
    whyRight: ['মৌখিক কথায় কাজ শুরু নিষিদ্ধ — লিখিত পারমিট ছাড়া লাইন চার্জ হতে পারে'],
    whyWrong: [
      'সাবস্টেশনের ডিউটি অপারেটরের মুখের কথাই লাইনম্যানের জন্য সবচেয়ে নির্ভরযোগ্য',
      'জরুরি ফল্ট মেরামতে ফোনে ফোনে অনুমতি নিয়ে কাজ সারলে দ্রুত বিদ্যুৎ চালু হয়',
    ],
    caughtTag: 'মৌখিক অনুমানের ভিত্তিতে কাজ বন্ধ',
  );
  const c8Hazard2 = TenSecCheck(
    id: 'c8_ptw_no_read',
    categoryBn: 'পিটিডব্লিউ ও ব্রিফিং',
    labelBn: 'পিটিডব্লিউ না পড়ে ও ফিডার নম্বর না মিলিয়ে অনুমান করে কাজ শুরু',
    svgArt: 'assets/game/art/scan_board/ptw_no_read.svg',
    isSafe: false,
    mistake: TenSecMistakes.ptwNoRead,
    whyRight: ['ফিডার নম্বর না মেলালে ভুলবশত লাইভ ফিডারে কাজ শুরু করার চরম ঝুঁকি তৈরি হয়'],
    whyWrong: [
      'কাছের ট্রান্সফরমার দেখেই অভিজ্ঞ লাইনে কোন ফিডার তা সহজে অনুমান করা যায়',
      'এলাকার সব ফিডারের কাজ একইরকম তাই আলাদা করে নম্বর মিলিয়ে দেখার দরকার নেই',
    ],
    caughtTag: 'ফিডার নম্বর যাচাইকরণ',
  );

  // 9. Weather & Surroundings
  const c9Safe = TenSecCheck(
    id: 'c9_env_ok',
    categoryBn: 'পরিবেশ ও ব্যারিকেড',
    labelBn: 'রাস্তার পাশে ট্র্যাফিক কোণ ও লাল-সাদা ব্যারিকেড টেপ লাগানো',
    svgArt: 'assets/game/art/scan_board/site_barricade.svg',
    isSafe: true,
    mistake: TenSecMistakes.safeStopped,
    whyRight: ['ব্যারিকেড চলমান দ্রুতগামী যানবাহন ও পথচারীদের কাজের এলাকা থেকে দূরে রাখে'],
    whyWrong: [
      'গ্রামের ফাঁকা শান্ত রাস্তায় আলাদা কোনো ট্র্যাফিক ব্যারিকেডের দরকার হয় না',
      'কাজের মই নিজেই অনেক দূর থেকে দেখা যায় তাই আলাদা ট্র্যাফিক কোণ রাখা অপচয়',
    ],
    caughtTag: 'সাইট ব্যারিকেড ও ট্র্যাফিক কোণ',
  );
  const c9Hazard1 = TenSecCheck(
    id: 'c9_storm_sky',
    categoryBn: 'পরিবেশ ও আবহাওয়া',
    labelBn: 'আকাশে কালো মেঘ ও বিদ্যুৎ চমকাচ্ছে',
    svgArt: 'assets/game/art/scan_board/hazard_storm_sky.svg',
    isSafe: false,
    mistake: TenSecMistakes.stormSky,
    whyRight: ['বজ্রপাত দেখা বা শোনা মাত্র কাজ বন্ধ — কোনো পিপিই বজ্রপাত ঠেকাতে পারে না'],
    whyWrong: [
      'পোলে রাবারের জুতো পরা থাকলে বজ্রপাতের প্রবল বিদ্যুৎ কখনোই শরীরে ধরে না',
      'ভারী বৃষ্টি শুরু না হওয়া পর্যন্ত পোলের উঁচুতে কাজ অনায়াসে চালিয়ে যাওয়া যায়',
    ],
    caughtTag: 'বজ্রপাতে কাজ বন্ধের সিদ্ধান্ত',
  );
  const c9Hazard2 = TenSecCheck(
    id: 'c9_beehive',
    categoryBn: 'পরিবেশ ও বাধা',
    labelBn: 'পোলের মাথায় ক্রসআর্মে বলতা বা মৌমাছির বিশাল চাক',
    svgArt: 'assets/game/art/scan_board/hazard_beehive.svg',
    isSafe: false,
    mistake: TenSecMistakes.beehiveCrossarm,
    whyRight: ['বলতার কামড়ে পোলের ওপর ভারসাম্য হারিয়ে মারাত্মক পতনের চরম ঝুঁকি তৈরি হয়'],
    whyWrong: [
      'ধোঁয়া না দিয়ে চুপচাপ সাবধানে কাজ করলে বলতা কখনোই মানুষকে কামড় দেয় না',
      'বলতার হুলে সামান্য জ্বালাপোড়া ছাড়া লাইনের কাজে কোনো বড় বিপদ হতে পারে না',
    ],
    caughtTag: 'বলতার চাক এড়িয়ে চলা',
  );
  const c9Hazard3 = TenSecCheck(
    id: 'c9_traffic',
    categoryBn: 'পরিবেশ ও ট্র্যাফিক',
    labelBn: 'ব্যস্ত রাস্তায় কোনো ট্র্যাফিক কোণ বা সিগন্যাল ছাড়াই মই লাগানো',
    svgArt: 'assets/game/art/scan_board/hazard_traffic.svg',
    isSafe: false,
    mistake: TenSecMistakes.trafficNoBarrier,
    whyRight: ['ব্যস্ত সড়কে ব্যারিকেড না থাকলে চলন্ত গাড়ির ধাক্কায় মই ভেঙে দুর্ঘটনা ঘটে'],
    whyWrong: [
      'গাড়ির ড্রাইভাররা দূর থেকেই উঁচু মই দেখতে পেয়ে নিজ দায়িত্বে গাড়ি থামাবে',
      'রাস্তার একেবারে কিনারায় কাজ করলে কোনো ট্র্যাফিক ব্যারিকেড টেপ দরকার হয় না',
    ],
    caughtTag: 'ট্র্যাফিক নিরাপত্তা নিশ্চিতকরণ',
  );

  // 10. Rescue & Mindset
  const c10Safe = TenSecCheck(
    id: 'c10_rescue_ok',
    categoryBn: 'উদ্ধার ও প্রস্তুতি',
    labelBn: 'উদ্ধারের দড়ি, প্রাথমিক চিকিৎসার কিট ও জরুরি নম্বর রেডি',
    svgArt: 'assets/game/art/scan_board/rescue_ready.svg',
    isSafe: true,
    mistake: TenSecMistakes.safeStopped,
    whyRight: ['দুর্ঘটনা ঘটলে গোল্ডেন মিনিটে দ্রুত উদ্ধার করতে সরঞ্জাম হাতের কাছে থাকা চাই'],
    whyWrong: [
      'কাজ শুরুর আগে বিপদের কথা ভেবে উদ্ধার কিট রেডি রাখলে কাজে অমঙ্গল ডেকে আনে',
      'প্রাথমিক চিকিৎসার বক্স কেবল হাসপাতালে থাকে, কাজের মাঠে ওসব বয়ে নেওয়া বাড়তি',
    ],
    caughtTag: 'জরুরি উদ্ধার প্রস্তুতি',
  );
  const c10Hazard1 = TenSecCheck(
    id: 'c10_rescue_blocked',
    categoryBn: 'উদ্ধার ও প্রস্তুতি',
    labelBn: 'উদ্ধারের রাস্তা অবরুদ্ধ এবং ফার্স্ট এইড কিট গায়েব',
    svgArt: 'assets/game/art/scan_board/rescue_blocked.svg',
    isSafe: false,
    mistake: TenSecMistakes.rescueBlocked,
    whyRight: ['উদ্ধারের পথ আটকানো থাকলে বিপদের সময় গোল্ডেন মিনিটের অমূল্য মুহূর্ত নষ্ট হয়'],
    whyWrong: [
      'জরুরি অ্যাম্বুলেন্স নম্বর জানা থাকলে মাঠে আলাদা উদ্ধার সরঞ্জামের প্রয়োজন নেই',
      'উদ্ধার মহড়ার নিয়মকানুন শুধুমাত্র বড় সাবস্টেশনের জন্য প্রযোজ্য, মাঠে নয়',
    ],
    caughtTag: 'অবরুদ্ধ উদ্ধার পথ পরিহার',
  );
  const c10Hazard2 = TenSecCheck(
    id: 'c10_mind_tired',
    categoryBn: 'মানসিক স্থিতি',
    labelBn: 'লাইনম্যানের শরীর অসুস্থ, মাথা ঘুরছে এবং মারাত্মক ক্লান্তি',
    svgArt: 'assets/game/art/scan_board/mind_tired.svg',
    isSafe: false,
    mistake: TenSecMistakes.mindTired,
    whyRight: ['শারীরিক অসুস্থতা বা ক্লান্তি থাকলে মনোযোগ হারিয়ে উঁচুতে মারাত্মক দুর্ঘটনা ঘটে'],
    whyWrong: [
      'কাজের চাপে একটু মাথা ঘুরলে চা খেয়ে কাজ চালিয়ে নেওয়া সাহসী লাইনম্যানের দায়িত্ব',
      'শরীর যেমনই লাগুক না কেন নির্ধারিত কাজ ফেলে বাড়ি ফেরা অপেশাদার আচরণের লক্ষণ',
    ],
    caughtTag: 'অসুস্থ অবস্থায় স্টপ ওয়ার্ক',
  );

  // Assemble candidate pools per category: [safe, hazard...]
  final pools = <List<TenSecCheck>>[
    [c1Safe, c1Hazard1, c1Hazard2],
    [c2Safe, c2Hazard],
    [c3Safe, c3Hazard],
    [c4Safe, c4Hazard1, c4Hazard2],
    [c5Safe, c5Hazard1, c5Hazard2],
    [c6Safe, c6Hazard1, c6Hazard2],
    [c7Safe, c7Hazard],
    [c8Safe, c8Hazard1, c8Hazard2],
    [c9Safe, c9Hazard1, c9Hazard2, c9Hazard3],
    [c10Safe, c10Hazard1, c10Hazard2],
  ];

  // Guarantee exactly 4 to 6 safe items (balanced mix of Go/Stop)
  final numSafe = 4 + rng.nextInt(3); // 4, 5, or 6
  final allIndices = List.generate(pools.length, (i) => i)..shuffle(rng);
  final safeIndices = allIndices.take(numSafe).toSet();

  final selected = <TenSecCheck>[];
  var deadlyCount = 0;

  for (var i = 0; i < pools.length; i++) {
    final pool = pools[i];
    if (safeIndices.contains(i)) {
      selected.add(pool.first);
    } else {
      final hazards = pool.sublist(1);
      final pick = hazards[rng.nextInt(hazards.length)];
      if (pick.mistake.deadly) deadlyCount++;
      selected.add(pick);
    }
  }

  // Ensure at least one deadly hazard is present
  if (deadlyCount == 0) {
    selected[5] = c6Hazard1; // Rusted pole base
  }

  // Coworker arrives at check 4 or 5
  final coworkerRound = rng.nextBool() ? 4 : 5;

  return TenSecDeal(checks: selected, coworkerRound: coworkerRound);
}


// ============================================================================
// TenSecRun (Logic Engine)
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

  int get percent => (100 - slips * 15).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 70;

  void tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Evaluates player decision: returns null if correct, or DoMistake if wrong.
  DoMistake? evaluate(bool chooseGo) {
    if (ended) return null;
    final c = current;
    if (chooseGo == c.isSafe) {
      tag(c.caughtTag);
      return null;
    }
    // Player made a wrong choice
    if (c.isSafe && !chooseGo) {
      // Stopped on a completely safe check
      slips++;
      return TenSecMistakes.safeStopped;
    } else {
      // Pressed GO on a hazard!
      final m = c.mistake;
      if (m.deadly) {
        deadly = m;
      } else {
        slips++;
      }
      return m;
    }
  }

  void advance() {
    if (index < deal.checks.length) {
      index++;
    }
  }
}

// ============================================================================
// Widgets & Pages
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

class _TenSecRunPageState extends ConsumerState<_TenSecRunPage>
    with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final TenSecRun _run = TenSecRun(dealTenSec(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;

  var _ready = false;
  int _stepTok = 0;
  final _nudge = TaskNudge();
  int _nudgeN = 0;
  String get _task => TenSecLines.ask;

  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? TenSecLines.tapWhy[_nudgeN++ % TenSecLines.tapWhy.length]
            : _nudge.next(_task);
    ref.read(guideDirectorProvider.notifier).say(mood: GuideMood.talk, line: line);
    unawaited(MascotSpeechLibrary.speak(line, muted: _muted));
  }

  @override
  LevelContext get deathCtx => widget.ctx;

  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _stepTok++;
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

  Future<void> _start() async {
    setState(() => _intro = false);
    _clock.start();
    _beginCheck();
  }

  void _beginCheck() {
    final tok = ++_stepTok;
    setState(() => _ready = false);

    // If coworker moment should happen at this round
    if (_run.index == _run.deal.coworkerRound && !coworkerDone) {
      scheduleCoworker();
    }

    unawaited(() async {
      await Future<void>.delayed(_quiet ? const Duration(milliseconds: 50) : const Duration(milliseconds: 200));
      if (!mounted || tok != _stepTok || _ended) return;
      setState(() => _ready = true);
      if (!coworkerOpen && !_waitingForCoworker) {
        await _say(TenSecLines.ask);
      }
    }());
  }

  bool get _waitingForCoworker => _run.index == _run.deal.coworkerRound && !coworkerDone && !coworkerOpen;

  bool get _canDecide =>
      !_intro && _ready && !_busy && !_ended && _card == null && !reasonOpen && !coworkerOpen && !_waitingForCoworker;

  // --- Decision Handler ------------------------------------------------------
  Future<void> _decide(bool chooseGo, Offset origin) async {
    if (!_canDecide) return;
    _busy = true;
    _hush();

    final mistake = _run.evaluate(chooseGo);
    if (mistake == null) {
      // CORRECT DECISION!
      HapticFeedback.lightImpact();
      if (!_muted) {
        unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.65, muted: false));
      }
      putOnTable(15);
      final c = _run.current;
      await askReason(
        deal: () => dealChoices(c.whyRight, c.whyWrong, widget.rng),
        question: 'কেন এই সিদ্ধান্ত নেওয়া জরুরি?',
        stillValid: () => mounted && !_ended,
      );
      _busy = false;
    } else {
      // MISTAKE!
      HapticFeedback.mediumImpact();
      if (!_muted) {
        unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
      }
      if (mistake.deadly) {
        final outcome = await bookDeadly(mistake, runScore: _runScore);
        setState(() {
          _card = mistake;
          _cardTone = outcome == DeadlyOutcome.nearMiss ? MistakeTone.nearMiss : MistakeTone.deadly;
          _busy = false;
        });
      } else {
        final out = strike(mistake);
        setState(() {
          _card = mistake;
          _cardTone = MistakeTone.slip;
          _busy = false;
        });
        if (out) {
          unawaited(recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore));
        }
      }
    }
  }

  // --- ReasonTable Hooks -----------------------------------------------------
  @override
  bool get reasonMuted => _muted;

  @override
  bool get reasonEnded => _ended;

  @override
  Future<void> reasonSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);

  @override
  void reasonHush() => _hush();

  @override
  Future<void> reasonScore(int delta, Offset origin, {GuideMood? mood}) async {
    _totalDelta += delta;
    _runScore += delta;
    await BeatFx.levelDelta(ref, delta, originGlobal: origin, mood: mood, muted: _muted);
  }

  @override
  void onReasonPaid() {
    _advance();
  }

  void _advance() {
    _run.advance();
    if (_run.done) {
      unawaited(_finish());
    } else {
      _beginCheck();
    }
  }

  Future<void> _finish() async {
    _clock.stop();
    final ms = _clock.elapsedMilliseconds;
    final mark = _run.percent;
    final passed = _run.passed;
    final quick = passed && ms <= 45000 && _run.slips == 0;
    final stars = starsFor(passed: passed, strikes: _run.slips, quick: quick);

    final save = ref.read(gameSaveProvider.notifier);
    await save.recordLevelResult(widget.ctx.rungId, mark);
    await save.commitLevelScore(widget.ctx.rungId, _runScore);

    setState(() {
      _ended = true;
      _mark = mark;
      _stars = stars;
      _quickBonus = quick;
    });

    if (passed) {
      if (!_muted) unawaited(ZlFx.cue('sounds/level_done.wav', volume: 0.8, muted: false));
      await _say(TenSecLines.allSet, mood: GuideMood.celebrate);
    } else {
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/level_fail.wav', volume: 0.7, muted: false));
      await _say(TenSecLines.fail, mood: GuideMood.warn);
    }
  }

  // --- CoworkerMoment Hooks --------------------------------------------------
  @override
  CoworkerScript get coworkerScript => TenSecLines.coworker;

  @override
  math.Random get coworkerRng => widget.rng;

  @override
  bool get coworkerMuted => _muted;

  @override
  bool? coworkerCanCome() {
    if (_ended || _intro || _card != null || reasonOpen || _run.done) return null;
    return _run.index == _run.deal.coworkerRound;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);

  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (held) {
      _run.tag('সহকর্মীর চাপে "না" বলা');
      putOnTable(20);
      await askReason(
        deal: () => dealChoices(TenSecLines.coworkerWhyRight, TenSecLines.coworkerWhyWrong, widget.rng),
        question: 'কেন সহকর্মীর কথায় চেকলিস্ট বাদ দেওয়া যাবে না?',
        stillValid: () => mounted && !_ended,
      );
    } else {
      final out = strike(TenSecMistakes.mindRushed);
      setState(() {
        _card = TenSecMistakes.mindRushed;
        _cardTone = MistakeTone.slip;
      });
      if (out) {
        unawaited(recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore));
      }
    }
  }

  // --- Dismissals & Exits ----------------------------------------------------
  void _dismissCard() {
    if (_card == null) return;
    final tone = _cardTone;
    setState(() => _card = null);
    if (tone == MistakeTone.deadly) {
      unawaited(dieAndLeave());
    } else if (tone == MistakeTone.nearMiss) {
      widget.onRetry(_muted);
    } else {
      if (struckOut) {
        widget.onRetry(_muted);
      } else {
        // Continue to next check after small slip
        _advance();
      }
    }
  }

  Future<void> _leave() async {
    _hush();
    if (deathPending) {
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

  // --- UI Build --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final playing = !_intro && _mark == null && !struckOut && _card == null;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _ready;

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
              labels: const ['১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯', '১০'],
              done: {for (var i = 0; i < math.min(_run.index, 10); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => [
              // 1. Photographic backdrop
              const Positioned.fill(
                child: DoBackdrop(
                  asset: 'assets/zero_loss/scene/bg_span_two_poles.webp',
                  alignment: Alignment(0, -0.2),
                ),
              ),

              // 2. Center Inspection Card
              if (playing && !_run.done)
                Positioned(
                  left: 16,
                  right: 16,
                  top: pad.top + 64,
                  bottom: pad.bottom + (deckUp ? 280 : 160),
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: deckUp ? 0.75 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      child: _ScanCard(
                        check: _run.current,
                        stepIndex: _run.index + 1,
                        totalSteps: _run.deal.checks.length,
                      ),
                    ),
                  ),
                ),
            ],
            overlays: [
              // Reason table tokens
              ...tableLayers(at: Offset(size.width / 2, pad.top + 130), quiet: quiet),

              // Hands-on Go / Stop Action Buttons
              if (handsOn)
                Positioned(
                  key: const ValueKey('hud-decide'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      // STOP BUTTON
                      Expanded(
                        flex: 3,
                        child: _StopButton(
                          label: TenSecLines.stopBtn,
                          onTapUp: (d) => unawaited(_decide(false, d.globalPosition)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // GO BUTTON
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

              // Options & Coworker Deck (bottom sheet)
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

              // Mascot in corner
              if (playing && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 236 : 72),
                  onLeft: coworkerFromRight,
                ),

              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),

              // Mistake Card
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
                  mistake: _card!,
                  tone: _cardTone,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null
                      ? null
                      : () => unawaited(
                            openLessonPoint(
                              context,
                              ref,
                              lessonId: widget.ctx.lessonId,
                              point: _card!.lessonPoint,
                              muted: _muted,
                            ),
                          ),
                  onGo: _dismissCard,
                ),

              // 3 Strikes Out Card
              if (struckOut && _card == null)
                StruckOutCard(
                  key: const ValueKey('struck'),
                  mistake: strikeOutBy ?? TenSecMistakes.safeStopped,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.electric,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),

              // Result Panels
              if (_mark != null)
                Positioned.fill(
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
                                  onRead: () => unawaited(
                                    openLessonPoint(
                                      context,
                                      ref,
                                      lessonId: widget.ctx.lessonId,
                                      point: 0,
                                      muted: _muted,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Intro Overlay
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: TenSecLines.intro,
                  alarm: 'sounds/learn/rush_in.wav',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    unawaited(_start());
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Visual Components
// ============================================================================

class _ScanCard extends StatelessWidget {
  const _ScanCard({
    required this.check,
    required this.stepIndex,
    required this.totalSteps,
  });

  final TenSecCheck check;
  final int stepIndex;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      constraints: const BoxConstraints(maxHeight: 310),
      decoration: BoxDecoration(
        color: SlmColors.navy900.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.4), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Pill: Step N/10 · Category
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
                      enDigits('ধাপ $stepIndex/$totalSteps'),
                      style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.gold300),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      check.categoryBn,
                      style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ivory),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Artwork Area
            Expanded(
              child: Container(
                color: const Color(0xFF09101F),
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: SvgPicture.asset(
                    check.svgArt,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Caption Pill
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              color: SlmColors.navy950,
              child: Text(
                check.labelBn,
                textAlign: TextAlign.center,
                style: bangla(fontSize: 13, fontWeight: FontWeight.w700, color: SlmColors.ivory, height: 1.3),
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
