import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
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
import 'm6_meter_swap_proof_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_meter_swap_proof_world.dart'
    show M6SwapDecoy, M6SwapGeo, M6SwapLookPainter, M6SwapMeter, M6SwapPoint, M6SwapScreen, M6SwapSeal, M6SwapShot, M6SwapSpot, M6SwapThing;

// Lesson 6.10 "এনার্জি মিটার: ক্যাশ রেজিস্টার", কাজ 2 "মিটার বদল, ছবিতে
// প্রমাণ" (pack do_6_10_b, rung 6.10/do/1, engineType m6_meter_swap_proof).
// Three meter changes on a lane of house walls (docket 'মিটার বদল'), dealt
// fresh; 1–2 of the three meters are tampered:
//
//  Look before touching: hold a finger on a seal to tug it (an intact seal
//    stays tight; a cut one swings loose — they look alike until tugged);
//    press the electronic meter's push-button to scroll its screens (kWh,
//    kW, V, A — and 'Tamper' or 'Error' on a tampered one, only when
//    scrolled); tap a dark thing on, beside or under the box, or the service
//    cable before the cut-out, for a close look (a magnet among harmless
//    clips, nests and grommets; a bypass tap joint or a plain cable). Then
//    'মিটার বদল শুরু' or 'অফিসে রিপোর্ট' (two-step preview).
//  A tampered meter: 'অফিসে রিপোর্ট' → the action deck (1 right + 2 dealt
//    wrongs that fit its sign): report and keep away (right) / pull the
//    bypass wire by hand (DEADLY) / take the magnet off and change it, reseal
//    it yourself, change it anyway, scold and walk off (slips) → ◆ → reason →
//    the next wall. 'মিটার বদল শুরু' on a tampered meter = slip; a report on
//    a clean meter = slip (R32).
//  A clean meter — the proof (the core): the phone is auto-framed on the
//    meter's face (one tap, no viewfinder: framing stays do_6_1_a's); the
//    photo shows exactly the screen on the meter then. The electronic meter
//    goes blank once the cut-out is out, so snap first (pulling first costs
//    only time: the carrier goes back, snap, out again). Isolate (live lesson
//    6.10 pro tip 2, ruling X5): drag the cut-out's carrier out, prove the
//    tester on the line contact (a known live point), 0 V on the load
//    contact, the tester again on the line; then the screwdriver on the box
//    (the swap is a cutaway, unscored). The carrier back in, the new LCD
//    wakes on a dealt screen; scroll to kWh, snap; 'জব কার্ড' shows both
//    photos: a missing photo or one that is not the kWh reading = slip.
//
// Deadly (module 6 table R30, R31 by X5 — owner confirmed after Wave A): a
// bypass wire pulled by hand (the action deck); the box opened for the swap
// with the cut-out still in (the supply on). Slips: the cut-out out but no
// 0 V (N4), a 0 V on a tester not proved first (N9), not proved again after
// the 0 V (N4), a change started on a tampered meter, a clean meter reported
// (R32), the magnet taken off / a reseal / no report (deck), a missing or
// non-kWh photo, and listening to the coworker (both his pushes are slips,
// ruling X2/B1). Three slips strike out.
//
// The coworker, once a play: on a magnet job at 'অফিসে রিপোর্ট' (the report
// waits for him), or on a clean job as the phone comes up for the old
// reading (the phone waits for him; so does the box, for a player who skips
// the photo).
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_meter_swap_proof_world.dart), corner guide, ReasonTable (the
// "কেন?" cards at once), CoworkerMoment, gesture hands for every waiting
// state (how, never what), MistakeCard, FreezeFrame + DoDeathGuard,
// DoStrikeOut, the pass panel with stars. Idle = zero frames.

// ============================================================================
// Content
// ============================================================================

/// The sign a tampered meter carries (lesson 6.10 point 4), one a meter.
enum M6SwapSign { none, seal, bypass, magnet, screen }

/// Where a wall's job is.
enum M6SwapStage { look, act, swap, closed }

/// The coworker's push (one a play).
enum M6SwapPush { magnet, photo }

/// What a reason asks about.
enum M6SwapWhy { oldPhoto, snapFirst, isolate, reportSeal, reportMagnet, reportScreen, bypass }

/// The action deck after a report on a tampered meter.
enum M6SwapAct { report, pullBypass, removeMagnet, reseal, startAnyway, noReport }

/// The tool row on a clean job: the phone (a tap snaps), the tester and the
/// screwdriver (taken in hand), the job card (after the swap).
enum M6SwapTool { phone, tester, driver, card }

abstract final class M6MeterSwapLines {
  static const title = 'মিটার বদল, ছবিতে প্রমাণ';

  // DRAFT wording — owner (M6-12): every guide line below is new text.
  static const intro = 'আজ তিনটে মিটার বদল — প্রতিটা রিডিংয়ের ছবি চাই!';
  static const askLook = 'আগে ভালো করে দেখুন — বদল, না রিপোর্ট?';
  static const askAct = 'রিপোর্টের পর কী করবেন?';
  static const askSwap = 'মিটারটা বদলান — দুই রিডিংয়েরই ছবি চাই।';
  static const askNew = 'নতুন মিটারের রিডিংয়ের ছবি, তারপর জব কার্ড।';
  static const tasks = [askLook, askAct, askSwap, askNew];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // On screen (a worker's own words; not spoken).
  static const docket = 'মিটার বদল';
  static const start = 'মিটার বদল শুরু';
  static const report = 'অফিসে রিপোর্ট';
  static const cutSwap = 'পুরনো মিটার খুলে নতুন মিটার লাগানো হলো';
  static const cutWalk = 'পরের বাড়ি';
  static const photoOld = 'পুরনো';
  static const photoNew = 'নতুন';
  static const cardTitle = 'জব কার্ড · মিটার বদল';
  static const cardOld = 'পুরনো মিটার';
  static const cardNew = 'নতুন মিটার';
  static const testerLive = 'লাইভ';
  static const testerDead = '0 V';
  static const sceneLook = 'মিটার বোর্ড';
  static const stages = ['বাড়ি 1', 'বাড়ি 2', 'বাড়ি 3'];

  static String tool(M6SwapTool t) => switch (t) {
        M6SwapTool.phone => 'ফোন',
        M6SwapTool.tester => 'টেস্টার',
        M6SwapTool.driver => 'স্ক্রু-ড্রাইভার',
        M6SwapTool.card => 'জব কার্ড',
      };

  // The action deck (DRAFT wording — owner). 26–33 letters.
  static const actRight = ['কর্তৃপক্ষকে রিপোর্ট করে দূরে থাকি', 'কিছু না ছুঁয়ে অফিসে রিপোর্ট করি'];
  static const actWrong = <M6SwapAct, List<String>>{
    M6SwapAct.pullBypass: ['বাইপাসের তারটা টেনে খুলে দিই'],
    M6SwapAct.removeMagnet: ['চুম্বক সরিয়ে বদল শুরু করি'],
    M6SwapAct.reseal: ['সিল তো পুরনো, নিজেই সিল দিই'],
    M6SwapAct.startAnyway: ['ও কিছু না, মিটারটা বদলেই দিই', 'লক্ষণ থাক, মিটার বদলে চলে যাই'],
    M6SwapAct.noReport: ['গ্রাহককে বকে দিয়ে চলে যাই', 'এবারের মতো ছেড়ে দিয়ে চলে যাই'],
  };
  static List<String> get allActWrong => [for (final l in actWrong.values) ...l];

  // The reasons. The right ones fit what this job had (lesson 6.10 point 4,
  // pro tips 2 and 3); the wrong ones are the lesson's myths and excuses.
  // DRAFT wording — owner. 38–47 letters.
  static const whyQ = <M6SwapWhy, String>{
    M6SwapWhy.oldPhoto: 'কেন পুরনো মিটারের শেষ রিডিংয়ের ছবি তুললেন?',
    M6SwapWhy.snapFirst: 'কেন কাটআউট খোলার আগেই ছবি তুললেন?',
    M6SwapWhy.isolate: 'কেন বক্স খোলার আগে কাটআউট খুলে টেস্টারে দেখলেন?',
    M6SwapWhy.reportSeal: 'কেন সিল ভাঙা দেখে বদল না করে রিপোর্ট করলেন?',
    M6SwapWhy.reportMagnet: 'কেন চুম্বক দেখে বদল না করে রিপোর্ট করলেন?',
    M6SwapWhy.reportScreen: 'কেন ডিসপ্লের লেখা দেখে বদল না করে রিপোর্ট করলেন?',
    M6SwapWhy.bypass: 'কেন বাইপাসের তারে হাত দিলেন না?',
  };
  static const whyRight = <M6SwapWhy, List<String>>{
    M6SwapWhy.oldPhoto: ['শেষ রিডিংয়ের ছবি থাকলে বিলিং-এ ঝামেলা হয় না', 'ছবিই প্রমাণ — পরে বিলিং নিয়ে তর্ক ওঠে না'],
    M6SwapWhy.snapFirst: ['কাটআউট খুললে এই মিটারের ডিসপ্লে নিভে যায়', 'সাপ্লাই গেলে ইলেকট্রনিক মিটারের স্ক্রিন ফাঁকা'],
    M6SwapWhy.isolate: ['আগে কাটআউট খুলে বিচ্ছিন্ন, তারপর টেস্টারে ডেড', 'লাইন বিচ্ছিন্ন করে ডেড প্রমাণ না করে কাজ নয়'],
    M6SwapWhy.reportSeal: ['ভাঙা সিল ট্যাম্পারিং-এর প্রথম ও প্রধান লক্ষণ', 'সিল ভাঙা মানে সন্দেহ — কর্তৃপক্ষকে জানাতে হয়'],
    M6SwapWhy.reportMagnet: ['মিটারের কাছে চুম্বক রাখা চুরির চেষ্টার লক্ষণ', 'চুম্বকই চুরির প্রমাণ — সরানো নয়, রিপোর্ট'],
    M6SwapWhy.reportScreen: ["ডিসপ্লেতে 'Tamper' বা 'Error' ট্যাম্পারের লক্ষণ", 'মিটারের এমন অস্বাভাবিক আচরণ মানেই রিপোর্ট'],
    M6SwapWhy.bypass: ['চোরের ওয়্যারিং বিপজ্জনক — ওই তার চালু থাকে', 'বাইপাসের তার চালু লাইন — খালি হাতে ছোঁয়া নয়'],
  };
  static const myths = [
    'চুম্বক রাখলে মিটার স্লো হয়, তাতে কী এসে যায়',
    'বৃষ্টি বা ঠান্ডায় মিটার তো এমনিই স্লো চলে',
    'রিডিং মুখে মনে রাখলেই কাজ ঠিক চলে যায়',
    'ইনসুলেটেড স্ক্রু-ড্রাইভারে লাইন বন্ধ করতে হয় না',
    'গ্রাহক যাতে খুশি থাকেন, শুধু সেই জন্যই',
    'শুধু ঝামেলা এড়াতে, এর আর কোনো মানে নেই',
    'নতুন মিটার এলে পুরনো রিডিং আর কাজে লাগে না',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play). DRAFT wording — owner; his two
  // pushes need recording (tool/rival_clip.py). His exit line is recorded.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerMagnet = CoworkerScript(
    line: 'চুম্বক-টুম্বক পুরনো কথা! ওটা সরিয়ে মিটার বদলে দাও — রিপোর্টের ঝামেলা কে করে?',
    exitLine: coworkerExit,
    right: ['না, যেমন আছে রেখে রিপোর্ট করব', 'না, চুম্বকই চুরির প্রমাণ, ছোঁব না', 'না, এটা কর্তৃপক্ষকে জানাতেই হবে'],
    wrong: [
      'ঠিক, চুম্বকটা সরিয়ে বদলে দিই',
      'আচ্ছা, রিপোর্টের কোনো দরকার নেই',
      'হ্যাঁ, চুম্বকটা খুলে রেখে দিই',
      'ঠিক আছে, চুপচাপ মিটার বদলে দিই',
      'হ্যাঁ, ঝামেলা বাড়িয়ে লাভ নেই',
    ],
    asks: ['কী করবেন?', 'ও বলছে চুম্বক সরিয়ে বদলে দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerPhoto = CoworkerScript(
    line: 'ছবি-টবি ছাড়ো, রিডিং মুখে মনে রাখো — তাড়াতাড়ি বদলাও!',
    exitLine: coworkerExit,
    right: ['না, দুই রিডিংয়েরই ছবি তুলব', 'না, ছবিই বিলিং-এর প্রমাণ', 'না, মুখের কথা কোনো প্রমাণ নয়'],
    wrong: [
      'ঠিক, রিডিং মনে রাখলেই হবে',
      'আচ্ছা, ছবি ছাড়াই বদলাই',
      'হ্যাঁ, ছবি তোলা সময় নষ্ট',
      'ঠিক আছে, পরে মনে করে লিখব',
      'হ্যাঁ, তাড়াতাড়ি বদলে ফেলি',
    ],
    asks: ['কী করবেন?', 'ও বলছে ছবি ছাড়াই বদলাতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M6SwapPush p) => switch (p) {
        M6SwapPush.magnet => coworkerMagnet,
        M6SwapPush.photo => coworkerPhoto,
      };
  static const allCoworkers = [coworkerMagnet, coworkerPhoto];

  static String callHeld(M6SwapPush p) => switch (p) {
        M6SwapPush.magnet => 'ঠিক! চুম্বক যেমন আছে থাক — ওটাই প্রমাণ।',
        M6SwapPush.photo => 'ঠিক! মুখের কথা নয় — ছবিই প্রমাণ।',
      };

  static const allSet = 'তিন বাড়ির কাজ শেষ — ছবিও আছে, রিপোর্টও আছে। দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে ভালো করে দেখে, ঠিক ক্রমে, ছবি তুলে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন" (on screen).
  static const caughtPhoto = 'দুই মিটারেরই kWh রিডিংয়ের ছবি তুলেছেন';
  static const caughtSnapFirst = 'কাটআউট খোলার আগেই ছবি তুলেছেন';
  static const caughtIsolate = 'কাটআউট খুলে, টেস্টারে ডেড দেখে বক্স খুলেছেন';
  static const caughtTamper = 'চুরির লক্ষণ দেখে কর্তৃপক্ষকে রিপোর্ট করেছেন';
  static const caughtBypass = 'বাইপাসের তারে হাত দেননি';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Every new spoken guide line (DRAFT wording — owner; to be recorded):
  /// the intro and tasks, the spoken "কেন?" questions, the praise after a
  /// refusal, the end lines, and every mistake text (read aloud the first
  /// time).
  static const newGuideLines = [
    intro,
    askLook,
    askAct,
    askSwap,
    askNew,
    'কেন পুরনো মিটারের শেষ রিডিংয়ের ছবি তুললেন?',
    'কেন কাটআউট খোলার আগেই ছবি তুললেন?',
    'কেন বক্স খোলার আগে কাটআউট খুলে টেস্টারে দেখলেন?',
    'কেন সিল ভাঙা দেখে বদল না করে রিপোর্ট করলেন?',
    'কেন চুম্বক দেখে বদল না করে রিপোর্ট করলেন?',
    'কেন ডিসপ্লের লেখা দেখে বদল না করে রিপোর্ট করলেন?',
    'কেন বাইপাসের তারে হাত দিলেন না?',
    'ঠিক! চুম্বক যেমন আছে থাক — ওটাই প্রমাণ।',
    'ঠিক! মুখের কথা নয় — ছবিই প্রমাণ।',
    'ও বলছে চুম্বক সরিয়ে বদলে দিতে। কী করবেন?',
    'ও বলছে ছবি ছাড়াই বদলাতে। কী করবেন?',
    allSet,
    fail,
    M6MeterSwapMistakes.pullBypassBn,
    M6MeterSwapMistakes.liveSwapBn,
    M6MeterSwapMistakes.startTamperBn,
    M6MeterSwapMistakes.falseReportBn,
    M6MeterSwapMistakes.removeMagnetBn,
    M6MeterSwapMistakes.resealBn,
    M6MeterSwapMistakes.noReportBn,
    M6MeterSwapMistakes.listenMagnetBn,
    M6MeterSwapMistakes.listenPhotoBn,
    M6MeterSwapMistakes.photoMissingBn,
    M6MeterSwapMistakes.photoScreenBn,
    M6MeterSwapMistakes.noTestBn,
    M6MeterSwapMistakes.testFirstBn,
    M6MeterSwapMistakes.noReproveBn,
  ];

  /// The coworker's new pushes (DRAFT wording — owner; to be recorded in his
  /// voice).
  static const newRivalLines = [
    'চুম্বক-টুম্বক পুরনো কথা! ওটা সরিয়ে মিটার বদলে দাও — রিপোর্টের ঝামেলা কে করে?',
    'ছবি-টবি ছাড়ো, রিডিং মুখে মনে রাখো — তাড়াতাড়ি বদলাও!',
  ];
}

abstract final class M6MeterSwapMistakes {
  static const _dir = 'assets/game/art/m6_meter_swap_proof';

  // Lesson 6.10 points (0-based): 0 the meter kinds, 1 the display and the
  // push-button (kWh, kW, V, A), 2 the complaints, 3 the tamper signs and
  // the safety tip (the pro tips follow it in the reader).
  // DRAFT wording — owner (every text below is read aloud the first time).
  static const pullBypassBn = 'খালি হাতে বাইপাসের তার টানলেন — ওটা চালু লাইন! চোরেরা বিপজ্জনক আর অপেশাদার পদ্ধতিতে ওয়্যারিং করে। কিছু না ছুঁয়ে কর্তৃপক্ষকে রিপোর্ট করুন।';
  static const liveSwapBn = 'কাটআউট না খুলেই মিটার বক্স খুললেন — চালু লাইন! মিটার বক্সে কাজের আগে পোলের ফিউজ বা ইনকামিং কাটআউট খুলে লাইন বিচ্ছিন্ন করুন, তারপর টেস্টারে ডেড প্রমাণ করুন।';
  static const startTamperBn = 'এই মিটারে ট্যাম্পারিং-এর লক্ষণ ছিল! এমন মিটার নিজে বদলাবেন না — অবিলম্বে কর্তৃপক্ষকে রিপোর্ট করুন।';
  static const falseReportBn = 'এই মিটারে সিল, তার, ডিসপ্লে, চুম্বক — কোনো লক্ষণই ছিল না। লক্ষণ না দেখে রিপোর্ট করলে গ্রাহক হয়রান হন, কাজও আটকে যায়।';
  static const removeMagnetBn = 'চুম্বক নিজে সরাবেন না — ওটাই চুরির প্রমাণ। যেমন আছে রেখে কর্তৃপক্ষকে রিপোর্ট করুন।';
  static const resealBn = 'ভাঙা সিল নিজে বদলে দিলে ট্যাম্পারিং-এর প্রমাণ মুছে যায়। যেমন আছে রেখে কর্তৃপক্ষকে রিপোর্ট করুন।';
  static const noReportBn = 'রিপোর্ট না করে চলে গেলে হবে না — বিদ্যুৎ চুরি দণ্ডনীয় অপরাধ। অবিলম্বে কর্তৃপক্ষকে রিপোর্ট করুন।';
  static const listenMagnetBn = '“পুরনো কথা” বলে চুম্বক সরানো নয় — ওটাই চুরির চেষ্টার প্রমাণ। যেমন আছে রেখে কর্তৃপক্ষকে রিপোর্ট করুন।';
  static const listenPhotoBn = 'মুখে মনে রাখা রিডিং প্রমাণ নয়! পুরনো মিটারের ফাইনাল রিডিং আর নতুন মিটারের প্রাথমিক রিডিং-এর ছবি তুলে রাখুন।';
  static const photoMissingBn = 'রিডিং-এর ছবি নেই! মিটার বদলের সময় পুরনো মিটারের ফাইনাল রিডিং এবং নতুন মিটারের প্রাথমিক রিডিং-এর ছবি তুলে রাখুন — বিলিং-এর ঝামেলা এড়াতে।';
  static const photoScreenBn = 'ছবিতে kWh-এর রিডিং নেই! পুশ-বাটন চেপে মোট kWh (ইউনিট)-এর স্ক্রিনে এনে তবে ছবি তুলুন।';
  static const noTestBn = 'কাটআউট খুলেছেন, কিন্তু টেস্টারে ডেড প্রমাণ করেননি! বক্স খোলার আগে টেস্টারে দেখে নিন।';
  static const testFirstBn = 'আগে জানা লাইভ পয়েন্টে টেস্টার যাচাই করে নিন — খারাপ টেস্টার চালু লাইনকেও ডেড দেখায়!';
  static const noReproveBn = 'ডেড দেখার পর আবার জানা লাইভে টেস্টার দেখে নিন — মাঝপথে টেস্টার বিগড়ালে "0 V"-র ভরসা নেই!';

  static const pullBypass = DoMistake(key: '6.10/m6_meter_swap_proof/pull-bypass', textBn: pullBypassBn, art: '$_dir/bypass_pull.svg', deadly: true, lessonPoint: 3);
  static const liveSwap = DoMistake(key: '6.10/m6_meter_swap_proof/live-swap', textBn: liveSwapBn, art: '$_dir/live_swap.svg', deadly: true, lessonPoint: 3);
  static const startTamper = DoMistake(key: '6.10/m6_meter_swap_proof/start-tamper', textBn: startTamperBn, art: '$_dir/start_tamper.svg', lessonPoint: 3);
  static const falseReport = DoMistake(key: '6.10/m6_meter_swap_proof/false-report', textBn: falseReportBn, art: '$_dir/false_report.svg', lessonPoint: 3);
  static const removeMagnet = DoMistake(key: '6.10/m6_meter_swap_proof/remove-magnet', textBn: removeMagnetBn, art: '$_dir/magnet.svg', lessonPoint: 3);
  static const reseal = DoMistake(key: '6.10/m6_meter_swap_proof/reseal', textBn: resealBn, art: '$_dir/reseal.svg', lessonPoint: 3);
  static const noReport = DoMistake(key: '6.10/m6_meter_swap_proof/no-report', textBn: noReportBn, art: '$_dir/start_tamper.svg', lessonPoint: 3);
  static const listenMagnet = DoMistake(key: '6.10/m6_meter_swap_proof/listen-magnet', textBn: listenMagnetBn, art: '$_dir/magnet.svg', lessonPoint: 3);
  static const listenPhoto = DoMistake(key: '6.10/m6_meter_swap_proof/listen-photo', textBn: listenPhotoBn, art: '$_dir/photo_missing.svg', lessonPoint: 3);
  static const photoMissing = DoMistake(key: '6.10/m6_meter_swap_proof/photo-missing', textBn: photoMissingBn, art: '$_dir/photo_missing.svg', lessonPoint: 3);
  static const photoScreen = DoMistake(key: '6.10/m6_meter_swap_proof/photo-screen', textBn: photoScreenBn, art: '$_dir/photo_screen.svg', lessonPoint: 1);
  static const noTest = DoMistake(key: '6.10/m6_meter_swap_proof/no-test', textBn: noTestBn, art: '$_dir/no_test.svg', lessonPoint: 3);

  /// The tester not proved on a live point before the 0 V (N9) / not proved
  /// again after it (N4). The live-dead-live picture of the M2 gate (it shows
  /// exactly this).
  static const testFirst = DoMistake(key: '6.10/m6_meter_swap_proof/test-before-proof', textBn: testFirstBn, art: 'assets/game/art/m2_gate_field/live_dead_live.svg', lessonPoint: 3);
  static const noReprove = DoMistake(key: '6.10/m6_meter_swap_proof/no-reprove', textBn: noReproveBn, art: 'assets/game/art/m2_gate_field/live_dead_live.svg', lessonPoint: 3);

  static DoMistake push(M6SwapPush p) => switch (p) {
        M6SwapPush.magnet => listenMagnet,
        M6SwapPush.photo => listenPhoto,
      };

  static DoMistake? act(M6SwapAct a) => switch (a) {
        M6SwapAct.report => null,
        M6SwapAct.pullBypass => pullBypass,
        M6SwapAct.removeMagnet => removeMagnet,
        M6SwapAct.reseal => reseal,
        M6SwapAct.startAnyway => startTamper,
        M6SwapAct.noReport => noReport,
      };

  static const List<DoMistake> all = [
    pullBypass,
    liveSwap,
    startTamper,
    falseReport,
    removeMagnet,
    reseal,
    noReport,
    listenMagnet,
    listenPhoto,
    photoMissing,
    photoScreen,
    noTest,
    testFirst,
    noReprove,
  ];
}

/// One wall's job.
@immutable
class M6SwapJob {
  const M6SwapJob({
    required this.meter,
    required this.sign,
    required this.brokenSeal,
    required this.magnetAt,
    required this.tamperWord,
    required this.startScreen,
    required this.newStart,
    required this.kwhTenths,
    required this.kwHundredths,
    required this.volt,
    required this.newKwhTenths,
    required this.decoys,
    required this.palette,
    required this.whyRoll,
  });

  final M6SwapMeter meter;
  final M6SwapSign sign;

  /// The cut seal (sign seal), the magnet's spot (sign magnet: top, side or
  /// under), the word on the tamper screen (sign screen).
  final M6SwapSeal? brokenSeal;
  final M6SwapSpot? magnetAt;
  final String tamperWord;

  /// The old LCD's screen when we arrive and the new one's when it wakes
  /// (0–3: kWh, kW, V, A).
  final int startScreen;
  final int newStart;

  /// The readings (game data).
  final int kwhTenths;
  final int kwHundredths;
  final int volt;
  final int newKwhTenths;
  int get ampTenths => (kwHundredths * 100 / volt).round();

  /// The harmless things at the box spots (top, side, under).
  final Map<M6SwapSpot, M6SwapDecoy> decoys;
  final int palette;
  final int whyRoll;

  bool get tampered => sign != M6SwapSign.none;
}

/// One play's deal: three walls, the coworker's push and its wall.
@immutable
class M6SwapDeal {
  const M6SwapDeal({required this.jobs, required this.push, required this.pushJob});
  final List<M6SwapJob> jobs;
  final M6SwapPush push;
  final int pushJob;
}

const _cycleOld = [M6SwapScreen.kwh, M6SwapScreen.kw, M6SwapScreen.volt, M6SwapScreen.amp];

/// The idle hand's sweep over the cut-out (null) and the tools on a clean
/// job: shuffled once per wall from the deal ([seed]), and never in the
/// procedure order (phone, cut-out, tester, screwdriver, card), so the hand
/// shows how to touch, never what comes next.
List<M6SwapTool?> m6SwapHintOrder(int seed, {required bool withCard}) {
  final procedure = <M6SwapTool?>[M6SwapTool.phone, null, M6SwapTool.tester, M6SwapTool.driver, if (withCard) M6SwapTool.card];
  final order = [...procedure]..shuffle(math.Random(seed));
  if (listEquals(order, procedure)) order.add(order.removeAt(0));
  return order;
}

M6SwapDeal m6SwapDeal(math.Random rng) {
  final tampers = 1 + rng.nextInt(2);
  final idx = [0, 1, 2]..shuffle(rng);
  final tamperAt = idx.take(tampers).toSet();
  final signs = [M6SwapSign.seal, M6SwapSign.bypass, M6SwapSign.magnet, M6SwapSign.screen]..shuffle(rng);
  final palettes = [0, 1, 2]..shuffle(rng);
  var si = 0;
  final sign = [for (var i = 0; i < 3; i++) tamperAt.contains(i) ? signs[si++] : M6SwapSign.none];
  final meter = [for (var i = 0; i < 3; i++) sign[i] == M6SwapSign.screen || rng.nextBool() ? M6SwapMeter.lcd : M6SwapMeter.disc];
  // At least one clean electronic meter (the snap-before-the-cut-out order).
  if (![for (var i = 0; i < 3; i++) sign[i] == M6SwapSign.none && meter[i] == M6SwapMeter.lcd].contains(true)) {
    meter[[for (var i = 0; i < 3; i++) i].firstWhere((i) => sign[i] == M6SwapSign.none)] = M6SwapMeter.lcd;
  }
  final jobs = <M6SwapJob>[
    for (var i = 0; i < 3; i++)
      M6SwapJob(
        meter: meter[i],
        sign: sign[i],
        brokenSeal: sign[i] == M6SwapSign.seal ? M6SwapSeal.values[rng.nextInt(2)] : null,
        magnetAt: sign[i] == M6SwapSign.magnet ? const [M6SwapSpot.top, M6SwapSpot.side, M6SwapSpot.under][rng.nextInt(3)] : null,
        tamperWord: rng.nextBool() ? 'Tamper' : 'Error',
        startScreen: rng.nextInt(4),
        newStart: rng.nextInt(4),
        kwhTenths: 10000 + rng.nextInt(90000),
        kwHundredths: 10 + rng.nextInt(240),
        volt: 226 + rng.nextInt(14),
        newKwhTenths: rng.nextInt(31),
        decoys: {for (final s in const [M6SwapSpot.top, M6SwapSpot.side, M6SwapSpot.under]) s: M6SwapDecoy.values[rng.nextInt(3)]},
        palette: palettes[i],
        whyRoll: rng.nextInt(1000),
      ),
  ];
  final magnets = [for (var i = 0; i < 3; i++) if (sign[i] == M6SwapSign.magnet) i];
  final clean = [for (var i = 0; i < 3; i++) if (sign[i] == M6SwapSign.none) i];
  if (magnets.isNotEmpty && rng.nextBool()) {
    return M6SwapDeal(jobs: jobs, push: M6SwapPush.magnet, pushJob: magnets.first);
  }
  return M6SwapDeal(jobs: jobs, push: M6SwapPush.photo, pushJob: clean[rng.nextInt(clean.length)]);
}

/// The clean job's reason topic: one that fits what he did (the
/// snap-before-the-cut-out reason only on an electronic meter he snapped
/// before any pull).
M6SwapWhy m6SwapCleanWhy(M6SwapJob j, {required bool snappedFirst}) {
  final fits = [M6SwapWhy.oldPhoto, M6SwapWhy.isolate, if (j.meter == M6SwapMeter.lcd && snappedFirst) M6SwapWhy.snapFirst];
  return fits[j.whyRoll % fits.length];
}

/// The tampered job's reason topic: its own sign.
M6SwapWhy m6SwapTamperWhy(M6SwapJob j) => switch (j.sign) {
      M6SwapSign.seal => M6SwapWhy.reportSeal,
      M6SwapSign.magnet => M6SwapWhy.reportMagnet,
      M6SwapSign.screen => M6SwapWhy.reportScreen,
      M6SwapSign.bypass || M6SwapSign.none => M6SwapWhy.bypass,
    };

/// The action deck for a tampered job: the right report, the wrong act that
/// fits its sign (the bypass pull only where there is a bypass), and a
/// generic one (both generic on a tamper screen).
List<ChoiceOption> m6SwapActDeal(M6SwapJob j, math.Random rng) {
  String pick(M6SwapAct a) {
    final l = M6MeterSwapLines.actWrong[a]!;
    return l[rng.nextInt(l.length)];
  }

  final own = switch (j.sign) {
    M6SwapSign.bypass => M6SwapAct.pullBypass,
    M6SwapSign.magnet => M6SwapAct.removeMagnet,
    M6SwapSign.seal => M6SwapAct.reseal,
    M6SwapSign.screen || M6SwapSign.none => null,
  };
  final generic = [M6SwapAct.startAnyway, M6SwapAct.noReport]..shuffle(rng);
  final wrong = [?own, ...generic].take(2);
  return [
    ChoiceOption(M6MeterSwapLines.actRight[rng.nextInt(M6MeterSwapLines.actRight.length)], true),
    for (final a in wrong) ChoiceOption(pick(a), false),
  ]..shuffle(rng);
}

/// Which act a deck card is.
M6SwapAct m6SwapActOf(String text) {
  if (M6MeterSwapLines.actRight.contains(text)) return M6SwapAct.report;
  for (final e in M6MeterSwapLines.actWrong.entries) {
    if (e.value.contains(text)) return e.key;
  }
  return M6SwapAct.startAnyway;
}

/// A tester reading.
@immutable
class M6SwapTest {
  const M6SwapTest({this.live, this.mistake});
  final bool? live;
  final DoMistake? mistake;
}

/// The play state (pure logic).
class M6SwapRun {
  M6SwapRun(this.deal) {
    _reset();
  }

  final M6SwapDeal deal;

  int jobIndex = 0;
  M6SwapStage stage = M6SwapStage.look;

  // The wall now.
  final Set<M6SwapSeal> tugged = {};
  int screenIdx = 0;
  int newIdx = 0;
  var carrierIn = true;
  var everPulled = false;
  var provedLive = false;
  var dead = false;
  var reproved = false;
  var swapped = false;
  M6SwapShot? oldPhoto;
  M6SwapShot? newPhoto;

  /// The old kWh photo was taken with the supply on, before any pull.
  var snappedFirst = false;
  var _isoSlip = false;
  int jobSlips = 0;

  /// The jobs closed so far: true = closed with no slip on it.
  final List<bool> closed = [];

  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  M6SwapJob get job => deal.jobs[math.min(jobIndex, deal.jobs.length - 1)];
  bool get finished => jobIndex >= deal.jobs.length;
  bool get ended => finished || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => finished && deadly == null && percent >= 55;
  bool get _open => deadly == null && !finished;

  /// The coworker's push lands on this wall.
  bool get pushHere => deal.pushJob == jobIndex;

  void _reset() {
    tugged.clear();
    screenIdx = job.startScreen;
    newIdx = job.newStart;
    carrierIn = true;
    everPulled = false;
    provedLive = false;
    dead = false;
    reproved = false;
    swapped = false;
    oldPhoto = null;
    newPhoto = null;
    snappedFirst = false;
    _isoSlip = false;
    jobSlips = 0;
    stage = M6SwapStage.look;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    jobSlips++;
    return m;
  }

  List<M6SwapScreen> get _oldCycle => [..._cycleOld, if (job.sign == M6SwapSign.screen) M6SwapScreen.tamper];

  /// The meter's face now: the new meter after the swap; the drum on a disc
  /// meter; an electronic one blank without supply.
  M6SwapShot get face {
    final j = job;
    if (swapped) {
      if (!carrierIn) return const M6SwapShot(M6SwapScreen.blank, '');
      final s = _cycleOld[newIdx % 4];
      return M6SwapShot(s, m6SwapScreenText(s, kwhTenths: j.newKwhTenths, kwHundredths: 0, volt: j.volt, ampTenths: 0));
    }
    if (j.meter == M6SwapMeter.disc) {
      return M6SwapShot(M6SwapScreen.drum, m6SwapScreenText(M6SwapScreen.drum, kwhTenths: j.kwhTenths, kwHundredths: 0, volt: 0, ampTenths: 0));
    }
    if (!carrierIn) return const M6SwapShot(M6SwapScreen.blank, '');
    final cyc = _oldCycle;
    final s = cyc[screenIdx % cyc.length];
    return M6SwapShot(s, m6SwapScreenText(s, kwhTenths: j.kwhTenths, kwHundredths: j.kwHundredths, volt: j.volt, ampTenths: j.ampTenths, tamperWord: j.tamperWord));
  }

  bool get _looking => _open && (stage == M6SwapStage.look || stage == M6SwapStage.swap);

  /// The push-button: the next screen (an electronic meter with supply).
  bool press() {
    if (!_looking || !carrierIn) return false;
    if (swapped) {
      newIdx = (newIdx + 1) % 4;
      return true;
    }
    if (job.meter != M6SwapMeter.lcd) return false;
    screenIdx = (screenIdx + 1) % _oldCycle.length;
    return true;
  }

  /// A seal tugged: true if it is the cut one (it swings loose).
  bool? tug(M6SwapSeal s) {
    if (!_looking || swapped) return null;
    tugged.add(s);
    return job.brokenSeal == s;
  }

  /// A close look at [s]: what is really there.
  M6SwapThing? look(M6SwapSpot s) {
    if (!_looking) return null;
    final j = job;
    if (s == M6SwapSpot.junction) return j.sign == M6SwapSign.bypass ? M6SwapThing.bypass : M6SwapThing.cable;
    if (j.magnetAt == s && !swapped) return M6SwapThing.magnet;
    return switch (j.decoys[s]!) {
      M6SwapDecoy.clip => M6SwapThing.clip,
      M6SwapDecoy.nest => M6SwapThing.nest,
      M6SwapDecoy.grommet => M6SwapThing.grommet,
    };
  }

  /// 'মিটার বদল শুরু' ([start]) or 'অফিসে রিপোর্ট': a change on a tampered
  /// meter, or a report on a clean one, is a slip (he looks again).
  DoMistake? decide({required bool start}) {
    if (!_open || stage != M6SwapStage.look) return null;
    if (start) {
      if (job.tampered) return _slip(M6MeterSwapMistakes.startTamper);
      stage = M6SwapStage.swap;
      return null;
    }
    if (!job.tampered) return _slip(M6MeterSwapMistakes.falseReport);
    stage = M6SwapStage.act;
    return null;
  }

  /// A card of the action deck: the report closes the job; a bypass pull is
  /// deadly; the rest are slips (the deck comes again).
  DoMistake? act(M6SwapAct a) {
    if (!_open || stage != M6SwapStage.act) return null;
    final m = M6MeterSwapMistakes.act(a);
    if (m == null) {
      stage = M6SwapStage.closed;
      closed.add(jobSlips == 0);
      _tag(M6MeterSwapLines.caughtTamper);
      if (job.sign == M6SwapSign.bypass) _tag(M6MeterSwapLines.caughtBypass);
      return null;
    }
    if (m.deadly) return deadly = m;
    return _slip(m);
  }

  /// Listened to the coworker: both his pushes are slips (B1).
  DoMistake listen(M6SwapPush p) => _slip(M6MeterSwapMistakes.push(p));

  /// The cut-out's carrier out (a clean job, before or after the swap).
  bool pull() {
    if (!_open || stage != M6SwapStage.swap || !carrierIn) return false;
    carrierIn = false;
    everPulled = true;
    return true;
  }

  /// The carrier back in: the supply on again (any 0 V is gone).
  bool pushIn() {
    if (!_open || stage != M6SwapStage.swap || carrierIn) return false;
    carrierIn = true;
    dead = false;
    reproved = false;
    return true;
  }

  /// Is a tester place live now? The line contact always; the load contact
  /// while the carrier is in.
  bool liveAt(M6SwapPoint p) => p == M6SwapPoint.line || carrierIn;

  /// The tester on [p]: any live reading proves it (again, after a 0 V); a
  /// 0 V on a tester not proved first is a slip (N9) and counts for nothing.
  M6SwapTest test(M6SwapPoint p) {
    if (!_open || stage != M6SwapStage.swap || swapped) return const M6SwapTest();
    if (liveAt(p)) {
      // Any known live point proves the tester (A9): the load contact with
      // the carrier in counts as much as the line contact. After a 0 V the
      // carrier is out, so the re-proof can only be on the line contact.
      provedLive = true;
      if (dead) reproved = true;
      return const M6SwapTest(live: true);
    }
    if (!provedLive) {
      _isoSlip = true;
      return M6SwapTest(live: false, mistake: _slip(M6MeterSwapMistakes.testFirst));
    }
    dead = true;
    reproved = false;
    return const M6SwapTest(live: false);
  }

  /// The screwdriver on the box: with the carrier in it is deadly (the
  /// supply on, X5); the carrier out but no 0 V, or not proved again, a slip
  /// (the box stays shut). Otherwise the swap happens.
  DoMistake? openBox() {
    if (!_open || stage != M6SwapStage.swap || swapped) return null;
    if (carrierIn) return deadly = M6MeterSwapMistakes.liveSwap;
    if (!dead) {
      _isoSlip = true;
      return _slip(M6MeterSwapMistakes.noTest);
    }
    if (!reproved) {
      _isoSlip = true;
      return _slip(M6MeterSwapMistakes.noReprove);
    }
    swapped = true;
    if (!_isoSlip) _tag(M6MeterSwapLines.caughtIsolate);
    return null;
  }

  /// The phone: the face now goes into the old slot (before the swap) or the
  /// new one (after it). True if a photo was taken.
  bool snap() {
    if (!_open || stage != M6SwapStage.swap) return false;
    final f = face;
    if (swapped) {
      newPhoto = f;
    } else {
      oldPhoto = f;
      snappedFirst = carrierIn && !everPulled && (f.screen == M6SwapScreen.kwh || f.screen == M6SwapScreen.drum);
    }
    return true;
  }

  static bool _kwh(M6SwapShot? s) => s != null && (s.screen == M6SwapScreen.kwh || s.screen == M6SwapScreen.drum);

  /// The job card: both photos must be there and be the kWh reading (one
  /// slip covers the card). The job closes either way.
  DoMistake? jobCard() {
    if (!_open || stage != M6SwapStage.swap || !swapped) return null;
    DoMistake? m;
    if (oldPhoto == null || newPhoto == null) {
      m = _slip(M6MeterSwapMistakes.photoMissing);
    } else if (!_kwh(oldPhoto) || newPhoto!.screen != M6SwapScreen.kwh) {
      m = _slip(M6MeterSwapMistakes.photoScreen);
    } else {
      _tag(M6MeterSwapLines.caughtPhoto);
      if (snappedFirst && job.meter == M6SwapMeter.lcd) _tag(M6MeterSwapLines.caughtSnapFirst);
    }
    stage = M6SwapStage.closed;
    closed.add(jobSlips == 0);
    return m;
  }

  /// On to the next wall (after its reason, or after its slip card).
  void nextJob() {
    if (stage != M6SwapStage.closed || finished) return;
    jobIndex++;
    if (!finished) _reset();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action, a mix of 1.5 clean and 1.5 tampered walls:
///   clean: tug × 2, look × 2, decide (preview) 2500, press × 2, snap, pull,
///     tester tool + 3 readings, screwdriver + box, swap cut 2400, carrier
///     in, press × 2, snap, job card + panel 2900, reason ~8200, walk 2400
///                                                            ≈ 47000
///   tampered: tug × 2, look × 2, decide 2500, deck 4000, reason ~8200,
///     walk 2400                                              ≈ 23000
///   1.5 × 47000 + 1.5 × 23000 + the coworker once ≈ 9600     ≈ 114600
/// 85 % ≈ 97400 → 100 s.
const m6MeterSwapQuickMs = 100000;

/// Test hook: the play state of the page now on screen (tests only).
abstract final class M6MeterSwapProbe {
  @visibleForTesting
  static M6SwapRun? run;
}

@immutable
class M6MeterSwapPack {
  const M6MeterSwapPack({required this.id, required this.titleBn, this.quickMs = m6MeterSwapQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6MeterSwapPack> m6MeterSwapPacks = {
  'do_6_10_b': M6MeterSwapPack(id: 'do_6_10_b', titleBn: M6MeterSwapLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M6MeterSwapPage extends StatefulWidget {
  const M6MeterSwapPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6MeterSwapPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6MeterSwapPage> createState() => _M6MeterSwapPageState();
}

class _M6MeterSwapPageState extends State<M6MeterSwapPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _SwapRunPage(
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

class _SwapRunPage extends ConsumerStatefulWidget {
  const _SwapRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6MeterSwapPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_SwapRunPage> createState() => _SwapRunPageState();
}

/// What a pan on the scene is doing.
enum _Pan { none, carrier, swipe }

class _SwapRunPageState extends ConsumerState<_SwapRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6SwapRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  VoidCallback? _afterCard;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;

  /// The tool in hand on a clean job (the tester or the screwdriver).
  M6SwapTool? _held;

  /// The decision's preview ('মিটার বদল শুরু' = true, 'অফিসে রিপোর্ট' =
  /// false) and the one set aside.
  bool? _preview;
  final Set<bool> _aside = {};

  // The action deck.
  var _actOpen = false;
  List<ChoiceOption> _actOpts = const [];
  final Set<String> _actWrong = {};
  String? _actPicked;
  int _actN = 0;

  /// A close look on screen, and the tester's reading chip.
  ({M6SwapSpot spot, M6SwapThing thing})? _look;
  Timer? _lookTimer;
  ({M6SwapPoint at, bool live})? _chip;
  Timer? _chipTimer;
  int _snapN = 0;

  /// The job card's panel (both photos) before its verdict.
  var _cardPanel = false;
  Timer? _panelTimer;

  /// A cutscene running ('swap', 'walk'); the scene takes no touch.
  String? _cut;
  Timer? _cutTimer;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final Map<M6SwapTool, GlobalKey> _toolKeys = {for (final t in M6SwapTool.values) t: GlobalKey()};
  final _startKey = GlobalKey();
  final _reportKey = GlobalKey();
  final _carrierKey = GlobalKey();
  int _hintN = 0;
  int _steps = 0;
  M6SwapGeo? _geoNow;

  _Pan _pan = _Pan.none;
  Offset _panFrom = Offset.zero;
  Offset _panNow = Offset.zero;

  @override
  void initState() {
    super.initState();
    _run = M6SwapRun(m6SwapDeal(widget.rng));
    M6MeterSwapProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _lookTimer?.cancel();
    _chipTimer?.cancel();
    _panelTimer?.cancel();
    _cutTimer?.cancel();
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
      !_intro &&
      !_ended &&
      _card == null &&
      !reasonOpen &&
      !tableBusy &&
      !coworkerOpen &&
      !_freeze &&
      _cut == null &&
      _preview == null &&
      !_actOpen &&
      !_cardPanel &&
      !_run.ended;

  String get _task => switch (_run.stage) {
        M6SwapStage.look => M6MeterSwapLines.askLook,
        M6SwapStage.act => M6MeterSwapLines.askAct,
        M6SwapStage.swap || M6SwapStage.closed => _run.swapped ? M6MeterSwapLines.askNew : M6MeterSwapLines.askSwap,
      };

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  Future<void> _start() async {
    _clock.start();
    _wallReady();
    unawaited(_sayChain([_task]));
  }

  /// A new wall: the coworker is scheduled when his push lands here (he
  /// comes only when the decisive control calls him: the report on the
  /// magnet job, the phone on the clean one).
  void _wallReady() {
    if (!coworkerDone && _run.pushHere) scheduleCoworker();
  }

  /// A rough global position of a design point (for the flying ◆ only).
  Offset _sceneToGlobal(Offset p) {
    final size = MediaQuery.sizeOf(context);
    final k = size.width / 360;
    return Offset(p.dx * k, p.dy * k);
  }

  // --- looking -----------------------------------------------------------------
  void _tug(M6SwapSeal s) {
    final broken = _run.tug(s);
    if (broken == null) return;
    if (broken) {
      HapticFeedback.mediumImpact();
      _cue('sounds/learn/dull_steel.ogg', volume: 0.55);
    } else {
      HapticFeedback.lightImpact();
      _cue('sounds/intro/tick.ogg', volume: 0.5);
    }
    _stepDone();
  }

  void _closeLook(M6SwapSpot s) {
    final thing = _run.look(s);
    if (thing == null) return;
    _tick('sounds/intro/click.ogg', 0.45);
    _lookTimer?.cancel();
    setState(() => _look = (spot: s, thing: thing));
    _lookTimer = Timer(Duration(milliseconds: _quiet ? 2600 : 2400), () {
      if (mounted) setState(() => _look = null);
    });
    _stepDone();
  }

  void _press() {
    if (!_run.press()) {
      _hints.missTap();
      return;
    }
    _tick('sounds/learn/dmm_beep.ogg', 0.45);
    _stepDone();
  }

  // --- the decision --------------------------------------------------------------
  void _openPreview(bool start) {
    if (!_canPlay || _run.stage != M6SwapStage.look) return;
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() => _preview = start);
  }

  void _rejectPreview() {
    final p = _preview;
    if (p == null) return;
    setState(() {
      _aside.add(p);
      _preview = null;
    });
  }

  void _confirmPreview() {
    final p = _preview;
    if (p == null) return;
    setState(() {
      _preview = null;
      _aside.clear();
    });
    _decide(start: p);
  }

  void _decide({required bool start}) {
    if (!_canPlay) return;
    // The magnet push waits for the report.
    if (!start && _run.deal.push == M6SwapPush.magnet && holdForCoworker()) return;
    final m = _run.decide(start: start);
    if (m != null) {
      unawaited(_mistake(m, _sceneToGlobal(_geoNow?.flashBox ?? Offset.zero)));
      return;
    }
    _hush();
    setState(() {
      _look = null;
      _wake++;
    });
    if (_run.stage == M6SwapStage.act) {
      _openAct();
    } else {
      HapticFeedback.mediumImpact();
      unawaited(_sayChain([_task]));
      _stepDone();
    }
  }

  // --- the action deck -----------------------------------------------------------
  void _openAct() {
    if (_ended || _run.stage != M6SwapStage.act) return;
    setState(() {
      _actOpts = m6SwapActDeal(_run.job, widget.rng);
      _actWrong.clear();
      _actPicked = null;
      _actOpen = true;
      _actN++;
    });
    unawaited(_sayChain([M6MeterSwapLines.askAct], mood: GuideMood.think));
  }

  Future<void> _pickAct(ChoiceOption o, Offset at) async {
    if (!_actOpen || _actPicked != null || _actWrong.isNotEmpty) return;
    _hush();
    setState(() => o.correct ? _actPicked = o.textBn : _actWrong.add(o.textBn));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || _ended) return;
    setState(() => _actOpen = false);
    final m = _run.act(m6SwapActOf(o.textBn));
    if (m != null) {
      if (m.deadly) _flashAt = _geoNow?.flashJoint ?? Offset.zero;
      _afterCard = _openAct;
      unawaited(_mistake(m, at));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/confirm.ogg', volume: 0.6);
    putOnTable(15 + (_run.jobSlips == 0 ? 5 : 0));
    final topic = m6SwapTamperWhy(_run.job);
    unawaited(askReason(
      deal: () => dealChoices(M6MeterSwapLines.whyRight[topic]!, M6MeterSwapLines.myths, widget.rng),
      question: M6MeterSwapLines.whyQ[topic]!,
      stillValid: () => !_ended,
    ));
  }

  // --- the clean job -------------------------------------------------------------
  void _tapTool(M6SwapTool t) {
    if (!_canPlay || _run.stage != M6SwapStage.swap) return;
    switch (t) {
      case M6SwapTool.phone:
        _snap();
      case M6SwapTool.card:
        _jobCard();
      case M6SwapTool.tester:
      case M6SwapTool.driver:
        _tick('sounds/intro/click.ogg', 0.5);
        setState(() {
          _held = _held == t ? null : t;
          _wake++;
        });
    }
  }

  void _snap() {
    // The photo push waits for the old reading's phone.
    if (_run.deal.push == M6SwapPush.photo && !_run.swapped && _run.oldPhoto == null && holdForCoworker()) return;
    if (!_run.snap()) return;
    HapticFeedback.lightImpact();
    _cue('sounds/intro/click.ogg', volume: 0.7);
    setState(() => _snapN++);
    _stepDone();
  }

  void _pull() {
    if (!_run.pull()) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.5);
    _stepDone();
  }

  void _pushIn() {
    if (!_run.pushIn()) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.55);
    _stepDone();
  }

  void _test(M6SwapPoint p) {
    final r = _run.test(p);
    if (r.live == null) return;
    _tick('sounds/learn/dmm_beep.ogg', 0.55);
    _chipTimer?.cancel();
    setState(() => _chip = (at: p, live: r.live!));
    _chipTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _chip = null);
    });
    final m = r.mistake;
    if (m != null) {
      unawaited(_mistake(m, _sceneToGlobal(_geoNow?.loadContact ?? Offset.zero)));
      return;
    }
    _stepDone();
  }

  void _openBox() {
    // A player who skips the old photo meets the photo push at the box.
    if (_run.deal.push == M6SwapPush.photo && !_run.swapped && _run.oldPhoto == null && holdForCoworker()) return;
    final m = _run.openBox();
    if (m != null) {
      if (m.deadly) _flashAt = _geoNow?.flashBox ?? Offset.zero;
      unawaited(_mistake(m, _sceneToGlobal(_geoNow?.flashBox ?? Offset.zero)));
      return;
    }
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
    setState(() => _held = null);
    _cutscene('swap', () => unawaited(_sayChain([_task])));
  }

  void _jobCard() {
    if (!_run.swapped) return;
    _hush();
    _tick('sounds/intro/click.ogg', 0.55);
    setState(() {
      _cardPanel = true;
      _held = null;
      _wake++;
    });
    _panelTimer?.cancel();
    _panelTimer = Timer(Duration(milliseconds: _quiet ? 700 : 1500), () {
      if (!mounted || _ended) return;
      final snappedFirst = _run.snappedFirst;
      final m = _run.jobCard();
      setState(() => _cardPanel = false);
      final size = MediaQuery.sizeOf(context);
      final at = Offset(size.width / 2, size.height * 0.4);
      if (m != null) {
        _afterCard = _nextWall;
        unawaited(_mistake(m, at));
        return;
      }
      HapticFeedback.mediumImpact();
      _cue('sounds/intro/confirm.ogg', volume: 0.6);
      putOnTable(15 + (_run.jobSlips == 0 ? 5 : 0));
      final topic = m6SwapCleanWhy(_run.job, snappedFirst: snappedFirst);
      unawaited(askReason(
        deal: () => dealChoices(M6MeterSwapLines.whyRight[topic]!, M6MeterSwapLines.myths, widget.rng),
        question: M6MeterSwapLines.whyQ[topic]!,
        stillValid: () => !_ended,
      ));
    });
  }

  void _nextWall() {
    if (_ended) return;
    _run.nextJob();
    if (_run.finished) {
      unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
        if (mounted && !_ended) unawaited(_finish());
      }));
      return;
    }
    setState(() {
      _held = null;
      _look = null;
      _chip = null;
      _aside.clear();
    });
    _cutscene('walk', () {
      _wallReady();
      unawaited(_sayChain([_task]));
    });
  }

  void _cutscene(String id, VoidCallback then) {
    _cutTimer?.cancel();
    setState(() {
      _cut = id;
      _wake++;
    });
    _cutTimer = Timer(Duration(milliseconds: _quiet ? 900 : 2400), () {
      if (!mounted || _ended) return;
      setState(() {
        _cut = null;
        _wake++;
      });
      then();
    });
  }

  // --- the scene's touches ---------------------------------------------------------
  void _tapScene(Offset p, M6SwapGeo geo) {
    if (!_canPlay) return;
    final stage = _run.stage;
    if (stage != M6SwapStage.look && stage != M6SwapStage.swap) return;
    for (final s in M6SwapSpot.values) {
      if (geo.spotHit(s).contains(p)) {
        _closeLook(s);
        return;
      }
    }
    if (geo.buttonHit.contains(p) && (_run.swapped || _run.job.meter == M6SwapMeter.lcd)) {
      _press();
      return;
    }
    if (stage == M6SwapStage.swap) {
      if (_held == M6SwapTool.tester) {
        for (final pt in M6SwapPoint.values) {
          if (geo.pointHit(pt).contains(p)) {
            _test(pt);
            return;
          }
        }
      }
      if (_held == M6SwapTool.driver && (geo.boxHit.contains(p) || geo.terminalCover.contains(p))) {
        _openBox();
        return;
      }
    }
    _hints.missTap();
  }

  /// A still press that the long press won: a seal tug, else the pan it was
  /// going to be (press the carrier, then drag).
  void _holdStart(Offset p, M6SwapGeo geo) {
    if (_canPlay && (_run.stage == M6SwapStage.look || _run.stage == M6SwapStage.swap)) {
      for (final s in M6SwapSeal.values) {
        if (geo.sealHit(s).contains(p)) {
          _pan = _Pan.none;
          _tug(s);
          return;
        }
      }
    }
    _panStart(p, geo);
  }

  void _panStart(Offset p, M6SwapGeo geo) {
    _pan = _Pan.none;
    if (!_canPlay) return;
    _panFrom = p;
    _panNow = p;
    if (_run.stage == M6SwapStage.swap && geo.carrierHit(_run.carrierIn).contains(p)) {
      _pan = _Pan.carrier;
      return;
    }
    _pan = _Pan.swipe;
  }

  void _panUpdate(Offset p) => _panNow = p;

  void _panEnd() {
    final kind = _pan;
    _pan = _Pan.none;
    if (!_canPlay) return;
    final d = _panNow - _panFrom;
    switch (kind) {
      case _Pan.carrier:
        if (_run.carrierIn && d.dy >= 26) {
          _pull();
        } else if (!_run.carrierIn && d.dy <= -26) {
          _pushIn();
        } else {
          _hints.missTap();
        }
      case _Pan.swipe:
        _hints.missTap();
      case _Pan.none:
        break;
    }
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
  void onReasonPaid() => _nextWall();

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M6MeterSwapLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;

  /// His moment: on his wall, at the report (magnet) or before the old photo
  /// (photo; still ahead while the player looks). Past it: null. He never
  /// comes on a timer: the decisive control calls him (holdForCoworker).
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.ended || !_run.pushHere) return null;
    final ahead = switch (_run.deal.push) {
      M6SwapPush.magnet => _run.stage == M6SwapStage.look,
      M6SwapPush.photo => (_run.stage == M6SwapStage.look || _run.stage == M6SwapStage.swap) && !_run.swapped && _run.oldPhoto == null,
    };
    return ahead ? false : null;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() {
    _hush();
    if (mounted && (_held != null || _look != null)) {
      setState(() {
        _held = null;
        _look = null;
      });
    }
  }

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _run.deal.push;
    // The magnet job: the report stands either way, then the action deck.
    if (p == M6SwapPush.magnet) _run.decide(start: false);
    if (!held) {
      final m = _run.listen(p);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      if (p == M6SwapPush.magnet) _afterCard = _openAct;
      await _slip(m);
      return;
    }
    _run.caught.add(M6MeterSwapLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    if (p == M6SwapPush.magnet) {
      unawaited(_sayChain([M6MeterSwapLines.callHeld(p)], mood: GuideMood.glad));
      _openAct();
      return;
    }
    unawaited(_sayChain([M6MeterSwapLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6MeterSwapLines.tapWhy[_nudgeN++ % M6MeterSwapLines.tapWhy.length]
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
      _held = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6swap/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly act: the scene freezes grey and the flash comes off it in
  /// colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _cutTimer?.cancel();
    _panelTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _held = null;
      _look = null;
      _actOpen = false;
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
    final speak = await SpokenOnce.first('m6swap/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6MeterSwapLines.deadlyWord : M6MeterSwapLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        final then = _afterCard;
        _afterCard = null;
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
    await _say(!_run.passed ? M6MeterSwapLines.fail : (_quickBonus ? M6MeterSwapLines.quick : M6MeterSwapLines.allSet),
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
    if (_held != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M6SwapWallRig get _rig {
    final j = _run.job;
    return M6SwapWallRig(
      palette: j.palette,
      meter: j.meter,
      fresh: _run.swapped,
      face: _run.face,
      carrierIn: _run.carrierIn,
      broken: j.brokenSeal,
      tugged: {..._run.tugged},
      bypass: j.sign == M6SwapSign.bypass,
      decoys: j.decoys,
      magnetAt: j.magnetAt,
      // The terminal cover off while the swap cutaway runs.
      boxOpen: _cut == 'swap',
    );
  }

  /// The gesture hand: how to touch, never what. Looking: a sweep over every
  /// seal and close-look place alike, a press-and-hold on an empty patch of
  /// wall (how a tug is done), a tap ripple on the push-button (it only
  /// scrolls), and a sweep over the two decision buttons. On a clean job: a
  /// sweep over the phone, the cut-out, the tester and the screwdriver, in a
  /// per-wall order that is never the procedure order (and
  /// the job card once there); a tool in hand, a sweep over every place it
  /// can touch alike; a short drag on the carrier only when putting it back
  /// is the one way forward (after the swap, with it out).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    if (_run.stage == M6SwapStage.look) {
      final lcd = _run.job.meter == M6SwapMeter.lcd;
      final ways = <HintSpec? Function()>[
        () => HintSpec.sweep(geo.lookRects, space: HintSpace.scene),
        () => HintSpec.hold(geo.emptyWall, space: HintSpace.scene),
        if (lcd) () => HintSpec.tap(geo.button, space: HintSpace.scene),
        () => HintSpec.sweepOver([_startKey, _reportKey]),
      ];
      return ways[n % ways.length]();
    }
    switch (_held) {
      case M6SwapTool.tester:
      case M6SwapTool.driver:
        // A fixed order that never matches the live-dead-live procedure.
        return HintSpec.sweep([geo.boxHit, geo.pointHit(M6SwapPoint.load), geo.pointHit(M6SwapPoint.line), geo.buttonHit, geo.carrierHit(_run.carrierIn)], space: HintSpace.scene);
      case M6SwapTool.phone:
      case M6SwapTool.card:
      case null:
        break;
    }
    if (_run.swapped && !_run.carrierIn && n.isOdd) {
      return HintSpec.drag(geo.carrier(false).center, toward: const Offset(0, -1), travel: 30, space: HintSpace.scene);
    }
    return HintSpec.sweepOver(m6SwapHintOrder(_run.job.whyRoll + 31 * _run.jobIndex, withCard: _run.swapped)
        .map((t) => t == null ? _carrierKey : _toolKeys[t]!)
        .toList());
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6SwapGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final look = _look;
    final chip = _chip;
    final carrier = geo.carrier(_run.carrierIn);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('wall'),
                child: RepaintBoundary(child: CustomPaint(painter: M6SwapWallPainter(geo: geo, rig: _rig))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      // Where the hand's sweep passes over the carrier.
      Positioned.fromRect(key: const ValueKey('hint-carrier'), rect: carrier.inflate(4), child: IgnorePointer(child: SizedBox.expand(key: _carrierKey))),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M6MeterSwapLines.sceneLook,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onLongPressStart: (d) => _holdStart(d.localPosition, geo),
            onLongPressMoveUpdate: (d) => _panUpdate(d.localPosition),
            onLongPressEnd: (_) => _panEnd(),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: _panEnd,
          ),
        ),
      ),
      // The close look.
      if (look != null && !_freeze)
        Positioned.fromRect(
          key: ValueKey('look-${look.spot.name}-${look.thing.name}'),
          rect: Rect.fromCircle(center: geo.lookAt(look.spot), radius: M6SwapGeo.lookR),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0.4, end: 1),
              duration: const Duration(milliseconds: 260),
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: CustomPaint(painter: M6SwapLookPainter(look.thing)),
            ),
          ),
        ),
      // The tester's reading.
      if (chip != null && !_freeze)
        Positioned(
          key: ValueKey('chip-${chip.at.name}-${chip.live}'),
          left: geo.pointHit(chip.at).right + 2,
          top: geo.pointHit(chip.at).top - 2,
          child: IgnorePointer(child: _TesterChip(live: chip.live)),
        ),
      // The phone's flash.
      if (_snapN > 0 && !_freeze)
        Positioned.fromRect(
          key: ValueKey('snap-$_snapN'),
          rect: geo.meter.inflate(6),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 0 : 0.85, end: 0),
              duration: const Duration(milliseconds: 320),
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
              builder: (_, v, _) => CustomPaint(painter: M6SwapFlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
      // A wall change: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('place-${_run.jobIndex}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.jobIndex == 0 ? 0 : 0.7, end: 0),
              duration: const Duration(milliseconds: 560),
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
    final deckUp = reasonOpen || coworkerChoiceUp || _actOpen;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && _cut == null && !_cardPanel && !_run.ended;
    final stage = _run.stage;
    final swapTools = [M6SwapTool.phone, M6SwapTool.tester, M6SwapTool.driver, if (_run.swapped) M6SwapTool.card];
    final toolW = math.min(88.0, (size.width - 8) / swapTools.length);
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
              labels: M6MeterSwapLines.stages,
              done: {for (var i = 0; i < _run.closed.length; i++) i},
              current: _run.finished ? null : _run.jobIndex,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _preview == null,
            hintKey: '${_run.jobIndex}/${stage.name}/$_steps/${_held?.name}/${_run.swapped}/${_run.carrierIn}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing)
                Positioned(
                  key: const ValueKey('docket'),
                  top: pad.top + 92,
                  left: 10,
                  child: const IgnorePointer(child: _DocketChip(text: M6MeterSwapLines.docket)),
                ),
              if (playing && stage == M6SwapStage.swap)
                Positioned(
                  key: const ValueKey('photos'),
                  top: pad.top + 120,
                  left: 10,
                  child: IgnorePointer(child: _PhotoStrip(old: _run.oldPhoto, fresh: _run.newPhoto)),
                ),
              if (handsOn && stage == M6SwapStage.look)
                Positioned(
                  key: ValueKey('hud-decide-${_run.jobIndex}'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      for (final start in const [true, false]) ...[
                        if (!start) const SizedBox(width: 10),
                        Expanded(
                          child: CardAside(
                            aside: _aside.contains(start),
                            child: _DecideButton(
                              key: start ? _startKey : _reportKey,
                              label: start ? M6MeterSwapLines.start : M6MeterSwapLines.report,
                              icon: start ? Icons.build_rounded : Icons.report_rounded,
                              onTap: () => _openPreview(start),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (handsOn && stage == M6SwapStage.swap)
                Positioned(
                  key: ValueKey('hud-tools-${_run.jobIndex}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final t in swapTools)
                        _ToolButton(
                          key: _toolKeys[t],
                          icon: _icons[t]!,
                          label: M6MeterSwapLines.tool(t),
                          width: toolW,
                          on: _held == t,
                          onTap: () => _tapTool(t),
                        ),
                    ],
                  ),
                ),
              if (_cardPanel)
                Positioned.fill(
                  key: const ValueKey('job-card'),
                  child: _JobCardPanel(old: _run.oldPhoto, fresh: _run.newPhoto, quiet: quiet),
                ),
              if (_cut != null)
                Positioned.fill(
                  key: ValueKey('cut-$_cut'),
                  child: _Cutscene(text: _cut == 'swap' ? M6MeterSwapLines.cutSwap : M6MeterSwapLines.cutWalk, swap: _cut == 'swap', quiet: quiet),
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
                        : _actOpen
                            ? ChoiceDeck(
                                key: ValueKey('act-deck-$_actN'),
                                options: _actOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _actWrong,
                                picked: _actPicked,
                                onPick: (o, at) => unawaited(_pickAct(o, at)),
                              )
                            : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              // Over the corner guide: nothing may cover the card's ✓ / ✕.
              if (handsOn && _preview != null)
                Positioned.fill(
                  key: ValueKey('decide-preview-$_preview'),
                  child: CardPreviewOverlay(
                    textBn: _preview! ? M6MeterSwapLines.start : M6MeterSwapLines.report,
                    icon: _preview! ? Icons.build_rounded : Icons.report_rounded,
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
                  line: M6MeterSwapLines.intro,
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
    M6SwapTool.phone: Icons.photo_camera_rounded,
    M6SwapTool.tester: Icons.electrical_services_rounded,
    M6SwapTool.driver: Icons.handyman_rounded,
    M6SwapTool.card: Icons.assignment_rounded,
  };
}

// ============================================================================
// Pieces
// ============================================================================

/// The docket on the job (a worker reads it).
class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xE6F7F1DE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E5E8E), width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_rounded, size: 13, color: Color(0xFF2E5E8E)),
          const SizedBox(width: 5),
          Text(text, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018))),
        ],
      ),
    );
  }
}

/// The two photos so far (the raw screens, small).
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.old, required this.fresh});
  final M6SwapShot? old;
  final M6SwapShot? fresh;

  @override
  Widget build(BuildContext context) {
    Widget one(String label, M6SwapShot? s, String key) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(key: ValueKey(key), width: 62, height: 28, child: CustomPaint(painter: M6SwapScreenPainter(s))),
              const SizedBox(height: 2),
              Text(label, style: bangla(fontSize: 10, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 0, 4),
      decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(padding: EdgeInsets.only(right: 5), child: Icon(Icons.photo_camera_rounded, size: 14, color: SlmColors.gold300)),
          one(M6MeterSwapLines.photoOld, old, 'photo-old'),
          one(M6MeterSwapLines.photoNew, fresh, 'photo-new'),
        ],
      ),
    );
  }
}

