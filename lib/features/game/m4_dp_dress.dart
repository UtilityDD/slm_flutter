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
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm4_dp_dress_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 4.7 "ডিপি (DP) স্ট্রাকচার ড্রেসিং: পরিচ্ছন্নতার শিল্প", কাজ 2
// "পরিচ্ছন্নতার শিল্প" (pack do_4_7_b, engineType m4_dp_dress). One village
// DP transformer structure, three rounds:
//
//  ক শাটডাউন (order): the permit in hand → the tester proves the line dead →
//    an earth set on each side span (left and right) → the harness on → climb.
//  খ ড্রেসিং (spot + choose): four of six places on the structure are untidy
//    (dealt fresh). Tap one, then choose how to put it right on the card deck.
//    Top first: HT before LT. A tidy place tapped = a slip.
//  গ লাইন ক্লিয়ার (order, in reverse): climb down → look over the work from
//    the ground (and take its photo) → both earth sets off → the line clear
//    (the permit returned).
//
// The lesson's rules, and only those (lesson 4.7 + its film script):
//   • point 1: jumpers in a smooth, even U/C shape; LT cables bunched with
//     ties/clamps; clearance between phases and from the body; extra binding
//     wire cut off; cross-arms/insulators level and plumb;
//   • point 2: tangled jumpers (measure, smooth bends); clearance (check it
//     from a distance); untidy LT cables (ties/clamps); loose connections
//     (tighten every nut, bolt and connector);
//   • pro tips: start from the top (HT) and come down to LT; photograph good
//     work; myths: "dressing is for show", "touching insulated wires is fine".
// From the module's safety rules (NOT lesson 4.7's text — flagged in
// REGISTER.md): line work only after shutdown, PTW, a test and earth; earth
// from both sides (lesson 4.1, point 1); the earth goes on after the test and
// comes off only after everyone is down, before the line clear (lessons 1.5,
// 1.6); a helmet and harness for anyone on a pole (the brief).
//
// Deadly: climbing to work without both earth sets on — also by listening to
// the coworker's "এক দিকের আর্থ খুলে কাজ সেরে ফেলো" while up the pole.
// Slips: a step out of order (test before the permit, earth before the
// test), climbing without the harness, a tidy place "fixed", LT before HT, a
// wrong fix (one per place), the earth off while still up, looking over the
// work from up the pole, the line clear with anything left undone.
// Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m4_dp_dress_world.dart), corner guide, ◆ on the table → "কেন …?"
// after each round → the next round by itself; the careless coworker once a
// play, during the dressing. Voice: the guide by device TTS; the coworker's
// new push by device TTS until recorded (his exit line is his existing clip).

// ============================================================================
// Content
// ============================================================================

/// The play's rounds.
enum M4DpDressRound { prep, dress, clear }

/// The hands-on buttons.
enum M4DpDressTool { permit, tester, harness, climb, down, look, lineClear }

abstract final class M4DpDressLines {
  static const title = 'পরিচ্ছন্নতার শিল্প';
  static const intro = 'অগোছালো ডিপি মানেই শর্ট সার্কিটের ফাঁদ! শাটডাউনে নিরাপদে উঠে পরিপাটি করে সাজান।';
  static const rounds = ['শাটডাউন', 'ড্রেসিং', 'লাইন ক্লিয়ার'];

  // The guide's task now (tap him: the same task, a different way).
  static const askPrep = 'ওঠার আগে লাইন নিরাপদ করুন।';
  static const askDress = 'স্ট্রাকচারের খুঁতগুলো খুঁজে ঠিক করুন।';
  static const askFix = 'কীভাবে ঠিক করবেন?';
  static const askClear = 'কাজ শেষ। এবার নিরাপদে লাইন ক্লিয়ার।';
  static const tasks = [askPrep, askDress, askFix, askClear];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (the tools, the tester).
  static const sceneLabel = 'ডিপি স্ট্রাকচার';
  static const permit = 'পারমিট';
  static const tester = 'টেস্টার';
  static const harness = 'হার্নেস';
  static const climb = 'উঠুন';
  static const down = 'নামুন';
  static const look = 'দেখে ছবি';
  static const lineClear = 'লাইন ক্লিয়ার';
  static const testerDead = '0 V';

  static String toolLabel(M4DpDressTool t) => switch (t) {
        M4DpDressTool.permit => permit,
        M4DpDressTool.tester => tester,
        M4DpDressTool.harness => harness,
        M4DpDressTool.climb => climb,
        M4DpDressTool.down => down,
        M4DpDressTool.look => look,
        M4DpDressTool.lineClear => lineClear,
      };

