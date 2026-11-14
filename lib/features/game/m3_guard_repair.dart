import 'dart:async';
import 'dart:math' as math;

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
import 'm3_guard_repair_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm3_guard_repair_world.dart' show M3GuardFault, M3GuardFaultKind, M3GuardGeo;

// Lesson 3.9 "গার্ড ওয়্যার ও ক্রেডল গার্ডিং: অতিরিক্ত সুরক্ষা জাল", কাজ 2
// "জাল মেরামত" (pack do_3_9_b, engineType m3_guard_repair). An 11 kV line
// crosses a village road; the cradle guarding under it is damaged. Four
// stations a play:
//   ক prep (order) — before a hand goes on the cradle: the shutdown, the PTW,
//     the line proven dead with the tester, the portable earth on it (lesson
//     point 4's safety tip: treat the guarding as live until the line above is
//     fully off and earthed; the PTW steps are lesson 1.6's), and the traffic
//     below held (point 2's safety tip); then up the pole (helmet and harness
//     drawn on him). As the shutdown is asked for, the careless coworker
//     walks in: "লাইন বন্ধ করার দরকার নেই, তাড়াতাড়ি সেরে নাও" — say no
//     (then the shutdown goes through); listening = up on the live cradle.
//   খ inspect (spot) — tag every fault on the cradle (point 4: a sagging
//     guard wire, a snapped lacing, a loose clamp, a stolen earth lead; myth
//     2: one broken wire weakens the whole net). Three faults a play: the sag
//     always, two of the other three, each in a dealt place.
//   গ repair (choose) — the right fix for each: re-tension the slack wire to
//     match the other (pro tip 3: not too tight, not too slack), a new GI
//     lacing (point 2: the net is GI wire; pro tip 2: strong joints — not a
//     rope), tighten the loose clamp (pro tip 2), a GI pipe up the pole and a
//     new earth lead through it (pro tip 4).
//   ঘ close (order) — check the vertical clearance between the live
//     conductor and the net (pro tip 1), come down, take the portable earth
//     off, then the line clear (lesson 1.6 point 3: all men down, all
//     equipment off, then the permit back).
//
// Deadly: going up on the cradle with the line live (also by listening to the
// coworker); the portable earth on a live line. Slips: the PTW before the
// shutdown; up without the PTW, the test, the earth or the traffic held; the
// earth before the test; a fault missed; a tag on a sound part (a wrong flag:
// tapping everywhere costs); a wrong fix; a rope for a lacing; pulling the
// guard wire too tight, or calling "টান ঠিক" while it still sags; a bare earth
// lead (no pipe); down without the clearance check; the earth off while still
// up; the line clear while still up or with the earth on. Three slips strike
// the level out. The tool trays are dealt in a shuffled order (never the
// order of the job), so the tray never spells out the steps.
//
// Listening to the coworker stays deadly: what he pushes (working on the
// cradle with the line live) is this rung's own 💀 in MODULE3_LADDER.md
// (row 27). Once the shutdown is asked for, the prep's next tap waits for him
// (holdForCoworker), so a fast player cannot run past him.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m3_guard_repair_world.dart), corner guide, ◆ on the table →
// "কেন …?" → the next station by itself. Gesture hints (how, never what):
// a sweep over the tray or over the whole cradle. Voice: the guide's lines by
// device TTS; the coworker's push is silent with its caption held until it is
// recorded (his exit line is already recorded).

// ============================================================================
// Content
// ============================================================================

enum M3GuardStation { prep, inspect, repair, close }

/// The hands-on tools of the repair.
enum M3GuardTool { tension, gi, spanner, pipe, earthLead, rope }

/// What the close station's reason asks about.
enum M3GuardCloseWhy { clearance, order }

abstract final class M3GuardRepairLines {
  static const title = 'জাল মেরামত';
  static const intro = 'রাস্তার ওপরের সুরক্ষা জাল ঝুলে গেছে, ছিঁড়েছে! আগে লাইন নিরাপদ, তারপর মেরামত।';
  static const rounds = ['ক', 'খ', 'গ', 'ঘ'];

  // The guide's task now (tap him: the same task, a different way).
  static const askPrep = 'জালে ওঠার আগে লাইনটা নিরাপদ করুন।';
  static const askInspect = 'জালটা খুঁটিয়ে দেখুন — কোথায় কোথায় খুঁত?';
  static const askRepair = 'এবার খুঁতগুলো সারান — ঠিক জিনিস দিয়ে।';
  static const askTension = 'তারটা টানুন — পেছনের তারের সমান।';
  static const askClose = 'মেরামত শেষ। এবার কাজ গুটিয়ে লাইন ফেরত দিন।';
  static const tasks = [askPrep, askInspect, askRepair, askTension, askClose];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (tools, the docket).
  static const sceneLabel = 'রাস্তা ক্রসিং-এর গার্ডিং';
  static const shutdown = 'শাটডাউন';
  static const ptw = 'PTW';
  static const tester = 'টেস্টার';
  static const earthSet = 'আর্থ সেট';
  static const traffic = 'ট্র্যাফিক';
  static const climb = 'উঠুন';
  static const doneLooking = 'দেখা শেষ';
  static const pull = 'টানুন';
  static const tensionOk = 'টান ঠিক';
  static const measure = 'ক্লিয়ারেন্স';
  static const comeDown = 'নামুন';
  static const earthOff = 'আর্থ খুলুন';
  static const lineClear = 'লাইন ক্লিয়ার';
  static String toolBn(M3GuardTool t) => switch (t) {
        M3GuardTool.tension => 'টান',
        M3GuardTool.gi => 'GI তার',
        M3GuardTool.spanner => 'স্প্যানার',
        M3GuardTool.pipe => 'পাইপ',
        M3GuardTool.earthLead => 'আর্থ তার',
        M3GuardTool.rope => 'দড়ি',
      };
  static const docket = 'ডকেট';
  static const job = 'রাস্তা ক্রসিং · গার্ডিং মেরামত';
  static String permitNo(int n) => enDigits('PTW নং $n');
  static const testerLive = 'লাইভ';
  static const testerDead = '0 V';

  // The reasons: the right ones state this station's rule; the wrong ones are
  // the lesson's myths and field excuses — never a true rule marked wrong.
  static const whyPrepQ = 'কেন জালে ওঠার আগে এত কিছু?';
  static const whyInspectQ = 'কেন পুরো জাল খুঁটিয়ে দেখলেন?';
  static String whyRepairQ(M3GuardFaultKind k) => switch (k) {
        M3GuardFaultKind.sag => 'কেন টানটা ঠিক জায়গায় থামালেন?',
        M3GuardFaultKind.lacing => 'কেন ছেঁড়া লেসিং নতুন GI তারে বাঁধলেন?',
        M3GuardFaultKind.clamp => 'কেন ঢিলে ক্ল্যাম্পটা টাইট করলেন?',
        M3GuardFaultKind.earth => 'কেন আর্থ তার পাইপের ভেতর দিয়ে নিলেন?',
      };
  static String whyCloseQ(M3GuardCloseWhy w) => switch (w) {
        M3GuardCloseWhy.clearance => 'কেন নামার আগে ক্লিয়ারেন্স দেখলেন?',
        M3GuardCloseWhy.order => 'কেন আর্থ খুলে তবে লাইন ক্লিয়ার দিলেন?',
      };