/// The job card: both photos, big, before the verdict.
class _JobCardPanel extends StatelessWidget {
  const _JobCardPanel({required this.old, required this.fresh, required this.quiet});
  final M6SwapShot? old;
  final M6SwapShot? fresh;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    Widget one(String label, M6SwapShot? s) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 124, height: 56, child: CustomPaint(painter: M6SwapScreenPainter(s))),
            const SizedBox(height: 4),
            Text(label, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF2A2018))),
          ],
        );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: ColoredBox(
        color: const Color(0x99050A16),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1DE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2E5E8E), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(M6MeterSwapLines.cardTitle, style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, color: const Color(0xFF2E5E8E))),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [one(M6MeterSwapLines.cardOld, old), const SizedBox(width: 14), one(M6MeterSwapLines.cardNew, fresh)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The tester's reading by its place: the lamp lit (live) or dark (0 V).
class _TesterChip extends StatelessWidget {
  const _TesterChip({required this.live});
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xF20B1324),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: live ? const Color(0xFFE5533D) : const Color(0xFF6E7C90), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: live ? const Color(0xFFFF5A3C) : const Color(0xFF3A4452))),
          const SizedBox(width: 4),
          Text(live ? M6MeterSwapLines.testerLive : M6MeterSwapLines.testerDead, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
        ],
      ),
    );
  }
}

/// A staged step (the swap, the walk to the next wall).
class _Cutscene extends StatelessWidget {
  const _Cutscene({required this.text, required this.swap, required this.quiet});
  final String text;
  final bool swap;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: ColoredBox(
        color: const Color(0x99050A16),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xF20B1324),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SlmColors.gold300, width: 1.6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(swap ? Icons.build_circle_rounded : Icons.directions_walk_rounded, size: 26, color: SlmColors.gold300),
                const SizedBox(width: 10),
                Flexible(child: Text(text, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the two decision buttons (a tap opens its preview).
class _DecideButton extends StatelessWidget {
  const _DecideButton({super.key, required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.gold300, width: 1.6),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: SlmColors.gold300),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tool: a round icon with its name under it; lit while in hand.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTap, this.width = 80});
  final IconData icon;
  final String label;
  final double width;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, softWrap: false, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