  // How to put each place right (the choose deck, lesson 4.7 points 1–2).
  // The wrong ones are field shortcuts and the lesson's myths. 33–41 letters.
  static const fixRight = <M4DpDressSlot, List<String>>{
    M4DpDressSlot.tangle: ['দৈর্ঘ্য মেপে জাম্পারে মসৃণ U বাঁক দিই', 'জট খুলে মাপমতো কেটে সুষম C আকার দিই'],
    M4DpDressSlot.clearance: ['জাম্পার সরিয়ে ক্রস-আর্ম থেকে দূরত্ব রাখি', 'ফেজ আর বডির মাঝে নিরাপদ দূরত্ব রেখে বাঁধি'],
    M4DpDressSlot.tail: ['বাইন্ডিং তারের বাড়তি লেজ কেটে ফেলি', 'বাঁধনের বাড়তি তার ছেঁটে ফেলে দিই'],
    M4DpDressSlot.tilt: ['ক্রস-আর্ম অনুভূমিক করে বসিয়ে কষে দিই', 'ক্রস-আর্ম লেভেলে এনে ফিউজ খাড়া করে দিই'],
    M4DpDressSlot.loose: ['নাট-বল্টু রেঞ্চে সঠিক টর্কে টাইট দিই', 'লাগের নাট পুরো বসিয়ে ঠিকমতো টাইট দিই'],
    M4DpDressSlot.ltCable: ['এলটি কেবিল ক্ল্যাম্পে গুছিয়ে বেঁধে নামাই', 'কেবিল টাই দিয়ে এলটি কেবিল বাঞ্চিং করি'],
  };
  static const fixWrong = [
    'টেপ পেঁচিয়ে দিই, ওতেই কাজ চলে যাবে',
    'যেমন আছে থাক, লাইন তো দিব্যি চলছে',
    'ইনসুলেটেড তার, ছুঁয়ে থাকলেও ক্ষতি নেই',
    'দেখতে খারাপ, তবে কাজে কোনো সমস্যা নেই',
    'পরের শাটডাউনে এসে এটা ঠিক করে দেব',
    'একটু ঢিলা থাক, পরে নিজে থেকেই বসে যাবে',
    'বাড়তি তার রেখে দিই, পরে কাজে লাগবে',
  ];
  static List<String> get allFixRight => [for (final l in fixRight.values) ...l];

  // The reasons: the right ones fit what was done this round; the wrong ones
  // are the lesson's myths and field excuses. 38–49 letters.
  static const prepWhyQ = 'কেন দুই দিকে আর্থ দিয়ে তবে উঠলেন?';
  static const clearWhyQ = 'কেন সবাই নামার পর তবে আর্থ খুললেন?';
  static const prepWhy = ['বন্ধ লাইনেও চার্জ থাকে, আর্থ তা মাটিতে নামায়', 'পারমিট, টেস্ট, দুই দিকে আর্থ — তবেই লাইনে হাত'];
  static const clearWhy = ['সবাই নিচে নামার পর তবেই আর্থ খোলা যায়', 'লোক পোলে থাকতে আর্থ খুললে সে অরক্ষিত হয়'];
  static const dressWhyQ = <M4DpDressSlot, String>{
    M4DpDressSlot.tangle: 'কেন জাম্পারে মসৃণ বাঁক দিলেন?',
    M4DpDressSlot.clearance: 'কেন জাম্পার পোল থেকে সরালেন?',
    M4DpDressSlot.tail: 'কেন বাইন্ডিং তারের লেজ কাটলেন?',
    M4DpDressSlot.tilt: 'কেন ক্রস-আর্ম সোজা করলেন?',
    M4DpDressSlot.loose: 'কেন লাগটা টাইট দিলেন?',
    M4DpDressSlot.ltCable: 'কেন এলটি কেবিল গুছিয়ে বাঁধলেন?',
  };
  static const dressWhy = <M4DpDressSlot, List<String>>{
    M4DpDressSlot.tangle: ['জট পাকানো জাম্পার বিপদের লক্ষণ, মসৃণ বাঁক চাই', 'মাপমতো জাম্পারে মসৃণ U বাঁক — জট থাকে না'],
    M4DpDressSlot.clearance: ['ফেজ আর বডির মাঝে ক্লিয়ারেন্স না থাকলে শর্ট হয়', 'বাতাসে দুলে ছুঁয়ে গেলে শর্ট সার্কিট হতে পারে'],
    M4DpDressSlot.tail: ['বাড়তি লেজ বাতাসে উড়ে অন্য তার ছুঁয়ে শর্ট করায়', 'বাইন্ডিং তারের বাড়তি অংশ কেটে ফেলাই নিয়ম'],
    M4DpDressSlot.tilt: ['ইনসুলেটর আর ক্রস-আর্ম খাড়া ও সোজা থাকাই নিয়ম', 'নিখুঁত উল্লম্ব-অনুভূমিক বিন্যাসই ভালো ড্রেসিং'],
    M4DpDressSlot.loose: ['সুন্দর ড্রেসিংও ঢিলা নাট-বল্টুতে নষ্ট হয়', 'প্রতিটি কানেকশন সঠিক টর্কে টাইট করা চাই'],
    M4DpDressSlot.ltCable: ['গোছানো কেবিলে অপ্রয়োজনীয় টান পড়ে না', 'গোছানো কেবিলে কোনটা কোথায়, সহজে বোঝা যায়'],
  };
  static const myths = [
    'ড্রেসিং তো শুধু দেখানোর, লাইন চললেই হলো',
    'ইনসুলেটেড তার, একটু ছুঁয়ে থাকলে কিছু হয় না',
    'শাটডাউন তো নেওয়া, আর্থ ছাড়াই উঠে যাওয়া যায়',
    'তাড়াতাড়ি সারতে হবে, তাই যেখান থেকে খুশি',
    'সুপারভাইজার দেখবেন না, তাই যেমন খুশি করলাম',
    'আর্থ এক দিকে থাকলেই যথেষ্ট, দুই দিকে লাগে না',
    'বাড়তি তার রেখে দিলে পরে কোনো কাজে লাগবে',
  ];
  static List<String> get allWhyRight => [...prepWhy, ...clearWhy, for (final l in dressWhy.values) ...l];