  static const prepWhy = ['জাল লাইভ ধরেই চলি — বন্ধ আর আর্থ ছাড়া হাত নয়', 'আর্থিং দুর্বল হলে পুরো জালটাই লাইভ হতে পারে', 'PTW শুধু কাগজ, টেস্টে মৃত প্রমাণ করা চাই'];
  static const inspectWhy = ['একটা ছেঁড়া তারেও পুরো জালের শক্তি কমে যায়', 'ঝুলে পড়া জাল বাতাসে লাইভ তার ছুঁতে পারে', 'আর্থ চুরি গেলে জাল তার আসল কাজটাই হারায়'];
  static const sagWhy = ['বেশি টানে তার ছেঁড়ে, কম টানে ঝুলে পড়ে', 'ঝুলে থাকলে লাইভ তারের সঙ্গে দূরত্ব কমে যায়'];
  static const lacingWhy = ['একটা ছেঁড়া লেসিং পুরো কাঠামোকে দুর্বল করে', 'জালটা GI তারে বোনা, জোড়াও মজবুত হওয়া চাই'];
  static const clampWhy = ['একটা দুর্বল জয়েন্টেই পুরো গার্ডিং অকেজো হয়', 'বাইন্ডিং তার আর ক্ল্যাম্প মজবুত রাখতে হয়'];
  static const earthWhy = ['আর্থ তার প্রায়ই চুরি যায়, পাইপে তা ঠেকানো যায়', 'জাল আর্থ থাকলে তবেই ফল্টে ব্রেকার ট্রিপ করে'];
  static const clearanceWhy = ['লাইভ তার আর জালের উল্লম্ব দূরত্ব আইনত জরুরি', 'দূরত্ব কম হলে আর্ক বা শর্ট সার্কিট হতে পারে'];
  static const orderWhy = ['সবাই নেমে, যন্ত্র সরিয়ে তবেই লাইন ক্লিয়ার', 'পোর্টেবল আর্থ লাগানো রেখে লাইন ফেরত নয়'];
  // Each question's own myths: they carry the question's key words (and the
  // right cards' echo of them), so a word shared with the question never
  // names the right card. One of them is always dealt with its question.
  static const prepMyths = ['ফোনে লাইন বন্ধ শুনলেই জালে উঠে পড়া যায়', 'গার্ডের জালে কারেন্ট থাকে না, খালি হাতেই চলে'];
  static const inspectMyths = ['পুরো জাল দেখা সময় নষ্ট, চোখে পড়াটুকু সারলেই হয়', 'দু-একটা তার ছিঁড়লেও পুরো জালের কিছু হয় না'];
  static const sagMyths = ['জাল যত টানটান তত ভালো, তাই যত পারি টানি', 'একটু ঝুলে থাকলেও ক্ষতি নেই, টান আন্দাজেই চলে'];
  static const lacingMyths = ['ছেঁড়া লেসিং থাকুক, GI তারে বোনা জাল এমনিতেই শক্ত', 'GI তারে না বেঁধে ছেঁড়া লেসিং দড়িতে বাঁধলেও চলে'];
  static const clampMyths = ['ক্ল্যাম্প একটু ঢিলে থাকলেও চলে, তার তো বাঁধা আছে', 'একটা ঢিলে ক্ল্যাম্পে পুরো গার্ডিং-এর কিছু হয় না'];
  static const earthMyths = ['আর্থ তার পাইপে ভরা বাড়তি ঝামেলা, খোলাই ভালো', 'জালের আর্থ তার না থাকলেও চলে, পাইপে লাভ নেই'];
  static const clearanceMyths = ['একবার দূরত্ব ঠিক ছিল, নামার আগে আর মাপা লাগে না', 'লাইভ তার আর জালের দূরত্ব একটু কম হলেও চলে'];
  static const orderMyths = ['আর্থ পরে খুললেও চলে, তবে আগে লাইন ক্লিয়ার দিই', 'আগে লাইন ক্লিয়ার দিলে তবেই সময় বাঁচে, আর্থ পরে'];

  /// Field excuses that fit any station (the second wrong card's pool, with
  /// the other questions' myths).
  static const generalMyths = ['তাড়াতাড়ি সারলে রাস্তার লোকের কষ্ট কমে', 'রাস্তায় গাড়ি কম, তাই নিয়ম না মানলেও চলে'];

  /// Every wrong reason card.
  static const myths = [
    ...prepMyths,
    ...inspectMyths,
    ...sagMyths,
    ...lacingMyths,
    ...clampMyths,
    ...earthMyths,
    ...clearanceMyths,
    ...orderMyths,
    ...generalMyths,
  ];
  static const allRight = [...prepWhy, ...inspectWhy, ...sagWhy, ...lacingWhy, ...clampWhy, ...earthWhy, ...clearanceWhy, ...orderWhy];

  static List<String> repairMyths(M3GuardFaultKind k) => switch (k) {
        M3GuardFaultKind.sag => sagMyths,
        M3GuardFaultKind.lacing => lacingMyths,
        M3GuardFaultKind.clamp => clampMyths,
        M3GuardFaultKind.earth => earthMyths,
      };
  static List<String> closeMyths(M3GuardCloseWhy w) => switch (w) {
        M3GuardCloseWhy.clearance => clearanceMyths,
        M3GuardCloseWhy.order => orderMyths,
      };

  static List<String> repairWhy(M3GuardFaultKind k) => switch (k) {
        M3GuardFaultKind.sag => sagWhy,
        M3GuardFaultKind.lacing => lacingWhy,
        M3GuardFaultKind.clamp => clampWhy,
        M3GuardFaultKind.earth => earthWhy,
      };
  static List<String> closeWhy(M3GuardCloseWhy w) => switch (w) {
        M3GuardCloseWhy.clearance => clearanceWhy,
        M3GuardCloseWhy.order => orderWhy,
      };

  /// The careless coworker: no shutdown, be quick.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'লাইন বন্ধ করার দরকার নেই, তাড়াতাড়ি সেরে নাও!',
    exitLine: coworkerExit,
    right: ['না, শাটডাউন, PTW, টেস্ট, আর্থ — তবে কাজ', 'না, জাল লাইভ ধরেই চলব, আগে লাইন বন্ধ', 'না, লাইন বন্ধ না করে জালে হাত দেব না'],
    wrong: [
      'ঠিক, চালু লাইনেই সাবধানে সেরে নিই',
      'আচ্ছা, জালে তো কারেন্ট নেই, উঠে পড়ি',
      'হ্যাঁ, পাঁচ মিনিটের কাজ, বন্ধ লাগবে না',
      'ঠিক আছে, গ্লাভস পরে চালুতেই করি',
      'শাটডাউনের ঝামেলা না করেই সেরে নিই',
    ],
    asks: ['ও বলছে লাইন বন্ধ না করেই সারতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'চালু লাইনের নিচে জালে উঠবেন?'],
  );