  static List<String> whyRight(M4DpDressRound r, M4DpDressSlot dress) => switch (r) {
        M4DpDressRound.prep => prepWhy,
        M4DpDressRound.dress => dressWhy[dress]!,
        M4DpDressRound.clear => clearWhy,
      };
  static String whyQuestion(M4DpDressRound r, M4DpDressSlot dress) => switch (r) {
        M4DpDressRound.prep => prepWhyQ,
        M4DpDressRound.dress => dressWhyQ[dress]!,
        M4DpDressRound.clear => clearWhyQ,
      };

  /// The careless coworker: take one earth off while he is up the pole.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'আর্থের তারটা হাতে বাধছে! এক দিকের আর্থ খুলে কাজ সেরে ফেলো।',
    exitLine: coworkerExit,
    right: ['না, দুই দিকের আর্থ রেখেই কাজ সারব', 'না, আর্থ খুলব কাজ শেষে, নামার পর', 'না, আর্থ খুললে আমি অরক্ষিত হব'],
    wrong: [
      'ঠিক, এক দিকের আর্থ খুলে নিই',
      'আচ্ছা, এক দিকে আর্থ থাকলেই চলবে',
      'হ্যাঁ, এক মিনিটের কাজ, খুলেই সারি',
      'ঠিক আছে, লাইন তো বন্ধই, খুলে দিই',
      'হ্যাঁ, তারটা সরাতে আর্থটা খুলি',
    ],
    asks: ['ও বলছে এক দিকের আর্থ খুলতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'আর্থ ছাড়া লাইনে কাজ করবেন?'],
  );

  static const callHeld = 'ঠিক! কাজ চলাকালীন দুই দিকের আর্থ থাকবেই।';
  static const allSet = 'পরিপাটি ডিপি — নিরাপদ শাটডাউনে, উপর থেকে নিচে, আর নিরাপদে লাইন ক্লিয়ার।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে নিরাপদ শাটডাউন, তারপর উপর থেকে নিচে ড্রেসিং।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtEarth = 'পারমিট, টেস্ট, দুই দিকে আর্থ — তবে ওঠা';
  static const caughtTop = 'উপর থেকে নিচে ড্রেসিং';
  static const caughtFix = 'প্রতিটি খুঁতের ঠিক সমাধান';
  static const caughtLook = 'দূর থেকে দেখে ছবি তুলেছেন';
  static const caughtClear = 'নেমে, আর্থ খুলে, তবে লাইন ক্লিয়ার';
  static const caughtCall = 'আর্থ খোলায় “না” বলেছেন';
}

abstract final class M4DpDressMistakes {
  static const _dir = 'assets/game/art/m4_dp_dress';

  // The module's safety rules (lessons 1.5, 1.6, 4.1 — not lesson 4.7's text):
  // no lesson point here.
  static const noEarth = DoMistake(
    key: '4.7/m4_dp_dress/no-earth',
    textBn: 'আর্থ ছাড়া লাইনে কাজ নয়! পারমিট, টেস্টারে মৃত প্রমাণ, তারপর দুই দিকে আর্থ — তবেই পোলে উঠে কাজ।',
    art: '$_dir/no_earth.svg',
    deadly: true,
  );
  static const permitFirst = DoMistake(
    key: '4.7/m4_dp_dress/permit-first',
    textBn: 'আগে পারমিট হাতে — তারপর টেস্ট আর আর্থ। পারমিট ছাড়া লাইনের কোনো কাজ নয়।',
    art: '$_dir/ptw_test.svg',
  );
  static const testFirst = DoMistake(
    key: '4.7/m4_dp_dress/test-first',
    textBn: 'আর্থ দেওয়ার আগে টেস্টারে দেখে নিন লাইন সত্যিই মৃত।',
    art: '$_dir/ptw_test.svg',
  );
  static const noHarness = DoMistake(
    key: '4.7/m4_dp_dress/no-harness',
    textBn: 'পোলে ওঠার আগে হেলমেট আর হার্নেস — পোলে যে-ই উঠুক।',
    art: '$_dir/harness.svg',
  );
  static const needless = DoMistake(
    key: '4.7/m4_dp_dress/needless',
    textBn: 'এই জায়গাটা তো ঠিকই আছে। ভালো করে দেখে আসল খুঁতগুলো খুঁজুন।',
    art: '$_dir/needless.svg',
    lessonPoint: 1,
  );
  static const topDown = DoMistake(
    key: '4.7/m4_dp_dress/top-down',
    textBn: 'ড্রেসিং উপর থেকে নিচে — আগে এইচটি অংশ, তারপর এলটি।',
    art: '$_dir/top_down.svg',
  );
  static const wrongTangle = DoMistake(
    key: '4.7/m4_dp_dress/fix-tangle',
    textBn: 'জট পাকানো জাম্পার বিপদের লক্ষণ। দৈর্ঘ্য মেপে মসৃণ, সুষম U বা C বাঁক দিন।',
    art: '$_dir/jumper_tangle.svg',
    lessonPoint: 2,
  );
  static const wrongClearance = DoMistake(
    key: '4.7/m4_dp_dress/fix-clearance',
    textBn: 'জাম্পার পোলের গায়ে! ফেজের মাঝে আর বডি থেকে নির্ধারিত নিরাপদ দূরত্ব রাখুন।',
    art: '$_dir/jumper_clear.svg',
    lessonPoint: 2,
  );
  static const wrongTail = DoMistake(
    key: '4.7/m4_dp_dress/fix-tail',
    textBn: 'বাইন্ডিং তারের বাড়তি লেজ কেটে ফেলুন — বাতাসে উড়ে অন্য তার ছুঁলেই শর্ট।',
    art: '$_dir/binding_tail.svg',
    lessonPoint: 1,
  );
  static const wrongTilt = DoMistake(
    key: '4.7/m4_dp_dress/fix-tilt',
    textBn: 'ক্রস-আর্ম আর ইনসুলেটর নিখুঁত অনুভূমিক ও উল্লম্ব থাকবে — বাঁকা থাকলে সোজা করুন।',
    art: '$_dir/level_arm.svg',
    lessonPoint: 1,
  );
  static const wrongLoose = DoMistake(
    key: '4.7/m4_dp_dress/fix-loose',
    textBn: 'ঢিলা কানেকশন নয় — প্রতিটি নাট-বল্টু আর কানেক্টর সঠিকভাবে টাইট করুন।',
    art: '$_dir/loose_lug.svg',
    lessonPoint: 2,
  );
  static const wrongLtCable = DoMistake(
    key: '4.7/m4_dp_dress/fix-lt-cable',
    textBn: 'এলটি কেবিল এলোমেলো ঝুলবে না — কেবিল টাই বা ক্ল্যাম্পে গুছিয়ে বেঁধে নামান।',
    art: '$_dir/lt_cable.svg',
    lessonPoint: 2,
  );
  static const lookAloft = DoMistake(
    key: '4.7/m4_dp_dress/look-from-ground',
    textBn: 'পোলের উপর থেকে পুরোটা দেখা যায় না। নেমে, দূর থেকে দেখে ক্লিয়ারেন্স যাচাই করুন।',
    art: '$_dir/look.svg',
    lessonPoint: 2,
  );
  static const earthEarly = DoMistake(
    key: '4.7/m4_dp_dress/earth-early',
    textBn: 'আগে সবাই নিচে — আর্থ খোলা হয় সবার শেষে, পোলে কেউ থাকতে নয়।',
    art: '$_dir/line_clear.svg',
  );
  static const clearEarly = DoMistake(
    key: '4.7/m4_dp_dress/clear-early',
    textBn: 'লাইন ক্লিয়ারের আগে: সবাই নিচে, দূর থেকে দেখা, দুই দিকের আর্থ খোলা — তবেই পারমিট ফেরত।',
    art: '$_dir/line_clear.svg',
  );