  static const callHeld = 'ঠিক! জালকে সবসময় লাইভ ধরুন।';
  static const allSet = 'জাল আবার মজবুত — লাইন বন্ধ রেখে, ঠিক টানে, আর্থ পাইপে।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে লাইন নিরাপদ, তারপর জাল।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtSafe = 'শাটডাউন, PTW, টেস্ট, আর্থ — তবে জালে';
  static const caughtTraffic = 'নিচের রাস্তা আগে থামিয়েছেন';
  static const caughtAll = 'জালের সব খুঁত ধরেছেন';
  static const caughtTension = 'ঠিক টানে জাল টানটান';
  static const caughtLacing = 'ছেঁড়া লেসিং নতুন GI তারে';
  static const caughtClamp = 'ঢিলে ক্ল্যাম্প টাইট';
  static const caughtEarth = 'আর্থ তার পাইপের ভেতর দিয়ে';
  static const caughtClearance = 'নামার আগে ক্লিয়ারেন্স দেখেছেন';
  static const caughtClose = 'নেমে, আর্থ খুলে, তবে লাইন ক্লিয়ার';
  static const caughtCall = 'চাপে “না” — আগে শাটডাউন';

  static String caughtFix(M3GuardFaultKind k) => switch (k) {
        M3GuardFaultKind.sag => caughtTension,
        M3GuardFaultKind.lacing => caughtLacing,
        M3GuardFaultKind.clamp => caughtClamp,
        M3GuardFaultKind.earth => caughtEarth,
      };
}

abstract final class M3GuardRepairMistakes {
  static const _dir = 'assets/game/art/m3_guard_repair';

  static const climbLive = DoMistake(
    key: '3.9/m3_guard_repair/climb-live',
    textBn: 'লাইন চালু রেখে জালে উঠলেন! গার্ডিংকে সবসময় লাইভ ধরুন — আগে শাটডাউন, PTW, টেস্টে মৃত প্রমাণ, আর্থ; তবে কাজ।',
    art: '$_dir/climb_live.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const earthLive = DoMistake(
    key: '3.9/m3_guard_repair/earth-live',
    textBn: 'চালু লাইনে আর্থ সেট লাগালেন! আগে শাটডাউন, তারপর টেস্টারে লাইন মৃত প্রমাণ — তবেই আর্থ।',
    art: '$_dir/earth_live.svg',
    deadly: true,
  );
  // The PTW steps are lesson 1.6's, not lesson 3.9's: no lesson point.
  static const ptwEarly = DoMistake(
    key: '3.9/m3_guard_repair/ptw-before-shutdown',
    textBn: 'আগে কন্ট্রোল রুমে শাটডাউন চান — লাইন বন্ধ আর লক-ট্যাগ হলে তবেই PTW ইস্যু হয়।',
    art: '$_dir/permit_steps.svg',
  );
  static const noPtw = DoMistake(
    key: '3.9/m3_guard_repair/no-ptw',
    textBn: 'লাইন বন্ধ হলেই হলো না — হাতে স্বাক্ষরিত PTW ছাড়া কাজ শুরু নয়।',
    art: '$_dir/permit_steps.svg',
  );
  static const noTest = DoMistake(
    key: '3.9/m3_guard_repair/not-tested',
    textBn: 'PTW কাগজ মাত্র — টেস্টারে দেখে নিন লাইন সত্যিই মৃত, তারপর আর্থ, তবে জালে।',
    art: '$_dir/permit_steps.svg',
  );
  static const earthUntested = DoMistake(
    key: '3.9/m3_guard_repair/earth-before-test',
    textBn: 'আর্থ লাগানোর আগে টেস্টারে দেখুন লাইন সত্যিই মৃত — তারপর আর্থ।',
    art: '$_dir/permit_steps.svg',
  );
  static const noEarth = DoMistake(
    key: '3.9/m3_guard_repair/no-earth',
    textBn: 'ওপরের লাইন বন্ধ আর আর্থ করা না থাকলে জালকে লাইভ ধরুন — আগে পোর্টেবল আর্থ, তবে কাজ।',
    art: '$_dir/permit_steps.svg',
    lessonPoint: 3,
  );
  static const noTraffic = DoMistake(
    key: '3.9/m3_guard_repair/traffic-not-held',
    textBn: 'নিচে রাস্তায় গাড়ি চলছে! গার্ডিং মেরামতের সময় আগে নিচের ট্র্যাফিক নিয়ন্ত্রণ করুন।',
    art: '$_dir/traffic.svg',
    lessonPoint: 1,
  );
  // A wrong flag: neutral (it names the four things to look for, never
  // which ones this cradle has).
  static const falseFlag = DoMistake(
    key: '3.9/m3_guard_repair/false-flag',
    textBn: 'আন্দাজে ট্যাগ নয় — আগে খুঁটিয়ে দেখুন: তার ঝুলেছে কি, লেসিং ছিঁড়েছে কি, ক্ল্যাম্প ঢিলে কি, আর্থ তার আছে কি।',
    art: '$_dir/faults.svg',
    lessonPoint: 3,
  );
  static const missedFault = DoMistake(
    key: '3.9/m3_guard_repair/fault-missed',
    textBn: 'একটা খুঁত বাদ গেল। গার্ডিং একসঙ্গে কাজ করে — একটা ছেঁড়া, ঝুলে পড়া বা ঢিলে অংশেই পুরো জাল দুর্বল হয়।',
    art: '$_dir/faults.svg',
    lessonPoint: 3,
  );
  static const wrongFix = DoMistake(
    key: '3.9/m3_guard_repair/wrong-fix',
    textBn: 'এই খুঁতে এটা নয়। ঝুলে পড়া তারে টান, ছেঁড়া লেসিং-এ নতুন GI তার, ঢিলে ক্ল্যাম্পে স্প্যানার, চুরি যাওয়া আর্থে পাইপ আর আর্থ তার।',
    art: '$_dir/faults.svg',
    lessonPoint: 3,
  );
  static const rope = DoMistake(
    key: '3.9/m3_guard_repair/rope-lacing',
    textBn: 'জাল GI তারে বোনা — দড়ি দিয়ে জোড়া নয়। বাইন্ডিং তার বা ক্ল্যাম্প মজবুত হওয়া চাই।',
    art: '$_dir/lacing.svg',
    lessonPoint: 1,
  );
  // Pro tips (not a lesson point): "পাঠে দেখুন" opens the lesson from its start.
  static const overTension = DoMistake(
    key: '3.9/m3_guard_repair/over-tension',
    textBn: 'বেশি টানলেন — অতিরিক্ত টানে গার্ডিং-এর তার ছিঁড়ে যেতে পারে। পেছনের তারের সমান টানে থামুন।',
    art: '$_dir/tension.svg',
  );
  static const underTension = DoMistake(
    key: '3.9/m3_guard_repair/under-tension',
    textBn: 'তার এখনো ঢিলে — ঝুলে থাকলে লাইভ তারের সঙ্গে দূরত্ব কমে যায়। পেছনের তারের সমান টানে থামুন।',
    art: '$_dir/tension.svg',
  );
  static const bareEarth = DoMistake(
    key: '3.9/m3_guard_repair/bare-earth-lead',
    textBn: 'খোলা আর্থ তার আবার চুরি যেতে পারে। আগে পোলে পাইপ, তার ভেতর দিয়ে নতুন আর্থ তার।',
    art: '$_dir/earth_pipe.svg',
  );
  static const noClearance = DoMistake(
    key: '3.9/m3_guard_repair/no-clearance-check',
    textBn: 'নামার আগে লাইভ তার আর জালের উল্লম্ব দূরত্ব দেখে নিন — দূরত্ব কম হলে আর্ক বা শর্ট সার্কিট হতে পারে।',
    art: '$_dir/clearance.svg',
  );
  static const earthOffUp = DoMistake(
    key: '3.9/m3_guard_repair/earth-off-while-up',
    textBn: 'আপনি এখনো জালে! আগে সবাই নেমে আসুন, যন্ত্র সরান — পোর্টেবল আর্থ খোলা সবার শেষে।',
    art: '$_dir/close_order.svg',
  );
  static const clearUp = DoMistake(
    key: '3.9/m3_guard_repair/line-clear-while-up',
    textBn: 'সবাই নেমে না এলে লাইন ক্লিয়ার নয় — আগে সবাইকে গুনে নিন।',
    art: '$_dir/close_order.svg',
  );
  static const clearEarthed = DoMistake(
    key: '3.9/m3_guard_repair/line-clear-earth-on',
    textBn: 'পোর্টেবল আর্থ এখনো লাগানো! সব যন্ত্র সরিয়ে তবে লাইন ক্লিয়ার দিন।',
    art: '$_dir/close_order.svg',
  );