  static DoMistake wrongFix(M4DpDressSlot s) => switch (s) {
        M4DpDressSlot.tangle => wrongTangle,
        M4DpDressSlot.clearance => wrongClearance,
        M4DpDressSlot.tail => wrongTail,
        M4DpDressSlot.tilt => wrongTilt,
        M4DpDressSlot.loose => wrongLoose,
        M4DpDressSlot.ltCable => wrongLtCable,
      };

  static List<DoMistake> get all => [
        noEarth,
        permitFirst,
        testFirst,
        noHarness,
        needless,
        topDown,
        for (final s in M4DpDressSlot.values) wrongFix(s),
        lookAloft,
        earthEarly,
        clearEarly,
      ];
}

/// The places on the LT side (dressed after every HT place).
const m4DpDressLt = {M4DpDressSlot.loose, M4DpDressSlot.ltCable};

@immutable
class M4DpDressDeal {
  const M4DpDressDeal({required this.untidy, required this.callAfter, required this.dressWhy});

  /// The untidy places this play (four of six, at least one on the LT side).
  final Set<M4DpDressSlot> untidy;

  /// The coworker comes after this many places are put right (1 or 2).
  final int callAfter;

  /// The place the dressing round's reason asks about (one of [untidy]).
  final M4DpDressSlot dressWhy;
}

M4DpDressDeal m4DpDressDeal(math.Random rng) {
  final ht = [M4DpDressSlot.tangle, M4DpDressSlot.clearance, M4DpDressSlot.tail, M4DpDressSlot.tilt]..shuffle(rng);
  final lt = [...m4DpDressLt]..shuffle(rng);
  // 2 HT + 2 LT, or 3 HT + 1 LT.
  final nLt = rng.nextBool() ? 1 : 2;
  final untidy = {...ht.take(4 - nLt), ...lt.take(nLt)};
  final list = untidy.toList()..sort((a, b) => a.index - b.index);
  return M4DpDressDeal(untidy: untidy, callAfter: 1 + rng.nextInt(2), dressWhy: list[rng.nextInt(list.length)]);
}

/// The play state (pure logic).
class M4DpDressRun {
  M4DpDressRun(this.deal);
  final M4DpDressDeal deal;

  int index = 0;
  int slips = 0;
  int roundSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The round's work is done (its reason comes next).
  var roundDone = false;

  // শাটডাউন
  var permit = false;
  var tested = false;
  var earthL = false;
  var earthR = false;
  var harness = false;
  var aloft = false;

  // ড্রেসিং
  final Set<M4DpDressSlot> fixed = {};
  M4DpDressSlot? picking;
  var _wrongFix = false;
  var _topSlip = false;

  // লাইন ক্লিয়ার
  var looked = false;

  M4DpDressRound get round => M4DpDressRound.values[index.clamp(0, 2)];
  bool get done => index >= 3;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => roundSlips == 0;
  Set<M4DpDressSlot> get untidy => deal.untidy.difference(fixed);
  bool get _open => !ended && !roundDone;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlips++;
    return m;
  }

  /// A tool button. Returns the mistake, if any.
  DoMistake? use(M4DpDressTool t) {
    if (!_open) return null;
    switch (round) {
      case M4DpDressRound.prep:
        switch (t) {
          case M4DpDressTool.permit:
            permit = true;
          case M4DpDressTool.tester:
            if (!permit) return _slip(M4DpDressMistakes.permitFirst);
            tested = true;
          case M4DpDressTool.harness:
            harness = true;
          case M4DpDressTool.climb:
            if (!earthL || !earthR) return deadly = M4DpDressMistakes.noEarth;
            if (!harness) return _slip(M4DpDressMistakes.noHarness);
            aloft = true;
            roundDone = true;
            _tag(M4DpDressLines.caughtEarth);
          default:
            break;
        }
      case M4DpDressRound.dress:
        break;
      case M4DpDressRound.clear:
        switch (t) {
          case M4DpDressTool.down:
            aloft = false;
          case M4DpDressTool.look:
            if (aloft) return _slip(M4DpDressMistakes.lookAloft);
            looked = true;
            _tag(M4DpDressLines.caughtLook);
          case M4DpDressTool.lineClear:
            if (aloft || !looked || earthL || earthR) return _slip(M4DpDressMistakes.clearEarly);
            roundDone = true;
            if (thorough) _tag(M4DpDressLines.caughtClear);
          default:
            break;
        }
    }
    return null;
  }

  /// The earth set on the [left] / right side span: on in round ক, off in round গ.
  DoMistake? tapEarth(bool left) {
    if (!_open) return null;
    final on = left ? earthL : earthR;
    switch (round) {
      case M4DpDressRound.prep:
        if (on) return null;
        if (!permit) return _slip(M4DpDressMistakes.permitFirst);
        if (!tested) return _slip(M4DpDressMistakes.testFirst);
        if (left) {
          earthL = true;
        } else {
          earthR = true;
        }
      case M4DpDressRound.dress:
        return null;
      case M4DpDressRound.clear:
        if (!on) return null;
        if (aloft) return _slip(M4DpDressMistakes.earthEarly);
        if (left) {
          earthL = false;
        } else {
          earthR = false;
        }
    }
    return null;
  }

  /// A place on the structure tapped in round খ (spot).
  DoMistake? tapSlot(M4DpDressSlot s) {
    if (!_open || round != M4DpDressRound.dress || picking != null) return null;
    if (fixed.contains(s)) return null;
    if (!deal.untidy.contains(s)) return _slip(M4DpDressMistakes.needless);
    if (m4DpDressLt.contains(s) && untidy.any((u) => !m4DpDressLt.contains(u))) {
      _topSlip = true;
      return _slip(M4DpDressMistakes.topDown);
    }
    picking = s;
    return null;
  }

  /// The fix chosen for the place being worked on (choose).
  DoMistake? pickFix(bool right) {
    final s = picking;
    if (!_open || s == null) return null;
    if (!right) {
      _wrongFix = true;
      return _slip(M4DpDressMistakes.wrongFix(s));
    }
    fixed.add(s);
    picking = null;
    if (untidy.isEmpty) {
      roundDone = true;
      if (!_topSlip) _tag(M4DpDressLines.caughtTop);
      if (!_wrongFix) _tag(M4DpDressLines.caughtFix);
    }
    return null;
  }

  /// Fails the play (listening to the coworker).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    roundSlips = 0;
    roundDone = false;
    picking = null;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   শাটডাউন: permit, tester, 2 earths, harness, climb ≈ 9000 + reason ~8200
///   ড্রেসিং: 4 × (tap + deal ~1500 + pick) ≈ 4 × 4500 + reason ~8200
///   লাইন ক্লিয়ার: down, look, 2 earths, line clear ≈ 7500 + reason ~8200
/// + the coworker once ≈ 9600                                     ≈ 76700
/// 85 % ≈ 65000 → 70 s.
const m4DpDressQuickMs = 70000;