  static const all = [
    climbLive,
    earthLive,
    ptwEarly,
    noPtw,
    noTest,
    earthUntested,
    noEarth,
    noTraffic,
    falseFlag,
    missedFault,
    wrongFix,
    rope,
    overTension,
    underTension,
    bareEarth,
    noClearance,
    earthOffUp,
    clearUp,
    clearEarthed,
  ];
}

/// One play: the faults (the sag always, two of the other three, each in a
/// dealt place), how many pulls bring the slack wire right, the PTW number,
/// which fault the repair reason asks about, what the close one asks, and the
/// order of the three trays (indices into [M3GuardRepairDeal.prepSteps],
/// [M3GuardTool.values] and [M3GuardRepairDeal.closeSteps]; never the job's
/// own order).
@immutable
class M3GuardRepairDeal {
  const M3GuardRepairDeal({
    required this.faults,
    required this.need,
    required this.permit,
    required this.repairAsk,
    required this.closeAsk,
    this.prepOrder = const [1, 3, 0, 5, 2, 4],
    this.toolOrder = const [2, 4, 1, 5, 0, 3],
    this.closeOrder = const [1, 3, 0, 2],
  });
  final List<M3GuardFault> faults;
  final int need;
  final int permit;
  final M3GuardFaultKind repairAsk;
  final M3GuardCloseWhy closeAsk;
  final List<int> prepOrder;
  final List<int> toolOrder;
  final List<int> closeOrder;

  /// The prep steps in the job's order (the tray shows them shuffled).
  static const prepSteps = [
    M3GuardRepairLines.shutdown,
    M3GuardRepairLines.ptw,
    M3GuardRepairLines.tester,
    M3GuardRepairLines.earthSet,
    M3GuardRepairLines.traffic,
    M3GuardRepairLines.climb,
  ];

  /// The close steps in the job's order (the tray shows them shuffled).
  static const closeSteps = [
    M3GuardRepairLines.measure,
    M3GuardRepairLines.comeDown,
    M3GuardRepairLines.earthOff,
    M3GuardRepairLines.lineClear,
  ];
}

/// A tray order that does not spell out the job: no step in its own place, no
/// two neighbours in the job's order (k then k + 1), and not the job reversed.
bool m3GuardTrayOrderOk(List<int> o) {
  final n = o.length;
  for (var i = 0; i < n; i++) {
    if (o[i] == i) return false;
    if (i + 1 < n && o[i + 1] == o[i] + 1) return false;
  }
  return ![for (var i = 0; i < n; i++) o[i] == n - 1 - i].every((x) => x);
}

/// 0..n-1 shuffled into an order [m3GuardTrayOrderOk] accepts.
List<int> _shuffledOrder(int n, math.Random rng) {
  final o = List<int>.generate(n, (i) => i);
  do {
    o.shuffle(rng);
  } while (!m3GuardTrayOrderOk(o));
  return o;
}

/// The reason cards for a station: its right card, one of its own myths (the
/// one that carries the question's words) and one more from the rest.
List<ChoiceOption> m3GuardDealWhy(List<String> right, List<String> own, math.Random rng) {
  final mine = own[rng.nextInt(own.length)];
  final rest = [
    for (final m in M3GuardRepairLines.myths)
      if (!own.contains(m)) m,
  ];
  return dealChoices(right, [mine, rest[rng.nextInt(rest.length)]], rng);
}

M3GuardRepairDeal m3GuardRepairDeal(math.Random rng) {
  final sagSide = rng.nextInt(2);
  final others = [M3GuardFaultKind.lacing, M3GuardFaultKind.clamp, M3GuardFaultKind.earth]..shuffle(rng);
  final faults = <M3GuardFault>[
    M3GuardFault(M3GuardFaultKind.sag, side: sagSide),
    for (final k in others.take(2))
      switch (k) {
        // A snapped lacing in the other half (clear of the sag).
        M3GuardFaultKind.lacing => M3GuardFault(k, lacing: (sagSide == 0 ? 3 : 0) + rng.nextInt(3)),
        _ => M3GuardFault(k, side: rng.nextInt(2)),
      },
  ]..shuffle(rng);
  final kinds = [for (final f in faults) f.kind];
  return M3GuardRepairDeal(
    faults: faults,
    need: 3 + rng.nextInt(3),
    permit: 1000 + rng.nextInt(9000),
    repairAsk: kinds[rng.nextInt(kinds.length)],
    closeAsk: M3GuardCloseWhy.values[rng.nextInt(2)],
    prepOrder: _shuffledOrder(M3GuardRepairDeal.prepSteps.length, rng),
    toolOrder: _shuffledOrder(M3GuardTool.values.length, rng),
    closeOrder: _shuffledOrder(M3GuardRepairDeal.closeSteps.length, rng),
  );
}

/// The play state (pure logic).
class M3GuardRepairRun {
  M3GuardRepairRun(this.deal);
  final M3GuardRepairDeal deal;

  M3GuardStation station = M3GuardStation.prep;
  int slips = 0;
  int stationSlips = 0;
  DoMistake? deadly;
  var finished = false;
  final List<String> caught = [];

  // prep
  var shutdown = false;
  var ptw = false;
  var proved = false;
  var earthed = false;
  var traffic = false;
  var up = false;

  // inspect + repair
  final Set<int> tagged = {};
  final Set<int> fixed = {};
  final Set<int> pipeOn = {};
  M3GuardTool? tool;
  var tensioning = false;
  int strokes = 0;

  // close
  var measured = false;
  var down = false;
  var earthOff = false;

  bool get ended => deadly != null || finished;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => finished && deadly == null && percent >= 55;
  bool get clean => stationSlips == 0;
  List<M3GuardFault> get faults => deal.faults;
  bool get allTagged => tagged.length == faults.length;
  bool get allFixed => fixed.length == faults.length;

  /// The slack wire's tension now (0 → 1; past 1 = too tight).
  double get tension {
    final i = faults.indexWhere((f) => f.kind == M3GuardFaultKind.sag);
    if (fixed.contains(i)) return 1;
    return strokes / deal.need;
  }

  /// The portable earth is on the conductors.
  bool get earthSetOn => earthed && !earthOff;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stationSlips++;
    return m;
  }

  bool _at(M3GuardStation s) => !ended && station == s;

  // --- ক prep -----------------------------------------------------------------
  /// Asks the control room for the shutdown (breaker OFF, lock and tag there).
  void callShutdown() {
    if (_at(M3GuardStation.prep)) shutdown = true;
  }

  DoMistake? takePtw() {
    if (!_at(M3GuardStation.prep) || ptw) return null;
    if (!shutdown) return _slip(M3GuardRepairMistakes.ptwEarly);
    ptw = true;
    return null;
  }

  /// The tester on the line: true = live.
  bool test() {
    if (_at(M3GuardStation.prep) && shutdown) proved = true;
    return !shutdown;
  }

  DoMistake? putEarth() {
    if (!_at(M3GuardStation.prep) || earthed) return null;
    if (!shutdown) return deadly = M3GuardRepairMistakes.earthLive;
    if (!proved) return _slip(M3GuardRepairMistakes.earthUntested);
    earthed = true;
    return null;
  }

  void holdTraffic() {
    if (_at(M3GuardStation.prep)) traffic = true;
  }

  /// Up the pole to the cradle. Null and [up] = the prep is done.
  DoMistake? climbUp() {
    if (!_at(M3GuardStation.prep) || up) return null;
    if (!shutdown) return deadly = M3GuardRepairMistakes.climbLive;
    if (!ptw) return _slip(M3GuardRepairMistakes.noPtw);
    if (!proved) return _slip(M3GuardRepairMistakes.noTest);
    if (!earthed) return _slip(M3GuardRepairMistakes.noEarth);
    if (!traffic) return _slip(M3GuardRepairMistakes.noTraffic);
    up = true;
    _tag(M3GuardRepairLines.caughtSafe);
    _tag(M3GuardRepairLines.caughtTraffic);
    return null;
  }

  /// Listened to the coworker: up on the live cradle.
  void failDeadly(DoMistake m) {
    if (!ended) deadly = m;
  }

  // --- খ inspect ----------------------------------------------------------------
  /// Tags fault [i]; true = newly tagged.
  bool tagFault(int i) {
    if (!_at(M3GuardStation.inspect) || i < 0 || i >= faults.length) return false;
    return tagged.add(i);
  }

  /// A tag on a sound part of the cradle: a wrong flag costs a slip (tapping
  /// everywhere must not find the faults for free).
  DoMistake? flagSound() {
    if (!_at(M3GuardStation.inspect)) return null;
    return _slip(M3GuardRepairMistakes.falseFlag);
  }

  /// "দেখা শেষ": a fault left untagged is a slip (and it is tagged now, so
  /// the player sees it); null = all found.
  DoMistake? doneLooking() {
    if (!_at(M3GuardStation.inspect)) return null;
    if (!allTagged) {
      for (var i = 0; i < faults.length; i++) {
        tagged.add(i);
      }
      return _slip(M3GuardRepairMistakes.missedFault);
    }
    _tag(M3GuardRepairLines.caughtAll);
    return null;
  }

  // --- গ repair -------------------------------------------------------------------
  void hold(M3GuardTool t) {
    if (!_at(M3GuardStation.repair) || tensioning) return;
    tool = tool == t ? null : t;
  }

  /// The tool in hand on fault [i]. Null = done (or nothing happened).
  DoMistake? apply(int i) {
    if (!_at(M3GuardStation.repair) || tensioning || i < 0 || i >= faults.length || fixed.contains(i)) return null;
    final t = tool;
    if (t == null) return null;
    final f = faults[i];
    DoMistake? fail(DoMistake m) {
      tool = null;
      return _slip(m);
    }

    switch (f.kind) {
      case M3GuardFaultKind.sag:
        if (t != M3GuardTool.tension) return fail(M3GuardRepairMistakes.wrongFix);
        tensioning = true;
        tool = null;
        return null;
      case M3GuardFaultKind.lacing:
        if (t == M3GuardTool.rope) return fail(M3GuardRepairMistakes.rope);
        if (t != M3GuardTool.gi) return fail(M3GuardRepairMistakes.wrongFix);
      case M3GuardFaultKind.clamp:
        if (t != M3GuardTool.spanner) return fail(M3GuardRepairMistakes.wrongFix);
      case M3GuardFaultKind.earth:
        if (t == M3GuardTool.pipe) {
          pipeOn.add(f.side);
          tool = null;
          return null;
        }
        if (t != M3GuardTool.earthLead) return fail(M3GuardRepairMistakes.wrongFix);
        if (!pipeOn.contains(f.side)) return fail(M3GuardRepairMistakes.bareEarth);
    }
    _fix(i);
    return null;
  }

  void _fix(int i) {
    fixed.add(i);
    tool = null;
    _tag(M3GuardRepairLines.caughtFix(faults[i].kind));
  }

  /// One pull on the slack wire; past the right tension: a slip, and it is let back.
  DoMistake? pullOnce() {
    if (!_at(M3GuardStation.repair) || !tensioning) return null;
    strokes++;
    if (strokes > deal.need) {
      strokes = deal.need;
      return _slip(M3GuardRepairMistakes.overTension);
    }
    return null;
  }

  /// "টান ঠিক": while it still sags = a slip (stopping short; the wire stays
  /// in hand to pull on); at the right tension = fixed (null).
  DoMistake? tensionDone() {
    if (!_at(M3GuardStation.repair) || !tensioning) return null;
    if (strokes < deal.need) return _slip(M3GuardRepairMistakes.underTension);
    tensioning = false;
    _fix(faults.indexWhere((f) => f.kind == M3GuardFaultKind.sag));
    return null;
  }

  // --- ঘ close ----------------------------------------------------------------------
  void measure() {
    if (_at(M3GuardStation.close) && !down) {
      measured = true;
      _tag(M3GuardRepairLines.caughtClearance);
    }
  }

  DoMistake? comeDown() {
    if (!_at(M3GuardStation.close) || down) return null;
    if (!measured) return _slip(M3GuardRepairMistakes.noClearance);
    down = true;
    return null;
  }

  DoMistake? takeEarthOff() {
    if (!_at(M3GuardStation.close) || earthOff) return null;
    if (!down) return _slip(M3GuardRepairMistakes.earthOffUp);
    earthOff = true;
    return null;
  }

  /// The permit back. Null and [finished] = the play is done.
  DoMistake? giveLineClear() {
    if (!_at(M3GuardStation.close)) return null;
    if (!down) return _slip(M3GuardRepairMistakes.clearUp);
    if (!earthOff) return _slip(M3GuardRepairMistakes.clearEarthed);
    _tag(M3GuardRepairLines.caughtClose);
    return null;
  }

  /// The station's work is done (the reason comes next).
  bool get stationDone => switch (station) {
        M3GuardStation.prep => up,
        M3GuardStation.inspect => false,
        M3GuardStation.repair => allFixed,
        M3GuardStation.close => down && earthOff && caught.contains(M3GuardRepairLines.caughtClose),
      };

  void next() {
    stationSlips = 0;
    switch (station) {
      case M3GuardStation.prep:
        station = M3GuardStation.inspect;
      case M3GuardStation.inspect:
        station = M3GuardStation.repair;
      case M3GuardStation.repair:
        station = M3GuardStation.close;
      case M3GuardStation.close:
        finished = true;
    }
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded).
///   prep: 6 taps ~9000 + the tester 2200 + the coworker ~9600
///     + reason ~8200                                               29000
///   inspect: 3 taps + done ~6000 + reason ~8200                    14200
///   repair: 3 faults × tool + tap ~3000, the pipe ~3000,
///     ~4 pulls + done ~6000, reason ~8200                          26200
///   close: 4 taps ~6000 + reason ~8200                             14200
///   ≈ 83600 ms; 85 % ≈ 71000 → 70 s.
const kM3GuardRepairQuickMs = 70000;