@immutable
class M4DpDressPack {
  const M4DpDressPack({required this.id, required this.titleBn, this.quickMs = m4DpDressQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M4DpDressPack> m4DpDressPacks = {
  'do_4_7_b': M4DpDressPack(id: 'do_4_7_b', titleBn: M4DpDressLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M4DpDressPage extends StatefulWidget {
  const M4DpDressPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M4DpDressPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4DpDressPage> createState() => _M4DpDressPageState();
}

class _M4DpDressPageState extends State<M4DpDressPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DressRunPage(
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

class _DressRunPage extends ConsumerStatefulWidget {
  const _DressRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4DpDressPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DressRunPage> createState() => _DressRunPageState();
}

class _DressRunPageState extends ConsumerState<_DressRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4DpDressRun _run = M4DpDressRun(m4DpDressDeal(widget.rng));
  late final int _seed = _run.deal.callAfter * 7 + _run.deal.dressWhy.index;
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

  // The fix deck (round খ).
  List<ChoiceOption> _fixOpts = const [];
  final Set<String> _fixWrong = {};
  String? _fixPicked;
  var _fixBusy = false;

  /// The tester's reading, a moment after the test.
  var _tester = false;
  Timer? _testerTimer;

  /// The place just put right (a green ring for a moment) and the photo flash.
  M4DpDressSlot? _justFixed;
  int _fixTok = 0;
  int _photoTok = 0;

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
    _testerTimer?.cancel();
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

  bool get _fixUp => _run.picking != null && _fixOpts.isNotEmpty;

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !coworkerOpen && !_run.roundDone && !_freeze;

  String get _task => switch (_run.round) {
        M4DpDressRound.prep => M4DpDressLines.askPrep,
        M4DpDressRound.dress => _run.picking != null ? M4DpDressLines.askFix : M4DpDressLines.askDress,
        M4DpDressRound.clear => M4DpDressLines.askClear,
      };

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  void _startRound() {
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  // --- hands on -----------------------------------------------------------------
  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  void _useTool(M4DpDressTool t, Offset global) {
    if (!_canPlay) return;
    _tick(t == M4DpDressTool.harness || t == M4DpDressTool.permit ? 'sounds/learn/tag_slap.wav' : 'sounds/intro/click.ogg', 0.5);
    final m = _run.use(t);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    switch (t) {
      case M4DpDressTool.tester:
        _testerTimer?.cancel();
        setState(() => _tester = true);
        _testerTimer = Timer(const Duration(milliseconds: 2200), () {
          if (mounted) setState(() => _tester = false);
        });
      case M4DpDressTool.look:
        _cue('sounds/intro/click.ogg', volume: 0.8);
        setState(() => _photoTok++);
      default:
        break;
    }
    if (_run.roundDone) unawaited(_roundDone());
  }

  void _tapScene(Offset p, M4DpDressGeo geo, Offset global) {
    if (!_canPlay || _fixUp) return;
    for (final left in [true, false]) {
      if (geo.earthHit(left).contains(p)) {
        final before = left ? _run.earthL : _run.earthR;
        final m = _run.tapEarth(left);
        final after = left ? _run.earthL : _run.earthR;
        if (m != null) {
          setState(() => _wake++);
          unawaited(_mistake(m, global));
        } else if (before != after) {
          _tick('sounds/intro/impact_metal.ogg', 0.55);
          setState(() => _wake++);
        }
        return;
      }
    }
    if (_run.round != M4DpDressRound.dress) return;
    for (final s in M4DpDressSlot.values) {
      if (geo.slotHit(s).contains(p)) {
        _tick();
        final m = _run.tapSlot(s);
        setState(() => _wake++);
        if (m != null) {
          unawaited(_mistake(m, global));
        } else if (_run.picking == s) {
          _dealFix(s);
        }
        return;
      }
    }
  }

  void _dealFix(M4DpDressSlot s) {
    setState(() {
      _fixOpts = dealChoices(M4DpDressLines.fixRight[s]!, M4DpDressLines.fixWrong, widget.rng);
      _fixWrong.clear();
      _fixPicked = null;
    });
    _cue('sounds/learn/card_deal_a.wav', volume: 0.6);
    unawaited(_sayChain([M4DpDressLines.askFix], mood: GuideMood.think));
  }

  Future<void> _pickFix(ChoiceOption o, Offset origin) async {
    if (!_canPlay || !_fixUp || _fixBusy || _fixWrong.contains(o.textBn) || _fixPicked != null) return;
    _hush();
    if (!o.correct) {
      setState(() => _fixWrong.add(o.textBn));
      final m = _run.pickFix(false);
      if (m != null) unawaited(_mistake(m, origin));
      return;
    }
    _fixBusy = true;
    final s = _run.picking!;
    setState(() => _fixPicked = o.textBn);
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.wav', volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _ended) return;
    _run.pickFix(true);
    _fixBusy = false;
    _cue('sounds/learn/tag_slap.wav', volume: 0.5);
    setState(() {
      _fixOpts = const [];
      _justFixed = s;
      _fixTok++;
      _wake++;
    });
    if (_run.roundDone) {
      unawaited(_roundDone());
      return;
    }
    if (!coworkerDone && _run.fixed.length >= _run.deal.callAfter) scheduleCoworker();
    unawaited(_sayChain([M4DpDressLines.askDress]));
  }

  Future<void> _roundDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.7);
    _cue('sounds/quiz_right.wav', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final r = _run.round;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M4DpDressLines.whyRight(r, _run.deal.dressWhy), M4DpDressLines.myths, widget.rng),
      question: M4DpDressLines.whyQuestion(r, _run.deal.dressWhy),
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M4DpDressLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.round != M4DpDressRound.dress || _run.roundDone) return null;
    if (_intro || _card != null || reasonOpen || _run.picking != null || _freeze) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: one earth comes off while he works on the line.
      _run.failDeadly(M4DpDressMistakes.noEarth);
      await _deadly(M4DpDressMistakes.noEarth);
      return;
    }
    _run.caught.add(M4DpDressLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M4DpDressLines.callHeld, M4DpDressLines.askDress], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M4DpDressLines.tapWhy[_nudgeN++ % M4DpDressLines.tapWhy.length]
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
    final speak = await SpokenOnce.first('dpdress/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Work on a line without its earths: the scene freezes grey and the flash
  /// comes off the line in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _testerTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _tester = false;
      _fixOpts = const [];
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
    final speak = await SpokenOnce.first('dpdress/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M4DpDressLines.deadlyWord : M4DpDressLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same round goes on from where it was.
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
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
    await _say(!_run.passed ? M4DpDressLines.fail : (_quickBonus ? M4DpDressLines.quick : M4DpDressLines.allSet),
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
    if (_run.aloft) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M4DpDressRig get _rig => M4DpDressRig(untidy: _run.untidy, earthL: _run.earthL, earthR: _run.earthR, aloft: _run.aloft);

  List<M4DpDressTool> get _tools => switch (_run.round) {
        M4DpDressRound.prep => const [M4DpDressTool.permit, M4DpDressTool.tester, M4DpDressTool.harness, M4DpDressTool.climb],
        M4DpDressRound.dress => const [],
        M4DpDressRound.clear => const [M4DpDressTool.down, M4DpDressTool.look, M4DpDressTool.lineClear],
      };

  bool _toolOn(M4DpDressTool t) => switch (t) {
        M4DpDressTool.permit => _run.permit,
        M4DpDressTool.tester => _run.tested,
        M4DpDressTool.harness => _run.harness,
        M4DpDressTool.climb => _run.aloft,
        M4DpDressTool.down => !_run.aloft,
        M4DpDressTool.look => _run.looked,
        M4DpDressTool.lineClear => false,
      };

  static const _icons = {
    M4DpDressTool.permit: Icons.assignment_turned_in_rounded,
    M4DpDressTool.tester: Icons.flash_on_rounded,
    M4DpDressTool.harness: Icons.security_rounded,
    M4DpDressTool.climb: Icons.north_rounded,
    M4DpDressTool.down: Icons.south_rounded,
    M4DpDressTool.look: Icons.photo_camera_rounded,
    M4DpDressTool.lineClear: Icons.power_rounded,
  };

  List<Widget> _scene(SceneMetrics m) {
    final geo = M4DpDressGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final tb = _run.aloft ? geo.aloft : geo.ground;
    final picking = _run.picking;
    final fixed = _justFixed;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('dp'),
                child: RepaintBoundary(child: CustomPaint(painter: M4DpDressPainter(geo: geo, rig: _rig, seed: _seed))),
              ),
              if (_run.aloft)
                Positioned.fill(
                  key: const ValueKey('strap'),
                  child: IgnorePointer(child: CustomPaint(painter: M4DpDressStrapPainter(box: tb))),
                ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: tb,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      // The place being worked on, ringed.
      if (picking != null && !_freeze)
        Positioned.fromRect(
          key: ValueKey('picking-${picking.name}'),
          rect: geo.slotHit(picking),
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFE08A), width: 2.4)),
            ),
          ),
        ),
      // The place just put right: a green ring that fades.
      if (fixed != null && !_freeze)
        Positioned.fromRect(
          key: ValueKey('fixed-$_fixTok'),
          rect: geo.slotHit(fixed),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 1100),
              builder: (_, v, _) => v <= 0.001
                  ? const SizedBox.shrink()
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SlmColors.success.withValues(alpha: v), width: 3),
                      ),
                    ),
            ),
          ),
        ),
      if (_tester && !_freeze)
        Positioned(
          key: const ValueKey('tester'),
          left: geo.ground.left - 4,
          top: geo.ground.top - 40,
          child: const IgnorePointer(child: _TesterChip()),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4DpDressLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition)),
        ),
      ),
      // The photo of the finished work: a short white flash.
      if (_photoTok > 0 && !_freeze)
        Positioned.fill(
          key: ValueKey('photo-$_photoTok'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 0 : 0.7, end: 0),
              duration: const Duration(milliseconds: 380),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(255, 255, 255, v)),
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
              builder: (_, v, _) => CustomPaint(painter: M4DpDressFlashPainter(geo: geo, v: v)),
            ),
          ),
        ),
      // The next round: a short fade.
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

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp || (_fixUp && playing);
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
    final tools = _tools;
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
              labels: M4DpDressLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && tools.isNotEmpty)
                Positioned(
                  key: ValueKey('hud-tools-${_run.index}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final t in tools)
                        _ToolButton(
                          icon: _icons[t]!,
                          label: M4DpDressLines.toolLabel(t),
                          on: _toolOn(t),
                          onTap: (g) => _useTool(t, g),
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
                        : coworkerChoiceUp
                            ? coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck'))
                            : ChoiceDeck(
                                key: ValueKey('fix-deck-${_run.picking?.name}'),
                                options: _fixOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _fixWrong,
                                picked: _fixPicked,
                                onPick: (o, at) => unawaited(_pickFix(o, at)),
                              ),
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
                  line: M4DpDressLines.intro,
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
          Text(M4DpDressLines.testerDead, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit once done.
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.on, required this.onTap});
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
          width: 76,
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