@immutable
class M3GuardRepairPack {
  const M3GuardRepairPack({required this.id, required this.titleBn, this.quickMs = kM3GuardRepairQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M3GuardRepairPack> m3GuardRepairPacks = {
  'do_3_9_b': M3GuardRepairPack(id: 'do_3_9_b', titleBn: M3GuardRepairLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M3GuardRepairPage extends StatefulWidget {
  const M3GuardRepairPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final M3GuardRepairPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3GuardRepairPage> createState() => _M3GuardRepairPageState();
}

class _M3GuardRepairPageState extends State<M3GuardRepairPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _GuardRunPage(
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

class _GuardRunPage extends ConsumerStatefulWidget {
  const _GuardRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3GuardRepairPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_GuardRunPage> createState() => _GuardRunPageState();
}

class _GuardRunPageState extends ConsumerState<_GuardRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3GuardRepairRun _run = M3GuardRepairRun(m3GuardRepairDeal(widget.rng));
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
  var _stationPaid = false;

  /// The shutdown is asked for; it goes through once he is answered.
  var _calling = false;

  /// The tester's lamp, a moment after it touches the line.
  bool? _tester;
  Timer? _testerTimer;

  var _freeze = false;
  Offset _arcAt = Offset.zero;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hint (how to tap, never what) and the keys it sweeps over.
  final _hints = IdleHintController();
  final Map<String, GlobalKey> _keys = {};
  GlobalKey _key(String id) => _keys.putIfAbsent(id, GlobalKey.new);

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

  String get _task => switch (_run.station) {
        M3GuardStation.prep => M3GuardRepairLines.askPrep,
        M3GuardStation.inspect => M3GuardRepairLines.askInspect,
        M3GuardStation.repair => _run.tensioning ? M3GuardRepairLines.askTension : M3GuardRepairLines.askRepair,
        M3GuardStation.close => M3GuardRepairLines.askClose,
      };

  void _start() {
    _clock.start();
    unawaited(_sayChain([_task]));
  }

  /// Scene controls are live: no intro, card, deck, coworker, freeze, and not
  /// in a right move's praise window ([tableBusy]).
  bool get _canPlay => !_intro && !_ended && _card == null && !tableBusy && !reasonOpen && !coworkerOpen && !struckOut && !_freeze && !_stationPaid;

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  void _placed() {
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
  }

  // --- ক prep --------------------------------------------------------------------
  void _prep(String what, Offset global) {
    if (!_canPlay || _run.station != M3GuardStation.prep) return;
    // The shutdown is asked for and he is on his way: the next step waits
    // for him (a fast player cannot run past him).
    if (what != M3GuardRepairLines.shutdown && holdForCoworker()) return;
    DoMistake? m;
    switch (what) {
      case M3GuardRepairLines.shutdown:
        if (_run.shutdown || _calling) return;
        _tick('sounds/intro/click.ogg', 0.6);
        if (coworkerDone) {
          _run.callShutdown();
        } else {
          // The call to the control room: he walks in before it goes through.
          _calling = true;
          scheduleCoworker();
        }
      case M3GuardRepairLines.ptw:
        m = _run.takePtw();
        if (m == null) _placed();
      case M3GuardRepairLines.tester:
        _useTester();
        return;
      case M3GuardRepairLines.earthSet:
        m = _run.putEarth();
        if (m == null) _placed();
        if (m != null && m.deadly) _arcAt = _geo.testAt;
      case M3GuardRepairLines.traffic:
        _run.holdTraffic();
        _placed();
      case M3GuardRepairLines.climb:
        _tick('sounds/intro/click.ogg', 0.5);
        m = _run.climbUp();
        if (m != null && m.deadly) _arcAt = _geo.anchor(const M3GuardFault(M3GuardFaultKind.clamp));
    }
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
    } else if (_run.up) {
      _stationRight(global);
    }
  }

  late M3GuardGeo _geo = M3GuardGeo.forScene(700, 0);

  void _useTester() {
    _tick('sounds/intro/click.ogg', 0.5);
    final live = _run.test();
    _testerTimer?.cancel();
    setState(() {
      _tester = live;
      _wake++;
    });
    _testerTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _tester = null);
    });
  }

  // --- খ / গ: taps on the cradle -------------------------------------------------------
  int? _faultAt(Offset p) {
    int? best;
    var bestD = double.infinity;
    for (final (i, f) in _run.faults.indexed) {
      final r = _geo.hit(f, t: _run.tension);
      if (!r.contains(p)) continue;
      final d = (r.center - p).distanceSquared;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  /// A sound part of the cradle under [p]: a place where a fault could be,
  /// but none was dealt. Forgiving: a tap within [_nearFault] of a dealt
  /// fault's area is a near miss, never a wrong flag; the slack half is all
  /// the sag's (its lacings are not checked there — the wire droops through
  /// them); and the sound half's wire is not a "sag" spot (that would blanket
  /// its lacings, where the snapped one is dealt).
  bool _soundAt(Offset p) {
    if (_run.faults.any((f) => _geo.hit(f, t: _run.tension).inflate(_nearFault).contains(p))) return false;
    final slackSides = {
      for (final f in _run.faults)
        if (f.kind == M3GuardFaultKind.sag) f.side,
    };
    for (final s in M3GuardGeo.spots) {
      if (_run.faults.contains(s)) continue;
      if (s.kind == M3GuardFaultKind.sag) continue;
      if (s.kind == M3GuardFaultKind.lacing && slackSides.contains(M3GuardGeo.lacingSide(s.lacing))) continue;
      if (_geo.hit(s, t: 1).deflate(4).contains(p)) return true;
    }
    return false;
  }

  /// How far beside a dealt fault a tap is still a near miss (design px).
  static const _nearFault = 16.0;

  void _tapScene(Offset p, Offset global) {
    if (!_canPlay) return;
    final i = _faultAt(p);
    switch (_run.station) {
      case M3GuardStation.inspect:
        if (i != null) {
          if (_run.tagFault(i)) {
            _placed();
            setState(() => _wake++);
          } else {
            _tick('sounds/intro/tick.ogg', 0.3);
          }
        } else if (_soundAt(p)) {
          // A tag on a sound part: a wrong flag costs (no free sweep-tapping).
          final m = _run.flagSound();
          setState(() => _wake++);
          if (m != null) unawaited(_mistake(m, global));
        } else {
          _hints.missTap();
          _tick('sounds/intro/tick.ogg', 0.3);
        }
      case M3GuardStation.repair:
        if (i == null || _run.tool == null) {
          _hints.missTap();
          _tick('sounds/intro/tick.ogg', 0.3);
          return;
        }
        final before = (_run.fixed.length, _run.pipeOn.length);
        final m = _run.apply(i);
        setState(() => _wake++);
        if (m == null && !_run.tensioning && before == (_run.fixed.length, _run.pipeOn.length)) {
          _tick('sounds/intro/tick.ogg', 0.3);
          return;
        }
        if (m != null) {
          unawaited(_mistake(m, global));
          return;
        }
        if (_run.tensioning) {
          _tick('sounds/intro/click.ogg', 0.6);
          unawaited(_sayChain([M3GuardRepairLines.askTension]));
          return;
        }
        _placed();
        if (_run.allFixed) _stationRight(global);
      case M3GuardStation.prep:
      case M3GuardStation.close:
        _hints.missTap();
        _tick('sounds/intro/tick.ogg', 0.3);
    }
  }

  Future<void> _doneLooking(Offset global) async {
    if (!_canPlay || _run.station != M3GuardStation.inspect) return;
    final m = _run.doneLooking();
    setState(() => _wake++);
    if (m != null) {
      await _mistake(m, global);
      return;
    }
    _stationRight(global);
  }

  void _hold(M3GuardTool t) {
    if (!_canPlay || _run.station != M3GuardStation.repair) return;
    _tick('sounds/quiz_select.ogg');
    setState(() {
      _run.hold(t);
      _wake++;
    });
  }

  void _pull(Offset global) {
    if (!_canPlay || !_run.tensioning) return;
    final m = _run.pullOnce();
    HapticFeedback.lightImpact();
    _cue('sounds/intro/click.ogg', volume: 0.8);
    setState(() => _wake++);
    if (m != null) unawaited(_mistake(m, global));
  }

  void _tensionDone(Offset global) {
    if (!_canPlay || !_run.tensioning) return;
    final m = _run.tensionDone();
    setState(() => _wake++);
    if (m != null) {
      // Stopped while it still sags: a slip (no free pull-and-check probing).
      unawaited(_mistake(m, global));
      return;
    }
    _placed();
    if (_run.allFixed) {
      _stationRight(global);
    } else {
      unawaited(_sayChain([M3GuardRepairLines.askRepair]));
    }
  }

  // --- ঘ close --------------------------------------------------------------------
  void _close(String what, Offset global) {
    if (!_canPlay || _run.station != M3GuardStation.close) return;
    DoMistake? m;
    switch (what) {
      case M3GuardRepairLines.measure:
        _run.measure();
        _tick('sounds/intro/click.ogg', 0.6);
      case M3GuardRepairLines.comeDown:
        m = _run.comeDown();
        if (m == null) _placed();
      case M3GuardRepairLines.earthOff:
        m = _run.takeEarthOff();
        if (m == null) _placed();
      case M3GuardRepairLines.lineClear:
        m = _run.giveLineClear();
    }
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
    } else if (_run.stationDone) {
      _stationRight(global);
    }
  }

  // --- a station done right: the ◆ and the reason ---------------------------------
  void _stationRight(Offset origin) {
    _hush();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    final station = _run.station;
    setState(() => _stationPaid = true);
    putOnTable(15 + (_run.clean ? 5 : 0));
    final d = _run.deal;
    final (List<String> right, List<String> own, String q) = switch (station) {
      M3GuardStation.prep => (M3GuardRepairLines.prepWhy, M3GuardRepairLines.prepMyths, M3GuardRepairLines.whyPrepQ),
      M3GuardStation.inspect => (M3GuardRepairLines.inspectWhy, M3GuardRepairLines.inspectMyths, M3GuardRepairLines.whyInspectQ),
      M3GuardStation.repair => (
          M3GuardRepairLines.repairWhy(d.repairAsk),
          M3GuardRepairLines.repairMyths(d.repairAsk),
          M3GuardRepairLines.whyRepairQ(d.repairAsk),
        ),
      M3GuardStation.close => (
          M3GuardRepairLines.closeWhy(d.closeAsk),
          M3GuardRepairLines.closeMyths(d.closeAsk),
          M3GuardRepairLines.whyCloseQ(d.closeAsk),
        ),
    };
    unawaited(askReason(
      deal: () => m3GuardDealWhy(right, own, widget.rng),
      question: q,
      stillValid: () => _run.station == station && !_ended,
    ));
  }

  void _nextStation() {
    final last = _run.station == M3GuardStation.close;
    _run.next();
    if (last) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _stationPaid = false;
      _wake++;
    });
    unawaited(_sayChain([_task]));
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
    final st = _run.station;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (mounted && !_ended && _run.station == st) _nextStation();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M3GuardRepairLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // His push ("no need to switch off") only fits while the shutdown call is
    // pending; once it went through, the moment has passed.
    if (_ended || _run.station != M3GuardStation.prep || _run.shutdown || _stationPaid || !_calling) return null;
    if (_intro || _card != null || tableBusy || reasonOpen || _tester != null || struckOut) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: up on the cradle under the live line.
      _run.failDeadly(M3GuardRepairMistakes.climbLive);
      _arcAt = _geo.anchor(const M3GuardFault(M3GuardFaultKind.clamp));
      await _deadly(M3GuardRepairMistakes.climbLive);
      return;
    }
    _calling = false;
    _run.callShutdown();
    setState(() => _wake++);
    _placed();
    _run.caught.add(M3GuardRepairLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M3GuardRepairLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3GuardRepairLines.tapWhy[_nudgeN++ % M3GuardRepairLines.tapWhy.length]
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
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('guard/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Live metal: the crossing freezes grey and the flash comes off the line
  /// in colour; then near-miss or death.
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
      _tester = null;
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
    final speak = await SpokenOnce.first('guard/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M3GuardRepairLines.deadlyWord : M3GuardRepairLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same station goes on from where it was.
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
    setState(() => _wake++);
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
    await _say(!_run.passed ? M3GuardRepairLines.fail : (_quickBonus ? M3GuardRepairLines.quick : M3GuardRepairLines.allSet),
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
    if (_mark != null && _passed) return LinemanMode.cheer;
    if (_run.up && !_run.down) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M3GuardState get _state => M3GuardState(
        faults: _run.faults,
        tagged: {..._run.tagged},
        fixed: {..._run.fixed},
        tension: _run.tension,
        pipeOn: {..._run.pipeOn},
        earthSet: _run.earthSetOn,
        traffic: _run.traffic,
        measured: _run.measured && !_run.down,
        seed: _run.deal.permit,
      );

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = M3GuardGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    // Up on the cradle (also the moment he climbed it live).
    final upNow = (_run.up && !_run.down) || _run.deadly == M3GuardRepairMistakes.climbLive;
    final tb = upNow ? geo.traineeUp() : geo.traineeGround();
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('crossing'),
                child: RepaintBoundary(child: CustomPaint(painter: M3GuardWorldPainter(geo: geo, s: _state))),
              ),
              if (upNow)
                Positioned.fill(
                  key: const ValueKey('strap'),
                  child: IgnorePointer(child: CustomPaint(painter: M3GuardStrapPainter(box: tb))),
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
      // The tester's lamp by the line at the left pole.
      if (_tester != null && !_freeze)
        Positioned(
          key: const ValueKey('tester'),
          left: geo.testAt.dx + 10,
          top: geo.testAt.dy + 8,
          child: IgnorePointer(child: _TesterChip(live: _tester!, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M3GuardRepairLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, d.globalPosition)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M3GuardArcPainter(at: _arcAt, v: v)),
            ),
          ),
        ),
    ];
  }

  Widget _tray(List<Widget> children) => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: children);

  // The trays come in the play's dealt order (never the job's order).
  List<String> get _prepShown => [for (final i in _run.deal.prepOrder) M3GuardRepairDeal.prepSteps[i]];
  List<M3GuardTool> get _toolsShown => [for (final i in _run.deal.toolOrder) M3GuardTool.values[i]];
  List<String> get _closeShown => [for (final i in _run.deal.closeOrder) M3GuardRepairDeal.closeSteps[i]];

  Widget _prepTray() {
    final r = _run;
    (IconData, bool) look(String label) => switch (label) {
          M3GuardRepairLines.shutdown => (Icons.phone_in_talk_rounded, r.shutdown || _calling),
          M3GuardRepairLines.ptw => (Icons.description_rounded, r.ptw),
          M3GuardRepairLines.tester => (Icons.flash_on_rounded, _tester != null),
          M3GuardRepairLines.earthSet => (Icons.link_rounded, r.earthed),
          M3GuardRepairLines.traffic => (Icons.traffic_rounded, r.traffic),
          _ => (Icons.north_rounded, r.up),
        };
    return _tray([
      for (final label in _prepShown)
        _ToolButton(key: _key('prep:$label'), icon: look(label).$1, label: label, on: look(label).$2, onTapUp: (d) => _prep(label, d.globalPosition)),
    ]);
  }

  Widget _repairTray() {
    IconData icon(M3GuardTool t) => switch (t) {
          M3GuardTool.tension => Icons.unfold_less_rounded,
          M3GuardTool.gi => Icons.cable_rounded,
          M3GuardTool.spanner => Icons.build_rounded,
          M3GuardTool.pipe => Icons.view_column_rounded,
          M3GuardTool.earthLead => Icons.electrical_services_rounded,
          M3GuardTool.rope => Icons.gesture_rounded,
        };
    return _tray([
      for (final t in _toolsShown)
        _ToolButton(key: _key('tool:${t.name}'), icon: icon(t), label: M3GuardRepairLines.toolBn(t), on: _run.tool == t, onTapUp: (_) => _hold(t)),
    ]);
  }

  Widget _closeTray() {
    final r = _run;
    (IconData, bool) look(String label) => switch (label) {
          M3GuardRepairLines.measure => (Icons.straighten_rounded, r.measured),
          M3GuardRepairLines.comeDown => (Icons.south_rounded, r.down),
          M3GuardRepairLines.earthOff => (Icons.link_off_rounded, r.earthOff),
          _ => (Icons.call_rounded, false),
        };
    return _tray([
      for (final label in _closeShown)
        _ToolButton(key: _key('close:$label'), icon: look(label).$1, label: label, on: look(label).$2, onTapUp: (d) => _close(label, d.globalPosition)),
    ]);
  }

  /// The gesture hint for now: how to interact, never the answer — a sweep
  /// over the whole tray (in its on-screen order) or along the whole cradle.
  HintSpec? _hint() {
    final cradle = HintSpec.sweep(_geo.cradleSweep, space: HintSpace.scene);
    return switch (_run.station) {
      M3GuardStation.prep => HintSpec.sweepOver([for (final l in _prepShown) _key('prep:$l')]),
      M3GuardStation.inspect => cradle,
      M3GuardStation.repair => _run.tensioning
          ? HintSpec.sweepOver([_key('pull'), _key('tension-ok')])
          : _run.tool == null
              ? HintSpec.sweepOver([for (final t in _toolsShown) _key('tool:${t.name}')])
              : cradle,
      M3GuardStation.close => HintSpec.sweepOver([for (final l in _closeShown) _key('close:$l')]),
    };
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final st = _run.station;
    final handsOn = playing && !deckUp && _card == null && !_stationPaid && !_run.finished;
    final Widget? hud = !handsOn
        ? null
        : switch (st) {
            M3GuardStation.prep => _prepTray(),
            M3GuardStation.inspect => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DoBigButton(label: M3GuardRepairLines.doneLooking, filled: true, onTapUp: (d) => unawaited(_doneLooking(d.globalPosition))),
              ),
            M3GuardStation.repair => _run.tensioning
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(child: DoBigButton(key: _key('pull'), label: M3GuardRepairLines.pull, filled: true, onTapUp: (d) => _pull(d.globalPosition))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: DoBigButton(
                                key: _key('tension-ok'), label: M3GuardRepairLines.tensionOk, filled: false, onDark: true, onTapUp: (d) => _tensionDone(d.globalPosition))),
                      ],
                    ),
                  )
                : _repairTray(),
            M3GuardStation.close => _closeTray(),
          };
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
              labels: M3GuardRepairLines.rounds,
              done: {for (var i = 0; i < st.index; i++) i, if (_run.finished) 3},
              current: _run.finished ? null : st.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !coworkerOnScreen && !tableBusy,
            hintKey: '${st.name}-${_run.tensioning}-${_run.tool?.name}',
            hintController: _hints,
            overlays: [
              if (playing && !coworkerOpen)
                Positioned(
                  key: const ValueKey('docket'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(permit: _run.ptw ? _run.deal.permit : null)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (hud case final h?)
                Positioned(
                  key: ValueKey('hud-${st.name}-${_run.tensioning}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 10,
                  child: h,
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${st.name}-$strikes'),
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
                  line: M3GuardRepairLines.intro,
                  alarm: 'sounds/learn/rush_in.ogg',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    _start();
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

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.permit});
  final int? permit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8A7A55), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(M3GuardRepairLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(M3GuardRepairLines.job, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
          if (permit != null)
            Text(M3GuardRepairLines.permitNo(permit!), style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1E6B3A))),
        ],
      ),
    );
  }
}

class _TesterChip extends StatelessWidget {
  const _TesterChip({required this.live, required this.quiet});
  final bool live;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: 0.7 + 0.3 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xEE101A2B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: live ? SlmColors.danger : const Color(0xFF6E7C90), width: 1.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: live ? const Color(0xFFFF5A3D) : const Color(0xFF3A3F45),
                boxShadow: live ? const [BoxShadow(color: Color(0xAAFF5A3D), blurRadius: 8, spreadRadius: 1)] : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(live ? M3GuardRepairLines.testerLive : M3GuardRepairLines.testerDead, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// A hands-on tool or step: a round icon with its name under it; lit while
/// in hand or once done.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTapUp});
  final IconData icon;
  final String label;
  final bool on;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTapUp,
        child: SizedBox(
          width: 58,
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
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
